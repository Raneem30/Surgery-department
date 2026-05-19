# Database Plan — Surgery Department

## Overview
Hospital Information System for the Surgery Department. Covers patients, surgeons, operating rooms, appointments, prescriptions, and administrative reporting.

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
| blood_pressure | VARCHAR(20) | | |
| heart_rate | INTEGER | | CHECK (> 0) |
| temperature | DECIMAL(4,1) | | |
| admission_date | DATE | | NOT NULL |

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
| chairman_ssn | VARCHAR(14) | FK → Doctor(ssn) | |
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
| ssn | VARCHAR(14) | PK | NOT NULL |
| name | VARCHAR(100) | | NOT NULL |
| sex | CHAR(1) | | NOT NULL, CHECK (IN 'M','F') |
| birth_date | DATE | | NOT NULL |
| major_area | VARCHAR(100) | | NOT NULL |
| degree | VARCHAR(50) | | NOT NULL |
| department_code | VARCHAR(10) | FK → Department | NOT NULL |
| join_date | DATE | | NOT NULL |
| email | VARCHAR(100) | | |
| phone | VARCHAR(20) | | |

---

### Treats (M:N Doctor ↔ Patient)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| patient_number | VARCHAR(20) | PK, FK → Patient | NOT NULL, ON DELETE CASCADE |
| doctor_ssn | VARCHAR(14) | PK, FK → Doctor | NOT NULL, ON DELETE CASCADE |
| hours_per_week | INTEGER | | CHECK (>= 0) |

---

### Prescription

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| prescription_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| doctor_ssn | VARCHAR(14) | FK → Doctor | NOT NULL |
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

### Prescription_Medication (M:N Prescription ↔ Medication)

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| prescription_id | INTEGER | PK, FK → Prescription | NOT NULL, ON DELETE CASCADE |
| medication_id | INTEGER | PK, FK → Medication | NOT NULL, ON DELETE RESTRICT |
| times_per_day | INTEGER | | NOT NULL, CHECK (> 0) |
| dose | VARCHAR(50) | | NOT NULL |

---

### Room

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| room_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| hospital_id | INTEGER | FK → Hospital | NOT NULL |
| room_number | VARCHAR(20) | | NOT NULL |
| room_type | VARCHAR(50) | | NOT NULL |
| is_available | BOOLEAN | | DEFAULT TRUE |

---

### Appointment

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| appointment_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| patient_number | VARCHAR(20) | FK → Patient | NOT NULL |
| doctor_ssn | VARCHAR(14) | FK → Doctor | NOT NULL |
| room_id | INTEGER | FK → Room | |
| appointment_date | TIMESTAMP | | NOT NULL |
| status | VARCHAR(20) | | NOT NULL, CHECK (IN 'scheduled','completed','cancelled') |

---

### Payment

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| payment_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| appointment_id | INTEGER | FK → Appointment | NOT NULL, UNIQUE |
| amount | DECIMAL(10,2) | | NOT NULL, CHECK (>= 0) |
| payment_date | TIMESTAMP | | NOT NULL |
| payment_method | VARCHAR(30) | | NOT NULL |
| status | VARCHAR(20) | | NOT NULL, CHECK (IN 'paid','refunded') |

---

### User

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| user_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| username | VARCHAR(50) | UNIQUE | NOT NULL |
| password_hash | VARCHAR(255) | | NOT NULL |
| role | VARCHAR(20) | | NOT NULL, CHECK (IN 'patient','doctor','nurse','admin') |
| person_type | VARCHAR(20) | | CHECK (IN 'Patient','Doctor') |
| person_id | VARCHAR(20) | | polymorphic → Patient / Doctor |

---

### Contact_Inquiry

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| inquiry_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| name | VARCHAR(100) | | NOT NULL |
| email | VARCHAR(100) | | NOT NULL |
| subject | VARCHAR(200) | | NOT NULL |
| message | TEXT | | NOT NULL |
| submitted_at | TIMESTAMP | | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| is_resolved | BOOLEAN | | DEFAULT FALSE |

---

### Geo_Location

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| location_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| latitude | DECIMAL(10,7) | | NOT NULL |
| longitude | DECIMAL(10,7) | | NOT NULL |
| address | VARCHAR(200) | | NOT NULL |
| entity_type | VARCHAR(30) | | polymorphic |
| entity_id | INTEGER | | polymorphic |

---

### Scan_Document

| Attribute | Domain | Key | Constraints |
|-----------|--------|-----|-------------|
| scan_id | INTEGER | PK | GENERATED ALWAYS AS IDENTITY |
| patient_number | VARCHAR(20) | FK → Patient | NOT NULL |
| doctor_ssn | VARCHAR(14) | FK → Doctor | NOT NULL |
| file_path | VARCHAR(500) | | NOT NULL |
| upload_date | TIMESTAMP | | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| description | VARCHAR(200) | | |

---

## 2. Key Relationships

| Entity 1 | Card. | Relationship | Card. | Entity 2 | Details |
|----------|-------|-------------|-------|----------|---------|
| Hospital | 1 | contains | N | Department | hospital_id FK in Department |
| Department | 1 | has locations | N | Department_Location | composite PK (dept_code, location) |
| Department | 1 | employs | N | Doctor | department_code FK in Doctor |
| Doctor | 0..1 | chaired by | 1 | Department | chairman_ssn FK in Department (nullable) |
| Doctor | M | treats | N | Patient | via Treats junction table |
| Doctor | 1 | writes | N | Prescription | doctor_ssn FK in Prescription |
| Patient | 1 | receives | N | Prescription | patient_number FK in Prescription |
| Prescription | M | includes | N | Medication | via Prescription_Medication junction |
| Hospital | 1 | contains | N | Room | hospital_id FK in Room |
| Room | 1 | assigned to | N | Appointment | room_id FK in Appointment |
| Patient | 1 | books | N | Appointment | patient_number FK in Appointment |
| Doctor | 1 | scheduled with | N | Appointment | doctor_ssn FK in Appointment |
| Appointment | 1 | has payment | 1 | Payment | appointment_id FK (UNIQUE) in Payment |
| Patient | 1 | has scans | N | Scan_Document | patient_number FK in Scan_Document |
| Doctor | 1 | uploads | N | Scan_Document | doctor_ssn FK in Scan_Document |

---

## 3. Completeness Constraints

| Entity | Relationship | Constraint | Meaning |
|--------|-------------|------------|---------|
| User | generalizes → Patient, Doctor | **Partial** | Admin/nurse roles have NULL person_type/person_id |
| Doctor | belongs to → Department | **Total** | department_code NOT NULL |
| Department | has chairman → Doctor | **Partial** | chairman_ssn nullable |
| Department | belongs to → Hospital | **Total** | hospital_id NOT NULL |
| Room | belongs to → Hospital | **Total** | hospital_id NOT NULL |
| Appointment | has → Payment | **Partial** | Payment created after appointment |

## 4. Subtype Discriminators

### Disjoint vs Overlapping

| Discriminator | Meaning | Present? |
|---------------|---------|----------|
| **Disjoint** | Instance belongs to at most one subtype (XOR) | Yes — User → Patient/Doctor |
| **Overlapping** | Instance can belong to multiple subtypes (AND) | No |

### Disjointness Constraints

| Generalization | Subtypes | Discriminator | Enforcement |
|----------------|----------|--------------|-------------|
| User → Person | Patient, Doctor | **Disjoint** | `person_type CHECK ('Patient','Doctor')` — single scalar, cannot hold multiple values |

> Overlapping would require a junction table. Not present in this schema.

---

## 5. Functional Requirements Coverage

| # | Requirement | Tables Involved |
|---|-------------|-----------------|
| 1 | Complete patient info | Patient |
| 2 | Hospitals with rooms | Hospital, Room |
| 3 | Doctor info | Doctor |
| 4 | Work relationship doctor-hospital | Doctor → Department → Hospital |
| 5 | Treatment relationship | Treats |
| 6 | Geo locations | Geo_Location |
| 7 | Register/pay for appointment | Appointment, Payment |
| 8 | Cancel/refund appointment | Appointment (status), Payment (status) |
| 9 | Reserve rooms for treatment | Room, Appointment (room_id) |
| 10 | Reports | Appointments, Room allocation via joins |

---

## 6. Normalization

All tables are in **3NF**:
- **1NF**: Atomic columns, no repeating groups
- **2NF**: No partial dependencies — composite PKs are minimal
- **3NF**: No transitive dependencies — all non-key attributes depend solely on the full PK
