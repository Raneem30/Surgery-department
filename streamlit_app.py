import sqlite3
import os
import math
import time
import re
from datetime import datetime

import streamlit as st
import pandas as pd
import plotly.express as px

DB_PATH = os.path.join(os.path.dirname(__file__), "surgery.db")
UPLOAD_DIR = os.path.join(os.path.dirname(__file__), "uploads")
QUERIES_PATH = os.path.join(os.path.dirname(__file__), "sql", "queries.sql")
os.makedirs(UPLOAD_DIR, exist_ok=True)

def load_queries():
    text = open(QUERIES_PATH).read()
    blocks, cur_num, cur_title, cur_lines = [], None, None, []
    for line in text.split("\n"):
        m = re.match(r'^-- (\d+)\.\s*(.*)', line)
        if m:
            if cur_num is not None:
                blocks.append((cur_num, cur_title, "\n".join(cur_lines).strip()))
            cur_num, cur_title = int(m.group(1)), m.group(2).strip()
            cur_lines = []
        elif cur_num is not None:
            if line.strip().startswith("-- ==="): continue
            if line.strip().startswith("-- ") and not re.match(r'^-- (\d+)\.', line): cur_lines.append(line)
            elif not line.strip().startswith("--"): cur_lines.append(line)
    if cur_num is not None:
        blocks.append((cur_num, cur_title, "\n".join(cur_lines).strip()))
    return {n: {"title": t, "sql": s} for n, t, s in blocks if s}

def adapt_sql(sql):
    sql = re.sub(r'\$(\d+)', '?', sql)
    sql = sql.replace('::date', '').replace('::integer', '')
    sql = sql.replace('CURRENT_DATE', "date('now')")
    sql = sql.replace("TO_CHAR(a.appointment_date, 'YYYY-MM')", "strftime('%Y-%m', a.appointment_date)")
    sql = sql.replace("TO_CHAR(payment_date, 'YYYY-MM')", "strftime('%Y-%m', payment_date)")
    sql = sql.replace('RETURNING prescription_id', '')
    sql = sql.replace('TRUE', '1').replace('FALSE', '0')
    return sql

def get_db():
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn

def run_query(num, params=None, fetch=True):
    q = st.session_state.queries
    if num not in q:
        st.error(f"Query #{num} not found"); return None if fetch else 0
    sql = adapt_sql(q[num]["sql"])
    if params is None: params = ()
    conn = get_db()
    try:
        if fetch:
            rows = conn.execute(sql, params).fetchall(); conn.commit()
            return [dict(r) for r in rows]
        cur = conn.execute(sql, params); conn.commit()
        return cur.lastrowid
    except Exception as e:
        st.error(f"Query #{num} failed: {e}")
        return None if fetch else 0
    finally:
        conn.close()

INIT_SQL = """
CREATE TABLE IF NOT EXISTS Hospital (hospital_id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(100) NOT NULL, address VARCHAR(200) NOT NULL);
CREATE TABLE IF NOT EXISTS Geo_Location (location_id INTEGER PRIMARY KEY AUTOINCREMENT, hospital_id INTEGER NOT NULL REFERENCES Hospital(hospital_id), latitude DECIMAL(10,7) NOT NULL, longitude DECIMAL(10,7) NOT NULL);
CREATE TABLE IF NOT EXISTS Patient (patient_number VARCHAR(20) PRIMARY KEY, ssn VARCHAR(14) NOT NULL UNIQUE, name VARCHAR(100) NOT NULL, address VARCHAR(200), phone VARCHAR(20), birthdate DATE NOT NULL, sex CHAR(1) NOT NULL CHECK (sex IN ('M','F')), medical_history TEXT, admission_date DATE NOT NULL, blood_pressure VARCHAR(20), heart_rate INTEGER CHECK (heart_rate > 0), temperature DECIMAL(4,1), spo2 INTEGER CHECK (spo2 >= 0 AND spo2 <= 100), recorded_at TIMESTAMP);
CREATE TABLE IF NOT EXISTS Doctor (doctor_id INTEGER PRIMARY KEY AUTOINCREMENT, ssn VARCHAR(14) NOT NULL UNIQUE, name VARCHAR(100) NOT NULL, sex CHAR(1) CHECK (sex IN ('M','F')), birth_date DATE, major_area VARCHAR(100) NOT NULL, degree VARCHAR(50) NOT NULL, department_code VARCHAR(10) NOT NULL, join_date DATE, email VARCHAR(100), phone VARCHAR(20));
CREATE TABLE IF NOT EXISTS Department (department_code VARCHAR(10) PRIMARY KEY, name VARCHAR(100) NOT NULL UNIQUE, hospital_id INTEGER NOT NULL REFERENCES Hospital(hospital_id), chairman_doctor_id INTEGER REFERENCES Doctor(doctor_id), chair_start_date DATE);
CREATE TABLE IF NOT EXISTS Department_Location (department_code VARCHAR(10) NOT NULL REFERENCES Department(department_code) ON DELETE CASCADE, location VARCHAR(200) NOT NULL, PRIMARY KEY (department_code, location));
CREATE TABLE IF NOT EXISTS Treats (patient_number VARCHAR(20) NOT NULL REFERENCES Patient(patient_number) ON DELETE CASCADE, doctor_id INTEGER NOT NULL REFERENCES Doctor(doctor_id), hours_per_week INTEGER CHECK (hours_per_week >= 0), PRIMARY KEY (patient_number, doctor_id));
CREATE TABLE IF NOT EXISTS Medication (medication_id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(100) NOT NULL UNIQUE);
CREATE TABLE IF NOT EXISTS Prescription (prescription_id INTEGER PRIMARY KEY AUTOINCREMENT, doctor_id INTEGER NOT NULL REFERENCES Doctor(doctor_id), patient_number VARCHAR(20) NOT NULL REFERENCES Patient(patient_number), prescription_date DATE NOT NULL, start_date DATE NOT NULL, end_date DATE NOT NULL, CHECK (end_date >= start_date));
CREATE TABLE IF NOT EXISTS Prescription_Medication (prescription_id INTEGER NOT NULL REFERENCES Prescription(prescription_id) ON DELETE CASCADE, medication_id INTEGER NOT NULL REFERENCES Medication(medication_id) ON DELETE RESTRICT, times_per_day INTEGER NOT NULL CHECK (times_per_day > 0), dose VARCHAR(50) NOT NULL, PRIMARY KEY (prescription_id, medication_id));
CREATE TABLE IF NOT EXISTS Room (room_id INTEGER PRIMARY KEY AUTOINCREMENT, hospital_id INTEGER NOT NULL REFERENCES Hospital(hospital_id), room_number VARCHAR(20) NOT NULL, room_type VARCHAR(50) NOT NULL CHECK (room_type IN ('OR','PACU','ICU','Ward','Clinic')), or_type VARCHAR(50) CHECK (or_type IN ('general','cardiac','hybrid','robotic')), has_robot INTEGER DEFAULT 0, has_c_arm INTEGER DEFAULT 0, is_available INTEGER DEFAULT 1, CHECK ((room_type = 'OR' AND or_type IS NOT NULL) OR (room_type != 'OR' AND or_type IS NULL)));
CREATE TABLE IF NOT EXISTS Surgical_Procedure (procedure_code VARCHAR(20) PRIMARY KEY, name VARCHAR(200) NOT NULL, standard_duration_minutes INTEGER NOT NULL CHECK (standard_duration_minutes > 0), required_room_type VARCHAR(50) NOT NULL CHECK (required_room_type IN ('general','cardiac','hybrid','robotic')), specialty VARCHAR(100) NOT NULL);
CREATE TABLE IF NOT EXISTS Surgery_Case (case_id INTEGER PRIMARY KEY AUTOINCREMENT, patient_number VARCHAR(20) NOT NULL REFERENCES Patient(patient_number), procedure_code VARCHAR(20) NOT NULL REFERENCES Surgical_Procedure(procedure_code), priority VARCHAR(20) NOT NULL CHECK (priority IN ('elective','emergency','urgent')), status VARCHAR(20) NOT NULL CHECK (status IN ('scheduled','pre_op','in_or','in_pacu','completed','cancelled')), cancel_reason VARCHAR(500), created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS Appointment (appointment_id INTEGER PRIMARY KEY AUTOINCREMENT, patient_number VARCHAR(20) NOT NULL REFERENCES Patient(patient_number), doctor_id INTEGER NOT NULL REFERENCES Doctor(doctor_id), room_id INTEGER REFERENCES Room(room_id), appointment_date TIMESTAMP NOT NULL, status VARCHAR(20) NOT NULL CHECK (status IN ('scheduled','completed','cancelled')), reason VARCHAR(500), case_id INTEGER REFERENCES Surgery_Case(case_id) ON DELETE SET NULL);
CREATE TABLE IF NOT EXISTS Payment (payment_id INTEGER PRIMARY KEY AUTOINCREMENT, appointment_id INTEGER NOT NULL REFERENCES Appointment(appointment_id) UNIQUE, amount DECIMAL(10,2) NOT NULL, payment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, payment_type VARCHAR(20) NOT NULL CHECK (payment_type IN ('register','pay','refund')), description VARCHAR(500));
CREATE TABLE IF NOT EXISTS User_Account (user_id INTEGER PRIMARY KEY AUTOINCREMENT, username VARCHAR(50) NOT NULL UNIQUE, password_hash VARCHAR(255) NOT NULL, role VARCHAR(20) NOT NULL CHECK (role IN ('admin','doctor','nurse','staff','patient')), doctor_id INTEGER REFERENCES Doctor(doctor_id), patient_number VARCHAR(20) REFERENCES Patient(patient_number), last_login TIMESTAMP);
CREATE TABLE IF NOT EXISTS Contact_Inquiry (inquiry_id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(100) NOT NULL, email VARCHAR(100) NOT NULL, phone VARCHAR(20), subject VARCHAR(200) NOT NULL, message TEXT NOT NULL, submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','read','replied','closed')));
CREATE TABLE IF NOT EXISTS Scan_Document (scan_id INTEGER PRIMARY KEY AUTOINCREMENT, patient_number VARCHAR(20) NOT NULL REFERENCES Patient(patient_number), uploaded_by_doctor_id INTEGER NOT NULL REFERENCES Doctor(doctor_id), file_path VARCHAR(500) NOT NULL, upload_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, description VARCHAR(200), document_type VARCHAR(50) CHECK (document_type IN ('consent','operative_report','imaging','lab_result')));
CREATE TABLE IF NOT EXISTS Surgery_Schedule (schedule_id INTEGER PRIMARY KEY AUTOINCREMENT, case_id INTEGER NOT NULL REFERENCES Surgery_Case(case_id) UNIQUE, or_room_id INTEGER NOT NULL REFERENCES Room(room_id), scheduled_start TIMESTAMP NOT NULL, scheduled_end TIMESTAMP NOT NULL, actual_start TIMESTAMP, actual_end TIMESTAMP, CHECK (scheduled_end > scheduled_start));
CREATE TABLE IF NOT EXISTS Surgical_Team_Assignment (case_id INTEGER NOT NULL REFERENCES Surgery_Case(case_id), doctor_id INTEGER NOT NULL REFERENCES Doctor(doctor_id), role VARCHAR(30) NOT NULL CHECK (role IN ('primary_surgeon','assistant','anesthesiologist','scrub_nurse','circulating_nurse')), PRIMARY KEY (case_id, doctor_id, role));
CREATE TABLE IF NOT EXISTS PACU_Record (pacu_id INTEGER PRIMARY KEY AUTOINCREMENT, case_id INTEGER NOT NULL REFERENCES Surgery_Case(case_id) UNIQUE, arrival_time TIMESTAMP NOT NULL, discharge_time TIMESTAMP, aldrete_score INTEGER CHECK (aldrete_score >= 0 AND aldrete_score <= 10), pain_score INTEGER CHECK (pain_score >= 0 AND pain_score <= 10), complications TEXT);
CREATE TABLE IF NOT EXISTS Surgical_Count (count_id INTEGER PRIMARY KEY AUTOINCREMENT, case_id INTEGER NOT NULL REFERENCES Surgery_Case(case_id), count_type VARCHAR(30) NOT NULL CHECK (count_type IN ('sponge','needle','instrument')), pre_count INTEGER NOT NULL CHECK (pre_count >= 0), post_count INTEGER NOT NULL CHECK (post_count >= 0), verified_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, verified_by_doctor_id INTEGER REFERENCES Doctor(doctor_id));
"""

SEED_SQL = """
INSERT OR IGNORE INTO Hospital (hospital_id, name, address) VALUES (1, 'Cairo University Hospital', 'Cairo, Egypt');
INSERT OR IGNORE INTO Geo_Location (hospital_id, latitude, longitude) VALUES (1, 30.0444, 31.2357);
INSERT OR IGNORE INTO Doctor (doctor_id, ssn, name, sex, birth_date, major_area, degree, department_code, join_date, email, phone) VALUES (1, '111-11-1111', 'Ahmed Ali', 'M', '1975-03-15', 'Cardiac Surgery', 'MD', 'CARD', '2010-01-01', 'ahmed@hospital.com', '0111111111');
INSERT OR IGNORE INTO Doctor (doctor_id, ssn, name, sex, birth_date, major_area, degree, department_code, join_date, email, phone) VALUES (2, '222-22-2222', 'Soha Hassan', 'F', '1980-07-20', 'General Surgery', 'MD', 'SURG', '2012-06-01', 'soha@hospital.com', '0122222222');
INSERT OR IGNORE INTO Doctor (doctor_id, ssn, name, sex, birth_date, major_area, degree, department_code, join_date, email, phone) VALUES (3, '333-33-3333', 'Mona Ibrahim', 'F', '1985-11-10', 'Anesthesiology', 'MD', 'SURG', '2015-03-01', 'mona@hospital.com', '0133333333');
INSERT OR IGNORE INTO Department (department_code, name, hospital_id, chairman_doctor_id, chair_start_date) VALUES ('SURG', 'Surgery', 1, 2, '2020-01-01');
INSERT OR IGNORE INTO Department (department_code, name, hospital_id, chairman_doctor_id, chair_start_date) VALUES ('CARD', 'Cardiology', 1, 1, '2020-01-01');
INSERT OR IGNORE INTO Department_Location (department_code, location) VALUES ('SURG', 'Building A, 2nd Floor');
INSERT OR IGNORE INTO Department_Location (department_code, location) VALUES ('CARD', 'Building A, 3rd Floor');
INSERT OR IGNORE INTO Patient (patient_number, ssn, name, address, phone, birthdate, sex, medical_history, admission_date, blood_pressure, heart_rate, temperature, spo2, recorded_at) VALUES ('P001', '123-45-6789', 'Omar Farouk', 'Cairo', '0101111111', '1990-01-15', 'M', 'None', '2026-05-18', '120/80', 72, 36.6, 98, '2026-05-18 08:00:00');
INSERT OR IGNORE INTO Patient (patient_number, ssn, name, address, phone, birthdate, sex, medical_history, admission_date, blood_pressure, heart_rate, temperature, spo2, recorded_at) VALUES ('P002', '234-56-7890', 'Layla Kamal', 'Giza', '0102222222', '1985-06-20', 'F', 'Diabetes', '2026-05-19', '130/85', 78, 37.0, 97, '2026-05-19 09:00:00');
INSERT OR IGNORE INTO Patient (patient_number, ssn, name, address, phone, birthdate, sex, medical_history, admission_date, blood_pressure, heart_rate, temperature, spo2, recorded_at) VALUES ('P003', '345-67-8901', 'Youssef Nabil', 'Alexandria', '0103333333', '1970-12-10', 'M', 'Hypertension', '2026-05-17', '140/90', 80, 36.8, 96, '2026-05-17 10:00:00');
INSERT OR IGNORE INTO Patient (patient_number, ssn, name, address, phone, birthdate, sex, medical_history, admission_date, blood_pressure, heart_rate, temperature, spo2, recorded_at) VALUES ('P004', '456-78-9012', 'Nour El-Din', 'Mansoura', '0104444444', '2000-08-25', 'M', 'None', '2026-05-20', '115/75', 68, 36.5, 99, '2026-05-20 07:00:00');
INSERT OR IGNORE INTO Patient (patient_number, ssn, name, address, phone, birthdate, sex, medical_history, admission_date, blood_pressure, heart_rate, temperature, spo2, recorded_at) VALUES ('P005', '567-89-0123', 'Hana Mahmoud', 'Cairo', '0105555555', '1995-03-05', 'F', 'Asthma', '2026-05-16', '118/78', 70, 36.7, 98, '2026-05-16 11:00:00');
INSERT OR IGNORE INTO Room (room_id, hospital_id, room_number, room_type, or_type, has_robot, has_c_arm, is_available) VALUES (1, 1, 'OR-1', 'OR', 'general', 0, 1, 1);
INSERT OR IGNORE INTO Room (room_id, hospital_id, room_number, room_type, or_type, has_robot, has_c_arm, is_available) VALUES (2, 1, 'OR-2', 'OR', 'cardiac', 1, 1, 1);
INSERT OR IGNORE INTO Room (room_id, hospital_id, room_number, room_type, or_type, has_robot, has_c_arm, is_available) VALUES (3, 1, 'W-01', 'Ward', NULL, 0, 0, 1);
INSERT OR IGNORE INTO Treats (patient_number, doctor_id, hours_per_week) VALUES ('P001', 1, 5); INSERT OR IGNORE INTO Treats (patient_number, doctor_id, hours_per_week) VALUES ('P002', 2, 3);
INSERT OR IGNORE INTO Treats (patient_number, doctor_id, hours_per_week) VALUES ('P003', 1, 4); INSERT OR IGNORE INTO Treats (patient_number, doctor_id, hours_per_week) VALUES ('P004', 2, 2);
INSERT OR IGNORE INTO Treats (patient_number, doctor_id, hours_per_week) VALUES ('P005', 2, 3);
INSERT OR IGNORE INTO Surgical_Procedure (procedure_code, name, standard_duration_minutes, required_room_type, specialty) VALUES ('APP', 'Appendectomy', 60, 'general', 'General Surgery');
INSERT OR IGNORE INTO Surgical_Procedure (procedure_code, name, standard_duration_minutes, required_room_type, specialty) VALUES ('CHOL', 'Cholecystectomy', 90, 'general', 'General Surgery');
INSERT OR IGNORE INTO Surgical_Procedure (procedure_code, name, standard_duration_minutes, required_room_type, specialty) VALUES ('CABG', 'Coronary Artery Bypass Graft', 240, 'cardiac', 'Cardiac Surgery');
INSERT OR IGNORE INTO Surgery_Case (case_id, patient_number, procedure_code, priority, status, created_at) VALUES (1, 'P001', 'APP', 'elective', 'completed', '2026-05-18 10:00:00');
INSERT OR IGNORE INTO Surgery_Case (case_id, patient_number, procedure_code, priority, status, created_at) VALUES (2, 'P003', 'CABG', 'urgent', 'in_or', '2026-05-19 14:00:00');
INSERT OR IGNORE INTO Surgery_Schedule (case_id, or_room_id, scheduled_start, scheduled_end) VALUES (2, 2, '2026-05-20 09:00:00', '2026-05-20 10:00:00');
INSERT OR IGNORE INTO Surgical_Team_Assignment (case_id, doctor_id, role) VALUES (2, 1, 'primary_surgeon');
INSERT OR IGNORE INTO Surgical_Team_Assignment (case_id, doctor_id, role) VALUES (2, 3, 'anesthesiologist');
INSERT OR IGNORE INTO Appointment (appointment_id, patient_number, doctor_id, room_id, appointment_date, status, reason, case_id) VALUES (1, 'P001', 1, 1, '2026-05-20 09:00:00', 'scheduled', 'Appendectomy consultation', 1);
INSERT OR IGNORE INTO Appointment (appointment_id, patient_number, doctor_id, room_id, appointment_date, status, reason, case_id) VALUES (2, 'P002', 2, 3, '2026-05-19 14:00:00', 'completed', 'Gallbladder pain', NULL);
INSERT OR IGNORE INTO Appointment (appointment_id, patient_number, doctor_id, room_id, appointment_date, status, reason, case_id) VALUES (3, 'P003', 1, 2, '2026-05-18 10:00:00', 'completed', 'Heart checkup', 2);
INSERT OR IGNORE INTO Appointment (appointment_id, patient_number, doctor_id, room_id, appointment_date, status, reason, case_id) VALUES (4, 'P004', 2, 3, '2026-05-25 11:00:00', 'scheduled', 'Consultation', NULL);
INSERT OR IGNORE INTO Appointment (appointment_id, patient_number, doctor_id, room_id, appointment_date, status, reason, case_id) VALUES (5, 'P001', 2, 1, '2026-05-17 09:00:00', 'cancelled', 'No show', NULL);
INSERT OR IGNORE INTO Payment (appointment_id, amount, payment_type, description) VALUES (2, 2000.00, 'pay', 'Consultation payment');
INSERT OR IGNORE INTO Payment (appointment_id, amount, payment_type, description) VALUES (3, 3000.00, 'pay', 'Cardiac checkup fee');
INSERT OR IGNORE INTO Payment (appointment_id, amount, payment_type, description) VALUES (5, 1000.00, 'refund', 'Refund for cancelled appointment');
INSERT OR IGNORE INTO Prescription (prescription_id, doctor_id, patient_number, prescription_date, start_date, end_date) VALUES (1, 1, 'P001', '2026-05-18', '2026-05-18', '2026-05-25');
INSERT OR IGNORE INTO Prescription (prescription_id, doctor_id, patient_number, prescription_date, start_date, end_date) VALUES (2, 2, 'P002', '2026-05-19', '2026-05-19', '2026-06-02');
INSERT OR IGNORE INTO Medication (medication_id, name) VALUES (1, 'Amoxicillin'); INSERT OR IGNORE INTO Medication (medication_id, name) VALUES (2, 'Ibuprofen');
INSERT OR IGNORE INTO Medication (medication_id, name) VALUES (3, 'Paracetamol'); INSERT OR IGNORE INTO Medication (medication_id, name) VALUES (4, 'Metformin');
INSERT OR IGNORE INTO Prescription_Medication (prescription_id, medication_id, times_per_day, dose) VALUES (1, 1, 3, '500mg');
INSERT OR IGNORE INTO Prescription_Medication (prescription_id, medication_id, times_per_day, dose) VALUES (1, 2, 2, '400mg');
INSERT OR IGNORE INTO Prescription_Medication (prescription_id, medication_id, times_per_day, dose) VALUES (2, 2, 3, '200mg');
INSERT OR IGNORE INTO Prescription_Medication (prescription_id, medication_id, times_per_day, dose) VALUES (2, 3, 2, '500mg');
INSERT OR IGNORE INTO Contact_Inquiry (inquiry_id, name, email, phone, subject, message, status) VALUES (1, 'Ali Hassan', 'ali@example.com', '0144444444', 'Appointment issue', 'I cannot book an appointment online.', 'pending');
INSERT OR IGNORE INTO Contact_Inquiry (inquiry_id, name, email, phone, subject, message, status) VALUES (2, 'Mona Said', 'mona@example.com', '0155555555', 'Billing question', 'I need a receipt for my payment.', 'closed');
INSERT OR IGNORE INTO Scan_Document (scan_id, patient_number, uploaded_by_doctor_id, file_path, upload_date, description, document_type) VALUES (1, 'P001', 1, 'uploads/ct_scan_001.pdf', '2026-05-18 11:00:00', 'CT Scan of abdomen', 'imaging');
INSERT OR IGNORE INTO Scan_Document (scan_id, patient_number, uploaded_by_doctor_id, file_path, upload_date, description, document_type) VALUES (2, 'P002', 2, 'uploads/consent_002.pdf', '2026-05-19 15:00:00', 'Surgery consent form', 'consent');
INSERT OR IGNORE INTO User_Account (username, password_hash, role, doctor_id, patient_number) VALUES ('admin', 'admin', 'admin', NULL, NULL);
INSERT OR IGNORE INTO User_Account (username, password_hash, role, doctor_id, patient_number) VALUES ('doctor', 'doctor', 'doctor', 1, NULL);
INSERT OR IGNORE INTO User_Account (username, password_hash, role, doctor_id, patient_number) VALUES ('patient', 'patient', 'patient', NULL, 'P001');
INSERT OR IGNORE INTO User_Account (username, password_hash, role, doctor_id, patient_number) VALUES ('nurse', 'nurse', 'staff', NULL, NULL);
INSERT OR IGNORE INTO PACU_Record (case_id, arrival_time, discharge_time, aldrete_score, pain_score, complications) VALUES (1, '2026-05-18 12:00:00', '2026-05-18 13:30:00', 9, 2, 'Mild nausea');
INSERT OR IGNORE INTO Surgical_Count (case_id, count_type, pre_count, post_count, verified_by_doctor_id) VALUES (1, 'sponge', 10, 10, 1);
"""

def init_database():
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    conn.execute("PRAGMA foreign_keys = ON")
    conn.executescript(INIT_SQL)
    if conn.execute("SELECT COUNT(*) FROM Hospital").fetchone()[0] == 0:
        conn.executescript(SEED_SQL)
    conn.commit(); conn.close()

def login_user(username, password):
    for qn in [1, 13, 24, 56]:
        conn = get_db()
        rows = conn.execute(adapt_sql(st.session_state.queries[qn]["sql"]), (username, password)).fetchall()
        conn.close()
        if rows: return dict(rows[0])
    return None

# ── Patient ────────────────────────────────────────────────────

def p_profile():
    st.subheader("My Profile")
    rows = run_query(2, (st.session_state.patient_number,))
    if rows: st.json(rows[0])

def p_doctors():
    st.subheader("My Doctors")
    rows = run_query(3, (st.session_state.patient_number,))
    if rows: st.dataframe(pd.DataFrame(rows), use_container_width=True)

def p_appointments():
    st.subheader("My Appointments")
    rows = run_query(4, (st.session_state.patient_number,))
    if rows: st.dataframe(pd.DataFrame(rows), use_container_width=True)

def p_book():
    st.subheader("Book Appointment")
    conn = get_db()
    doctors = conn.execute(adapt_sql(st.session_state.queries[27]["sql"])).fetchall()
    rooms = conn.execute("SELECT room_id, room_number, room_type FROM Room WHERE is_available=1").fetchall()
    conn.close()
    doc_choices = {f"{d['name']} ({d['major_area']})": d['doctor_id'] for d in doctors}
    room_choices = {f"{r['room_number']} ({r['room_type']})": r['room_id'] for r in rooms}
    with st.form("book_f"):
        dl = st.selectbox("Doctor", options=list(doc_choices.keys()))
        rl = st.selectbox("Room", options=["None"] + list(room_choices.keys()))
        dt = st.datetime_input("Date")
        rsn = st.text_area("Reason")
        if st.form_submit_button("Book", type="primary"):
            rid = room_choices[rl] if rl != "None" else None
            run_query(5, (st.session_state.patient_number, doc_choices[dl], rid, dt, rsn), fetch=False)
            st.success("Booked")

def p_cancel():
    st.subheader("Cancel Appointment")
    rows = run_query(4, (st.session_state.patient_number,))
    sched = [r for r in rows if r["status"] == "scheduled"]
    if not sched: st.info("No scheduled appointments"); return
    choices = {f"#{r['appointment_id']} — {r['appointment_date']}": r['appointment_id'] for r in sched}
    sel = st.selectbox("Select", options=list(choices.keys()))
    if st.button("Cancel", type="primary"):
        aid = choices[sel]
        run_query(6, (aid, st.session_state.patient_number), fetch=False)
        pay = run_query(8, (st.session_state.patient_number,))
        for p in pay or []:
            if p["appointment_id"] == aid and p["payment_type"] == "pay":
                run_query(7, (aid, p["amount"], "Refund for cancelled appointment"), fetch=False)
        st.success("Cancelled")

def p_pay():
    st.subheader("Make Payment")
    rows = run_query(4, (st.session_state.patient_number,))
    open_appts = [r for r in rows if r["status"] != "cancelled"]
    if not open_appts: st.info("No payable appointments"); return
    choices = {f"#{r['appointment_id']} — {r['appointment_date']}": r['appointment_id'] for r in open_appts}
    with st.form("pay_f"):
        sel = st.selectbox("Appointment", options=list(choices.keys()))
        amt = st.number_input("Amount", min_value=0.01, step=10.0)
        desc = st.text_input("Description")
        if st.form_submit_button("Pay", type="primary"):
            run_query(7, (choices[sel], amt, desc), fetch=False)
            st.success("Paid")

def p_payments():
    st.subheader("Payment History")
    rows = run_query(8, (st.session_state.patient_number,))
    if rows:
        df = pd.DataFrame(rows)
        st.dataframe(df, use_container_width=True)
        net = df.loc[df.payment_type == "pay", "amount"].sum() - df.loc[df.payment_type == "refund", "amount"].sum()
        st.metric("Net Total", f"${net:.2f}")

def p_rx():
    st.subheader("Prescriptions")
    rows = run_query(9, (st.session_state.patient_number,))
    if rows: st.dataframe(pd.DataFrame(rows), use_container_width=True)

def p_scans():
    st.subheader("Scan Documents")
    rows = run_query(10, (st.session_state.patient_number,))
    if rows: st.dataframe(pd.DataFrame(rows), use_container_width=True)

def p_inquiry():
    st.subheader("Contact Inquiry")
    with st.form("inq_f"):
        n = st.text_input("Name"); e = st.text_input("Email"); ph = st.text_input("Phone")
        s = st.text_input("Subject"); m = st.text_area("Message")
        if st.form_submit_button("Submit", type="primary"):
            run_query(11, (n, e, ph, s, m), fetch=False)
            st.success("Submitted")

def p_nearest():
    st.subheader("Find Nearest Hospital")
    with st.form("geo_f"):
        lat = st.number_input("Latitude", value=30.0, format="%.6f")
        lon = st.number_input("Longitude", value=31.0, format="%.6f")
        if st.form_submit_button("Find", type="primary"):
            conn = get_db()
            rows = conn.execute("SELECT h.name, h.address, gl.latitude, gl.longitude FROM Geo_Location gl JOIN Hospital h ON h.hospital_id=gl.hospital_id").fetchall()
            conn.close()
            best, bd = None, float("inf")
            for r in rows:
                d = math.acos(min(1, max(-1,
                    math.sin(math.radians(lat)) * math.sin(math.radians(r["latitude"])) +
                    math.cos(math.radians(lat)) * math.cos(math.radians(r["latitude"])) *
                    math.cos(math.radians(r["longitude"]) - math.radians(lon))
                ))) * 6371
                if d < bd: bd, best = d, r
            if best: st.success(f"**{best['name']}** — {best['address']} ({bd:.2f} km)")

# ── Doctor ────────────────────────────────────────────────────

def d_profile():
    st.subheader("My Profile")
    rows = run_query(14, (st.session_state.doctor_id,))
    if rows: st.json(rows[0])

def d_appointments():
    st.subheader("My Appointments")
    rows = run_query(15, (st.session_state.doctor_id,))
    if rows: st.dataframe(pd.DataFrame(rows), use_container_width=True)

def d_patients():
    st.subheader("My Patients")
    rows = run_query(16, (st.session_state.doctor_id,))
    if rows: st.dataframe(pd.DataFrame(rows), use_container_width=True)

def d_patient_details():
    st.subheader("Patient Details")
    pno = st.text_input("Patient Number")
    if pno:
        rows = run_query(17, (pno,))
        if rows: st.json(rows[0])

def d_write_rx():
    st.subheader("Write Prescription")
    conn = get_db()
    patients = conn.execute(adapt_sql(st.session_state.queries[31]["sql"])).fetchall()
    meds = conn.execute("SELECT medication_id, name FROM Medication").fetchall()
    conn.close()
    p_choices = {f"{p['patient_number']} — {p['name']}": p['patient_number'] for p in patients}
    m_choices = {m['name']: m['medication_id'] for m in meds}
    with st.form("rx_f"):
        pl = st.selectbox("Patient", options=list(p_choices.keys()))
        rd = st.date_input("Rx Date"); sd = st.date_input("Start"); ed = st.date_input("End")
        ml = st.selectbox("Medication", options=list(m_choices.keys()))
        tpd = st.number_input("Times/day", min_value=1, step=1); dose = st.text_input("Dose")
        if st.form_submit_button("Write", type="primary"):
            conn = get_db()
            conn.execute(adapt_sql(st.session_state.queries[18]["sql"].split("\n\n")[0]),
                         (st.session_state.doctor_id, p_choices[pl], rd, sd, ed))
            rx_id = conn.execute("SELECT last_insert_rowid()").fetchone()[0]
            conn.execute(adapt_sql(st.session_state.queries[18]["sql"].split("\n\n")[1]),
                         (rx_id, m_choices[ml], tpd, dose))
            conn.commit(); conn.close()
            st.success("Prescription written")

def d_schedule():
    st.subheader("Schedule Appointment")
    conn = get_db()
    patients = conn.execute(adapt_sql(st.session_state.queries[31]["sql"])).fetchall()
    rooms = conn.execute("SELECT room_id, room_number, room_type FROM Room").fetchall()
    conn.close()
    p_choices = {f"{p['patient_number']} — {p['name']}": p['patient_number'] for p in patients}
    r_choices = {f"{r['room_number']} ({r['room_type']})": r['room_id'] for r in rooms}
    with st.form("sched_f"):
        pl = st.selectbox("Patient", options=list(p_choices.keys()))
        rl = st.selectbox("Room", options=["None"] + list(r_choices.keys()))
        dt = st.datetime_input("Date"); rsn = st.text_area("Reason")
        if st.form_submit_button("Schedule", type="primary"):
            rid = r_choices[rl] if rl != "None" else None
            run_query(19, (p_choices[pl], st.session_state.doctor_id, rid, dt, rsn), fetch=False)
            st.success("Scheduled")

def d_cancel():
    st.subheader("Cancel Appointment")
    rows = run_query(15, (st.session_state.doctor_id,))
    sched = [r for r in rows if r["status"] == "scheduled"]
    if not sched: st.info("None"); return
    choices = {f"#{r['appointment_id']} — {r['patient_number']} — {r['appointment_date']}": r['appointment_id'] for r in sched}
    sel = st.selectbox("Select", options=list(choices.keys()))
    if st.button("Cancel", type="primary"):
        run_query(20, (choices[sel], st.session_state.doctor_id), fetch=False)
        st.success("Cancelled")

def d_upload():
    st.subheader("Upload Scan")
    conn = get_db()
    patients = conn.execute(adapt_sql(st.session_state.queries[31]["sql"])).fetchall()
    conn.close()
    p_choices = {f"{p['patient_number']} — {p['name']}": p['patient_number'] for p in patients}
    with st.form("upl_f"):
        pl = st.selectbox("Patient", options=list(p_choices.keys()))
        dt = st.selectbox("Type", ["imaging", "consent", "operative_report", "lab_result"])
        desc = st.text_input("Description")
        fup = st.file_uploader("File")
        if st.form_submit_button("Upload", type="primary") and fup:
            fname = f"{int(time.time())}_{fup.name}"
            with open(os.path.join(UPLOAD_DIR, fname), "wb") as f: f.write(fup.getbuffer())
            run_query(21, (p_choices[pl], st.session_state.doctor_id, f"uploads/{fname}", desc, dt), fetch=False)
            st.success("Uploaded")

def d_reserve():
    st.subheader("Reserve Room")
    rows = run_query(39, ())
    ors = [r for r in rows if r["room_type"] == "OR" and r["is_available"]]
    if not ors: st.info("No available ORs"); return
    choices = {f"{r['room_number']} ({r['or_type']})": r['room_id'] for r in ors}
    sel = st.selectbox("OR", options=list(choices.keys()))
    if st.button("Reserve", type="primary"):
        run_query(22, (choices[sel],), fetch=False)
        st.success("Reserved")

def d_surgery():
    st.subheader("My Surgery Schedule")
    rows = run_query(23, (st.session_state.doctor_id,))
    if rows: st.dataframe(pd.DataFrame(rows), use_container_width=True)

# ── Admin ──────────────────────────────────────────────────────

def a_dashboard():
    st.subheader("Dashboard")
    rows = run_query(25, ())
    if rows:
        r = rows[0]
        cols = st.columns(4)
        cols[0].metric("Patients", r["total_patients"])
        cols[1].metric("Doctors", r["total_doctors"])
        cols[2].metric("Appointments", r["total_appointments"])
        cols[3].metric("Revenue", f"${r['total_revenue']:.2f}")
        status_rows = run_query(55, ())
        if status_rows:
            st.plotly_chart(px.pie(pd.DataFrame(status_rows), names="status", values="count", title="Surgery Status"), use_container_width=True)

def a_doctors():
    st.subheader("Doctors")
    t1, t2, t3, t4 = st.tabs(["List", "Create", "Update", "Delete"])
    with t1:
        rows = run_query(27, ())
        if rows: st.dataframe(pd.DataFrame(rows), use_container_width=True)
    with t2:
        conn = get_db(); depts = [d["department_code"] for d in conn.execute("SELECT department_code FROM Department").fetchall()]; conn.close()
        with st.form("c_doc"):
            ssn = st.text_input("SSN"); name = st.text_input("Name"); sex = st.selectbox("Sex", ["M","F"])
            bd = st.date_input("Birth"); major = st.text_input("Major"); deg = st.text_input("Degree")
            dept = st.selectbox("Dept", depts); jd = st.date_input("Join"); em = st.text_input("Email"); ph = st.text_input("Phone")
            if st.form_submit_button("Create", type="primary"):
                run_query(26, (ssn, name, sex, bd, major, deg, dept, jd, em, ph), fetch=False); st.success("Created")
    with t3:
        conn = get_db(); docs = conn.execute("SELECT doctor_id, name FROM Doctor").fetchall(); conn.close()
        doc_choices = {f"{d['doctor_id']} — {d['name']}": d['doctor_id'] for d in docs}
        sel = st.selectbox("Doctor", options=list(doc_choices.keys()), key="upd_doc")
        r = run_query(14, (doc_choices[sel],))
        if r:
            d = r[0]
            with st.form("u_doc"):
                ssn = st.text_input("SSN", d["ssn"]); name = st.text_input("Name", d["name"])
                sex = st.selectbox("Sex", ["M","F"], 0 if d["sex"]=="M" else 1)
                bd = st.date_input("Birth", datetime.strptime(d["birth_date"],"%Y-%m-%d").date() if d["birth_date"] else datetime.today())
                major = st.text_input("Major", d["major_area"]); deg = st.text_input("Degree", d["degree"])
                conn2 = get_db(); depts2 = [r["department_code"] for r in conn2.execute("SELECT department_code FROM Department").fetchall()]; conn2.close()
                dept = st.selectbox("Dept", depts2, index=depts2.index(d["department_code"]) if d["department_code"] in depts2 else 0)
                jd = st.date_input("Join", datetime.strptime(d["join_date"],"%Y-%m-%d").date() if d["join_date"] else datetime.today())
                em = st.text_input("Email", d["email"] or ""); ph = st.text_input("Phone", d["phone"] or "")
                if st.form_submit_button("Update", type="primary"):
                    run_query(28, (ssn, name, sex, bd, major, deg, dept, jd, em, ph, d["doctor_id"]), fetch=False); st.success("Updated")
    with t4:
        conn = get_db(); docs = conn.execute("SELECT doctor_id, name FROM Doctor").fetchall(); conn.close()
        doc_choices = {f"{d['doctor_id']} — {d['name']}": d['doctor_id'] for d in docs}
        sel = st.selectbox("Doctor to delete", options=list(doc_choices.keys()), key="del_doc")
        if st.button("Delete", type="primary"):
            run_query(29, (doc_choices[sel],), fetch=False); st.success("Deleted")

def a_patients():
    st.subheader("Patients")
    t1, t2, t3, t4 = st.tabs(["List", "Create", "Update", "Delete"])
    with t1:
        rows = run_query(31, ())
        if rows: st.dataframe(pd.DataFrame(rows), use_container_width=True)
    with t2:
        with st.form("c_pat"):
            pno = st.text_input("Patient Number"); ssn = st.text_input("SSN"); name = st.text_input("Name")
            addr = st.text_input("Address"); ph = st.text_input("Phone"); bd = st.date_input("Birth")
            sex = st.selectbox("Sex", ["M","F"]); hist = st.text_area("History"); adm = st.date_input("Admission")
            if st.form_submit_button("Create", type="primary"):
                run_query(30, (pno, ssn, name, addr, ph, bd, sex, hist, adm), fetch=False); st.success("Created")
    with t3:
        conn = get_db(); pats = conn.execute("SELECT patient_number, name FROM Patient").fetchall(); conn.close()
        pat_choices = {f"{p['patient_number']} — {p['name']}": p['patient_number'] for p in pats}
        sel = st.selectbox("Patient", options=list(pat_choices.keys()), key="upd_pat")
        r = run_query(31, ())
        match = [x for x in r if x["patient_number"] == pat_choices[sel]] if r else []
        if match:
            p = match[0]
            with st.form("u_pat"):
                ssn = st.text_input("SSN", p["ssn"]); name = st.text_input("Name", p["name"])
                addr = st.text_input("Address", p["address"] or ""); ph = st.text_input("Phone", p["phone"] or "")
                bd = st.date_input("Birth", datetime.strptime(p["birthdate"],"%Y-%m-%d").date())
                sex = st.selectbox("Sex", ["M","F"], 0 if p["sex"]=="M" else 1)
                hist = st.text_area("History", p["medical_history"] or "")
                adm = st.date_input("Admission", datetime.strptime(p["admission_date"],"%Y-%m-%d").date())
                if st.form_submit_button("Update", type="primary"):
                    run_query(32, (ssn, name, addr, ph, bd, sex, hist, adm, p["patient_number"]), fetch=False); st.success("Updated")
    with t4:
        conn = get_db(); pats = conn.execute("SELECT patient_number, name FROM Patient").fetchall(); conn.close()
        pat_choices = {f"{p['patient_number']} — {p['name']}": p['patient_number'] for p in pats}
        sel = st.selectbox("Patient to delete", options=list(pat_choices.keys()), key="del_pat")
        if st.button("Delete", type="primary"):
            run_query(33, (pat_choices[sel],), fetch=False); st.success("Deleted")

def a_departments():
    st.subheader("Departments")
    t1, t2, t3, t4 = st.tabs(["List", "Create", "Update", "Delete"])
    with t1:
        rows = run_query(35, ())
        if rows: st.dataframe(pd.DataFrame(rows), use_container_width=True)
    with t2:
        conn = get_db(); docs = conn.execute("SELECT doctor_id, name FROM Doctor").fetchall(); conn.close()
        doc_choices = {f"{d['doctor_id']} — {d['name']}": d['doctor_id'] for d in docs}
        with st.form("c_dept"):
            code = st.text_input("Code"); name = st.text_input("Name")
            chair = st.selectbox("Chairman", options=["None"] + list(doc_choices.keys())); csd = st.date_input("Chair Start")
            if st.form_submit_button("Create", type="primary"):
                cid = doc_choices[chair] if chair != "None" else None
                run_query(34, (code, name, 1, cid, csd), fetch=False); st.success("Created")
    with t3:
        conn = get_db(); depts = conn.execute("SELECT department_code, name FROM Department").fetchall()
        docs = conn.execute("SELECT doctor_id, name FROM Doctor").fetchall(); conn.close()
        dept_choices = {f"{d['department_code']} — {d['name']}": d['department_code'] for d in depts}
        doc_choices = {f"{d['doctor_id']} — {d['name']}": d['doctor_id'] for d in docs}
        sel = st.selectbox("Dept", options=list(dept_choices.keys()), key="upd_dept")
        r = run_query(35, ())
        match = [x for x in r if x["department_code"] == dept_choices[sel]] if r else []
        if match:
            d = match[0]
            with st.form("u_dept"):
                name = st.text_input("Name", d["name"])
                chair_opts = ["None"] + list(doc_choices.keys())
                curr = next((k for k,v in doc_choices.items() if v==d["chairman_doctor_id"]), "None")
                chair = st.selectbox("Chairman", options=chair_opts, index=chair_opts.index(curr) if curr in chair_opts else 0)
                csd = st.date_input("Chair Start", datetime.strptime(d["chair_start_date"],"%Y-%m-%d").date() if d["chair_start_date"] else datetime.today())
                if st.form_submit_button("Update", type="primary"):
                    cid = doc_choices[chair] if chair != "None" else None
                    run_query(36, (name, 1, cid, csd, d["department_code"]), fetch=False); st.success("Updated")
    with t4:
        conn = get_db(); depts = conn.execute("SELECT department_code, name FROM Department").fetchall(); conn.close()
        dept_choices = {f"{d['department_code']} — {d['name']}": d['department_code'] for d in depts}
        sel = st.selectbox("Dept to delete", options=list(dept_choices.keys()), key="del_dept")
        if st.button("Delete", type="primary"):
            run_query(37, (dept_choices[sel],), fetch=False); st.success("Deleted")

def a_rooms():
    st.subheader("Rooms")
    t1, t2, t3, t4 = st.tabs(["List", "Create", "Update", "Delete"])
    with t1:
        rows = run_query(39, ())
        if rows: st.dataframe(pd.DataFrame(rows), use_container_width=True)
    with t2:
        with st.form("c_room"):
            rno = st.text_input("Number"); rt = st.selectbox("Type", ["OR","PACU","ICU","Ward","Clinic"])
            ot = st.selectbox("OR Type", ["","general","cardiac","hybrid","robotic"])
            hr = st.checkbox("Has Robot"); hc = st.checkbox("Has C-Arm"); av = st.checkbox("Available", True)
            if st.form_submit_button("Create", type="primary"):
                run_query(38, (1, rno, rt, ot or None, int(hr), int(hc), int(av)), fetch=False); st.success("Created")
    with t3:
        conn = get_db(); rooms = conn.execute("SELECT room_id, room_number FROM Room").fetchall(); conn.close()
        rm_choices = {f"#{r['room_id']} — {r['room_number']}": r['room_id'] for r in rooms}
        sel = st.selectbox("Room", options=list(rm_choices.keys()), key="upd_rm")
        r = run_query(39, ())
        match = [x for x in r if x["room_id"] == rm_choices[sel]] if r else []
        if match:
            rm = match[0]
            with st.form("u_room"):
                rno = st.text_input("Number", rm["room_number"])
                rt = st.selectbox("Type", ["OR","PACU","ICU","Ward","Clinic"], index=["OR","PACU","ICU","Ward","Clinic"].index(rm["room_type"]))
                or_opts = ["","general","cardiac","hybrid","robotic"]
                ot = st.selectbox("OR Type", or_opts, index=or_opts.index(rm["or_type"]) if rm["or_type"] in or_opts else 0)
                hr = st.checkbox("Has Robot", bool(rm["has_robot"])); hc = st.checkbox("Has C-Arm", bool(rm["has_c_arm"]))
                av = st.checkbox("Available", bool(rm["is_available"]))
                if st.form_submit_button("Update", type="primary"):
                    run_query(40, (1, rno, rt, ot or None, int(hr), int(hc), int(av), rm["room_id"]), fetch=False); st.success("Updated")
    with t4:
        conn = get_db(); rooms = conn.execute("SELECT room_id, room_number FROM Room").fetchall(); conn.close()
        rm_choices = {f"#{r['room_id']} — {r['room_number']}": r['room_id'] for r in rooms}
        sel = st.selectbox("Room to delete", options=list(rm_choices.keys()), key="del_rm")
        if st.button("Delete", type="primary"):
            run_query(41, (rm_choices[sel],), fetch=False); st.success("Deleted")

def a_procedures():
    st.subheader("Procedures")
    t1, t2, t3, t4 = st.tabs(["List", "Create", "Update", "Delete"])
    with t1:
        rows = run_query(44, ())
        if rows: st.dataframe(pd.DataFrame(rows), use_container_width=True)
    with t2:
        with st.form("c_proc"):
            code = st.text_input("Code"); name = st.text_input("Name"); dur = st.number_input("Duration", min_value=1, step=5)
            rt = st.selectbox("Room Type", ["general","cardiac","hybrid","robotic"]); spec = st.text_input("Specialty")
            if st.form_submit_button("Create", type="primary"):
                run_query(43, (code, name, dur, rt, spec), fetch=False); st.success("Created")
    with t3:
        conn = get_db(); procs = conn.execute("SELECT procedure_code, name FROM Surgical_Procedure").fetchall(); conn.close()
        proc_choices = {f"{p['procedure_code']} — {p['name']}": p['procedure_code'] for p in procs}
        sel = st.selectbox("Procedure", options=list(proc_choices.keys()), key="upd_proc")
        r = run_query(44, ())
        match = [x for x in r if x["procedure_code"] == proc_choices[sel]] if r else []
        if match:
            p = match[0]
            with st.form("u_proc"):
                name = st.text_input("Name", p["name"]); dur = st.number_input("Duration", min_value=1, step=5, value=p["standard_duration_minutes"])
                rt = st.selectbox("Room Type", ["general","cardiac","hybrid","robotic"], index=["general","cardiac","hybrid","robotic"].index(p["required_room_type"]))
                spec = st.text_input("Specialty", p["specialty"])
                if st.form_submit_button("Update", type="primary"):
                    run_query(45, (name, dur, rt, spec, p["procedure_code"]), fetch=False); st.success("Updated")
    with t4:
        conn = get_db(); procs = conn.execute("SELECT procedure_code, name FROM Surgical_Procedure").fetchall(); conn.close()
        proc_choices = {f"{p['procedure_code']} — {p['name']}": p['procedure_code'] for p in procs}
        sel = st.selectbox("Procedure to delete", options=list(proc_choices.keys()), key="del_proc")
        if st.button("Delete", type="primary"):
            run_query(46, (proc_choices[sel],), fetch=False); st.success("Deleted")

def a_appointments():
    st.subheader("All Appointments")
    with st.form("filt"):
        col1, col2, col3, col4 = st.columns(4)
        sf = col1.selectbox("Status", ["","scheduled","completed","cancelled"])
        df_inp = col2.date_input("Date", value=None)
        conn = get_db()
        docs = conn.execute("SELECT doctor_id, name FROM Doctor").fetchall(); conn.close()
        doc_opts = {"": ""}; doc_opts.update({f"{d['doctor_id']} — {d['name']}": str(d['doctor_id']) for d in docs})
        docf = col3.selectbox("Doctor", options=list(doc_opts.keys()))
        patf = col4.text_input("Patient #")
        filtered = st.form_submit_button("Filter")
    rows = run_query(48, ())
    if rows:
        df = pd.DataFrame(rows)
        if sf: df = df[df["appointment_status"] == sf]
        if df_inp:
            df["_date"] = pd.to_datetime(df["appointment_date"]).dt.date
            df = df[df["_date"] == df_inp]
            df = df.drop(columns=["_date"])
        if doc_opts.get(docf): df = df[df["doctor_name"] == docf.replace(f" — {docf.split(' — ')[1]}", "") if " — " in docf else docf]
        if patf: df = df[df["patient_number"] == patf]
        st.dataframe(df, use_container_width=True)

def a_payments():
    st.subheader("Payments")
    rev = run_query(49, ())
    if rev: st.metric("Net Revenue", f"${rev[0]['total_revenue']:.2f}")
    rows = run_query(48, ())
    if rows: st.dataframe(pd.DataFrame(rows), use_container_width=True)

def a_inquiries():
    st.subheader("Contact Inquiries")
    rows = run_query(50, ())
    if rows:
        st.dataframe(pd.DataFrame(rows), use_container_width=True)
        iid = st.number_input("Mark as closed (ID)", min_value=1, step=1)
        if st.button("Close"):
            run_query(51, (iid,), fetch=False); st.success("Closed"); st.rerun()

def a_reports():
    st.subheader("Reports")
    rt = st.selectbox("Report", ["Appointments/Doctor/Month", "Revenue/Month", "Room Allocation", "Surgery Status"])
    if rt == "Appointments/Doctor/Month":
        rows = run_query(52, ())
        if rows:
            df = pd.DataFrame(rows); st.dataframe(df, use_container_width=True)
            st.plotly_chart(px.bar(df, x="doctor_name", y="appointment_count", color="month", barmode="group"), use_container_width=True)
    elif rt == "Revenue/Month":
        rows = run_query(53, ())
        if rows:
            df = pd.DataFrame(rows); st.dataframe(df, use_container_width=True)
            st.plotly_chart(px.line(df, x="month", y=["revenue","refunds","net_revenue"], markers=True), use_container_width=True)
    elif rt == "Room Allocation":
        rows = run_query(54, ())
        if rows:
            df = pd.DataFrame(rows); st.dataframe(df, use_container_width=True)
            st.plotly_chart(px.bar(df, x="room_number", y="total_schedules", color="room_type"), use_container_width=True)
    elif rt == "Surgery Status":
        rows = run_query(55, ())
        if rows:
            st.plotly_chart(px.pie(pd.DataFrame(rows), names="status", values="count", title="Surgery Status"), use_container_width=True)

# ── Nurse ──────────────────────────────────────────────────────

def n_or_schedule():
    st.subheader("Today's OR Schedule")
    rows = run_query(57, ())
    if rows: st.dataframe(pd.DataFrame(rows), use_container_width=True)
    else: st.info("No cases today")

def n_cases():
    st.subheader("Cases by Status")
    status = st.selectbox("Status", ["scheduled","pre_op","in_or","in_pacu","completed","cancelled"])
    rows = run_query(58, (status,))
    if rows: st.dataframe(pd.DataFrame(rows), use_container_width=True)

def n_assign():
    st.subheader("Assign Team")
    conn = get_db(); cases = conn.execute("SELECT case_id, status FROM Surgery_Case WHERE status IN ('scheduled','pre_op')").fetchall()
    docs = conn.execute("SELECT doctor_id, name, major_area FROM Doctor").fetchall(); conn.close()
    if not cases: st.info("No eligible cases"); return
    c_choices = {f"Case #{c['case_id']} ({c['status']})": c['case_id'] for c in cases}
    d_choices = {f"{d['name']} ({d['major_area']})": d['doctor_id'] for d in docs}
    with st.form("team_f"):
        cl = st.selectbox("Case", options=list(c_choices.keys()))
        dl = st.selectbox("Doctor", options=list(d_choices.keys()))
        role = st.selectbox("Role", ["primary_surgeon","assistant","anesthesiologist","scrub_nurse","circulating_nurse"])
        if st.form_submit_button("Assign", type="primary"):
            run_query(59, (c_choices[cl], d_choices[dl], role), fetch=False); st.success("Assigned")

def n_update_status():
    st.subheader("Update Case Status")
    conn = get_db(); cases = conn.execute("SELECT case_id, status FROM Surgery_Case WHERE status NOT IN ('completed','cancelled')").fetchall(); conn.close()
    if not cases: st.info("None"); return
    c_choices = {f"Case #{c['case_id']} ({c['status']})": c['case_id'] for c in cases}
    sel = st.selectbox("Case", options=list(c_choices.keys()))
    ns = st.selectbox("New Status", ["scheduled","pre_op","in_or","in_pacu","completed","cancelled"])
    if st.button("Update", type="primary"):
        run_query(60, (ns, c_choices[sel]), fetch=False); st.success("Updated")

def n_vitals():
    st.subheader("Patient Vitals")
    pno = st.text_input("Patient Number")
    if pno:
        rows = run_query(61, (pno,))
        if rows: st.json(rows[0])

def n_pacu():
    st.subheader("PACU Record")
    conn = get_db(); cases = conn.execute("SELECT case_id, status FROM Surgery_Case WHERE status IN ('in_or','in_pacu','completed')").fetchall(); conn.close()
    if not cases: st.info("None"); return
    c_choices = {f"Case #{c['case_id']} ({c['status']})": c['case_id'] for c in cases}
    with st.form("pacu_f"):
        cl = st.selectbox("Case", options=list(c_choices.keys()))
        at = st.datetime_input("Arrival"); dt = st.datetime_input("Discharge (optional)")
        ald = st.slider("Aldrete", 0, 10, 9); pain = st.slider("Pain", 0, 10, 2)
        comp = st.text_area("Complications")
        if st.form_submit_button("Save", type="primary"):
            run_query(62, (c_choices[cl], at, dt or None, ald, pain, comp), fetch=False); st.success("Saved")

def n_count():
    st.subheader("Surgical Count")
    conn = get_db(); cases = conn.execute("SELECT case_id, status FROM Surgery_Case WHERE status IN ('in_or','completed')").fetchall()
    docs = conn.execute("SELECT doctor_id, name FROM Doctor").fetchall(); conn.close()
    if not cases: st.info("None"); return
    c_choices = {f"Case #{c['case_id']} ({c['status']})": c['case_id'] for c in cases}
    d_choices = {d['name']: d['doctor_id'] for d in docs}
    with st.form("cnt_f"):
        cl = st.selectbox("Case", options=list(c_choices.keys()))
        ct = st.selectbox("Type", ["sponge","needle","instrument"])
        pre = st.number_input("Pre", min_value=0, step=1); post = st.number_input("Post", min_value=0, step=1)
        dl = st.selectbox("Verified by", options=list(d_choices.keys()))
        if st.form_submit_button("Save", type="primary"):
            run_query(63, (c_choices[cl], ct, pre, post, d_choices[dl]), fetch=False); st.success("Saved")

def n_rooms():
    st.subheader("Room Availability")
    rows = run_query(64, ())
    if rows: st.dataframe(pd.DataFrame(rows), use_container_width=True)
    rid = st.number_input("Room ID", min_value=1, step=1)
    nv = st.selectbox("Set Available", [1, 0])
    if st.button("Update", type="primary"):
        run_query(65, (nv, rid), fetch=False); st.success("Updated"); st.rerun()

# ── Test Query ────────────────────────────────────────────────

def test_query():
    st.subheader("Test Query")
    qs = st.session_state.queries
    options = {f"#{n} — {v['title']}": n for n, v in qs.items()}
    sel = st.selectbox("Select Query", options=list(options.keys()))
    n = options[sel]
    st.code(qs[n]["sql"], language="sql")
    with st.form("test_f"):
        params_str = st.text_input("Parameters (comma-separated)")
        if st.form_submit_button("Run", type="primary"):
            params = [p.strip() for p in params_str.split(",")] if params_str else []
            conn = get_db()
            sql = adapt_sql(qs[n]["sql"])
            try:
                cur = conn.execute(sql, params)
                if sql.strip().upper().startswith("SELECT"):
                    rows = [dict(r) for r in cur.fetchall()]
                    if rows: st.dataframe(pd.DataFrame(rows), use_container_width=True)
                    else: st.info("No rows returned")
                else:
                    conn.commit(); st.success(f"Executed. Rows affected: {cur.rowcount}")
            except Exception as e:
                st.error(str(e))
            finally:
                conn.close()

# ── Main ─────────────────────────────────────────────────────

def main():
    st.set_page_config(page_title="Surgery Department", layout="wide")
    init_database()
    if "queries" not in st.session_state:
        st.session_state.queries = load_queries()

    if "user_id" not in st.session_state:
        st.title("Surgery Department — Login")
        with st.form("login_f"):
            u = st.text_input("Username"); p = st.text_input("Password", type="password")
            if st.form_submit_button("Login", type="primary"):
                user = login_user(u, p)
                if user:
                    st.session_state.user_id = user["user_id"]
                    st.session_state.username = user["username"]
                    st.session_state.role = user["role"]
                    st.session_state.doctor_id = user.get("doctor_id")
                    st.session_state.patient_number = user.get("patient_number")
                    st.rerun()
                else:
                    st.error("Invalid credentials")
        return

    with st.sidebar:
        st.markdown(f"**{st.session_state.username}** ({st.session_state.role})")
        st.divider()
        role = st.session_state.role
        menu_map = {
            "patient": ["Profile","My Doctors","My Appointments","Book Appointment",
                        "Cancel Appointment","Make Payment","Payment History",
                        "Prescriptions","Scan Documents","Contact Inquiry","Nearest Hospital"],
            "doctor": ["Profile","My Appointments","My Patients","Patient Details",
                       "Write Prescription","Schedule Appointment","Cancel Appointment",
                       "Upload Scan","Reserve Room","My Surgery Schedule"],
            "admin": ["Dashboard","Manage Doctors","Manage Patients","Manage Departments",
                      "Manage Rooms","Manage Procedures","All Appointments",
                      "Payments","Contact Inquiries","Reports"],
            "staff": ["OR Schedule","Surgery Cases","Assign Team","Update Case Status",
                      "Patient Vitals","PACU Record","Surgical Count","Room Availability"],
        }
        items = menu_map.get(role, []) + ["Test Query"]
        selection = st.sidebar.radio("Navigation", items)
        st.divider()
        if st.button("Logout"):
            for k in ["user_id","username","role","doctor_id","patient_number"]:
                st.session_state.pop(k, None)
            st.rerun()

    pages = {
        "Profile": p_profile, "My Doctors": p_doctors, "My Appointments": p_appointments,
        "Book Appointment": p_book, "Cancel Appointment": p_cancel,
        "Make Payment": p_pay, "Payment History": p_payments,
        "Prescriptions": p_rx, "Scan Documents": p_scans,
        "Contact Inquiry": p_inquiry, "Nearest Hospital": p_nearest,
        "My Patients": d_patients, "Patient Details": d_patient_details,
        "Write Prescription": d_write_rx, "Schedule Appointment": d_schedule,
        "Upload Scan": d_upload, "Reserve Room": d_reserve, "My Surgery Schedule": d_surgery,
        "Dashboard": a_dashboard, "Manage Doctors": a_doctors, "Manage Patients": a_patients,
        "Manage Departments": a_departments, "Manage Rooms": a_rooms,
        "Manage Procedures": a_procedures, "All Appointments": a_appointments,
        "Payments": a_payments, "Contact Inquiries": a_inquiries, "Reports": a_reports,
        "OR Schedule": n_or_schedule, "Surgery Cases": n_cases, "Assign Team": n_assign,
        "Update Case Status": n_update_status, "Patient Vitals": n_vitals,
        "PACU Record": n_pacu, "Surgical Count": n_count, "Room Availability": n_rooms,
    }
    pages.get(selection, lambda: None)() if selection != "Test Query" else test_query()

if __name__ == "__main__":
    main()
