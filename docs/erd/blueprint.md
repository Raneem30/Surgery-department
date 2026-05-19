# Database Blueprint — Surgery Department

## Entities, Keys & Constraints

---

### Patient

| Column | Type | Key |
|--------|------|-----|
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

| Column | Type | Key |
|--------|------|-----|
| hospital_id | INTEGER | PK |
| name | VARCHAR(100) | |
| address | VARCHAR(200) | |

---

### Department

| Column | Type | Key |
|--------|------|-----|
| department_code | VARCHAR(10) | PK |
| name | VARCHAR(100) | UNIQUE |
| hospital_id | INTEGER | FK → Hospital(hospital_id) |
| chairman_ssn | VARCHAR(14) | FK → Doctor(ssn) |
| chair_start_date | DATE | |

---

### Department_Location

| Column | Type | Key |
|--------|------|-----|
| department_code | VARCHAR(10) | PK, FK → Department(department_code) |
| location | VARCHAR(200) | PK |

---

### Doctor

| Column | Type | Key |
|--------|------|-----|
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

### Treats

| Column | Type | Key |
|--------|------|-----|
| patient_number | VARCHAR(20) | PK, FK → Patient(patient_number) |
| doctor_ssn | VARCHAR(14) | PK, FK → Doctor(ssn) |
| hours_per_week | INTEGER | |

---

### Prescription

| Column | Type | Key |
|--------|------|-----|
| prescription_id | INTEGER | PK |
| doctor_ssn | VARCHAR(14) | FK → Doctor(ssn) |
| patient_number | VARCHAR(20) | FK → Patient(patient_number) |
| prescription_date | DATE | |
| start_date | DATE | |
| end_date | DATE | |

---

### Medication

| Column | Type | Key |
|--------|------|-----|
| medication_id | INTEGER | PK |
| name | VARCHAR(100) | UNIQUE |

---

### Prescription_Medication

| Column | Type | Key |
|--------|------|-----|
| prescription_id | INTEGER | PK, FK → Prescription(prescription_id) |
| medication_id | INTEGER | PK, FK → Medication(medication_id) |
| times_per_day | INTEGER | |
| dose | VARCHAR(50) | |

---

### Room

| Column | Type | Key |
|--------|------|-----|
| room_id | INTEGER | PK |
| hospital_id | INTEGER | FK → Hospital(hospital_id) |
| room_number | VARCHAR(20) | |
| room_type | VARCHAR(50) | |
| is_available | BOOLEAN | |

---

### Appointment

| Column | Type | Key |
|--------|------|-----|
| appointment_id | INTEGER | PK |
| patient_number | VARCHAR(20) | FK → Patient(patient_number) |
| doctor_ssn | VARCHAR(14) | FK → Doctor(ssn) |
| room_id | INTEGER | FK → Room(room_id) |
| appointment_date | TIMESTAMP | |
| status | VARCHAR(20) | |

---

### Payment

| Column | Type | Key |
|--------|------|-----|
| payment_id | INTEGER | PK |
| appointment_id | INTEGER | FK → Appointment(appointment_id) |
| amount | DECIMAL(10,2) | |
| payment_date | TIMESTAMP | |
| payment_method | VARCHAR(30) | |
| status | VARCHAR(20) | |

---

### User

| Column | Type | Key |
|--------|------|-----|
| user_id | INTEGER | PK |
| username | VARCHAR(50) | UNIQUE |
| password_hash | VARCHAR(255) | |
| role | VARCHAR(20) | |
| person_type | VARCHAR(20) | polymorphic ref |
| person_id | VARCHAR(20) | polymorphic ref → Patient / Doctor |

---

### Contact_Inquiry

| Column | Type | Key |
|--------|------|-----|
| inquiry_id | INTEGER | PK |
| name | VARCHAR(100) | |
| email | VARCHAR(100) | |
| subject | VARCHAR(200) | |
| message | TEXT | |
| submitted_at | TIMESTAMP | |
| is_resolved | BOOLEAN | |

---

### Geo_Location

| Column | Type | Key |
|--------|------|-----|
| location_id | INTEGER | PK |
| latitude | DECIMAL(10,7) | |
| longitude | DECIMAL(10,7) | |
| address | VARCHAR(200) | |
| entity_type | VARCHAR(30) | polymorphic ref |
| entity_id | INTEGER | polymorphic ref |

---

### Scan_Document

| Column | Type | Key |
|--------|------|-----|
| scan_id | INTEGER | PK |
| patient_number | VARCHAR(20) | FK → Patient(patient_number) |
| doctor_ssn | VARCHAR(14) | FK → Doctor(ssn) |
| file_path | VARCHAR(500) | |
| upload_date | TIMESTAMP | |
| description | VARCHAR(200) | |

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

## Disjointness Constraints

| Generalization | Subclasses | Constraint | Meaning |
|----------------|-----------|------------|---------|
| User → Person | Patient, Doctor | **Disjoint** | A User can be linked to EITHER a Patient OR a Doctor, never both. Enforced by `person_type CHECK ('Patient', 'Doctor')` |
