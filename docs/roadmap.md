# Boker Tov — Implementation Roadmap

> Rules: every step is small, testable, and leaves the bot working. Free tier (Gemini default). n8n does the deterministic work; LLM only where judgment is needed. Checkpoint at the end of each step.

**Current state:** Telegram → n8n → Gemini live. Sync layer + nightly git snapshots done. 4b done (bot reads `core/*.md` + `today.md` into system prompt).

---

## Phase 0 — Update the specs (Obsidian only, no server work)

- [x] **0.1** Rewrite `core/morning-flow.md` to the new spec: 10 free-text questions in the agreed order, no buttons, no branches, freeze mechanic, coach behavior, first-task ≤30min rule, timer-at-the-end.
- [x] **0.2** Update `core/identity.md`: add the dual mandate (push toward work / full permission to rest, wholeness not coercion). Remove the modes section. Add: never auto-start — always ask readiness. Add: not a therapist — refer to the therapist bot.
- [x] **0.3** Create `core/projects.md`: list your active projects, each with 2–4 lines of context (status, current focus).
- [x] **0.4** Remove `therapist/listener.md` and `therapist/focus.md` from the loaded set (keep the files parked if you want, but out of `core/`).
- [x] **0.5** Save `docs/features.md` and `docs/roadmap.md` (these two documents) into the repo.

**Checkpoint:** message the bot "מה אתה יודע עליי ועל הפרויקטים שלי" — it should answer from the updated files, mention the dual mandate tone, know your projects.

---

## Phase 1 — Memory: the bot stops forgetting (4c, dumb-simple version)

- [x] **1.1** n8n: after the Gemini node, an Execute Command node appends the exchange to `today.md` (`### [time]\nיהודה: ...\nבוקר טוב: ...`).
- [x] **1.2** Nightly cron (before the 03:00 git snapshot): if `today.md` is non-empty → move to `archive/YYYY-MM-DD.md`, create fresh empty `today.md`.
- [x] **1.3** Verify the archive gets committed by the existing git snapshot.

**Checkpoint:** chat with the bot, ask "מה אמרתי לך לפני שתי הודעות?" — it answers correctly. Next morning: yesterday's file is in `archive/` and on GitHub.

---

## Phase 2 — Session state

- [ ] **2.1** Define `state.json` schema: `{session_active, session_started_at, flow_position, frozen, current_task, timer, last_session_file}`.
- [ ] **2.2** n8n: a Code/Execute node reads `state.json` at the start of every message and routes: no active session → "new session" path; active → normal chat path.
- [ ] **2.3** New-session path: LLM-generated warm welcome (for now without the check-in — just the welcome), mark session active.
- [ ] **2.4** "End day" detection (user writes סיים יום / נגמר להיום): archive `today.md` → `archive/YYYY-MM-DD-sessionN.md`, update `last_session_file`, reset state, fresh `today.md`. Nightly cron becomes the fallback for unclosed sessions only.

**Checkpoint:** say hi → get a fresh welcome once. Chat. Say "סיים יום" → file lands in archive. Say hi again same day → new welcome, new session. The bot survives this cycle without breaking normal chat.

---

## Phase 3 — The morning check-in flow

- [ ] **3.1** Flow engine: `flow_position` in `state.json` tracks which question is next. n8n injects into the system prompt: the flow spec + current position + instruction "ask question N, respond as coach to the answer."
- [ ] **3.2** Wire questions 1–2 only (work window, ritalin). Log answers as structured lines in `today.md` (e.g., `window_end: 17:00`, `meds: no`).
- [ ] **3.3** Add questions 3–5 with the **freeze mechanic**: `frozen: true` in state, bot says the freeze line, any later message resumes at the same position. Parked items (Q5) logged as `parked: ...`.
- [ ] **3.4** Add questions 6–8 (project recognition from `projects.md`, first-task coaching + ≤30min rule, vague day list capture).
- [ ] **3.5** Add questions 9–10 (yesterday review from `last_session_file`, wholeness gate). Skip yesterday review gracefully if no last session exists.

**Checkpoint per sub-step:** run the flow for real one morning after each addition. The bot must complete the wired questions, log structured data, and fall back to normal chat afterwards. Freeze test: answer "עייף, לא יכול" mid-flow, walk away, come back — it resumes.

---

## Phase 4 — Timer + first task

- [ ] **4.1** Timer mechanism: on duration answer + readiness "כן" → write `timer: {task, minutes, started_at}` to state; a separate n8n Schedule workflow (every minute) checks state and fires the ping when time is up. (Simplest free-tier-safe approach; no long-running Wait nodes.)
- [ ] **4.2** Ping → "איך הולך? סיימת?" → LLM classifies the answer: done / extend (new estimate, restart timer) / stuck (coach).
- [ ] **4.3** Early finish: "סיימתי" while timer runs → cancel timer, celebrate.
- [ ] **4.4** Connect to flow end: question 11 (duration) closes the check-in and arms the first timer.

**Checkpoint:** full real morning — check-in → first task → timer fires → answer each of the three paths on different days. Also test early finish.

---

## Phase 5 — End-of-day block + digests + recall

- [ ] **5.1** End-of-day conversation (triggered by "סיים יום" or when the driven day reaches it): parked items → done-vs-planned → achievements → reflection → tomorrow items. Sequenced like a mini-flow via `flow_position`.
- [ ] **5.2** On archive: one Gemini call produces the structured digest header (summary, achievements, decisions, tomorrow-notes) written above the raw log. Silent-day cron does the same and adds "היום נקטע באמצע".
- [ ] **5.3** Welcome upgrade: new-session welcome references the last digest. Q9 (yesterday review) reads from the digest, delivered in small skippable chunks.
- [ ] **5.4** On-demand recall: intent detection ("תזכיר לי...") → Execute Command greps/reads archive digest headers → answer from them.

**Checkpoint:** end a real day → archive file has digest + raw log. Next session: welcome mentions yesterday, Q9 works, "מה עשינו לפני 3 ימים?" gets a real answer.

**🎉 Milestone: the full daily loop works without a calendar — morning to archive.**

---

## Phase 6 — Google Calendar

- [ ] **6.1** Google OAuth credential in n8n. Test: read today's events, bot can answer "מה יש לי היום ביומן?"
- [ ] **6.2** תכנון יום v1: after first task, bot reflects vague list + remaining window + existing meetings, collects durations, **proposes** the block plan in chat (no writing yet). You approve manually.
- [ ] **6.3** תכנון יום v2: on approval, bot writes the blocks + breaks + end-of-day block (30 min) into the calendar, around fixed meetings.
- [ ] **6.4** Driving the day: Schedule workflow watches the calendar; at each block start → announce + ask readiness → timer mechanic. Never auto-start.
- [ ] **6.5** Interruptions: pause timer / pause day commands; on return → reshuffle remaining blocks in the calendar. "End day" mid-day → jump to end-of-day block.

**Checkpoint per sub-step:** one real day per feature. Final test: a full driven day — meetings respected, breaks happen, an interruption reshuffles cleanly, end-of-day block runs on schedule.

---

## Later (parked)
- Claude Code layer
- ARM machine migration
- Therapist bot integration
- Multi-day recall improvements (semantic search over digests)
