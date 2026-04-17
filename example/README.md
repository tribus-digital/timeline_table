# timeline_table_example

Example gallery for the `timeline_table` package.

The app now includes five demo scenarios:

- `Transit Operations` for grouped route schedules
- `Product Roadmap` for custom headers and milestone rendering across non-overlapping lanes
- `Clinic Appointments` for controller-driven navigation
- `Broadcast Rundown` for live-state tracking and edge-triggered range extension
- `Incident Response` for mouse drag, keyboard focus, and accessibility review

The example data also follows the package invariant that each row is a single
non-overlapping lane. If two events overlap in time, they should be split into
separate rows before they are passed into `TimelineTable`.
