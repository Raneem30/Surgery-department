# Surgery Department

## Project Overview
A specialized database for the Surgery Department. Manages surgical cases, OR scheduling with overlap prevention, surgical teams, appointments, payments, and patient records.

---

## Phase 1: Database Design & Implementation 

### Deliverable 1: Database Plan

| File | Description |
|------|-------------|
| `docs/erd/plan.md` | Comprehensive database plan — 20 tables, attributes, domains, keys, constraints, relationships, completeness constraints, functional requirements, normalization |
| `docs/erd/keys_table.md` | PK/FK reference — all primary keys, foreign keys, composite keys, unique constraints, and indexes |

**Entities (20 tables):**
- **Core & Location:** Patient (with embedded vitals), Hospital, Geo_Location, Department, Department_Location
- **Personnel:** Doctor
- **Clinical:** Treats, Prescription, Medication, Prescription_Medication, Scan_Document
- **Scheduling & Finance:** Appointment, Payment, Contact_Inquiry
- **Access:** User
- **Facilities:** Room (enhanced for Surgery — OR rooms)
- **Surgery:** Surgical_Procedure, Surgery_Case, Surgery_Schedule (with OR overlap prevention), Surgical_Team_Assignment

### Deliverable 2: SQL Implementation

| File | Description |
|------|-------------|
| `sql/schema.sql` | DDL — 20 CREATE TABLE statements, CHECK/FK/UNIQUE constraints, `EXCLUDE USING gist` for OR overlap prevention, 28 indexes |
| `sql/seed.sql` | Realistic seed data — hospitals, geo locations, departments, doctors, patients (with vitals), medications, prescriptions, rooms, procedures (CPT codes), surgery cases, schedules, team assignments, appointments, payments, users, contact inquiries, scan documents |
| `sql/queries.sql` | 10 surgery-specific queries — daily OR schedule, surgeries by status, OR utilization, doctor workload, procedure duration vs standard, cancelled surgeries, team role distribution, OR turnaround time, patient payment history, upcoming appointments |

### Key Features
- **OR Overlap Prevention** — `EXCLUDE USING gist (or_room_id WITH =, tstzrange(scheduled_start, scheduled_end) WITH &&)`
- **Patient Vitals Embedded** — blood pressure, heart rate, temperature, SpO2 stored directly in Patient table
- **Peri-operative Workflow** — Surgery_Case status pipeline (scheduled → pre_op → in_or → in_pacu → completed)
- **Payment Lifecycle** — Register/pay/refund per appointment
- **Role-based Access** — User table with admin/doctor/nurse/staff roles

---

## Phase 2: Application Features & Presentation

### Tech Stack
- **Backend:** Spring Boot (Java)
- **Database:** PostgreSQL (with btree_gist extension)
- **Frontend:** Thymeleaf or React (TBD)
- **Build Tool:** Maven

### Presentation
- Schema walkthrough (20 tables, 28 indexes, exclusion constraint)
- Key surgery queries demonstration
- OR scheduling with overlap prevention explanation
