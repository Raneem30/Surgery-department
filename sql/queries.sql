-- ============================================
-- Sample Queries: Surgery Department HIS
-- ============================================

-- -------------------------------------------------
-- 1. List all patients in the Surgery Department with their vital signs
-- -------------------------------------------------
SELECT p.patient_number, p.name, p.blood_pressure, p.heart_rate, p.temperature, p.admission_date
FROM Patient p
ORDER BY p.admission_date DESC;

-- -------------------------------------------------
-- 2. Find all doctors in the Surgery Department (Cairo)
-- -------------------------------------------------
SELECT d.ssn, d.name, d.major_area, d.degree
FROM Doctor d
JOIN Department dept ON d.department_code = dept.department_code
WHERE dept.name = 'Surgery Department' AND dept.hospital_id = 1;

-- -------------------------------------------------
-- 3. Show each doctor's patient load (number of patients they treat)
-- -------------------------------------------------
SELECT d.name AS doctor_name, COUNT(t.patient_number) AS patient_count
FROM Doctor d
LEFT JOIN Treats t ON d.ssn = t.doctor_ssn
GROUP BY d.name
ORDER BY patient_count DESC;

-- -------------------------------------------------
-- 4. List upcoming appointments with patient and doctor details
-- -------------------------------------------------
SELECT a.appointment_id, p.name AS patient_name, d.name AS doctor_name,
       a.appointment_date, a.status, a.reason
FROM Appointment a
JOIN Patient p ON a.patient_number = p.patient_number
JOIN Doctor d ON a.doctor_ssn = d.ssn
WHERE a.status = 'scheduled' AND a.appointment_date >= CURRENT_TIMESTAMP
ORDER BY a.appointment_date;

-- -------------------------------------------------
-- 5. Room allocation report (which rooms are used/busy)
-- -------------------------------------------------
SELECT r.room_id, r.room_number, r.room_type, r.hospital_id,
       CASE WHEN r.is_available THEN 'Available' ELSE 'Occupied' END AS status
FROM Room r
ORDER BY r.room_type, r.room_number;

-- -------------------------------------------------
-- 6. Find available operating rooms
-- -------------------------------------------------
SELECT r.room_id, r.room_number, h.name AS hospital
FROM Room r
JOIN Hospital h ON r.hospital_id = h.hospital_id
WHERE r.room_type = 'Operating Room' AND r.is_available = TRUE;

-- -------------------------------------------------
-- 7. Patient medication history (prescriptions + details)
-- -------------------------------------------------
SELECT p.patient_number, pat.name AS patient_name,
       pr.prescription_id, pr.prescription_date, m.name AS medication,
       pm.times_per_day, pm.dose, pr.start_date, pr.end_date
FROM Prescription pr
JOIN Patient pat ON pr.patient_number = pat.patient_number
JOIN Prescription_Medication pm ON pr.prescription_id = pm.prescription_id
JOIN Medication m ON pm.medication_id = m.medication_id
ORDER BY pat.name, pr.prescription_date;

-- -------------------------------------------------
-- 8. Payment report: total revenue per hospital
-- -------------------------------------------------
SELECT h.name AS hospital, SUM(py.amount) AS total_revenue
FROM Payment py
JOIN Appointment a ON py.appointment_id = a.appointment_id
JOIN Doctor d ON a.doctor_ssn = d.ssn
JOIN Department dept ON d.department_code = dept.department_code
JOIN Hospital h ON dept.hospital_id = h.hospital_id
WHERE py.status = 'paid'
GROUP BY h.name;

-- -------------------------------------------------
-- 9. Cancelled appointments with refund info
-- -------------------------------------------------
SELECT a.appointment_id, p.name AS patient_name, d.name AS doctor_name,
       a.appointment_date, a.reason,
       py.amount AS refund_amount, py.payment_date AS refund_date
FROM Appointment a
JOIN Patient p ON a.patient_number = p.patient_number
JOIN Doctor d ON a.doctor_ssn = d.ssn
JOIN Payment py ON a.appointment_id = py.appointment_id
WHERE a.status = 'cancelled' AND py.status = 'refunded';

-- -------------------------------------------------
-- 10. Doctor workload: total hours per week per doctor
-- -------------------------------------------------
SELECT d.name AS doctor_name, d.major_area,
       COALESCE(SUM(t.hours_per_week), 0) AS total_hours_per_week
FROM Doctor d
LEFT JOIN Treats t ON d.ssn = t.doctor_ssn
GROUP BY d.name, d.major_area
ORDER BY total_hours_per_week DESC;

-- -------------------------------------------------
-- 11. Admin dashboard: statistics summary
-- -------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM Patient) AS total_patients,
    (SELECT COUNT(*) FROM Doctor) AS total_doctors,
    (SELECT COUNT(*) FROM Appointment) AS total_appointments,
    (SELECT COUNT(*) FROM Appointment WHERE status = 'scheduled') AS upcoming_appointments,
    (SELECT COUNT(*) FROM Appointment WHERE status = 'cancelled') AS cancelled_appointments,
    (SELECT COUNT(*) FROM Room WHERE room_type = 'Operating Room' AND is_available = TRUE) AS available_ORs,
    (SELECT COALESCE(SUM(amount), 0) FROM Payment WHERE status = 'paid') AS total_revenue;

-- -------------------------------------------------
-- 12. Find nearest hospital (example for Cairo coordinates)
-- -------------------------------------------------
SELECT h.name, h.address,
       gl.latitude, gl.longitude,
       SQRT(POWER(gl.latitude - 30.0444, 2) + POWER(gl.longitude - 31.2357, 2)) AS distance
FROM Hospital h
JOIN Geo_Location gl ON gl.entity_id = h.hospital_id AND gl.entity_type = 'Hospital'
ORDER BY distance
LIMIT 1;

-- -------------------------------------------------
-- 13. Patients treated by more than one doctor
-- -------------------------------------------------
SELECT p.patient_number, p.name, COUNT(t.doctor_ssn) AS doctor_count
FROM Patient p
JOIN Treats t ON p.patient_number = t.patient_number
GROUP BY p.patient_number, p.name
HAVING COUNT(t.doctor_ssn) > 1;

-- -------------------------------------------------
-- 14. Appointment room utilization per month
-- -------------------------------------------------
SELECT TO_CHAR(a.appointment_date, 'YYYY-MM') AS month,
       r.room_type, COUNT(a.appointment_id) AS usage_count
FROM Appointment a
JOIN Room r ON a.room_id = r.room_id
WHERE a.status != 'cancelled'
GROUP BY month, r.room_type
ORDER BY month, r.room_type;

-- -------------------------------------------------
-- 15. Prescriptions written per doctor (with counts)
-- -------------------------------------------------
SELECT d.name AS doctor_name, COUNT(pr.prescription_id) AS prescription_count
FROM Doctor d
LEFT JOIN Prescription pr ON d.ssn = pr.doctor_ssn
GROUP BY d.name
ORDER BY prescription_count DESC;
