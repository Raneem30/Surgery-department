-- ============================================
-- Seed Data: Surgery Department — OR Module
-- ============================================

-- Hospitals
INSERT INTO Hospital (name, address) VALUES
    ('Cairo University Hospital', 'Kasr Al-Ainy, Cairo'),
    ('Alexandria Medical Center', 'Alexandria');

-- Departments
INSERT INTO Department (department_code, name, hospital_id) VALUES
    ('SURG-CAI', 'Surgery Department', 1),
    ('SURG-ALX', 'Surgery Department', 2);

-- Staff (doctors, nurses, techs)
INSERT INTO Staff (ssn, name, role, sex, birth_date, major_area, degree, department_code, join_date, email, phone) VALUES
    ('29801011234567', 'Dr. Ahmed Hassan',     'doctor', 'M', '1978-01-01', 'General Surgery',         'Professor',         'SURG-CAI', '2010-09-01', 'ahmed.hassan@cuh.edu.eg',   '01001111111'),
    ('28905121234568', 'Dr. Mona Youssef',     'doctor', 'F', '1979-05-12', 'Cardiothoracic Surgery',  'Professor',         'SURG-CAI', '2012-03-15', 'mona.youssef@cuh.edu.eg',   '01002222222'),
    ('29508081234569', 'Dr. Khaled Ibrahim',   'doctor', 'M', '1985-08-08', 'Orthopedic Surgery',      'Associate Professor', 'SURG-CAI', '2015-07-01', 'khaled.ibrahim@cuh.edu.eg', '01003333333'),
    ('30011221234570', 'Dr. Sarah Ali',        'doctor', 'F', '1990-11-22', 'Neurosurgery',            'Consultant',        'SURG-ALX', '2018-01-15', 'sarah.ali@amc.edu.eg',      '01004444444'),
    ('29203031234571', 'Dr. Omar Mahmoud',     'doctor', 'M', '1982-03-03', 'Pediatric Surgery',       'Associate Professor', 'SURG-ALX', '2014-06-01', 'omar.mahmoud@amc.edu.eg',   '01005555555'),
    ('28807151234572', 'Nurse Fatima Hassan',  'nurse',  'F', '1988-07-15', NULL, NULL,                 'SURG-CAI', '2016-04-01', 'fatima.hassan@cuh.edu.eg',  '01006666666'),
    ('29711231234573', 'Nurse Ahmed Said',     'nurse',  'M', '1997-11-23', NULL, NULL,                 'SURG-CAI', '2019-08-15', 'ahmed.said@cuh.edu.eg',     '01007777777');

-- Set chairmen (staff_id 1 and 4)
UPDATE Department SET chairman_staff_id = 1, chair_start_date = '2020-01-01' WHERE department_code = 'SURG-CAI';
UPDATE Department SET chairman_staff_id = 4, chair_start_date = '2022-03-01' WHERE department_code = 'SURG-ALX';

-- Department Locations
INSERT INTO Department_Location (department_code, location) VALUES
    ('SURG-CAI', 'Main Building, 3rd Floor'),
    ('SURG-CAI', 'Emergency Wing, Ground Floor'),
    ('SURG-ALX', 'Block A, 2nd Floor');

-- Patients
INSERT INTO Patient (patient_number, ssn, name, address, phone, birthdate, sex, medical_history) VALUES
    ('P001', '28501101234580', 'Ali Zayed',    '12 Tahrir St, Cairo',        '01211111111', '1985-01-10', 'M', 'Appendicitis'),
    ('P002', '29207071234581', 'Fatima Noor',  '45 Garden City, Cairo',       '01222222222', '1992-07-07', 'F', 'Gallstones'),
    ('P003', '27805151234582', 'Hassan Omar',  '78 Nasr City, Cairo',         '01233333333', '1978-05-15', 'M', 'Hernia'),
    ('P004', '30012121234583', 'Layla Samir',  '22 Smouha, Alexandria',       '01244444444', '2000-12-12', 'F', 'ACL tear'),
    ('P005', '29503181234584', 'Youssef Nabil','5 Stanley Bay, Alexandria',   '01255555555', '1995-03-18', 'M', 'Kidney stones');

-- Treats (Staff-Patient)
INSERT INTO Treats (patient_number, staff_id, hours_per_week) VALUES
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
INSERT INTO Prescription (staff_id, patient_number, prescription_date, start_date, end_date) VALUES
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
    (1, 'OR-101', 'OR', 'general',   FALSE, TRUE,  TRUE),
    (1, 'OR-102', 'OR', 'cardiac',   FALSE, TRUE,  TRUE),
    (1, 'OR-103', 'OR', 'robotic',   TRUE,  TRUE,  TRUE),
    (1, 'OR-104', 'OR', 'hybrid',    TRUE,  TRUE,  TRUE),
    (1, 'PACU-01', 'PACU', NULL,     FALSE, FALSE, FALSE),
    (1, 'ICU-301', 'ICU', NULL,      FALSE, FALSE, FALSE),
    (1, 'W-401',   'Ward', NULL,     FALSE, FALSE, FALSE),
    (1, 'CL-501',  'Clinic', NULL,   FALSE, FALSE, FALSE);

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

-- Admissions
INSERT INTO Admission (patient_number, admission_date, discharge_date, bed_number) VALUES
    ('P001', '2026-05-01', '2026-05-03', 'W-401-A'),
    ('P002', '2026-05-02', NULL,          'W-401-B'),
    ('P003', '2026-05-03', NULL,          NULL);

-- Vital Signs
INSERT INTO Vital_Sign (patient_number, recorded_at, blood_pressure, heart_rate, temperature, spo2, recorded_by_staff_id) VALUES
    ('P001', '2026-05-01 07:00:00', '120/80', 72, 37.2, 98, 1),
    ('P001', '2026-05-01 14:00:00', '118/78', 70, 37.0, 99, 1),
    ('P002', '2026-05-02 08:00:00', '130/85', 78, 37.5, 97, 2),
    ('P003', '2026-05-03 06:30:00', '140/90', 80, 36.9, 96, 3);

-- Surgery Cases
INSERT INTO Surgery_Case (patient_number, procedure_code, priority, status, admission_id, cancel_reason) VALUES
    ('P001', 'CPT-44970', 'elective',  'completed', 1, NULL),
    ('P002', 'CPT-47562', 'elective',  'scheduled', 2, NULL),
    ('P003', 'CPT-49505', 'elective',  'pre_op',    3, NULL),
    ('P004', 'CPT-27447', 'elective',  'scheduled', NULL, NULL),
    ('P005', 'CPT-44140', 'emergency', 'scheduled', NULL, NULL);

-- Surgery Schedules
INSERT INTO Surgery_Schedule (case_id, or_room_id, scheduled_start, scheduled_end, actual_start, actual_end) VALUES
    (1, 1, '2026-05-01 08:00:00', '2026-05-01 09:00:00', '2026-05-01 08:05:00', '2026-05-01 08:55:00'),
    (2, 1, '2026-05-11 08:00:00', '2026-05-11 09:30:00', NULL, NULL),
    (3, 1, '2026-05-12 09:00:00', '2026-05-12 10:15:00', NULL, NULL),
    (4, 3, '2026-05-13 10:00:00', '2026-05-13 12:00:00', NULL, NULL),
    (5, 2, '2026-05-14 02:00:00', '2026-05-14 04:30:00', NULL, NULL);

-- Surgical Team Assignments (using staff_id)
INSERT INTO Surgical_Team_Assignment (case_id, staff_id, role) VALUES
    (1, 1, 'primary_surgeon'),
    (1, 2, 'assistant'),
    (1, 3, 'anesthesiologist'),
    (1, 6, 'scrub_nurse'),
    (1, 7, 'circulating_nurse'),
    (2, 2, 'primary_surgeon'),
    (2, 1, 'assistant'),
    (3, 3, 'primary_surgeon'),
    (4, 4, 'primary_surgeon'),
    (5, 1, 'primary_surgeon');

-- IntraOp Events
INSERT INTO IntraOp_Event (case_id, event_time, event_type, notes) VALUES
    (1, '2026-05-01 08:10:00', 'incision', 'Standard laparoscopy incision'),
    (1, '2026-05-01 08:15:00', 'biopsy', 'Appendix visualized, inflamed'),
    (1, '2026-05-01 08:40:00', 'closure', 'Port sites closed, sterile dressing applied');

-- IntraOp Medications
INSERT INTO IntraOp_Medication (case_id, drug_name, dose, route, administered_at, given_by_staff_id, notes) VALUES
    (1, 'Propofol',      '200mg', 'IV',  '2026-05-01 08:00:00', 3, 'Induction dose'),
    (1, 'Sevoflurane',   '2%',    'inhalation', '2026-05-01 08:02:00', 3, 'Maintenance anesthesia'),
    (1, 'Cefazolin',     '1g',    'IV',  '2026-05-01 08:05:00', 3, 'Prophylactic antibiotic'),
    (1, 'Fentanyl',      '100mcg','IV',  '2026-05-01 08:12:00', 3, 'Intra-op analgesia');

-- Specimens
INSERT INTO Specimen (case_id, laterality, tissue_type, container_type, pathology_request_id) VALUES
    (1, NULL, 'Appendix', 'Formalin jar', 'PATH-2026-001');

-- Implant Devices
INSERT INTO Implant_Device (case_id, device_type, serial_number, lot_number, manufacturer) VALUES
    (4, 'Total Knee Prosthesis', 'TKA-2026-0042', 'LOT-42-2026', 'Zimmer Biomet');

-- PACU Records
INSERT INTO PACU_Record (case_id, arrival_time, discharge_time, aldrete_score, pain_score, complications) VALUES
    (1, '2026-05-01 09:00:00', '2026-05-01 10:30:00', 9, 3, NULL);

-- Surgical Counts
INSERT INTO Surgical_Count (case_id, count_type, pre_count, post_count, verified_by_staff_id, verified_at) VALUES
    (1, 'sponge',    10, 10, 6, '2026-05-01 08:05:00'),
    (1, 'needle',    4,  4,  6, '2026-05-01 08:05:00'),
    (1, 'instrument',12, 12, 6, '2026-05-01 08:50:00');

-- Clinic Appointments
INSERT INTO Clinic_Appointment (patient_number, staff_id, room_id, appointment_date, status, reason, case_id) VALUES
    ('P001', 1, 8, '2026-04-28 09:00:00', 'completed', 'Pre-op assessment', 1),
    ('P001', 1, 8, '2026-05-05 10:00:00', 'scheduled', 'Post-op follow-up', 1),
    ('P002', 2, 8, '2026-05-08 11:00:00', 'scheduled', 'Pre-op assessment', 2),
    ('P003', 3, 8, '2026-05-09 14:00:00', 'scheduled', 'Pre-op assessment', 3);

-- Scan Documents
INSERT INTO Scan_Document (patient_number, uploaded_by_staff_id, file_path, upload_date, description, document_type) VALUES
    ('P001', 1, '/uploads/scans/p001_ct_scan.pdf',   '2026-04-28 10:00:00', 'CT Scan - Abdomen',     'imaging'),
    ('P001', 1, '/uploads/scans/p001_consent.pdf',   '2026-04-28 11:00:00', 'Surgery consent form',  'consent'),
    ('P002', 2, '/uploads/scans/p002_ultrasound.pdf','2026-05-02 14:00:00', 'Ultrasound - Gallbladder','imaging'),
    ('P003', 3, '/uploads/scans/p003_mri.pdf',        '2026-05-03 09:00:00', 'MRI - Lower abdomen',   'imaging'),
    ('P001', 1, '/uploads/scans/p001_op_report.pdf',  '2026-05-01 15:00:00', 'Operative Report - Appendectomy', 'operative_report');
