# Ditto App Roadmap

*A personal task scheduler for the Congressional App Challenge*

**Project:** Flutter app  
**Plan focus:** Phases 1-5  
**Date:** July 14, 2026

This roadmap breaks the Ditto project into clear build phases. The main goal is to create a reliable, demo-ready Android Flutter app that helps people turn tasks and available time into a realistic daily schedule.

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

## Phase 1: Decide the MVP

**Goal:** Make the idea clear enough to build.

### 1.1 Confirm the core idea

- Confirm Ditto as a daily personal planner.
- Confirm Ditto as the final app name.
- Define the main problem: people need help turning tasks into a realistic plan.
- Keep the first version focused on one-day planning instead of weekly or long-term planning.

### 1.2 Define the target user

- Design for anyone managing tasks, responsibilities, goals, and deadlines.
- Use broad language that works for school, work, personal tasks, and appointments.
- Keep the app simple enough to use in a few minutes each morning.

### 1.3 Choose the MVP promise

- Use this promise for the first build: enter tasks and free time, then get a realistic plan for today.
- Require each task to include a minimum and maximum time range.
- Use as much task time as possible, then squeeze tasks toward their minimum time if the schedule is crowded.
- Do not add automatic break time in the MVP.
- Avoid features that distract from the main scheduling flow.
- Make sure the MVP can be explained clearly in the Congressional App Challenge demo.

### 1.4 Confirm the first screens

- Today screen for the generated schedule.
- Tasks screen for saved tasks.
- Add Task screen for creating new tasks.
- Available Time screen for adding free work windows.
- Generate Plan flow for building the daily schedule.
- Do not include a separate Task Details screen in the MVP.

### 1.5 Decide technical scope

- Use Flutter and Dart as the main app stack.
- Start local-first so the demo does not depend on accounts, cloud sync, or internet access.
- Target Android only for the MVP.

### 1.6 Define success for the first review

- The user can understand the app purpose from the first screen.
- The team agrees on the MVP screens and first milestone.
- The project is ready for coding after explicit permission from the user.

## Phase 2: First demo version

**Goal:** Build the full basic app flow.

### 2.1 Project setup

- Create the Flutter project.
- Set the app name and package information.
- Add the basic folder structure.
- Set up the app theme.
- Confirm the app runs locally.

### 2.2 Navigation and layout

- Build the main app shell.
- Add bottom navigation or a simple page flow.
- Create placeholder screens for Today, Tasks, Available Time, Generate Plan, and Settings/About.

### 2.3 Task entry

- Add the task model.
- Build the Add Task screen.
- Let users enter task name, due date, minimum duration, maximum duration, and importance: Optional, Can wait, or Must complete.
- Show saved tasks in a task list.

### 2.4 Available time

- Add the available time block model.
- Build the Available Time screen.
- Let users add work windows, such as 4:00 PM-6:00 PM.
- Show and edit today's available time blocks.

### 2.5 Basic scheduling

- Create the first scheduling algorithm.
- Schedule Must complete tasks first, then Can wait tasks, then Optional tasks.
- Try to give each task as much time as possible, up to its maximum duration.
- Squeeze tasks toward their minimum duration when the schedule is crowded.
- Fit tasks into available time blocks.
- Move lower-priority tasks out of the schedule when required tasks need the time.
- If Must complete tasks still cannot fit, do not create a schedule; show a warning and suggest adding more available time.

### 2.6 Today timeline

- Show the generated schedule as a timeline.
- Display time, task name, duration, and priority.
- Highlight the next task.
- Add empty states for no tasks or no schedule.

### 2.7 Progress

- Let users mark scheduled tasks complete.
- Keep completed tasks visually separate.
- Add a regenerate plan button for remaining work.

## Phase 3: Make Ditto feel smart

**Goal:** Make the planner feel helpful and adaptive.

### 3.1 Better prioritization

- Improve task scoring using due date, importance, estimated duration, and overdue status.
- Show simple explanation text, such as "Scheduled first because it is due soon."

### 3.2 Task splitting

- Split long tasks into smaller work sessions.
- Add labels such as Part 1 and Part 2.
- Avoid giant schedule blocks that feel unrealistic.

### 3.3 Breaks and buffer time

- Add optional breaks between work blocks.
- Leave small gaps for transitions.
- Let users choose break length later.

### 3.4 Regenerate remaining day

- Rebuild the schedule from the current time onward.
- Keep completed tasks done.
- Move unfinished tasks into the remaining available time.

### 3.5 Smarter conflict handling

- Show tasks that could not fit.
- Suggest shortening, moving, or rescheduling tasks.
- Warn when the day is overloaded.

### 3.6 Local persistence

- Save tasks, time blocks, and schedules locally.
- Make sure data stays after closing the app.
- Keep demo data easy to reset.

## Phase 4: Polish for the challenge

**Goal:** Make the app impressive and easy to present.

### 4.1 Visual polish

- Improve colors, spacing, typography, and icons.
- Make the Today screen feel like the main product.
- Add polished cards, timeline markers, and status labels.

### 4.2 Demo flow

- Add sample tasks for the demo.
- Create a one-tap load demo day option.
- Make sure the app can demonstrate the full story quickly.

### 4.3 Edge cases

- Handle an empty task list.
- Handle no available time.
- Handle too many tasks.
- Handle a completed schedule.
- Handle invalid time ranges.

### 4.4 Testing and reliability

- Run Flutter analysis.
- Add basic tests for the scheduling algorithm.
- Test the app on the chosen platform.
- Fix layout issues on small screens.

### 4.5 Submission materials

- Prepare the app description.
- Prepare the feature list.
- Prepare the demo script.
- Capture screenshots.
- Outline the video story: problem, solution, demo, impact, and future improvements.

## Phase 5: Optional advanced features

**Goal:** Add these only after the MVP is strong.

### 5.1 Notifications

- Remind users before scheduled tasks.
- Add start-task and break reminders.
- Keep notifications optional.

### 5.2 Weekly planning

- Add a multi-day schedule view.
- Let unfinished tasks roll over.
- Support future due dates better.

### 5.3 Calendar integration

- Import busy time from a calendar.
- Avoid scheduling during events.
- Possibly export the generated plan.

### 5.4 AI assistance

- Suggest task durations.
- Rewrite vague tasks into clearer steps.
- Explain schedule choices in natural language.
- Help break big assignments into smaller tasks.

### 5.5 Accounts and cloud sync

- Add user accounts only if needed.
- Sync tasks across devices.
- Back up schedules.

### 5.6 Analytics and reflection

- Show completed work over time.
- Track planning accuracy.
- Help users learn how long tasks really take.

### 5.7 Sharing

- Let people share a plan with a parent, teacher, or study partner.
- Export a simple daily agenda.
- Keep privacy in mind.

## Recommended first milestone

Phase 1 decisions are complete. Build through Phase 2.7 next and pause for review. That creates a complete basic app before adding smarter behavior or advanced features.
