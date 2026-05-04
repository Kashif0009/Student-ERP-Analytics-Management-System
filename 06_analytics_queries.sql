-- ============================================================
--  Student ERP Analytics & Management System
--  ADVANCED ANALYTICS QUERIES
--  Showcases: JOINs · Subqueries · CTEs · Window Functions
-- ============================================================
USE student_erp;

-- ═══════════════════════════════════════════════════════════
--  SECTION 1 ── STUDENT PERFORMANCE ANALYSIS
-- ═══════════════════════════════════════════════════════════

-- Q1. Rank all students within their department using WINDOW FUNCTION
SELECT
    s.roll_number,
    s.student_name,
    d.dept_name,
    s.cgpa,
    RANK()       OVER (PARTITION BY s.dept_id ORDER BY s.cgpa DESC) AS dept_rank,
    DENSE_RANK() OVER (ORDER BY s.cgpa DESC)                        AS overall_rank,
    NTILE(4)     OVER (ORDER BY s.cgpa DESC)                        AS performance_quartile,
    ROUND(AVG(s.cgpa) OVER (PARTITION BY s.dept_id), 2)             AS dept_avg_cgpa
FROM students s
JOIN departments d ON s.dept_id = d.dept_id
WHERE s.status = 'Active'
ORDER BY d.dept_name, dept_rank;

-- Q2. Top 3 toppers per department using CTE + WINDOW FUNCTION
WITH ranked_students AS (
    SELECT
        s.student_id,
        s.roll_number,
        s.student_name,
        d.dept_name,
        s.cgpa,
        s.batch_year,
        ROW_NUMBER() OVER (PARTITION BY s.dept_id ORDER BY s.cgpa DESC) AS rn
    FROM students s
    JOIN departments d ON s.dept_id = d.dept_id
    WHERE s.status = 'Active'
)
SELECT dept_name, roll_number, student_name, cgpa, batch_year, rn AS rank_in_dept
FROM ranked_students
WHERE rn <= 3
ORDER BY dept_name, rn;

-- Q3. CGPA distribution by grade band (subquery)
SELECT
    grade_band,
    COUNT(*) AS student_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM students WHERE status='Active'), 2) AS percentage
FROM (
    SELECT
        CASE
            WHEN cgpa >= 9.0 THEN 'O  (9.0 – 10.0)'
            WHEN cgpa >= 8.0 THEN 'A+ (8.0 – 8.99)'
            WHEN cgpa >= 7.0 THEN 'A  (7.0 – 7.99)'
            WHEN cgpa >= 6.0 THEN 'B+ (6.0 – 6.99)'
            WHEN cgpa >= 5.0 THEN 'B  (5.0 – 5.99)'
            ELSE                  'C  (< 5.0)'
        END AS grade_band
    FROM students WHERE status = 'Active'
) graded
GROUP BY grade_band
ORDER BY grade_band;

-- Q4. Year-on-year batch performance comparison using CTE
WITH batch_stats AS (
    SELECT
        batch_year,
        COUNT(*)              AS total_students,
        ROUND(AVG(cgpa), 2)   AS avg_cgpa,
        MAX(cgpa)             AS highest_cgpa,
        SUM(CASE WHEN cgpa >= 8.0 THEN 1 ELSE 0 END) AS distinctions,
        SUM(CASE WHEN cgpa <  5.0 THEN 1 ELSE 0 END) AS at_risk
    FROM students WHERE status <> 'Dropped'
    GROUP BY batch_year
)
SELECT *,
    ROUND(avg_cgpa - LAG(avg_cgpa) OVER (ORDER BY batch_year), 2) AS cgpa_delta
FROM batch_stats
ORDER BY batch_year;

-- Q5. Backlog students: failed in at least one End-Sem subject
SELECT
    s.roll_number,
    s.student_name,
    d.dept_name,
    s.semester,
    COUNT(CASE WHEN e.marks_obtained < 40 THEN 1 END) AS backlog_count,
    s.cgpa
FROM students s
JOIN departments d ON s.dept_id = d.dept_id
JOIN exams e       ON s.student_id = e.student_id AND e.exam_type = 'End-Sem'
WHERE s.status = 'Active'
GROUP BY s.student_id, s.roll_number, s.student_name, d.dept_name, s.semester, s.cgpa
HAVING backlog_count > 0
ORDER BY backlog_count DESC;

-- ═══════════════════════════════════════════════════════════
--  SECTION 2 ── ATTENDANCE ANALYSIS
-- ═══════════════════════════════════════════════════════════

-- Q6. Department-wise attendance trends
SELECT
    d.dept_name,
    d.dept_code,
    ROUND(AVG(a.attendance_percent), 2) AS avg_attendance,
    MIN(a.attendance_percent)           AS min_attendance,
    MAX(a.attendance_percent)           AS max_attendance,
    SUM(CASE WHEN a.attendance_percent < 75 THEN 1 ELSE 0 END) AS students_below_75,
    COUNT(a.student_id)                 AS total_students
FROM attendance_summary a
JOIN students s    ON a.student_id = s.student_id
JOIN departments d ON s.dept_id    = d.dept_id
WHERE s.status = 'Active'
GROUP BY d.dept_name, d.dept_code
ORDER BY avg_attendance DESC;

-- Q7. Students with perfect or near-perfect attendance (>= 95 %)
SELECT
    s.roll_number,
    s.student_name,
    d.dept_name,
    a.classes_attended,
    a.total_classes,
    a.attendance_percent
FROM attendance_summary a
JOIN students s    ON a.student_id = s.student_id
JOIN departments d ON s.dept_id    = d.dept_id
WHERE a.attendance_percent >= 95 AND s.status = 'Active'
ORDER BY a.attendance_percent DESC;

-- Q8. Correlation: attendance vs CGPA using window buckets
WITH att_buckets AS (
    SELECT
        s.student_id,
        s.cgpa,
        a.attendance_percent,
        CASE
            WHEN a.attendance_percent >= 90 THEN '90-100%'
            WHEN a.attendance_percent >= 75 THEN '75-89%'
            WHEN a.attendance_percent >= 60 THEN '60-74%'
            ELSE 'Below 60%'
        END AS att_bucket
    FROM students s JOIN attendance_summary a ON s.student_id = a.student_id
    WHERE s.status = 'Active'
)
SELECT
    att_bucket,
    COUNT(*)              AS students,
    ROUND(AVG(cgpa), 2)   AS avg_cgpa,
    MAX(cgpa)             AS max_cgpa,
    MIN(cgpa)             AS min_cgpa
FROM att_buckets
GROUP BY att_bucket
ORDER BY att_bucket DESC;

-- ═══════════════════════════════════════════════════════════
--  SECTION 3 ── FEE ANALYTICS
-- ═══════════════════════════════════════════════════════════

-- Q9. Monthly fee collection trend
SELECT
    YEAR(payment_date)  AS pay_year,
    MONTH(payment_date) AS pay_month,
    COUNT(fee_id)        AS transactions,
    ROUND(SUM(amount_paid), 2)          AS monthly_collection,
    ROUND(AVG(amount_paid), 2)          AS avg_transaction,
    ROUND(SUM(SUM(amount_paid)) OVER (
        PARTITION BY YEAR(payment_date)
        ORDER BY MONTH(payment_date)
    ), 2)                               AS ytd_collection
FROM fees
WHERE payment_date IS NOT NULL
GROUP BY pay_year, pay_month
ORDER BY pay_year, pay_month;

-- Q10. Fee collection efficiency per department
WITH dept_fee AS (
    SELECT
        d.dept_name,
        SUM(f.amount_due)                               AS total_due,
        SUM(f.amount_paid)                              AS total_paid,
        COUNT(CASE WHEN f.status = 'Paid'    THEN 1 END) AS fully_paid,
        COUNT(CASE WHEN f.status = 'Overdue' THEN 1 END) AS overdue_count,
        COUNT(CASE WHEN f.status = 'Partial' THEN 1 END) AS partial_count
    FROM fees f
    JOIN students s ON f.student_id = s.student_id
    JOIN departments d ON s.dept_id = d.dept_id
    GROUP BY d.dept_name
)
SELECT
    dept_name,
    ROUND(total_due,  2) AS total_due,
    ROUND(total_paid, 2) AS total_paid,
    ROUND(total_due - total_paid, 2) AS total_outstanding,
    ROUND(total_paid * 100.0 / NULLIF(total_due, 0), 2) AS collection_pct,
    fully_paid,
    overdue_count,
    partial_count
FROM dept_fee
ORDER BY collection_pct DESC;

-- ═══════════════════════════════════════════════════════════
--  SECTION 4 ── PLACEMENT ANALYTICS
-- ═══════════════════════════════════════════════════════════

-- Q11. Highest package per department
SELECT
    d.dept_name,
    s.student_name,
    s.roll_number,
    s.cgpa,
    p.company_name,
    p.job_role,
    p.package_lpa
FROM placements p
JOIN students s    ON p.student_id = s.student_id
JOIN departments d ON s.dept_id    = d.dept_id
WHERE (d.dept_id, p.package_lpa) IN (
    SELECT s2.dept_id, MAX(p2.package_lpa)
    FROM placements p2
    JOIN students s2 ON p2.student_id = s2.student_id
    GROUP BY s2.dept_id
)
ORDER BY p.package_lpa DESC;

-- Q12. Company-wise placement count and average package
SELECT
    p.company_name,
    COUNT(p.placement_id)         AS offers,
    ROUND(AVG(p.package_lpa), 2)  AS avg_package,
    MAX(p.package_lpa)            AS max_package,
    MIN(p.package_lpa)            AS min_package,
    GROUP_CONCAT(DISTINCT p.job_role ORDER BY p.job_role SEPARATOR ' | ') AS roles_offered
FROM placements p
WHERE p.status IN ('Accepted','Joined')
GROUP BY p.company_name
ORDER BY offers DESC, avg_package DESC;

-- Q13. Placement rate vs avg CGPA by department
WITH dept_place AS (
    SELECT
        d.dept_id,
        d.dept_name,
        COUNT(DISTINCT s.student_id)  AS total_students,
        COUNT(DISTINCT p.student_id)  AS placed_students,
        ROUND(AVG(s.cgpa), 2)         AS avg_cgpa,
        ROUND(AVG(p.package_lpa), 2)  AS avg_package
    FROM departments d
    LEFT JOIN students   s ON d.dept_id = s.dept_id AND s.status IN ('Active','Graduated')
    LEFT JOIN placements p ON s.student_id = p.student_id AND p.status IN ('Accepted','Joined')
    GROUP BY d.dept_id, d.dept_name
)
SELECT
    dept_name,
    total_students,
    placed_students,
    ROUND(placed_students * 100.0 / NULLIF(total_students, 0), 2) AS placement_rate_pct,
    avg_cgpa,
    avg_package
FROM dept_place
ORDER BY placement_rate_pct DESC;

-- Q14. Running total of placements by month (window function)
SELECT
    DATE_FORMAT(p.offer_date, '%Y-%m') AS offer_month,
    COUNT(p.placement_id)              AS monthly_placements,
    ROUND(AVG(p.package_lpa), 2)       AS avg_pkg,
    SUM(COUNT(p.placement_id)) OVER (ORDER BY DATE_FORMAT(p.offer_date, '%Y-%m')) AS cumulative_placed
FROM placements p
WHERE p.status IN ('Accepted','Joined')
GROUP BY offer_month
ORDER BY offer_month;

-- ═══════════════════════════════════════════════════════════
--  SECTION 5 ── ADVANCED CTE & WINDOW FUNCTION SHOWCASES
-- ═══════════════════════════════════════════════════════════

-- Q15. Multi-metric student ranking with percentile
WITH student_metrics AS (
    SELECT
        s.student_id,
        s.roll_number,
        s.student_name,
        d.dept_name,
        s.cgpa,
        a.attendance_percent,
        COALESCE(p.package_lpa, 0) AS package_lpa
    FROM students s
    JOIN departments d ON s.dept_id = d.dept_id
    LEFT JOIN attendance_summary a ON s.student_id = a.student_id
    LEFT JOIN placements p         ON s.student_id = p.student_id
    WHERE s.status = 'Active'
),
scored AS (
    SELECT *,
        ROUND(cgpa * 0.5 + attendance_percent * 0.003 + package_lpa * 0.2, 2) AS composite_score
    FROM student_metrics
)
SELECT
    roll_number,
    student_name,
    dept_name,
    cgpa,
    attendance_percent,
    package_lpa,
    composite_score,
    PERCENT_RANK() OVER (ORDER BY composite_score)            AS percentile_rank,
    RANK()         OVER (ORDER BY composite_score DESC)       AS overall_rank
FROM scored
ORDER BY overall_rank
LIMIT 50;

-- Q16. Students above department average CGPA (correlated subquery)
SELECT
    s.roll_number,
    s.student_name,
    d.dept_name,
    s.cgpa,
    (SELECT ROUND(AVG(cgpa),2) FROM students s2
     WHERE s2.dept_id = s.dept_id AND s2.status='Active') AS dept_avg,
    ROUND(s.cgpa -
         (SELECT AVG(cgpa) FROM students s2
          WHERE s2.dept_id = s.dept_id AND s2.status='Active'), 2) AS above_avg_by
FROM students s
JOIN departments d ON s.dept_id = d.dept_id
WHERE s.status = 'Active'
  AND s.cgpa > (SELECT AVG(cgpa) FROM students s3
                WHERE s3.dept_id = s.dept_id AND s3.status='Active')
ORDER BY above_avg_by DESC;

-- Q17. Detect students at academic risk (low CGPA + low attendance + fee due)
SELECT
    s.roll_number,
    s.student_name,
    s.phone,
    d.dept_name,
    s.cgpa,
    a.attendance_percent,
    ROUND(SUM(CASE WHEN f.status IN ('Pending','Overdue')
                   THEN f.amount_due - f.amount_paid ELSE 0 END), 2) AS pending_fees,
    CASE
        WHEN s.cgpa < 5 AND a.attendance_percent < 60 THEN 'HIGH RISK'
        WHEN s.cgpa < 6 AND a.attendance_percent < 75 THEN 'MEDIUM RISK'
        ELSE 'LOW RISK'
    END AS risk_level
FROM students s
JOIN departments d      ON s.dept_id    = d.dept_id
JOIN attendance_summary a ON s.student_id = a.student_id
LEFT JOIN fees f          ON s.student_id = f.student_id
WHERE s.status = 'Active'
  AND (s.cgpa < 6 OR a.attendance_percent < 75)
GROUP BY s.student_id, s.roll_number, s.student_name, s.phone,
         d.dept_name, s.cgpa, a.attendance_percent
ORDER BY risk_level, s.cgpa ASC;

-- Q18. Subject pass/fail ratio with subject difficulty index
SELECT
    sub.subject_name,
    sub.subject_code,
    d.dept_name,
    COUNT(e.exam_id)                                          AS total_attempts,
    SUM(CASE WHEN e.marks_obtained >= 40 THEN 1 ELSE 0 END)  AS pass_count,
    SUM(CASE WHEN e.marks_obtained <  40 THEN 1 ELSE 0 END)  AS fail_count,
    ROUND(AVG(e.marks_obtained), 2)                          AS avg_marks,
    ROUND(SUM(CASE WHEN e.marks_obtained < 40 THEN 1 ELSE 0 END) * 100.0
          / NULLIF(COUNT(e.exam_id), 0), 2)                  AS fail_rate_pct,
    CASE
        WHEN AVG(e.marks_obtained) < 50 THEN 'Hard'
        WHEN AVG(e.marks_obtained) < 65 THEN 'Moderate'
        ELSE 'Easy'
    END AS difficulty_index
FROM exams e
JOIN subjects sub ON e.subject_id = sub.subject_id
JOIN departments d ON sub.dept_id = d.dept_id
WHERE e.exam_type = 'End-Sem'
GROUP BY sub.subject_id, sub.subject_name, sub.subject_code, d.dept_name
ORDER BY fail_rate_pct DESC;
