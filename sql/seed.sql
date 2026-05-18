-- ============================================
-- Seed Data: Surgery Department
-- ============================================

-- Hospitals
INSERT INTO Hospital (name, address) VALUES
    ('Cairo University Hospital', 'Kasr Al-Ainy, Cairo'),
    ('Alexandria Medical Center', 'Alexandria');

-- Departments
INSERT INTO Department (department_code, name, hospital_id) VALUES
    ('SURG-CAI', 'Surgery Department', 1),
    ('SURG-ALX', 'Surgery Department', 2);

-- Doctors
INSERT INTO Doctor (ssn, name, sex, birth_date, major_area, degree, department_code, join_date, email, phone) VALUES
    ('29801011234567', 'Dr. Ahmed Hassan', 'M', '1978-01-01', 'General Surgery', 'Professor', 'SURG-CAI', '2010-09-01', 'ahmed.hassan@cuh.edu.eg', '01001111111'),
    ('28905121234568', 'Dr. Mona Youssef', 'F', '1979-05-12', 'Cardiothoracic Surgery', 'Professor', 'SURG-CAI', '2012-03-15', 'mona.youssef@cuh.edu.eg', '01002222222'),
    ('29508081234569', 'Dr. Khaled Ibrahim', 'M', '1985-08-08', 'Orthopedic Surgery', 'Associate Professor', 'SURG-CAI', '2015-07-01', 'khaled.ibrahim@cuh.edu.eg', '01003333333'),
    ('30011221234570', 'Dr. Sarah Ali', 'F', '1990-11-22', 'Neurosurgery', 'Consultant', 'SURG-ALX', '2018-01-15', 'sarah.ali@amc.edu.eg', '01004444444'),
    ('29203031234571', 'Dr. Omar Mahmoud', 'M', '1982-03-03', 'Pediatric Surgery', 'Associate Professor', 'SURG-ALX', '2014-06-01', 'omar.mahmoud@amc.edu.eg', '01005555555');

-- Set chairmen
UPDATE Department SET chairman_ssn = '29801011234567', chair_start_date = '2020-01-01' WHERE department_code = 'SURG-CAI';
UPDATE Department SET chairman_ssn = '30011221234570', chair_start_date = '2022-03-01' WHERE department_code = 'SURG-ALX';

-- Department Locations
INSERT INTO Department_Location (department_code, location) VALUES
    ('SURG-CAI', 'Main Building, 3rd Floor'),
    ('SURG-CAI', 'Emergency Wing, Ground Floor'),
    ('SURG-ALX', 'Block A, 2nd Floor');

-- Patients
INSERT INTO Patient (patient_number, ssn, name, address, phone, birthdate, sex, medical_history, blood_pressure, heart_rate, temperature, admission_date) VALUES
    ('P001', '28501101234580', 'Ali Zayed', '12 Tahrir St, Cairo', '01211111111', '1985-01-10', 'M', 'Appendicitis', '120/80', 72, 37.2, '2026-05-01'),
    ('P002', '29207071234581', 'Fatima Noor', '45 Garden City, Cairo', '01222222222', '1992-07-07', 'F', 'Gallstones', '130/85', 78, 37.5, '2026-05-02'),
    ('P003', '27805151234582', 'Hassan Omar', '78 Nasr City, Cairo', '01233333333', '1978-05-15', 'M', 'Hernia', '140/90', 80, 36.9, '2026-05-03'),
    ('P004', '30012121234583', 'Layla Samir', '22 Smouha, Alexandria', '01244444444', '2000-12-12', 'F', 'ACL tear', '115/75', 68, 37.0, '2026-05-04'),
    ('P005', '29503181234584', 'Youssef Nabil', '5 Stanley Bay, Alexandria', '01255555555', '1995-03-18', 'M', 'Kidney stones', '125/82', 75, 37.3, '2026-05-05');

-- Treats (Doctor-Patient)
INSERT INTO Treats (patient_number, doctor_ssn, hours_per_week) VALUES
    ('P001', '29801011234567', 4),
    ('P002', '28905121234568', 3),
    ('P003', '29508081234569', 5),
    ('P004', '30011221234570', 6),
    ('P005', '29203031234571', 4),
    ('P001', '28905121234568', 2); -- Patient under two doctors

-- Medications
INSERT INTO Medication (name) VALUES
    ('Amoxicillin'),
    ('Ibuprofen'),
    ('Paracetamol'),
    ('Morphine'),
    ('Ciprofloxacin'),
    ('Metronidazole');

-- Prescriptions
INSERT INTO Prescription (doctor_ssn, patient_number, prescription_date, start_date, end_date) VALUES
    ('29801011234567', 'P001', '2026-05-01', '2026-05-01', '2026-05-10'),
    ('28905121234568', 'P002', '2026-05-02', '2026-05-02', '2026-05-12'),
    ('29508081234569', 'P003', '2026-05-03', '2026-05-03', '2026-05-17'),
    ('30011221234570', 'P004', '2026-05-04', '2026-05-04', '2026-05-14'),
    ('29203031234571', 'P005', '2026-05-05', '2026-05-05', '2026-05-15');

-- Prescription_Medication
INSERT INTO Prescription_Medication (prescription_id, medication_id, times_per_day, dose) VALUES
    (1, 1, 3, '500mg'),
    (1, 3, 2, '500mg'),
    (2, 2, 3, '400mg'),
    (2, 5, 2, '250mg'),
    (3, 6, 3, '500mg'),
    (4, 4, 1, '10mg'),
    (5, 1, 2, '500mg');

-- Rooms
INSERT INTO Room (hospital_id, room_number, room_type, is_available) VALUES
    (1, 'OR-101', 'Operating Room', TRUE),
    (1, 'OR-102', 'Operating Room', TRUE),
    (1, 'RR-201', 'Recovery Room', TRUE),
    (1, 'RR-202', 'Recovery Room', TRUE),
    (1, 'ICU-301', 'ICU', TRUE),
    (2, 'OR-101', 'Operating Room', TRUE),
    (2, 'RR-201', 'Recovery Room', TRUE),
    (2, 'ICU-301', 'ICU', TRUE);

-- Appointments
INSERT INTO Appointment (patient_number, doctor_ssn, room_id, appointment_date, status, reason) VALUES
    ('P001', '29801011234567', 1, '2026-05-10 09:00:00', 'scheduled', 'Appendectomy'),
    ('P002', '28905121234568', 2, '2026-05-11 10:00:00', 'scheduled', 'Cholecystectomy'),
    ('P003', '29508081234569', 3, '2026-05-12 11:00:00', 'scheduled', 'Hernia repair'),
    ('P004', '30011221234570', 6, '2026-05-13 14:00:00', 'scheduled', 'ACL reconstruction'),
    ('P005', '29203031234571', 7, '2026-05-14 09:30:00', 'scheduled', 'Lithotripsy'),
    ('P001', '28905121234568', NULL, '2026-05-15 15:00:00', 'cancelled', 'Follow-up cancelled');

-- Payments
INSERT INTO Payment (appointment_id, amount, payment_date, payment_method, status) VALUES
    (1, 5000.00, '2026-05-08 12:00:00', 'Credit Card', 'paid'),
    (2, 8000.00, '2026-05-09 14:00:00', 'Bank Transfer', 'paid'),
    (3, 4000.00, '2026-05-10 10:00:00', 'Cash', 'paid'),
    (4, 15000.00, '2026-05-11 09:00:00', 'Credit Card', 'paid'),
    (5, 6000.00, '2026-05-12 11:00:00', 'Credit Card', 'paid'),
    (6, 3000.00, '2026-05-14 10:00:00', 'Cash', 'refunded');

-- Users
INSERT INTO "User" (username, password_hash, role, person_type, person_id) VALUES
    ('ali.zayed', 'hash_placeholder_001', 'patient', 'Patient', 'P001'),
    ('fatima.noor', 'hash_placeholder_002', 'patient', 'Patient', 'P002'),
    ('ahmed.hassan', 'hash_placeholder_003', 'doctor', 'Doctor', '29801011234567'),
    ('mona.youssef', 'hash_placeholder_004', 'doctor', 'Doctor', '28905121234568'),
    ('admin', 'hash_placeholder_admin', 'admin', NULL, NULL),
    ('nurse.sara', 'hash_placeholder_005', 'nurse', NULL, NULL);

-- Contact Inquiries
INSERT INTO Contact_Inquiry (name, email, subject, message, submitted_at, is_resolved) VALUES
    ('Karim Adel', 'karim@example.com', 'Appointment inquiry', 'I would like to book a consultation for my father.', '2026-05-01 10:30:00', TRUE),
    ('Nadia Samir', 'nadia@example.com', 'Billing question', 'I have a question about my recent payment.', '2026-05-03 15:45:00', FALSE);

-- Geo Locations
INSERT INTO Geo_Location (latitude, longitude, address, entity_type, entity_id) VALUES
    (30.0444, 31.2357, 'Kasr Al-Ainy, Cairo', 'Hospital', 1),
    (31.2001, 29.9187, 'Alexandria', 'Hospital', 2);

-- Scan Documents
INSERT INTO Scan_Document (patient_number, doctor_ssn, file_path, upload_date, description) VALUES
    ('P001', '29801011234567', '/uploads/scans/p001_ct_scan.pdf', '2026-05-01 11:00:00', 'CT Scan - Abdomen'),
    ('P002', '28905121234568', '/uploads/scans/p002_ultrasound.pdf', '2026-05-02 14:00:00', 'Ultrasound - Gallbladder'),
    ('P003', '29508081234569', '/uploads/scans/p003_mri.pdf', '2026-05-03 09:00:00', 'MRI - Lower abdomen');
