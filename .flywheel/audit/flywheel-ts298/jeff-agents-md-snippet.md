# AGENTS.md — Jeffrey Emanuel Personal Site

## RULE NUMBER 1 (NEVER EVER EVER FORGET THIS RULE!!!)

**YOU ARE NEVER ALLOWED TO DELETE A FILE WITHOUT EXPRESS PERMISSION FROM ME OR A DIRECT COMMAND FROM ME.**

Even a new file that you yourself created, such as a test code file. You have a horrible track record of deleting critically important files or otherwise throwing away tons of expensive work that I then need to pay to reproduce.

As a result, you have permanently lost any and all rights to determine that a file or folder should be deleted. You must **ALWAYS** ask and *receive* clear, written permission from me before ever even thinking of deleting a file or folder of any kind!

---

## IRREVERSIBLE GIT & FILESYSTEM ACTIONS — DO-NOT-EVER BREAK GLASS

1. **Absolutely forbidden commands:** `git reset --hard`, `git clean -fd`, `rm -rf`, or any command that can delete or overwrite code/data must never be run unless the user explicitly provides the exact command and states, in the same message, that they understand and want the irreversible consequences.

2. **No guessing:** If there is any uncertainty about what a command might delete or overwrite, stop immediately and ask the user for specific approval. "I think it's safe" is never acceptable.

3. **Safer alternatives first:** When cleanup or rollbacks are needed, request permission to use non-destructive options (`git status`, `git diff`, `git stash`, copying to backups) before ever considering a destructive command.

4. **Mandatory explicit plan:** Even after explicit user authorization, restate the command verbatim, list exactly what will be affected, and wait for a confirmation that your understanding is correct. Only then may you execute it—if anything remains ambiguous, refuse and escalate.

5. **Document the confirmation:** When running any approved destructive command, record (in the session notes / final response) the exact user text that authorized it, the command actually run, and the execution time. If that record is absent, the operation did not happen.

---

## Project Overview

This is Jeffrey Emanuel's personal website — a Next.js 16 site showcasing his work, projects, writing, and the Flywheel ecosystem of AI coding tools.

**Repository:** https://github.com/Dicklesworthstone/jeffrey_emanuel_personal_site

**Live Site:** Deployed on Vercel

---

## Tech Stack

| Layer | Technology |
|-------|------------|
