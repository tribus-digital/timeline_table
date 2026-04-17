# Contributing

Thanks for contributing to `timeline_table`.

This repository contains both the reusable package and a runnable example app. Good contributions keep the package API, behavior, tests, and example gallery aligned.

## Before You Start

For small fixes, typo corrections, and focused improvements, feel free to open a pull request directly.

For larger changes, new public API surface, behavioral changes, or anything that may affect existing consumers, start with a discussion in the project issue tracker first. That helps avoid duplicated work and gives maintainers a chance to confirm direction before implementation begins.

## Local Setup

Make sure you have a supported Flutter and Dart toolchain installed.

From the repository root:

```sh
flutter pub get
```

The example app uses the package by path, so fetch dependencies for it as well:

```sh
cd example
flutter pub get
```

## Repository Layout

- `lib/` contains the package source
- `test/` contains package unit and widget tests
- `example/` contains the example gallery app used to exercise real package
  usage patterns

## Local Verification

Run verification from the repository root unless noted otherwise.

Core package checks:

```sh
dart analyze
flutter test
```

Example app checks:

```sh
cd example
flutter test test/widget_test.dart
```

Use the example app when a change affects:

- layout or rendering behavior
- controller interactions
- accessibility or desktop/web interaction
- public-facing examples in the gallery

## Code Expectations

Please aim for changes that are easy to review and easy to maintain.

Contributors should:

- keep changes focused on the problem being solved
- follow the existing style and architecture of the package
- add or update tests when behavior changes
- update docs and examples when public usage changes
- avoid unrelated refactors in the same pull request unless they are necessary to support the change

## Public API And Behavior Changes

Be especially careful with changes that affect package consumers.

If your change modifies public behavior, public types, builder contracts,
controller behavior, layout semantics, or accessibility expectations:

- update README documentation and examples as needed
- add or adjust tests in `test/`
- update the example app if it demonstrates the affected behavior
- call out any breaking or migration-relevant changes clearly in the pull
  request description

If a change is intentionally breaking, explain:

- what changed
- why it changed
- how existing users should migrate

## Pull Request Guidance

When opening a pull request:

- describe the problem and the chosen solution clearly
- keep the change set as small and focused as practical
- mention any tradeoffs or follow-up work
- include screenshots or recordings for visible UI changes when helpful
- note the verification you ran locally

Good pull requests usually make it easy for a reviewer to answer:

- what changed
- why it changed
- how it was tested
- whether any public behavior changed

## Documentation

Documentation is part of the product, not an afterthought.

Please update relevant docs when you change:

- public API usage
- package behavior described in [`README.md`](README.md)
- example app behavior that serves as reference material
- contributor expectations that are no longer accurate

## Questions And Proposals

Use the project issue tracker for general questions, bug reports, feature
proposals, and discussion of larger changes.

Do not use public issues for Code of Conduct reports. Those should go through the private reporting path described in [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
