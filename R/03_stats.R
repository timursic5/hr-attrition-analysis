# Statistics step for the HR attrition project.
# Base R only, no packages to install.
# Run from the project root:  Rscript R/03_stats.R
# Writes results to output/stats_results.txt and two charts to output/.

dir.create("output", showWarnings = FALSE)

hr <- read.csv("data/hr_attrition.csv", fileEncoding = "UTF-8-BOM",
               stringsAsFactors = TRUE)

# Outcome as 0/1, and readable factor levels
hr$left       <- as.integer(hr$Attrition == "Yes")
hr$OverTime   <- relevel(hr$OverTime, ref = "No")
hr$Department <- relevel(hr$Department, ref = "Research & Development")
hr$MaritalStatus <- relevel(hr$MaritalStatus, ref = "Married")
hr$income_k   <- hr$MonthlyIncome / 1000   # income in thousands, easier to read

cramers_v <- function(tab) {
  chi <- suppressWarnings(chisq.test(tab, correct = FALSE))$statistic
  k   <- min(dim(tab)) - 1
  unname(sqrt(chi / (sum(tab) * k)))
}

sink("output/stats_results.txt", split = TRUE)

cat("=== 1. Overtime vs attrition (chi-square test of independence) ===\n")
tab_ot <- table(OverTime = hr$OverTime, Attrition = hr$Attrition)
print(tab_ot)
print(round(prop.table(tab_ot, 1) * 100, 1))
print(chisq.test(tab_ot))
cat("Cramer's V:", round(cramers_v(tab_ot), 3), "\n\n")

cat("=== 2. Department vs attrition (chi-square test of independence) ===\n")
tab_dep <- table(Department = hr$Department, Attrition = hr$Attrition)
print(tab_dep)
print(chisq.test(tab_dep))
cat("Cramer's V:", round(cramers_v(tab_dep), 3), "\n\n")

cat("=== 3. Monthly income: leavers vs stayers ===\n")
print(aggregate(MonthlyIncome ~ Attrition, data = hr, FUN = median))
# Income is right-skewed, so use a rank-based test as the main test
print(wilcox.test(MonthlyIncome ~ Attrition, data = hr))
print(t.test(MonthlyIncome ~ Attrition, data = hr))   # Welch t-test, for reference

cat("=== 4. Tenure: years at company, leavers vs stayers ===\n")
print(aggregate(YearsAtCompany ~ Attrition, data = hr, FUN = median))
print(wilcox.test(YearsAtCompany ~ Attrition, data = hr))

cat("=== 5. Logistic regression: what predicts leaving? ===\n")
model <- glm(left ~ OverTime + YearsAtCompany + income_k + Age +
               JobSatisfaction + WorkLifeBalance + EnvironmentSatisfaction +
               MaritalStatus + Department + DistanceFromHome,
             data = hr, family = binomial)
print(summary(model))

cat("\nOdds ratios with 95% confidence intervals (Wald):\n")
or_table <- exp(cbind(odds_ratio = coef(model), confint.default(model)))
print(round(or_table, 3))

# Simple fit check: share of employees classified correctly at a 0.5 cut-off,
# against the baseline of predicting "No" for everyone.
pred <- as.integer(fitted(model) > 0.5)
cat("\nAccuracy at 0.5 cut-off:", round(mean(pred == hr$left), 3),
    " | baseline (always 'No'):", round(1 - mean(hr$left), 3), "\n")
cat("Leavers correctly flagged (recall):",
    round(sum(pred == 1 & hr$left == 1) / sum(hr$left == 1), 3), "\n")

sink()

# Charts ------------------------------------------------------------------
png("output/attrition_by_overtime.png", width = 700, height = 450)
rates_ot <- tapply(hr$left, hr$OverTime, mean) * 100
bp <- barplot(rates_ot, col = c("grey70", "firebrick"), ylim = c(0, 40),
              ylab = "Attrition rate (%)", xlab = "Works overtime",
              main = "Attrition rate by overtime")
text(bp, rates_ot + 2, paste0(round(rates_ot, 1), "%"))
invisible(dev.off())

hr$tenure_band <- cut(hr$YearsAtCompany, breaks = c(-1, 0, 2, 5, 10, Inf),
                      labels = c("<1", "1-2", "3-5", "6-10", "11+"))
png("output/attrition_by_tenure.png", width = 700, height = 450)
rates_ten <- tapply(hr$left, hr$tenure_band, mean) * 100
bp <- barplot(rates_ten, col = "steelblue", ylim = c(0, 45),
              ylab = "Attrition rate (%)", xlab = "Years at company",
              main = "Attrition rate by tenure")
text(bp, rates_ten + 2, paste0(round(rates_ten, 1), "%"))
invisible(dev.off())

cat("Done. See output/ for results and charts.\n")
