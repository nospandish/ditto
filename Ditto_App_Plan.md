# Ditto App Plan

*A personal task scheduler for turning to-do lists into realistic daily plans*

**App name:** Ditto  
**Project:** Android Flutter app for the Congressional App Challenge
**Plan stage:** Early MVP concept  
**Date:** July 14, 2026

## Vision

**Ditto helps people turn a list of tasks, responsibilities, and goals into an achievable schedule.** Instead of deciding when every task should happen, the user gives Ditto the task details and available time; Ditto creates a clear plan for the day.

## The problem

People often know what they need to do but have trouble deciding what to start, how long to spend on it, and how to fit everything into a busy day. A long to-do list can feel stressful because it does not show a realistic order or time to work.

## Target users

Ditto is for anyone who wants help organizing tasks and making a realistic daily plan. The design should stay simple enough for a person to use in a few minutes each morning.

## MVP: the first useful version

The MVP should focus on one useful promise: after entering tasks and free time, a person gets a realistic plan for today.

- **Task capture:** Let the user enter a task name, due date, required time range, and importance: Optional, Can wait, or Must complete.
- **Available time:** Let the user choose the blocks of time they can work during the day.
- **Automatic schedule:** Create time blocks that prioritize urgent and important work while fitting inside the user's available hours.
- **Today view:** Show the planned agenda in a clean timeline that is easy to follow during the day.
- **Progress:** Let the user mark a task complete or ask Ditto to regenerate the remaining plan if the day changes.

## How the scheduling should work

### 1. Understand each task

Ditto collects the task name, deadline, required time range, and importance. Each task must include a minimum and maximum amount of time. These details give the app enough information to decide which work needs attention first and how much the task can be adjusted.

### 2. Respect the user's actual day

The schedule only uses time the user marks as available. It should avoid assuming that every free minute can be used for work.

### 3. Build an achievable order

Must complete tasks come first, followed by Can wait tasks and then Optional tasks. Ditto should try to give each scheduled task as much time as possible, up to its maximum time. If the day is too full, Ditto can squeeze a task down toward its minimum time so higher-priority work still fits. Longer work can be split into manageable sessions when helpful.

### 4. Make changes easy

If the user finishes early, falls behind, or adds a new task, Ditto can rebuild the remaining schedule rather than making the user reorganize it manually.

### 5. Handle an impossible schedule honestly

If Must complete tasks do not fit inside the user's available time, Ditto first removes lower-priority tasks from the schedule and reduces scheduled tasks toward their minimum time. If the required tasks still cannot fit, Ditto does not create a schedule. It shows a clear warning, identifies the required work that could not fit, and suggests adding more available time.

### 6. Use task time ranges

Every task must include a minimum and maximum time estimate. For example, a task could need 30-60 minutes. Ditto should use as much time as possible when the day has room, but it can reduce the task toward 30 minutes if the schedule is crowded. If even the minimum time cannot fit for required work, Ditto should warn the user instead of creating an unrealistic plan.

## Simple user flow

1. **Open Ditto:** The user sees today's plan or starts a new one.
2. **Add tasks:** The user enters what needs to be done and how long it may take.
3. **Set free time:** The user identifies the hours they are actually available.
4. **Generate plan:** Ditto creates a time-blocked agenda for the day.
5. **Follow and adjust:** The user completes tasks or regenerates the plan when their day changes.

## Experience principles

- **Feel immediately useful:** The first screen should show a schedule or a clear path to make one, not a marketing page.
- **Keep choices understandable:** Every recommendation should have a simple reason, such as an upcoming deadline or a high importance level.
- **Avoid pressure:** The app should make the day feel manageable, not punish users for an unfinished plan.
- **Stay demo-friendly:** The main flow must work smoothly with local data and without requiring accounts or an internet connection.

## Initial product decisions

**Planning scope:** Start with a one-day schedule. Weekly planning can become a later feature once the daily flow works well.

**Platform:** Build the MVP for Android only.

**Task duration:** Every task must include a time range with a minimum and maximum duration.

**Breaks:** Do not add automatic break time in the MVP.

**MVP screens:** Build Today, Tasks, Add Task, Available Time, and Generate Plan. Do not build a separate Task Details screen for the first version.

**Data:** Store tasks and schedules locally for the MVP so the app is dependable during a live demo.

**Advanced features:** Fixed events, accounts, cloud sync, notifications, maps, camera features, and AI are not required for the first version. Fixed events can be added later so Ditto avoids scheduling tasks during work, school, appointments, or practices.

## Phase 1 progress

- [x] Define Ditto as a daily personal planner for anyone with tasks to organize.
- [x] Choose Android as the MVP platform.
- [x] Define task importance as Optional, Can wait, and Must complete.
- [x] Decide that Must complete tasks are scheduled first and lower-priority tasks are removed when necessary.
- [x] Decide that Ditto warns and does not create an impossible schedule when required tasks still cannot fit.
- [x] Confirm Ditto as the final app name.
- [x] Require every task to include a minimum and maximum time range.
- [x] Decide that Ditto should use as much task time as possible, then squeeze tasks toward minimum time when needed.
- [x] Decide that the MVP will not include automatic break time.
- [x] Confirm MVP screens: Today, Tasks, Add Task, Available Time, and Generate Plan.
- [x] Remove a separate Task Details screen from the MVP.

## Next decisions to confirm

Phase 1 decisions are complete. The next step is to begin Phase 2 after the user gives explicit permission to start coding.
