# Primary & Foreign Keys Reference

| # | Table | Primary Key | Foreign Key(s) | References |
|---|-------|-------------|----------------|------------|
| 1 | **Patient** | `patient_number` | — | — |
| 2 | **Hospital** | `hospital_id` | — | — |
| 3 | **Department** | `department_code` | `hospital_id` | Hospital(hospital_id) |
| | | | `chairman_ssn` | Doctor(ssn) |
| 4 | **Department_Location** | `(department_code, location)` | `department_code` | Department(department_code) |
| 5 | **Doctor** | `ssn` | `department_code` | Department(department_code) |
| 6 | **Treats** | `(patient_number, doctor_ssn)` | `patient_number` | Patient(patient_number) |
| | | | `doctor_ssn` | Doctor(ssn) |
| 7 | **Prescription** | `prescription_id` | `doctor_ssn` | Doctor(ssn) |
| | | | `patient_number` | Patient(patient_number) |
| 8 | **Medication** | `medication_id` | — | — |
| 9 | **Prescription_Medication** | `(prescription_id, medication_id)` | `prescription_id` | Prescription(prescription_id) |
| | | | `medication_id` | Medication(medication_id) |
| 10 | **Room** | `room_id` | `hospital_id` | Hospital(hospital_id) |
| 11 | **Appointment** | `appointment_id` | `patient_number` | Patient(patient_number) |
| | | | `doctor_ssn` | Doctor(ssn) |
| | | | `room_id` | Room(room_id) |
| 12 | **Payment** | `payment_id` | `appointment_id` | Appointment(appointment_id) |
| 13 | **User** | `user_id` | — (polymorphic: person_type + person_id) | Patient(patient_number) or Doctor(ssn) |
| 14 | **Contact_Inquiry** | `inquiry_id` | — | — |
| 15 | **Geo_Location** | `location_id` | — (polymorphic: entity_type + entity_id) | — |
| 16 | **Scan_Document** | `scan_id` | `patient_number` | Patient(patient_number) |
| | | | `doctor_ssn` | Doctor(ssn) |

## Composite Keys Summary

| Table | Composite PK Columns | Type |
|-------|----------------------|------|
| Department_Location | `department_code` + `location` | Weak entity (owner PK + partial key) |
| Treats | `patient_number` + `doctor_ssn` | M:N relationship junction |
| Prescription_Medication | `prescription_id` + `medication_id` | M:N relationship junction |

## Polymorphic References

| Table | Type Column | ID Column | Target Tables |
|-------|-------------|-----------|---------------|
| **User** | `person_type` ('Patient' / 'Doctor') | `person_id` | Patient(patient_number) or Doctor(ssn) |
| **Geo_Location** | `entity_type` | `entity_id` | Any table (generic) |

## Indexes (for FK performance)

| Index Name | Table | Column(s) |
|------------|-------|-----------|
| `idx_doctor_department` | Doctor | `department_code` |
| `idx_appointment_patient` | Appointment | `patient_number` |
| `idx_appointment_doctor` | Appointment | `doctor_ssn` |
| `idx_appointment_date` | Appointment | `appointment_date` |
| `idx_prescription_patient` | Prescription | `patient_number` |
| `idx_treats_doctor` | Treats | `doctor_ssn` |
| `idx_room_hospital` | Room | `hospital_id` |
| `idx_geo_entity` | Geo_Location | `entity_type`, `entity_id` |
| `idx_scan_patient` | Scan_Document | `patient_number` |
