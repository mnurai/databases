CREATE TABLE accounts (
 id SERIAL PRIMARY KEY,
 name VARCHAR(100) NOT NULL,
 balance DECIMAL(10, 2) DEFAULT 0.00
);
CREATE TABLE products (
 id SERIAL PRIMARY KEY,
 shop VARCHAR(100) NOT NULL,
 product VARCHAR(100) NOT NULL,
 price DECIMAL(10, 2) NOT NULL
);
-- Insert test data
INSERT INTO accounts (name, balance) VALUES
 ('Alice', 1000.00),
 ('Bob', 500.00),
 ('Wally', 750.00);
INSERT INTO products (shop, product, price) VALUES
 ('Joe''s Shop', 'Coke', 2.50),
 ('Joe''s Shop', 'Pepsi', 3.00);

-- task 1
BEGIN;
UPDATE accounts SET balance = balance - 100.00
 WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100.00
 WHERE name = 'Bob';
COMMIT;
--a) Alice 900 and Bob 600
--b) to ensure data integrity and maintain the ACID properties
--c) second UPDATE never runs. The total money in the system would drop from 1500 to 1400

--task 2
BEGIN;
UPDATE accounts SET balance = balance - 500.00
 WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';
-- Oops! Wrong amount, let's undo
ROLLBACK;
SELECT * FROM accounts WHERE name = 'Alice';
--a) 500
--b) 1000
--c) error handling, program logic, constraint violations

--task 3
BEGIN;
UPDATE accounts SET balance = balance - 100.00
 WHERE name = 'Alice';
SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100.00
 WHERE name = 'Bob';
-- Oops, should transfer to Wally instead
ROLLBACK TO my_savepoint;
UPDATE accounts SET balance = balance + 100.00
 WHERE name = 'Wally';
COMMIT;
--a) alice 900, bob 500, wally 850
--b) yes, was equal to 600 temporarily. however in the final it was undid
--c) partial rollback. allows to undo some parts or remove fully

--task 4
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to make changes and COMMIT
-- Then re-run:
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;
BEGIN;
DELETE FROM products WHERE shop = 'Joe''s Shop';
INSERT INTO products (shop, product, price)
 VALUES ('Joe''s Shop', 'Fanta', 3.50);
COMMIT;

BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to make changes and COMMIT
-- Then re-run:
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;
BEGIN;
DELETE FROM products WHERE shop = 'Joe''s Shop';
INSERT INTO products (shop, product, price)
 VALUES ('Joe''s Shop', 'Fanta', 3.50);
COMMIT;
--a) Before Terminal 2 commits: Terminal 1 sees the initial products: Coke (2.50) and Pepsi (3.00)
--After Terminal 2 commits: Terminal 1 sees the newly committed product: Fanta (3.50)
--b) the exact same data in both SELECT statements: Coke (2.50) and Pepsi (3.00)
--c) READ COMMITTED: data can change between queries, SERIALIZABLE: data stays the same during the whole transaction

--task 5
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM products
 WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2
SELECT MAX(price), MIN(price) FROM products
 WHERE shop = 'Joe''s Shop';
COMMIT;

BEGIN;
INSERT INTO products (shop, product, price)
 VALUES ('Joe''s Shop', 'Sprite', 4.00);
COMMIT;
--a) yes
--b)within a single transaction, two identical SELECT queries are executed, and the second query returns
-- a different set of rows (a phantom) than the first
--c) SERIALIZABLE

--task 6
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to UPDATE but NOT commit
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to ROLLBACK
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

BEGIN;
UPDATE products SET price = 99.99
 WHERE product = 'Fanta';
-- Wait here (don't commit yet)
-- Then:
ROLLBACK;

--a)yes
--b) one transaction reads data that has been modified by another transaction, but has not yet been committed
--c) it violates the ACID property of Isolation


--independent exercise
--1
UPDATE accounts
SET balance = balance - 200.00
WHERE name = 'Bob' AND balance >= 200.00;
UPDATE accounts SET balance = balance + 200.00 WHERE name = 'Wally';

--2
BEGIN;
INSERT INTO products (shop, product, price)
VALUES ('Demo Shop', 'Product A', 10.00);
SAVEPOINT S1;
SELECT 'State After S1 (Product A: 10.00)' AS step, product, price FROM products WHERE shop = 'Demo Shop';
UPDATE products
SET price = 15.00
WHERE product = 'Product A';
SAVEPOINT S2;
SELECT 'State After S2 (Product A: 15.00)' AS step, product, price FROM products WHERE shop = 'Demo Shop';
DELETE FROM products
WHERE product = 'Product A';
SELECT 'State After Delete (Product A deleted)' AS step, product, price FROM products WHERE shop = 'Demo Shop';
ROLLBACK TO S1;
SELECT 'State After ROLLBACK TO S1' AS step, product, price FROM products WHERE shop = 'Demo Shop';
COMMIT;
SELECT 'FINAL COMMITTED STATE' AS step, shop, product, price FROM products WHERE shop = 'Demo Shop';

--3
--Key Difference: SERIALIZABLE uses locks (or transactional memory) to prevent one transaction from
-- overwriting the read-modify-write cycle of another, thereby avoiding the Lost Update anomaly

BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE name = 'Bob';
UPDATE accounts SET balance = 200.00 WHERE name = 'Bob';
COMMIT;

BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT balance FROM accounts WHERE name = 'Bob';
UPDATE accounts SET balance = balance - 300.00 WHERE name = 'Bob';
COMMIT;

--4
DELETE FROM products WHERE shop = 'Test Shop';
INSERT INTO products (shop, product, price) VALUES
('Test Shop', 'High Priced Item', 20.00),
('Test Shop', 'Low Priced Item', 10.00);

BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT MIN(price) AS Sallys_Min FROM products WHERE shop = 'Test Shop';

BEGIN;
UPDATE products SET price = 5.00 WHERE price = 20.00 AND shop = 'Test Shop';
UPDATE products SET price = 25.00 WHERE price = 10.00 AND shop = 'Test Shop';
COMMIT;

SELECT MAX(price) AS Sallys_Max FROM products WHERE shop = 'Test Shop';
COMMIT;

BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT MIN(price) AS Sallys_Min FROM products WHERE shop = 'Test Shop';

BEGIN;
UPDATE products SET price = 20.00 WHERE price = 5.00 AND shop = 'Test Shop';
UPDATE products SET price = 10.00 WHERE price = 25.00 AND shop = 'Test Shop';
COMMIT;

BEGIN;
UPDATE products SET price = 5.00 WHERE price = 20.00 AND shop = 'Test Shop';
UPDATE products SET price = 25.00 WHERE price = 10.00 AND shop = 'Test Shop';
COMMIT;

SELECT MAX(price) AS Sallys_Max FROM products WHERE shop = 'Test Shop';
COMMIT;


--5
--questions
--1 Atomicity: All steps succeed or none
--  Consistency: Transaction moves DB from one valid state to another
--  Isolation: Concurrent transactions don’t affect each other
--  Durability: Once committed, data stays even after crash

--2 COMMIT: Permanently saves changes
--  ROLLBACK: Undoes uncommitted changes

--3 When you want to undo only part of a long transaction, not the whole thing

--4 Read Uncommitted: Allows dirty reads
--  Read Committed: Prevents dirty reads; non-repeatable reads possible
--	Repeatable Read: Prevents dirty + non-repeatable reads; phantom reads possible
--	Serializable: Prevents all anomalies (dirty, non-repeatable, phantom)

--5 Reading uncommitted data. Allowed only in Read Uncommitted

--6 A row read twice gives different values because another transaction updated it

--7 A query returns different sets of rows because another transaction inserted/deleted rows
--	Prevented by serializable

--8 READ COMMITTED is faster, less locking. SERIALIZABLE causes more blocking

--9 They group operations as one unit, prevent partial updates, and isolate concurrent actions

--10 They are lost. Only committed data is recovered

--conclusion
--Transactions are essential for maintaining data integrity.
-- Low isolation levels like READ COMMITTED expose the database to concurrency anomalies,
-- such as the Non-Repeatable Read, which can lead to illogical results (like MAX < MIN in aggregate queries).
-- The highest isolation level, SERIALIZABLE, prevents these anomalies by enforcing a consistent
-- data snapshot throughout the transaction, guaranteeing the database's logical correctness.
-- We learned that the choice of isolation level is a critical trade-off between data consistency and
-- application performance