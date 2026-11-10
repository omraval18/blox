# Benchmarking Blox against AeroSpace

`Scripts/bench-compare.swift` measures whichever manager is running, on identical work, so two runs
can be put side by side. Run it once per manager:

```
swift Scripts/bench-compare.swift aerospace      # with AeroSpace running (Blox quit)
swift Scripts/bench-compare.swift blox           # with Blox running (AeroSpace quit)
# options: --sizes 0,5,10,20   --runs 20   --idle 10
```

## What is measured

| Metric | How | Why it matters |
|---|---|---|
| Memory footprint | `footprint <pid>` | What Activity Monitor calls Memory; the honest cost of the process |
| RSS | `ps -o rss` | Includes shared system libraries, so it flatters nobody; reported for reference |
| Threads | `ps -M` | Proxy for background work |
| Idle CPU | CPU-time delta over `--idle` seconds | A manager should cost nothing while you are not touching it |
| Work CPU | CPU-time delta divided by commands sent | The real cost of each action, independent of timing noise |
| CLI round trip | Time for the CLI process to start, send and exit | What a script or binding waits for |
| Time until windows move | Polls WindowServer until the test windows reach the expected state | What you actually see; does not trust the manager's own reply |
| Peak RSS | Sampled after every command | Catches spikes that a single reading misses |

Each is taken at several window counts (default 0, 5, 10, 20), because cost that grows with windows
is the one that matters.

## Workloads

Both are real changes to real windows (TextEdit documents the script opens and later closes):

1. **Workspace flip.** Sends all N windows to an empty workspace and back. Exercises hiding,
   showing and re-placing every window.
2. **Layout flip.** Toggles between two layouts. Exercises a full re-tile.

Animation is switched off in Blox for the run (and restored by a config reload afterwards), so
the numbers reflect the manager, not a deliberate 0.5 s glide.

## Rules for a fair comparison

- **Same machine state.** Plug in the charger (the script warns on battery), close heavy apps, and
  keep the lid and screen as they are for both runs. Don't touch the keyboard during a run.
- **Same windows.** Same `--sizes` and `--runs` for both. The script refuses to run unless the
  scratch workspace `Z` is empty and not current.
- **One manager at a time.** Quit the other first; both fight over the same windows and keys.
- **Repeat.** Run each manager three times and compare medians. Discard a run if anything else
  was using the CPU (a build, a sync).
- **Same era.** Compare release builds. A debug Blox is several times slower.

## Limits to keep in mind

- The CLI round trip includes starting the CLI process. That cost is the same for both, but it
  puts a floor of a few milliseconds under every latency number.
- "Windows moved" is detected by polling every 2 ms, so differences below that are noise.
- "Parked" is recognised as a window whose left edge is at the right screen edge, which both
  managers use to hide windows. A manager that hid windows differently would need a different test.
- TextEdit windows are simple. Apps that resize slowly (Chrome, Electron) will make any manager
  look slower, and Blox's minimum-size learning only kicks in for windows that resist their tile.
- Idle CPU resolution is 0.01 s of CPU over the sample, so 0.1% at the default 10 s.
- Results are for one machine; they say nothing about other Macs.

Results print to the terminal. Copy them somewhere before closing it; they are not saved.
