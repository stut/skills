# tech-interview

A skill that runs you through a technical interview at a level you choose, then probes your work and gives you a detailed evaluation.

## What it does

You invoke it with a level and (optionally) a stack and question type. It poses an appropriately calibrated question, plays a neutral interviewer while you work — answering clarifying questions but never hinting, coaching, or evaluating mid-session. When you say you're done, it asks targeted scenario questions designed to surface edge cases without telegraphing them, then writes a structured report covering strengths, gaps, level fit, and concrete suggestions.

It's built for engineers preparing for interviews, but a side effect is that it makes you a better *interviewer* — being on the receiving end of rigorous probing teaches you what depth feels like in a way no how-to guide can.

## Quick start

Install via the plugin (see the [repo README](../../README.md#install)):

```text
/plugin marketplace add stut/skills
/plugin install stut@skills
```

Then in Claude Code:

```
/stut:tech-interview senior go
/stut:tech-interview mid-level architecture
/stut:tech-interview                       # launches a setup wizard
```

(If you installed via the raw-skills path, the command is `/tech-interview` without the namespace prefix.)

Arguments are free-form. The skill parses what it can and asks for what's missing. Examples:

```
/tech-interview principal              # asks for type/stack as needed
/tech-interview lead architecture 60m  # 60-minute time budget
/tech-interview senior python "focus on concurrency, no web"
```

## How calibration works

The skill pitches the question's scope and ambiguity to the level:

| Level | Question shape |
|---|---|
| **junior** | Concrete, narrow task. Clear inputs/outputs. Implementation focus. |
| **mid-level** | Real-world feature with some edges left implicit. |
| **senior** | Intentional ambiguity. Expect clarifying questions and justified choices. |
| **lead** | Design-leaning, multiple components, team-level concerns. |
| **staff** | Cross-system design. Significant ambiguity. Risk and prioritization. |
| **principal** | Open-ended, strategic. Org-wide, multi-year, ambiguous business framing. |

Question types: `coding`, `architecture` / `system-design`, `debugging`, `code-review`, `refactor`. If you don't pick, the skill picks one suited to the level (juniors lean coding; staff/principal lean architecture).

## Worked example: mid-level Go, coding

**Invocation:** `/tech-interview mid-level go`

**Question posed:**

> Implement an in-memory key-value cache in Go with the following API:
>
> ```go
> type Cache interface {
>     Get(key string) (value string, ok bool)
>     Set(key, value string, ttl time.Duration)
>     Delete(key string)
> }
> ```
>
> Requirements: TTL expiration, goroutine-safe, include tests covering the behavior you consider important.

**During the session**, the candidate asks clarifying questions (size limits? TTL replacement semantics? eager vs. lazy deletion? expected workload?). The interviewer answers each within scope and bounces design decisions back: *"your call — be ready to justify it."*

**On "I'm done"**, the skill reads the candidate's `cache.go` and `cache_test.go`, then asks scenario questions like:

- "Walk me through what happens when two goroutines call `Set` on the same key at the same time."
- "Walk me through what `Get` returns immediately after `Delete`."
- "The same user submits the same long URL twice — what does the system return?"

It covers 3–6 scenarios — enough to surface the work's structure without exhausting it — then produces a report:

> **Summary** — Built a `MemoryCache` backed by `sync.Map`, with TTLs per item, lazy expiration on `Get`, and a periodic background "vacuum" pass to evict expired entries…
>
> **Strengths** — Asked good clarifying questions… lazy expiration on `Get` is correct… `TryLock` to avoid pile-up was a sensible call…
>
> **Gaps** — Data race on `nextVacuumDueAt` (read in `vacuum()` without a lock, written in two places). `Delete` mutates a shared `*memoryCacheItem` in place — another goroutine reading via `Get` could see a torn `expiresAt`. Tests use real `time.Sleep` instead of an injected clock — flaky and slow…
>
> **Level fit** — Meets mid-level overall, with reservations on concurrency. The shape is right, follow-up answers were strong, but the race conditions are the kind of thing mid-level Go engineers should catch — running `go test -race` once would have flagged them.
>
> **Suggestions** — Run `-race` as part of "done"… inject a clock for time-dependent tests… don't mutate stored items in place; replace the pointer instead… add a concurrent-access test under `-race`…

**After the report**, the skill invites follow-up: *"Happy to dig into any of this — why a miss mattered, what a stronger answer would have looked like, how this differs at the next level up, or anything else."*

## Worked example: junior Go, coding

**Invocation:** `/tech-interview junior go`

**Question posed:**

> Write a Go function `WordCount` that takes a string and returns a `map[string]int` mapping each distinct word to its count. Words are separated by whitespace. Comparison is case-insensitive.

The candidate asks about punctuation handling, whitespace definition, and error handling — all answered factually within scope. They submit a 14-line solution. The probing phase walks through edge cases like punctuation-attached words, mixed case, and empty input. The report flags a missed requirement (case-insensitivity not implemented), a redundant map check, and `println` vs. `fmt.Println`, while crediting idiomatic use of `strings.Fields`.

## Worked example: principal architecture (sketch)

**Invocation:** `/tech-interview principal architecture`

**Question posed:**

> Your company is a four-year-old SaaS that has grown ~10× in 18 months. The central data warehouse — originally a single Postgres instance, now a managed analytics warehouse — has become both a bottleneck and a political flashpoint: every team's reporting depends on it, the data team is overwhelmed, and product, finance, and ML are all blocked on changes that conflict with each other. Leadership wants a multi-year strategy. Walk me through how you'd approach this.

At principal level the question is deliberately under-specified. The interviewer expects the candidate to: name stakeholders and their actual incentives, articulate non-goals as well as goals, propose an organizational shape (centralized data team vs. embedded analytics engineers vs. data mesh), sequence the work in phases with measurable outcomes, identify the political/cultural risks, and explicitly trade off speed vs. consolidation. There's no "right answer" — the report evaluates the *quality of the framing*: did they treat this as a technical problem only, or did they integrate org structure, business priorities, and migration risk?

## Features

- **Setup wizard** — invoke with no arguments and the skill walks you through level → type → stack → time budget → focus, conversationally. Skip any step you've already answered.
- **Probing phase** — 3–6 scenario questions designed to surface edge cases without naming them. Telegraphs nothing; lets the candidate discover gaps themselves.
- **Diff against the prompt** — the interviewer explicitly checks what the prompt asked for against what the candidate delivered, and probes anything missing.
- **Spaced-repetition history** — sessions are logged with a canonical "shape tag." On future invocations, the skill avoids any shape used in the last 30 days at the same level. Older shapes can recur, and the skill flags it: *"I last gave you this 4 months ago — let's see how your approach has evolved."*
- **Time budget (soft)** — pass `30m` or `60m` to scope the question and get gentle nudges as you approach the limit. Note: the skill can only respond to your messages; it can't proactively interrupt silence.
- **Stack-agnostic mode** — non-coding question types (architecture, debugging discussion) default to stack-agnostic so you don't have to specify one.

## Limitations

- **Question pool diversity.** Models have a strong tendency to gravitate toward well-known problem shapes (caches, rate limiters, URL shorteners). The spaced-repetition feature mitigates this within ~30 days, but heavy users will see shape repetition over a longer horizon. Adding `extra instructions` like "no caches, no rate limiters" forces the model into less-trodden territory.
- **No live timer.** A skill can only act on user messages; it can't proactively tell you "5 minutes left" while you're working in silence. Time checks happen on each turn you take.
- **Memory is per-machine.** The session history file lives in the host's local memory directory. If you use multiple machines, histories don't sync — workaround is to dotfile-sync the memory directory.
- **The interviewer is patient and never gets bored.** Real interviews have time pressure and evaluator fatigue; this one doesn't. That's a feature for practice but not a fully realistic simulation.

## Configuration

All inputs are optional except level (which the wizard or a gap-fill prompt will ask for if missing).

| Input | Example | Notes |
|---|---|---|
| Level | `junior`, `senior`, `principal` | Required. |
| Stack | `Go`, `TS + React`, `Python + Postgres` | Required only for code-producing types. Defaults to stack-agnostic for architecture/design. |
| Type | `coding`, `architecture`, `debugging`, `code-review`, `refactor` | Optional; skill picks one if omitted. |
| Time budget | `30m`, `60m` | Optional; soft. |
| Extras | `"focus on concurrency"`, `"no frontend"` | Free-form constraints. |

## Files

- [`SKILL.md`](SKILL.md) — the skill definition. This is what Claude Code loads.

## Contributing

Improvements welcome. Areas where contributions would help:

- **Expand the shape-tag taxonomy** in `SKILL.md` to cover question types or domains the current list misses.
- **Add example sessions** to this README at levels not yet illustrated (lead, staff).
- **Test on other agentic clients** that support the Skills format and document any compatibility issues.

## License

MIT — see the [repo LICENSE](../../LICENSE).
