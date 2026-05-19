# Primary & Foreign Keys Reference

| # | Table | Primary Key | Foreign Key(s) | References |
|---|-------|-------------|----------------|------------|
| 1 | **Patient** | `patient_number` | — | — |
| 2 | **Hospital** | `hospital_id` | — | — |
| 3 | **Geo_Location** | `location_id` | `hospital_id` | Hospital |
| 4 | **Department** | `department_code` | `hospital_id` | Hospital |
| | | | `chairman_doctor_id` | Doctor(doctor_id) |
| 5 | **Department_Location** | `(department_code, location)` | `department_code` | Department |
| 6 | **Doctor** | `doctor_id` | `department_code` | Department |
| 7 | **Treats** | `(patient_number, doctor_id)` | `patient_number` | Patient |
| | | | `doctor_id` | Doctor |
| 8 | **Prescription** | `prescription_id` | `doctor_id` | Doctor |
| | | | `patient_number` | Patient |
| 9 | **Medication** | `medication_id` | — | — |
| 10 | **Prescription_Medication** | `(prescription_id, medication_id)` | `prescription_id` | Prescription |
| | | | `medication_id` | Medication |
| 11 | **Room** | `room_id` | `hospital_id` | Hospital |
| 12 | **Surgical_Procedure** | `procedure_code` | — | — |
| 13 | **Surgery_Case** | `case_id` | `patient_number` | Patient |
| | | | `procedure_code` | Surgical_Procedure |
| 14 | **Appointment** | `appointment_id` | `patient_number` | Patient |
| | | | `doctor_id` | Doctor |
| | | | `room_id` | Room |
| | | | `case_id` | Surgery_Case (ON DELETE SET NULL) |
| 15 | **Payment** | `payment_id` | `appointment_id` (UNIQUE) | Appointment |
| 16 | **User** | `user_id` | `doctor_id` | Doctor |
| | | | `patient_number` | Patient |
| 17 | **Contact_Inquiry** | `inquiry_id` | — | — |
| 18 | **Scan_Document** | `scan_id` | `patient_number` | Patient |
| | | | `uploaded_by_doctor_id` | Doctor |
| 19 | **Surgery_Schedule** | `schedule_id` | `case_id` (UNIQUE) | Surgery_Case |
| | | | `or_room_id` | Room |
| 20 | **Surgical_Team_Assignment** | `(case_id, doctor_id, role)` | `case_id` | Surgery_Case |
| | | | `doctor_id` | Doctor |

## Composite Keys

| Table | Composite PK Columns | Purpose |
|-------|----------------------|---------|
| Department_Location | `department_code` + `location` | Weak entity |
| Treats | `patient_number` + `doctor_id` | M:N junction |
| Prescription_Medication | `prescription_id` + `medication_id` | M:N junction |
| Surgical_Team_Assignment | `case_id` + `doctor_id` + `role` | M:N with role discriminator |

## Unique Constraints (non-PK)

| Table | Column(s) | Reason |
|-------|-----------|--------|
| Patient | `ssn` | National ID uniqueness |
| Doctor | `ssn` | National ID uniqueness |
| Department | `name` | Department name uniqueness |
| Medication | `name` | Drug name uniqueness |
| Surgery_Schedule | `case_id` | One schedule per case |
| Payment | `appointment_id` | One payment per appointment |

## Indexes

| Index | Table | Column(s) | Purpose |
|-------|-------|-----------|---------|
| `idx_doctor_department` | Doctor | `department_code` | FK lookup |
| `idx_geo_hospital` | Geo_Location | `hospital_id` | FK lookup |
| `idx_room_hospital` | Room | `hospital_id` | FK lookup |
| `idx_room_type` | Room | `room_type` | Filter by type |
| `idx_appointment_patient` | Appointment | `patient_number` | FK lookup |
| `idx_appointment_doctor` | Appointment | `doctor_id` | FK lookup |
| `idx_appointment_date` | Appointment | `appointment_date` | Date range queries |
| `idx_appointment_case` | Appointment | `case_id` | FK lookup |
| `idx_prescription_doctor` | Prescription | `doctor_id` | FK lookup |
| `idx_prescription_patient` | Prescription | `patient_number` | FK lookup |
| `idx_treats_doctor` | Treats | `doctor_id` | FK lookup |
| `idx_payment_appointment` | Payment | `appointment_id` | FK lookup |
| `idx_payment_date` | Payment | `payment_date` | Date range queries |
| `idx_scan_patient` | Scan_Document | `patient_number` | FK lookup |
| `idx_scan_uploader` | Scan_Document | `uploaded_by_doctor_id` | FK lookup |
| `idx_user_doctor` | User | `doctor_id` | FK lookup |
| `idx_user_patient` | User | `patient_number` | FK lookup |
| `idx_contact_status` | Contact_Inquiry | `status` | Status filtering |
| `idx_surgery_patient` | Surgery_Case | `patient_number` | FK lookup |
| `idx_surgery_procedure` | Surgery_Case | `procedure_code` | FK lookup |
| `idx_surgery_status` | Surgery_Case | `status` | Status filtering |
| `idx_surgery_priority` | Surgery_Case | `priority` | Priority filtering |
| `idx_schedule_case` | Surgery_Schedule | `case_id` | FK lookup |
| `idx_schedule_room` | Surgery_Schedule | `or_room_id` | FK lookup |
| `idx_schedule_dates` | Surgery_Schedule | `scheduled_start, scheduled_end` | Range queries |
| `idx_team_case` | Surgical_Team_Assignment | `case_id` | FK lookup |
| `idx_team_doctor` | Surgical_Team_Assignment | `doctor_id` | FK lookup |
