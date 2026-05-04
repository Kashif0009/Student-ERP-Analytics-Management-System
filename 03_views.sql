-- ============================================================
--  Student ERP Analytics & Management System
--  VIEWS  |  Reusable Analytical Dashboards
-- ============================================================
USE student_erp;

-- ── 1. TOPPER STUDENTS (CGPA > 8.5) ──────────────────────────────────────────
CREATE OR REPLACE VIEW vw_topper_students AS
SELECT
    s.student_id,
    s.roll_number,
    s.student_name,
    d.dept_name,
    d.dept_code,
    s.batch_year,
    s.cgpa,
    s.semester,
    s.city
FROM students s
JOIN departments d ON s.dept_id = d.dept_id
WHERE s.cgpa > 8.5 AND s.status = 'Active'
ORDER BY s.cgpa DESC;

-- ── 2. LOW ATTENDANCE ALERT (below 75 %) ─────────────────────────────────────
CREATE OR REPLACE VIEW vw_low_attendance_alert AS
SELECT
    s.student_id,
    s.roll_number,
    s.student_name,
    s.phone,
    d.dept_name,
    s.semester,
    a.total_classes,
    a.classes_attended,
    a.attendance_percent,
    CASE
        WHEN a.attendance_percent < 60 THEN 'CRITICAL'
        WHEN a.attendance_percent < 75 THEN 'WARNING'
        ELSE 'OK'
    END AS alert_level
FROM students s
JOIN departments d ON s.dept_id = d.dept_id
JOIN attendance_summary a ON s.student_id = a.student_id
WHERE a.attendance_percent < 75 AND s.status = 'Active'
ORDER BY a.attendance_percent ASC;

-- ── 3. PENDING FEE REPORT ─────────────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_pending_fees AS
SELECT
    s.student_id,
    s.roll_number,
    s.student_name,
    s.phone,
    d.dept_name,
    f.fee_type,
    f.academic_year,
    f.amount_due,
    f.amount_paid,
    ROUND(f.amount_due - f.amount_paid, 2) AS amount_pending,
    f.due_date,
    f.status,
    DATEDIFF(CURDATE(), f.due_date) AS days_overdue
FROM fees f
JOIN students s ON f.student_id = s.student_id
JOIN departments d ON s.dept_id = d.dept_id
WHERE f.status IN ('Pending','Partial','Overdue')
ORDER BY amount_pending DESC;

-- ── 4. DEPARTMENT PERFORMANCE DASHBOARD ──────────────────────────────────────
CREATE OR REPLACE VIEW vw_dept_performance AS
SELECT
    d.dept_id,
    d.dept_name,
    d.dept_code,
    COUNT(s.student_id)                        AS total_students,
    ROUND(AVG(s.cgpa), 2)                      AS avg_cgpa,
    MAX(s.cgpa)                                AS highest_cgpa,
    MIN(s.cgpa)                                AS lowest_cgpa,
    SUM(CASE WHEN s.cgpa >= 8.0 THEN 1 ELSE 0 END) AS distinction_count,
    SUM(CASE WHEN s.cgpa < 5.0  THEN 1 ELSE 0 END) AS backlog_risk_count,
    ROUND(AVG(a.attendance_percent), 2)        AS avg_attendance,
    COUNT(p.placement_id)                      AS placed_students
FROM departments d
LEFT JOIN students s ON d.dept_id = s.dept_id AND s.status = 'Active'
LEFT JOIN attendance_summary a ON s.student_id = a.student_id
LEFT JOIN placements p ON s.student_id = p.student_id AND p.status IN ('Accepted','Joined')
GROUP BY d.dept_id, d.dept_name, d.dept_code
ORDER BY avg_cgpa DESC;

-- ── 5. PLACEMENT ANALYTICS VIEW ──────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_placement_summary AS
SELECT
    s.student_id,
    s.roll_number,
    s.student_name,
    d.dept_name,
    s.cgpa,
    p.company_name,
    p.job_role,
    p.package_lpa,
    p.placement_type,
    p.offer_date,
    p.location,
    p.status AS placement_status
FROM placements p
JOIN students s ON p.student_id = s.student_id
JOIN departments d ON s.dept_id = d.dept_id
ORDER BY p.package_lpa DESC;

-- ── 6. SUBJECT-WISE AVERAGE MARKS ────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_subject_avg_marks AS
SELECT
    sub.subject_id,
    sub.subject_name,
    sub.subject_code,
    d.dept_name,
    e.exam_type,
    COUNT(e.exam_id)              AS total_exams_taken,
    ROUND(AVG(e.marks_obtained), 2) AS avg_marks,
    MAX(e.marks_obtained)         AS highest_marks,
    MIN(e.marks_obtained)         AS lowest_marks,
    SUM(CASE WHEN e.marks_obtained < 40 THEN 1 ELSE 0 END) AS fail_count
FROM exams e
JOIN subjects sub ON e.subject_id = sub.subject_id
JOIN departments d ON sub.dept_id = d.dept_id
GROUP BY sub.subject_id, sub.subject_name, sub.subject_code, d.dept_name, e.exam_type
ORDER BY avg_marks DESC;

-- ── 7. STUDENT FULL PROFILE ───────────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_student_profile AS
SELECT
    s.student_id,
    s.roll_number,
    s.student_name,
    s.email,
    s.phone,
    s.gender,
    s.dob,
    d.dept_name,
    d.dept_code,
    s.semester,
    s.batch_year,
    s.cgpa,
    s.city,
    s.status,
    a.attendance_percent,
    COALESCE(p.company_name, 'Not Placed')     AS placed_company,
    COALESCE(p.package_lpa, 0)                 AS package_lpa,
    COALESCE(f_pending.pending_amount, 0)      AS pending_fee_amount
FROM students s
JOIN departments d ON s.dept_id = d.dept_id
LEFT JOIN attendance_summary a ON s.student_id = a.student_id
LEFT JOIN placements p ON s.student_id = p.student_id
LEFT JOIN (
    SELECT student_id, ROUND(SUM(amount_due - amount_paid), 2) AS pending_amount
    FROM fees WHERE status IN ('Pending','Partial','Overdue')
    GROUP BY student_id
) f_pending ON s.student_id = f_pending.student_id;
