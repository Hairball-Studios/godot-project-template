# Contributing

Changes that make the template a better starting point are welcome: a fix, a clearer check, a
platform that does not build, a newer pinned version.

1. Run `mise run setup` once (the [README](README.md) says what it needs).
2. Make the change. Keep the template small: it is tooling for a game's repository, not a game
   framework, so a new feature for the Snake game is rarely the right change.
3. Run `mise run check`; it must pass. `mise run format` fixes layout, and
   [CHECKS.md](CHECKS.md) shows what each check reports.
4. A change to behaviour comes with a test in `tests/`. A change to a task, a tool or a file's
   purpose comes with the matching line in the README.
5. Open a pull request that says what changed and why, and which platform you ran it on.

Bugs: open an issue with your platform, the task you ran, and what it printed.
