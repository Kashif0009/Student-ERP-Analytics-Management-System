-- ============================================================
--  Student ERP Analytics & Management System
--  STORED PROCEDURES  |  Automated Reports & Business Logic
-- ============================================================
USE student_erp;

DELIMITER $$

-- ── 1. MONTHLY ATTENDANCE REPORT ─────────────────────────────────────────────
-- CALL monthly_attendance_report(2024, 10);
CREATE PROCEDURE monthly_attendance_report(
    IN p_year  INT,
    IN p_month INT
)
BEGIN
    SELECT
        d.dept_name,
        s.roll_number,
        s.student_name,
        COUNT(a.attendance_id)                                 AS total_days,
        SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) AS days_present,
        SUM(CASE WHEN a.status = 'Absent'  THEN 1 ELSE 0 END) AS days_absent,
        ROUND(
            SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) * 100.0 /
            NULLIF(COUNT(a.attendance_id), 0), 2
        )                                                      AS monthly_pct
    FROM attendance a
    JOIN students s   ON a.student_id   = s.student_id
    JOIN departments d ON s.dept_id     = d.dept_id
    WHERE YEAR(a.attendance_date)  = p_year
      AND MONTH(a.attendance_date) = p_month
    GROUP BY d.dept_name, s.roll_number, s.student_name
    ORDER BY monthly_pct ASC;
END$$

-- ── 2. DEPARTMENT WISE FEE COLLECTION REPORT ─────────────────────────────────
-- CALL dept_fee_collection_report('2024-25');
CREATE PROCEDURE dept_fee_collection_report(
    IN p_academic_year VARCHAR(10)
)
BEGIN
    SELECT
        d.dept_name,
        d.dept_code,
        COUNT(DISTINCT f.student_id)          AS total_students,
        ROUND(SUM(f.amount_due),  2)          AS total_amount_due,
        ROUND(SUM(f.amount_paid), 2)          AS total_collected,
        ROUND(SUM(f.amount_due - f.amount_paid), 2) AS total_pending,
        ROUND(SUM(f.amount_paid) * 100.0 /
              NULLIF(SUM(f.amount_due), 0), 2) AS collection_pct
    FROM fees f
    JOIN students s    ON f.student_id = s.student_id
    JOIN departments d ON s.dept_id    = d.dept_id
    WHERE f.academic_year = p_academic_year
    GROUP BY d.dept_name, d.dept_code
    ORDER BY collection_pct DESC;
END$$

-- ── 3. STUDENT ACADEMIC REPORT ────────────────────────────────────────────────
-- CALL get_student_report(1);
CREATE PROCEDURE get_student_report(
    IN p_student_id INT
)
BEGIN
    -- Basic Info
    SELECT s.*, d.dept_name, d.dept_code
    FROM students s JOIN departments d ON s.dept_id = d.dept_id
    WHERE s.student_id = p_student_id;

    -- Attendance
    SELECT total_classes, classes_attended, attendance_percent
    FROM attendance_summary WHERE student_id = p_student_id;

    -- Exam Results
    SELECT sub.subject_name, e.exam_type, e.marks_obtained, e.grade, e.exam_date
    FROM exams e JOIN subjects sub ON e.subject_id = sub.subject_id
    WHERE e.student_id = p_student_id
    ORDER BY e.exam_date DESC;

    -- Fee Status
    SELECT fee_type, academic_year, amount_due, amount_paid,
           ROUND(amount_due - amount_paid,2) AS balance, status
    FROM fees WHERE student_id = p_student_id ORDER BY due_date;

    -- Placement
    SELECT company_name, job_role, package_lpa, placement_type, status
    FROM placements WHERE student_id = p_student_id;
END$$

-- ── 4. TOPPERS LIST BY DEPARTMENT ─────────────────────────────────────────────
-- CALL get_dept_toppers(1, 5);
CREATE PROCEDURE get_dept_toppers(
    IN p_dept_id INT,
    IN p_top_n   INT
)
BEGIN
    SELECT
        s.roll_number,
        s.student_name,
        s.batch_year,
        s.cgpa,
        RANK() OVER (ORDER BY s.cgpa DESC) AS dept_rank
    FROM students s
    WHERE s.dept_id = p_dept_id AND s.status = 'Active'
    ORDER BY s.cgpa DESC
    LIMIT p_top_n;
END$$

-- ── 5. BACKLOG ANALYSIS ───────────────────────────────────────────────────────
-- CALL backlog_analysis();
CREATE PROCEDURE backlog_analysis()
BEGIN
    SELECT
        s.roll_number,
        s.student_name,
        d.dept_name,
        s.semester,
        COUNT(e.exam_id)                                       AS subjects_appeared,
        SUM(CASE WHEN e.marks_obtained < 40 THEN 1 ELSE 0 END) AS backlogs,
        s.cgpa
    FROM students s
    JOIN departments d ON s.dept_id = d.dept_id
    JOIN exams e ON s.student_id = e.student_id
    WHERE e.exam_type = 'End-Sem'
    GROUP BY s.student_id, s.roll_number, s.student_name, d.dept_name, s.semester, s.cgpa
    HAVING backlogs > 0
    ORDER BY backlogs DESC;
END$$

-- ── 6. PLACEMENT PACKAGE ANALYSIS ────────────────────────────────────────────
-- CALL placement_package_analysis();
CREATE PROCEDURE placement_package_analysis()
BEGIN
    SELECT
        d.dept_name,
        COUNT(p.placement_id)            AS placed_count,
        ROUND(AVG(p.package_lpa), 2)     AS avg_package,
        MAX(p.package_lpa)               AS highest_package,
        MIN(p.package_lpa)               AS lowest_package,
        SUM(CASE WHEN p.package_lpa >= 10 THEN 1 ELSE 0 END) AS dream_offers,
        SUM(CASE WHEN p.package_lpa BETWEEN 5 AND 9.99 THEN 1 ELSE 0 END) AS good_offers,
        SUM(CASE WHEN p.package_lpa < 5 THEN 1 ELSE 0 END)  AS base_offers
    FROM placements p
    JOIN students s    ON p.student_id = s.student_id
    JOIN departments d ON s.dept_id    = d.dept_id
    WHERE p.status IN ('Accepted','Joined')
    GROUP BY d.dept_name
    ORDER BY avg_package DESC;
END$$

-- ── 7. FEE DEFAULTER LIST ─────────────────────────────────────────────────────
-- CALL get_fee_defaulters(30);
CREATE PROCEDURE get_fee_defaulters(
    IN p_days_overdue INT
)
BEGIN
    SELECT
        s.roll_number,
        s.student_name,
        s.phone,
        d.dept_name,
        f.fee_type,
        f.academic_year,
        ROUND(f.amount_due - f.amount_paid, 2) AS pending,
        f.due_date,
        DATEDIFF(CURDATE(), f.due_date) AS overdue_days
    FROM fees f
    JOIN students s    ON f.student_id = s.student_id
    JOIN departments d ON s.dept_id    = d.dept_id
    WHERE f.status IN ('Pending','Overdue')
      AND DATEDIFF(CURDATE(), f.due_date) >= p_days_overdue
    ORDER BY overdue_days DESC;
END$$

DELIMITER ;
