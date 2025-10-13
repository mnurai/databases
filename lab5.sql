--Nuray Mukhambet, 24B0318895
--1.1
CREATE TABLE employees (
    employee_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC CHECK (salary > 0)
);

--1.2
CREATE TABLE products_catalog (
    product_id INTEGER,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0 AND
        discount_price > 0 AND
        discount_price < regular_price
    )
);

--1.3
CREATE TABLE bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)
);

--1.4
--1
INSERT INTO employees (employee_id, first_name, last_name, age, salary) VALUES
(1, 'Alice', 'Smith', 25, 50000),
(2, 'Bob', 'Johnson', 60, 120000);

INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price) VALUES
(101, 'Laptop', 1000, 900),
(102, 'Headphones', 200, 150);

INSERT INTO bookings (check_in_date, check_out_date, num_guests) VALUES
('2025-10-20', '2025-10-22', 2),
('2025-11-01', '2025-11-05', 10);
--2
INSERT INTO employees (employee_id, first_name, last_name, age, salary) VALUES
(3, 'Charlie', 'Brown', 17, 40000); --age less than 18
INSERT INTO employees (employee_id, first_name, last_name, age, salary) VALUES
(4, 'Dana', 'White', 30, 0); --salary less than or equal to 0

INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price) VALUES
(103, 'Monitor', 300, 350); -- discount_price >= regular_price
INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price) VALUES
(104, 'USB Cable', 0, 5); -- regular_price <= 0
INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price) VALUES
(105, 'Keyboard', 50, 0); -- discount_price <= 0

INSERT INTO bookings (check_in_date, check_out_date, num_guests) VALUES
('2025-12-01', '2025-12-03', 0); -- num_guests out of range (0)
INSERT INTO bookings (check_in_date, check_out_date, num_guests) VALUES
('2025-12-10', '2025-12-08', 3); -- check_out_date before check_in_date

--2.1
CREATE TABLE customers (
    customer_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

--2.2
CREATE TABLE inventory (
    item_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

--2.3
--1
INSERT INTO customers (customer_id, email, phone, registration_date) VALUES
(1, 'alice@example.com', '123-456', '2025-01-01'),
(2, 'bob@example.com', NULL, '2025-02-01');
--2
-- customer_id is NULL
INSERT INTO customers (customer_id, email, phone, registration_date) VALUES
(NULL, 'charlie@example.com', '789-101', '2025-03-01');
--3
-- Insert with NULL value in phone (nullable column)
INSERT INTO customers (customer_id, email, phone, registration_date) VALUES
(10, 'nullphone@example.com', NULL, '2025-10-13');

--3.1 & 3.3 (modified)
CREATE TABLE users (
    user_id INTEGER,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    created_at TIMESTAMP,
    CONSTRAINT unique_username UNIQUE (username),
    CONSTRAINT unique_email UNIQUE (email)
);

--3.2
CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    UNIQUE (student_id, course_code, semester)
);

--3.3
INSERT INTO users (user_id, username, email, created_at) VALUES
(1, 'user1', 'user1@example.com', '2025-10-13 08:00:00'),
(2, 'user2', 'user2@example.com', '2025-10-13 09:00:00');
INSERT INTO users (user_id, username, email, created_at) VALUES
(3, 'user1', 'uniqueemail@example.com', '2025-10-13 10:00:00');
INSERT INTO users (user_id, username, email, created_at) VALUES
(4, 'uniqueuser', 'user2@example.com', '2025-10-13 11:00:00');

--4.1
CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);
--1
INSERT INTO departments (dept_id, dept_name, location) VALUES
(1, 'Human Resources', 'Building A');
INSERT INTO departments (dept_id, dept_name, location) VALUES
(1, 'Marketing', 'Building D');
--2
INSERT INTO departments (dept_id, dept_name, location) VALUES
(NULL, 'Legal', 'Building E');

--4.2
CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);

--4.3
--1
--PRIMARY KEY and UNIQUE constraints both enforce uniqueness, but PRIMARY KEYs are stricter
-- (no NULLs, single per table) and used as the main row identifier. UNIQUE constraints allow flexibility
-- with NULLs and multiple uniqueness rules per table depending on data needs
--2
--single-column PRIMARY KEY when one attribute uniquely identifies a row
--composite PRIMARY KEY when uniqueness depends on multiple columns together
--3
--only one PRIMARY KEY is allowed because it defines the main identifier for rows
--multiple UNIQUE constraints are allowed to enforce uniqueness on other columns without being the main key

--5.1
CREATE TABLE employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);
--1
INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date) VALUES
(1, 'Alice', 1, '2025-01-15');
--2
INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date) VALUES
(3, 'Charlie', 999, '2025-03-01');

--5.2
CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(author_id),
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);

INSERT INTO authors (author_id, author_name, country) VALUES
(1, 'George Orwell', 'United Kingdom'),
(2, 'Haruki Murakami', 'Japan'),
(3, 'Isabel Allende', 'Chile');

INSERT INTO publishers (publisher_id, publisher_name, city) VALUES
(1, 'Penguin Random House', 'New York'),
(2, 'HarperCollins', 'London'),
(3, 'Macmillan Publishers', 'London');

INSERT INTO books (book_id, title, author_id, publisher_id, publication_year, isbn) VALUES
(1, '1984', 1, 1, 1949, '9780451524935'),
(2, 'Kafka on the Shore', 2, 2, 2002, '9781400079278'),
(3, 'The House of the Spirits', 3, 3, 1982, '9780553383805');

--5.3
CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER,
    CONSTRAINT fk_category FOREIGN KEY (category_id)
        REFERENCES categories(category_id) ON DELETE RESTRICT NOT DEFERRABLE
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity INTEGER CHECK (quantity > 0)
);

INSERT INTO categories (category_id, category_name) VALUES
(1, 'Electronics');
INSERT INTO products_fk (product_id, product_name, category_id) VALUES
(101, 'Laptop', 1);
INSERT INTO orders (order_id, order_date) VALUES
(201, '2025-10-13');
INSERT INTO order_items (item_id, order_id, product_id, quantity) VALUES
(301, 201, 101, 2);

--1
DELETE FROM categories WHERE category_id = 1;
--fail with an error due to ON DELETE RESTRICT because
-- category 1 is referenced by product 101 in products_fk
--2
DELETE FROM orders WHERE order_id = 201;
--all related order_items with order_id 201 (item 301) will be automatically deleted
-- due to ON DELETE CASCADE

--6.1
--wrote 6 near each table name, so that they are unique
-- (tables with the same name were created before in this lab)
CREATE TABLE customers6 (
    customer_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE products6 (
    product_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC NOT NULL CHECK (price >= 0),
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0)
);

CREATE TABLE orders6 (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    order_date DATE NOT NULL,
    total_amount NUMERIC NOT NULL CHECK (total_amount >= 0),
    status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
    CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES customers6(customer_id) ON DELETE CASCADE
);

CREATE TABLE order_details6 (
    order_detail_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price >= 0),
    CONSTRAINT fk_order FOREIGN KEY (order_id) REFERENCES orders6(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES products6(product_id) ON DELETE RESTRICT
);
