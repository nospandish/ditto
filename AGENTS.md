# AGENTS.md

## Project Purpose

This project is a Flutter app for the Congressional App Challenge. The goal is to build a polished, useful, and demo-ready application that solves a clear real-world problem and can be explained well in a short presentation or video.

The app should be built with student ownership in mind: Codex can do most of the coding, but choices should stay understandable, reviewable, and easy for the student team to explain to judges.

## Primary Goals

- Build a working Flutter app that can run reliably for a live demo.
- Keep the user experience simple, polished, and purposeful.
- Focus on a strong MVP before adding advanced features.
- Prefer features that clearly support the app's problem statement.
- Keep the codebase organized so future work is easy to continue.
- Make implementation choices that can be explained in the Congressional App Challenge submission.

## Development Approach

- Use Flutter and Dart as the main app stack.
- Start with local-first data unless cloud sync, accounts, or collaboration become necessary.
- Avoid adding heavy dependencies unless they solve a real problem.
- Keep screens and widgets small, readable, and well named.
- Prioritize stable, demo-friendly behavior over experimental complexity.
- Build in checkpoints so the app can be reviewed as it grows.

## GitHub Workflow

- This project will be hosted on GitHub.
- Treat the GitHub repository as the shared source of truth for the project.
- Follow this workflow unless the user gives different instructions:
  1. Pull any remote changes when a remote is configured.
  2. Listen to the user's app ideas.
  3. Discuss the ideas with the user and ask any needed questions.
  4. Wait for explicit permission before starting coding.
  5. Let the user review the changes.
  6. Commit and push only with explicit permission from the user.
- Use clear commit messages that describe the feature, fix, or setup change.
- Do not overwrite teammates' work or force-push unless the user explicitly asks for it.
- If there are local changes from the user or another collaborator, preserve them and work with them.
- Prefer small, reviewable commits over large mixed changes.

## Suggested Flutter Structure

When the Flutter project is created, prefer this general structure:

```text
lib/
  main.dart
  app/
  screens/
  widgets/
  models/
  services/
  theme/
```

Use the existing project structure if it becomes more specific later.

## Design Principles

- The first screen should feel like the actual app, not a marketing page.
- UI should be clean, readable, and easy to demo.
- Use accessible contrast, clear labels, and predictable navigation.
- Avoid clutter; every visible feature should have a purpose.
- Prefer a mature, polished look over flashy effects.

## Collaboration Rules

- Ask clarifying questions when the app idea, users, or core features are unclear.
- Once requirements are clear, implement changes directly.
- Explain important technical choices in plain language.
- Do not rewrite unrelated files or undo user changes.
- Keep changes focused and easy to review.
- After coding, run available formatting, analysis, or tests when possible.

## Bug Reporting Workflow

- Create one report per issue in `docs/bugs/` using
  `docs/BUG_REPORT_TEMPLATE.md`.
- Include exact reproduction steps, expected behavior, actual behavior, and
  environment details.
- Add screenshots, videos, logs, or test names when available.
- Do not mark a bug fixed until a regression test or documented manual
  verification exists.
- Update the report status as work progresses.
- Keep each report focused on one issue.

## Current Unknowns

The following should be decided early:

- App name
- Problem statement
- Target users
- Required MVP screens
- Whether the app needs accounts, cloud data, maps, camera, AI, notifications, or offline support
- Target platforms: Android, iOS, web, or all Flutter targets
