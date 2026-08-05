# Changelog

All notable changes to `timeline_table` will be documented in this file.


## 0.3.3

### Fixed

- `intl` constraint reverted to `^0.20.2`. 0.3.2 raised it to `^0.20.3`, which
  no app using `flutter_localizations` can resolve - that package pins `intl` to
  exactly 0.20.2.


## 0.3.2

### Updated dependencies

- `collection` ^1.19.0 -> ^1.19.1
- `equatable` ^2.0.5 -> ^2.1.0
- `intl` ^0.20.2 -> ^0.20.3


## 0.3.1

### Changed
- `TimelineThemeData` now mixes in `Equatable` rather than the deprecated
  `EquatableMixin`, which `equatable` 2.1.0 replaced with `Equatable` itself.
  Equality and `props` behaviour are unchanged.


## 0.3.0

Grouped row headers reworked. Groups are now contiguous runs with fixed merge
geometry, which changes how non-adjacent rows sharing a `groupId` are treated -
see below.

### Fixed
- Group merges now follow *contiguous runs*. `start`/`count` were tracked per
  `groupId`, taking a run's length from the group's total row count, so a group
  whose rows were not adjacent merged straight through the rows in between - in
  the bundled transit demo, `Green Line` (rows 1, 2, 5) merged rows 1-3 and
  swallowed a `Control` row. Rows sharing a `groupId` without being adjacent now
  form separate runs. As before, a run of a single row is not merged.
- Group headers no longer jump or disappear when scrolling vertically and then
  horizontally. The merge start was pinned to the first *visible* row, so it
  moved with the scroll offset; `TableView` requires the same merge information
  from every vicinity a merged cell contains and unmerges the rest when it
  changes. Worse, when the first visible row belonged to a different group, the
  intended group matched no vicinity and rendered no header at all. Merge
  geometry is now fixed per run and independent of scroll position.
- Group headers no longer crash with `RangeError (end)` during layout. When a
  group extended above the viewport its pinned header counted the group's rows
  from the first *visible* row rather than from the group's start, reading past
  the end of the row list whenever the group reached the end of the table.
- `groupHeaderBuilder` now always receives the group's own rows. A header pinned
  part-way into a group could previously report rows belonging to the *following*
  group, and the reported rows shifted with the scroll offset - so any
  group-level total derived from them changed as the user scrolled.


## 0.2.0
Maintenance release

### Updated dependencies

- `two_dimensional_scrollables` 0.4.2 -> 0.5.3


## 0.1.0

Initial standalone package release.

### Added

- Virtualised timeline table widget built on `two_dimensional_scrollables`
- Generic timeline models for config, data, rows, and events
- Typed controller with readiness, scrolling, and observable view state
- Builder-first customisation for headers and event cells
- Table-level event tap and long-press interactions
- Configurable lifecycle callbacks for event activation behavior
- Package-owned event cell helper widget and timeline styling primitives
- Package-level theming via `TimelineThemeData`, `TimelineTableStyle`, and dedicated current-time / pinned-header styling
- Example app, widget tests, and package documentation
