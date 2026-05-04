-- ============================================================
--  Student ERP Analytics & Management System
--  TRIGGERS  |  Automated Business Rules
-- ============================================================
USE student_erp;

DELIMITER $$

-- ── 1. AUTO-UPDATE ATTENDANCE SUMMARY AFTER INSERT ───────────────────────────
CREATE TRIGGER trg_update_attendance_summary
AFTER INSERT ON attendance
FOR EACH ROW
BEGIN
    DECLARE v_total    INT DEFAULT 0;
    DECLARE v_attended INT DEFAULT 0;
    DECLARE v_pct      DECIMAL(5,2) DEFAULT 0.00;

    SELECT COUNT(*),
           SUM(CASE WHEN status IN ('Present','Late') THEN 1 ELSE 0 END)
    INTO v_total, v_attended
    FROM attendance
    WHERE student_id = NEW.student_id;

    SET v_pct = IF(v_total > 0, ROUND(v_attended * 100.0 / v_total, 2), 0);

    INSERT INTO attendance_summary (student_id, total_classes, classes_attended, attendance_percent)
    VALUES (NEW.student_id, v_total, v_attended, v_pct)
    ON DUPLICATE KEY UPDATE
        total_classes      = v_total,
        classes_attended   = v_attended,
        attendance_percent = v_pct;
END$$

-- ── 2. AUTO-ASSIGN GRADE BEFORE EXAM INSERT ───────────────────────────────────
CREATE TRIGGER trg_auto_grade_before_insert
BEFORE INSERT ON exams
FOR EACH ROW
BEGIN
    SET NEW.grade = CASE
        WHEN NEW.marks_obtained >= 90 THEN 'O'
        WHEN NEW.marks_obtained >= 80 THEN 'A+'
        WHEN NEW.marks_obtained >= 70 THEN 'A'
        WHEN NEW.marks_obtained >= 60 THEN 'B+'
        WHEN NEW.marks_obtained >= 50 THEN 'B'
        WHEN NEW.marks_obtained >= 40 THEN 'C'
        ELSE 'F'
    END;
END$$

-- ── 3. AUTO-ASSIGN GRADE BEFORE EXAM UPDATE ──────────────────────────────────
CREATE TRIGGER trg_auto_grade_before_update
BEFORE UPDATE ON exams
FOR EACH ROW
BEGIN
    SET NEW.grade = CASE
        WHEN NEW.marks_obtained >= 90 THEN 'O'
        WHEN NEW.marks_obtained >= 80 THEN 'A+'
        WHEN NEW.marks_obtained >= 70 THEN 'A'
        WHEN NEW.marks_obtained >= 60 THEN 'B+'
        WHEN NEW.marks_obtained >= 50 THEN 'B'
        WHEN NEW.marks_obtained >= 40 THEN 'C'
        ELSE 'F'
    END;
END$$

-- ── 4. AUTO-UPDATE FEE STATUS ON PAYMENT ─────────────────────────────────────
CREATE TRIGGER trg_update_fee_status
BEFORE UPDATE ON fees
FOR EACH ROW
BEGIN
    IF NEW.amount_paid >= NEW.amount_due THEN
        SET NEW.status = 'Paid';
    ELSEIF NEW.amount_paid > 0 AND NEW.amount_paid < NEW.amount_due THEN
        SET NEW.status = 'Partial';
    ELSEIF NEW.amount_paid = 0 AND CURDATE() > NEW.due_date THEN
        SET NEW.status = 'Overdue';
    ELSE
        SET NEW.status = 'Pending';
    END IF;
END$$

-- ── 5. PREVENT DUPLICATE PLACEMENT RECORD ────────────────────────────────────
CREATE TRIGGER trg_prevent_duplicate_placement
BEFORE INSERT ON placements
FOR EACH ROW
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count FROM placements WHERE student_id = NEW.student_id;
    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student already has a placement record. Use UPDATE instead.';
    END IF;
END$$

-- ── 6. LOG STUDENT STATUS CHANGE (audit trail) ────────────────────────────────
CREATE TABLE IF NOT EXISTS student_audit_log (
    log_id       INT PRIMARY KEY AUTO_INCREMENT,
    student_id   INT,
    old_status   VARCHAR(30),
    new_status   VARCHAR(30),
    changed_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_student_status_audit
AFTER UPDATE ON students
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        INSERT INTO student_audit_log (student_id, old_status, new_status)
        VALUES (NEW.student_id, OLD.status, NEW.status);
    END IF;
END$$

DELIMITER ;
