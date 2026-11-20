# HR Attrition Analysis (SQL + R)

Why do employees leave? This project answers that question for a fictional company of 1,470 employees, using SQL for the descriptive analysis and R for the statistical tests.

**Data:** [IBM HR Analytics Employee Attrition & Performance](https://www.kaggle.com/datasets/pavansubhasht/ibm-hr-analytics-attrition-dataset), a public dataset created by IBM data scientists. One row per employee, 35 columns (department, role, income, tenure, overtime, satisfaction scores, and whether the employee left).

## Project structure

```
data/hr_attrition.csv     raw dataset (1,470 rows)
sql/01_load.sql           creates the SQLite table and loads the CSV
sql/02_analysis.sql       10 business questions answered in SQL
R/03_stats.R              chi-square tests, Wilcoxon tests, logistic regression, charts
output/                   R results and charts
```

## How to run

Needs SQLite 3.32+ and R 4.x. No R packages needed.

```bash
sqlite3 hr.db < sql/01_load.sql
sqlite3 -header -column hr.db < sql/02_analysis.sql
Rscript R/03_stats.R
```

## Key findings (SQL)

Overall attrition: **16.1%** (237 of 1,470).

| Question | Finding |
|---|---|
| Department | Sales loses the most people (20.6%), then HR (19.0%), then R&D (13.8%). |
| Job role | Sales Representatives leave at 39.8%, Laboratory Technicians at 23.9%. Research Directors at 2.5%. |
| Tenure | Attrition is highest early: 36.4% in the first year, 28.9% at 1–2 years, 8.1% after 10 years. |
| Overtime | Staff working overtime leave at 30.5% vs 10.4% without, about 3x. This holds in every department. |
| Pay | At job levels 1, 3 and 4, leavers earned less on average than stayers at the same level. |
| Satisfaction | Job satisfaction 1 (low): 22.8% attrition; 4 (very high): 11.3%. Poor work-life balance (1): 31.3%. |
| Risk segment | Under 30, single, on overtime and in their first 2 years: 17 of 20 left (85%). Small group, so treat as a signal, not a rate. |

SQL techniques used: aggregation with `GROUP BY`/`HAVING`, conditional aggregation, `CASE` banding, CTEs, `UNION ALL`, and a window function (`RANK() OVER (PARTITION BY ...)`).

## Statistics (R)

`R/03_stats.R` tests whether the patterns above are more than chance:

1. **Chi-square test**: overtime × attrition, with Cramér's V for effect size.
2. **Chi-square test**: department × attrition.
3. **Wilcoxon rank-sum test**: monthly income, leavers vs stayers (income is skewed, so a rank test fits better than a t-test).
4. **Wilcoxon rank-sum test**: years at company, leavers vs stayers.
5. **Logistic regression**: attrition on overtime, tenure, income, age, satisfaction scores, marital status, department and commute distance. Reported as odds ratios with 95% confidence intervals.

Full output: `output/stats_results.txt`. Charts: `output/attrition_by_overtime.png`, `output/attrition_by_tenure.png`.

<!-- TODO after running R: add the 2-3 headline numbers here, e.g. the overtime odds ratio and its CI. -->

## What HR could do with this

- Target retention effort at the first two years, where most leavers go.
- Review overtime load, especially in Sales and among Laboratory Technicians.
- Check pay for entry-level (job level 1) roles against the market.

## Limitations

- The data is fictional and cross-sectional (one snapshot), so it shows associations, not causes.
- Some groups are small (HR department: 63 staff), so their rates are less stable.
