-- Hospital
INSERT INTO Hospital (name, address) VALUES ('Cairo University Hospital', 'Cairo, Egypt');

-- Geo_Location
INSERT INTO Geo_Location (hospital_id, latitude, longitude) VALUES (1, 30.0444, 31.2357);

-- Doctors (insert before Department for chairman FK)
INSERT INTO Doctor (ssn, name, sex, birth_date, major_area, degree, department_code, join_date, email, phone)
VALUES
('111-11-1111', 'Ahmed Ali', 'M', '1975-03-15', 'Cardiac Surgery', 'MD', 'CARD', '2010-01-01', 'ahmed@hospital.com', '0111111111'),
('222-22-2222', 'Soha Hassan', 'F', '1980-07-20', 'General Surgery', 'MD', 'SURG', '2012-06-01', 'soha@hospital.com', '0122222222'),
('333-33-3333', 'Mona Ibrahim', 'F', '1985-11-10', 'Anesthesiology', 'MD', 'SURG', '2015-03-01', 'mona@hospital.com', '0133333333');

-- Departments (chairman_doctor_id set later)
INSERT INTO Department (department_code, name, hospital_id, chairman_doctor_id, chair_start_date)
VALUES
('SURG', 'Surgery', 1, 2, '2020-01-01'),
('CARD', 'Cardiology', 1, 1, '2020-01-01');

-- Update doctor department_code FKs now that departments exist
UPDATE Doctor SET department_code = 'CARD' WHERE doctor_id = 1;
UPDATE Doctor SET department_code = 'SURG' WHERE doctor_id = 2;
UPDATE Doctor SET department_code = 'SURG' WHERE doctor_id = 3;

-- Department_Location
INSERT INTO Department_Location (department_code, location) VALUES
('SURG', 'Building A, 2nd Floor'),
('CARD', 'Building A, 3rd Floor');

-- Patients
INSERT INTO Patient (patient_number, ssn, name, address, phone, birthdate, sex, medical_history, admission_date, blood_pressure, heart_rate, temperature, spo2, recorded_at)
VALUES
('P001', '123-45-6789', 'Omar Farouk', 'Cairo', '0101111111', '1990-01-15', 'M', 'None', '2026-05-18', '120/80', 72, 36.6, 98, '2026-05-18 08:00:00'),
('P002', '234-56-7890', 'Layla Kamal', 'Giza', '0102222222', '1985-06-20', 'F', 'Diabetes', '2026-05-19', '130/85', 78, 37.0, 97, '2026-05-19 09:00:00'),
('P003', '345-67-8901', 'Youssef Nabil', 'Alexandria', '0103333333', '1970-12-10', 'M', 'Hypertension', '2026-05-17', '140/90', 80, 36.8, 96, '2026-05-17 10:00:00'),
('P004', '456-78-9012', 'Nour El-Din', 'Mansoura', '0104444444', '2000-08-25', 'M', 'None', '2026-05-20', '115/75', 68, 36.5, 99, '2026-05-20 07:00:00'),
('P005', '567-89-0123', 'Hana Mahmoud', 'Cairo', '0105555555', '1995-03-05', 'F', 'Asthma', '2026-05-16', '118/78', 70, 36.7, 98, '2026-05-16 11:00:00');

-- Rooms
INSERT INTO Room (hospital_id, room_number, room_type, or_type, has_robot, has_c_arm, is_available)
VALUES
(1, 'OR-1', 'OR', 'general', FALSE, TRUE, TRUE),
(1, 'OR-2', 'OR', 'cardiac', TRUE, TRUE, TRUE),
(1, 'W-01', 'Ward', NULL, FALSE, FALSE, TRUE);

-- Treats
INSERT INTO Treats (patient_number, doctor_id, hours_per_week) VALUES
('P001', 1, 5),
('P002', 2, 3),
('P003', 1, 4),
('P004', 2, 2),
('P005', 2, 3);

-- Surgical_Procedure
INSERT INTO Surgical_Procedure (procedure_code, name, standard_duration_minutes, required_room_type, specialty)
VALUES
('APP', 'Appendectomy', 60, 'general', 'General Surgery'),
('CHOL', 'Cholecystectomy', 90, 'general', 'General Surgery'),
('CABG', 'Coronary Artery Bypass Graft', 240, 'cardiac', 'Cardiac Surgery');

-- Surgery_Case
INSERT INTO Surgery_Case (patient_number, procedure_code, priority, status, created_at)
VALUES
('P001', 'APP', 'elective', 'completed', '2026-05-18 10:00:00'),
('P003', 'CABG', 'urgent', 'in_or', '2026-05-19 14:00:00');

-- Surgery_Schedule
INSERT INTO Surgery_Schedule (case_id, or_room_id, scheduled_start, scheduled_end)
VALUES (2, 2, '2026-05-20 09:00:00', '2026-05-20 10:00:00');

-- Surgical_Team_Assignment
INSERT INTO Surgical_Team_Assignment (case_id, doctor_id, role) VALUES
(2, 1, 'primary_surgeon'),
(2, 3, 'anesthesiologist');

-- Appointments
INSERT INTO Appointment (patient_number, doctor_id, room_id, appointment_date, status, reason, case_id)
VALUES
('P001', 1, 1, '2026-05-20 09:00:00', 'scheduled', 'Appendectomy consultation', 1),
('P002', 2, 3, '2026-05-19 14:00:00', 'completed', 'Gallbladder pain', NULL),
('P003', 1, 2, '2026-05-18 10:00:00', 'completed', 'Heart checkup', 2),
('P004', 2, 3, '2026-05-25 11:00:00', 'scheduled', 'Consultation', NULL),
('P001', 2, 1, '2026-05-17 09:00:00', 'cancelled', 'No show', NULL);

-- Payments (2 pay, 1 refund)
INSERT INTO Payment (appointment_id, amount, payment_type, description)
VALUES
(2, 2000.00, 'pay', 'Consultation payment'),
(3, 3000.00, 'pay', 'Cardiac checkup fee'),
(5, 1000.00, 'refund', 'Refund for cancelled appointment');

-- Prescriptions
INSERT INTO Prescription (doctor_id, patient_number, prescription_date, start_date, end_date)
VALUES
(1, 'P001', '2026-05-18', '2026-05-18', '2026-05-25'),
(2, 'P002', '2026-05-19', '2026-05-19', '2026-06-02');

-- Medication
INSERT INTO Medication (name) VALUES
('Amoxicillin'),
('Ibuprofen'),
('Paracetamol'),
('Metformin');

-- Prescription_Medication
INSERT INTO Prescription_Medication (prescription_id, medication_id, times_per_day, dose) VALUES
(1, 1, 3, '500mg'),
(1, 2, 2, '400mg'),
(2, 2, 3, '200mg'),
(2, 3, 2, '500mg');

-- Contact_Inquiry
INSERT INTO Contact_Inquiry (name, email, phone, subject, message, status)
VALUES
('Ali Hassan', 'ali@example.com', '0144444444', 'Appointment issue', 'I cannot book an appointment online.', 'pending'),
('Mona Said', 'mona@example.com', '0155555555', 'Billing question', 'I need a receipt for my payment.', 'closed');

-- Scan_Document
INSERT INTO Scan_Document (patient_number, uploaded_by_doctor_id, file_path, upload_date, description, document_type)
VALUES
('P001', 1, 'uploads/ct_scan_001.pdf', '2026-05-18 11:00:00', 'CT Scan of abdomen', 'imaging'),
('P002', 2, 'uploads/consent_002.pdf', '2026-05-19 15:00:00', 'Surgery consent form', 'consent');

-- Users (role: admin, doctor, staff=nurse, patient)
INSERT INTO User_Account (username, password_hash, role, doctor_id, patient_number)
VALUES
('admin', 'admin', 'admin', NULL, NULL),
('doctor', 'doctor', 'doctor', 1, NULL),
('patient', 'patient', 'patient', NULL, 'P001'),
('nurse', 'nurse', 'staff', NULL, NULL);

-- PACU_Record (for completed case 1)
INSERT INTO PACU_Record (case_id, arrival_time, discharge_time, aldrete_score, pain_score, complications)
VALUES (1, '2026-05-18 12:00:00', '2026-05-18 13:30:00', 9, 2, 'Mild nausea');

-- Surgical_Count (for completed case 1)
INSERT INTO Surgical_Count (case_id, count_type, pre_count, post_count, verified_by_doctor_id)
VALUES (1, 'sponge', 10, 10, 1);
