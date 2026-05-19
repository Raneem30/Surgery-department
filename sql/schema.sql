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
DROP TABLE IF EXISTS IntraOp_Medication CASCADE;
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
DROP TABLE IF EXISTS Surgical_Procedure CASCADE;
DROP TABLE IF EXISTS Scan_Document CASCADE;
DROP TABLE IF EXISTS Clinic_Appointment CASCADE;
DROP TABLE IF EXISTS Prescription_Medication CASCADE;
DROP TABLE IF EXISTS Medication CASCADE;
DROP TABLE IF EXISTS Prescription CASCADE;
DROP TABLE IF EXISTS Treats CASCADE;
DROP TABLE IF EXISTS Room CASCADE;
DROP TABLE IF EXISTS Surgery_Audit_Log CASCADE;
DROP TABLE IF EXISTS Staff CASCADE;
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
-- Staff (replaces Doctor — unified for all roles)
-- ============================================
CREATE TABLE Staff (
    staff_id       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ssn            VARCHAR(14) NOT NULL UNIQUE,
    name           VARCHAR(100) NOT NULL,
    role           VARCHAR(20) NOT NULL CHECK (role IN ('doctor', 'nurse', 'tech')),
    sex            CHAR(1) CHECK (sex IN ('M', 'F')),
    birth_date     DATE,
    major_area     VARCHAR(100),
    degree         VARCHAR(50),
    department_code VARCHAR(10) NOT NULL,
    join_date      DATE,
    email          VARCHAR(100),
    phone          VARCHAR(20)
);

-- ============================================
-- Department
-- ============================================
CREATE TABLE Department (
    department_code   VARCHAR(10) PRIMARY KEY,
    name              VARCHAR(100) NOT NULL UNIQUE,
    hospital_id       INTEGER NOT NULL REFERENCES Hospital(hospital_id),
    chairman_staff_id INTEGER,
    chair_start_date  DATE
);

-- Add FK for Department chairman (circular ref resolved)
ALTER TABLE Department
    ADD CONSTRAINT fk_department_chairman
    FOREIGN KEY (chairman_staff_id) REFERENCES Staff(staff_id);

ALTER TABLE Staff
    ADD CONSTRAINT fk_staff_department
    FOREIGN KEY (department_code) REFERENCES Department(department_code);

-- ============================================
-- Department_Location
-- ============================================
CREATE TABLE Department_Location (
    department_code VARCHAR(10) NOT NULL REFERENCES Department(department_code) ON DELETE CASCADE,
    location        VARCHAR(200) NOT NULL,
    PRIMARY KEY (department_code, location)
);

-- ============================================
-- Treats (Staff-Patient, doctors only)
-- ============================================
CREATE TABLE Treats (
    patient_number VARCHAR(20) NOT NULL REFERENCES Patient(patient_number) ON DELETE CASCADE,
    staff_id       INTEGER NOT NULL REFERENCES Staff(staff_id),
    hours_per_week INTEGER CHECK (hours_per_week >= 0),
    PRIMARY KEY (patient_number, staff_id)
);

-- ============================================
-- Prescription
-- ============================================
CREATE TABLE Prescription (
    prescription_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    staff_id          INTEGER NOT NULL REFERENCES Staff(staff_id),
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
    laminar_flow BOOLEAN DEFAULT FALSE,
    -- Enforce or_type NOT NULL for OR rooms, NULL for others
    CHECK (
        (room_type = 'OR' AND or_type IS NOT NULL) OR
        (room_type != 'OR' AND or_type IS NULL)
    )
);

-- ============================================
-- Clinic_Appointment (pre-op / post-op visits only)
-- ============================================
CREATE TABLE Clinic_Appointment (
    appointment_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_number   VARCHAR(20) NOT NULL REFERENCES Patient(patient_number),
    staff_id         INTEGER NOT NULL REFERENCES Staff(staff_id),
    room_id          INTEGER REFERENCES Room(room_id),
    appointment_date TIMESTAMP NOT NULL,
    status           VARCHAR(20) NOT NULL CHECK (status IN ('scheduled', 'completed', 'cancelled')),
    reason           VARCHAR(500),
    case_id          INTEGER REFERENCES Surgery_Case(case_id) ON DELETE SET NULL
);

-- ============================================
-- Scan_Document
-- ============================================
CREATE TABLE Scan_Document (
    scan_id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_number   VARCHAR(20) NOT NULL REFERENCES Patient(patient_number),
    uploaded_by_staff_id INTEGER NOT NULL REFERENCES Staff(staff_id),
    file_path        VARCHAR(500) NOT NULL,
    upload_date      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    description      VARCHAR(200),
    document_type    VARCHAR(50) CHECK (document_type IN ('consent', 'operative_report', 'imaging', 'lab_result'))
);

-- ============================================
-- Surgical_Procedure (master list — CPT / ICD-PCS)
-- ============================================
CREATE TABLE Surgical_Procedure (
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
-- Vital_Sign (time-series)
-- ============================================
CREATE TABLE Vital_Sign (
    vital_id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_number    VARCHAR(20) NOT NULL REFERENCES Patient(patient_number),
    recorded_at       TIMESTAMP NOT NULL,
    blood_pressure    VARCHAR(20),
    heart_rate        INTEGER CHECK (heart_rate > 0),
    temperature       DECIMAL(4,1),
    spo2              INTEGER CHECK (spo2 >= 0 AND spo2 <= 100),
    recorded_by_staff_id INTEGER NOT NULL REFERENCES Staff(staff_id)
);

-- ============================================
-- Surgery_Case (central hub)
-- ============================================
CREATE TABLE Surgery_Case (
    case_id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_number  VARCHAR(20) NOT NULL REFERENCES Patient(patient_number),
    procedure_code  VARCHAR(20) NOT NULL REFERENCES Surgical_Procedure(procedure_code),
    priority        VARCHAR(20) NOT NULL CHECK (priority IN ('elective', 'emergency', 'urgent')),
    status          VARCHAR(20) NOT NULL CHECK (status IN ('scheduled', 'pre_op', 'in_or', 'in_pacu', 'completed', 'cancelled')),
    admission_id    INTEGER REFERENCES Admission(admission_id),
    cancel_reason   VARCHAR(500),
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- Surgery_Schedule (OR scheduling with overlap prevention)
-- ============================================
CREATE TABLE Surgery_Schedule (
    schedule_id     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    case_id         INTEGER NOT NULL UNIQUE REFERENCES Surgery_Case(case_id),
    or_room_id      INTEGER NOT NULL REFERENCES Room(room_id),
    scheduled_start TIMESTAMP NOT NULL,
    scheduled_end   TIMESTAMP NOT NULL,
    actual_start    TIMESTAMP,
    actual_end      TIMESTAMP,
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
    case_id  INTEGER NOT NULL REFERENCES Surgery_Case(case_id),
    staff_id INTEGER NOT NULL REFERENCES Staff(staff_id),
    role     VARCHAR(30) NOT NULL CHECK (role IN (
        'primary_surgeon', 'assistant', 'anesthesiologist',
        'scrub_nurse', 'circulating_nurse'
    )),
    PRIMARY KEY (case_id, staff_id, role)
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
-- IntraOp_Medication (drugs given during surgery)
-- ============================================
CREATE TABLE IntraOp_Medication (
    medication_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    case_id          INTEGER NOT NULL REFERENCES Surgery_Case(case_id),
    drug_name        VARCHAR(100) NOT NULL,
    dose             VARCHAR(50) NOT NULL,
    route            VARCHAR(30) NOT NULL CHECK (route IN ('IV', 'PO', 'IM', 'SC', 'inhalation', 'topical')),
    administered_at  TIMESTAMP NOT NULL,
    given_by_staff_id INTEGER NOT NULL REFERENCES Staff(staff_id),
    notes            TEXT
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
    count_id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    case_id           INTEGER NOT NULL REFERENCES Surgery_Case(case_id),
    count_type        VARCHAR(30) NOT NULL CHECK (count_type IN ('sponge', 'needle', 'instrument')),
    pre_count         INTEGER NOT NULL CHECK (pre_count >= 0),
    post_count        INTEGER NOT NULL CHECK (post_count >= 0),
    verified_by_staff_id INTEGER NOT NULL REFERENCES Staff(staff_id),
    verified_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- Surgery_Audit_Log (medicolegal audit trail)
-- ============================================
CREATE TABLE Surgery_Audit_Log (
    log_id     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id  INTEGER NOT NULL,
    action     VARCHAR(20) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    changed_by_staff_id INTEGER NOT NULL REFERENCES Staff(staff_id),
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    old_data   JSONB,
    new_data   JSONB
);

-- --------------------------------------------------
-- Audit Trigger Function
-- Usage: SET app.current_staff_id = <id>; in session
-- --------------------------------------------------
CREATE OR REPLACE FUNCTION fn_audit_trigger()
RETURNS TRIGGER AS $$
DECLARE
    v_staff_id INTEGER;
BEGIN
    v_staff_id := current_setting('app.current_staff_id')::INTEGER;

    IF TG_OP = 'INSERT' THEN
        INSERT INTO Surgery_Audit_Log (table_name, record_id, action, changed_by_staff_id, new_data)
        VALUES (TG_TABLE_NAME, NEW.implant_id, 'INSERT', v_staff_id, row_to_json(NEW)::jsonb);
        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO Surgery_Audit_Log (table_name, record_id, action, changed_by_staff_id, old_data, new_data)
        VALUES (TG_TABLE_NAME, NEW.implant_id, 'UPDATE', v_staff_id, row_to_json(OLD)::jsonb, row_to_json(NEW)::jsonb);
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO Surgery_Audit_Log (table_name, record_id, action, changed_by_staff_id, old_data)
        VALUES (TG_TABLE_NAME, OLD.implant_id, 'DELETE', v_staff_id, row_to_json(OLD)::jsonb);
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Audit triggers on Implant_Device
CREATE TRIGGER trg_implant_audit
    AFTER INSERT OR UPDATE OR DELETE ON Implant_Device
    FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

-- Audit triggers on Surgical_Count
CREATE TRIGGER trg_surgical_count_audit
    AFTER INSERT OR UPDATE OR DELETE ON Surgical_Count
    FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

-- ============================================
-- Indexes for performance
-- ============================================
CREATE INDEX idx_staff_department ON Staff(department_code);
CREATE INDEX idx_staff_role ON Staff(role);

CREATE INDEX idx_room_hospital ON Room(hospital_id);
CREATE INDEX idx_room_type ON Room(room_type);

CREATE INDEX idx_appointment_patient ON Clinic_Appointment(patient_number);
CREATE INDEX idx_appointment_staff ON Clinic_Appointment(staff_id);
CREATE INDEX idx_appointment_date ON Clinic_Appointment(appointment_date);
CREATE INDEX idx_clinic_appointment_case ON Clinic_Appointment(case_id);

CREATE INDEX idx_prescription_staff ON Prescription(staff_id);
CREATE INDEX idx_prescription_patient ON Prescription(patient_number);
CREATE INDEX idx_treats_staff ON Treats(staff_id);

CREATE INDEX idx_scan_patient ON Scan_Document(patient_number);
CREATE INDEX idx_scan_uploader ON Scan_Document(uploaded_by_staff_id);

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
CREATE INDEX idx_team_staff ON Surgical_Team_Assignment(staff_id);

CREATE INDEX idx_intraop_case ON IntraOp_Event(case_id);

CREATE INDEX idx_intraop_med_case ON IntraOp_Medication(case_id);

CREATE INDEX idx_specimen_case ON Specimen(case_id);

CREATE INDEX idx_implant_case ON Implant_Device(case_id);
CREATE INDEX idx_implant_serial ON Implant_Device(serial_number);

CREATE INDEX idx_pacu_case ON PACU_Record(case_id);

CREATE INDEX idx_surgical_count_case ON Surgical_Count(case_id);

CREATE INDEX idx_vital_patient ON Vital_Sign(patient_number);
CREATE INDEX idx_vital_time ON Vital_Sign(recorded_at);

CREATE INDEX idx_admission_patient ON Admission(patient_number);

CREATE INDEX idx_audit_table_time ON Surgery_Audit_Log(table_name, changed_at);
