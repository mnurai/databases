--1.1
-- Create table: employees
CREATE TABLE employees (
emp_id INT PRIMARY KEY,
emp_name VARCHAR(50),
dept_id INT,
salary DECIMAL(10, 2)
);
-- Create table: departments
CREATE TABLE departments (
dept_id INT PRIMARY KEY,
dept_name VARCHAR(50),
location VARCHAR(50)
);
-- Create table: projects
CREATE TABLE projects (
project_id INT PRIMARY KEY,
project_name VARCHAR(50),
dept_id INT,
budget DECIMAL(10, 2)
);

--1.2
-- Insert data into employees
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 102, 60000),
(3, 'Mike Johnson', 101, 55000),
(4, 'Sarah Williams', 103, 65000),
(5, 'Tom Brown', NULL, 45000);
-- Insert data into departments
INSERT INTO departments (dept_id, dept_name, location) VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Finance', 'Building C'),
(104, 'Marketing', 'Building D');
-- Insert data into projects
INSERT INTO projects (project_id, project_name, dept_id,
budget) VALUES
(1, 'Website Redesign', 101, 100000),
(2, 'Employee Training', 102, 50000),
(3, 'Budget Analysis', 103, 75000),
(4, 'Cloud Migration', 101, 150000),
(5, 'AI Research', NULL, 200000);

--2.1
SELECT e.emp_name, d.dept_name
FROM employees e CROSS JOIN departments d;
--result contains 20 rows

--2.2
--a
SELECT e.emp_name, d.dept_name
FROM employees e, departments d;
--b
SELECT e.emp_name, d.dept_name
FROM employees e INNER JOIN departments d ON TRUE;

--2.3
SELECT e.emp_name, p.project_name
FROM employees e CROSS JOIN projects p;

--3.1
SELECT e.emp_name, d.dept_name, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;
--4 rows. His dept_id is NULL

--3.2
SELECT emp_name, dept_name, location
FROM employees
INNER JOIN departments USING (dept_id);
--The USING clause results in only one copy of the join column

--3.3
SELECT emp_name, dept_name, location
FROM employees
NATURAL INNER JOIN departments;

--3.4
SELECT e.emp_name, d.dept_name, p.project_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN projects p ON d.dept_id = p.dept_id;

--4.1
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;
--Tom Brown appears with his emp_dept showing NULL (because he has no department)

--4.2
SELECT emp_name, dept_id, dept_name
FROM employees
LEFT JOIN departments USING (dept_id);

--4.3
SELECT e.emp_name, e.dept_id
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;

--4.4
SELECT d.dept_name, COUNT(e.emp_id) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;

--5.1
SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

--5.2
SELECT e.emp_name, d.dept_name
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id;

--5.3
SELECT d.dept_name, d.location
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;

--6.1
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id;
--NULL on the left side: departments without any employees
--NULL on the right side: employees without any departments

--6.2
SELECT d.dept_name, p.project_name, p.budget
FROM departments d
FULL JOIN projects p ON d.dept_id = p.dept_id;

--6.3
SELECT
  CASE
    WHEN e.emp_id IS NULL THEN 'Department without employees'
    WHEN d.dept_id IS NULL THEN 'Employee without department'
    ELSE 'Matched'
  END AS record_status,
  e.emp_name,
  d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL;

--7.1
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';

--7.2
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
--Query 1 (ON clause): Applies the filter BEFORE the join, so all employees are included, but
--only departments in Building A are matched.
--Query 2 (WHERE clause): Applies the filter AFTER the join, so employees are excluded if
--their department is not in Building A

--7.3
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';

SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
--no differences. Filtering in the ON clause or the WHERE clause produces the same
-- effect since non-matching rows are excluded in both cases

--8.1
SELECT
  d.dept_name,
  e.emp_name,
  e.salary,
  p.project_name,
  p.budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;

--8.2
ALTER TABLE employees ADD COLUMN manager_id INT;

UPDATE employees SET manager_id = 3 WHERE emp_id IN (1, 2, 4, 5);
UPDATE employees SET manager_id = NULL WHERE emp_id = 3;

SELECT
  e.emp_name AS employee,
  m.emp_name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;

--8.3
SELECT d.dept_name, AVG(e.salary) AS avg_salary
FROM departments d
INNER JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;

--Questions
--1. What is the difference between INNER JOIN and LEFT JOIN?
-- INNER JOIN returns only matching values, LEFT JOIN returns values from the left table
-- and matching values from the right table

--2. When would you use CROSS JOIN in a practical scenario?
-- when all combination of rows are needed, like pairing

--3. Explain why the position of a filter condition (ON vs WHERE) matters for outer
-- joins but not for inner joins.
--For inner joins, the position of the filter does not change the result since only
-- matched rows are returned regardless, and both clauses filter the matched rows

--4. What is the result of: SELECT COUNT(*) FROM table1 CROSS JOIN table2
-- if table1 has 5 rows and table2 has 10 rows?
-- 5*10=50

--5. How does NATURAL JOIN determine which columns to join on?
--automatically joins tables using all columns with the same names in both tables

--6. What are the potential risks of using NATURAL JOIN?
-- unexpected joins if tables share columns not intended for joining,
-- leading to incorrect or confusing results

--7. Convert this LEFT JOIN to a RIGHT JOIN: SELECT * FROM A LEFT JOIN B ON A.id = B.id
-- SELECT * FROM B RIGHT JOIN A ON A.id = B.id;

--8. When should you use FULL OUTER JOIN instead of other join types?
--when you need to retain all rows from both tables


--Additional challenges
--1
SELECT e.emp_name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
UNION
SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

--2
SELECT DISTINCT e.emp_name
FROM employees e
JOIN projects p ON e.dept_id = p.dept_id
GROUP BY e.emp_name, e.dept_id
HAVING COUNT(DISTINCT p.project_id) > 1;

--3
SELECT
  e.emp_name AS employee,
  m.emp_name AS manager,
  mm.emp_name AS managers_manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id
LEFT JOIN employees mm ON m.manager_id = mm.emp_id;

--4
SELECT e1.emp_name AS employee1, e2.emp_name AS employee2, e1.dept_id
FROM employees e1
JOIN employees e2 ON e1.dept_id = e2.dept_id AND e1.emp_id <> e2.emp_id
ORDER BY e1.dept_id, e1.emp_name, e2.emp_name;



