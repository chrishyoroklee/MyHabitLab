# Performance Notes

## Dashboard
- The dashboard pre-fetches today's completions in a single SwiftData query and builds a lookup table by habit id to avoid per-row scans.
- Recompute the day key only on view appearance or when the app becomes active (not per-row).

## Quick profiling checklist
- Use Instruments → Time Profiler while scrolling a large list (100+ habits) to confirm minimal main-thread work.
- Use Instruments → Core Data / SwiftData template to verify a single fetch for completions per refresh.
- Watch frame rate in the simulator (Debug → View Debugging → Show Rendering) to ensure smooth scrolling.

## Known hotspots to watch
- Per-row relationship access to `habit.completions` (avoid N+1 fetches).
- Date calculations inside lists or grids (keep them cached per view refresh).
