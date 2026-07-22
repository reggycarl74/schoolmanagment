# School Management System

A Rails 8 modular monolith for running a school. The initial domain covers academic calendars, classrooms, students and guardians, staff, enrollment, subjects, attendance, assessments, and grades.

## Stack

- Ruby 3.4 and Rails 8
- MySQL 8 using `mysql2` and full `utf8mb4` support
- Server-rendered ERB with Turbo and Stimulus
- Tailwind CSS
- Solid Queue, Solid Cache, and Solid Cable

## Setup

Prerequisites: Ruby 3.4+, MySQL 8+, and a working C compiler/MySQL client library for `mysql2`.

```sh
bundle install
DB_USERNAME=root DB_PASSWORD=your_password bin/rails db:prepare
DB_USERNAME=root DB_PASSWORD=your_password bin/rails db:seed
bin/dev
```

Database settings can be supplied with `DB_HOST`, `DB_PORT`, `DB_USERNAME`, `DB_PASSWORD`, and `DB_NAME`.

Demo seed accounts use school code `DEMO`. The administrator is `admin@example.test` / `ChangeMe123!`. Teacher accounts use the emails in `db/seeds/demo_school.rb` and password `Teacher123!`. Override these defaults with `ADMIN_PASSWORD` and `TEACHER_PASSWORD` when seeding.

Parent portal: `parent1@example.test` / `Parent123!`. Student portal: `student@example.test` / `Student123!`. Override with `PARENT_PASSWORD` and `STUDENT_PASSWORD` when seeding.

## Included modules

Role-scoped portals, admissions and promotion, bulk attendance, configurable assessments, approval and publishing, bulk result entry, report cards, lesson notes, timetable, announcements, billing and payments, student documents, and audit history.

See [docs/architecture.md](docs/architecture.md) for the frontend decision and schema explanation.
