# Lemelsonbot

<div align="center">
  <img src="docs/lemelsonbot_hero.webp" alt="Lemelsonbot - invention notebook corpus and methodology">
</div>

<div align="center">

[![Corpus](https://img.shields.io/badge/corpus-lemelsonbot-blue)](LEMELSON_NOTEBOOKS_EXTRACTED_v1.md)

</div>

Operationalized corpus and methodology distilled from Jerome H. Lemelson's invention notebooks.

<div align="center">
<h3>Quick Install</h3>

```bash
curl -fsSL https://raw.githubusercontent.com/Dicklesworthstone/lemelsonbot/main/LEMELSON_NOTEBOOKS_EXTRACTED_v1.md -o LEMELSON_NOTEBOOKS_EXTRACTED_v1.md
```

</div>

---

## TL;DR

**The Problem**
- The notebooks are scanned PDFs with Smithsonian headers and repeated metadata.
- OCR output is inconsistent and hard to search at scale.

**The Solution**
- A single cleaned corpus file plus a structured methodology distillation that is machine-parseable.

**Why Use Lemelsonbot?**

| Feature | What you get | Why it matters |
| --- | --- | --- |
| Cleaned corpus | `LEMELSON_NOTEBOOKS_EXTRACTED_v1.md` with boilerplate removed | Search without noise |
| Evidence traceability | Quote bank and provenance graph | Every rule points back to sources |
| Methodology distillation | Triangulated kernel and operator library | Reusable invention heuristics |
| Validation scripts | `scripts/validate-*.py` | Prevents drift and regressions |
| Machine markers | HTML comment markers for kernels/operators | Easy downstream parsing |

## Quick Example

```bash
rg -n "feedback" LEMELSON_NOTEBOOKS_EXTRACTED_v1.md | head
python3 scripts/validate-corpus.py
python3 scripts/validate-kernel.py
python3 scripts/extract-kernel.py --in corpus/specs/triangulated_kernel.md --out artifacts/triangulated_kernel.md
rg -n "OPERATOR_CARD_START" corpus/specs/operator_library.md | head
python3 scripts/validate-operators.py
python3 scripts/validate-kickoffs.py
```

## Design Philosophy

- Evidence first: Every operator is anchored to corpus excerpts and quote IDs.
- Stable artifacts: Kernel, operator library, and specs are versioned and linted.
- Machine-parseable by default: Markers make extraction deterministic.
- Progressive disclosure: Glossary and kickoffs let roles work at different depth.
- Validation in CI: Scripts encode the contract so changes fail fast.

## Comparison

| Approach | Cleaned text | Methodology distillation | Validation | Machine markers |
| --- | --- | --- | --- | --- |
| Lemelsonbot | Yes | Yes | Yes | Yes |
| Raw PDFs | No | No | No | No |
| OCR dump only | Partial | No | No | No |
| General note archive | Partial | Partial | No | No |

## Installation

No build step is required. Choose the path that matches how you want to use the data.

### Option 1: Download the corpus only (curl)

```bash
