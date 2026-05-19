-- ============================================
-- Surgery Department — Clinical Queries
-- ============================================

-- -------------------------------------------------
-- 1. Daily OR Schedule
-- -------------------------------------------------
SELECT
    ss.schedule_id,
    r.room_number,
    r.or_type,
    sc.case_id,
    p.name AS patient_name,
    sp.name AS procedure_name,
    sp.standard_duration_minutes,
    ss.scheduled_start,
    ss.scheduled_end,
    ss.actual_start,
    ss.actual_end,
    d.name AS primary_surgeon
FROM Surgery_Schedule ss
JOIN Room r ON ss.or_room_id = r.room_id
JOIN Surgery_Case sc ON ss.case_id = sc.case_id
JOIN Patient p ON sc.patient_number = p.patient_number
JOIN Surgical_Procedure sp ON sc.procedure_code = sp.procedure_code
LEFT JOIN Surgical_Team_Assignment sta
    ON sc.case_id = sta.case_id AND sta.role = 'primary_surgeon'
LEFT JOIN Doctor d ON sta.doctor_id = d.doctor_id
WHERE ss.scheduled_start::date = CURRENT_DATE
ORDER BY ss.scheduled_start;

-- -------------------------------------------------
-- 2. Surgeries by Status
-- -------------------------------------------------
SELECT
    sc.status,
    COUNT(*) AS case_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM Surgery_Case sc
GROUP BY sc.status
ORDER BY sc.status;

-- -------------------------------------------------
-- 3. Operating Room Utilization
-- -------------------------------------------------
SELECT
    r.room_number,
    r.or_type,
    COUNT(ss.schedule_id) AS total_surgeries,
    ROUND(EXTRACT(EPOCH FROM SUM(COALESCE(ss.actual_end, CURRENT_TIMESTAMP) - COALESCE(ss.actual_start, ss.scheduled_start))) / 3600, 1) AS actual_hours,
    ROUND(EXTRACT(EPOCH FROM SUM(ss.scheduled_end - ss.scheduled_start)) / 3600, 1) AS scheduled_hours,
    CASE
        WHEN SUM(EXTRACT(EPOCH FROM ss.scheduled_end - ss.scheduled_start)) > 0
        THEN ROUND(100.0 * SUM(EXTRACT(EPOCH FROM COALESCE(ss.actual_end, CURRENT_TIMESTAMP) - COALESCE(ss.actual_start, ss.scheduled_start)))
             / SUM(EXTRACT(EPOCH FROM ss.scheduled_end - ss.scheduled_start)), 1)
        ELSE 0
    END AS utilization_pct
FROM Room r
JOIN Surgery_Schedule ss ON r.room_id = ss.or_room_id
WHERE r.room_type = 'OR'
GROUP BY r.room_number, r.or_type
ORDER BY utilization_pct DESC;

-- -------------------------------------------------
-- 4. Doctor Workload
-- -------------------------------------------------
SELECT
    d.name AS doctor_name,
    sta.role AS team_role,
    DATE_TRUNC('week', sc.created_at) AS week_start,
    COUNT(*) AS case_count
FROM Surgical_Team_Assignment sta
JOIN Doctor d ON sta.doctor_id = d.doctor_id
JOIN Surgery_Case sc ON sta.case_id = sc.case_id
GROUP BY d.name, sta.role, DATE_TRUNC('week', sc.created_at)
ORDER BY week_start DESC, case_count DESC;

-- -------------------------------------------------
-- 5. Average Procedure Duration vs Standard
-- -------------------------------------------------
SELECT
    sp.procedure_code,
    sp.name AS procedure_name,
    sp.standard_duration_minutes,
    COUNT(*) AS case_count,
    ROUND(AVG(EXTRACT(EPOCH FROM (ss.actual_end - ss.actual_start)) / 60), 1) AS avg_actual_minutes,
    ROUND(AVG(EXTRACT(EPOCH FROM (ss.actual_end - ss.actual_start)) / 60) - sp.standard_duration_minutes, 1) AS variance_minutes
FROM Surgery_Schedule ss
JOIN Surgery_Case sc ON ss.case_id = sc.case_id
JOIN Surgical_Procedure sp ON sc.procedure_code = sp.procedure_code
WHERE ss.actual_start IS NOT NULL AND ss.actual_end IS NOT NULL
GROUP BY sp.procedure_code, sp.name, sp.standard_duration_minutes
ORDER BY variance_minutes DESC;

-- -------------------------------------------------
-- 6. Cancelled Surgeries
-- -------------------------------------------------
SELECT
    sc.case_id,
    p.name AS patient_name,
    sp.name AS procedure_name,
    sc.priority,
    sc.cancel_reason,
    sc.created_at,
    ss.scheduled_start
FROM Surgery_Case sc
JOIN Patient p ON sc.patient_number = p.patient_number
JOIN Surgical_Procedure sp ON sc.procedure_code = sp.procedure_code
LEFT JOIN Surgery_Schedule ss ON sc.case_id = ss.case_id
WHERE sc.status = 'cancelled'
ORDER BY sc.created_at DESC;

-- -------------------------------------------------
-- 7. Team Role Distribution per Procedure
-- -------------------------------------------------
SELECT
    sp.name AS procedure_name,
    sta.role,
    COUNT(*) AS assignments
FROM Surgical_Team_Assignment sta
JOIN Surgery_Case sc ON sta.case_id = sc.case_id
JOIN Surgical_Procedure sp ON sc.procedure_code = sp.procedure_code
GROUP BY sp.name, sta.role
ORDER BY sp.name, assignments DESC;

-- -------------------------------------------------
-- 8. OR Turnaround Time
-- -------------------------------------------------
WITH or_schedule AS (
    SELECT
        ss.or_room_id,
        ss.schedule_id,
        ss.scheduled_start,
        ss.actual_end,
        LEAD(ss.actual_start) OVER (
            PARTITION BY ss.or_room_id
            ORDER BY ss.scheduled_start
        ) AS next_actual_start
    FROM Surgery_Schedule ss
    WHERE ss.actual_end IS NOT NULL
)
SELECT
    r.room_number,
    os.schedule_id,
    os.actual_end AS previous_case_end,
    os.next_actual_start AS next_case_start,
    ROUND(EXTRACT(EPOCH FROM (os.next_actual_start - os.actual_end)) / 60, 1) AS turnaround_minutes
FROM or_schedule os
JOIN Room r ON os.or_room_id = r.room_id
WHERE os.next_actual_start IS NOT NULL
ORDER BY turnaround_minutes DESC;

-- -------------------------------------------------
-- 9. Patient Payment History
-- -------------------------------------------------
SELECT
    p.patient_number,
    p.name AS patient_name,
    a.appointment_id,
    a.appointment_date,
    pm.payment_id,
    pm.amount,
    pm.payment_type,
    pm.payment_date,
    pm.description
FROM Payment pm
JOIN Appointment a ON pm.appointment_id = a.appointment_id
JOIN Patient p ON a.patient_number = p.patient_number
ORDER BY pm.payment_date DESC;

-- -------------------------------------------------
-- 10. Upcoming Appointments
-- -------------------------------------------------
SELECT
    a.appointment_id,
    p.name AS patient_name,
    d.name AS doctor_name,
    a.appointment_date,
    a.status,
    a.reason,
    r.room_number
FROM Appointment a
JOIN Patient p ON a.patient_number = p.patient_number
JOIN Doctor d ON a.doctor_id = d.doctor_id
LEFT JOIN Room r ON a.room_id = r.room_id
WHERE a.appointment_date >= CURRENT_TIMESTAMP
ORDER BY a.appointment_date;
