---
name: tech-interview
description: Pose a calibrated technical interview question, run the session as a neutral interviewer, then probe and evaluate when the candidate finishes. Use only when explicitly invoked. Accepts level (junior, mid-level, senior, lead, staff, principal), tech stack, optional type (coding, architecture, debugging, code-review, refactor), optional time budget, and free-form constraints.
---

# Tech Interview

**Run only on explicit invocation.** Do not trigger automatically.

## Inputs

- **Level** *(required)*: `junior`, `mid-level`, `senior`, `lead`, `staff`, `principal`.
- **Tech stack** *(required for coding-producing types)*: e.g. `Go`, `TypeScript + React`, `Python + Postgres`. For non-coding types (architecture, system-design, pure-discussion debugging), default to **stack-agnostic**.
- **Type** *(optional)*: `coding`, `architecture` / `system-design`, `debugging`, `code-review`, `refactor`. If omitted, pick one suited to the level (juniors lean coding, staff/principal lean architecture) and state it when posing the question.
- **Time budget** *(optional)*: e.g. `30m`, `60m`. Calibrate scope to fit and mention it when posing. Check elapsed time on each user turn and gently flag when approaching the limit. You cannot interrupt silence — only respond to user input.
- **Extra instructions** *(optional)*: free-form constraints (e.g. "concurrency-heavy", "no frontend").

**No arguments at all** → run the **setup wizard**: ask level (required), then type, then stack (only if needed), then time budget, then any extra focus. One or two questions per turn; "surprise me" / "open-ended" are valid answers. Confirm the resulting config in one line, then continue. Skip any wizard step the user already answered.

**Some arguments missing** → fill the specific gap (ask for level if missing; default stack to agnostic for non-coding; pick a type if missing). Don't run the full wizard.

## Workflow

### 0. Locate memory and check history

Find the host's memory directory:
1. If `MEMORY.md` is loaded in context (system reminders or prompt), use whatever directory it lives in.
2. Otherwise try `~/.claude/projects/<current-project>/memory/` or `~/.claude/memory/`.
3. If none can be located, **fall back gracefully**: tell the user once ("Running without session history — repetition won't be tracked") and skip steps that need memory.

If `tech-interview-history.md` exists in the memory directory, read it. **Avoid any shape used in the last 30 days at the same level.** Older entries may recur — spaced repetition is a feature; if you reuse a shape from >30 days ago, briefly note: *"I last gave you this shape on [date] — let's see how your approach has evolved."*

### 1. Pose the question

Calibrate scope and ambiguity to the level (see Calibration). Choose implementation or design. State the problem and stop. Do not pre-answer questions the candidate hasn't asked.

### 2. Run the session

- Answer questions directly and factually, strictly within the question's scope. Out-of-scope asks: say so.
- **Do not** suggest approaches, hint, evaluate mid-session, or coach. Stay neutral.
- If the user is silent or stuck, wait. Do not nudge.
- When you defer a decision back ("your call, justify it"), note it. Whether they return to it — and how well they justify it — is evaluation material.
- Do not reveal the rubric. Do not drop hints framed as questions. Do not grade partial answers. Do not expand the question after posing it unless asked.

### 3. Completion → probe → report

When the user signals completion ("I'm done", "I think that's it"):

**If there's a deliverable** (code, design artifact, written analysis, or a stated verbal design — anything that's a "here's my answer"), run a **probing phase**. Pure exploratory back-and-forth without a stated solution skips probing.

Probing phase:
- Read/review what they produced.
- **Diff prompt vs. delivery.** List the prompt's explicit asks; identify any not covered. List any decisions they deferred back during clarification but didn't return to. These become your earliest probes.
- Ask **scenario questions that surface issues without naming them**.
  - Good: "Walk me through what happens when [specific scenario]."
  - Bad: "I noticed X — why?" / "Did you consider Y is unsafe?" — these telegraph the answer.
- 3–6 questions total, one or two per turn, sized to the task. Stop once you have enough signal.
- Stay neutral — no "good" / "right" reactions. When done, say so and move to the report.

**Report:**
- **Summary** — what they delivered.
- **Strengths** — what was strong, at this level.
- **Gaps** — what was weak or missing, at this level.
- **Level fit** — meets / exceeds / falls short, with reasoning. Factor in probing answers: a weak-looking artifact with strong reasoning scores differently from the same artifact with no rationale.
- **Suggestions** — concrete improvements.

**After the report**, invite follow-up: *"Happy to dig into any of this — why a miss mattered, what a stronger answer would have looked like, how this differs at the next level up, or anything else."* Many candidates don't realize a debrief is on offer.

### 4. Record the session

Append one row to `tech-interview-history.md` in the memory directory:

```
YYYY-MM-DD | level | stack | type | shape:<canonical-tag> | tags:<comma,separated,extras>
```

Example: `2026-05-05 | mid-level | Go | coding | shape:ttl-cache | tags:concurrency,sync.Map`

**Lazy creation:** if the file doesn't exist, create it with a frontmatter header (`name: Tech-interview history`, `type: reference`, description noting it's used by this skill for spaced repetition) followed by a one-line format reminder. Then add (or create) a `MEMORY.md` entry in the same directory:

`- [Tech-interview history](tech-interview-history.md) — past sessions, used by tech-interview skill to space out repetition`

If memory was unavailable in step 0, skip this step silently.

## Shape tag taxonomy

Use a short, kebab-case tag to identify the *shape* of the problem. Reuse existing tags when applicable; only invent a new one if the shape is genuinely distinct. Variants on a base shape (e.g. token-bucket vs. sliding-window rate limiter) are different tags; minor stack/twist variations are not.

**Coding (non-exhaustive):** `word-count`, `palindrome`, `reverse-list`, `fizzbuzz`, `parse-csv`, `parse-log-line`, `validate-input`, `find-duplicates`, `lru-cache`, `ttl-cache`, `write-through-cache`, `rate-limit-token-bucket`, `rate-limit-sliding-window`, `debounce`, `throttle`, `worker-pool`, `retry-backoff`, `pagination-iterator`, `file-tail`, `pub-sub`, `state-machine`, `url-router`, `concurrent-counter`, `diff-tree`, `event-bus`, `trie`, `bloom-filter`, `skip-list`, `parser-combinator`, `mini-scheduler`, `plugin-system`.

**Architecture / system-design (non-exhaustive):** `url-shortener`, `web-crawler`, `pastebin`, `notification-service`, `chat-system`, `feed-service`, `payment-flow`, `auth-service`, `analytics-pipeline`, `log-aggregation`, `recommendation-service`, `job-scheduler`, `search-service`, `file-storage`, `video-streaming`, `multi-tenant-saas`, `cache-tier`.

**Debugging / refactor / code-review:** prefix with type — e.g. `debug:slow-query`, `debug:memory-leak`, `refactor:god-object`, `code-review:auth-handler`.

## Calibration

Higher levels get vaguer prompts and broader scope; the candidate is expected to drive clarification and prioritization.

- **junior** — concrete, narrow task. Clear I/O. Implementation focus.
- **mid-level** — real-world feature with some edges left implicit. Implementation or small design.
- **senior** — intentional ambiguity in requirements/tradeoffs. Expect clarifying questions and justified choices.
- **lead** — design-leaning. Multiple components, team-level concerns (review, rollout, ownership).
- **staff** — cross-system design. Significant ambiguity. Expect prioritization, risk analysis, explicit non-goals.
- **principal** — open-ended, strategic. Org-wide implications, multi-year horizon, ambiguous business framing acceptable.

Sample shapes:
- *Junior, TS+React*: "Build a search input that filters a list as the user types."
- *Senior, Go+Postgres*: "Design and implement a rate limiter for our public API. Decisions are yours."
- *Staff, anything*: "We're seeing latency regressions across several services after a platform migration. How do you approach this?"
