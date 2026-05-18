-- ============================================
-- Hospital Information System: Surgery Department
-- Schema DDL
-- Target: PostgreSQL
-- ============================================

-- Drop existing tables if they exist (for idempotency)
DROP TABLE IF EXISTS Scan_Document CASCADE;
DROP TABLE IF EXISTS Geo_Location CASCADE;
DROP TABLE IF EXISTS Contact_Inquiry CASCADE;
DROP TABLE IF EXISTS "User" CASCADE;
DROP TABLE IF EXISTS Payment CASCADE;
DROP TABLE IF EXISTS Appointment CASCADE;
DROP TABLE IF EXISTS Prescription_Medication CASCADE;
DROP TABLE IF EXISTS Medication CASCADE;
DROP TABLE IF EXISTS Prescription CASCADE;
DROP TABLE IF EXISTS Treats CASCADE;
DROP TABLE IF EXISTS Room CASCADE;
DROP TABLE IF EXISTS Doctor CASCADE;
DROP TABLE IF EXISTS Department_Location CASCADE;
DROP TABLE IF EXISTS Department CASCADE;
DROP TABLE IF EXISTS Hospital CASCADE;
DROP TABLE IF EXISTS Patient CASCADE;

-- ============================================
-- Patient
-- ============================================
CREATE TABLE Patient (
    patient_number  VARCHAR(20) PRIMARY KEY,
    ssn             VARCHAR(14) NOT NULL UNIQUE,
    name            VARCHAR(100) NOT NULL,
    address         VARCHAR(200),
    phone           VARCHAR(20),
    birthdate       DATE NOT NULL,
    sex             CHAR(1) NOT NULL CHECK (sex IN ('M', 'F')),
    medical_history TEXT,
    blood_pressure  VARCHAR(20),
    heart_rate      INTEGER CHECK (heart_rate > 0),
    temperature     DECIMAL(4,1),
    admission_date  DATE NOT NULL
);

-- ============================================
-- Hospital
-- ============================================
CREATE TABLE Hospital (
    hospital_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    address     VARCHAR(200) NOT NULL
);

-- ============================================
-- Department
-- ============================================
CREATE TABLE Department (
    department_code VARCHAR(10) PRIMARY KEY,
    name            VARCHAR(100) NOT NULL UNIQUE,
    hospital_id     INTEGER NOT NULL REFERENCES Hospital(hospital_id),
    chairman_ssn    VARCHAR(14),
    chair_start_date DATE
);

-- ============================================
-- Department_Location
-- ============================================
CREATE TABLE Department_Location (
    department_code VARCHAR(10) NOT NULL REFERENCES Department(department_code) ON DELETE CASCADE,
    location        VARCHAR(200) NOT NULL,
    PRIMARY KEY (department_code, location)
);

-- ============================================
-- Doctor
-- ============================================
CREATE TABLE Doctor (
    ssn             VARCHAR(14) PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    sex             CHAR(1) NOT NULL CHECK (sex IN ('M', 'F')),
    birth_date      DATE NOT NULL,
    major_area      VARCHAR(100) NOT NULL,
    degree          VARCHAR(50) NOT NULL,
    department_code VARCHAR(10) NOT NULL REFERENCES Department(department_code),
    join_date       DATE NOT NULL,
    email           VARCHAR(100),
    phone           VARCHAR(20)
);

-- Add FK for chairman after Doctor exists
ALTER TABLE Department
    ADD CONSTRAINT fk_department_chairman
    FOREIGN KEY (chairman_ssn) REFERENCES Doctor(ssn);

-- ============================================
-- Treats (Doctor-Patient relationship)
-- ============================================
CREATE TABLE Treats (
    patient_number VARCHAR(20) NOT NULL REFERENCES Patient(patient_number) ON DELETE CASCADE,
    doctor_ssn     VARCHAR(14) NOT NULL REFERENCES Doctor(ssn) ON DELETE CASCADE,
    hours_per_week INTEGER CHECK (hours_per_week >= 0),
    PRIMARY KEY (patient_number, doctor_ssn)
);

-- ============================================
-- Prescription
-- ============================================
CREATE TABLE Prescription (
    prescription_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    doctor_ssn        VARCHAR(14) NOT NULL REFERENCES Doctor(ssn),
    patient_number    VARCHAR(20) NOT NULL REFERENCES Patient(patient_number),
    prescription_date DATE NOT NULL,
    start_date        DATE NOT NULL,
    end_date          DATE NOT NULL,
    CHECK (end_date >= start_date)
);

-- ============================================
-- Medication
-- ============================================
CREATE TABLE Medication (
    medication_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name          VARCHAR(100) NOT NULL UNIQUE
);

-- ============================================
-- Prescription_Medication
-- ============================================
CREATE TABLE Prescription_Medication (
    prescription_id INTEGER NOT NULL REFERENCES Prescription(prescription_id) ON DELETE CASCADE,
    medication_id   INTEGER NOT NULL REFERENCES Medication(medication_id) ON DELETE RESTRICT,
    times_per_day   INTEGER NOT NULL CHECK (times_per_day > 0),
    dose            VARCHAR(50) NOT NULL,
    PRIMARY KEY (prescription_id, medication_id)
);

-- ============================================
-- Room
-- ============================================
CREATE TABLE Room (
    room_id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hospital_id  INTEGER NOT NULL REFERENCES Hospital(hospital_id),
    room_number  VARCHAR(20) NOT NULL,
    room_type    VARCHAR(50) NOT NULL,
    is_available BOOLEAN DEFAULT TRUE
);

-- ============================================
-- Appointment
-- ============================================
CREATE TABLE Appointment (
    appointment_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_number   VARCHAR(20) NOT NULL REFERENCES Patient(patient_number),
    doctor_ssn       VARCHAR(14) NOT NULL REFERENCES Doctor(ssn),
    room_id          INTEGER REFERENCES Room(room_id),
    appointment_date TIMESTAMP NOT NULL,
    status           VARCHAR(20) NOT NULL CHECK (status IN ('scheduled', 'completed', 'cancelled')),
    reason           VARCHAR(500)
);

-- ============================================
-- Payment
-- ============================================
CREATE TABLE Payment (
    payment_id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    appointment_id  INTEGER NOT NULL UNIQUE REFERENCES Appointment(appointment_id),
    amount          DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    payment_date    TIMESTAMP NOT NULL,
    payment_method  VARCHAR(30) NOT NULL,
    status          VARCHAR(20) NOT NULL CHECK (status IN ('paid', 'refunded'))
);

-- ============================================
-- User (login accounts)
-- ============================================
CREATE TABLE "User" (
    user_id       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username      VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role          VARCHAR(20) NOT NULL CHECK (role IN ('patient', 'doctor', 'nurse', 'admin')),
    person_type   VARCHAR(20) CHECK (person_type IN ('Patient', 'Doctor')),
    person_id     VARCHAR(20)
);

-- ============================================
-- Contact_Inquiry
-- ============================================
CREATE TABLE Contact_Inquiry (
    inquiry_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    email        VARCHAR(100) NOT NULL,
    subject      VARCHAR(200) NOT NULL,
    message      TEXT NOT NULL,
    submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_resolved  BOOLEAN DEFAULT FALSE
);

-- ============================================
-- Geo_Location
-- ============================================
CREATE TABLE Geo_Location (
    location_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    latitude    DECIMAL(10,7) NOT NULL,
    longitude   DECIMAL(10,7) NOT NULL,
    address     VARCHAR(200) NOT NULL,
    entity_type VARCHAR(30),
    entity_id   INTEGER
);

-- ============================================
-- Scan_Document
-- ============================================
CREATE TABLE Scan_Document (
    scan_id       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_number VARCHAR(20) NOT NULL REFERENCES Patient(patient_number),
    doctor_ssn    VARCHAR(14) NOT NULL REFERENCES Doctor(ssn),
    file_path     VARCHAR(500) NOT NULL,
    upload_date   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    description   VARCHAR(200)
);

-- ============================================
-- Indexes for performance
-- ============================================
CREATE INDEX idx_doctor_department ON Doctor(department_code);
CREATE INDEX idx_appointment_patient ON Appointment(patient_number);
CREATE INDEX idx_appointment_doctor ON Appointment(doctor_ssn);
CREATE INDEX idx_appointment_date ON Appointment(appointment_date);
CREATE INDEX idx_prescription_patient ON Prescription(patient_number);
CREATE INDEX idx_treats_doctor ON Treats(doctor_ssn);
CREATE INDEX idx_room_hospital ON Room(hospital_id);
CREATE INDEX idx_geo_entity ON Geo_Location(entity_type, entity_id);
CREATE INDEX idx_scan_patient ON Scan_Document(patient_number);
