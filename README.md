# Surgery Department - Hospital Information System

## Project Overview
A Hospital Information System (HIS) for the **Surgery Department** — managing patients, surgeons, operating rooms, appointments, prescriptions, and administrative reporting.

---

## Phase 1: Database Design & Implementation (May 16)

### Deliverable 1: Entity-Relationship Diagram (ERD)

| File | Description |
|------|-------------|
| `docs/erd/ERD.puml` | Original PlantUML ERD |
| `docs/erd/plan.md` | Comprehensive database plan — entities, attributes, domains, keys, constraints, relationships, completeness & disjointness constraints, functional requirements, normalization |

**Entities identified:**
- **Patient** — core entity with personal data, medical history, vital signs, admission date
- **Hospital** — contains departments, owns rooms
- **Department** — Surgery Dept, has locations, headed by a chairman (doctor)
- **Department_Location** — weak entity, multi-location departments
- **Doctor** — surgeon with specialization, degree, joins one department
- **Treats** (M:N) — which doctors treat which patients, with hours/week tracking
- **Prescription** — doctor writes for patient, includes medication directions
- **Medication** — medication catalog
- **Prescription_Medication** (M:N) — link table with dose & frequency
- **Room** — operating rooms, recovery rooms, regular rooms
- **Appointment** — patient books with doctor, linked to a room
- **Payment** — tracks appointment payments and refunds
- **User** — login accounts for patients, doctors, nurses, admins
- **Contact_Inquiry** — visitor contact form submissions
- **Geo_Location** — geographic coordinates for hospitals/departments
- **Scan_Document** — patient scans, X-rays, MRI uploads

### Deliverable 2: Relational Schema Mapping
**Files:**
- `docs/erd/plan.md` — complete database plan including schema, constraints, and mapping
- `docs/erd/keys_table.md` — comprehensive PK/FK reference table with composite keys, polymorphic refs, and indexes

### Deliverable 3: SQL Implementation
**Files:** `sql/schema.sql`, `sql/seed.sql`, `sql/queries.sql`

- `schema.sql` — DDL with CREATE TABLE statements, constraints, indexes
- `seed.sql` — realistic sample data for Surgery Department
- `queries.sql` — complex queries for reports (appointments, room allocation, etc.)

---

## Phase 2: Application Features & Presentation (May 23)

### Tech Stack
- **Backend:** Spring Boot (Java)
- **Database:** PostgreSQL / MySQL
- **Frontend:** Thymeleaf or React (TBD)
- **Build Tool:** Maven

### Features to Implement

| # | Feature | Details |
|---|---------|---------|
| 1 | Home page | Public landing page for visitors |
| 2 | User roles & auth | Patients, Doctors, Nurses, Admins — registration + login |
| 3 | User profiles | Doctor profile (schedule, specialization), Patient profile (history, upcoming surgeries) |
| 4 | File uploads | Patient scans, X-rays, MRI uploads |
| 5 | Appointments | Booking system between surgeons and patients |
| 6 | Contact forms | Inquiry/submission system for visitors |
| 7 | Admin dashboard | Statistical analysis: appointment reports, room utilization, patient demographics |
| 8 | Room management | Doctor reserves operating/recovery rooms for procedures |
| 9 | Payment & refunds | Patients pay for appointments, cancel for refund |
| 10 | Geo-location | Find nearest hospital/surgery center |

### Presentation
- Live demo of the application
- ERD walkthrough
- Key SQL queries demonstration
- Architecture overview
