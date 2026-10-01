-- =====================================================================
-- LIBRARY MANAGEMENT SYSTEM - ANALYSIS QUERIES
-- Demonstrates: JOINs, subqueries, aggregation, window functions,
--               views, triggers, and stored procedures
-- =====================================================================

USE library_management_system;

-- ---------------------------------------------------------------------
-- 1. List all books with their author(s), category, and publisher
-- ---------------------------------------------------------------------
SELECT
    b.title,
    GROUP_CONCAT(CONCAT(a.first_name, ' ', a.last_name) SEPARATOR ', ') AS authors,
    c.category_name,
    p.name AS publisher,
    b.available_copies,
    b.total_copies
FROM Books b
JOIN Book_Authors ba ON b.book_id = ba.book_id
JOIN Authors a        ON ba.author_id = a.author_id
JOIN Categories c     ON b.category_id = c.category_id
JOIN Publishers p     ON b.publisher_id = p.publisher_id
GROUP BY b.book_id
ORDER BY b.title;

-- ---------------------------------------------------------------------
-- 2. Members who currently have overdue books
-- ---------------------------------------------------------------------
SELECT
    m.member_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    b.title,
    br.due_date,
    DATEDIFF(CURDATE(), br.due_date) AS days_overdue
FROM BorrowRecords br
JOIN Members m ON br.member_id = m.member_id
JOIN Books b   ON br.book_id = b.book_id
WHERE br.status = 'Overdue'
ORDER BY days_overdue DESC;

-- ---------------------------------------------------------------------
-- 3. Total fines collected vs pending, by status
-- ---------------------------------------------------------------------
SELECT
    paid_status,
    COUNT(*) AS number_of_fines,
    SUM(amount) AS total_amount
FROM Fines
GROUP BY paid_status;

-- ---------------------------------------------------------------------
-- 4. Top 5 most borrowed books (all-time)
-- ---------------------------------------------------------------------
SELECT
    b.title,
    COUNT(br.record_id) AS times_borrowed
FROM BorrowRecords br
JOIN Books b ON br.book_id = b.book_id
GROUP BY b.book_id
ORDER BY times_borrowed DESC
LIMIT 5;

-- ---------------------------------------------------------------------
-- 5. Available book count and inventory value by category
-- ---------------------------------------------------------------------
SELECT
    c.category_name,
    COUNT(b.book_id) AS num_titles,
    SUM(b.available_copies) AS copies_available,
    SUM(b.total_copies * b.price) AS inventory_value
FROM Categories c
LEFT JOIN Books b ON c.category_id = b.category_id
GROUP BY c.category_id
ORDER BY inventory_value DESC;

-- ---------------------------------------------------------------------
-- 6. Staff ranked by number of transactions processed (window function)
-- ---------------------------------------------------------------------
SELECT
    s.staff_id,
    CONCAT(s.first_name, ' ', s.last_name) AS staff_name,
    COUNT(br.record_id) AS transactions_handled,
    RANK() OVER (ORDER BY COUNT(br.record_id) DESC) AS staff_rank
FROM Staff s
LEFT JOIN BorrowRecords br ON s.staff_id = br.staff_id
GROUP BY s.staff_id;

-- ---------------------------------------------------------------------
-- 7. Members who have never returned a book late
--    (subquery: exclude members who appear in the overdue/fined list)
-- ---------------------------------------------------------------------
SELECT
    member_id,
    CONCAT(first_name, ' ', last_name) AS member_name
FROM Members
WHERE member_id NOT IN (
    SELECT DISTINCT br.member_id
    FROM BorrowRecords br
    JOIN Fines f ON br.record_id = f.record_id
);

-- ---------------------------------------------------------------------
-- 8. Member borrowing frequency ranking (window function + CTE)
-- ---------------------------------------------------------------------
WITH member_activity AS (
    SELECT
        member_id,
        COUNT(*) AS total_borrows
    FROM BorrowRecords
    GROUP BY member_id
)
SELECT
    m.member_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    ma.total_borrows,
    DENSE_RANK() OVER (ORDER BY ma.total_borrows DESC) AS activity_rank
FROM member_activity ma
JOIN Members m ON ma.member_id = m.member_id
ORDER BY activity_rank;

-- ---------------------------------------------------------------------
-- 9. VIEW: Quick-access overdue books dashboard
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW Overdue_Books_View AS
SELECT
    br.record_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    m.phone,
    b.title,
    br.due_date,
    DATEDIFF(CURDATE(), br.due_date) AS days_overdue
FROM BorrowRecords br
JOIN Members m ON br.member_id = m.member_id
JOIN Books b   ON br.book_id = b.book_id
WHERE br.status = 'Overdue';

-- Usage:  SELECT * FROM Overdue_Books_View;

-- ---------------------------------------------------------------------
-- 10. TRIGGER: Auto-decrement available_copies when a book is borrowed
-- ---------------------------------------------------------------------
DELIMITER $$

CREATE TRIGGER trg_after_borrow
AFTER INSERT ON BorrowRecords
FOR EACH ROW
BEGIN
    UPDATE Books
    SET available_copies = available_copies - 1
    WHERE book_id = NEW.book_id;
END$$

-- ---------------------------------------------------------------------
-- 11. TRIGGER: Auto-increment available_copies when a book is returned
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_after_return
AFTER UPDATE ON BorrowRecords
FOR EACH ROW
BEGIN
    IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
        UPDATE Books
        SET available_copies = available_copies + 1
        WHERE book_id = NEW.book_id;

        UPDATE BorrowRecords
        SET status = 'Returned'
        WHERE record_id = NEW.record_id;
    END IF;
END$$

-- ---------------------------------------------------------------------
-- 12. STORED PROCEDURE: Issue a book to a member
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_issue_book (
    IN p_book_id   INT,
    IN p_member_id INT,
    IN p_staff_id  INT,
    IN p_days      INT
)
BEGIN
    DECLARE v_available INT;

    SELECT available_copies INTO v_available
    FROM Books WHERE book_id = p_book_id;

    IF v_available > 0 THEN
        INSERT INTO BorrowRecords (book_id, member_id, staff_id, borrow_date, due_date, status)
        VALUES (p_book_id, p_member_id, p_staff_id, CURDATE(), DATE_ADD(CURDATE(), INTERVAL p_days DAY), 'Borrowed');
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No copies available for this book.';
    END IF;
END$$

-- ---------------------------------------------------------------------
-- 13. STORED PROCEDURE: Return a book and calculate fine (₹10/day late)
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_return_book (
    IN p_record_id INT
)
BEGIN
    DECLARE v_due_date DATE;
    DECLARE v_days_late INT;
    DECLARE v_fine DECIMAL(8,2);

    SELECT due_date INTO v_due_date
    FROM BorrowRecords WHERE record_id = p_record_id;

    UPDATE BorrowRecords
    SET return_date = CURDATE(), status = 'Returned'
    WHERE record_id = p_record_id;

    SET v_days_late = DATEDIFF(CURDATE(), v_due_date);

    IF v_days_late > 0 THEN
        SET v_fine = v_days_late * 10;
        INSERT INTO Fines (record_id, amount, paid_status)
        VALUES (p_record_id, v_fine, 'Unpaid');
    END IF;
END$$

DELIMITER ;

-- Usage examples:
-- CALL sp_issue_book(7, 3, 2, 14);
-- CALL sp_return_book(9);
