# Ditto App Plan

*A student-first task scheduler for turning to-do lists into realistic daily plans*

**Working name:** Ditto  
**Project:** Flutter app for the Congressional App Challenge  
**Plan stage:** Early MVP concept  
**Date:** July 14, 2026

## Vision

**Ditto helps students turn a list of assignments, chores, and goals into an achievable schedule.** Instead of deciding when every task should happen, the user gives Ditto the task details and available time; Ditto creates a clear plan for the day.

## The problem

Students often know what they need to do but have trouble deciding what to start, how long to spend on it, and how to fit everything into a busy day. A long to-do list can feel stressful because it does not show a realistic order or time to work.

## Target users

The first audience is busy high school students managing homework, extracurricular activities, personal tasks, and deadlines. The design should stay simple enough for a student to use in a few minutes each morning.

## MVP: the first useful version

The MVP should focus on one useful promise: after entering tasks and free time, a student gets a realistic plan for today.

- **Task capture:** Let the user enter a task name, due date, estimated duration, and importance.
- **Available time:** Let the user choose the blocks of time they can work during the day.
- **Automatic schedule:** Create time blocks that prioritize urgent and important work while fitting inside the user's available hours.
- **Today view:** Show the planned agenda in a clean timeline that is easy to follow during the day.
- **Progress:** Let the user mark a task complete or ask Ditto to regenerate the remaining plan if the day changes.

## How the scheduling should work

### 1. Understand each task

Ditto collects the task name, deadline, estimated time, and importance. These details give the app enough information to decide which work needs attention first.

### 2. Respect the student's actual day

The schedule only uses time the student marks as available. It should avoid assuming that every free minute can be used for work.

### 3. Build an achievable order

Near deadlines and high-priority tasks come first. Longer work can be split into manageable sessions when helpful, and the app should leave room for breaks and unexpected changes.

### 4. Make changes easy

If the user finishes early, falls behind, or adds a new task, Ditto can rebuild the remaining schedule rather than making the student reorganize it manually.

## Simple user flow

1. **Open Ditto:** The student sees today's plan or starts a new one.
2. **Add tasks:** The student enters what needs to be done and how long it may take.
3. **Set free time:** The student identifies the hours they are actually available.
4. **Generate plan:** Ditto creates a time-blocked agenda for the day.
5. **Follow and adjust:** The student completes tasks or regenerates the plan when their day changes.

## Experience principles

- **Feel immediately useful:** The first screen should show a schedule or a clear path to make one, not a marketing page.
- **Keep choices understandable:** Every recommendation should have a simple reason, such as an upcoming deadline or a high importance level.
- **Avoid pressure:** The app should make the day feel manageable, not punish users for an unfinished plan.
- **Stay demo-friendly:** The main flow must work smoothly with local data and without requiring accounts or an internet connection.

## Initial product decisions

**Planning scope:** Start with a one-day schedule. Weekly planning can become a later feature once the daily flow works well.

**Data:** Store tasks and schedules locally for the MVP so the app is dependable during a live demo.

**Advanced features:** Accounts, cloud sync, notifications, maps, camera features, and AI are not required for the first version.

## Next decisions to confirm

**App name:** Decide whether Ditto is the final name.

**Schedule style:** Confirm the daily-first approach and decide how much break time the app should include.

**Platforms:** Choose whether the first demo should target Android, iOS, web, or more than one platform.

**MVP screens:** Likely screens are Today, Add Task, Available Time, Generate Schedule, and Task Details.
