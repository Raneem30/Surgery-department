# Database Plan — Surgery Department (OR Module)

## Overview
Operating Theater module for the Surgery Department. Manages patients (with embedded vitals), doctors, appointments, payments, contact inquiries, surgical procedures, OR scheduling with overlap prevention, and surgical teams.

---

## 1. Entities, Attributes & Constraints

### Patient (vitals embedded per guidelines)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| patient_number | VARCHAR(20) | PK | NOT NULL |
| ssn | VARCHAR(14) | UNIQUE | NOT NULL |
| name | VARCHAR(100) | | NOT NULL |
| address | VARCHAR(200) | | |
| phone | VARCHAR(20) | | |
| birthdate | DATE | | NOT NULL |
| sex | CHAR(1) | | NOT NULL, CHECK (IN 'M','F') |
| medical_history | TEXT | | |
| admission_date | DATE | | NOT NULL |
| blood_pressure | VARCHAR(20) | | (embedded vital) |
| heart_rate | INTEGER | | CHECK (> 0) |
| temperature | DECIMAL(4,1) | | (embedded vital) |
| spo2 | INTEGER | | CHECK (0-100) |
| recorded_at | TIMESTAMP | | (vitals timestamp) |

---

### Hospital

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| hospital_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| name | VARCHAR(100) | | NOT NULL |
| address | VARCHAR(200) | | NOT NULL |

---

### Geo_Location (guideline requirement)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| location_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| hospital_id | INTEGER | FK → Hospital | NOT NULL |
| latitude | DECIMAL(10,7) | | NOT NULL |
| longitude | DECIMAL(10,7) | | NOT NULL |

---

### Department

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| department_code | VARCHAR(10) | PK | NOT NULL |
| name | VARCHAR(100) | UNIQUE | NOT NULL |
| hospital_id | INTEGER | FK → Hospital | NOT NULL |
| chairman_doctor_id | INTEGER | FK → Doctor | |
| chair_start_date | DATE | | |

---

### Department_Location

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| department_code | VARCHAR(10) | PK, FK → Department | NOT NULL, ON DELETE CASCADE |
| location | VARCHAR(200) | PK | NOT NULL |

---

### Doctor

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| doctor_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| ssn | VARCHAR(14) | UNIQUE | NOT NULL |
| name | VARCHAR(100) | | NOT NULL |
| sex | CHAR(1) | | CHECK (IN 'M','F') |
| birth_date | DATE | | |
| major_area | VARCHAR(100) | | NOT NULL |
| degree | VARCHAR(50) | | NOT NULL |
| department_code | VARCHAR(10) | FK → Department | NOT NULL |
| join_date | DATE | | |
| email | VARCHAR(100) | | |
| phone | VARCHAR(20) | | |

---

### Treats (Doctor ↔ Patient, with hours_per_week)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| patient_number | VARCHAR(20) | PK, FK → Patient | NOT NULL, ON DELETE CASCADE |
| doctor_id | INTEGER | PK, FK → Doctor | NOT NULL |
| hours_per_week | INTEGER | | CHECK (>= 0) |

---

### Prescription

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| prescription_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| doctor_id | INTEGER | FK → Doctor | NOT NULL |
| patient_number | VARCHAR(20) | FK → Patient | NOT NULL |
| prescription_date | DATE | | NOT NULL |
| start_date | DATE | | NOT NULL |
| end_date | DATE | | NOT NULL, CHECK (end >= start) |

---

### Medication

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| medication_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| name | VARCHAR(100) | UNIQUE | NOT NULL |

---

### Prescription_Medication (M:N)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| prescription_id | INTEGER | PK, FK → Prescription | NOT NULL, ON DELETE CASCADE |
| medication_id | INTEGER | PK, FK → Medication | NOT NULL, ON DELETE RESTRICT |
| times_per_day | INTEGER | | NOT NULL, CHECK (> 0) |
| dose | VARCHAR(50) | | NOT NULL |

---

### Room (enhanced for Surgery — OR rooms)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| room_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| hospital_id | INTEGER | FK → Hospital | NOT NULL |
| room_number | VARCHAR(20) | | NOT NULL |
| room_type | VARCHAR(50) | | NOT NULL, CHECK (IN 'OR','PACU','ICU','Ward','Clinic') |
| or_type | VARCHAR(50) | | CHECK (IN 'general','cardiac','hybrid','robotic') |
| has_robot | BOOLEAN | | DEFAULT FALSE |
| has_c_arm | BOOLEAN | | DEFAULT FALSE |
| | | | CHECK ((room_type='OR' AND or_type IS NOT NULL) OR (room_type!='OR' AND or_type IS NULL)) |

---

### Surgical_Procedure (surgery-specific master list)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| procedure_code | VARCHAR(20) | PK | NOT NULL |
| name | VARCHAR(200) | | NOT NULL |
| standard_duration_minutes | INTEGER | | NOT NULL, CHECK (> 0) |
| required_room_type | VARCHAR(50) | | NOT NULL, CHECK (IN 'general','cardiac','hybrid','robotic') |
| specialty | VARCHAR(100) | | NOT NULL |

---

### Surgery_Case (central hub for surgery)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| case_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| patient_number | VARCHAR(20) | FK → Patient | NOT NULL |
| procedure_code | VARCHAR(20) | FK → Surgical_Procedure | NOT NULL |
| priority | VARCHAR(20) | | NOT NULL, CHECK (IN 'elective','emergency','urgent') |
| status | VARCHAR(20) | | NOT NULL, CHECK (IN 'scheduled','pre_op','in_or','in_pacu','completed','cancelled') |
| cancel_reason | VARCHAR(500) | | |
| created_at | TIMESTAMP | | NOT NULL, DEFAULT CURRENT_TIMESTAMP |

---

### Appointment (guideline requirement)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| appointment_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| patient_number | VARCHAR(20) | FK → Patient | NOT NULL |
| doctor_id | INTEGER | FK → Doctor | NOT NULL |
| room_id | INTEGER | FK → Room | |
| appointment_date | TIMESTAMP | | NOT NULL |
| status | VARCHAR(20) | | NOT NULL, CHECK (IN 'scheduled','completed','cancelled') |
| reason | VARCHAR(500) | | |
| case_id | INTEGER | FK → Surgery_Case | ON DELETE SET NULL |

---

### Payment (guideline requirement: register/pay/refund)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| payment_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| appointment_id | INTEGER | FK → Appointment (UNIQUE) | NOT NULL |
| amount | DECIMAL(10,2) | | NOT NULL |
| payment_date | TIMESTAMP | | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| payment_type | VARCHAR(20) | | NOT NULL, CHECK (IN 'register','pay','refund') |
| description | VARCHAR(500) | | |

---

### User (guideline requirement for login)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| user_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| username | VARCHAR(50) | UNIQUE | NOT NULL |
| password_hash | VARCHAR(255) | | NOT NULL |
| role | VARCHAR(20) | | NOT NULL, CHECK (IN 'admin','doctor','nurse','staff') |
| doctor_id | INTEGER | FK → Doctor | (links to doctor) |
| patient_number | VARCHAR(20) | FK → Patient | (links to patient) |
| last_login | TIMESTAMP | | |

---

### Contact_Inquiry (guideline requirement)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| inquiry_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| name | VARCHAR(100) | | NOT NULL |
| email | VARCHAR(100) | | NOT NULL |
| phone | VARCHAR(20) | | |
| subject | VARCHAR(200) | | NOT NULL |
| message | TEXT | | NOT NULL |
| submitted_at | TIMESTAMP | | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| status | VARCHAR(20) | | NOT NULL, DEFAULT 'pending', CHECK (IN 'pending','read','replied','closed') |

---

### Scan_Document (guideline requirement for file uploads)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| scan_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| patient_number | VARCHAR(20) | FK → Patient | NOT NULL |
| uploaded_by_doctor_id | INTEGER | FK → Doctor | NOT NULL |
| file_path | VARCHAR(500) | | NOT NULL |
| upload_date | TIMESTAMP | | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| description | VARCHAR(200) | | |
| document_type | VARCHAR(50) | | CHECK (IN 'consent','operative_report','imaging','lab_result') |

---

### Surgery_Schedule (OR scheduling with overlap prevention)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| schedule_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| case_id | INTEGER | FK → Surgery_Case (UNIQUE) | NOT NULL |
| or_room_id | INTEGER | FK → Room | NOT NULL |
| scheduled_start | TIMESTAMP | | NOT NULL |
| scheduled_end | TIMESTAMP | | NOT NULL, CHECK (end > start) |
| actual_start | TIMESTAMP | | |
| actual_end | TIMESTAMP | | CHECK (end > start) |
| **Overlap Prevention** | | | EXCLUDE USING gist (or_room_id WITH =, tsrange(scheduled_start, scheduled_end) WITH &&) |

---

### Surgical_Team_Assignment (surgery team with roles)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| case_id | INTEGER | PK, FK → Surgery_Case | NOT NULL |
| doctor_id | INTEGER | PK, FK → Doctor | NOT NULL |
| role | VARCHAR(30) | PK | NOT NULL, CHECK (IN 'primary_surgeon','assistant','anesthesiologist','scrub_nurse','circulating_nurse') |

---

## 2. Key Relationships

| Entity 1 | Card. | Relationship | Card. | Entity 2 | Detail |
|----------|-------|-------------|-------|----------|--------|
| Hospital | 1 | has geo locations | N | Geo_Location | hospital_id FK |
| Hospital | 1 | contains | N | Department | hospital_id FK |
| Department | 1 | has locations | N | Department_Location | composite PK |
| Department | 1 | employs | N | Doctor | department_code FK |
| Doctor | 0..1 | chaired by | 1 | Department | chairman_doctor_id FK |
| Doctor | M | treats | N | Patient | Treats junction |
| Doctor | 1 | writes | N | Prescription | doctor_id FK |
| Patient | 1 | receives | N | Prescription | patient_number FK |
| Prescription | M | includes | N | Medication | Prescription_Medication junction |
| Hospital | 1 | contains | N | Room | hospital_id FK |
| Patient | 1 | undergoes | N | Surgery_Case | patient_number FK |
| Surgery_Case | 1 | scheduled as | 1 | Surgery_Schedule | case_id FK (UNIQUE) |
| Surgery_Case | 1 | staffed by | N | Surgical_Team_Assignment | case_id FK |
| Surgery_Schedule | 1 | occupies | 1 | Room | or_room_id FK |
| Doctor | 1 | on team | N | Surgical_Team_Assignment | doctor_id FK |
| Patient | 1 | books | N | Appointment | patient_number FK |
| Doctor | 1 | runs | N | Appointment | doctor_id FK |
| Appointment | 1 | relates to | 0..1 | Surgery_Case | case_id FK (ON DELETE SET NULL) |
| Appointment | 1 | has | 1 | Payment | appointment_id FK (UNIQUE) |
| User | 0..1 | links to | 1 | Doctor | doctor_id FK |
| User | 0..1 | links to | 1 | Patient | patient_number FK |
| Doctor | 1 | uploads | N | Scan_Document | uploaded_by_doctor_id FK |

---

## 3. Completeness Constraints

| Entity | Relationship | Constraint | Meaning |
|--------|-------------|------------|---------|
| Doctor | belongs to → Department | **Total** | department_code NOT NULL |
| Department | has chairman → Doctor | **Partial** | chairman_doctor_id nullable |
| Department | belongs to → Hospital | **Total** | hospital_id NOT NULL |
| Room | belongs to → Hospital | **Total** | hospital_id NOT NULL |
| Room | or_type → room_type | **Total (conditional)** | NOT NULL when room_type='OR', NULL otherwise |
| Surgery_Schedule | actual times | **Partial** | actual_start/actual_end nullable |

## 4. Subtype Discriminators

| Discriminator | Meaning | Present? |
|---------------|---------|----------|
| **Disjoint** | Instance belongs to at most one subtype (XOR) | No |
| **Overlapping** | Instance can belong to multiple subtypes (AND) | No |

> No generalization hierarchies in this schema.

---

## 5. Functional Requirements Coverage

| # | Requirement | Tables Involved |
|---|-------------|-----------------|
| 1 | Daily OR schedule | Surgery_Schedule, Room, Surgery_Case, Patient, Surgical_Procedure, Surgical_Team_Assignment, Doctor |
| 2 | Surgery case tracking by status | Surgery_Case |
| 3 | OR utilization | Room, Surgery_Schedule |
| 4 | Doctor workload | Surgical_Team_Assignment, Surgery_Case, Doctor |
| 5 | Procedure duration vs standard | Surgery_Schedule, Surgery_Case, Surgical_Procedure |
| 6 | Cancelled surgeries | Surgery_Case, Surgical_Procedure, Surgery_Schedule |
| 7 | Team role distribution | Surgical_Team_Assignment, Surgery_Case, Surgical_Procedure |
| 8 | OR turnaround time | Surgery_Schedule (LEAD window) |
| 9 | Patient payment history | Payment, Appointment, Patient |
| 10 | Upcoming appointments | Appointment, Patient, Doctor, Room |

---

## 6. Normalization

All tables are in **3NF**:
- **1NF**: Atomic columns, no repeating groups
- **2NF**: No partial dependencies — composite PKs are minimal
- **3NF**: No transitive dependencies — all non-key attributes depend solely on the full PK
