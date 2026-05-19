# Database Plan — Surgery Department (OR Module)

## Overview
Operating Theater module for the Surgery Department. Manages patients, surgical procedures, OR scheduling with overlap prevention, surgical teams, intraoperative events, implants, specimens, PACU recovery, and safety counts.

---

## 1. Entities, Attributes & Constraints

### Patient

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

---

### Hospital

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| hospital_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| name | VARCHAR(100) | | NOT NULL |
| address | VARCHAR(200) | | NOT NULL |

---

### Department

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| department_code | VARCHAR(10) | PK | NOT NULL |
| name | VARCHAR(100) | UNIQUE | NOT NULL |
| hospital_id | INTEGER | FK → Hospital | NOT NULL |
| chairman_staff_id | INTEGER | FK → Staff(staff_id) | |
| chair_start_date | DATE | | |

---

### Department_Location

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| department_code | VARCHAR(10) | PK, FK → Department | NOT NULL, ON DELETE CASCADE |
| location | VARCHAR(200) | PK | NOT NULL |

---

### Staff (unified personnel — doctors, nurses, techs)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| staff_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| ssn | VARCHAR(14) | UNIQUE | NOT NULL |
| name | VARCHAR(100) | | NOT NULL |
| role | VARCHAR(20) | | NOT NULL, CHECK (IN 'doctor','nurse','tech') |
| sex | CHAR(1) | | CHECK (IN 'M','F') |
| birth_date | DATE | | |
| major_area | VARCHAR(100) | | NOT NULL when role='doctor', NULL otherwise |
| degree | VARCHAR(50) | | NOT NULL when role='doctor', NULL otherwise |
| department_code | VARCHAR(10) | FK → Department | NOT NULL |
| **Role Validation** | | | CHECK ((role='doctor' AND major_area IS NOT NULL AND degree IS NOT NULL) OR (role!='doctor' AND major_area IS NULL AND degree IS NULL)) |
| join_date | DATE | | |
| email | VARCHAR(100) | | |
| phone | VARCHAR(20) | | |

---

### Treats (M:N Staff ↔ Patient)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| patient_number | VARCHAR(20) | PK, FK → Patient | NOT NULL, ON DELETE CASCADE |
| staff_id | INTEGER | PK, FK → Staff | NOT NULL, ON DELETE CASCADE |
| hours_per_week | INTEGER | | CHECK (>= 0) |
| **Doctor-Only** | | | Trigger: BEFORE INSERT/UPDATE ensures staff_id references a doctor |

---

### Prescription

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| prescription_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| staff_id | INTEGER | FK → Staff | NOT NULL |
| patient_number | VARCHAR(20) | FK → Patient | NOT NULL |
| prescription_date | DATE | | NOT NULL |
| start_date | DATE | | NOT NULL |
| end_date | DATE | | NOT NULL, CHECK (end >= start) |
| **Doctor-Only** | | | Trigger: BEFORE INSERT/UPDATE ensures staff_id references a doctor |

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

### Room (Operating Rooms & Patient Care Areas)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| room_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| hospital_id | INTEGER | FK → Hospital | NOT NULL |
| room_number | VARCHAR(20) | | NOT NULL |
| room_type | VARCHAR(50) | | NOT NULL, CHECK (IN 'OR','PACU','ICU','Ward','Clinic') |
| or_type | VARCHAR(50) | | CHECK (IN 'general','cardiac','hybrid','robotic') |
| has_robot | BOOLEAN | | DEFAULT FALSE |
| has_c_arm | BOOLEAN | | DEFAULT FALSE |
| laminar_flow | BOOLEAN | | DEFAULT FALSE |
| | | | CHECK ((room_type='OR' AND or_type IS NOT NULL) OR (room_type!='OR' AND or_type IS NULL)) |

---

### Clinic_Appointment (pre-op / post-op visits only)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| appointment_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| patient_number | VARCHAR(20) | FK → Patient | NOT NULL |
| staff_id | INTEGER | FK → Staff | NOT NULL |
| room_id | INTEGER | FK → Room | |
| appointment_date | TIMESTAMP | | NOT NULL |
| status | VARCHAR(20) | | NOT NULL, CHECK (IN 'scheduled','completed','cancelled') |
| reason | VARCHAR(500) | | |
| case_id | INTEGER | FK → Surgery_Case | ON DELETE SET NULL |

---

### Scan_Document

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| scan_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| patient_number | VARCHAR(20) | FK → Patient | NOT NULL |
| uploaded_by_staff_id | INTEGER | FK → Staff | NOT NULL |
| file_path | VARCHAR(500) | | NOT NULL |
| upload_date | TIMESTAMP | | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| description | VARCHAR(200) | | |
| document_type | VARCHAR(50) | | CHECK (IN 'consent','operative_report','imaging','lab_result') |

---

### Surgical_Procedure (master list — CPT / ICD-PCS)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| procedure_code | VARCHAR(20) | PK | NOT NULL |
| name | VARCHAR(200) | | NOT NULL |
| standard_duration_minutes | INTEGER | | NOT NULL, CHECK (> 0) |
| required_room_type | VARCHAR(50) | | NOT NULL, CHECK (IN 'general','cardiac','hybrid','robotic') |
| specialty | VARCHAR(100) | | NOT NULL |

---

### Admission (hospital stay)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| admission_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| patient_number | VARCHAR(20) | FK → Patient | NOT NULL |
| admission_date | DATE | | NOT NULL |
| discharge_date | DATE | | CHECK (discharge >= admission) |
| bed_number | VARCHAR(20) | | |

---

### Vital_Sign (time-series)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| vital_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| patient_number | VARCHAR(20) | FK → Patient | NOT NULL |
| recorded_at | TIMESTAMP | | NOT NULL |
| blood_pressure | VARCHAR(20) | | |
| heart_rate | INTEGER | | CHECK (> 0) |
| temperature | DECIMAL(4,1) | | |
| spo2 | INTEGER | | CHECK (0-100) |
| recorded_by_staff_id | INTEGER | FK → Staff | NOT NULL |

---

### Surgery_Case (central hub)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| case_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| patient_number | VARCHAR(20) | FK → Patient | NOT NULL |
| procedure_code | VARCHAR(20) | FK → Surgical_Procedure | NOT NULL |
| priority | VARCHAR(20) | | NOT NULL, CHECK (IN 'elective','emergency','urgent') |
| status | VARCHAR(20) | | NOT NULL, CHECK (IN 'scheduled','pre_op','in_or','in_pacu','completed','cancelled') |
| admission_id | INTEGER | FK → Admission | |
| cancel_reason | VARCHAR(500) | | |
| created_at | TIMESTAMP | | NOT NULL, DEFAULT CURRENT_TIMESTAMP |

---

### Surgery_Schedule (OR scheduling)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| schedule_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| case_id | INTEGER | FK → Surgery_Case (UNIQUE) | NOT NULL |
| or_room_id | INTEGER | FK → Room | NOT NULL |
| scheduled_start | TIMESTAMP | | NOT NULL |
| scheduled_end | TIMESTAMP | | NOT NULL, CHECK (end > start) |
| actual_start | TIMESTAMP | | |
| actual_end | TIMESTAMP | | CHECK (end > start) |
| **Overlap Prevention** | | | EXCLUDE USING gist (or_room_id WITH =, tstzrange(scheduled_start, scheduled_end) WITH &&) |

---

### Surgical_Team_Assignment

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| case_id | INTEGER | PK, FK → Surgery_Case | NOT NULL |
| staff_id | INTEGER | PK, FK → Staff | NOT NULL |
| role | VARCHAR(30) | PK | NOT NULL, CHECK (IN 'primary_surgeon','assistant','anesthesiologist','scrub_nurse','circulating_nurse') |

---

### IntraOp_Event

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| event_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| case_id | INTEGER | FK → Surgery_Case | NOT NULL |
| event_time | TIMESTAMP | | NOT NULL |
| event_type | VARCHAR(50) | | NOT NULL, CHECK (IN 'incision','biopsy','bleeding','implant_placed','closure') |
| notes | TEXT | | |

---

### IntraOp_Medication (drugs given during surgery)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| medication_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| case_id | INTEGER | FK → Surgery_Case | NOT NULL |
| drug_name | VARCHAR(100) | | NOT NULL |
| dose | VARCHAR(50) | | NOT NULL |
| route | VARCHAR(30) | | NOT NULL, CHECK (IN 'IV','PO','IM','SC','inhalation','topical') |
| administered_at | TIMESTAMP | | NOT NULL |
| given_by_staff_id | INTEGER | FK → Staff | NOT NULL |
| notes | TEXT | | |

---

### Specimen

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| specimen_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| case_id | INTEGER | FK → Surgery_Case | NOT NULL |
| laterality | VARCHAR(20) | | CHECK (IN 'left','right','bilateral') |
| tissue_type | VARCHAR(100) | | NOT NULL |
| container_type | VARCHAR(100) | | NOT NULL |
| pathology_request_id | VARCHAR(50) | | |

---

### Implant_Device

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| implant_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| case_id | INTEGER | FK → Surgery_Case | NOT NULL |
| device_type | VARCHAR(100) | | NOT NULL |
| serial_number | VARCHAR(100) | | NOT NULL |
| lot_number | VARCHAR(100) | | |
| manufacturer | VARCHAR(200) | | NOT NULL |

---

### PACU_Record

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| pacu_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| case_id | INTEGER | FK → Surgery_Case (UNIQUE) | NOT NULL |
| arrival_time | TIMESTAMP | | NOT NULL |
| discharge_time | TIMESTAMP | | CHECK (discharge >= arrival) |
| aldrete_score | INTEGER | | CHECK (0-10) |
| pain_score | INTEGER | | CHECK (0-10) |
| complications | TEXT | | |

---

### Surgical_Count

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| count_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| case_id | INTEGER | FK → Surgery_Case | NOT NULL |
| count_type | VARCHAR(30) | | NOT NULL, CHECK (IN 'sponge','needle','instrument') |
| pre_count | INTEGER | | NOT NULL, CHECK (>= 0) |
| post_count | INTEGER | | NOT NULL, CHECK (>= 0) |
| verified_by_staff_id | INTEGER | FK → Staff | NOT NULL |
| verified_at | TIMESTAMP | | NOT NULL, DEFAULT CURRENT_TIMESTAMP |

---

### Surgery_Audit_Log (medicolegal audit trail)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| log_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| table_name | VARCHAR(50) | | NOT NULL |
| record_id | INTEGER | | NOT NULL |
| action | VARCHAR(20) | | NOT NULL, CHECK (IN 'INSERT','UPDATE','DELETE') |
| changed_by_staff_id | INTEGER | FK → Staff | NOT NULL |
| changed_at | TIMESTAMP | | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| old_data | JSONB | | (previous row snapshot) |
| new_data | JSONB | | (new row snapshot) |

---

## 2. Key Relationships

| Entity 1 | Card. | Relationship | Card. | Entity 2 | Detail |
|----------|-------|-------------|-------|----------|--------|
| Hospital | 1 | contains | N | Department | hospital_id FK |
| Department | 1 | has locations | N | Department_Location | composite PK |
| Department | 1 | employs | N | Staff | department_code FK |
| Staff (doctor) | 0..1 | chaired by | 1 | Department | chairman_staff_id FK |
| Staff | M | treats | N | Patient | Treats junction |
| Staff | 1 | writes | N | Prescription | staff_id FK |
| Patient | 1 | receives | N | Prescription | patient_number FK |
| Prescription | M | includes | N | Medication | Prescription_Medication junction |
| Hospital | 1 | contains | N | Room | hospital_id FK |
| Patient | 1 | admitted to | N | Admission | patient_number FK |
| Patient | 1 | has vitals | N | Vital_Sign | patient_number FK |
| Patient | 1 | undergoes | N | Surgery_Case | patient_number FK |
| Surgery_Case | 1 | scheduled as | 1 | Surgery_Schedule | case_id FK (UNIQUE) |
| Surgery_Case | 1 | staffed by | N | Surgical_Team_Assignment | case_id FK |
| Surgery_Case | 1 | has events | N | IntraOp_Event | case_id FK |
| Surgery_Case | 1 | receives meds | N | IntraOp_Medication | case_id FK |
| Surgery_Case | 1 | yields | N | Specimen | case_id FK |
| Surgery_Case | 1 | uses | N | Implant_Device | case_id FK |
| Surgery_Case | 1 | recovers in | 1 | PACU_Record | case_id FK (UNIQUE) |
| Surgery_Case | 1 | counted in | N | Surgical_Count | case_id FK |
| Surgery_Schedule | 1 | occupies | 1 | Room | or_room_id FK |
| Clinic_Appointment | 1 | relates to | 0..1 | Surgery_Case | case_id FK (ON DELETE SET NULL) |
| Staff | 1 | records vitals | N | Vital_Sign | recorded_by_staff_id FK |
| Staff | 1 | verifies counts | N | Surgical_Count | verified_by_staff_id FK |
| Staff | 1 | on team | N | Surgical_Team_Assignment | staff_id FK |
| Staff | 1 | gives meds | N | IntraOp_Medication | given_by_staff_id FK |
| Staff | 1 | uploads scans | N | Scan_Document | uploaded_by_staff_id FK |

---

## 3. Completeness Constraints

| Entity | Relationship | Constraint | Meaning |
|--------|-------------|------------|---------|
| Staff | belongs to → Department | **Total** | department_code NOT NULL |
| Staff | major_area / degree | **Total (conditional)** | NOT NULL when role='doctor', NULL otherwise |
| Treats staff_id | Treats → Staff(doctor) | **Total** | Trigger ensures only doctors can treat patients |
| Prescription staff_id | Prescription → Staff(doctor) | **Total** | Trigger ensures only doctors can prescribe |
| Department | has chairman → Staff(doctor) | **Partial** | chairman_staff_id nullable |
| Department | belongs to → Hospital | **Total** | hospital_id NOT NULL |
| Room | belongs to → Hospital | **Total** | hospital_id NOT NULL |
| Room | or_type → room_type | **Total (conditional)** | NOT NULL when room_type='OR', NULL otherwise |
| Admission | discharge → date | **Partial** | discharge_date nullable |
| Surgery_Case | linked to → Admission | **Partial** | admission_id nullable |
| Surgery_Case | has → PACU_Record | **Partial** | not all cases reach PACU |
| Surgery_Schedule | actual times | **Partial** | actual_start/actual_end nullable |

## 4. Subtype Discriminators

| Discriminator | Meaning | Present? |
|---------------|---------|----------|
| **Disjoint** | Instance belongs to at most one subtype (XOR) | No generalization hierarchies in this schema |
| **Overlapping** | Instance can belong to multiple subtypes (AND) | No |

> The previous User → Patient/Doctor generalization was removed. This schema has no subtype discriminators.

---

## 5. Functional Requirements Coverage

| # | Requirement | Tables Involved |
|---|-------------|-----------------|
| 1 | Daily OR schedule | Surgery_Schedule, Room, Surgery_Case, Patient, Surgical_Procedure, Surgical_Team_Assignment, Staff |
| 2 | Surgery case tracking by status | Surgery_Case |
| 3 | Implant traceability | Implant_Device, Surgery_Case, Patient, Surgical_Procedure, Surgical_Team_Assignment, Staff |
| 4 | Surgical count safety | Surgical_Count, Surgery_Case, Staff |
| 5 | PACU recovery times | PACU_Record, Surgery_Case, Surgical_Procedure |
| 6 | Specimen tracking | Specimen, Surgery_Case, Patient |
| 7 | Complication rates | IntraOp_Event, Surgery_Case, Surgical_Procedure, Surgical_Team_Assignment, Staff |
| 8 | OR utilization | Room, Surgery_Schedule |
| 9 | Emergency response time | Surgery_Case, IntraOp_Event |
| 10 | Staff workload | Surgical_Team_Assignment, Surgery_Case, Staff |
| 11 | Procedure duration vs standard | Surgery_Schedule, Surgery_Case, Surgical_Procedure |
| 12 | Cancelled surgeries | Surgery_Case, Surgical_Procedure, Surgery_Schedule |
| 13 | Multi-implant patients | Implant_Device, Surgery_Case, Patient |
| 14 | Team role distribution | Surgical_Team_Assignment, Surgery_Case, Surgical_Procedure |
| 15 | OR turnaround time | Surgery_Schedule (LEAD window) |
| 16 | Intra-op medication log | IntraOp_Medication, Surgery_Case, Patient, Surgical_Procedure, Staff |
| 17 | Audit log trail | Surgery_Audit_Log, Staff |
| 12 | Cancelled surgeries | Surgery_Case, Surgery_Schedule |
| 13 | Multi-implant patients | Implant_Device, Surgery_Case, Patient |
| 14 | Team role distribution | Surgical_Team_Assignment, Surgery_Case, Procedure |
| 15 | OR turnaround time | Surgery_Schedule (self-join with LEAD) |

---

## 6. Normalization

All tables are in **3NF**:
- **1NF**: Atomic columns, no repeating groups
- **2NF**: No partial dependencies — composite PKs are minimal
- **3NF**: No transitive dependencies — all non-key attributes depend solely on the full PK
