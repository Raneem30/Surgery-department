-- ============================================
-- Surgery Department — Operating Theater Module
-- Schema DDL
-- Target: PostgreSQL
-- ============================================

-- Enable extension for OR overlap prevention
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- ============================================
-- Drop existing tables (idempotent)
-- ============================================
DROP TABLE IF EXISTS Surgical_Count CASCADE;
DROP TABLE IF EXISTS PACU_Record CASCADE;
DROP TABLE IF EXISTS Implant_Device CASCADE;
DROP TABLE IF EXISTS Specimen CASCADE;
DROP TABLE IF EXISTS IntraOp_Event CASCADE;
DROP TABLE IF EXISTS Surgical_Team_Assignment CASCADE;
DROP TABLE IF EXISTS Surgery_Schedule CASCADE;
DROP TABLE IF EXISTS Surgery_Case CASCADE;
DROP TABLE IF EXISTS Vital_Sign CASCADE;
DROP TABLE IF EXISTS Admission CASCADE;
DROP TABLE IF EXISTS Procedure_ CASCADE;
DROP TABLE IF EXISTS Scan_Document CASCADE;
DROP TABLE IF EXISTS Clinic_Appointment CASCADE;
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
    medical_history TEXT
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
    department_code  VARCHAR(10) PRIMARY KEY,
    name             VARCHAR(100) NOT NULL UNIQUE,
    hospital_id      INTEGER NOT NULL REFERENCES Hospital(hospital_id),
    chairman_ssn     VARCHAR(14),
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

-- FK for Department chairman (circular ref)
ALTER TABLE Department
    ADD CONSTRAINT fk_department_chairman
    FOREIGN KEY (chairman_ssn) REFERENCES Doctor(ssn);

-- ============================================
-- Treats (Doctor-Patient)
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
-- Room (Operating Rooms & PACU)
-- ============================================
CREATE TABLE Room (
    room_id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hospital_id  INTEGER NOT NULL REFERENCES Hospital(hospital_id),
    room_number  VARCHAR(20) NOT NULL,
    room_type    VARCHAR(50) NOT NULL CHECK (room_type IN ('OR', 'PACU', 'ICU', 'Ward', 'Clinic')),
    or_type      VARCHAR(50) CHECK (or_type IN ('general', 'cardiac', 'hybrid', 'robotic')),
    has_robot    BOOLEAN DEFAULT FALSE,
    has_c_arm    BOOLEAN DEFAULT FALSE,
    laminar_flow BOOLEAN DEFAULT FALSE
);

-- ============================================
-- Clinic_Appointment (pre-op / post-op visits only)
-- ============================================
CREATE TABLE Clinic_Appointment (
    appointment_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_number   VARCHAR(20) NOT NULL REFERENCES Patient(patient_number),
    doctor_ssn       VARCHAR(14) NOT NULL REFERENCES Doctor(ssn),
    room_id          INTEGER REFERENCES Room(room_id),
    appointment_date TIMESTAMP NOT NULL,
    status           VARCHAR(20) NOT NULL CHECK (status IN ('scheduled', 'completed', 'cancelled')),
    reason           VARCHAR(500),
    case_id          INTEGER      -- nullable link to surgery
);

-- ============================================
-- Scan_Document
-- ============================================
CREATE TABLE Scan_Document (
    scan_id        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_number VARCHAR(20) NOT NULL REFERENCES Patient(patient_number),
    doctor_ssn     VARCHAR(14) NOT NULL REFERENCES Doctor(ssn),
    file_path      VARCHAR(500) NOT NULL,
    upload_date    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    description    VARCHAR(200),
    document_type  VARCHAR(50) CHECK (document_type IN ('consent', 'operative_report', 'imaging', 'lab_result'))
);

-- ============================================
-- Procedure (master list — CPT / ICD-PCS)
-- ============================================
CREATE TABLE Procedure_ (
    procedure_code           VARCHAR(20) PRIMARY KEY,
    name                     VARCHAR(200) NOT NULL,
    standard_duration_minutes INTEGER NOT NULL CHECK (standard_duration_minutes > 0),
    required_room_type       VARCHAR(50) NOT NULL CHECK (required_room_type IN ('general', 'cardiac', 'hybrid', 'robotic')),
    specialty                VARCHAR(100) NOT NULL
);

-- ============================================
-- Admission (hospital stay)
-- ============================================
CREATE TABLE Admission (
    admission_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_number VARCHAR(20) NOT NULL REFERENCES Patient(patient_number),
    admission_date DATE NOT NULL,
    discharge_date DATE,
    bed_number     VARCHAR(20),
    CHECK (discharge_date IS NULL OR discharge_date >= admission_date)
);

-- ============================================
-- Vital_Sign (time-series, not on Patient)
-- ============================================
CREATE TABLE Vital_Sign (
    vital_id       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_number VARCHAR(20) NOT NULL REFERENCES Patient(patient_number),
    recorded_at    TIMESTAMP NOT NULL,
    blood_pressure VARCHAR(20),
    heart_rate     INTEGER CHECK (heart_rate > 0),
    temperature    DECIMAL(4,1),
    spo2           INTEGER CHECK (spo2 >= 0 AND spo2 <= 100),
    recorded_by_ssn VARCHAR(14) NOT NULL REFERENCES Doctor(ssn)
);

-- ============================================
-- Surgery_Case (central hub)
-- ============================================
CREATE TABLE Surgery_Case (
    case_id        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_number VARCHAR(20) NOT NULL REFERENCES Patient(patient_number),
    procedure_code VARCHAR(20) NOT NULL REFERENCES Procedure_(procedure_code),
    priority       VARCHAR(20) NOT NULL CHECK (priority IN ('elective', 'emergency', 'urgent')),
    status         VARCHAR(20) NOT NULL CHECK (status IN ('scheduled', 'pre_op', 'in_or', 'in_pacu', 'completed', 'cancelled')),
    admission_id   INTEGER REFERENCES Admission(admission_id),
    cancel_reason  VARCHAR(500),
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- Surgery_Schedule (OR scheduling with overlap prevention)
-- ============================================
CREATE TABLE Surgery_Schedule (
    schedule_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    case_id        INTEGER NOT NULL UNIQUE REFERENCES Surgery_Case(case_id),
    or_room_id     INTEGER NOT NULL REFERENCES Room(room_id),
    scheduled_start TIMESTAMP NOT NULL,
    scheduled_end   TIMESTAMP NOT NULL,
    actual_start   TIMESTAMP,
    actual_end     TIMESTAMP,
    CHECK (scheduled_end > scheduled_start),
    CHECK (actual_end IS NULL OR actual_start IS NOT NULL),
    CHECK (actual_end IS NULL OR actual_end > actual_start),
    -- Prevent overlapping schedules for the same OR
    EXCLUDE USING gist (
        or_room_id WITH =,
        tstzrange(scheduled_start, scheduled_end) WITH &&
    )
);

-- ============================================
-- Surgical_Team_Assignment
-- ============================================
CREATE TABLE Surgical_Team_Assignment (
    case_id    INTEGER NOT NULL REFERENCES Surgery_Case(case_id),
    doctor_ssn VARCHAR(14) NOT NULL REFERENCES Doctor(ssn),
    role       VARCHAR(30) NOT NULL CHECK (role IN (
        'primary_surgeon', 'assistant', 'anesthesiologist',
        'scrub_nurse', 'circulating_nurse'
    )),
    PRIMARY KEY (case_id, doctor_ssn, role)
);

-- ============================================
-- IntraOp_Event
-- ============================================
CREATE TABLE IntraOp_Event (
    event_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    case_id    INTEGER NOT NULL REFERENCES Surgery_Case(case_id),
    event_time TIMESTAMP NOT NULL,
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN (
        'incision', 'biopsy', 'bleeding', 'implant_placed', 'closure'
    )),
    notes      TEXT
);

-- ============================================
-- Specimen (tissue sent to pathology)
-- ============================================
CREATE TABLE Specimen (
    specimen_id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    case_id              INTEGER NOT NULL REFERENCES Surgery_Case(case_id),
    laterality           VARCHAR(20) CHECK (laterality IN ('left', 'right', 'bilateral')),
    tissue_type          VARCHAR(100) NOT NULL,
    container_type       VARCHAR(100) NOT NULL,
    pathology_request_id VARCHAR(50)
);

-- ============================================
-- Implant_Device (traceable)
-- ============================================
CREATE TABLE Implant_Device (
    implant_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    case_id       INTEGER NOT NULL REFERENCES Surgery_Case(case_id),
    device_type   VARCHAR(100) NOT NULL,
    serial_number VARCHAR(100) NOT NULL,
    lot_number    VARCHAR(100),
    manufacturer  VARCHAR(200) NOT NULL
);

-- ============================================
-- PACU_Record (post-anesthesia recovery)
-- ============================================
CREATE TABLE PACU_Record (
    pacu_id        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    case_id        INTEGER NOT NULL UNIQUE REFERENCES Surgery_Case(case_id),
    arrival_time   TIMESTAMP NOT NULL,
    discharge_time TIMESTAMP,
    aldrete_score  INTEGER CHECK (aldrete_score >= 0 AND aldrete_score <= 10),
    pain_score     INTEGER CHECK (pain_score >= 0 AND pain_score <= 10),
    complications  TEXT,
    CHECK (discharge_time IS NULL OR discharge_time >= arrival_time)
);

-- ============================================
-- Surgical_Count (safety — sponges, needles, instruments)
-- ============================================
CREATE TABLE Surgical_Count (
    count_id           INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    case_id            INTEGER NOT NULL REFERENCES Surgery_Case(case_id),
    count_type         VARCHAR(30) NOT NULL CHECK (count_type IN ('sponge', 'needle', 'instrument')),
    pre_count          INTEGER NOT NULL CHECK (pre_count >= 0),
    post_count         INTEGER NOT NULL CHECK (post_count >= 0),
    verified_by_nurse_ssn VARCHAR(14) NOT NULL REFERENCES Doctor(ssn),
    verified_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- Indexes for performance
-- ============================================
CREATE INDEX idx_doctor_department ON Doctor(department_code);
CREATE INDEX idx_room_hospital ON Room(hospital_id);
CREATE INDEX idx_room_type ON Room(room_type);

CREATE INDEX idx_appointment_patient ON Clinic_Appointment(patient_number);
CREATE INDEX idx_appointment_doctor ON Clinic_Appointment(doctor_ssn);
CREATE INDEX idx_appointment_date ON Clinic_Appointment(appointment_date);

CREATE INDEX idx_prescription_patient ON Prescription(patient_number);
CREATE INDEX idx_treats_doctor ON Treats(doctor_ssn);

CREATE INDEX idx_scan_patient ON Scan_Document(patient_number);

-- Surgery indexes
CREATE INDEX idx_surgery_patient ON Surgery_Case(patient_number);
CREATE INDEX idx_surgery_procedure ON Surgery_Case(procedure_code);
CREATE INDEX idx_surgery_status ON Surgery_Case(status);
CREATE INDEX idx_surgery_priority ON Surgery_Case(priority);
CREATE INDEX idx_surgery_admission ON Surgery_Case(admission_id);

CREATE INDEX idx_schedule_case ON Surgery_Schedule(case_id);
CREATE INDEX idx_schedule_room ON Surgery_Schedule(or_room_id);
CREATE INDEX idx_schedule_dates ON Surgery_Schedule(scheduled_start, scheduled_end);

CREATE INDEX idx_team_case ON Surgical_Team_Assignment(case_id);
CREATE INDEX idx_team_doctor ON Surgical_Team_Assignment(doctor_ssn);

CREATE INDEX idx_intraop_case ON IntraOp_Event(case_id);

CREATE INDEX idx_specimen_case ON Specimen(case_id);

CREATE INDEX idx_implant_case ON Implant_Device(case_id);
CREATE INDEX idx_implant_serial ON Implant_Device(serial_number);

CREATE INDEX idx_pacu_case ON PACU_Record(case_id);

CREATE INDEX idx_surgical_count_case ON Surgical_Count(case_id);

CREATE INDEX idx_vital_patient ON Vital_Sign(patient_number);
CREATE INDEX idx_vital_time ON Vital_Sign(recorded_at);

CREATE INDEX idx_admission_patient ON Admission(patient_number);
