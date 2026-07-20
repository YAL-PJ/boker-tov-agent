# Boker Tov — Features Spec

> Status: agreed 2026-07-20. This is the "now" scope. Later: Claude Code layer, ARM migration, therapist-bot integration.

## Core principle — the dual mandate

The bot is a coach with two goals held at once:

1. **Push toward work** when there is desire — encouragement, momentum, structure.
2. **Full support and permission to rest** when there isn't — compassion, calm, legitimacy.

We work from wholeness and desire, never coercion. This principle filters every question and every response. It belongs in `core/identity.md`.

## Architecture decisions

- **No modes.** One bot, one coach personality, driven by flow state. Listener/focus modes are deleted.
- **Not a therapist.** Light emotional support is in scope — encouragement, compassion, simple techniques (breathing, a short break, slicing a task down). For a deeper emotional conversation or real difficulty the bot refers: "אתה רוצה להתייעץ עם המטפל שלך?" (separate bot; possible future integration).
- **All free text.** No Telegram buttons, no hardcoded branches. The coach prompt handles judgment. n8n handles the deterministic mechanics (state, timers, files, calendar).
- **Session-based, not date-based.** "אתמול" always means the *last session* — could be earlier today or a week ago. Archive unit is the session.
- **User always holds the trigger.** The bot never auto-starts a timer or a task. Every transition is an ask: "מוכן להתחיל?"

## The daily loop

### 1. Session start
- User initiates with any message ("היי", "בוקר טוב", anything).
- If this is the first contact of the session (no active session in `state.json`), the bot opens the check-in — regardless of the hour.
- Welcome: **LLM-generated**, short, warm, encouraging for the new day. Can reference the last session's summary.

### 2. Morning check-in — 10 questions, in order

All free text. Bot replies between questions are short LLM-generated acknowledgments, not fixed text. Answers are logged to `today.md`.

1. **השעה עכשיו [שעה] — עד מתי אתה יכול לעבוד היום?** → bot computes the work window, short acknowledgment.
2. **האם לקחת ריטלין?** → if no: ask why. If it's possible to take — brief encouragement. If not — acknowledge, note the day may look different. **Log "no meds today" to today.md** so the whole day's context knows.
3. **האם אתה עייף?** → if tired: ask if he can still work. Can't → legitimize rest, **freeze the flow**: "כתוב לי אם תרצה להמשיך היום." Maybe → suggest coffee / short walk, re-check. Can → acknowledge and factor into the plan. Not tired → great, move on.
4. **האם משהו יושב עליך רגשית?** → light emotional support in-flow (encouragement, compassion, simple techniques). Only a deeper emotional conversation → refer to the therapist bot. Freeze if needed.
5. **האם אתה באמצע משהו אחר? יש לך נושא לא סגור?** → two options offered: (a) finish it first → freeze: "אוקיי נעצור פה ותכתוב לי כשאתה מוכן להמשיך"; (b) park it → bot writes it down and **reminds at end of day**.
6. **על איזה פרויקט אתה עובד?** → free text; bot recognizes the project against `core/projects.md` and can pull its context.
7. **מה המשימה האחת הבאה שלך?** → coach behavior: if vague or big, sharpen into one concrete startable step. **Rule: first task ≤ 30 minutes** — bigger estimates get sliced down.
8. **אילו משימות אתה רוצה לעשות היום?** → capture only. A vague picture of the day. No shaping here — deep planning is its own task later.
9. **אתמול עשית X — רוצה לעבור על מה שהיה?** → "אתמול" = last session. If yes: walk the last-session summary in small responses. Skippable anytime ("תדלג על זה").
10. **אתה מוכן לעבוד מתוך הנאה? יש לך כח לזה?** → final wholeness gate. Intentionally overlaps Q4 — one clears blockers early, one confirms readiness at the end. Handled with the dual mandate.
11. **כמה זמן המשימה הראשונה תיקח?** → answer **starts the timer** (after a ready-check). The flow ends with the user working.

### 3. Timer mechanic (used all day)
- Bot asks "מוכן להתחיל?" → yes → timer runs for the estimate.
- **Timer fires** → "איך הולך? סיימת?"
  - Done → brief celebration → next block.
  - Not done → new estimate, timer restarts.
  - Stuck → coach: unstick, maybe re-slice.
- **Early finish**: user messages "סיימתי" anytime → cancel timer, celebrate, move on.

### 4. תכנון יום (built-in second task, after the first task)
- Bot reflects the vague day list + remaining work window.
- User writes today's tasks — one chunk or one-by-one.
- Bot ensures every task has a duration (asks if missing).
- Bot **reads the real Google Calendar** — existing meetings are fixed blocks.
- Bot builds the day in Google Calendar around them: tasks **plus breaks**, inside the work window.
- Bot manages and edits the calendar as things shift.

### 5. Driving the day
- Bot announces each calendar block, asks readiness, runs the timer, same done/extend/stuck mechanic. Breaks announced too.
- **Interruptions**: user can pause a timer or pause the day. On return → calendar reshuffles around what's left.
- **End day**: user can end the day anytime → end-of-day block runs → later he can start fresh as a new session, even the same calendar day.

### 6. End-of-day block (~30 min, scheduled in the calendar, bot-driven)
1. Parked items from Q5 — "מה עושים עם X?"
2. Done-vs-planned summary.
3. Achievements review — go over the wins explicitly.
4. Reflection — "איך היה היום?" (free conversation).
5. Anything for tomorrow — captured, feeds the next session's welcome and Q9.
6. **Archive**: full session chat saved to `archive/`, with a structured LLM-generated digest header (summary, decisions, tomorrow-notes) above the raw log.

### 7. Silent-day fallback
If the session never closes (user disappears), nightly cron summarizes whatever happened, archives it, and the digest notes the day ended off-pattern ("היום נקטע באמצע").

## On-demand recall
Anytime, any point: "תזכיר לי מה עשינו אתמול" or any question against the bot's files (archive digests, core, projects). Digest headers make multi-file recall feasible on free tier — the bot searches digests, not full logs.

## Files
| File | Role |
|---|---|
| `core/identity.md` | Persona + dual mandate. Loaded every message. |
| `core/morning-flow.md` | This flow spec (rewrite from the old buttons version). |
| `core/projects.md` | Project list + context. Maintained in Obsidian. |
| `core/about-me.md` | Personal background. |
| `today.md` | Current session log. |
| `state.json` | Session state: active/frozen, flow position, current task, timer, last-session pointer. |
| `archive/YYYY-MM-DD-sessionN.md` | Digest header + raw log per session. |

## Out of scope (later)
- Claude Code layer
- ARM migration
- Therapist bot integration
- Listener / focus modes (deleted, absorbed into the coach)
