--1.1
CREATE DATABASE university_main
    WITH OWNER = postgres
    TEMPLATE = template0
    ENCODING = 'UTF8';

CREATE DATABASE university_archive
    WITH OWNER = postgres
    TEMPLATE = template0
    CONNECTION LIMIT = 50;

CREATE DATABASE university_test
WITH OWNER = postgres
TEMPLATE = template0
CONNECTION LIMIT = 10;

UPDATE pg_database
SET datistemplate = TRUE --
WHERE datname = 'university_test';

--1.2
CREATE TABLESPACE student_data
    LOCATION '/Users/nuraimuhambet/pg_tablespaces/data/students';

CREATE TABLESPACE course_data
    OWNER postgres
    LOCATION '/Users/nuraimuhambet/pg_tablespaces/data/courses';

CREATE DATABASE university_distributed
    WITH OWNER = postgres
    TABLESPACE = student_data
    TEMPLATE = template0
    ENCODING = 'UTF8'; --latin9 didnt work, old version

--2.1
CREATE TABLE students (
    student_id       SERIAL PRIMARY KEY,
    first_name       VARCHAR(50)   NOT NULL,
    last_name        VARCHAR(50)   NOT NULL,
    email            VARCHAR(100)  UNIQUE, -- students cant have the same emails
    phone            CHAR(15),
    date_of_birth    DATE,
    enrollment_date  DATE,
    gpa              NUMERIC(3,2),
    is_active        BOOLEAN DEFAULT TRUE, -- assumes new students are active by default
    graduation_year  SMALLINT
);

CREATE TABLE professors (
    professor_id     SERIAL PRIMARY KEY,
    first_name       VARCHAR(50)   NOT NULL,
    last_name        VARCHAR(50)   NOT NULL,
    email            VARCHAR(100)  UNIQUE,
    office_number    VARCHAR(20),
    hire_date        DATE,
    salary           NUMERIC(12,2),
    is_tenured       BOOLEAN DEFAULT FALSE,
    years_experience INTEGER
);

CREATE TABLE courses (
    course_id     SERIAL PRIMARY KEY,
    course_code   CHAR(8)        UNIQUE,
    course_title  VARCHAR(100)   NOT NULL,
    description   TEXT,
    credits       SMALLINT,
    max_enrollment INTEGER,
    course_fee    NUMERIC(10,2),
    is_online     BOOLEAN DEFAULT FALSE,
    created_at    TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP -- stores both date and time
);

--2.2
CREATE TABLE class_schedule (
    schedule_id  SERIAL PRIMARY KEY,
    course_id    INTEGER REFERENCES courses(course_id) ON DELETE CASCADE, -- foreign key, if a course is deleted, all schedules for that course are automatically deleted
    professor_id INTEGER REFERENCES professors(professor_id) ON DELETE SET NULL,
    classroom    VARCHAR(20),
    class_date   DATE,
    start_time   TIME WITHOUT TIME ZONE,
    end_time     TIME WITHOUT TIME ZONE,
    duration     INTERVAL
);

CREATE TABLE student_records (
    record_id            SERIAL PRIMARY KEY,
    student_id           INTEGER REFERENCES students(student_id) ON DELETE CASCADE,
    course_id            INTEGER REFERENCES courses(course_id)   ON DELETE CASCADE,
    semester             VARCHAR(20),
    year                 INTEGER,
    grade                CHAR(2),
    attendance_percentage NUMERIC(4,1),
    submission_timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, -- with timezone
    last_updated         TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

--3.1
ALTER TABLE students
    ADD COLUMN middle_name VARCHAR(30),
    ADD COLUMN student_status VARCHAR(20) DEFAULT 'ACTIVE',
    ALTER COLUMN phone TYPE VARCHAR(20),
    ALTER COLUMN gpa SET DEFAULT 0.00;

ALTER TABLE professors
    ADD COLUMN department_code CHAR(5),
    ADD COLUMN research_area TEXT,
    ALTER COLUMN years_experience TYPE SMALLINT,
    ALTER COLUMN is_tenured SET DEFAULT FALSE,
    ADD COLUMN last_promotion_date DATE;

ALTER TABLE courses
    ADD COLUMN prerequisite_course_id INTEGER,
    ADD COLUMN difficulty_level SMALLINT,
    ALTER COLUMN course_code TYPE VARCHAR(10),
    ALTER COLUMN credits SET DEFAULT 3,
    ADD COLUMN lab_required BOOLEAN DEFAULT FALSE;

--3.2
ALTER TABLE class_schedule
    ADD COLUMN room_capacity INTEGER,
    DROP COLUMN duration,
    ADD COLUMN session_type VARCHAR(15),
    ALTER COLUMN classroom TYPE VARCHAR(30),
    ADD COLUMN equipment_needed TEXT;

ALTER TABLE student_records
    ADD COLUMN extra_credit_points NUMERIC(3,1) DEFAULT 0.0,
    ALTER COLUMN grade TYPE VARCHAR(5),
    ADD COLUMN final_exam_date DATE,
    DROP COLUMN last_updated;

--4.1
CREATE TABLE departments (
    department_id     SERIAL PRIMARY KEY,
    department_name   VARCHAR(100) NOT NULL,
    department_code   CHAR(5)      UNIQUE,
    building          VARCHAR(50),
    phone             VARCHAR(15),
    budget            NUMERIC(12,2),
    established_year  INTEGER
);

CREATE TABLE library_books (
    book_id               SERIAL PRIMARY KEY,
    isbn                  CHAR(13) UNIQUE,
    title                 VARCHAR(200) NOT NULL,
    author                VARCHAR(100),
    publisher             VARCHAR(100),
    publication_date      DATE,
    price                 NUMERIC(10,2),
    is_available          BOOLEAN DEFAULT TRUE,
    acquisition_timestamp TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE student_book_loans (
    loan_id      SERIAL PRIMARY KEY,
    student_id   INTEGER,
    book_id      INTEGER,
    loan_date    DATE,
    due_date     DATE,
    return_date  DATE,
    fine_amount  NUMERIC(10,2),
    loan_status  VARCHAR(20)
);

--4.2
ALTER TABLE professors
    ADD COLUMN department_id INTEGER;
ALTER TABLE students
    ADD COLUMN advisor_id INTEGER;
ALTER TABLE courses
    ADD COLUMN department_id INTEGER;

CREATE TABLE grade_scale (
    grade_id       SERIAL PRIMARY KEY,
    letter_grade   CHAR(2) NOT NULL,
    min_percentage NUMERIC(4,1),
    max_percentage NUMERIC(4,1),
    gpa_points     NUMERIC(3,2)
);

CREATE TABLE semester_calendar (
    semester_id           SERIAL PRIMARY KEY,
    semester_name         VARCHAR(20),
    academic_year         INTEGER,
    start_date            DATE,
    end_date              DATE,
    registration_deadline TIMESTAMPTZ, --with timezone
    is_current            BOOLEAN DEFAULT FALSE
);

--5.1
DROP TABLE IF EXISTS student_book_loans;
DROP TABLE IF EXISTS library_books;
DROP TABLE IF EXISTS grade_scale;

CREATE TABLE grade_scale (
    grade_id       SERIAL PRIMARY KEY,
    letter_grade   CHAR(2) NOT NULL,
    min_percentage NUMERIC(4,1),
    max_percentage NUMERIC(4,1),
    gpa_points     NUMERIC(3,2),
    description    TEXT
);

DROP TABLE IF EXISTS semester_calendar CASCADE;

CREATE TABLE semester_calendar (
    semester_id           SERIAL PRIMARY KEY,
    semester_name         VARCHAR(20),
    academic_year         INTEGER,
    start_date            DATE,
    end_date              DATE,
    registration_deadline TIMESTAMPTZ,
    is_current            BOOLEAN DEFAULT FALSE
);

--5.2
UPDATE pg_database
SET datistemplate = FALSE
WHERE datname = 'university_test'; -- to work with template db

DROP DATABASE IF EXISTS university_test;
DROP DATABASE IF EXISTS university_distributed;

CREATE DATABASE university_backup
    WITH TEMPLATE = university_main
    OWNER = postgres
    ENCODING = 'UTF8';