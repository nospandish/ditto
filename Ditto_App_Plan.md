# Ditto App Plan

*A personal task scheduler for turning to-do lists into realistic daily plans*

**Working name:** Ditto  
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

- **Task capture:** Let the user enter a task name, due date, estimated duration, and importance: Optional, Can wait, or Must complete.
- **Available time:** Let the user choose the blocks of time they can work during the day.
- **Automatic schedule:** Create time blocks that prioritize urgent and important work while fitting inside the user's available hours.
- **Today view:** Show the planned agenda in a clean timeline that is easy to follow during the day.
- **Progress:** Let the user mark a task complete or ask Ditto to regenerate the remaining plan if the day changes.

## How the scheduling should work

### 1. Understand each task

Ditto collects the task name, deadline, estimated time, and importance. These details give the app enough information to decide which work needs attention first.

### 2. Respect the user's actual day

The schedule only uses time the user marks as available. It should avoid assuming that every free minute can be used for work.

### 3. Build an achievable order

Must complete tasks come first, followed by Can wait tasks and then Optional tasks. Longer work can be split into manageable sessions when helpful, and the app should leave room for breaks and unexpected changes.

### 4. Make changes easy

If the user finishes early, falls behind, or adds a new task, Ditto can rebuild the remaining schedule rather than making the user reorganize it manually.

### 5. Handle an impossible schedule honestly

If Must complete tasks do not fit inside the user's available time, Ditto first removes lower-priority tasks from the schedule. If the required tasks still cannot fit, Ditto does not create a schedule. It shows a clear warning, identifies the required work that could not fit, and suggests adding more available time.

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

**Data:** Store tasks and schedules locally for the MVP so the app is dependable during a live demo.

**Advanced features:** Fixed events, accounts, cloud sync, notifications, maps, camera features, and AI are not required for the first version. Fixed events can be added later so Ditto avoids scheduling tasks during work, school, appointments, or practices.

## Phase 1 progress

- [x] Define Ditto as a daily personal planner for anyone with tasks to organize.
- [x] Choose Android as the MVP platform.
- [x] Define task importance as Optional, Can wait, and Must complete.
- [x] Decide that Must complete tasks are scheduled first and lower-priority tasks are removed when necessary.
- [x] Decide that Ditto warns and does not create an impossible schedule when required tasks still cannot fit.
- [ ] Confirm whether Ditto is the final app name.

## Next decisions to confirm

**App name:** Decide whether Ditto is the final name.

**Schedule style:** Decide how much break time the app should include.

**Task duration:** Confirm whether every task must have an estimated duration.

**MVP screens:** Likely screens are Today, Add Task, Available Time, Generate Schedule, and Task Details.
