# Entity-Relationship Diagram (ERD) — Surgery Department

## Overview
ERD for the Surgery Department Hospital Information System, covering patients, surgeons, operating rooms, appointments, prescriptions, and administrative functions.

## Entities & Attributes

### Patient
| Attribute | Type | Constraints |
|-----------|------|-------------|
| patient_number | VARCHAR(20) | **PK, UNIQUE** |
| ssn | VARCHAR(14) | **UNIQUE** |
| name | VARCHAR(100) | NOT NULL |
| address | VARCHAR(200) | |
| phone | VARCHAR(20) | |
| birthdate | DATE | NOT NULL |
| sex | CHAR(1) | NOT NULL |
| medical_history | TEXT | |
| blood_pressure | VARCHAR(20) | |
| heart_rate | INTEGER | |
| temperature | DECIMAL(4,1) | |
| admission_date | DATE | NOT NULL |

### Hospital
| Attribute | Type | Constraints |
|-----------|------|-------------|
| hospital_id | INTEGER | **PK** |
| name | VARCHAR(100) | NOT NULL |
| address | VARCHAR(200) | NOT NULL |

### Department
| Attribute | Type | Constraints |
|-----------|------|-------------|
| department_code | VARCHAR(10) | **PK, UNIQUE** |
| name | VARCHAR(100) | **UNIQUE**, NOT NULL |
| hospital_id | INTEGER | FK → Hospital |
| chairman_ssn | VARCHAR(14) | FK → Doctor |
| chair_start_date | DATE | |

### Department_Location
| Attribute | Type | Constraints |
|-----------|------|-------------|
| department_code | VARCHAR(10) | **PK (composite)**, FK → Department |
| location | VARCHAR(200) | **PK (composite)** |

### Doctor
| Attribute | Type | Constraints |
|-----------|------|-------------|
| ssn | VARCHAR(14) | **PK, UNIQUE** |
| name | VARCHAR(100) | NOT NULL |
| sex | CHAR(1) | NOT NULL |
| birth_date | DATE | NOT NULL |
| major_area | VARCHAR(100) | NOT NULL |
| degree | VARCHAR(50) | NOT NULL |
| department_code | VARCHAR(10) | FK → Department, NOT NULL |
| join_date | DATE | NOT NULL |

### Treats (relationship: Doctor ↔ Patient)
| Attribute | Type | Constraints |
|-----------|------|-------------|
| patient_number | VARCHAR(20) | **PK (composite)**, FK → Patient |
| doctor_ssn | VARCHAR(14) | **PK (composite)**, FK → Doctor |
| hours_per_week | INTEGER | |

### Prescription
| Attribute | Type | Constraints |
|-----------|------|-------------|
| prescription_id | INTEGER | **PK** |
| doctor_ssn | VARCHAR(14) | FK → Doctor, NOT NULL |
| patient_number | VARCHAR(20) | FK → Patient, NOT NULL |
| prescription_date | DATE | NOT NULL |
| start_date | DATE | NOT NULL |
| end_date | DATE | NOT NULL |

### Medication
| Attribute | Type | Constraints |
|-----------|------|-------------|
| medication_id | INTEGER | **PK** |
| name | VARCHAR(100) | NOT NULL |

### Prescription_Medication (relationship: Prescription ↔ Medication)
| Attribute | Type | Constraints |
|-----------|------|-------------|
| prescription_id | INTEGER | **PK (composite)**, FK → Prescription |
| medication_id | INTEGER | **PK (composite)**, FK → Medication |
| times_per_day | INTEGER | NOT NULL |
| dose | VARCHAR(50) | NOT NULL |

### Room
| Attribute | Type | Constraints |
|-----------|------|-------------|
| room_id | INTEGER | **PK** |
| hospital_id | INTEGER | FK → Hospital, NOT NULL |
| room_number | VARCHAR(20) | NOT NULL |
| room_type | VARCHAR(50) | NOT NULL (e.g., Operating Room, Recovery, ICU) |
| is_available | BOOLEAN | |

### Appointment
| Attribute | Type | Constraints |
|-----------|------|-------------|
| appointment_id | INTEGER | **PK** |
| patient_number | VARCHAR(20) | FK → Patient, NOT NULL |
| doctor_ssn | VARCHAR(14) | FK → Doctor, NOT NULL |
| room_id | INTEGER | FK → Room |
| appointment_date | TIMESTAMP | NOT NULL |
| status | VARCHAR(20) | NOT NULL (scheduled, completed, cancelled) |

### Payment
| Attribute | Type | Constraints |
|-----------|------|-------------|
| payment_id | INTEGER | **PK** |
| appointment_id | INTEGER | FK → Appointment, NOT NULL, UNIQUE |
| amount | DECIMAL(10,2) | NOT NULL |
| payment_date | TIMESTAMP | NOT NULL |
| payment_method | VARCHAR(30) | NOT NULL |
| status | VARCHAR(20) | NOT NULL (paid, refunded) |

### User
| Attribute | Type | Constraints |
|-----------|------|-------------|
| user_id | INTEGER | **PK** |
| username | VARCHAR(50) | **UNIQUE**, NOT NULL |
| password_hash | VARCHAR(255) | NOT NULL |
| role | VARCHAR(20) | NOT NULL (patient, doctor, nurse, admin) |
| person_type | VARCHAR(20) | (Patient, Doctor) |
| person_id | VARCHAR(20) | links to Patient.patient_number or Doctor.ssn |

### Contact_Inquiry
| Attribute | Type | Constraints |
|-----------|------|-------------|
| inquiry_id | INTEGER | **PK** |
| name | VARCHAR(100) | NOT NULL |
| email | VARCHAR(100) | NOT NULL |
| subject | VARCHAR(200) | NOT NULL |
| message | TEXT | NOT NULL |
| submitted_at | TIMESTAMP | NOT NULL |
| is_resolved | BOOLEAN | |

### Geo_Location
| Attribute | Type | Constraints |
|-----------|------|-------------|
| location_id | INTEGER | **PK** |
| latitude | DECIMAL(10,7) | NOT NULL |
| longitude | DECIMAL(10,7) | NOT NULL |
| address | VARCHAR(200) | NOT NULL |
| entity_type | VARCHAR(30) | (Hospital, Department) |
| entity_id | INTEGER | links to Hospital or Department |

### Scan_Document
| Attribute | Type | Constraints |
|-----------|------|-------------|
| scan_id | INTEGER | **PK** |
| patient_number | VARCHAR(20) | FK → Patient, NOT NULL |
| doctor_ssn | VARCHAR(14) | FK → Doctor, NOT NULL |
| file_path | VARCHAR(500) | NOT NULL |
| upload_date | TIMESTAMP | NOT NULL |
| description | VARCHAR(200) | |

## Key Relationships
- **Hospital** 1--N **Department** (a hospital contains many departments)
- **Department** 1--N **Doctor** (a department employs many doctors)
- **Department** N--M **Location** (a department can have multiple locations)
- **Doctor** 1--1 **Department** (chairman relationship)
- **Doctor** N--M **Patient** via **Treats** (with hours_per_week)
- **Doctor** 1--N **Prescription**, **Patient** 1--N **Prescription**
- **Prescription** N--M **Medication** via **Prescription_Medication**
- **Hospital** 1--N **Room**
- **Patient** 1--N **Appointment**, **Doctor** 1--N **Appointment**
- **Room** 1--N **Appointment**
- **Appointment** 1--1 **Payment**
