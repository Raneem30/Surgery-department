# Primary & Foreign Keys Reference

| # | Table | Primary Key | Foreign Key(s) | References |
|---|-------|-------------|----------------|------------|
| 1 | **Patient** | `patient_number` | — | — |
| 2 | **Hospital** | `hospital_id` | — | — |
| 3 | **Department** | `department_code` | `hospital_id` | Hospital |
| | | | `chairman_staff_id` | Staff(staff_id) |
| 4 | **Department_Location** | `(department_code, location)` | `department_code` | Department |
| 5 | **Staff** | `staff_id` | `department_code` | Department |
| 6 | **Treats** | `(patient_number, staff_id)` | `patient_number` | Patient |
| | | | `staff_id` | Staff |
| 7 | **Prescription** | `prescription_id` | `staff_id` | Staff |
| | | | `patient_number` | Patient |
| 8 | **Medication** | `medication_id` | — | — |
| 9 | **Prescription_Medication** | `(prescription_id, medication_id)` | `prescription_id` | Prescription |
| | | | `medication_id` | Medication |
| 10 | **Room** | `room_id` | `hospital_id` | Hospital |
| 11 | **Clinic_Appointment** | `appointment_id` | `patient_number` | Patient |
| | | | `staff_id` | Staff |
| | | | `room_id` | Room |
| | | | `case_id` | Surgery_Case (ON DELETE SET NULL) |
| 12 | **Scan_Document** | `scan_id` | `patient_number` | Patient |
| | | | `uploaded_by_staff_id` | Staff |
| 13 | **Surgical_Procedure** | `procedure_code` | — | — |
| 14 | **Admission** | `admission_id` | `patient_number` | Patient |
| 15 | **Vital_Sign** | `vital_id` | `patient_number` | Patient |
| | | | `recorded_by_staff_id` | Staff |
| 16 | **Surgery_Case** | `case_id` | `patient_number` | Patient |
| | | | `procedure_code` | Surgical_Procedure |
| | | | `admission_id` | Admission |
| 17 | **Surgery_Schedule** | `schedule_id` | `case_id` (UNIQUE) | Surgery_Case |
| | | | `or_room_id` | Room |
| 18 | **Surgical_Team_Assignment** | `(case_id, staff_id, role)` | `case_id` | Surgery_Case |
| | | | `staff_id` | Staff |
| 19 | **IntraOp_Event** | `event_id` | `case_id` | Surgery_Case |
| 20 | **IntraOp_Medication** | `medication_id` | `case_id` | Surgery_Case |
| | | | `given_by_staff_id` | Staff |
| 21 | **Specimen** | `specimen_id` | `case_id` | Surgery_Case |
| 22 | **Implant_Device** | `implant_id` | `case_id` | Surgery_Case |
| 23 | **PACU_Record** | `pacu_id` | `case_id` (UNIQUE) | Surgery_Case |
| 24 | **Surgical_Count** | `count_id` | `case_id` | Surgery_Case |
| | | | `verified_by_staff_id` | Staff |
| 25 | **Surgery_Audit_Log** | `log_id` | `changed_by_staff_id` | Staff |

## Composite Keys

| Table | Composite PK Columns | Purpose |
|-------|----------------------|---------|
| Department_Location | `department_code` + `location` | Weak entity |
| Treats | `patient_number` + `staff_id` | M:N junction |
| Prescription_Medication | `prescription_id` + `medication_id` | M:N junction |
| Surgical_Team_Assignment | `case_id` + `staff_id` + `role` | M:N with role discriminator |

## Unique Constraints (non-PK)

| Table | Column(s) | Reason |
|-------|-----------|--------|
| Patient | `ssn` | National ID uniqueness |
| Staff | `ssn` | National ID uniqueness |
| Department | `name` | Department name uniqueness |
| Medication | `name` | Drug name uniqueness |
| Surgery_Schedule | `case_id` | One schedule per case |
| PACU_Record | `case_id` | One PACU record per case |

## Indexes

| Index | Table | Column(s) | Purpose |
|-------|-------|-----------|---------|
| `idx_staff_department` | Staff | `department_code` | FK lookup |
| `idx_staff_role` | Staff | `role` | Filter by role |
| `idx_room_hospital` | Room | `hospital_id` | FK lookup |
| `idx_room_type` | Room | `room_type` | Filter by type |
| `idx_appointment_patient` | Clinic_Appointment | `patient_number` | FK lookup |
| `idx_appointment_staff` | Clinic_Appointment | `staff_id` | FK lookup |
| `idx_appointment_date` | Clinic_Appointment | `appointment_date` | Date range queries |
| `idx_clinic_appointment_case` | Clinic_Appointment | `case_id` | FK lookup |
| `idx_prescription_staff` | Prescription | `staff_id` | FK lookup |
| `idx_prescription_patient` | Prescription | `patient_number` | FK lookup |
| `idx_treats_staff` | Treats | `staff_id` | FK lookup |
| `idx_scan_patient` | Scan_Document | `patient_number` | FK lookup |
| `idx_scan_uploader` | Scan_Document | `uploaded_by_staff_id` | FK lookup |
| `idx_surgery_patient` | Surgery_Case | `patient_number` | FK lookup |
| `idx_surgery_procedure` | Surgery_Case | `procedure_code` | FK lookup |
| `idx_surgery_status` | Surgery_Case | `status` | Status filtering |
| `idx_surgery_priority` | Surgery_Case | `priority` | Priority filtering |
| `idx_surgery_admission` | Surgery_Case | `admission_id` | FK lookup |
| `idx_schedule_case` | Surgery_Schedule | `case_id` | FK lookup |
| `idx_schedule_room` | Surgery_Schedule | `or_room_id` | FK lookup |
| `idx_schedule_dates` | Surgery_Schedule | `scheduled_start, scheduled_end` | Range queries |
| `idx_team_case` | Surgical_Team_Assignment | `case_id` | FK lookup |
| `idx_team_staff` | Surgical_Team_Assignment | `staff_id` | FK lookup |
| `idx_intraop_case` | IntraOp_Event | `case_id` | FK lookup |
| `idx_intraop_med_case` | IntraOp_Medication | `case_id` | FK lookup |
| `idx_specimen_case` | Specimen | `case_id` | FK lookup |
| `idx_implant_case` | Implant_Device | `case_id` | FK lookup |
| `idx_implant_serial` | Implant_Device | `serial_number` | Traceability |
| `idx_pacu_case` | PACU_Record | `case_id` | FK lookup |
| `idx_surgical_count_case` | Surgical_Count | `case_id` | FK lookup |
| `idx_vital_patient` | Vital_Sign | `patient_number` | FK lookup |
| `idx_vital_time` | Vital_Sign | `recorded_at` | Time-series |
| `idx_admission_patient` | Admission | `patient_number` | FK lookup |
| `idx_audit_table_time` | Surgery_Audit_Log | `table_name, changed_at` | Audit trail queries |
