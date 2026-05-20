-- ================================
-- PATIENT QUERIES (12)
-- ================================

-- 1. Patient Login
SELECT user_id, username, role, patient_number
FROM User_Account
WHERE username = $1 AND password_hash = $2 AND role = 'patient';

-- 2. View Patient Profile
SELECT patient_number, ssn, name, address, phone, birthdate, sex,
       medical_history, admission_date, blood_pressure, heart_rate,
       temperature, spo2, recorded_at
FROM Patient
WHERE patient_number = $1;

-- 3. View My Doctors
SELECT d.doctor_id, d.name, d.major_area, d.degree, d.email, d.phone,
       t.hours_per_week
FROM Treats t
JOIN Doctor d ON d.doctor_id = t.doctor_id
WHERE t.patient_number = $1
ORDER BY t.hours_per_week DESC;

-- 4. View My Appointments
SELECT a.appointment_id, a.appointment_date, a.status, a.reason,
       d.doctor_id, d.name AS doctor_name, d.major_area,
       r.room_id, r.room_number, r.room_type
FROM Appointment a
JOIN Doctor d ON d.doctor_id = a.doctor_id
LEFT JOIN Room r ON r.room_id = a.room_id
WHERE a.patient_number = $1
ORDER BY a.appointment_date DESC;

-- 5. Book Appointment
INSERT INTO Appointment (patient_number, doctor_id, room_id, appointment_date, status, reason)
VALUES ($1, $2, $3, $4, 'scheduled', $5);

-- 6. Cancel Appointment
UPDATE Appointment
SET status = 'cancelled'
WHERE appointment_id = $1 AND patient_number = $2 AND status = 'scheduled';

INSERT INTO Payment (appointment_id, amount, payment_type, description)
SELECT $1, amount, 'refund', 'Refund for cancelled appointment'
FROM Payment
WHERE appointment_id = $1 AND payment_type = 'pay';

-- 7. Make Payment
INSERT INTO Payment (appointment_id, amount, payment_type, description)
VALUES ($1, $2, 'pay', $3);

-- 8. View Payment History
SELECT p.payment_id, p.amount, p.payment_date, p.payment_type, p.description,
       a.appointment_id, a.appointment_date, a.reason
FROM Payment p
JOIN Appointment a ON a.appointment_id = p.appointment_id
WHERE a.patient_number = $1
ORDER BY p.payment_date DESC;

-- 9. View Prescriptions
SELECT pr.prescription_id, pr.prescription_date, pr.start_date, pr.end_date,
       d.doctor_id, d.name AS doctor_name,
       m.medication_id, m.name AS medication_name,
       pm.times_per_day, pm.dose
FROM Prescription pr
JOIN Doctor d ON d.doctor_id = pr.doctor_id
JOIN Prescription_Medication pm ON pm.prescription_id = pr.prescription_id
JOIN Medication m ON m.medication_id = pm.medication_id
WHERE pr.patient_number = $1
ORDER BY pr.prescription_date DESC, pr.prescription_id;

-- 10. View Scan Documents
SELECT scan_id, file_path, upload_date, description, document_type
FROM Scan_Document
WHERE patient_number = $1
ORDER BY upload_date DESC;

-- 11. Submit Contact Inquiry
INSERT INTO Contact_Inquiry (name, email, phone, subject, message, status)
VALUES ($1, $2, $3, $4, $5, 'pending');

-- 12. Find Nearest Hospital
SELECT h.name, h.address,
       gl.latitude, gl.longitude,
       (6371 * acos(cos(radians($1)) * cos(radians(gl.latitude))
        * cos(radians(gl.longitude) - radians($2))
        + sin(radians($1)) * sin(radians(gl.latitude)))) AS distance_km
FROM Geo_Location gl
JOIN Hospital h ON h.hospital_id = gl.hospital_id
ORDER BY distance_km
LIMIT 1;

-- ================================
-- DOCTOR QUERIES (11)
-- ================================

-- 13. Doctor Login
SELECT user_id, username, role, doctor_id
FROM User_Account
WHERE username = $1 AND password_hash = $2 AND role = 'doctor';

-- 14. View Doctor Profile
SELECT doctor_id, ssn, name, sex, birth_date, major_area, degree,
       department_code, join_date, email, phone
FROM Doctor
WHERE doctor_id = $1;

-- 15. View My Appointments
SELECT a.appointment_id, a.appointment_date, a.status, a.reason,
       p.patient_number, p.name AS patient_name, p.phone, p.birthdate,
       r.room_id, r.room_number
FROM Appointment a
JOIN Patient p ON p.patient_number = a.patient_number
LEFT JOIN Room r ON r.room_id = a.room_id
WHERE a.doctor_id = $1
ORDER BY a.appointment_date DESC;

-- 16. View My Patients
SELECT p.patient_number, p.name, p.phone, p.birthdate, p.sex,
       p.medical_history, p.admission_date, t.hours_per_week
FROM Treats t
JOIN Patient p ON p.patient_number = t.patient_number
WHERE t.doctor_id = $1
ORDER BY t.hours_per_week DESC;

-- 17. View Patient Details
SELECT patient_number, name, address, phone, birthdate, sex,
       medical_history, admission_date, blood_pressure, heart_rate,
       temperature, spo2, recorded_at
FROM Patient
WHERE patient_number = $1;

-- 18. Write Prescription
INSERT INTO Prescription (doctor_id, patient_number, prescription_date, start_date, end_date)
VALUES ($1, $2, $3, $4, $5)
RETURNING prescription_id;

INSERT INTO Prescription_Medication (prescription_id, medication_id, times_per_day, dose)
VALUES ($1, $2, $3, $4);

-- 19. Schedule Appointment
INSERT INTO Appointment (patient_number, doctor_id, room_id, appointment_date, status, reason)
VALUES ($1, $2, $3, $4, 'scheduled', $5);

-- 20. Cancel Appointment (Doctor)
UPDATE Appointment
SET status = 'cancelled'
WHERE appointment_id = $1 AND doctor_id = $2 AND status = 'scheduled';

-- 21. Upload Scan Document
INSERT INTO Scan_Document (patient_number, uploaded_by_doctor_id, file_path, description, document_type)
VALUES ($1, $2, $3, $4, $5);

-- 22. Reserve Room
UPDATE Room
SET is_available = FALSE
WHERE room_id = $1 AND is_available = TRUE;

-- 23. View My Surgery Schedule
SELECT sc.case_id, sc.priority, sc.status, sc.created_at,
       sp.procedure_code, sp.name AS procedure_name, sp.standard_duration_minutes,
       p.patient_number, p.name AS patient_name,
       ss.schedule_id, ss.or_room_id, ss.scheduled_start, ss.scheduled_end,
       ss.actual_start, ss.actual_end,
       sta.role
FROM Surgical_Team_Assignment sta
JOIN Surgery_Case sc ON sc.case_id = sta.case_id
JOIN Surgical_Procedure sp ON sp.procedure_code = sc.procedure_code
JOIN Patient p ON p.patient_number = sc.patient_number
LEFT JOIN Surgery_Schedule ss ON ss.case_id = sc.case_id
WHERE sta.doctor_id = $1
ORDER BY sc.created_at DESC;

-- ================================
-- ADMIN QUERIES (11)
-- ================================

-- 24. Admin Login
SELECT user_id, username, role
FROM User_Account
WHERE username = $1 AND password_hash = $2 AND role = 'admin';

-- 25. Dashboard Metrics
SELECT
  (SELECT COUNT(*) FROM Patient) AS total_patients,
  (SELECT COUNT(*) FROM Doctor) AS total_doctors,
  (SELECT COUNT(*) FROM Appointment) AS total_appointments,
  (SELECT COALESCE(SUM(CASE WHEN payment_type = 'pay' THEN amount WHEN payment_type = 'refund' THEN -amount ELSE 0 END), 0) FROM Payment) AS total_revenue,
  (SELECT COUNT(*) FROM Surgery_Case WHERE status = 'scheduled') AS scheduled_surgeries,
  (SELECT COUNT(*) FROM Surgery_Case WHERE status = 'in_or') AS in_or_surgeries,
  (SELECT COUNT(*) FROM Surgery_Case WHERE status = 'completed') AS completed_surgeries,
  (SELECT COUNT(*) FROM Surgery_Case WHERE status = 'cancelled') AS cancelled_surgeries;

-- 26. Create Doctor
INSERT INTO Doctor (ssn, name, sex, birth_date, major_area, degree, department_code, join_date, email, phone)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);

-- 27. Read Doctors
SELECT doctor_id, ssn, name, sex, birth_date, major_area, degree,
       department_code, join_date, email, phone
FROM Doctor
ORDER BY name;

-- 28. Update Doctor
UPDATE Doctor
SET ssn = $1, name = $2, sex = $3, birth_date = $4, major_area = $5,
    degree = $6, department_code = $7, join_date = $8, email = $9, phone = $10
WHERE doctor_id = $11;

-- 29. Delete Doctor
DELETE FROM Doctor WHERE doctor_id = $1;

-- 30. Create Patient
INSERT INTO Patient (patient_number, ssn, name, address, phone, birthdate, sex, medical_history, admission_date)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9);

-- 31. Read Patients
SELECT patient_number, ssn, name, address, phone, birthdate, sex,
       medical_history, admission_date, blood_pressure, heart_rate,
       temperature, spo2, recorded_at
FROM Patient
ORDER BY name;

-- 32. Update Patient
UPDATE Patient
SET ssn = $1, name = $2, address = $3, phone = $4, birthdate = $5,
    sex = $6, medical_history = $7, admission_date = $8
WHERE patient_number = $9;

-- 33. Delete Patient
DELETE FROM Patient WHERE patient_number = $1;

-- 34. Create Department
INSERT INTO Department (department_code, name, hospital_id, chairman_doctor_id, chair_start_date)
VALUES ($1, $2, $3, $4, $5);

-- 35. Read Departments
SELECT d.department_code, d.name, d.hospital_id, d.chairman_doctor_id,
       d.chair_start_date, doc.name AS chairman_name
FROM Department d
LEFT JOIN Doctor doc ON doc.doctor_id = d.chairman_doctor_id
ORDER BY d.name;

-- 36. Update Department
UPDATE Department
SET name = $1, hospital_id = $2, chairman_doctor_id = $3, chair_start_date = $4
WHERE department_code = $5;

-- 37. Delete Department
DELETE FROM Department WHERE department_code = $1;

-- 38. Create Room
INSERT INTO Room (hospital_id, room_number, room_type, or_type, has_robot, has_c_arm, is_available)
VALUES ($1, $2, $3, $4, $5, $6, $7);

-- 39. Read Rooms
SELECT room_id, hospital_id, room_number, room_type, or_type,
       has_robot, has_c_arm, is_available
FROM Room
ORDER BY room_type, room_number;

-- 40. Update Room
UPDATE Room
SET hospital_id = $1, room_number = $2, room_type = $3, or_type = $4,
    has_robot = $5, has_c_arm = $6, is_available = $7
WHERE room_id = $8;

-- 41. Delete Room
DELETE FROM Room WHERE room_id = $1;

-- 42. Toggle Room Availability
UPDATE Room SET is_available = NOT is_available WHERE room_id = $1;

-- 43. Create Surgical_Procedure
INSERT INTO Surgical_Procedure (procedure_code, name, standard_duration_minutes, required_room_type, specialty)
VALUES ($1, $2, $3, $4, $5);

-- 44. Read Surgical_Procedures
SELECT procedure_code, name, standard_duration_minutes, required_room_type, specialty
FROM Surgical_Procedure
ORDER BY name;

-- 45. Update Surgical_Procedure
UPDATE Surgical_Procedure
SET name = $1, standard_duration_minutes = $2, required_room_type = $3, specialty = $4
WHERE procedure_code = $5;

-- 46. Delete Surgical_Procedure
DELETE FROM Surgical_Procedure WHERE procedure_code = $1;

-- 47. View All Appointments (filtered)
SELECT a.appointment_id, a.appointment_date, a.status, a.reason,
       p.patient_number, p.name AS patient_name,
       d.doctor_id, d.name AS doctor_name,
       r.room_number
FROM Appointment a
JOIN Patient p ON p.patient_number = a.patient_number
JOIN Doctor d ON d.doctor_id = a.doctor_id
LEFT JOIN Room r ON r.room_id = a.room_id
WHERE ($1 IS NULL OR a.status = $1)
  AND ($2 IS NULL OR a.appointment_date::date = $2::date)
  AND ($3 IS NULL OR a.doctor_id = $3::integer)
  AND ($4 IS NULL OR a.patient_number = $4)
ORDER BY a.appointment_date DESC;

-- 48. View All Payments with Revenue
SELECT p.payment_id, p.amount, p.payment_date, p.payment_type, p.description,
       a.appointment_id, a.appointment_date, a.status AS appointment_status,
       pat.patient_number, pat.name AS patient_name
FROM Payment p
JOIN Appointment a ON a.appointment_id = p.appointment_id
JOIN Patient pat ON pat.patient_number = a.patient_number
ORDER BY p.payment_date DESC;

-- 49. Total Revenue
SELECT COALESCE(SUM(CASE WHEN payment_type = 'pay' THEN amount WHEN payment_type = 'refund' THEN -amount ELSE 0 END), 0) AS total_revenue
FROM Payment;

-- 50. View Contact Inquiries
SELECT inquiry_id, name, email, phone, subject, message, submitted_at, status
FROM Contact_Inquiry
ORDER BY submitted_at DESC;

-- 51. Mark Contact Inquiry as Closed
UPDATE Contact_Inquiry SET status = 'closed' WHERE inquiry_id = $1;

-- 52. Report: Appointments per Doctor per Month
SELECT d.doctor_id, d.name AS doctor_name,
       TO_CHAR(a.appointment_date, 'YYYY-MM') AS month,
       COUNT(*) AS appointment_count
FROM Appointment a
JOIN Doctor d ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.name, TO_CHAR(a.appointment_date, 'YYYY-MM')
ORDER BY month DESC, appointment_count DESC;

-- 53. Report: Revenue per Month
SELECT TO_CHAR(payment_date, 'YYYY-MM') AS month,
       SUM(CASE WHEN payment_type = 'pay' THEN amount ELSE 0 END) AS revenue,
       SUM(CASE WHEN payment_type = 'refund' THEN amount ELSE 0 END) AS refunds,
       SUM(CASE WHEN payment_type = 'pay' THEN amount WHEN payment_type = 'refund' THEN -amount ELSE 0 END) AS net_revenue
FROM Payment
GROUP BY TO_CHAR(payment_date, 'YYYY-MM')
ORDER BY month DESC;

-- 54. Report: Room Allocation
SELECT r.room_id, r.room_number, r.room_type, r.is_available,
       COUNT(ss.schedule_id) AS total_schedules
FROM Room r
LEFT JOIN Surgery_Schedule ss ON ss.or_room_id = r.room_id
GROUP BY r.room_id, r.room_number, r.room_type, r.is_available
ORDER BY r.room_type, r.room_number;

-- 55. Report: Surgery Status Distribution
SELECT status, COUNT(*) AS count
FROM Surgery_Case
GROUP BY status
ORDER BY status;

-- ================================
-- NURSE QUERIES (9) - role='staff'
-- ================================

-- 56. Nurse Login
SELECT user_id, username, role
FROM User_Account
WHERE username = $1 AND password_hash = $2 AND role = 'staff';

-- 57. View Today's OR Schedule
SELECT ss.schedule_id, ss.scheduled_start, ss.scheduled_end,
       ss.actual_start, ss.actual_end,
       sc.case_id, sc.priority, sc.status,
       sp.procedure_code, sp.name AS procedure_name,
       p.patient_number, p.name AS patient_name,
       r.room_id, r.room_number, r.or_type
FROM Surgery_Schedule ss
JOIN Surgery_Case sc ON sc.case_id = ss.case_id
JOIN Surgical_Procedure sp ON sp.procedure_code = sc.procedure_code
JOIN Patient p ON p.patient_number = sc.patient_number
JOIN Room r ON r.room_id = ss.or_room_id
WHERE ss.scheduled_start::date = CURRENT_DATE
ORDER BY ss.scheduled_start;

-- 58. View Surgery Cases by Status
SELECT sc.case_id, sc.priority, sc.status, sc.created_at,
       sp.name AS procedure_name,
       p.patient_number, p.name AS patient_name
FROM Surgery_Case sc
JOIN Surgical_Procedure sp ON sp.procedure_code = sc.procedure_code
JOIN Patient p ON p.patient_number = sc.patient_number
WHERE sc.status = $1
ORDER BY sc.created_at DESC;

-- 59. Assign Surgical Team
INSERT INTO Surgical_Team_Assignment (case_id, doctor_id, role)
VALUES ($1, $2, $3);

-- 60. Update Surgery Case Status
UPDATE Surgery_Case
SET status = $1
WHERE case_id = $2;

-- 61. View Patient Vitals
SELECT patient_number, name, blood_pressure, heart_rate, temperature, spo2, recorded_at
FROM Patient
WHERE patient_number = $1;

-- 62. Record PACU Data
INSERT INTO PACU_Record (case_id, arrival_time, discharge_time, aldrete_score, pain_score, complications)
VALUES ($1, $2, $3, $4, $5, $6);

-- 63. Record Surgical Count
INSERT INTO Surgical_Count (case_id, count_type, pre_count, post_count, verified_by_doctor_id)
VALUES ($1, $2, $3, $4, $5);

-- 64. View All Rooms
SELECT room_id, room_number, room_type, or_type, is_available
FROM Room
ORDER BY room_type, room_number;

-- 65. Update Room Availability
UPDATE Room SET is_available = $1 WHERE room_id = $2;
