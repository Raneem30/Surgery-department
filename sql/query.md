| # | Query Name | Purpose | Parameters | Returns | Role |
|---|-----------|---------|-----------|---------|------|
| 1 | Login | Authenticate patient | username, password | user_id, username, role, patient_number | Patient |
| 2 | View Profile | Show patient profile | patient_number | All Patient columns | Patient |
| 3 | View My Doctors | List doctors treating patient | patient_number | doctor_id, name, major_area, degree, email, phone, hours_per_week | Patient |
| 4 | View My Appointments | List patient appointments | patient_number | appointment_id, date, status, reason, doctor details, room details | Patient |
| 5 | Book Appointment | Schedule new appointment | patient_number, doctor_id, room_id, appointment_date, reason | Inserted row | Patient |
| 6 | Cancel Appointment | Cancel + issue refund | appointment_id, patient_number | Updated status; inserted refund Payment | Patient |
| 7 | Make Payment | Pay for appointment | appointment_id, amount, description | Inserted Payment row | Patient |
| 8 | View Payment History | All payments for patient | patient_number | payment_id, amount, date, type, description, appointment details | Patient |
| 9 | View Prescriptions | Prescriptions + meds | patient_number | prescription_id, date, doctor, medication name, dose, times_per_day | Patient |
| 10 | View Scan Documents | List uploaded scans | patient_number | scan_id, file_path, upload_date, description, document_type | Patient |
| 11 | Submit Contact Inquiry | File a complaint/question | name, email, phone, subject, message | Inserted Contact_Inquiry row | Patient |
| 12 | Find Nearest Hospital | Distance from lat/lon | latitude, longitude | hospital name, address, lat, lon, distance_km | Patient |
| 13 | Login | Authenticate doctor | username, password | user_id, username, role, doctor_id | Doctor |
| 14 | View Profile | Show doctor profile | doctor_id | All Doctor columns | Doctor |
| 15 | View My Appointments | List doctor appointments | doctor_id | appointment_id, date, status, patient details, room | Doctor |
| 16 | View My Patients | List treated patients | doctor_id | patient_number, name, phone, medical_history, hours_per_week | Doctor |
| 17 | View Patient Details | Full patient info+vitals | patient_number | All Patient columns including vitals | Doctor |
| 18 | Write Prescription | Insert prescription + meds | doctor_id, patient_number, dates, medication details | prescription_id; inserted Prescription_Medication rows | Doctor |
| 19 | Schedule Appointment | Book appointment (doctor) | patient_number, doctor_id, room_id, date, reason | Inserted Appointment row | Doctor |
| 20 | Cancel Appointment | Doctor cancels | appointment_id, doctor_id | Updated status | Doctor |
| 21 | Upload Scan | Save scan document | patient_number, doctor_id, file_path, description, type | Inserted Scan_Document row | Doctor |
| 22 | Reserve Room | Mark room unavailable | room_id | Updated is_available = FALSE | Doctor |
| 23 | View My Surgery Schedule | Doctor's surgeries | doctor_id | case_id, procedure, patient, schedule, role | Doctor |
| 24 | Login | Authenticate admin | username, password | user_id, username, role | Admin |
| 25 | Dashboard | Show key metrics | none | patient/doctor/appointment counts, revenue, surgery stats | Admin |
| 26 | Create Doctor | Add new doctor | ssn, name, sex, birth, major_area, degree, dept, join, email, phone | Inserted Doctor row | Admin |
| 27 | Read Doctors | List all doctors | none | All Doctor columns | Admin |
| 28 | Update Doctor | Edit doctor | all doctor fields + doctor_id | Updated Doctor row | Admin |
| 29 | Delete Doctor | Remove doctor | doctor_id | Deleted Doctor row | Admin |
| 30 | Create Patient | Add new patient | patient_number, ssn, name, address, phone, birthdate, sex, history, admission | Inserted Patient row | Admin |
| 31 | Read Patients | List all patients | none | All Patient columns | Admin |
| 32 | Update Patient | Edit patient | patient fields + patient_number | Updated Patient row | Admin |
| 33 | Delete Patient | Remove patient | patient_number | Deleted Patient row | Admin |
| 34 | Create Department | Add department | code, name, hospital_id, chairman_id, start_date | Inserted Department row | Admin |
| 35 | Read Departments | List all departments | none | department details + chairman name | Admin |
| 36 | Update Department | Edit department | name, hospital_id, chairman, start_date + code | Updated Department row | Admin |
| 37 | Delete Department | Remove department | department_code | Deleted Department row | Admin |
| 38 | Create Room | Add room | hospital_id, room_number, type, or_type, has_robot, has_c_arm, available | Inserted Room row | Admin |
| 39 | Read Rooms | List all rooms | none | All Room columns | Admin |
| 40 | Update Room | Edit room | room fields + room_id | Updated Room row | Admin |
| 41 | Delete Room | Remove room | room_id | Deleted Room row | Admin |
| 42 | Toggle Room Availability | Flip is_available | room_id | Updated Room row | Admin |
| 43 | Create Procedure | Add surgical procedure | code, name, duration, room_type, specialty | Inserted Surgical_Procedure row | Admin |
| 44 | Read Procedures | List all procedures | none | All Surgical_Procedure columns | Admin |
| 45 | Update Procedure | Edit procedure | name, duration, room_type, specialty + code | Updated Surgical_Procedure row | Admin |
| 46 | Delete Procedure | Remove procedure | procedure_code | Deleted Surgical_Procedure row | Admin |
| 47 | View All Appointments | Filtered appointment list | status, date, doctor_id, patient_number | appointment details + patient/doctor/room | Admin |
| 48 | View All Payments | All payments with details | none | payment_id, amount, date, type, appointment, patient | Admin |
| 49 | Total Revenue | Calculate net revenue | none | total_revenue (pay - refund) | Admin |
| 50 | View Contact Inquiries | List inquiries | none | All Contact_Inquiry columns | Admin |
| 51 | Mark Inquiry Closed | Update status | inquiry_id | Updated Contact_Inquiry row | Admin |
| 52 | Appointments per Doctor/Month | Report | none | doctor_id, name, month, count | Admin |
| 53 | Revenue per Month | Report | none | month, revenue, refunds, net_revenue | Admin |
| 54 | Room Allocation | Report | none | room_id, number, type, available, schedule count | Admin |
| 55 | Surgery Status Distribution | Report | none | status, count | Admin |
| 56 | Login | Authenticate nurse (staff) | username, password | user_id, username, role | Nurse |
| 57 | View Today's OR Schedule | Daily schedule | none | schedule, case, procedure, patient, room details | Nurse |
| 58 | View Surgery Cases by Status | Filter cases | status | case_id, priority, status, procedure, patient | Nurse |
| 59 | Assign Surgical Team | Add team member | case_id, doctor_id, role | Inserted Surgical_Team_Assignment row | Nurse |
| 60 | Update Surgery Case Status | Change case status | status, case_id | Updated Surgery_Case row | Nurse |
| 61 | View Patient Vitals | Read vitals | patient_number | blood_pressure, heart_rate, temperature, spo2, recorded_at | Nurse |
| 62 | Record PACU Data | Insert PACU record | case_id, arrival, discharge, aldrete, pain, complications | Inserted PACU_Record row | Nurse |
| 63 | Record Surgical Count | Insert count record | case_id, count_type, pre_count, post_count, doctor_id | Inserted Surgical_Count row | Nurse |
| 64 | View Room Availability | List rooms | none | room_id, number, type, is_available | Nurse |
| 65 | Update Room Availability | Set room status | is_available, room_id | Updated Room row | Nurse |
