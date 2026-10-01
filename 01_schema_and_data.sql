-- =====================================================================
-- LIBRARY MANAGEMENT SYSTEM - DATABASE SCHEMA & SAMPLE DATA
-- Author: Iqra
-- Description: A relational database for managing books, members,
--              staff, borrowing transactions, and fines in a library.
-- DBMS: MySQL 8.0+ (compatible with most SQL engines with minor tweaks)
-- =====================================================================

DROP DATABASE IF EXISTS library_management_system;
CREATE DATABASE library_management_system;
USE library_management_system;

-- ---------------------------------------------------------------------
-- TABLE: Publishers
-- ---------------------------------------------------------------------
CREATE TABLE Publishers (
    publisher_id   INT PRIMARY KEY AUTO_INCREMENT,
    name           VARCHAR(100) NOT NULL,
    address        VARCHAR(150),
    phone          VARCHAR(15),
    email          VARCHAR(100)
);

-- ---------------------------------------------------------------------
-- TABLE: Categories
-- ---------------------------------------------------------------------
CREATE TABLE Categories (
    category_id    INT PRIMARY KEY AUTO_INCREMENT,
    category_name  VARCHAR(50) NOT NULL UNIQUE
);

-- ---------------------------------------------------------------------
-- TABLE: Authors
-- ---------------------------------------------------------------------
CREATE TABLE Authors (
    author_id      INT PRIMARY KEY AUTO_INCREMENT,
    first_name     VARCHAR(50) NOT NULL,
    last_name      VARCHAR(50) NOT NULL,
    nationality    VARCHAR(50)
);

-- ---------------------------------------------------------------------
-- TABLE: Books
-- ---------------------------------------------------------------------
CREATE TABLE Books (
    book_id         INT PRIMARY KEY AUTO_INCREMENT,
    title           VARCHAR(150) NOT NULL,
    isbn            VARCHAR(20) UNIQUE,
    publisher_id    INT,
    category_id     INT,
    published_year  YEAR,
    total_copies    INT NOT NULL DEFAULT 1,
    available_copies INT NOT NULL DEFAULT 1,
    price           DECIMAL(8,2),
    CONSTRAINT fk_books_publisher FOREIGN KEY (publisher_id) REFERENCES Publishers(publisher_id),
    CONSTRAINT fk_books_category  FOREIGN KEY (category_id)  REFERENCES Categories(category_id),
    CONSTRAINT chk_copies CHECK (available_copies >= 0 AND available_copies <= total_copies)
);

-- ---------------------------------------------------------------------
-- TABLE: Book_Authors (Many-to-Many bridge table)
-- ---------------------------------------------------------------------
CREATE TABLE Book_Authors (
    book_id     INT,
    author_id   INT,
    PRIMARY KEY (book_id, author_id),
    CONSTRAINT fk_ba_book   FOREIGN KEY (book_id)   REFERENCES Books(book_id)   ON DELETE CASCADE,
    CONSTRAINT fk_ba_author FOREIGN KEY (author_id) REFERENCES Authors(author_id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- TABLE: Members
-- ---------------------------------------------------------------------
CREATE TABLE Members (
    member_id       INT PRIMARY KEY AUTO_INCREMENT,
    first_name      VARCHAR(50) NOT NULL,
    last_name       VARCHAR(50) NOT NULL,
    email           VARCHAR(100) UNIQUE,
    phone           VARCHAR(15),
    address         VARCHAR(150),
    membership_date DATE NOT NULL,
    membership_type ENUM('Basic','Premium','Student') DEFAULT 'Basic'
);

-- ---------------------------------------------------------------------
-- TABLE: Staff
-- ---------------------------------------------------------------------
CREATE TABLE Staff (
    staff_id    INT PRIMARY KEY AUTO_INCREMENT,
    first_name  VARCHAR(50) NOT NULL,
    last_name   VARCHAR(50) NOT NULL,
    email       VARCHAR(100) UNIQUE,
    phone       VARCHAR(15),
    role        VARCHAR(50),
    hire_date   DATE,
    salary      DECIMAL(10,2)
);

-- ---------------------------------------------------------------------
-- TABLE: BorrowRecords
-- ---------------------------------------------------------------------
CREATE TABLE BorrowRecords (
    record_id    INT PRIMARY KEY AUTO_INCREMENT,
    book_id      INT NOT NULL,
    member_id    INT NOT NULL,
    staff_id     INT,
    borrow_date  DATE NOT NULL,
    due_date     DATE NOT NULL,
    return_date  DATE NULL,
    status       ENUM('Borrowed','Returned','Overdue') DEFAULT 'Borrowed',
    CONSTRAINT fk_br_book   FOREIGN KEY (book_id)   REFERENCES Books(book_id)   ON UPDATE CASCADE,
    CONSTRAINT fk_br_member FOREIGN KEY (member_id) REFERENCES Members(member_id) ON UPDATE CASCADE,
    CONSTRAINT fk_br_staff  FOREIGN KEY (staff_id)  REFERENCES Staff(staff_id)  ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_dates CHECK (due_date >= borrow_date)
);

-- ---------------------------------------------------------------------
-- TABLE: Fines
-- ---------------------------------------------------------------------
CREATE TABLE Fines (
    fine_id     INT PRIMARY KEY AUTO_INCREMENT,
    record_id   INT NOT NULL,
    amount      DECIMAL(8,2) NOT NULL,
    paid_status ENUM('Paid','Unpaid') DEFAULT 'Unpaid',
    paid_date   DATE NULL,
    CONSTRAINT fk_fines_record FOREIGN KEY (record_id) REFERENCES BorrowRecords(record_id) ON DELETE CASCADE,
    CONSTRAINT chk_amount CHECK (amount >= 0)
);

-- =====================================================================
-- INDEXES (query performance on frequently filtered/joined columns)
-- =====================================================================
CREATE INDEX idx_books_category   ON Books(category_id);
CREATE INDEX idx_books_publisher  ON Books(publisher_id);
CREATE INDEX idx_books_title      ON Books(title);
CREATE INDEX idx_br_book          ON BorrowRecords(book_id);
CREATE INDEX idx_br_member        ON BorrowRecords(member_id);
CREATE INDEX idx_br_status        ON BorrowRecords(status);
CREATE INDEX idx_br_due_date      ON BorrowRecords(due_date);
CREATE INDEX idx_fines_status     ON Fines(paid_status);

-- =====================================================================
-- SAMPLE DATA
-- =====================================================================

INSERT INTO Publishers (name, address, phone, email) VALUES
('Penguin Random House', 'Mumbai, India', '9820011223', 'contact@penguin.in'),
('HarperCollins', 'Delhi, India', '9820011224', 'info@harpercollins.in'),
('O''Reilly Media', 'California, USA', '9820011225', 'support@oreilly.com'),
('Bloomsbury', 'London, UK', '9820011226', 'contact@bloomsbury.co.uk'),
('Manning Publications', 'New York, USA', '9820011227', 'sales@manning.com');

INSERT INTO Categories (category_name) VALUES
('Fiction'), ('Non-Fiction'), ('Science & Technology'),
('Business'), ('Biography'), ('Children'), ('Self-Help');

INSERT INTO Authors (first_name, last_name, nationality) VALUES
('J.K.', 'Rowling', 'British'),
('Yuval Noah', 'Harari', 'Israeli'),
('James', 'Clear', 'American'),
('Chimamanda Ngozi', 'Adichie', 'Nigerian'),
('Robert C.', 'Martin', 'American'),
('Agatha', 'Christie', 'British'),
('Wes', 'McKinney', 'American'),
('Paulo', 'Coelho', 'Brazilian');

INSERT INTO Books (title, isbn, publisher_id, category_id, published_year, total_copies, available_copies, price) VALUES
('Harry Potter and the Sorcerer''s Stone', '9780747532699', 1, 6, 1997, 6, 4, 499.00),
('Sapiens: A Brief History of Humankind', '9780062316097', 2, 2, 2011, 5, 3, 599.00),
('Atomic Habits', '9780735211292', 1, 7, 2018, 8, 5, 399.00),
('Americanah', '9780307455925', 4, 1, 2013, 4, 4, 450.00),
('Clean Code', '9780132350884', 3, 3, 2008, 5, 2, 899.00),
('Murder on the Orient Express', '9780062693662', 2, 1, 1934, 3, 1, 350.00),
('Python for Data Analysis', '9781491957660', 3, 3, 2017, 6, 6, 799.00),
('The Alchemist', '9780061122415', 4, 1, 1988, 7, 5, 299.00),
('Homo Deus', '9781910701881', 2, 2, 2016, 4, 4, 550.00),
('The 7 Habits of Highly Effective People', '9780743269513', 5, 7, 1989, 5, 3, 425.00);

INSERT INTO Book_Authors (book_id, author_id) VALUES
(1,1), (2,2), (3,3), (4,4), (5,5), (6,6), (7,7), (8,8), (9,2), (10,3);

INSERT INTO Members (first_name, last_name, email, phone, address, membership_date, membership_type) VALUES
('Aarav', 'Shah', 'aarav.shah@email.com', '9812345601', 'Andheri, Mumbai', '2023-01-15', 'Premium'),
('Priya', 'Nair', 'priya.nair@email.com', '9812345602', 'Bandra, Mumbai', '2023-03-22', 'Student'),
('Rohan', 'Mehta', 'rohan.mehta@email.com', '9812345603', 'Dadar, Mumbai', '2022-11-05', 'Basic'),
('Sneha', 'Verma', 'sneha.verma@email.com', '9812345604', 'Powai, Mumbai', '2024-02-10', 'Student'),
('Karan', 'Kapoor', 'karan.kapoor@email.com', '9812345605', 'Thane, Mumbai', '2023-07-30', 'Premium'),
('Isha', 'Joshi', 'isha.joshi@email.com', '9812345606', 'Kurla, Mumbai', '2024-05-18', 'Basic'),
('Vivaan', 'Rao', 'vivaan.rao@email.com', '9812345607', 'Chembur, Mumbai', '2022-08-12', 'Premium'),
('Ananya', 'Desai', 'ananya.desai@email.com', '9812345608', 'Vashi, Navi Mumbai', '2023-09-25', 'Student');

INSERT INTO Staff (first_name, last_name, email, phone, role, hire_date, salary) VALUES
('Meera', 'Iyer', 'meera.iyer@library.com', '9900011122', 'Librarian', '2019-06-01', 35000.00),
('Arjun', 'Reddy', 'arjun.reddy@library.com', '9900011123', 'Assistant Librarian', '2021-02-15', 25000.00),
('Divya', 'Menon', 'divya.menon@library.com', '9900011124', 'Front Desk', '2022-09-10', 20000.00);

INSERT INTO BorrowRecords (book_id, member_id, staff_id, borrow_date, due_date, return_date, status) VALUES
(1, 1, 1, '2025-01-05', '2025-01-19', '2025-01-18', 'Returned'),
(2, 2, 2, '2025-01-10', '2025-01-24', '2025-01-26', 'Returned'),
(3, 3, 1, '2025-02-01', '2025-02-15', NULL, 'Overdue'),
(5, 4, 3, '2025-02-05', '2025-02-19', '2025-02-17', 'Returned'),
(6, 5, 2, '2025-02-10', '2025-02-24', NULL, 'Overdue'),
(1, 6, 1, '2025-03-01', '2025-03-15', NULL, 'Borrowed'),
(4, 7, 3, '2025-03-05', '2025-03-19', '2025-03-19', 'Returned'),
(10, 8, 2, '2025-03-10', '2025-03-24', NULL, 'Borrowed'),
(3, 2, 1, '2025-03-12', '2025-03-26', NULL, 'Borrowed'),
(9, 1, 3, '2025-03-15', '2025-03-29', '2025-03-28', 'Returned');

INSERT INTO Fines (record_id, amount, paid_status, paid_date) VALUES
(2, 20.00, 'Paid', '2025-01-27'),
(3, 150.00, 'Unpaid', NULL),
(5, 100.00, 'Unpaid', NULL);
