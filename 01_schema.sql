-- ============================================================
--  Student ERP Analytics & Management System
--  Schema  |  MySQL 8.0 Compatible
--  Author  : Generated for Resume Portfolio Project
-- ============================================================

CREATE DATABASE IF NOT EXISTS student_erp;
USE student_erp;

-- ── DEPARTMENTS ────────────────────────────────────────────
CREATE TABLE departments (
    dept_id        INT PRIMARY KEY AUTO_INCREMENT,
    dept_name      VARCHAR(100) NOT NULL,
    dept_code      VARCHAR(10)  NOT NULL UNIQUE,
    hod_name       VARCHAR(100),
    program        VARCHAR(50),
    duration       VARCHAR(20),
    total_seats    INT          DEFAULT 60,
    established_yr YEAR,
    created_at     TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

-- ── FACULTY ────────────────────────────────────────────────
CREATE TABLE faculty (
    faculty_id    INT PRIMARY KEY AUTO_INCREMENT,
    faculty_name  VARCHAR(100) NOT NULL,
    email         VARCHAR(120) UNIQUE NOT NULL,
    phone         VARCHAR(15),
    dept_id       INT,
    designation   VARCHAR(60),
    experience_yr INT          DEFAULT 0,
    salary        DECIMAL(10,2),
    joining_date  DATE,
    created_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

-- ── SUBJECTS ───────────────────────────────────────────────
CREATE TABLE subjects (
    subject_id   INT PRIMARY KEY AUTO_INCREMENT,
    subject_name VARCHAR(100) NOT NULL,
    subject_code VARCHAR(20)  NOT NULL UNIQUE,
    dept_id      INT,
    semester     INT          CHECK (semester BETWEEN 1 AND 8),
    credits      INT          DEFAULT 4,
    faculty_id   INT,
    FOREIGN KEY (dept_id)    REFERENCES departments(dept_id),
    FOREIGN KEY (faculty_id) REFERENCES faculty(faculty_id)
);

-- ── STUDENTS ───────────────────────────────────────────────
CREATE TABLE students (
    student_id    INT PRIMARY KEY AUTO_INCREMENT,
    roll_number   VARCHAR(20)  UNIQUE NOT NULL,
    student_name  VARCHAR(100) NOT NULL,
    email         VARCHAR(120) UNIQUE NOT NULL,
    phone         VARCHAR(15),
    gender        ENUM('Male','Female','Other'),
    dob           DATE,
    dept_id       INT,
    semester      INT          CHECK (semester BETWEEN 1 AND 8),
    batch_year    YEAR,
    cgpa          DECIMAL(4,2) CHECK (cgpa BETWEEN 0 AND 10),
    address       TEXT,
    city          VARCHAR(60),
    admission_date DATE,
    status        ENUM('Active','Inactive','Graduated','Dropped') DEFAULT 'Active',
    created_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

-- ── ATTENDANCE ─────────────────────────────────────────────
CREATE TABLE attendance (
    attendance_id    INT PRIMARY KEY AUTO_INCREMENT,
    student_id       INT,
    subject_id       INT,
    attendance_date  DATE,
    status           ENUM('Present','Absent','Late') DEFAULT 'Present',
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id)
);

-- ── ATTENDANCE SUMMARY (denormalized for speed) ────────────
CREATE TABLE attendance_summary (
    summary_id         INT PRIMARY KEY AUTO_INCREMENT,
    student_id         INT UNIQUE,
    total_classes      INT     DEFAULT 0,
    classes_attended   INT     DEFAULT 0,
    attendance_percent DECIMAL(5,2) DEFAULT 0.00,
    last_updated       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

-- ── EXAMS ──────────────────────────────────────────────────
CREATE TABLE exams (
    exam_id      INT PRIMARY KEY AUTO_INCREMENT,
    exam_name    VARCHAR(100) NOT NULL,
    subject_id   INT,
    student_id   INT,
    exam_date    DATE,
    max_marks    INT DEFAULT 100,
    marks_obtained DECIMAL(5,2),
    grade        VARCHAR(5),
    exam_type    ENUM('Internal','Mid-Sem','End-Sem','Practical') DEFAULT 'End-Sem',
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

-- ── FEES ───────────────────────────────────────────────────
CREATE TABLE fees (
    fee_id          INT PRIMARY KEY AUTO_INCREMENT,
    student_id      INT,
    fee_type        ENUM('Tuition','Hostel','Library','Lab','Exam','Transport','Misc') DEFAULT 'Tuition',
    amount_due      DECIMAL(10,2),
    amount_paid     DECIMAL(10,2) DEFAULT 0.00,
    due_date        DATE,
    payment_date    DATE,
    payment_mode    ENUM('Online','Cash','DD','Card','UPI') DEFAULT 'Online',
    status          ENUM('Paid','Pending','Partial','Overdue') DEFAULT 'Pending',
    semester        INT,
    academic_year   VARCHAR(10),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

-- ── PLACEMENTS ─────────────────────────────────────────────
CREATE TABLE placements (
    placement_id   INT PRIMARY KEY AUTO_INCREMENT,
    student_id     INT UNIQUE,
    company_name   VARCHAR(100),
    job_role       VARCHAR(100),
    package_lpa    DECIMAL(6,2),
    offer_date     DATE,
    joining_date   DATE,
    placement_type ENUM('On-Campus','Off-Campus','Internship') DEFAULT 'On-Campus',
    location       VARCHAR(80),
    status         ENUM('Offered','Accepted','Declined','Joined') DEFAULT 'Offered',
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

-- ── INDEXES FOR PERFORMANCE ────────────────────────────────
CREATE INDEX idx_students_dept      ON students(dept_id);
CREATE INDEX idx_students_cgpa      ON students(cgpa);
CREATE INDEX idx_students_batch     ON students(batch_year);
CREATE INDEX idx_attendance_student ON attendance(student_id);
CREATE INDEX idx_attendance_date    ON attendance(attendance_date);
CREATE INDEX idx_exams_student      ON exams(student_id);
CREATE INDEX idx_exams_subject      ON exams(subject_id);
CREATE INDEX idx_fees_student       ON fees(student_id);
CREATE INDEX idx_fees_status        ON fees(status);
CREATE INDEX idx_placements_pkg     ON placements(package_lpa);
