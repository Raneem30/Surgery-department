import streamlit as st
import psycopg2
import pandas as pd
from datetime import date, datetime, timedelta
import os
import re

# ── Paths ────────────────────────────────────────────────────
QUERIES_PATH = os.path.join(os.path.dirname(__file__), "sql", "queries.sql")


# ── Load queries from queries.sql ────────────────────────────
@st.cache_data
def load_queries():
    with open(QUERIES_PATH) as f:
        text = f.read()
    queries = {}
    chunks = re.split(r"\n-- -{40,}\n", text)
    for i in range(1, len(chunks), 2):
        if i + 1 >= len(chunks):
            break
        name = chunks[i].strip().lstrip("-- ").strip()
        sql = chunks[i + 1].strip().rstrip(";").strip()
        if name and sql:
            queries[name] = sql
    return queries


# ── Page config ──────────────────────────────────────────────
st.set_page_config(
    page_title="Surgery Department",
    page_icon="🏥",
    layout="wide",
    initial_sidebar_state="expanded",
)

# ── DB connection ────────────────────────────────────────────
DB_CONFIG = {
    "host":     os.getenv("DB_HOST", "localhost"),
    "port":     int(os.getenv("DB_PORT", "5432")),
    "dbname":   os.getenv("DB_NAME", "surgery_department"),
    "user":     os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "postgres"),
}


def get_conn():
    return psycopg2.connect(**DB_CONFIG)


def query(sql, params=None):
    conn = get_conn()
    try:
        return pd.read_sql(sql, conn, params=params)
    finally:
        conn.close()


def execute(sql, params=None):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            conn.commit()
    finally:
        conn.close()


# ── Sidebar navigation ──────────────────────────────────────
PAGES = [
    "📊  Dashboard",
    "👤  Patients",
    "🩺  Doctors",
    "📅  Appointments",
    "🏥  Surgery Cases",
    "⏱  OR Schedule",
    "💰  Payments",
    "📋  Reports",
]

st.sidebar.title("🏥 Surgery Dept")
st.sidebar.caption("PostgreSQL · Streamlit")
page = st.sidebar.radio("Navigate", PAGES)

st.sidebar.markdown("---")
st.sidebar.subheader("Quick Stats")
try:
    stats = query(
        "SELECT (SELECT COUNT(*) FROM Patient) AS patients,"
        " (SELECT COUNT(*) FROM Doctor) AS doctors,"
        " (SELECT COUNT(*) FROM Surgery_Case) AS cases,"
        " (SELECT COUNT(*) FROM Appointment) AS appointments"
    )
    if not stats.empty:
        r = stats.iloc[0]
        col1, col2 = st.sidebar.columns(2)
        col1.metric("Patients", r["patients"])
        col2.metric("Doctors", r["doctors"])
        col1.metric("Surgeries", r["cases"])
        col2.metric("Appts", r["appointments"])
except Exception:
    st.sidebar.error("DB not reachable")

st.sidebar.markdown("---")
st.sidebar.caption("Phase 1 · DB Project")


# ── Helpers ──────────────────────────────────────────────────
def show_table(df, title=None):
    if df.empty:
        st.info("No data.")
        return
    if title:
        st.caption(f"{len(df)} row(s)")
    st.dataframe(df, use_container_width=True, hide_index=True)


def pick_patient(label="Patient"):
    df = query("SELECT patient_number, name FROM Patient ORDER BY name")
    if df.empty:
        st.warning("No patients found.")
        return None
    opts = df["patient_number"].tolist()
    fmt = {r["patient_number"]: f"{r['patient_number']} — {r['name']}" for _, r in df.iterrows()}
    chosen = st.selectbox(label, opts, format_func=lambda x: fmt.get(x, x))
    return chosen


def pick_doctor(label="Doctor"):
    df = query("SELECT doctor_id, name FROM Doctor ORDER BY name")
    if df.empty:
        st.warning("No doctors found.")
        return None
    opts = df["doctor_id"].tolist()
    fmt = {r["doctor_id"]: f"{r['doctor_id']} — {r['name']}" for _, r in df.iterrows()}
    chosen = st.selectbox(label, opts, format_func=lambda x: fmt.get(x, x))
    return chosen


def pick_room(label="Room"):
    df = query("SELECT room_id, room_number, room_type FROM Room ORDER BY room_number")
    if df.empty:
        st.warning("No rooms found.")
        return None
    opts = df["room_id"].tolist()
    fmt = {r["room_id"]: f"{r['room_id']} — {r['room_number']} ({r['room_type']})" for _, r in df.iterrows()}
    chosen = st.selectbox(label, opts, format_func=lambda x: fmt.get(x, x))
    return chosen


def pick_procedure(label="Procedure"):
    df = query("SELECT procedure_code, name FROM Surgical_Procedure ORDER BY name")
    if df.empty:
        st.warning("No procedures found.")
        return None
    opts = df["procedure_code"].tolist()
    fmt = {r["procedure_code"]: f"{r['procedure_code']} — {r['name']}" for _, r in df.iterrows()}
    chosen = st.selectbox(label, opts, format_func=lambda x: fmt.get(x, x))
    return chosen


# ==============================================================
#  📊  DASHBOARD
# ==============================================================
if page == PAGES[0]:
    st.title("📊 Dashboard")
    st.markdown("Overview of the Surgery Department database.")

    k1, k2, k3, k4, k5 = st.columns(5)
    try:
        d = query(
            "SELECT"
            " (SELECT COUNT(*) FROM Patient) AS patients,"
            " (SELECT COUNT(*) FROM Doctor) AS doctors,"
            " (SELECT COUNT(*) FROM Surgery_Case) AS surgery_cases,"
            " (SELECT COUNT(*) FROM Appointment) AS appointments,"
            " (SELECT COUNT(*) FROM Payment) AS payments"
        ).iloc[0]
        k1.metric("🧑‍⚕️ Patients", d["patients"])
        k2.metric("🩺 Doctors", d["doctors"])
        k3.metric("🏥 Surgeries", d["surgery_cases"])
        k4.metric("📅 Appointments", d["appointments"])
        k5.metric("💰 Payments", d["payments"])
    except Exception as e:
        st.error(f"Could not reach database: {e}")

    st.divider()
    col_left, col_right = st.columns(2)
    with col_left:
        st.subheader("Surgeries by Status")
        try:
            df = query(
                "SELECT sc.status, COUNT(*) AS case_count,"
                " ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct"
                " FROM Surgery_Case sc GROUP BY sc.status ORDER BY sc.status"
            )
            if not df.empty:
                st.dataframe(df, use_container_width=True, hide_index=True)
        except Exception as e:
            st.error(str(e))
    with col_right:
        st.subheader("Upcoming Appointments")
        try:
            df = query(
                "SELECT a.appointment_id, p.name AS patient,"
                " d.name AS doctor, a.appointment_date, a.status"
                " FROM Appointment a"
                " JOIN Patient p ON a.patient_number = p.patient_number"
                " JOIN Doctor d ON a.doctor_id = d.doctor_id"
                " WHERE a.appointment_date >= CURRENT_TIMESTAMP"
                " ORDER BY a.appointment_date LIMIT 10"
            )
            show_table(df)
        except Exception as e:
            st.error(str(e))

    st.divider()
    st.subheader("Today's OR Schedule")
    try:
        df = query(
            "SELECT r.room_number, r.or_type, p.name AS patient,"
            " sp.name AS procedure, ss.scheduled_start, ss.scheduled_end,"
            " ss.actual_start, ss.actual_end"
            " FROM Surgery_Schedule ss"
            " JOIN Room r ON ss.or_room_id = r.room_id"
            " JOIN Surgery_Case sc ON ss.case_id = sc.case_id"
            " JOIN Patient p ON sc.patient_number = p.patient_number"
            " JOIN Surgical_Procedure sp ON sc.procedure_code = sp.procedure_code"
            " WHERE ss.scheduled_start::date = CURRENT_DATE"
            " ORDER BY ss.scheduled_start"
        )
        show_table(df)
    except Exception as e:
        st.error(str(e))


# ==============================================================
#  👤  PATIENTS
# ==============================================================
elif page == PAGES[1]:
    st.title("👤 Patients")

    tab_list, tab_add, tab_delete, tab_detail = st.tabs(["All Patients", "➕ Add Patient", "🗑️ Delete", "Patient Detail"])

    with tab_list:
        try:
            df = query(
                "SELECT patient_number, ssn, name, phone, birthdate, sex,"
                " admission_date, blood_pressure, heart_rate,"
                " temperature, spo2, recorded_at"
                " FROM Patient ORDER BY name"
            )
            show_table(df)
        except Exception as e:
            st.error(str(e))

    with tab_add:
        with st.form("add_patient"):
            c1, c2 = st.columns(2)
            with c1:
                pid = st.text_input("Patient Number *")
                name = st.text_input("Full Name *")
                ssn = st.text_input("SSN *")
                phone = st.text_input("Phone")
                address = st.text_input("Address")
            with c2:
                sex = st.selectbox("Sex", ["M", "F"])
                birthdate = st.date_input("Birthdate *")
                adm_date = st.date_input("Admission Date *", value=date.today())
                bp = st.text_input("Blood Pressure (e.g. 120/80)")
                hr = st.number_input("Heart Rate", min_value=1, step=1)

            c3, c4 = st.columns(2)
            with c3:
                temp = st.number_input("Temperature (°C)", format="%.1f")
            with c4:
                spo2 = st.number_input("SpO₂ (%)", min_value=0, max_value=100, step=1)
            c5, c6 = st.columns(2)
            with c5:
                rec_date = st.date_input("Vitals Date", value=date.today())
            with c6:
                rec_time = st.time_input("Vitals Time", value=datetime.now().time())
            medhist = st.text_area("Medical History")

            if st.form_submit_button("💾 Save Patient", type="primary"):
                if not pid or not name or not ssn:
                    st.error("Patient Number, Name, and SSN are required.")
                else:
                    try:
                        recorded_at = datetime.combine(rec_date, rec_time).strftime("%Y-%m-%d %H:%M:%S")
                        execute(
                            "INSERT INTO Patient (patient_number, ssn, name, address, phone, birthdate, sex,"
                            " medical_history, admission_date, blood_pressure, heart_rate, temperature, spo2, recorded_at)"
                            " VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)",
                            (pid, ssn, name, address or None, phone or None, birthdate, sex,
                             medhist or None, adm_date, bp or None, hr or None,
                             temp if temp else None, spo2 if spo2 else None,
                             recorded_at),
                        )
                        st.success(f"Patient {pid} added!")
                        st.rerun()
                    except Exception as e:
                        st.error(str(e))

    with tab_detail:
        chosen = pick_patient()
        if chosen:
            c1, c2 = st.columns(2)
            with c1:
                st.subheader("Info & Vitals")
                df = query("SELECT * FROM Patient WHERE patient_number = %s", params=(chosen,))
                if not df.empty:
                    st.dataframe(df.T.rename(columns={0: "Value"}), use_container_width=True)
            with c2:
                st.subheader("Surgery History")
                df = query(
                    "SELECT sc.case_id, sp.name AS procedure, sc.status,"
                    " sc.priority, sc.created_at"
                    " FROM Surgery_Case sc"
                    " JOIN Surgical_Procedure sp ON sc.procedure_code = sp.procedure_code"
                    " WHERE sc.patient_number = %s ORDER BY sc.created_at DESC",
                    params=(chosen,),
                )
                show_table(df)
                st.subheader("Appointments")
                df = query(
                    "SELECT a.appointment_id, d.name AS doctor,"
                    " a.appointment_date, a.status, a.reason"
                    " FROM Appointment a JOIN Doctor d ON a.doctor_id = d.doctor_id"
                    " WHERE a.patient_number = %s ORDER BY a.appointment_date DESC",
                    params=(chosen,),
                )
                show_table(df)

    with tab_delete:
        df = query("SELECT patient_number, name FROM Patient ORDER BY name")
        if not df.empty:
            pid_to_del = st.selectbox("Select Patient to Delete", df["patient_number"].tolist(),
                                      format_func=lambda x: df[df.patient_number == x].iloc[0]["name"])
            if st.button("🗑️ Delete Patient", type="primary"):
                if st.checkbox("Confirm permanent deletion? This may fail if related records exist."):
                    try:
                        execute("DELETE FROM Patient WHERE patient_number = %s", (pid_to_del,))
                        st.success(f"Patient {pid_to_del} deleted!")
                        st.rerun()
                    except Exception as e:
                        st.error(f"Cannot delete: {e}")
        else:
            st.info("No patients found.")


# ==============================================================
#  🩺  DOCTORS
# ==============================================================
elif page == PAGES[2]:
    st.title("🩺 Doctors")

    tab_view, tab_add, tab_delete = st.tabs(["All Doctors", "➕ Add Doctor", "🗑️ Delete Doctor"])

    with tab_view:
        try:
            df = query(
                "SELECT d.doctor_id, d.name, d.major_area, d.degree,"
                " d.department_code, dep.name AS department, d.email, d.phone"
                " FROM Doctor d"
                " JOIN Department dep ON d.department_code = dep.department_code"
                " ORDER BY d.name"
            )
            show_table(df)
        except Exception as e:
            st.error(str(e))

        st.divider()
        st.subheader("Weekly Workload")
        df = query(
            "SELECT d.name AS doctor_name, sta.role AS team_role,"
            " DATE_TRUNC('week', sc.created_at)::date AS week_start,"
            " COUNT(*) AS case_count"
            " FROM Surgical_Team_Assignment sta"
            " JOIN Doctor d ON sta.doctor_id = d.doctor_id"
            " JOIN Surgery_Case sc ON sta.case_id = sc.case_id"
            " GROUP BY d.name, sta.role, DATE_TRUNC('week', sc.created_at)"
            " ORDER BY week_start DESC, case_count DESC"
        )
        show_table(df)

    with tab_add:
        depts = query("SELECT department_code, name FROM Department ORDER BY name")
        with st.form("add_doctor"):
            c1, c2 = st.columns(2)
            with c1:
                dname = st.text_input("Full Name *")
                ssn = st.text_input("SSN *")
                sex = st.selectbox("Sex", ["M", "F"])
                birth = st.date_input("Birth Date")
            with c2:
                major = st.text_input("Major Area *")
                degree = st.text_input("Degree *")
                dept = st.selectbox(
                    "Department *",
                    options=depts["department_code"].tolist(),
                    format_func=lambda x: f"{x} — {depts[depts.department_code==x].iloc[0]['name']}",
                )
                email = st.text_input("Email")
                phone = st.text_input("Phone")
            join_date = st.date_input("Join Date", value=date.today())

            if st.form_submit_button("💾 Save Doctor", type="primary"):
                if not dname or not ssn or not major or not degree:
                    st.error("Name, SSN, Major Area, and Degree are required.")
                else:
                    try:
                        execute(
                            "INSERT INTO Doctor (ssn, name, sex, birth_date, major_area, degree,"
                            " department_code, join_date, email, phone)"
                            " VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)",
                            (ssn, dname, sex, birth or None, major, degree, dept,
                             join_date or None, email or None, phone or None),
                        )
                        st.success(f"Doctor {dname} added!")
                        st.rerun()
                    except Exception as e:
                        st.error(str(e))

    with tab_delete:
        docs = query("SELECT doctor_id, name FROM Doctor ORDER BY name")
        if not docs.empty:
            doc_id = st.selectbox(
                "Select Doctor to Delete",
                options=docs["doctor_id"].tolist(),
                format_func=lambda x: docs[docs.doctor_id == x].iloc[0]["name"],
            )
            if st.button("🗑️ Delete Doctor", type="primary"):
                if st.checkbox("Confirm permanent deletion?"):
                    try:
                        execute("DELETE FROM Doctor WHERE doctor_id = %s", (doc_id,))
                        st.success("Doctor deleted!")
                        st.rerun()
                    except Exception as e:
                        st.error(f"Cannot delete: {e}")
        else:
            st.info("No doctors found.")


# ==============================================================
#  📅  APPOINTMENTS
# ==============================================================
elif page == PAGES[3]:
    st.title("📅 Appointments")

    tab_view, tab_schedule, tab_cancel, tab_delete = st.tabs(["View", "📅 Schedule Appointment", "❌ Cancel", "🗑️ Delete"])

    with tab_view:
        status_filter = st.selectbox("Filter by status", ["All", "scheduled", "completed", "cancelled"])
        where = "" if status_filter == "All" else "WHERE a.status = %s"
        params = None if status_filter == "All" else (status_filter,)
        try:
            df = query(
                "SELECT a.appointment_id, p.name AS patient,"
                " d.name AS doctor, a.appointment_date, a.status, a.reason, r.room_number"
                " FROM Appointment a"
                " JOIN Patient p ON a.patient_number = p.patient_number"
                " JOIN Doctor d ON a.doctor_id = d.doctor_id"
                " LEFT JOIN Room r ON a.room_id = r.room_id"
                f" {where} ORDER BY a.appointment_date DESC LIMIT 100",
                params=params,
            )
            show_table(df)
        except Exception as e:
            st.error(str(e))

    with tab_schedule:
        with st.form("add_appointment"):
            pat = pick_patient()
            doc = pick_doctor()
            room = pick_room()
            c1, c2 = st.columns(2)
            with c1:
                apt_date = st.date_input("Date *")
                apt_time = st.time_input("Time *")
            with c2:
                reason = st.text_input("Reason")
            case_ids = query("SELECT case_id FROM Surgery_Case ORDER BY case_id")
            case_opts = [None] + case_ids["case_id"].tolist()
            case = st.selectbox("Link to Surgery Case (optional)", case_opts,
                                format_func=lambda x: f"Case #{x}" if x else "None")

            if st.form_submit_button("💾 Schedule", type="primary"):
                dt = datetime.combine(apt_date, apt_time).strftime("%Y-%m-%d %H:%M:%S")
                if not pat or not doc:
                    st.error("Patient and Doctor are required.")
                else:
                    try:
                        execute(
                            "INSERT INTO Appointment (patient_number, doctor_id, room_id,"
                            " appointment_date, status, reason, case_id)"
                            " VALUES (%s,%s,%s,%s,'scheduled',%s,%s)",
                            (pat, doc, room, dt, reason or None, case),
                        )
                        st.success("Appointment scheduled!")
                        st.rerun()
                    except Exception as e:
                        st.error(str(e))

    with tab_cancel:
        appts = query(
            "SELECT a.appointment_id, p.name AS patient, d.name AS doctor,"
            " a.appointment_date FROM Appointment a"
            " JOIN Patient p ON a.patient_number = p.patient_number"
            " JOIN Doctor d ON a.doctor_id = d.doctor_id"
            " WHERE a.status = 'scheduled' ORDER BY a.appointment_date"
        )
        if appts.empty:
            st.info("No scheduled appointments to cancel.")
        else:
            opts = appts["appointment_id"].tolist()
            fmt = {r["appointment_id"]: f"#{r['appointment_id']} — {r['patient']} with {r['doctor']} on {r['appointment_date']}"
                   for _, r in appts.iterrows()}
            chosen = st.selectbox("Appointment to cancel", opts, format_func=lambda x: fmt.get(x, x))
            cancel_reason = st.text_input("Cancellation reason")
            if st.button("❌ Confirm Cancellation", type="primary"):
                try:
                    execute("UPDATE Appointment SET status='cancelled', reason=%s WHERE appointment_id=%s",
                            (cancel_reason or None, chosen))
                    st.success(f"Appointment #{chosen} cancelled.")
                    st.rerun()
                except Exception as e:
                    st.error(str(e))

    with tab_delete:
        appts = query(
            "SELECT a.appointment_id, p.name AS patient, d.name AS doctor,"
            " a.appointment_date, a.status FROM Appointment a"
            " JOIN Patient p ON a.patient_number = p.patient_number"
            " JOIN Doctor d ON a.doctor_id = d.doctor_id"
            " ORDER BY a.appointment_date DESC LIMIT 100"
        )
        if not appts.empty:
            opts = appts["appointment_id"].tolist()
            fmt = {r["appointment_id"]: f"#{r['appointment_id']} — {r['patient']} with {r['doctor']} ({r['status']})"
                   for _, r in appts.iterrows()}
            chosen = st.selectbox("Appointment to delete", opts, format_func=lambda x: fmt.get(x, x))
            if st.button("🗑️ Delete Appointment", type="primary"):
                if st.checkbox("Confirm permanent deletion?"):
                    try:
                        execute("DELETE FROM Appointment WHERE appointment_id = %s", (chosen,))
                        st.success(f"Appointment #{chosen} deleted!")
                        st.rerun()
                    except Exception as e:
                        st.error(f"Cannot delete: {e}")
        else:
            st.info("No appointments found.")


# ==============================================================
#  🏥  SURGERY CASES
# ==============================================================
elif page == PAGES[4]:
    st.title("🏥 Surgery Cases")

    tab_view, tab_add, tab_update, tab_delete = st.tabs(["View", "➕ New Case", "✏️ Update Status", "🗑️ Delete"])

    with tab_view:
        status_f = st.selectbox(
            "Status", ["All", "scheduled", "pre_op", "in_or", "in_pacu", "completed", "cancelled"],
            key="sc_status",
        )
        where = "" if status_f == "All" else "WHERE sc.status = %s"
        params = None if status_f == "All" else (status_f,)
        try:
            df = query(
                "SELECT sc.case_id, p.name AS patient, sp.name AS procedure,"
                " sc.priority, sc.status, sc.created_at, sc.cancel_reason"
                " FROM Surgery_Case sc"
                " JOIN Patient p ON sc.patient_number = p.patient_number"
                " JOIN Surgical_Procedure sp ON sc.procedure_code = sp.procedure_code"
                f" {where} ORDER BY sc.created_at DESC LIMIT 100",
                params=params,
            )
            show_table(df)
        except Exception as e:
            st.error(str(e))

    with tab_add:
        with st.form("add_case"):
            pat = pick_patient()
            proc = pick_procedure()
            prio = st.selectbox("Priority", ["elective", "emergency", "urgent"])
            if st.form_submit_button("💾 Create Case", type="primary"):
                if not pat or not proc:
                    st.error("Patient and Procedure are required.")
                else:
                    try:
                        execute(
                            "INSERT INTO Surgery_Case (patient_number, procedure_code, priority, status)"
                            " VALUES (%s,%s,%s,'scheduled')",
                            (pat, proc, prio),
                        )
                        st.success("Surgery case created!")
                        st.rerun()
                    except Exception as e:
                        st.error(str(e))

    with tab_update:
        cases = query(
            "SELECT sc.case_id, p.name AS patient, sp.name AS procedure, sc.status"
            " FROM Surgery_Case sc"
            " JOIN Patient p ON sc.patient_number = p.patient_number"
            " JOIN Surgical_Procedure sp ON sc.procedure_code = sp.procedure_code"
            " WHERE sc.status NOT IN ('completed','cancelled')"
            " ORDER BY sc.case_id"
        )
        if cases.empty:
            st.info("No active cases to update.")
        else:
            opts = cases["case_id"].tolist()
            fmt = {r["case_id"]: f"#{r['case_id']} — {r['patient']} — {r['procedure']} ({r['status']})"
                   for _, r in cases.iterrows()}
            chosen = st.selectbox("Case", opts, format_func=lambda x: fmt.get(x, x))
            new_status = st.selectbox(
                "New status",
                ["scheduled", "pre_op", "in_or", "in_pacu", "completed"],
            )
            cancel_reason = st.text_input("Cancel reason (if cancelling)")
            if st.button("✏️ Update", type="primary"):
                try:
                    if new_status == "cancelled":
                        execute("UPDATE Surgery_Case SET status=%s, cancel_reason=%s WHERE case_id=%s",
                                (new_status, cancel_reason or None, chosen))
                    else:
                        execute("UPDATE Surgery_Case SET status=%s WHERE case_id=%s",
                                (new_status, chosen))
                    st.success(f"Case #{chosen} updated to {new_status}.")
                    st.rerun()
                except Exception as e:
                    st.error(str(e))

    with tab_delete:
        cases = query(
            "SELECT sc.case_id, p.name AS patient, sp.name AS procedure, sc.status"
            " FROM Surgery_Case sc"
            " JOIN Patient p ON sc.patient_number = p.patient_number"
            " JOIN Surgical_Procedure sp ON sc.procedure_code = sp.procedure_code"
            " ORDER BY sc.case_id DESC LIMIT 100"
        )
        if not cases.empty:
            opts = cases["case_id"].tolist()
            fmt = {r["case_id"]: f"#{r['case_id']} — {r['patient']} — {r['procedure']} ({r['status']})"
                   for _, r in cases.iterrows()}
            chosen = st.selectbox("Case to delete", opts, format_func=lambda x: fmt.get(x, x))
            if st.button("🗑️ Delete Case", type="primary"):
                if st.checkbox("Confirm permanent deletion? This may fail if related records exist."):
                    try:
                        execute("DELETE FROM Surgery_Case WHERE case_id = %s", (chosen,))
                        st.success(f"Case #{chosen} deleted!")
                        st.rerun()
                    except Exception as e:
                        st.error(f"Cannot delete: {e}")
        else:
            st.info("No cases found.")


# ==============================================================
#  ⏱  OR SCHEDULE
# ==============================================================
elif page == PAGES[5]:
    st.title("⏱ OR Schedule")

    tab_view, tab_schedule = st.tabs(["View Schedule", "➕ Schedule Surgery"])

    with tab_view:
        date_pick = st.date_input("Date", value=date.today())
        try:
            df = query(
                "SELECT ss.schedule_id, r.room_number, r.or_type,"
                " p.name AS patient, sp.name AS procedure,"
                " ss.scheduled_start, ss.scheduled_end,"
                " ss.actual_start, ss.actual_end, d.name AS primary_surgeon"
                " FROM Surgery_Schedule ss"
                " JOIN Room r ON ss.or_room_id = r.room_id"
                " JOIN Surgery_Case sc ON ss.case_id = sc.case_id"
                " JOIN Patient p ON sc.patient_number = p.patient_number"
                " JOIN Surgical_Procedure sp ON sc.procedure_code = sp.procedure_code"
                " LEFT JOIN Surgical_Team_Assignment sta"
                "   ON sc.case_id = sta.case_id AND sta.role = 'primary_surgeon'"
                " LEFT JOIN Doctor d ON sta.doctor_id = d.doctor_id"
                " WHERE ss.scheduled_start::date = %s ORDER BY ss.scheduled_start",
                params=(date_pick,),
            )
            show_table(df)
        except Exception as e:
            st.error(str(e))

    with tab_schedule:
        cases = query(
            "SELECT sc.case_id, p.name AS patient, sp.name AS procedure"
            " FROM Surgery_Case sc"
            " JOIN Patient p ON sc.patient_number = p.patient_number"
            " JOIN Surgical_Procedure sp ON sc.procedure_code = sp.procedure_code"
            " WHERE sc.case_id NOT IN (SELECT case_id FROM Surgery_Schedule)"
            " ORDER BY sc.case_id"
        )
        if cases.empty:
            st.info("All cases are already scheduled.")
        else:
            with st.form("add_schedule"):
                opts = cases["case_id"].tolist()
                fmt = {r["case_id"]: f"#{r['case_id']} — {r['patient']} — {r['procedure']}"
                       for _, r in cases.iterrows()}
                chosen_case = st.selectbox("Surgery Case", opts, format_func=lambda x: fmt.get(x, x))
                room = pick_room()
                c1, c2 = st.columns(2)
                with c1:
                    start_date = st.date_input("Start Date *")
                    start_time = st.time_input("Start Time *")
                with c2:
                    end_date = st.date_input("End Date *")
                    end_time = st.time_input("End Time *")
                if st.form_submit_button("💾 Schedule", type="primary"):
                    s_start = datetime.combine(start_date, start_time).strftime("%Y-%m-%d %H:%M:%S")
                    s_end = datetime.combine(end_date, end_time).strftime("%Y-%m-%d %H:%M:%S")
                    try:
                        execute(
                            "INSERT INTO Surgery_Schedule (case_id, or_room_id, scheduled_start, scheduled_end)"
                            " VALUES (%s,%s,%s,%s)",
                            (chosen_case, room, s_start, s_end),
                        )
                        st.success("Surgery scheduled!")
                        st.rerun()
                    except Exception as e:
                        st.error(str(e))


# ==============================================================
#  💰  PAYMENTS
# ==============================================================
elif page == PAGES[6]:
    st.title("💰 Payments")

    tab_view, tab_add, tab_delete = st.tabs(["All Payments", "➕ Register Payment", "🗑️ Delete"])

    with tab_view:
        try:
            df = query(
                "SELECT pm.payment_id, p.patient_number, p.name AS patient,"
                " a.appointment_id, a.appointment_date,"
                " pm.amount, pm.payment_type, pm.payment_date, pm.description"
                " FROM Payment pm"
                " JOIN Appointment a ON pm.appointment_id = a.appointment_id"
                " JOIN Patient p ON a.patient_number = p.patient_number"
                " ORDER BY pm.payment_date DESC LIMIT 100"
            )
            show_table(df)
        except Exception as e:
            st.error(str(e))

    with tab_add:
        appts = query(
            "SELECT a.appointment_id, p.name AS patient, a.appointment_date"
            " FROM Appointment a"
            " JOIN Patient p ON a.patient_number = p.patient_number"
            " WHERE a.appointment_id NOT IN (SELECT appointment_id FROM Payment)"
            " ORDER BY a.appointment_date"
        )
        if appts.empty:
            st.info("All appointments already have payments.")
        else:
            with st.form("add_payment"):
                opts = appts["appointment_id"].tolist()
                fmt = {r["appointment_id"]: f"#{r['appointment_id']} — {r['patient']} on {r['appointment_date']}"
                       for _, r in appts.iterrows()}
                apt = st.selectbox("Appointment", opts, format_func=lambda x: fmt.get(x, x))
                c1, c2 = st.columns(2)
                with c1:
                    amt = st.number_input("Amount (EGP)", min_value=0.0, format="%.2f")
                    ptype = st.selectbox("Type", ["register", "pay", "refund"])
                with c2:
                    pay_date = st.date_input("Payment Date", value=date.today())
                    pay_time = st.time_input("Payment Time", value=datetime.now().time())
                    desc = st.text_input("Description")
                if st.form_submit_button("💾 Register Payment", type="primary"):
                    try:
                        pdate = datetime.combine(pay_date, pay_time).strftime("%Y-%m-%d %H:%M:%S")
                        execute(
                            "INSERT INTO Payment (appointment_id, amount, payment_date, payment_type, description)"
                            " VALUES (%s,%s,%s,%s,%s)",
                            (apt, amt, pdate, ptype, desc or None),
                        )
                        st.success("Payment registered!")
                        st.rerun()
                    except Exception as e:
                        st.error(str(e))

    with tab_delete:
        payments = query(
            "SELECT pm.payment_id, p.name AS patient,"
            " a.appointment_id, pm.amount, pm.payment_type, pm.payment_date"
            " FROM Payment pm"
            " JOIN Appointment a ON pm.appointment_id = a.appointment_id"
            " JOIN Patient p ON a.patient_number = p.patient_number"
            " ORDER BY pm.payment_date DESC LIMIT 100"
        )
        if not payments.empty:
            opts = payments["payment_id"].tolist()
            fmt = {r["payment_id"]: f"#{r['payment_id']} — {r['patient']} (Appt #{r['appointment_id']}) — {r['payment_type']} {r['amount']}EGP"
                   for _, r in payments.iterrows()}
            chosen = st.selectbox("Payment to delete", opts, format_func=lambda x: fmt.get(x, x))
            if st.button("🗑️ Delete Payment", type="primary"):
                if st.checkbox("Confirm permanent deletion?"):
                    try:
                        execute("DELETE FROM Payment WHERE payment_id = %s", (chosen,))
                        st.success(f"Payment #{chosen} deleted!")
                        st.rerun()
                    except Exception as e:
                        st.error(f"Cannot delete: {e}")
        else:
            st.info("No payments found.")


# ==============================================================
#  📋  REPORTS (from sql/queries.sql)
# ==============================================================
elif page == PAGES[7]:
    st.title("📋 Reports")
    st.markdown("Run the pre-built analytical queries from `sql/queries.sql`.")

    try:
        REPORTS = load_queries()
    except FileNotFoundError:
        st.error(f"`{QUERIES_PATH}` not found.")
        st.stop()
    except Exception as e:
        st.error(f"Failed to parse queries: {e}")
        st.stop()

    report_name = st.selectbox("Choose a report", list(REPORTS.keys()))
    if report_name:
        sql = REPORTS[report_name]
        st.code(sql, language="sql")
        if st.button("▶ Run Report", type="primary"):
            with st.spinner("Running query..."):
                try:
                    df = query(sql)
                    show_table(df, title=report_name)
                except Exception as e:
                    st.error(str(e))


