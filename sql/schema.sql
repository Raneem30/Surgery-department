CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE Hospital (
    hospital_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(200) NOT NULL
);

CREATE TABLE Geo_Location (
    location_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hospital_id INTEGER NOT NULL REFERENCES Hospital(hospital_id),
    latitude DECIMAL(10,7) NOT NULL,
    longitude DECIMAL(10,7) NOT NULL
);

CREATE TABLE Patient (
    patient_number VARCHAR(20) PRIMARY KEY,
    ssn VARCHAR(14) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(200),
    phone VARCHAR(20),
    birthdate DATE NOT NULL,
    sex CHAR(1) NOT NULL CHECK (sex IN ('M','F')),
    medical_history TEXT,
    admission_date DATE NOT NULL,
    blood_pressure VARCHAR(20),
    heart_rate INTEGER CHECK (heart_rate > 0),
    temperature DECIMAL(4,1),
    spo2 INTEGER CHECK (spo2 >= 0 AND spo2 <= 100),
    recorded_at TIMESTAMP
);

CREATE TABLE Doctor (
    doctor_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ssn VARCHAR(14) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    sex CHAR(1) CHECK (sex IN ('M','F')),
    birth_date DATE,
    major_area VARCHAR(100) NOT NULL,
    degree VARCHAR(50) NOT NULL,
    department_code VARCHAR(10) NOT NULL,
    join_date DATE,
    email VARCHAR(100),
    phone VARCHAR(20)
);

CREATE TABLE Department (
    department_code VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    hospital_id INTEGER NOT NULL REFERENCES Hospital(hospital_id),
    chairman_doctor_id INTEGER REFERENCES Doctor(doctor_id),
    chair_start_date DATE
);

CREATE TABLE Department_Location (
    department_code VARCHAR(10) NOT NULL REFERENCES Department(department_code) ON DELETE CASCADE,
    location VARCHAR(200) NOT NULL,
    PRIMARY KEY (department_code, location)
);

CREATE TABLE Treats (
    patient_number VARCHAR(20) NOT NULL REFERENCES Patient(patient_number) ON DELETE CASCADE,
    doctor_id INTEGER NOT NULL REFERENCES Doctor(doctor_id),
    hours_per_week INTEGER CHECK (hours_per_week >= 0),
    PRIMARY KEY (patient_number, doctor_id)
);

CREATE TABLE Medication (
    medication_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Prescription (
    prescription_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    doctor_id INTEGER NOT NULL REFERENCES Doctor(doctor_id),
    patient_number VARCHAR(20) NOT NULL REFERENCES Patient(patient_number),
    prescription_date DATE NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    CHECK (end_date >= start_date)
);

CREATE TABLE Prescription_Medication (
    prescription_id INTEGER NOT NULL REFERENCES Prescription(prescription_id) ON DELETE CASCADE,
    medication_id INTEGER NOT NULL REFERENCES Medication(medication_id) ON DELETE RESTRICT,
    times_per_day INTEGER NOT NULL CHECK (times_per_day > 0),
    dose VARCHAR(50) NOT NULL,
    PRIMARY KEY (prescription_id, medication_id)
);

CREATE TABLE Room (
    room_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hospital_id INTEGER NOT NULL REFERENCES Hospital(hospital_id),
    room_number VARCHAR(20) NOT NULL,
    room_type VARCHAR(50) NOT NULL CHECK (room_type IN ('OR','PACU','ICU','Ward','Clinic')),
    or_type VARCHAR(50) CHECK (or_type IN ('general','cardiac','hybrid','robotic')),
    has_robot BOOLEAN DEFAULT FALSE,
    has_c_arm BOOLEAN DEFAULT FALSE,
    is_available BOOLEAN DEFAULT TRUE,
    CHECK ((room_type = 'OR' AND or_type IS NOT NULL) OR (room_type != 'OR' AND or_type IS NULL))
);

CREATE TABLE Surgical_Procedure (
    procedure_code VARCHAR(20) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    standard_duration_minutes INTEGER NOT NULL CHECK (standard_duration_minutes > 0),
    required_room_type VARCHAR(50) NOT NULL CHECK (required_room_type IN ('general','cardiac','hybrid','robotic')),
    specialty VARCHAR(100) NOT NULL
);

CREATE TABLE Surgery_Case (
    case_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_number VARCHAR(20) NOT NULL REFERENCES Patient(patient_number),
    procedure_code VARCHAR(20) NOT NULL REFERENCES Surgical_Procedure(procedure_code),
    priority VARCHAR(20) NOT NULL CHECK (priority IN ('elective','emergency','urgent')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('scheduled','pre_op','in_or','in_pacu','completed','cancelled')),
    cancel_reason VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Appointment (
    appointment_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_number VARCHAR(20) NOT NULL REFERENCES Patient(patient_number),
    doctor_id INTEGER NOT NULL REFERENCES Doctor(doctor_id),
    room_id INTEGER REFERENCES Room(room_id),
    appointment_date TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('scheduled','completed','cancelled')),
    reason VARCHAR(500),
    case_id INTEGER REFERENCES Surgery_Case(case_id) ON DELETE SET NULL
);

CREATE TABLE Payment (
    payment_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    appointment_id INTEGER NOT NULL REFERENCES Appointment(appointment_id) UNIQUE,
    amount DECIMAL(10,2) NOT NULL,
    payment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_type VARCHAR(20) NOT NULL CHECK (payment_type IN ('register','pay','refund')),
    description VARCHAR(500)
);

CREATE TABLE User_Account (
    user_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin','doctor','nurse','staff','patient')),
    doctor_id INTEGER REFERENCES Doctor(doctor_id),
    patient_number VARCHAR(20) REFERENCES Patient(patient_number),
    last_login TIMESTAMP
);

CREATE TABLE Contact_Inquiry (
    inquiry_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    subject VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','read','replied','closed'))
);

CREATE TABLE Scan_Document (
    scan_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_number VARCHAR(20) NOT NULL REFERENCES Patient(patient_number),
    uploaded_by_doctor_id INTEGER NOT NULL REFERENCES Doctor(doctor_id),
    file_path VARCHAR(500) NOT NULL,
    upload_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    description VARCHAR(200),
    document_type VARCHAR(50) CHECK (document_type IN ('consent','operative_report','imaging','lab_result'))
);

CREATE TABLE Surgery_Schedule (
    schedule_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    case_id INTEGER NOT NULL REFERENCES Surgery_Case(case_id) UNIQUE,
    or_room_id INTEGER NOT NULL REFERENCES Room(room_id),
    scheduled_start TIMESTAMP NOT NULL,
    scheduled_end TIMESTAMP NOT NULL,
    actual_start TIMESTAMP,
    actual_end TIMESTAMP,
    CHECK (scheduled_end > scheduled_start),
    CHECK (actual_end IS NULL OR actual_start IS NULL OR actual_end > actual_start),
    EXCLUDE USING gist (or_room_id WITH =, tsrange(scheduled_start, scheduled_end) WITH &&)
);

CREATE TABLE Surgical_Team_Assignment (
    case_id INTEGER NOT NULL REFERENCES Surgery_Case(case_id),
    doctor_id INTEGER NOT NULL REFERENCES Doctor(doctor_id),
    role VARCHAR(30) NOT NULL CHECK (role IN ('primary_surgeon','assistant','anesthesiologist','scrub_nurse','circulating_nurse')),
    PRIMARY KEY (case_id, doctor_id, role)
);

CREATE TABLE PACU_Record (
    pacu_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    case_id INTEGER NOT NULL REFERENCES Surgery_Case(case_id) UNIQUE,
    arrival_time TIMESTAMP NOT NULL,
    discharge_time TIMESTAMP,
    aldrete_score INTEGER CHECK (aldrete_score BETWEEN 0 AND 10),
    pain_score INTEGER CHECK (pain_score BETWEEN 0 AND 10),
    complications TEXT
);

CREATE TABLE Surgical_Count (
    count_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    case_id INTEGER NOT NULL REFERENCES Surgery_Case(case_id),
    count_type VARCHAR(30) NOT NULL CHECK (count_type IN ('sponge','needle','instrument')),
    pre_count INTEGER NOT NULL CHECK (pre_count >= 0),
    post_count INTEGER NOT NULL CHECK (post_count >= 0),
    verified_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    verified_by_doctor_id INTEGER REFERENCES Doctor(doctor_id)
);

CREATE INDEX idx_doctor_department ON Doctor(department_code);
CREATE INDEX idx_geo_hospital ON Geo_Location(hospital_id);
CREATE INDEX idx_room_hospital ON Room(hospital_id);
CREATE INDEX idx_room_type ON Room(room_type);
CREATE INDEX idx_appointment_patient ON Appointment(patient_number);
CREATE INDEX idx_appointment_doctor ON Appointment(doctor_id);
CREATE INDEX idx_appointment_date ON Appointment(appointment_date);
CREATE INDEX idx_appointment_case ON Appointment(case_id);
CREATE INDEX idx_prescription_doctor ON Prescription(doctor_id);
CREATE INDEX idx_prescription_patient ON Prescription(patient_number);
CREATE INDEX idx_treats_doctor ON Treats(doctor_id);
CREATE INDEX idx_payment_appointment ON Payment(appointment_id);
CREATE INDEX idx_payment_date ON Payment(payment_date);
CREATE INDEX idx_scan_patient ON Scan_Document(patient_number);
CREATE INDEX idx_scan_uploader ON Scan_Document(uploaded_by_doctor_id);
CREATE INDEX idx_user_doctor ON User_Account(doctor_id);
CREATE INDEX idx_user_patient ON User_Account(patient_number);
CREATE INDEX idx_contact_status ON Contact_Inquiry(status);
CREATE INDEX idx_surgery_patient ON Surgery_Case(patient_number);
CREATE INDEX idx_surgery_procedure ON Surgery_Case(procedure_code);
CREATE INDEX idx_surgery_status ON Surgery_Case(status);
CREATE INDEX idx_surgery_priority ON Surgery_Case(priority);
CREATE INDEX idx_schedule_case ON Surgery_Schedule(case_id);
CREATE INDEX idx_schedule_room ON Surgery_Schedule(or_room_id);
CREATE INDEX idx_schedule_dates ON Surgery_Schedule(scheduled_start, scheduled_end);
CREATE INDEX idx_team_case ON Surgical_Team_Assignment(case_id);
CREATE INDEX idx_team_doctor ON Surgical_Team_Assignment(doctor_id);

ALTER TABLE Doctor ADD CONSTRAINT fk_doctor_department FOREIGN KEY (department_code) REFERENCES Department(department_code);
ALTER TABLE Department ADD CONSTRAINT fk_department_hospital FOREIGN KEY (hospital_id) REFERENCES Hospital(hospital_id);
ALTER TABLE Department ADD CONSTRAINT fk_department_chairman FOREIGN KEY (chairman_doctor_id) REFERENCES Doctor(doctor_id);
