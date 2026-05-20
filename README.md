# Surgery Department

## Project Overview
A specialized database for the Surgery Department. Manages surgical cases, OR scheduling with overlap prevention, surgical teams, appointments, payments, patient records, post-anesthesia care (PACU), and surgical safety counts.

---

## Database Plan

| File | Description |
|------|-------------|
| `docs/erd/plan.md` | Comprehensive database plan — 20 tables, attributes, domains, keys, constraints, relationships, completeness constraints, functional requirements, normalization |
| `docs/erd/keys_table.md` | PK/FK reference — all primary keys, foreign keys, composite keys, unique constraints, and indexes |

**Entities (20 base tables + 2 added tables):**
- **Core & Location:** Patient (with embedded vitals), Hospital, Geo_Location, Department, Department_Location
- **Personnel:** Doctor
- **Clinical:** Treats, Prescription, Medication, Prescription_Medication, Scan_Document
- **Scheduling & Finance:** Appointment, Payment, Contact_Inquiry
- **Access:** User_Account
- **Facilities:** Room (enhanced for Surgery — OR rooms)
- **Surgery:** Surgical_Procedure, Surgery_Case, Surgery_Schedule (with OR overlap prevention), Surgical_Team_Assignment
- **Post-Operative:** PACU_Record, Surgical_Count

---

## Deliverables (6 Files)

| File | Description |
|------|-------------|
| `sql/schema.sql` | PostgreSQL DDL — 22 CREATE TABLE statements, CHECK/FK/UNIQUE constraints, `EXCLUDE USING gist` for OR overlap prevention, 28 indexes |
| `sql/seed.sql` | Realistic seed data — hospital, geo locations, departments, 3 doctors, 5 patients (with vitals), medications, prescriptions, rooms, procedures, surgery cases, schedule, team assignments, 5 appointments, 3 payments, 4 users, contact inquiries, scan documents, PACU record, surgical count |
| `sql/queries.sql` | 65 parameterized queries covering all 43 role‑based functions — Patient (12), Doctor (11), Admin (11), Nurse (9), plus CRUD sub‑operations |
| `sql/query.md` | Documentation table listing every query number, name, purpose, parameters, return columns, and role |
| `streamlit_app.py` | Full Streamlit UI — login with 4 roles, role‑based sidebar navigation, all 43 functions as pages, file uploads to `./uploads/`, plotly charts for admin reports, Test Query tab for running any query |
| `requirements.txt` | streamlit, pandas, plotly |

---

## Quick Start

```bash
pip install -r requirements.txt
streamlit run streamlit_app.py
```

The app will create a local `surgery.db` (SQLite) with the schema and seed data on first run.

### Default Logins

| Username | Password | Role | Linked To |
|----------|----------|------|-----------|
| admin | admin | admin | — |
| doctor | doctor | doctor | Ahmed Ali (cardiac surgeon) |
| patient | patient | patient | Omar Farouk (P001) |
| nurse | nurse | staff | — |

---

## Key Features

- **OR Overlap Prevention** — `EXCLUDE USING gist (or_room_id WITH =, tsrange(scheduled_start, scheduled_end) WITH &&)` (PostgreSQL)
- **Patient Vitals Embedded** — blood pressure, heart rate, temperature, SpO2 stored directly in Patient table
- **Peri-operative Workflow** — Surgery_Case status pipeline (scheduled → pre_op → in_or → in_pacu → completed)
- **Payment Lifecycle** — Pay/refund per appointment
- **Role-based Access** — User_Account table with admin/doctor/staff/patient roles
- **PACU Tracking** — Aldrete score, pain score, complications
- **Surgical Safety Counts** — Sponge, needle, and instrument counts with verification
- **Test Query Tab** — Select any query from `queries.sql`, view its SQL, and execute it with custom parameters

---

## Architecture

### PostgreSQL (via run.sh)

```bash
./run.sh                  # Create DB → schema → seed → run Streamlit
./run.sh --seed-only      # Create DB → schema → seed (stop)
./run.sh --app-only       # Run Streamlit (assumes DB ready)
./run.sh --reset          # Drop & recreate → full
```

### SQLite (via streamlit_app.py directly)

The Streamlit app defaults to SQLite (built-in). Schema and seed data are embedded in the app for zero-config startup.

---

## Role-Based Functions

| Role | Functions |
|------|-----------|
| **Patient** | Login, profile, doctors, appointments, book/cancel appointment, pay, payment history, prescriptions, scans, contact inquiry, nearest hospital |
| **Doctor** | Login, profile, appointments, patients, patient details, write prescription, schedule/cancel appointment, upload scan, reserve room, surgery schedule |
| **Admin** | Login, dashboard, CRUD all entities, view appointments (filtered), payments/revenue, contact inquiries, 4 reports with charts |
| **Nurse (staff)** | Login, OR schedule, surgery cases by status, assign team, update case status, patient vitals, PACU record, surgical count, room availability |
