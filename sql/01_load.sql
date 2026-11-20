-- Build the SQLite database from the raw CSV.
-- Run from the project root:  sqlite3 hr.db < sql/01_load.sql

DROP TABLE IF EXISTS employees;

CREATE TABLE employees (
    age                         INTEGER,
    attrition                   TEXT,     -- 'Yes' / 'No'
    business_travel             TEXT,
    daily_rate                  INTEGER,
    department                  TEXT,
    distance_from_home          INTEGER,
    education                   INTEGER,  -- 1 Below College .. 5 Doctor
    education_field             TEXT,
    employee_count              INTEGER,  -- constant 1, not used
    employee_number             INTEGER PRIMARY KEY,
    environment_satisfaction    INTEGER,  -- 1 Low .. 4 Very High
    gender                      TEXT,
    hourly_rate                 INTEGER,
    job_involvement             INTEGER,
    job_level                   INTEGER,
    job_role                    TEXT,
    job_satisfaction            INTEGER,  -- 1 Low .. 4 Very High
    marital_status              TEXT,
    monthly_income              INTEGER,
    monthly_rate                INTEGER,
    num_companies_worked        INTEGER,
    over18                      TEXT,     -- constant 'Y', not used
    overtime                    TEXT,     -- 'Yes' / 'No'
    percent_salary_hike         INTEGER,
    performance_rating          INTEGER,
    relationship_satisfaction   INTEGER,
    standard_hours              INTEGER,  -- constant 80, not used
    stock_option_level          INTEGER,
    total_working_years         INTEGER,
    training_times_last_year    INTEGER,
    work_life_balance           INTEGER,  -- 1 Bad .. 4 Best
    years_at_company            INTEGER,
    years_in_current_role       INTEGER,
    years_since_last_promotion  INTEGER,
    years_with_curr_manager     INTEGER
);

-- Header row is skipped; columns map by position to the table above.
.import --csv --skip 1 data/hr_attrition.csv employees

-- Sanity checks: expect 1470 rows, 237 leavers, no missing key fields.
SELECT 'rows'          AS check_name, COUNT(*) AS value FROM employees
UNION ALL
SELECT 'leavers',       COUNT(*) FROM employees WHERE attrition = 'Yes'
UNION ALL
SELECT 'missing_dept',  COUNT(*) FROM employees WHERE department IS NULL OR department = '';
