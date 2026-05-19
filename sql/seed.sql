-- ============================================
-- Seed Data: Surgery Department — OR Module
-- ============================================

-- Hospitals
INSERT INTO Hospital (name, address) VALUES
    ('Cairo University Hospital', 'Kasr Al-Ainy, Cairo'),
    ('Alexandria Medical Center', 'Alexandria');

-- Geo_Location
INSERT INTO Geo_Location (hospital_id, latitude, longitude) VALUES
    (1, 30.0444200, 31.2357120),
    (2, 31.2000920, 29.9187390);

-- Departments
INSERT INTO Department (department_code, name, hospital_id) VALUES
    ('SURG-CAI', 'Cairo Surgery Department', 1),
    ('SURG-ALX', 'Alexandria Surgery Department', 2);

-- Doctors
INSERT INTO Doctor (ssn, name, sex, birth_date, major_area, degree, department_code, join_date, email, phone) VALUES
    ('29801011234567', 'Dr. Ahmed Hassan',    'M', '1978-01-01', 'General Surgery',        'Professor',           'SURG-CAI', '2010-09-01', 'ahmed.hassan@cuh.edu.eg',  '01001111111'),
    ('28905121234568', 'Dr. Mona Youssef',    'F', '1979-05-12', 'Cardiothoracic Surgery', 'Professor',           'SURG-CAI', '2012-03-15', 'mona.youssef@cuh.edu.eg',  '01002222222'),
    ('29508081234569', 'Dr. Khaled Ibrahim',  'M', '1985-08-08', 'Orthopedic Surgery',     'Associate Professor',  'SURG-CAI', '2015-07-01', 'khaled.ibrahim@cuh.edu.eg', '01003333333'),
    ('30011221234570', 'Dr. Sarah Ali',       'F', '1990-11-22', 'Neurosurgery',           'Consultant',          'SURG-ALX', '2018-01-15', 'sarah.ali@amc.edu.eg',     '01004444444'),
    ('29203031234571', 'Dr. Omar Mahmoud',    'M', '1982-03-03', 'Pediatric Surgery',      'Associate Professor',  'SURG-ALX', '2014-06-01', 'omar.mahmoud@amc.edu.eg',  '01005555555');

-- Set chairmen (doctor_id 1 and 4)
UPDATE Department SET chairman_doctor_id = 1, chair_start_date = '2020-01-01' WHERE department_code = 'SURG-CAI';
UPDATE Department SET chairman_doctor_id = 4, chair_start_date = '2022-03-01' WHERE department_code = 'SURG-ALX';

-- Department Locations
INSERT INTO Department_Location (department_code, location) VALUES
    ('SURG-CAI', 'Main Building, 3rd Floor'),
    ('SURG-CAI', 'Emergency Wing, Ground Floor'),
    ('SURG-ALX', 'Block A, 2nd Floor');

-- Patients (with embedded vitals)
INSERT INTO Patient (patient_number, ssn, name, address, phone, birthdate, sex, medical_history, admission_date, blood_pressure, heart_rate, temperature, spo2, recorded_at) VALUES
    ('P001', '28501101234580', 'Ali Zayed',    '12 Tahrir St, Cairo',      '01211111111', '1985-01-10', 'M', 'Appendicitis',  '2026-04-28', '120/80', 72, 37.2, 98, '2026-05-01 07:00:00'),
    ('P002', '29207071234581', 'Fatima Noor',  '45 Garden City, Cairo',     '01222222222', '1992-07-07', 'F', 'Gallstones',    '2026-05-02', '130/85', 78, 37.5, 97, '2026-05-02 08:00:00'),
    ('P003', '27805151234582', 'Hassan Omar',  '78 Nasr City, Cairo',       '01233333333', '1978-05-15', 'M', 'Hernia',        '2026-05-03', '140/90', 80, 36.9, 96, '2026-05-03 06:30:00'),
    ('P004', '30012121234583', 'Layla Samir',  '22 Smouha, Alexandria',     '01244444444', '2000-12-12', 'F', 'ACL tear',      '2026-05-10', NULL, NULL, NULL, NULL, NULL),
    ('P005', '29503181234584', 'Youssef Nabil', '5 Stanley Bay, Alexandria', '01255555555', '1995-03-18', 'M', 'Kidney stones', '2026-05-11', NULL, NULL, NULL, NULL, NULL);

-- Treats (Doctor ↔ Patient)
INSERT INTO Treats (patient_number, doctor_id, hours_per_week) VALUES
    ('P001', 1, 4),
    ('P002', 2, 3),
    ('P003', 3, 5),
    ('P004', 4, 6),
    ('P005', 5, 4),
    ('P001', 2, 2);

-- Medications
INSERT INTO Medication (name) VALUES
    ('Amoxicillin'),
    ('Ibuprofen'),
    ('Paracetamol'),
    ('Morphine'),
    ('Ciprofloxacin'),
    ('Metronidazole');

-- Prescriptions
INSERT INTO Prescription (doctor_id, patient_number, prescription_date, start_date, end_date) VALUES
    (1, 'P001', '2026-05-01', '2026-05-01', '2026-05-10'),
    (2, 'P002', '2026-05-02', '2026-05-02', '2026-05-12'),
    (3, 'P003', '2026-05-03', '2026-05-03', '2026-05-17'),
    (4, 'P004', '2026-05-04', '2026-05-04', '2026-05-14'),
    (5, 'P005', '2026-05-05', '2026-05-05', '2026-05-15');

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
INSERT INTO Room (hospital_id, room_number, room_type, or_type, has_robot, has_c_arm, laminar_flow) VALUES
    (1, 'OR-101',  'OR',    'general', FALSE, TRUE,  TRUE),
    (1, 'OR-102',  'OR',    'cardiac', FALSE, TRUE,  TRUE),
    (1, 'OR-103',  'OR',    'robotic', TRUE,  TRUE,  TRUE),
    (1, 'OR-104',  'OR',    'hybrid',  TRUE,  TRUE,  TRUE),
    (1, 'PACU-01', 'PACU',  NULL,      FALSE, FALSE, FALSE),
    (1, 'ICU-301', 'ICU',   NULL,      FALSE, FALSE, FALSE),
    (1, 'W-401',   'Ward',  NULL,      FALSE, FALSE, FALSE),
    (1, 'CL-501',  'Clinic', NULL,     FALSE, FALSE, FALSE);

-- Surgical Procedures
INSERT INTO Surgical_Procedure (procedure_code, name, standard_duration_minutes, required_room_type, specialty) VALUES
    ('CPT-47562', 'Laparoscopic Cholecystectomy',        90,  'general', 'General Surgery'),
    ('CPT-44970', 'Laparoscopic Appendectomy',           60,  'general', 'General Surgery'),
    ('CPT-49505', 'Inguinal Hernia Repair',              75,  'general', 'General Surgery'),
    ('CPT-33426', 'Mitral Valve Repair',                 240, 'cardiac', 'Cardiothoracic Surgery'),
    ('CPT-33405', 'Aortic Valve Replacement',            210, 'cardiac', 'Cardiothoracic Surgery'),
    ('CPT-27447', 'Total Knee Arthroplasty',             120, 'robotic', 'Orthopedic Surgery'),
    ('CPT-63030', 'Lumbar Laminectomy',                  120, 'general', 'Neurosurgery'),
    ('CPT-61781', 'Deep Brain Stimulator Implant',       180, 'robotic', 'Neurosurgery'),
    ('CPT-44140', 'Partial Colectomy',                   150, 'general', 'General Surgery');

-- Surgery Cases
INSERT INTO Surgery_Case (patient_number, procedure_code, priority, status, cancel_reason) VALUES
    ('P001', 'CPT-44970', 'elective',  'completed', NULL),
    ('P002', 'CPT-47562', 'elective',  'scheduled', NULL),
    ('P003', 'CPT-49505', 'elective',  'pre_op',    NULL),
    ('P004', 'CPT-27447', 'elective',  'scheduled', NULL),
    ('P005', 'CPT-44140', 'emergency', 'scheduled', NULL);

-- Surgery Schedules
INSERT INTO Surgery_Schedule (case_id, or_room_id, scheduled_start, scheduled_end, actual_start, actual_end) VALUES
    (1, 1, '2026-05-01 08:00:00', '2026-05-01 09:00:00', '2026-05-01 08:05:00', '2026-05-01 08:55:00'),
    (2, 1, '2026-05-11 08:00:00', '2026-05-11 09:30:00', NULL, NULL),
    (3, 1, '2026-05-12 09:00:00', '2026-05-12 10:15:00', NULL, NULL),
    (4, 3, '2026-05-13 10:00:00', '2026-05-13 12:00:00', NULL, NULL),
    (5, 2, '2026-05-14 02:00:00', '2026-05-14 04:30:00', NULL, NULL);

-- Surgical Team Assignments
INSERT INTO Surgical_Team_Assignment (case_id, doctor_id, role) VALUES
    (1, 1, 'primary_surgeon'),
    (1, 2, 'assistant'),
    (1, 3, 'anesthesiologist'),
    (2, 2, 'primary_surgeon'),
    (2, 1, 'assistant'),
    (3, 3, 'primary_surgeon'),
    (4, 4, 'primary_surgeon'),
    (5, 1, 'primary_surgeon');

-- Appointments
INSERT INTO Appointment (patient_number, doctor_id, room_id, appointment_date, status, reason, case_id) VALUES
    ('P001', 1, 8, '2026-04-28 09:00:00', 'completed', 'Pre-op assessment', 1),
    ('P001', 1, 8, '2026-05-05 10:00:00', 'scheduled', 'Post-op follow-up', 1),
    ('P002', 2, 8, '2026-05-08 11:00:00', 'scheduled', 'Pre-op assessment', 2),
    ('P003', 3, 8, '2026-05-09 14:00:00', 'scheduled', 'Pre-op assessment', 3);

-- Payments (linked to appointments)
INSERT INTO Payment (appointment_id, amount, payment_date, payment_type, description) VALUES
    (1, 500.00, '2026-04-28 09:00:00', 'register', 'Registration fee - Pre-op assessment'),
    (2, 200.00, '2026-05-05 10:00:00', 'pay',      'Post-op follow-up visit');

-- Users
INSERT INTO "User" (username, password_hash, role, doctor_id, patient_number) VALUES
    ('ahmed.hassan', 'hash_ahmed_123',  'doctor', 1, NULL),
    ('mona.youssef', 'hash_mona_456',   'doctor', 2, NULL),
    ('khaled.ibrahim', 'hash_khaled_789', 'doctor', 3, NULL),
    ('sarah.ali',    'hash_sarah_012',  'doctor', 4, NULL),
    ('omar.mahmoud', 'hash_omar_345',   'doctor', 5, NULL),
    ('ali.zayed',    'hash_ali_678',    'staff',  NULL, 'P001');

-- Contact Inquiries
INSERT INTO Contact_Inquiry (name, email, phone, subject, message, status) VALUES
    ('Ali Zayed',    'ali.zayed@email.com',  '01211111111', 'Surgery date change',   'Can I reschedule my appendectomy to next week?', 'pending'),
    ('Fatima Noor',  'fatima.noor@email.com', '01222222222', 'Billing question',     'What is the total cost of gallbladder surgery?', 'read'),
    ('Hassan Omar',  'hassan.omar@email.com', '01233333333', 'Pre-op instructions', 'Do I need to stop taking blood thinners before surgery?', 'replied');

-- Scan Documents
INSERT INTO Scan_Document (patient_number, uploaded_by_doctor_id, file_path, upload_date, description, document_type) VALUES
    ('P001', 1, '/uploads/scans/p001_ct_scan.pdf',   '2026-04-28 10:00:00', 'CT Scan - Abdomen',      'imaging'),
    ('P001', 1, '/uploads/scans/p001_consent.pdf',   '2026-04-28 11:00:00', 'Surgery consent form',   'consent'),
    ('P002', 2, '/uploads/scans/p002_ultrasound.pdf','2026-05-02 14:00:00', 'Ultrasound - Gallbladder', 'imaging'),
    ('P003', 3, '/uploads/scans/p003_mri.pdf',        '2026-05-03 09:00:00', 'MRI - Lower abdomen',    'imaging'),
    ('P001', 1, '/uploads/scans/p001_op_report.pdf',  '2026-05-01 15:00:00', 'Operative Report - Appendectomy', 'operative_report');
