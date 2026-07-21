# Boker Tov Bot — Verification & Testing Checklist

Use this manual test protocol to verify that all features of the Boker Tov Telegram bot are functioning properly.

---

## 1. New Session & Greeting Test
- [ ] **Test**: Send `"היי"` or `"בוקר טוב"` to the Telegram bot.
- [ ] **Expected**:
  - Bot responds with a warm, brief, LLM-generated welcome message.
  - If a previous session digest exists, the welcome briefly mentions context from the last session.
  - Bot initiates Question 1 of the morning check-in: *"עד מתי אתה יכול לעבוד היום?"*

---

## 2. Work Window Validation (Question 1)
- [ ] **Test A (Invalid input)**: Reply with invalid time format like `"117"` or `"25:00"`.
  - **Expected**: Bot gently asks for clarification without advancing to Q2.
- [ ] **Test B (Valid input)**: Reply with `"17:30"`.
  - **Expected**: Bot acknowledges the work window, logs `window_end=17:30` to `today.md`, and moves to Q2 (Ritalin).

---

## 3. Ritalin & Health Check (Question 2)
- [ ] **Test**: Reply `"לא לקחתי"`.
  - **Expected**: Bot asks why or acknowledges gently, logs `meds=no` to `today.md`, and advances to Q3 (Tiredness).

---

## 4. Freeze Mechanic Test (Question 3 / 4 / 5)
- [ ] **Test A (Trigger Freeze)**: When asked *"האם אתה עייף?"*, reply `"עייף מאוד, לא יכול לעבוד עכשיו"`.
  - **Expected**:
    - Bot gives full permission to rest and says *"כתוב לי אם תרצה להמשיך היום"*.
    - Bot sets `frozen: true` in `state.json` and does NOT ask Q4.
- [ ] **Test B (Unfreeze / Resume)**: Send any message later (e.g., `"אני מוכן להמשיך"`).
  - **Expected**: Bot welcomes you back and resumes at Question 3 without resetting to Question 1.

---

## 5. Parked Items (Question 5)
- [ ] **Test**: When asked about open topics, reply `"צריך לשלם חשמל, ניקח את זה כנושא לא סגור"`.
  - **Expected**: Bot offers option to handle now or park it. If parked, logs `parked=לשלם חשמל` to `today.md`.

---

## 6. Project Recognition & First Task (Questions 6 & 7)
- [ ] **Test A (Project)**: When asked about the project, mention a project from `core/projects.md` (e.g. `"עובד על בוקר טוב"`).
  - **Expected**: Bot recognizes the project context and moves to Q7.
- [ ] **Test B (≤30 Min Rule)**: When asked for the first task, estimate 2 hours (e.g., `"לכתוב את כל הקוד לבוט"`).
  - **Expected**: Bot acts as coach and asks you to slice it down to a single step taking ≤30 minutes.

---

## 7. Timer Mechanics & Early Finish (Question 11)
- [ ] **Test A (Arm Timer)**: Enter `"10 דקות"` and confirm `"כן מוכן"`.
  - **Expected**: `state.json` receives active timer data structure with `started_at` and `ends_at`.
- [ ] **Test B (Timer Ping)**: Wait for timer duration or trigger cron check.
  - **Expected**: Bot pings *"⏰ הטיימר למשימה... הסתיים! איך הולך? סיימת?"*.
- [ ] **Test C (Early Finish)**: While timer is running, send `"סיימתי"`.
  - **Expected**: Bot cancels active timer (`timer_cancel`), celebrates briefly, and asks for the next step.

---

## 8. End of Day & Archiving ("סיים יום")
- [ ] **Test**: Send `"סיים יום"` or `"נגמר להיום"`.
  - **Expected**:
    - Bot generates a structured Hebrew digest header (`## סיכום`, `## הישגים`, `## החלטות`, `## הערות למחר`).
    - Raw log from `today.md` is archived to `archive/YYYY-MM-DD-sessionN.md`.
    - `today.md` is reset to fresh empty state.
    - Bot sends confirmation: *"הסשן נסגר ונשמר בארכיון. נתראה בסשן הבא 👋"*.

---

## 9. On-Demand Recall
- [ ] **Test**: In a new session, ask `"תזכיר לי מה עשינו בסשן הקודם?"`.
  - **Expected**: Bot reads the last archive digest header and summarizes past achievements and notes accurately.

---

## 10. Google Calendar Integration
- [ ] **Test**: Ask `"מה יש לי היום ביומן?"`.
  - **Expected**: Bot reads today's events via the Google Calendar node and lists them.
