# 🎓 Student ERP Analytics & Management System

**A complete SQL portfolio project showcasing advanced database design, analytics, and automation.**

---

## 📌 Project Overview

A production-grade, SQL-based Student ERP system built to manage and analyze academic, attendance, fee, and placement data for 1,000 students across 8 departments. Designed to demonstrate advanced SQL proficiency for a software/data engineering resume.

---

## 🗂️ File Structure

| File | Description |
|------|-------------|
| `01_schema.sql` | Complete database schema — 9 relational tables with constraints, FK relationships, and indexes |
| `02_sample_data.sql` | 1,000 students + 3,000 exam records + 2,000 fee records + 525 placement records |
| `03_views.sql` | 7 reusable analytical views (dashboards) |
| `04_stored_procedures.sql` | 7 stored procedures for automated reports |
| `05_triggers.sql` | 6 triggers for business rule automation |
| `06_analytics_queries.sql` | 18 advanced analytics queries |

---

## 🗄️ Database Schema

```
student_erp
│
├── departments        (8 departments)
├── faculty            (56 faculty members)
├── subjects           (80 subjects, 10 per dept)
├── students           (1,000 students)
├── attendance         (detail log)
├── attendance_summary (denormalized summary — trigger maintained)
├── exams              (3,000 records)
├── fees               (2,000 records)
├── placements         (525 records)
└── student_audit_log  (trigger-generated audit trail)
```

### Entity Relationships
- **departments** → faculty, subjects, students (1:N)
- **students** → attendance, exams, fees, placements (1:N)
- **subjects** → exams, attendance (1:N)
- **faculty** → subjects (1:N)

---

## 📊 Sample Dataset Summary

| Entity | Records |
|--------|---------|
| Departments | 8 |
| Faculty | 56 |
| Subjects | 80 |
| **Students** | **1,000** |
| Exam Records | 3,000 |
| Fee Records | 2,000 |
| Placement Records | ~525 |

**Data includes:** CSE, ECE, MECH, CIVIL, IT, EEE, MBA, Data Science departments across batches 2020–2024.

---

## ⚙️ SQL Concepts Demonstrated

### 🔗 Joins
- INNER JOIN, LEFT JOIN across 4–5 tables
- Self-referencing subqueries

### 📝 Subqueries
- Correlated subqueries (dept avg CGPA comparison)
- IN-clause with grouped subqueries (highest package per dept)
- Scalar subqueries in SELECT

### 🔄 CTEs (Common Table Expressions)
- `ranked_students` — dept-wise toppers
- `batch_stats` — year-on-year comparison
- `student_metrics` — composite scoring
- Multi-CTE chaining

### 🪟 Window Functions
- `RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`
- `NTILE(4)` — performance quartiles
- `PERCENT_RANK()` — percentile scores
- `AVG() OVER (PARTITION BY ...)` — dept averages
- `SUM() OVER (ORDER BY ...)` — running totals (YTD fee collection, cumulative placements)
- `LAG()` — year-on-year CGPA delta

### 👁️ Views
| View | Purpose |
|------|---------|
| `vw_topper_students` | CGPA > 8.5 active students |
| `vw_low_attendance_alert` | Below 75% with WARNING/CRITICAL levels |
| `vw_pending_fees` | All pending/overdue fee records |
| `vw_dept_performance` | Full dept KPI dashboard |
| `vw_placement_summary` | All placements with student details |
| `vw_subject_avg_marks` | Subject-wise performance |
| `vw_student_profile` | 360° student profile |

### 🔧 Stored Procedures
| Procedure | Usage |
|-----------|-------|
| `monthly_attendance_report(year, month)` | Month-wise attendance |
| `dept_fee_collection_report(academic_year)` | Fee collection by dept |
| `get_student_report(student_id)` | Full student profile report |
| `get_dept_toppers(dept_id, n)` | Top N students in dept |
| `backlog_analysis()` | Students with failed subjects |
| `placement_package_analysis()` | Package stats by dept |
| `get_fee_defaulters(days_overdue)` | Overdue fee list |

### ⚡ Triggers
| Trigger | Event | Action |
|---------|-------|--------|
| `trg_update_attendance_summary` | AFTER INSERT on attendance | Recalculates attendance % |
| `trg_auto_grade_before_insert` | BEFORE INSERT on exams | Auto-assigns grade |
| `trg_auto_grade_before_update` | BEFORE UPDATE on exams | Auto-updates grade |
| `trg_update_fee_status` | BEFORE UPDATE on fees | Auto-sets Paid/Partial/Overdue |
| `trg_prevent_duplicate_placement` | BEFORE INSERT on placements | Prevents duplicates |
| `trg_student_status_audit` | AFTER UPDATE on students | Logs status changes |

### 📈 Analytics Features
- **Performance**: Dept rank, overall rank, CGPA quartiles, batch comparison, backlog analysis
- **Attendance**: Dept trends, low-alert students, attendance vs CGPA correlation
- **Fees**: Monthly collection trend, YTD running totals, defaulter list
- **Placements**: Highest package per dept, company-wise stats, placement rate vs CGPA

### 🚀 Indexing & Optimization
```sql
CREATE INDEX idx_students_cgpa      ON students(cgpa);
CREATE INDEX idx_students_batch     ON students(batch_year);
CREATE INDEX idx_attendance_student ON attendance(student_id);
CREATE INDEX idx_fees_status        ON fees(status);
CREATE INDEX idx_placements_pkg     ON placements(package_lpa);
```

---

## 🚀 How to Run

### Prerequisites
- MySQL 8.0+ (recommended) or MariaDB 10.5+
- MySQL Workbench / DBeaver / CLI

### Setup Steps
```bash
# 1. Connect to MySQL
mysql -u root -p

# 2. Run files in order
source 01_schema.sql
source 02_sample_data.sql
source 03_views.sql
source 04_stored_procedures.sql
source 05_triggers.sql

# 3. Run analytics
source 06_analytics_queries.sql
```

### Quick Test Queries
```sql
USE student_erp;

-- View all toppers
SELECT * FROM vw_topper_students LIMIT 10;

-- Low attendance alert
SELECT * FROM vw_low_attendance_alert;

-- Department dashboard
SELECT * FROM vw_dept_performance;

-- Run stored procedures
CALL backlog_analysis();
CALL placement_package_analysis();
CALL get_student_report(1);
CALL get_fee_defaulters(30);
```

---

## 💼 Resume Description

> **Student ERP Analytics & Management System** | *MySQL, SQL*
> Designed and implemented a full-stack SQL database system managing 1,000+ student records across 8 departments. Built normalized relational schema with 9 tables, 7 analytical views, 7 stored procedures, 6 automated triggers, and 18 advanced analytics queries leveraging window functions (RANK, NTILE, PERCENT_RANK, LAG), CTEs, correlated subqueries, and query optimization with strategic indexing. Features include real-time attendance tracking, fee defaulter detection, placement analytics, and academic risk scoring.

---

## 🛠️ Technologies
`MySQL 8.0` · `SQL DDL/DML` · `Stored Procedures` · `Triggers` · `Views` · `CTEs` · `Window Functions` · `Query Optimization` · `Indexing` · `Relational Database Design`

---

## 📁 GitHub Upload Checklist
- [ ] All 6 `.sql` files
- [ ] This `README.md`
- [ ] ER Diagram (draw using MySQL Workbench → Database → Reverse Engineer)
- [ ] Screenshots of query outputs
- [ ] Sample output CSVs (optional)
