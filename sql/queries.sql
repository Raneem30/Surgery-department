-- ============================================
-- Surgery Department — Clinical Queries
-- ============================================

-- -------------------------------------------------
-- 1. Daily OR Schedule
-- Shows all surgeries scheduled for today with
-- room, surgeon, procedure, and times.
-- -------------------------------------------------
SELECT
    ss.schedule_id,
    r.room_number,
    r.or_type,
    sc.case_id,
    p.name AS patient_name,
    pr.name AS procedure_name,
    pr.standard_duration_minutes,
    ss.scheduled_start,
    ss.scheduled_end,
    ss.actual_start,
    ss.actual_end,
    d.name AS primary_surgeon
FROM Surgery_Schedule ss
JOIN Room r ON ss.or_room_id = r.room_id
JOIN Surgery_Case sc ON ss.case_id = sc.case_id
JOIN Patient p ON sc.patient_number = p.patient_number
JOIN Procedure_ pr ON sc.procedure_code = pr.procedure_code
LEFT JOIN Surgical_Team_Assignment sta
    ON sc.case_id = sta.case_id AND sta.role = 'primary_surgeon'
LEFT JOIN Doctor d ON sta.doctor_ssn = d.ssn
WHERE ss.scheduled_start::date = CURRENT_DATE
ORDER BY ss.scheduled_start;

-- -------------------------------------------------
-- 2. Surgeries by Status
-- Count of surgery cases in each phase of the
-- perioperative workflow.
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
-- Every implanted device linked to patient, surgeon,
-- serial number, and manufacturer.
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
    pr.name AS procedure_name,
    sc.created_at AS surgery_date,
    d.name AS primary_surgeon
FROM Implant_Device id
JOIN Surgery_Case sc ON id.case_id = sc.case_id
JOIN Patient p ON sc.patient_number = p.patient_number
JOIN Procedure_ pr ON sc.procedure_code = pr.procedure_code
LEFT JOIN Surgical_Team_Assignment sta
    ON sc.case_id = sta.case_id AND sta.role = 'primary_surgeon'
LEFT JOIN Doctor d ON sta.doctor_ssn = d.ssn
ORDER BY sc.created_at DESC;

-- -------------------------------------------------
-- 4. Surgical Counts Mismatch Report
-- Cases where pre-count != post-count (safety alert).
-- -------------------------------------------------
SELECT
    sc.count_id,
    sc.count_type,
    sc.pre_count,
    sc.post_count,
    (sc.pre_count - sc.post_count) AS discrepancy,
    scc.case_id,
    p.name AS patient_name,
    pr.name AS procedure_name,
    d.name AS verified_by_nurse,
    sc.verified_at
FROM Surgical_Count sc
JOIN Surgery_Case scc ON sc.case_id = scc.case_id
JOIN Patient p ON scc.patient_number = p.patient_number
JOIN Procedure_ pr ON scc.procedure_code = pr.procedure_code
JOIN Doctor d ON sc.verified_by_nurse_ssn = d.ssn
WHERE sc.pre_count != sc.post_count
ORDER BY sc.verified_at DESC;

-- -------------------------------------------------
-- 5. PACU Recovery Times
-- Average and outlier recovery times by procedure.
-- -------------------------------------------------
SELECT
    pr.name AS procedure_name,
    COUNT(*) AS case_count,
    ROUND(AVG(EXTRACT(EPOCH FROM (pacu.discharge_time - pacu.arrival_time)) / 60), 1) AS avg_recovery_minutes,
    ROUND(MAX(EXTRACT(EPOCH FROM (pacu.discharge_time - pacu.arrival_time)) / 60), 1) AS max_recovery_minutes,
    ROUND(MIN(EXTRACT(EPOCH FROM (pacu.discharge_time - pacu.arrival_time)) / 60), 1) AS min_recovery_minutes
FROM PACU_Record pacu
JOIN Surgery_Case sc ON pacu.case_id = sc.case_id
JOIN Procedure_ pr ON sc.procedure_code = pr.procedure_code
WHERE pacu.discharge_time IS NOT NULL
GROUP BY pr.name
ORDER BY avg_recovery_minutes DESC;

-- -------------------------------------------------
-- 6. Specimen Tracking
-- All specimens collected during surgery with
-- case and patient details.
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
    pr.name AS procedure_name,
    sc.created_at AS surgery_date
FROM Specimen sp
JOIN Surgery_Case sc ON sp.case_id = sc.case_id
JOIN Patient p ON sc.patient_number = p.patient_number
JOIN Procedure_ pr ON sc.procedure_code = pr.procedure_code
ORDER BY sc.created_at DESC;

-- -------------------------------------------------
-- 7. Intra-Op Complication Rates
-- Complication events (bleeding) per procedure and
-- per surgeon.
-- -------------------------------------------------
SELECT
    pr.name AS procedure_name,
    d.name AS surgeon_name,
    COUNT(DISTINCT ie.case_id) AS cases_with_complications,
    ROUND(100.0 * COUNT(DISTINCT ie.case_id) / NULLIF(
        (SELECT COUNT(*) FROM Surgery_Case sc2
         JOIN Surgical_Team_Assignment sta2 ON sc2.case_id = sta2.case_id AND sta2.role = 'primary_surgeon'
         WHERE sc2.procedure_code = pr.procedure_code AND sta2.doctor_ssn = d.ssn), 0), 1) AS complication_pct
FROM IntraOp_Event ie
JOIN Surgery_Case sc ON ie.case_id = sc.case_id
JOIN Procedure_ pr ON sc.procedure_code = pr.procedure_code
JOIN Surgical_Team_Assignment sta
    ON sc.case_id = sta.case_id AND sta.role = 'primary_surgeon'
JOIN Doctor d ON sta.doctor_ssn = d.ssn
WHERE ie.event_type = 'bleeding'
GROUP BY pr.name, d.name
ORDER BY complication_pct DESC;

-- -------------------------------------------------
-- 8. Operating Room Utilization
-- Percentage of scheduled block time actually used.
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
-- Time from case creation to actual incision.
-- -------------------------------------------------
SELECT
    sc.case_id,
    p.name AS patient_name,
    pr.name AS procedure_name,
    sc.created_at AS case_created,
    ie.event_time AS incision_time,
    ROUND(EXTRACT(EPOCH FROM (ie.event_time - sc.created_at)) / 60, 1) AS response_time_minutes
FROM Surgery_Case sc
JOIN Patient p ON sc.patient_number = p.patient_number
JOIN Procedure_ pr ON sc.procedure_code = pr.procedure_code
JOIN IntraOp_Event ie ON sc.case_id = ie.case_id AND ie.event_type = 'incision'
WHERE sc.priority IN ('emergency', 'urgent')
ORDER BY response_time_minutes;

-- -------------------------------------------------
-- 10. Surgeon Workload
-- Cases per week by role.
-- -------------------------------------------------
SELECT
    d.name AS surgeon_name,
    sta.role,
    DATE_TRUNC('week', sc.created_at) AS week_start,
    COUNT(*) AS case_count
FROM Surgical_Team_Assignment sta
JOIN Doctor d ON sta.doctor_ssn = d.ssn
JOIN Surgery_Case sc ON sta.case_id = sc.case_id
GROUP BY d.name, sta.role, DATE_TRUNC('week', sc.created_at)
ORDER BY week_start DESC, case_count DESC;

-- -------------------------------------------------
-- 11. Average Procedure Duration vs Standard
-- Actual duration compared to the scheduled
-- standard duration.
-- -------------------------------------------------
SELECT
    pr.procedure_code,
    pr.name AS procedure_name,
    pr.standard_duration_minutes,
    COUNT(*) AS case_count,
    ROUND(AVG(EXTRACT(EPOCH FROM (ss.actual_end - ss.actual_start)) / 60), 1) AS avg_actual_minutes,
    ROUND(AVG(EXTRACT(EPOCH FROM (ss.actual_end - ss.actual_start)) / 60) - pr.standard_duration_minutes, 1) AS variance_minutes
FROM Surgery_Schedule ss
JOIN Surgery_Case sc ON ss.case_id = sc.case_id
JOIN Procedure_ pr ON sc.procedure_code = pr.procedure_code
WHERE ss.actual_start IS NOT NULL AND ss.actual_end IS NOT NULL
GROUP BY pr.procedure_code, pr.name, pr.standard_duration_minutes
ORDER BY variance_minutes DESC;

-- -------------------------------------------------
-- 12. Cancelled Surgeries
-- All cancelled cases with reason.
-- -------------------------------------------------
SELECT
    sc.case_id,
    p.name AS patient_name,
    pr.name AS procedure_name,
    sc.priority,
    sc.cancel_reason,
    sc.created_at,
    ss.scheduled_start
FROM Surgery_Case sc
JOIN Patient p ON sc.patient_number = p.patient_number
JOIN Procedure_ pr ON sc.procedure_code = pr.procedure_code
LEFT JOIN Surgery_Schedule ss ON sc.case_id = ss.case_id
WHERE sc.status = 'cancelled'
ORDER BY sc.created_at DESC;

-- -------------------------------------------------
-- 13. Patients with Multiple Implants
-- Patients who received multiple devices across
-- one or more surgeries.
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
-- Shows which roles are most common for each
-- procedure type.
-- -------------------------------------------------
SELECT
    pr.name AS procedure_name,
    sta.role,
    COUNT(*) AS assignments
FROM Surgical_Team_Assignment sta
JOIN Surgery_Case sc ON sta.case_id = sc.case_id
JOIN Procedure_ pr ON sc.procedure_code = pr.procedure_code
GROUP BY pr.name, sta.role
ORDER BY pr.name, assignments DESC;

-- -------------------------------------------------
-- 15. OR Turnaround Time
-- Time between consecutive surgeries in the same OR.
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
