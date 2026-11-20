-- HR attrition analysis: business questions answered in SQL.
-- Run from the project root:  sqlite3 -header -column hr.db < sql/02_analysis.sql
-- "Attrition rate" = leavers / headcount in the group, as a percentage.

-- Q1. What is the overall attrition rate?
SELECT
    COUNT(*)                                                    AS headcount,
    SUM(attrition = 'Yes')                                      AS leavers,
    ROUND(100.0 * SUM(attrition = 'Yes') / COUNT(*), 1)         AS attrition_pct
FROM employees;


-- Q2. Which departments lose the most people?
SELECT
    department,
    COUNT(*)                                                    AS headcount,
    SUM(attrition = 'Yes')                                      AS leavers,
    ROUND(100.0 * SUM(attrition = 'Yes') / COUNT(*), 1)         AS attrition_pct
FROM employees
GROUP BY department
ORDER BY attrition_pct DESC;


-- Q3. Which job roles have the highest attrition? (roles with 30+ staff)
SELECT
    job_role,
    COUNT(*)                                                    AS headcount,
    SUM(attrition = 'Yes')                                      AS leavers,
    ROUND(100.0 * SUM(attrition = 'Yes') / COUNT(*), 1)         AS attrition_pct
FROM employees
GROUP BY job_role
HAVING COUNT(*) >= 30
ORDER BY attrition_pct DESC;


-- Q4. How does attrition change with tenure?
WITH banded AS (
    SELECT
        attrition,
        CASE
            WHEN years_at_company < 1  THEN '1: <1 yr'
            WHEN years_at_company <= 2 THEN '2: 1-2 yrs'
            WHEN years_at_company <= 5 THEN '3: 3-5 yrs'
            WHEN years_at_company <= 10 THEN '4: 6-10 yrs'
            ELSE                            '5: 11+ yrs'
        END AS tenure_band
    FROM employees
)
SELECT
    tenure_band,
    COUNT(*)                                                    AS headcount,
    SUM(attrition = 'Yes')                                      AS leavers,
    ROUND(100.0 * SUM(attrition = 'Yes') / COUNT(*), 1)         AS attrition_pct
FROM banded
GROUP BY tenure_band
ORDER BY tenure_band;


-- Q5. Does overtime go with higher attrition?
SELECT
    overtime,
    COUNT(*)                                                    AS headcount,
    SUM(attrition = 'Yes')                                      AS leavers,
    ROUND(100.0 * SUM(attrition = 'Yes') / COUNT(*), 1)         AS attrition_pct
FROM employees
GROUP BY overtime;


-- Q6. Is the overtime effect the same in every department?
SELECT
    department,
    ROUND(100.0 * SUM(CASE WHEN overtime = 'Yes' AND attrition = 'Yes' THEN 1 ELSE 0 END)
          / SUM(overtime = 'Yes'), 1)                           AS attrition_pct_overtime,
    ROUND(100.0 * SUM(CASE WHEN overtime = 'No'  AND attrition = 'Yes' THEN 1 ELSE 0 END)
          / SUM(overtime = 'No'), 1)                            AS attrition_pct_no_overtime,
    SUM(overtime = 'Yes')                                       AS n_overtime
FROM employees
GROUP BY department
ORDER BY department;


-- Q7. Do leavers earn less than stayers at the same job level?
SELECT
    job_level,
    ROUND(AVG(CASE WHEN attrition = 'Yes' THEN monthly_income END)) AS avg_income_leavers,
    ROUND(AVG(CASE WHEN attrition = 'No'  THEN monthly_income END)) AS avg_income_stayers,
    SUM(attrition = 'Yes')                                          AS leavers,
    COUNT(*)                                                        AS headcount
FROM employees
GROUP BY job_level
ORDER BY job_level;


-- Q8. Attrition by job satisfaction and work-life balance (1 = worst, 4 = best).
SELECT
    'job_satisfaction'  AS measure,
    job_satisfaction    AS score,
    COUNT(*)            AS headcount,
    ROUND(100.0 * SUM(attrition = 'Yes') / COUNT(*), 1) AS attrition_pct
FROM employees
GROUP BY job_satisfaction
UNION ALL
SELECT
    'work_life_balance',
    work_life_balance,
    COUNT(*),
    ROUND(100.0 * SUM(attrition = 'Yes') / COUNT(*), 1)
FROM employees
GROUP BY work_life_balance
ORDER BY measure, score;


-- Q9. Highest-risk segment: young, single, on overtime, in their first 2 years.
--     Compare its attrition rate against everyone else.
SELECT
    CASE
        WHEN age < 30 AND marital_status = 'Single'
             AND overtime = 'Yes' AND years_at_company <= 2
        THEN 'high-risk segment'
        ELSE 'everyone else'
    END                                                         AS segment,
    COUNT(*)                                                    AS headcount,
    SUM(attrition = 'Yes')                                      AS leavers,
    ROUND(100.0 * SUM(attrition = 'Yes') / COUNT(*), 1)         AS attrition_pct
FROM employees
GROUP BY segment;


-- Q10. Within each department, rank job roles by attrition rate (window function).
WITH role_rates AS (
    SELECT
        department,
        job_role,
        COUNT(*)                                                AS headcount,
        ROUND(100.0 * SUM(attrition = 'Yes') / COUNT(*), 1)     AS attrition_pct
    FROM employees
    GROUP BY department, job_role
    HAVING COUNT(*) >= 10
)
SELECT
    department,
    job_role,
    headcount,
    attrition_pct,
    RANK() OVER (PARTITION BY department ORDER BY attrition_pct DESC) AS rank_in_dept
FROM role_rates
ORDER BY department, rank_in_dept;
