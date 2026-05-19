# Surgery Department

## Project Overview
A specialized database for the Surgery Department. Manages surgical cases, OR scheduling with overlap prevention, surgical teams, intraoperative events, implants, specimens, PACU recovery, and safety counts.

---

## Phase 1: Database Design & Implementation 

### Deliverable 1: Database Plan

| File | Description |
|------|-------------|
| `docs/erd/plan.md` | Comprehensive database plan — 25 tables, attributes, domains, keys, constraints, relationships, completeness constraints, functional requirements, normalization |
| `docs/erd/ERD.puml` | Original PlantUML ERD (legacy) |
| `docs/erd/keys_table.md` | PK/FK reference — all primary keys, foreign keys, composite keys, unique constraints, and indexes |

**Entities (25 tables):**
- **Core:** Patient, Hospital, Department, Department_Location, Staff (replaces Doctor)
- **Clinical:** Treats, Prescription, Medication, Prescription_Medication, Vital_Sign, Admission, Scan_Document
- **Surgery:** Surgical_Procedure, Surgery_Case, Surgery_Schedule, Surgical_Team_Assignment, IntraOp_Event, IntraOp_Medication
- **Peri-op:** Specimen, Implant_Device, PACU_Record, Surgical_Count, Surgery_Audit_Log
- **Clinic:** Clinic_Appointment (pre-op/post-op visits)

**Removed (general clinic tables):** Geo_Location, Contact_Inquiry, User, Payment, Appointment (renamed), Doctor (replaced by Staff)

### Deliverable 2: SQL Implementation

| File | Description |
|------|-------------|
| `sql/schema.sql` | DDL — 25 CREATE TABLE statements, CHECK/FK/UNIQUE constraints, `EXCLUDE USING gist` for OR overlap prevention, audit triggers, 34 indexes |
| `sql/seed.sql` | Realistic seed data — hospitals, ORs (with robot/C-arm/flow), procedures (CPT codes), surgery cases, schedules, teams, events, implants, specimens, PACU records, counts |
| `sql/queries.sql` | 17 surgery-specific queries — daily OR schedule, implant traceability, count mismatch alerts, PACU recovery times, complication rates, OR utilization, emergency response time, staff workload, turnaround time, intra-op medication log, audit trail |

### Key Features
- **OR Overlap Prevention** — `EXCLUDE USING gist (or_room_id WITH =, tstzrange(scheduled_start, scheduled_end) WITH &&)`
- **Safety** — Surgical_Count with pre/post discrepancy alerts
- **Traceability** — Implant_Device with serial/lot/manufacturer tracking
- **Peri-operative Workflow** — Surgery_Case status pipeline (scheduled → pre_op → in_or → in_pacu → completed)
- **PACU Recovery** — Aldrete and pain score tracking
- **Specimen Tracking** — Laterality, tissue type, container, pathology request ID

---

## Phase 2: Application Features & Presentation

### Tech Stack
- **Backend:** Spring Boot (Java)
- **Database:** PostgreSQL (with btree_gist extension)
- **Frontend:** Thymeleaf or React (TBD)
- **Build Tool:** Maven

### Presentation
- Schema walkthrough (23 tables, 27 indexes, exclusion constraint)
- Key surgery queries demonstration
- OR scheduling with overlap prevention explanation
