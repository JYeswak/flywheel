#!/usr/bin/env python3
"""check-contrast.py - WCAG contrast checker for the ZestStream site CSS.

The FQ-15 gate check. Joshua: "why aren't we globally applying WCAG?" — and the
methodology page shipped white-on-white text in the system map. This catches
that class mechanically.

WHAT IT CHECKS (and what it does not):
  - Builds the :root custom-property map (--token -> color).
  - For every CSS rule block that declares BOTH a text `color` and a
    `background`/`background-color`, resolves var() refs and computes the WCAG
    2.x contrast ratio.
  - fail  < 4.5:1 (AA normal text floor)
  - warn  4.5-7.0 (passes AA, below AAA)
  - pass  >= 7.0 (AAA)
  - Alpha colors (rgba with a<1) are reported `indeterminate` — the real
    contrast depends on the backdrop, which static CSS cannot resolve. Those
    still need a render check; this tool is honest about that boundary.

  --pair "#fff" "#000"  checks any two colors on demand (no CSS parse).

Exit: 0 clean (no fails) - 1 one or more fails - 2 usage error.
"""
import re
import sys
from pathlib import Path


def _hex_to_rgb(h):
    h = h.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    if len(h) not in (6, 8):
        return None
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def parse_color(value, tokens, _depth=0):
    """Return (r,g,b) | 'alpha' | None. Resolves var() against `tokens`."""
    if value is None or _depth > 8:
        return None
    value = value.strip()
    m = re.match(r"var\(\s*(--[\w-]+)\s*\)", value)
    if m:
        return parse_color(tokens.get(m.group(1)), tokens, _depth + 1)
    if value.startswith("#"):
        return _hex_to_rgb(value)
    m = re.match(r"rgba?\(([^)]+)\)", value)
    if m:
        parts = [p.strip() for p in re.split(r"[,/]", m.group(1)) if p.strip()]
        if len(parts) >= 4 and parts[3] not in ("1", "1.0", "100%"):
            return "alpha"
        try:
            return tuple(int(float(p)) for p in parts[:3])
        except ValueError:
            return None
    return None


def _rel_luminance(rgb):
    def chan(c):
        c /= 255.0
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (chan(x) for x in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast_ratio(rgb1, rgb2):
    l1, l2 = _rel_luminance(rgb1), _rel_luminance(rgb2)
    lo, hi = sorted((l1, l2))
    return (hi + 0.05) / (lo + 0.05)


def _verdict(ratio):
    if ratio < 4.5:
        return "fail"
    if ratio < 7.0:
        return "warn"
    return "pass"


def extract_tokens(css):
    tokens = {}
    for m in re.finditer(r"(--[\w-]+)\s*:\s*([^;]+);", css):
        tokens[m.group(1)] = m.group(2).strip()
    return tokens


def check_css(paths):
    """Check same-block color+background pairs only.

    Cross-block / cross-cascade contrast (a `color` rule on one selector, the
    `background` it actually renders on set by a parent or a section class) is
    NOT checked here — a selector-family heuristic over-pairs badly (a section's
    text color against a button's background, a base class against its `.dark`
    modifier, a container against a decorative `::before`). Static CSS cannot
    resolve which element renders on which background; that needs the DOM. So
    this gate checks what it can check honestly, and cross-cascade contrast
    stays a render-review responsibility — which is why Joshua's eye is a
    success criterion, not just the gate. Use `--pair` to verify any specific
    pair (e.g. the resolved colors behind a flagged component) on demand.
    """
    css = "\n".join(Path(p).read_text() for p in paths if Path(p).exists())
    tokens = extract_tokens(css)
    results = []
    for m in re.finditer(r"([^{}]+)\{([^{}]+)\}", css):
        selector, body = m.group(1).strip(), m.group(2)
        col = re.search(r"(?<![-\w])color\s*:\s*([^;]+);", body)
        bg = re.search(r"background(?:-color)?\s*:\s*([^;]+);", body)
        if not (col and bg):
            continue
        fg = parse_color(col.group(1), tokens)
        bgc = parse_color(bg.group(1), tokens)
        if fg == "alpha" or bgc == "alpha":
            results.append((selector, "indeterminate", 0.0))
        elif fg and bgc:
            r = contrast_ratio(fg, bgc)
            results.append((selector, _verdict(r), r))
    return results


def main():
    args = sys.argv[1:]
    if args and args[0] == "--pair" and len(args) == 3:
        a, b = _hex_to_rgb(args[1]), _hex_to_rgb(args[2])
        if not a or not b:
            print("usage: check-contrast.py --pair '#hex' '#hex'", file=sys.stderr)
            return 2
        r = contrast_ratio(a, b)
        print(f"{args[1]} on {args[2]}: {r:.2f}:1  [{_verdict(r)}]")
        return 0 if r >= 4.5 else 1

    repo = Path(__file__).resolve().parent.parent
    if "--repo" in args:
        i = args.index("--repo")
        if i + 1 < len(args):
            repo = Path(args[i + 1])
    css_paths = sorted((repo / "site").glob("*.css"))
    if not css_paths:
        print("no site/*.css found", file=sys.stderr)
        return 2
    results = check_css(css_paths)
    fails = [r for r in results if r[1] == "fail"]
    warns = [r for r in results if r[1] == "warn"]
    indet = [r for r in results if r[1] == "indeterminate"]
    print(f"Contrast check (FQ-15) - {len(css_paths)} CSS file(s)")
    for sel, _, ratio in fails:
        print(f"  FAIL  {ratio:5.2f}:1  {sel[:70]}")
    for sel, _, ratio in warns:
        print(f"  warn  {ratio:5.2f}:1  {sel[:70]}")
    print(f"Status: pass-or-better={len(results) - len(fails) - len(warns) - len(indet)} "
          f"warn={len(warns)} fail={len(fails)} indeterminate(alpha)={len(indet)}")
    if indet:
        print("  note: alpha-channel pairs need a render check — static CSS "
              "cannot resolve their backdrop.")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
