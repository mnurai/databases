-- 1
CREATE DATABASE advanced_lab;

CREATE TABLE employees (
    emp_id     SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name  VARCHAR(50),
    department VARCHAR(100),
    salary     INT,
    hire_date  DATE,
    status     VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id    SERIAL PRIMARY KEY,
    dept_name  VARCHAR(100),
    budget     INT,
    manager_id INT
);

CREATE TABLE projects (
    project_id   SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    dept_id      INT,
    start_date   DATE,
    end_date     DATE,
    budget       INT
);


-- 2
-- not insert into emp_id manually when it is SERIAL; the database generates it
INSERT INTO employees (first_name, last_name, department)
VALUES
    ('John',  'Doe',      'Finance'),
    ('Anna',  'Smith',    'HR'),
    ('David', 'Johnson',  'IT');


-- 3
--salary does not have a default, it will become NULL if you use DEFAULT
INSERT INTO employees
    (first_name, last_name, department, salary, hire_date, status)
VALUES
    ('Emily', 'Brown', 'Marketing', DEFAULT, '2025-09-27', DEFAULT);


-- 4
INSERT INTO departments (dept_name, budget, manager_id)
VALUES
    ('Finance',   500000, 1),
    ('Human Resources', 200000, 2),
    ('Information Technology', 750000, 3);


-- 5
INSERT INTO employees
    (first_name, last_name, department, salary, hire_date)
VALUES
    ('Michael', 'Green', 'Finance', 50000 * 1.1, CURRENT_DATE);


-- 6
CREATE TEMPORARY TABLE temp_employees AS SELECT * FROM employees
WHERE department = 'IT';


-- 7
UPDATE employees SET salary = salary * 1.1;


-- 8
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000 AND hire_date < '2020-01-01';


-- 9
-- works as if/else
UPDATE employees
SET department =
    CASE
        WHEN salary > 80000 THEN 'Management'
        WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
        ELSE 'Junior'
    END;


-- 10
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';


-- 11
UPDATE departments d
SET budget = (
    SELECT AVG(e.salary) * 1.2
    FROM employees e
    WHERE e.department = d.dept_name
);


-- 12
UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';


-- 13
DELETE FROM employees
WHERE status = 'Terminated';


-- 14
DELETE FROM employees
WHERE salary < 40000 AND hire_date > '2023-01-01' AND department IS NULL;


-- 15
DELETE FROM departments d
WHERE d.dept_name NOT IN (
    SELECT DISTINCT e.department
    FROM employees e
    WHERE e.department IS NOT NULL
);


-- 16
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;


-- 17
INSERT INTO employees (first_name, last_name, salary, department, hire_date)
VALUES ('Alice', 'Brown', NULL, NULL, CURRENT_DATE);


-- 18
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;


-- 19
DELETE FROM employees
WHERE salary IS NULL OR department IS NULL;


-- 20
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('John', 'Doe', 'IT', 60000, CURRENT_DATE)
RETURNING emp_id,
       first_name || ' ' || last_name AS full_name;


-- 21
UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id,
       salary - 5000 AS old_salary,
       salary        AS new_salary;


-- 22
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;


-- 23
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Jane', 'Smith', 'IT', 55000, CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1
    FROM employees
    WHERE first_name = 'Jane'
      AND last_name  = 'Smith'
);


-- 24
UPDATE employees e
SET salary = salary *
    CASE
        WHEN d.budget > 100000 THEN 1.10   -- 10% raise
        ELSE 1.05                         -- 5% raise
    END
FROM departments d
WHERE e.department = d.dept_name;


-- 25
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES
  ('Alice',   'Brown',   'IT',       60000, CURRENT_DATE),
  ('Bob',     'Smith',   'Sales',    55000, CURRENT_DATE),
  ('Charlie', 'Johnson', 'HR',       50000, CURRENT_DATE),
  ('Diana',   'Lee',     'Finance',  70000, CURRENT_DATE),
  ('Ethan',   'Clark',   'IT',       65000, CURRENT_DATE);

UPDATE employees
SET salary = salary * 1.10
WHERE (first_name, last_name) IN (
    ('Alice','Brown'),
    ('Bob','Smith'),
    ('Charlie','Johnson'),
    ('Diana','Lee'),
    ('Ethan','Clark')
);


-- 26
CREATE TABLE employee_archive
(LIKE employees INCLUDING ALL); -- also copies indexes, defaults, constraints where possible

INSERT INTO employee_archive
SELECT *
FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';


-- 27
UPDATE projects p
SET end_date = end_date + INTERVAL '30 days'
WHERE p.budget > 50000
  AND p.dept_id IN (
        SELECT d.dept_id
        FROM departments d
        JOIN employees e
          ON e.department = d.dept_name
        GROUP BY d.dept_id
        HAVING COUNT(e.emp_id) > 3
      );