-- ============================================================
-- Customer Churn Analytics — SQL Queries
-- Check Point Home Assignment | Tal Ilan
-- ============================================================

-- ============================================================
-- Part 1: Data Preparation
-- ============================================================

-- Create unified analytical dataset
-- LEFT JOIN from charges_data (base table with churn) 
-- to preserve all 7,032 customers
DROP TABLE IF EXISTS Full_Churn_Data

SELECT 
    C.customerID,
    -- Charges & Contract
    C.tenure,
    C.contract,
    C.paperlessBilling,
    C.paymentMethod,
    C.monthlyCharges,
    C.totalCharges,
    C.churn,
    -- Personal
    P.gender,
    P.partner,
    P.dependents,
    P.age,
    -- Plan
    PL.phoneService,
    PL.multipleLines,
    PL.internetService,
    PL.onlineSecurity,
    PL.onlineBackup,
    PL.deviceProtection,
    PL.techSupport,
    PL.streamingTV,
    PL.streamingMovies
INTO Full_Churn_Data
FROM [dbo].[charges_data] C
LEFT JOIN [dbo].[personal_data] P
    ON C.customerID = P.customerID
LEFT JOIN [dbo].[plan_data] PL
    ON C.customerID = PL.customerID;


-- Data coverage analysis
SELECT 
    COUNT(*) AS total_customers,
    SUM(CASE WHEN P.customerID IS NOT NULL THEN 1 ELSE 0 END) AS has_personal,
    SUM(CASE WHEN PL.customerID IS NOT NULL THEN 1 ELSE 0 END) AS has_plan,
    SUM(CASE WHEN P.customerID IS NOT NULL 
          AND PL.customerID IS NOT NULL THEN 1 ELSE 0 END) AS has_all_data
FROM [dbo].[charges_data] C
LEFT JOIN [dbo].[personal_data] P
    ON C.customerID = P.customerID
LEFT JOIN [dbo].[plan_data] PL
    ON C.customerID = PL.customerID;


-- Churn rate comparison across data coverage levels
-- Purpose: Validate that missing data does not introduce bias
WITH base AS (
    SELECT 
        C.customerID,
        C.churn,
        CASE WHEN P.customerID IS NOT NULL THEN 1 ELSE 0 END AS has_personal,
        CASE WHEN PL.customerID IS NOT NULL THEN 1 ELSE 0 END AS has_plan
    FROM [dbo].[charges_data] C
    LEFT JOIN [dbo].[personal_data] P
        ON C.customerID = P.customerID
    LEFT JOIN [dbo].[plan_data] PL
        ON C.customerID = PL.customerID
)
SELECT 'charges' AS data_coverage, COUNT(*) AS customers,
       SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
       ROUND(100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS churn_rate_pct
FROM base
UNION ALL
SELECT 'personal', COUNT(*),
       SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1)
FROM base WHERE has_personal = 1
UNION ALL
SELECT 'plan', COUNT(*),
       SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1)
FROM base WHERE has_plan = 1
UNION ALL
SELECT 'all', COUNT(*),
       SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1)
FROM base WHERE has_personal = 1 AND has_plan = 1;

/*
Data Coverage Validation:
Churn rate is consistent (~26%) across all data subsets,
confirming no systematic bias from missing personal/plan data.
LEFT JOIN from charges_data is valid as the base table.

| Subset   | Customers | Churn Rate |
| charges  | 7,032     | 26.6%      |
| personal | 5,276     | 26.2%      |
| plan     | 3,537     | 26.0%      |
| all      | 3,537     | 26.0%      |
*/


-- ============================================================
-- Part 2: Analysis
-- ============================================================

-- Tenure quartile boundaries (used to define tenure groups)
SELECT DISTINCT 
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY tenure) OVER() AS Q1,
    PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY tenure) OVER() AS Q2,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tenure) OVER() AS Q3
FROM charges_data;


-- 2.1 Churn rate by tenure groups (based on quartile boundaries)
SELECT 
    CASE 
        WHEN tenure <= 9  THEN '0-9'
        WHEN tenure <= 29 THEN '10-29'
        WHEN tenure <= 55 THEN '30-55'
        ELSE '>=56'
    END AS tenure_group,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    COUNT(customerID) AS total,
    CAST(
        100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) 
        / COUNT(customerID) 
    AS DECIMAL(5,2)) AS churn_rate_pct
FROM Full_Churn_Data
GROUP BY 
    CASE 
        WHEN tenure <= 9  THEN '0-9'
        WHEN tenure <= 29 THEN '10-29'
        WHEN tenure <= 55 THEN '30-55'
        ELSE '>=56'
    END
ORDER BY 
    MIN(tenure);

/*
Tenure Analysis Results:
Churn rate decreases consistently with tenure.
The first 9 months are a critical retention window.

| Tenure Group | Churned | Total | Churn Rate |
| 0-9          | 1,014   | 2,023 | 50.12%     |
| 10-29        | 486     | 1,717 | 28.31%     |
| 30-55        | 269     | 1,537 | 17.50%     |
| >=56         | 100     | 1,755 | 5.70%      |
*/


-- 2.2 Churn rate by contract type
-- Selected as the additional dimension due to highest spread (39.9pp)
-- among all categorical variables tested
SELECT * FROM (
    SELECT 
        Contract,
        SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
        COUNT(customerID) AS total,
        CAST(
            100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) 
            / COUNT(customerID) 
        AS DECIMAL(5,2)) AS churn_rate_pct
    FROM Full_Churn_Data
    GROUP BY Contract
) t
ORDER BY churn_rate_pct DESC;

/*
Contract Analysis Results:
Month-to-month customers represent both the largest segment (55%)
and the highest churn rate (42.7%), making them the primary retention target.
Long-term contracts show significantly lower churn, suggesting that
contract conversion programs could be an effective retention strategy —
after further segmentation to identify the most convertible sub-groups.

| Contract       | Churned | Total | Churn Rate |
| Month-to-month | 1,655   | 3,875 | 42.71%     |
| One year       | 166     | 1,473 | 11.27%     |
| Two year       | 48      | 1,684 | 2.85%      |
*/
