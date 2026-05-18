# Relational Schema Mapping — Surgery Department

Mapped from ERD to relational tables (3NF). Bold = PK, *Italic* = FK.

---

## Tables

### Patient
| Column | Domain | Constraints |
|--------|--------|-------------|
| **patient_number** | VARCHAR(20) | PRIMARY KEY |
| ssn | VARCHAR(14) | UNIQUE, NOT NULL |
| name | VARCHAR(100) | NOT NULL |
| address | VARCHAR(200) | |
| phone | VARCHAR(20) | |
| birthdate | DATE | NOT NULL |
| sex | CHAR(1) | NOT NULL, CHECK (sex IN ('M','F')) |
| medical_history | TEXT | |
| blood_pressure | VARCHAR(20) | |
| heart_rate | INTEGER | CHECK (heart_rate > 0) |
| temperature | DECIMAL(4,1) | |
| admission_date | DATE | NOT NULL |

### Hospital
| Column | Domain | Constraints |
|--------|--------|-------------|
| **hospital_id** | INTEGER | PRIMARY KEY (GENERATED ALWAYS AS IDENTITY) |
| name | VARCHAR(100) | NOT NULL |
| address | VARCHAR(200) | NOT NULL |

### Department
| Column | Domain | Constraints |
|--------|--------|-------------|
| **department_code** | VARCHAR(10) | PRIMARY KEY |
| name | VARCHAR(100) | UNIQUE, NOT NULL |
| *hospital_id* | INTEGER | NOT NULL, FK → Hospital(hospital_id) |
| *chairman_ssn* | VARCHAR(14) | FK → Doctor(ssn) |
| chair_start_date | DATE | |

### Department_Location
| Column | Domain | Constraints |
|--------|--------|-------------|
| **department_code** | VARCHAR(10) | PK (composite), FK → Department(department_code) ON DELETE CASCADE |
| **location** | VARCHAR(200) | PK (composite) |

### Doctor
| Column | Domain | Constraints |
|--------|--------|-------------|
| **ssn** | VARCHAR(14) | PRIMARY KEY |
| name | VARCHAR(100) | NOT NULL |
| sex | CHAR(1) | NOT NULL, CHECK (sex IN ('M','F')) |
| birth_date | DATE | NOT NULL |
| major_area | VARCHAR(100) | NOT NULL |
| degree | VARCHAR(50) | NOT NULL |
| *department_code* | VARCHAR(10) | NOT NULL, FK → Department(department_code) |
| join_date | DATE | NOT NULL |
| email | VARCHAR(100) | |
| phone | VARCHAR(20) | |

### Treats
| Column | Domain | Constraints |
|--------|--------|-------------|
| **patient_number** | VARCHAR(20) | PK (composite), FK → Patient(patient_number) ON DELETE CASCADE |
| **doctor_ssn** | VARCHAR(14) | PK (composite), FK → Doctor(ssn) ON DELETE CASCADE |
| hours_per_week | INTEGER | CHECK (hours_per_week >= 0) |

### Prescription
| Column | Domain | Constraints |
|--------|--------|-------------|
| **prescription_id** | INTEGER | PRIMARY KEY (GENERATED ALWAYS AS IDENTITY) |
| *doctor_ssn* | VARCHAR(14) | NOT NULL, FK → Doctor(ssn) |
| *patient_number* | VARCHAR(20) | NOT NULL, FK → Patient(patient_number) |
| prescription_date | DATE | NOT NULL |
| start_date | DATE | NOT NULL |
| end_date | DATE | NOT NULL, CHECK (end_date >= start_date) |

### Medication
| Column | Domain | Constraints |
|--------|--------|-------------|
| **medication_id** | INTEGER | PRIMARY KEY (GENERATED ALWAYS AS IDENTITY) |
| name | VARCHAR(100) | NOT NULL, UNIQUE |

### Prescription_Medication
| Column | Domain | Constraints |
|--------|--------|-------------|
| **prescription_id** | INTEGER | PK (composite), FK → Prescription(prescription_id) ON DELETE CASCADE |
| **medication_id** | INTEGER | PK (composite), FK → Medication(medication_id) ON DELETE RESTRICT |
| times_per_day | INTEGER | NOT NULL, CHECK (times_per_day > 0) |
| dose | VARCHAR(50) | NOT NULL |

### Room
| Column | Domain | Constraints |
|--------|--------|-------------|
| **room_id** | INTEGER | PRIMARY KEY (GENERATED ALWAYS AS IDENTITY) |
| *hospital_id* | INTEGER | NOT NULL, FK → Hospital(hospital_id) |
| room_number | VARCHAR(20) | NOT NULL |
| room_type | VARCHAR(50) | NOT NULL |
| is_available | BOOLEAN | DEFAULT TRUE |

### Appointment
| Column | Domain | Constraints |
|--------|--------|-------------|
| **appointment_id** | INTEGER | PRIMARY KEY (GENERATED ALWAYS AS IDENTITY) |
| *patient_number* | VARCHAR(20) | NOT NULL, FK → Patient(patient_number) |
| *doctor_ssn* | VARCHAR(14) | NOT NULL, FK → Doctor(ssn) |
| *room_id* | INTEGER | FK → Room(room_id) |
| appointment_date | TIMESTAMP | NOT NULL |
| status | VARCHAR(20) | NOT NULL, CHECK (status IN ('scheduled','completed','cancelled')) |
| reason | VARCHAR(500) | |

### Payment
| Column | Domain | Constraints |
|--------|--------|-------------|
| **payment_id** | INTEGER | PRIMARY KEY (GENERATED ALWAYS AS IDENTITY) |
| *appointment_id* | INTEGER | NOT NULL, UNIQUE, FK → Appointment(appointment_id) |
| amount | DECIMAL(10,2) | NOT NULL, CHECK (amount >= 0) |
| payment_date | TIMESTAMP | NOT NULL |
| payment_method | VARCHAR(30) | NOT NULL |
| status | VARCHAR(20) | NOT NULL, CHECK (status IN ('paid','refunded')) |

### "User"
| Column | Domain | Constraints |
|--------|--------|-------------|
| **user_id** | INTEGER | PRIMARY KEY (GENERATED ALWAYS AS IDENTITY) |
| username | VARCHAR(50) | UNIQUE, NOT NULL |
| password_hash | VARCHAR(255) | NOT NULL |
| role | VARCHAR(20) | NOT NULL, CHECK (role IN ('patient','doctor','nurse','admin')) |
| person_type | VARCHAR(20) | CHECK (person_type IN ('Patient','Doctor')) |
| person_id | VARCHAR(20) | |

### Contact_Inquiry
| Column | Domain | Constraints |
|--------|--------|-------------|
| **inquiry_id** | INTEGER | PRIMARY KEY (GENERATED ALWAYS AS IDENTITY) |
| name | VARCHAR(100) | NOT NULL |
| email | VARCHAR(100) | NOT NULL |
| subject | VARCHAR(200) | NOT NULL |
| message | TEXT | NOT NULL |
| submitted_at | TIMESTAMP | NOT NULL DEFAULT CURRENT_TIMESTAMP |
| is_resolved | BOOLEAN | DEFAULT FALSE |

### Geo_Location
| Column | Domain | Constraints |
|--------|--------|-------------|
| **location_id** | INTEGER | PRIMARY KEY (GENERATED ALWAYS AS IDENTITY) |
| latitude | DECIMAL(10,7) | NOT NULL |
| longitude | DECIMAL(10,7) | NOT NULL |
| address | VARCHAR(200) | NOT NULL |
| entity_type | VARCHAR(30) | |
| entity_id | INTEGER | |

### Scan_Document
| Column | Domain | Constraints |
|--------|--------|-------------|
| **scan_id** | INTEGER | PRIMARY KEY (GENERATED ALWAYS AS IDENTITY) |
| *patient_number* | VARCHAR(20) | NOT NULL, FK → Patient(patient_number) |
| *doctor_ssn* | VARCHAR(14) | NOT NULL, FK → Doctor(ssn) |
| file_path | VARCHAR(500) | NOT NULL |
| upload_date | TIMESTAMP | NOT NULL DEFAULT CURRENT_TIMESTAMP |
| description | VARCHAR(200) | |

---

## Functional Requirements Coverage

| # | Requirement | Tables Involved |
|---|-------------|-----------------|
| 1 | Complete patient info | Patient |
| 2 | Hospitals with rooms | Hospital, Room |
| 3 | Doctor info | Doctor |
| 4 | Work relationship doctor-hospital | Doctor → Department → Hospital |
| 5 | Treatment relationship | Treats |
| 6 | Geo locations | Geo_Location |
| 7 | Register/pay for appointment | Appointment, Payment |
| 8 | Cancel/refund appointment | Appointment (status), Payment (status=refunded) |
| 9 | Reserve rooms for treatment | Room, Appointment (room_id) |
| 10 | Reports | Appointments, Room allocation via joins |

---

## Normalization
All tables are in **3NF**:
- No partial dependencies (composite PKs are minimal)
- No transitive dependencies (all non-key attributes depend solely on the full PK)
