# 0003: Per-app frame channels

Status: accepted (on `tune/hyprland-feel`, after v0.0.19). Built and unit-tested only; never run
against real windows.

## Context

`FrameAnimator.tick` used to make one blocking Accessibility call per moving window, in sequence,
on the main actor. A display frame therefore cost the sum of every app's answer time (measured:
~4 ms for Ghostty and System Settings, ~9 ms for Opera with 22 ms spikes), and one hung app
(1 s messaging timeout) stalled every animation, tiling and the hotkeys with it.

`AXUIElement` is not `Sendable`, so elements cannot be handed from the main actor to another
isolation domain. Swift 6 strict concurrency (and the lint rules: no `@unchecked Sendable`, no
`nonisolated(unsafe)`, no `Task.detached`) rule out smuggling them across.

## Decision

Frame setting goes through one channel per app (pid), `AppChannel`, an `actor`:

- It owns its own elements. It creates `AXUIElementCreateApplication(pid)` itself and resolves a
  window by `WindowID` from the app's `kAXWindowsAttribute` list (`AXWindow.init`, which uses the
  `windowID` helper), caching the result. A failed call or a released window drops the cache entry.
  Only `Sendable` values cross: `WindowID`, `CGRect`/`CGPoint`, `FrameStep`.
- It runs on its own `DispatchSerialQueue` (custom executor), so a call blocked on a hung app ties up
  that app's queue, not a thread of Swift's shared cooperative pool.
- Work is handed over through a mailbox, `OSAllocatedUnfairLock<AppQueue>`, that the main actor
  writes without waiting. `AppQueue` and `StepQueue` are pure Core types (unit-tested) that decide:
  - Latest frame wins: a newer animation step merges into the one still waiting for that window
    (a move after a waiting resize keeps the resize's size), so a slow app skips stale frames
    instead of queueing them. At most two steps wait per window.
  - A final step (`settle`, `park`) replaces everything waiting before it and is never dropped or
    overtaken by an older step; steps after it wait behind it. Per-window order is preserved.
    A newer final step does replace an older one that has not been applied yet.
  - Submitting to an idle channel wakes it (one `Task` that drains until the mailbox is empty);
    only one drain runs at a time.
  - `AXEnhancedUserInterface` (see the handoff, slice 5): the channel reads it before the first step
    of a session and switches it off if on; it is switched back on once no animation holds the app
    and nothing waits. Doing this in the channel keeps it ordered with the steps.
- After applying a step, the channel measures how long the app took and hops to the main actor,
  which records the pace (`blox stats`), moves the ring to the window server's bounds,
  `CATransaction.flush()`es, and, for `settle`, runs `onSettled`.

What stays on the main actor, exactly as before: `current`/`tracks` bookkeeping (updated when a
step is submitted), adoption, observers (`AXObserver` needs the main run loop), focus and raise,
close, attribute reads (`isTileable`, `isFullScreen`), the immediate re-park and read-back in
`WindowSystem+Reshape`, and the restore of parked windows on quit.

## Consequences

- A frame costs the main actor only the submits; apps answer in parallel, each at its own pace.
- A hung app can still block the main actor through the paths that stay there (focus/raise,
  adoption, attribute reads, close). Moving them into the channel is future work.
- Ring updates follow the app's answer instead of the request, as before, but now arrive
  asynchronously; a completion for a window Blox has forgotten or parked meanwhile is ignored.
- The late-frame counter in `blox stats` now measures only the main actor's work per tick; the
  per-app answer times are what show a slow app.
- Quit is synchronous: `restoreParked()` closes every mailbox, waits for each channel's current
  call (`DispatchSerialQueue.sync`, quit only), restores `AXEnhancedUserInterface` where a channel
  switched it off, then puts parked windows back with direct calls, because the process exits
  right after and queued work would never run.
- Channels are created on first use and closed and removed when their app quits (`detach`).
