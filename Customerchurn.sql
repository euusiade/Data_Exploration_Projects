SELECT * FROM customer_churn_data;

-- Customer Demographics and Churn

SELECT 
        gender,
        SUM(CASE WHEN age <= 20 THEN 1 ELSE 0 END) AS total_below_or_20,
        SUM(CASE WHEN age BETWEEN 21 AND 30 THEN 1 ELSE 0 END) AS total_age21_30,
        SUM(CASE WHEN age BETWEEN 31 AND 40 THEN 1 ELSE 0 END) AS total_age31_40,
        SUM(CASE WHEN age BETWEEN 41 AND 50 THEN 1 ELSE 0 END) AS total_age41_50,
        SUM(CASE WHEN age BETWEEN 51 AND 60 THEN 1 ELSE 0 END) AS total_age51_60,
        SUM(CASE WHEN age BETWEEN 61 AND 70 THEN 1 ELSE 0 END) AS total_age61_70,
        SUM(CASE WHEN age >= 71 THEN 1 ELSE 0 END) AS total_after_71
    FROM customer_churn_data
    GROUP BY gender;

#Age groups with intervals of 10, grouped by gender
WITH agegendergroup AS (
    SELECT 
        gender,
        SUM(CASE WHEN age <= 20 THEN 1 ELSE 0 END) AS total_below_or_20,
        SUM(CASE WHEN age BETWEEN 21 AND 30 THEN 1 ELSE 0 END) AS total_age21_30,
        SUM(CASE WHEN age BETWEEN 31 AND 40 THEN 1 ELSE 0 END) AS total_age31_40,
        SUM(CASE WHEN age BETWEEN 41 AND 50 THEN 1 ELSE 0 END) AS total_age41_50,
        SUM(CASE WHEN age BETWEEN 51 AND 60 THEN 1 ELSE 0 END) AS total_age51_60,
        SUM(CASE WHEN age BETWEEN 61 AND 70 THEN 1 ELSE 0 END) AS total_age61_70,
        SUM(CASE WHEN age >= 71 THEN 1 ELSE 0 END) AS total_after_71
    FROM customer_churn_data
    GROUP BY gender
),
#Churned customers for age/gender groups
churncustomers AS (
    SELECT 
        gender,
        SUM(CASE WHEN age <= 20 AND churn = 'Yes' THEN 1 ELSE 0 END) AS churn_below_or_20,
        SUM(CASE WHEN age BETWEEN 21 AND 30 AND churn = 'Yes' THEN 1 ELSE 0 END) AS churn_age21_30,
        SUM(CASE WHEN age BETWEEN 31 AND 40 AND churn = 'Yes' THEN 1 ELSE 0 END) AS churn_age31_40,
        SUM(CASE WHEN age BETWEEN 41 AND 50 AND churn = 'Yes' THEN 1 ELSE 0 END) AS churn_age41_50,
        SUM(CASE WHEN age BETWEEN 51 AND 60 AND churn = 'Yes' THEN 1 ELSE 0 END) AS churn_age51_60,
        SUM(CASE WHEN age BETWEEN 61 AND 70 AND churn = 'Yes' THEN 1 ELSE 0 END) AS churn_age61_70,
        SUM(CASE WHEN age >= 71 AND churn = 'Yes' THEN 1 ELSE 0 END) AS churn_after_71
    FROM customer_churn_data
    GROUP BY gender
)
# Churn percentage for each gender and age group.
SELECT 
    ag.gender,
    (cc.churn_below_or_20 * 100.0 / ag.total_below_or_20) AS churn_percent_below_or_20,
    (cc.churn_age21_30 * 100.0 / ag.total_age21_30) AS churn_percent_age21_30,
    (cc.churn_age31_40 * 100.0 / ag.total_age31_40) AS churn_percent_age31_40,
    (cc.churn_age41_50 * 100.0 / ag.total_age41_50) AS churn_percent_age41_50,
    (cc.churn_age51_60 * 100.0 / ag.total_age51_60) AS churn_percent_age51_60,
    (cc.churn_age61_70 * 100.0 / ag.total_age61_70) AS churn_percent_age61_70,
    (cc.churn_after_71 * 100.0 / ag.total_after_71) AS churn_percent_after_71
FROM agegendergroup ag
JOIN churncustomers cc
    ON ag.gender = cc.gender;

-- Contract Type vs. Churn
WITH total AS (
    SELECT contracttype, COUNT(*) AS totalcount
    FROM customer_churn_data
    GROUP BY contracttype
),
contracttype_churn AS (
    SELECT contracttype, SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churncount
    FROM customer_churn_data
    GROUP BY contracttype
)
SELECT 
    t.contracttype, 
    ROUND((c.churncount * 100.0 / t.totalcount), 1) AS churnpercent
FROM total t
JOIN contracttype_churn c 
    ON t.contracttype = c.contracttype
ORDER BY churnpercent ASC;

-- Monthly Charges and Customer Retention
 
 SELECT MIN(monthlycharges), MAX(monthlycharges) FROM customer_churn_data;
 
WITH chargesgroup AS (
    SELECT 
        SUM(CASE WHEN monthlycharges BETWEEN 29 AND 51 THEN 1 ELSE 0 END) AS charges_30_50,
        SUM(CASE WHEN monthlycharges BETWEEN 50 AND 71 THEN 1 ELSE 0 END) AS charges_51_70,
        SUM(CASE WHEN monthlycharges BETWEEN 70 AND 91 THEN 1 ELSE 0 END) AS charges_71_90,
        SUM(CASE WHEN monthlycharges BETWEEN 90 AND 111 THEN 1 ELSE 0 END) AS charges_91_110,
        SUM(CASE WHEN monthlycharges > 110 THEN 1 ELSE 0 END) AS charges_after_110
    FROM customer_churn_data
),
chargeschurn AS (
    SELECT 
        SUM(CASE WHEN monthlycharges BETWEEN 29 AND 51 AND churn = 'Yes' THEN 1 ELSE 0 END) AS churncharges_30_50,
        SUM(CASE WHEN monthlycharges BETWEEN 50 AND 71 AND churn = 'Yes' THEN 1 ELSE 0 END) AS churncharges_51_70,
        SUM(CASE WHEN monthlycharges BETWEEN 70 AND 91 AND churn = 'Yes' THEN 1 ELSE 0 END) AS churncharges_71_90,
        SUM(CASE WHEN monthlycharges BETWEEN 90 AND 111 AND churn = 'Yes' THEN 1 ELSE 0 END) AS churncharges_91_110,
        SUM(CASE WHEN monthlycharges > 110 AND churn = 'Yes' THEN 1 ELSE 0 END) AS churncharges_after_110
    FROM customer_churn_data
)
#Churn percentage for monthly charges groups
SELECT 
    ROUND(((cc.churncharges_30_50 * 100) / cg.charges_30_50), 1) AS cp30_50,
    ROUND(((cc.churncharges_51_70 * 100) / cg.charges_51_70), 1) AS cp51_70,
    ROUND(((cc.churncharges_71_90 * 100) / cg.charges_71_90), 1) AS cp71_90,
    ROUND(((cc.churncharges_91_110 * 100) / cg.charges_91_110), 1) AS cp91_110,
    ROUND(((cc.churncharges_after_110 * 100) / cg.charges_after_110), 1) AS cp_after_110
FROM chargesgroup cg, chargeschurn cc;

-- Tech Support and Churn

WITH techgroups AS (
    SELECT 
        SUM(CASE WHEN techsupport = 'Yes' THEN 1 ELSE 0 END) AS yesgroup,
        SUM(CASE WHEN techsupport = 'No' THEN 1 ELSE 0 END) AS nogroup
    FROM customer_churn_data
), 
techgroupchurn AS (
    SELECT 
        SUM(CASE WHEN techsupport = 'Yes' AND churn = 'Yes' THEN 1 ELSE 0 END) AS churnyesgroup,
        SUM(CASE WHEN techsupport = 'No' AND churn = 'Yes' THEN 1 ELSE 0 END) AS churnnogroup
    FROM customer_churn_data
)
#Churn pecentage for Tech support groups 
SELECT 
    ROUND(((tgc.churnyesgroup * 100) / tg.yesgroup), 1) AS cp_yesgroup,
    ROUND(((tgc.churnnogroup * 100) / tg.nogroup), 1) AS cp_nogroup
FROM techgroups tg, techgroupchurn tgc;

-- Tenure vs. Churn

SELECT MIN(tenure), MAX(tenure) FROM customer_churn_data;

WITH tenuregroups AS (
    SELECT 
        SUM(CASE WHEN tenure <= 20 THEN 1 ELSE 0 END) AS below_or20,
        SUM(CASE WHEN tenure BETWEEN 21 AND 40 THEN 1 ELSE 0 END) AS tenure21_40,
        SUM(CASE WHEN tenure BETWEEN 41 AND 60 THEN 1 ELSE 0 END) AS tenure41_60,
        SUM(CASE WHEN tenure BETWEEN 61 AND 80 THEN 1 ELSE 0 END) AS tenure61_80,
        SUM(CASE WHEN tenure BETWEEN 81 AND 100 THEN 1 ELSE 0 END) AS tenure81_100,
        SUM(CASE WHEN tenure > 100 THEN 1 ELSE 0 END) AS after100
    FROM customer_churn_data
),
churntenuregroups AS (
    SELECT 
        SUM(CASE WHEN tenure <= 20 AND churn = 'Yes' THEN 1 ELSE 0 END) AS churn_below_or20,
        SUM(CASE WHEN tenure BETWEEN 21 AND 40 AND churn = 'Yes' THEN 1 ELSE 0 END) AS churn_tenure21_40,
        SUM(CASE WHEN tenure BETWEEN 41 AND 60 AND churn = 'Yes' THEN 1 ELSE 0 END) AS churn_tenure41_60,
        SUM(CASE WHEN tenure BETWEEN 61 AND 80 AND churn = 'Yes' THEN 1 ELSE 0 END) AS churn_tenure61_80,
        SUM(CASE WHEN tenure BETWEEN 81 AND 100 AND churn = 'Yes' THEN 1 ELSE 0 END) AS churn_tenure81_100,
        SUM(CASE WHEN tenure > 100 AND churn = 'Yes' THEN 1 ELSE 0 END) AS churn_after100
    FROM customer_churn_data
)
-- Churn percentage for each tenure group
SELECT 
    ROUND((ctg.churn_below_or20 * 100.0) / tg.below_or20, 1) AS cp_below_or20,
    ROUND((ctg.churn_tenure21_40 * 100.0) / tg.tenure21_40, 1) AS cp_tenure21_40,
    ROUND((ctg.churn_tenure41_60 * 100.0) / tg.tenure41_60, 1) AS cp_tenure41_60,
    ROUND((ctg.churn_tenure61_80 * 100.0) / tg.tenure61_80, 1) AS cp_tenure61_80,
    ROUND((ctg.churn_tenure81_100 * 100.0) / tg.tenure81_100, 1) AS cp_tenure81_100,
    ROUND((ctg.churn_after100 * 100.0) / tg.after100, 1) AS cp_after100
FROM tenuregroups tg, churntenuregroups ctg;
