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

### Key findings (R)

- **Overtime is the strongest signal.** χ²(1) = 87.6, p < 0.001, Cramér's V = 0.25. In the regression, overtime multiplies the odds of leaving by **5.1** (95% CI 3.7–7.1), holding the other factors constant.
- **Department matters, but weakly on its own.** χ²(2) = 10.8, p = 0.005, Cramér's V = 0.09. After controls, Sales staff have about 1.9x the odds of leaving compared with R&D (CI 1.4–2.7).
- **Leavers earn less.** Median monthly income is 3,202 for leavers and 5,204 for stayers (Wilcoxon p < 0.001). Each extra 1,000 per month goes with about 10% lower odds of leaving (OR 0.90, CI 0.85–0.96).
- **Tenure works through other factors.** Leavers have a median tenure of 3 years against 6 for stayers (Wilcoxon p < 0.001). In the regression, tenure is no longer significant (OR 0.97, p = 0.08) once age, income and overtime are included. Short tenure seems to proxy for being young, junior and lower paid.
- **Other significant factors:** being single (OR 2.5), each step up in job satisfaction (OR 0.71) or environment satisfaction (OR 0.71), better work-life balance (OR 0.74), and commute distance (+3% odds per unit of distance; the dataset does not state the unit).
- **Model fit:** 86.3% accuracy against an 83.9% "nobody leaves" baseline. The model catches only 26% of leavers at a 0.5 cut-off. It is useful for explaining what drives attrition, not for predicting who will leave.

## What HR could do with this

- Target retention effort at the first two years, where most leavers go.
- Review overtime load, especially in Sales and among Laboratory Technicians.
- Check pay for entry-level (job level 1) roles against the market.

## Limitations

- The data is fictional and cross-sectional (one snapshot), so it shows associations, not causes.
- Some groups are small (HR department: 63 staff), so their rates are less stable.
