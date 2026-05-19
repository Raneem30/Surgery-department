# ERD Blueprint — Surgery Department

## Overview
ERD for the Surgery Department Hospital Information System, covering patients, surgeons, operating rooms, appointments, prescriptions, and administrative functions.

---

## Entities , Attributes & Keys

### Patient

| Attribute | Type | Key |
|-----------|------|-----|
| patient_number | VARCHAR(20) | PK |
| ssn | VARCHAR(14) | UNIQUE |
| name | VARCHAR(100) | |
| address | VARCHAR(200) | |
| phone | VARCHAR(20) | |
| birthdate | DATE | |
| sex | CHAR(1) | |
| medical_history | TEXT | |
| blood_pressure | VARCHAR(20) | |
| heart_rate | INTEGER | |
| temperature | DECIMAL(4,1) | |
| admission_date | DATE | |

---

### Hospital

| Attribute | Type | Key |
|-----------|------|-----|
| hospital_id | INTEGER | PK |
| name | VARCHAR(100) | |
| address | VARCHAR(200) | |

---

### Department

| Attribute | Type | Key |
|-----------|------|-----|
| department_code | VARCHAR(10) | PK |
| name | VARCHAR(100) | UNIQUE |
| hospital_id | INTEGER | FK → Hospital(hospital_id) |
| chairman_ssn | VARCHAR(14) | FK → Doctor(ssn) |
| chair_start_date | DATE | |

---

### Department_Location

| Attribute | Type | Key |
|-----------|------|-----|
| department_code | VARCHAR(10) | PK, FK → Department(department_code) |
| location | VARCHAR(200) | PK |

---

### Doctor

| Attribute | Type | Key |
|-----------|------|-----|
| ssn | VARCHAR(14) | PK |
| name | VARCHAR(100) | |
| sex | CHAR(1) | |
| birth_date | DATE | |
| major_area | VARCHAR(100) | |
| degree | VARCHAR(50) | |
| department_code | VARCHAR(10) | FK → Department(department_code) |
| join_date | DATE | |
| email | VARCHAR(100) | |
| phone | VARCHAR(20) | |

---

### Treats (relationship: Doctor ↔ Patient)

| Attribute | Type | Key |
|-----------|------|-----|
| patient_number | VARCHAR(20) | PK, FK → Patient(patient_number) |
| doctor_ssn | VARCHAR(14) | PK, FK → Doctor(ssn) |
| hours_per_week | INTEGER | |

---

### Prescription

| Attribute | Type | Key |
|-----------|------|-----|
| prescription_id | INTEGER | PK |
| doctor_ssn | VARCHAR(14) | FK → Doctor(ssn) |
| patient_number | VARCHAR(20) | FK → Patient(patient_number) |
| prescription_date | DATE | |
| start_date | DATE | |
| end_date | DATE | |

---

### Medication

| Attribute | Type | Key |
|-----------|------|-----|
| medication_id | INTEGER | PK |
| name | VARCHAR(100) | UNIQUE |

---

### Prescription_Medication (relationship: Prescription ↔ Medication)

| Attribute | Type | Key |
|-----------|------|-----|
| prescription_id | INTEGER | PK, FK → Prescription(prescription_id) |
| medication_id | INTEGER | PK, FK → Medication(medication_id) |
| times_per_day | INTEGER | |
| dose | VARCHAR(50) | |

---

### Room

| Attribute | Type | Key |
|-----------|------|-----|
| room_id | INTEGER | PK |
| hospital_id | INTEGER | FK → Hospital(hospital_id) |
| room_number | VARCHAR(20) | |
| room_type | VARCHAR(50) | |
| is_available | BOOLEAN | |

---

### Appointment

| Attribute | Type | Key |
|-----------|------|-----|
| appointment_id | INTEGER | PK |
| patient_number | VARCHAR(20) | FK → Patient(patient_number) |
| doctor_ssn | VARCHAR(14) | FK → Doctor(ssn) |
| room_id | INTEGER | FK → Room(room_id) |
| appointment_date | TIMESTAMP | |
| status | VARCHAR(20) | |

---

### Payment

| Attribute | Type | Key |
|-----------|------|-----|
| payment_id | INTEGER | PK |
| appointment_id | INTEGER | FK → Appointment(appointment_id) |
| amount | DECIMAL(10,2) | |
| payment_date | TIMESTAMP | |
| payment_method | VARCHAR(30) | |
| status | VARCHAR(20) | |

---

### User

| Attribute | Type | Key |
|-----------|------|-----|
| user_id | INTEGER | PK |
| username | VARCHAR(50) | UNIQUE |
| password_hash | VARCHAR(255) | |
| role | VARCHAR(20) | |
| person_type | VARCHAR(20) | polymorphic ref |
| person_id | VARCHAR(20) | polymorphic ref → Patient / Doctor |

---

### Contact_Inquiry

| Attribute | Type | Key |
|-----------|------|-----|
| inquiry_id | INTEGER | PK |
| name | VARCHAR(100) | |
| email | VARCHAR(100) | |
| subject | VARCHAR(200) | |
| message | TEXT | |
| submitted_at | TIMESTAMP | |
| is_resolved | BOOLEAN | |

---

### Geo_Location

| Attribute | Type | Key |
|-----------|------|-----|
| location_id | INTEGER | PK |
| latitude | DECIMAL(10,7) | |
| longitude | DECIMAL(10,7) | |
| address | VARCHAR(200) | |
| entity_type | VARCHAR(30) | polymorphic ref |
| entity_id | INTEGER | polymorphic ref |

---

### Scan_Document

| Attribute | Type | Key |
|-----------|------|-----|
| scan_id | INTEGER | PK |
| patient_number | VARCHAR(20) | FK → Patient(patient_number) |
| doctor_ssn | VARCHAR(14) | FK → Doctor(ssn) |
| file_path | VARCHAR(500) | |
| upload_date | TIMESTAMP | |
| description | VARCHAR(200) | |

---

## Key Relationships

| Entity 1 | Cardinality | Relationship | Cardinality | Entity 2 |
|----------|------------|-------------|-------------|----------|
| Hospital | 1 | contains | N | Department |
| Department | 1 | has locations | N | Department_Location |
| Department | 1 | employs | N | Doctor |
| Doctor | 0..1 | chaired by | 1 | Department |
| Doctor | M | treats | N | Patient |
| Doctor | 1 | writes | N | Prescription |
| Patient | 1 | receives | N | Prescription |
| Prescription | M | includes | N | Medication |
| Hospital | 1 | contains | N | Room |
| Room | 1 | assigned to | N | Appointment |
| Patient | 1 | books | N | Appointment |
| Doctor | 1 | scheduled with | N | Appointment |
| Appointment | 1 | has payment | 1 | Payment |
| Patient | 1 | has scans | N | Scan_Document |
| Doctor | 1 | uploads | N | Scan_Document |

---

## Completeness Constraints

| Entity | Relationship | Constraint | Meaning |
|--------|-------------|------------|---------|
| User | generalizes → Patient, Doctor | **Partial** | Not all Users must link to a Person record; admin & nurse roles have `person_type` / `person_id` NULL |
| Doctor | belongs to → Department | **Total** | Every Doctor MUST belong to exactly one Department (`department_code` NOT NULL) |
| Department | has chairman → Doctor | **Partial** | Not all Departments must have a chairman (`chairman_ssn` is nullable) |
| Department | belongs to → Hospital | **Total** | Every Department MUST belong to a Hospital (`hospital_id` NOT NULL) |
| Room | belongs to → Hospital | **Total** | Every Room MUST belong to a Hospital (`hospital_id` NOT NULL) |
| Appointment | has → Payment | **Partial** | Not every Appointment has a Payment yet; Payment is created after the appointment |

---

## Subtype Discriminators

### Disjoint vs Overlapping

A **subtype discriminator** specifies whether a supertype instance can belong to multiple subtypes:

| Discriminator | Meaning | Present in Schema? |
|---------------|---------|--------------------|
| **Disjoint** | An entity instance can belong to **at most one** subtype (XOR) | Yes — User → Patient/Doctor |
| **Overlapping** | An entity instance can belong to **multiple** subtypes simultaneously (AND) | No — no overlapping hierarchies exist |

### Disjointness Constraints

| Generalization | Subtypes | Discriminator | Meaning | Enforcement |
|----------------|----------|--------------|---------|-------------|
| User → Person | Patient, Doctor | **Disjoint** | A User can be linked to EITHER a Patient OR a Doctor, never both | `person_type CHECK ('Patient', 'Doctor')` — single scalar column cannot hold multiple values |

> **Note:** If the schema had an overlapping hierarchy (e.g., a Person who is both a Patient and a Doctor), it would require a separate junction table instead of a single `person_type` column. This schema has no such case, so **Overlapping** does not apply here.
