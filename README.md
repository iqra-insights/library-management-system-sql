# 📚 SQL Library Management System

A relational database project simulating a real-world library — books,
members, staff, borrowing transactions, and fine management — designed to
demonstrate practical, job-ready SQL skills.

---

## 📁 Project Structure

```
sql-library-management-system/
├── 01_schema_and_data.sql        # Database schema + sample data
├── 02_queries_and_analysis.sql   # Queries, views, triggers, stored procedures
└── README.md
```

---

## 🧩 Entity-Relationship Overview

```
Publishers ──┐
             ├──< Books >──── Categories
Authors ──< Book_Authors        │
                                 │
Members ──< BorrowRecords >──── Books
   │              │
   │              └──< Fines
Staff ──< BorrowRecords
```

**8 tables:**
`Publishers`, `Categories`, `Authors`, `Books`, `Book_Authors` (many-to-many
bridge), `Members`, `Staff`, `BorrowRecords`, `Fines`

---

## ⚙️ How to Run

1. Open MySQL Workbench (or any MySQL 8.0+ client).
2. Run `01_schema_and_data.sql` — creates the database and loads sample data.
3. Run `02_queries_and_analysis.sql` — creates the view, triggers, stored
   procedures, and runs the analysis queries.

> Written in MySQL syntax. For PostgreSQL/SQLite, minor changes are needed
> (`AUTO_INCREMENT` → `SERIAL`, remove `DELIMITER` blocks, `GROUP_CONCAT` →
> `STRING_AGG`).

---

## 🎯 SQL Concepts Demonstrated

| Concept | Where |
|---|---|
| Schema design (PK/FK, `CHECK`, `ENUM`, cascading deletes, `ON UPDATE`/`ON DELETE` rules) | `01_schema_and_data.sql` |
| Normalization to 3NF (no transitive/partial dependencies; `Book_Authors` resolves the M:N relationship) | `01_schema_and_data.sql` |
| Indexing for query performance (FKs, status, due date, title) | `01_schema_and_data.sql` |
| Multi-table `JOIN`s (inner + left) | Query 1, 2, 5 |
| Aggregation (`GROUP BY`, `SUM`, `COUNT`, `GROUP_CONCAT`) | Query 3, 4, 5 |
| Subqueries (`NOT IN`) | Query 7 |
| CTEs (`WITH`) | Query 8 |
| Window functions (`RANK()`, `DENSE_RANK()`) | Query 6, 8 |
| Views | `Overdue_Books_View` |
| Triggers | `trg_after_borrow`, `trg_after_return` |
| Stored procedures with error handling | `sp_issue_book`, `sp_return_book` |

### Data Integrity Rules
- `chk_copies` — `available_copies` can never exceed `total_copies` or drop below 0
- `chk_dates` — `due_date` can never be earlier than `borrow_date`
- `chk_amount` — fine `amount` can never be negative
- `Fines.record_id` cascades on delete (a fine can't outlive its borrow record)
- `BorrowRecords.staff_id` sets to `NULL` on staff deletion (history is preserved even if a staff member leaves)

---

## 📊 Sample Business Questions Answered

- Which books are most popular?
- Which members currently have overdue books, and by how many days?
- How much fine revenue is pending vs. collected?
- Which staff member has processed the most transactions?
- What's the total inventory value per category?

**Example output — Overdue Books View:**

| member_name | phone | title | due_date | days_overdue |
|---|---|---|---|---|
| Rohan Mehta | 9812345603 | Atomic Habits | 2025-02-15 | 30 |
| Karan Kapoor | 9812345605 | Murder on the Orient Express | 2025-02-24 | 21 |

---

## 🚀 Possible Extensions

- Connect to Power BI / Tableau for a live dashboard on top of these queries
- Wrap the stored procedures in a Python (Flask/Streamlit) front end for an
  interactive library app
- Add a `Reservations` table for hold-queue functionality

---

**Author:** Iqra Siddiqui
**Tech stack:** MySQL, SQL Workbench
