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
    s.name AS primary_surgeon
FROM Surgery_Schedule ss
JOIN Room r ON ss.or_room_id = r.room_id
JOIN Surgery_Case sc ON ss.case_id = sc.case_id
JOIN Patient p ON sc.patient_number = p.patient_number
JOIN Surgical_Procedure sp ON sc.procedure_code = sp.procedure_code
LEFT JOIN Surgical_Team_Assignment sta
    ON sc.case_id = sta.case_id AND sta.role = 'primary_surgeon'
LEFT JOIN Staff s ON sta.staff_id = s.staff_id
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
-- 3. Implant Traceability Report
-- -------------------------------------------------
SELECT
    id.implant_id,
    id.device_type,
    id.serial_number,
    id.lot_number,
    id.manufacturer,
    p.patient_number,
    p.name AS patient_name,
    sc.case_id,
    sp.name AS procedure_name,
    sc.created_at AS surgery_date,
    s.name AS primary_surgeon
FROM Implant_Device id
JOIN Surgery_Case sc ON id.case_id = sc.case_id
JOIN Patient p ON sc.patient_number = p.patient_number
JOIN Surgical_Procedure sp ON sc.procedure_code = sp.procedure_code
LEFT JOIN Surgical_Team_Assignment sta
    ON sc.case_id = sta.case_id AND sta.role = 'primary_surgeon'
LEFT JOIN Staff s ON sta.staff_id = s.staff_id
ORDER BY sc.created_at DESC;

-- -------------------------------------------------
-- 4. Surgical Counts Mismatch Report
-- -------------------------------------------------
SELECT
    sc.count_id,
    sc.count_type,
    sc.pre_count,
    sc.post_count,
    (sc.pre_count - sc.post_count) AS discrepancy,
    scc.case_id,
    p.name AS patient_name,
    sp.name AS procedure_name,
    s.name AS verified_by_staff,
    sc.verified_at
FROM Surgical_Count sc
JOIN Surgery_Case scc ON sc.case_id = scc.case_id
JOIN Patient p ON scc.patient_number = p.patient_number
JOIN Surgical_Procedure sp ON scc.procedure_code = sp.procedure_code
JOIN Staff s ON sc.verified_by_staff_id = s.staff_id
WHERE sc.pre_count != sc.post_count
ORDER BY sc.verified_at DESC;

-- -------------------------------------------------
-- 5. PACU Recovery Times
-- -------------------------------------------------
SELECT
    sp.name AS procedure_name,
    COUNT(*) AS case_count,
    ROUND(AVG(EXTRACT(EPOCH FROM (pacu.discharge_time - pacu.arrival_time)) / 60), 1) AS avg_recovery_minutes,
    ROUND(MAX(EXTRACT(EPOCH FROM (pacu.discharge_time - pacu.arrival_time)) / 60), 1) AS max_recovery_minutes,
    ROUND(MIN(EXTRACT(EPOCH FROM (pacu.discharge_time - pacu.arrival_time)) / 60), 1) AS min_recovery_minutes
FROM PACU_Record pacu
JOIN Surgery_Case sc ON pacu.case_id = sc.case_id
JOIN Surgical_Procedure sp ON sc.procedure_code = sp.procedure_code
WHERE pacu.discharge_time IS NOT NULL
GROUP BY sp.name
ORDER BY avg_recovery_minutes DESC;

-- -------------------------------------------------
-- 6. Specimen Tracking
-- -------------------------------------------------
SELECT
    sp.specimen_id,
    sp.laterality,
    sp.tissue_type,
    sp.container_type,
    sp.pathology_request_id,
    sc.case_id,
    p.name AS patient_name,
    p.patient_number,
    s_pr.name AS procedure_name,
    sc.created_at AS surgery_date
FROM Specimen sp
JOIN Surgery_Case sc ON sp.case_id = sc.case_id
JOIN Patient p ON sc.patient_number = p.patient_number
JOIN Surgical_Procedure s_pr ON sc.procedure_code = s_pr.procedure_code
ORDER BY sc.created_at DESC;

-- -------------------------------------------------
-- 7. Intra-Op Complication Rates
-- -------------------------------------------------
WITH surgeon_cases AS (
    SELECT
        sp.name AS procedure_name,
        s.name AS surgeon_name,
        s.staff_id,
        sp.procedure_code,
        COUNT(*) AS total_cases
    FROM Surgical_Team_Assignment sta
    JOIN Surgery_Case sc ON sta.case_id = sc.case_id
    JOIN Surgical_Procedure sp ON sc.procedure_code = sp.procedure_code
    JOIN Staff s ON sta.staff_id = s.staff_id
    WHERE sta.role = 'primary_surgeon'
    GROUP BY sp.name, s.name, s.staff_id, sp.procedure_code
),
complicated_cases AS (
    SELECT
        sp.name AS procedure_name,
        s.name AS surgeon_name,
        COUNT(DISTINCT ie.case_id) AS cases_with_complications
    FROM IntraOp_Event ie
    JOIN Surgery_Case sc ON ie.case_id = sc.case_id
    JOIN Surgical_Procedure sp ON sc.procedure_code = sp.procedure_code
    JOIN Surgical_Team_Assignment sta
        ON sc.case_id = sta.case_id AND sta.role = 'primary_surgeon'
    JOIN Staff s ON sta.staff_id = s.staff_id
    WHERE ie.event_type = 'bleeding'
    GROUP BY sp.name, s.name
)
SELECT
    sc.procedure_name,
    sc.surgeon_name,
    COALESCE(cc.cases_with_complications, 0) AS cases_with_complications,
    ROUND(100.0 * COALESCE(cc.cases_with_complications, 0) / sc.total_cases, 1) AS complication_pct
FROM surgeon_cases sc
LEFT JOIN complicated_cases cc
    ON sc.procedure_name = cc.procedure_name AND sc.surgeon_name = cc.surgeon_name
ORDER BY complication_pct DESC;

-- -------------------------------------------------
-- 8. Operating Room Utilization
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
-- 9. Emergency Surgery Response Time
-- -------------------------------------------------
SELECT
    sc.case_id,
    p.name AS patient_name,
    sp.name AS procedure_name,
    sc.created_at AS case_created,
    ie.event_time AS incision_time,
    ROUND(EXTRACT(EPOCH FROM (ie.event_time - sc.created_at)) / 60, 1) AS response_time_minutes
FROM Surgery_Case sc
JOIN Patient p ON sc.patient_number = p.patient_number
JOIN Surgical_Procedure sp ON sc.procedure_code = sp.procedure_code
JOIN IntraOp_Event ie ON sc.case_id = ie.case_id AND ie.event_type = 'incision'
WHERE sc.priority IN ('emergency', 'urgent')
ORDER BY response_time_minutes;

-- -------------------------------------------------
-- 10. Staff Workload (doctors and nurses)
-- -------------------------------------------------
SELECT
    s.name AS staff_name,
    s.role,
    sta.role AS team_role,
    DATE_TRUNC('week', sc.created_at) AS week_start,
    COUNT(*) AS case_count
FROM Surgical_Team_Assignment sta
JOIN Staff s ON sta.staff_id = s.staff_id
JOIN Surgery_Case sc ON sta.case_id = sc.case_id
GROUP BY s.name, s.role, sta.role, DATE_TRUNC('week', sc.created_at)
ORDER BY week_start DESC, case_count DESC;

-- -------------------------------------------------
-- 11. Average Procedure Duration vs Standard
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
-- 12. Cancelled Surgeries
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
-- 13. Patients with Multiple Implants
-- -------------------------------------------------
SELECT
    p.patient_number,
    p.name AS patient_name,
    COUNT(DISTINCT id.implant_id) AS total_implants,
    COUNT(DISTINCT sc.case_id) AS surgery_count,
    STRING_AGG(DISTINCT id.device_type, ', ') AS device_types
FROM Patient p
JOIN Surgery_Case sc ON p.patient_number = sc.patient_number
JOIN Implant_Device id ON sc.case_id = id.case_id
GROUP BY p.patient_number, p.name
HAVING COUNT(DISTINCT id.implant_id) > 1
ORDER BY total_implants DESC;

-- -------------------------------------------------
-- 14. Team Role Distribution per Procedure
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
-- 15. OR Turnaround Time
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
-- 16. Intra-Op Medication Administration Log
-- -------------------------------------------------
SELECT
    im.medication_id,
    im.drug_name,
    im.dose,
    im.route,
    im.administered_at,
    im.notes,
    sc.case_id,
    p.name AS patient_name,
    sp.name AS procedure_name,
    s.name AS given_by_staff
FROM IntraOp_Medication im
JOIN Surgery_Case sc ON im.case_id = sc.case_id
JOIN Patient p ON sc.patient_number = p.patient_number
JOIN Surgical_Procedure sp ON sc.procedure_code = sp.procedure_code
JOIN Staff s ON im.given_by_staff_id = s.staff_id
ORDER BY sc.case_id, im.administered_at;

-- -------------------------------------------------
-- 17. Surgery Audit Log
-- -------------------------------------------------
SELECT
    al.log_id,
    al.table_name,
    al.record_id,
    al.action,
    s.name AS changed_by_staff,
    s.role AS staff_role,
    al.changed_at,
    al.old_data,
    al.new_data
FROM Surgery_Audit_Log al
JOIN Staff s ON al.changed_by_staff_id = s.staff_id
ORDER BY al.changed_at DESC
LIMIT 100;
