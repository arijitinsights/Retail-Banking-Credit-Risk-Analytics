-- Query 1: Overall KPI Summary
-- Business Question: What is our total portfolio size and approval rate?
SELECT ...

 RetailBankingCreditRisk;
GO

SELECT 
    COUNT(DISTINCT c.Customer_ID) AS Total_Customers,
    COUNT(DISTINCT la.Application_ID) AS Total_Applications,
    SUM(CASE WHEN la.Application_Status = 'Approved' THEN 1 ELSE 0 END) AS Approved_Applications,
    CAST(SUM(CASE WHEN la.Application_Status = 'Approved' THEN 1 ELSE 0 END) AS DECIMAL(10,4)) 
        / COUNT(DISTINCT la.Application_ID) AS Approval_Rate
FROM Customers c
LEFT JOIN Loan_Applications la ON la.Customer_ID = c.Customer_ID;


-- Query 2: Default Rate by Credit Score Band
-- Business Question: Does credit score actually predict default?

SELECT
    CASE
        WHEN c.Credit_Score < 580 THEN '300-579 (Poor)'
        WHEN c.Credit_Score < 670 THEN '580-669 (Fair)'
        WHEN c.Credit_Score < 740 THEN '670-739 (Good)'
        WHEN c.Credit_Score < 800 THEN '740-799 (Very Good)'
        ELSE '800-850 (Excellent)'
    END AS Credit_Score_Band,
    COUNT(*) AS Total_Loans,
    SUM(CAST(la.Default_Flag AS INT)) AS Defaulted_Loans,
    CAST(SUM(CAST(la.Default_Flag AS INT)) AS DECIMAL(10,4)) / COUNT(*) AS Default_Rate
FROM Loan_Accounts la
INNER JOIN Customers c ON c.Customer_ID = la.Customer_ID
GROUP BY 
    CASE
        WHEN c.Credit_Score < 580 THEN '300-579 (Poor)'
        WHEN c.Credit_Score < 670 THEN '580-669 (Fair)'
        WHEN c.Credit_Score < 740 THEN '670-739 (Good)'
        WHEN c.Credit_Score < 800 THEN '740-799 (Very Good)'
        ELSE '800-850 (Excellent)'
    END
HAVING COUNT(*) > 50
ORDER BY Default_Rate DESC;

-- Query 3: Branch Performance Ranking
-- Business Question: Which branches over/underperform within their region?

WITH Monthly_Disbursement AS (
    SELECT 
        FORMAT(Disbursement_Date, 'yyyy-MM') AS Disb_Month,
        SUM(Disbursed_Amount) AS Total_Disbursed,
        COUNT(*) AS Loans_Disbursed
    FROM Loan_Accounts
    GROUP BY FORMAT(Disbursement_Date, 'yyyy-MM')
)
SELECT 
    Disb_Month,
    Total_Disbursed,
    Loans_Disbursed,
    LAG(Total_Disbursed)  OVER (ORDER BY Disb_Month) AS Prev_Month_Disbursed,
    Total_Disbursed - LAG(Total_Disbursed) OVER (ORDER BY Disb_Month) AS MoM_Change,
    LEAD(Total_Disbursed) OVER (ORDER BY Disb_Month) AS Next_Month_Disbursed
FROM Monthly_Disbursement
ORDER BY Disb_Month;

-- Query 4: Monthly Disbursement Trend (LAG/LEAD)
-- Business Question: Is lending seasonal? How does disbursement change month over month?

WITH Monthly_Disbursement AS (
    SELECT 
        FORMAT(Disbursement_Date, 'yyyy-MM') AS Disb_Month,
        SUM(Disbursed_Amount) AS Total_Disbursed,
        COUNT(*) AS Loans_Disbursed
    FROM Loan_Accounts
    GROUP BY FORMAT(Disbursement_Date, 'yyyy-MM')
)
SELECT 
    Disb_Month,
    Total_Disbursed,
    Loans_Disbursed,
    LAG(Total_Disbursed)  OVER (ORDER BY Disb_Month) AS Prev_Month_Disbursed,
    Total_Disbursed - LAG(Total_Disbursed) OVER (ORDER BY Disb_Month) AS MoM_Change,
    LEAD(Total_Disbursed) OVER (ORDER BY Disb_Month) AS Next_Month_Disbursed
FROM Monthly_Disbursement
ORDER BY Disb_Month;

-- Query 5: Customer Risk Segmentation (Subquery)
-- Business Question: How much loan exposure and default risk sits with each customer risk category?
SELECT 
    c.Risk_Category,
    COUNT(DISTINCT c.Customer_ID) AS Num_Customers,
    (SELECT COUNT(*) FROM Loan_Accounts la WHERE la.Customer_ID IN 
        (SELECT Customer_ID FROM Customers c2 WHERE c2.Risk_Category = c.Risk_Category)) AS Total_Loans,
    SUM(la.Disbursed_Amount) AS Total_Disbursed,
    SUM(la.Outstanding_Amount) AS Total_Outstanding,
    CAST(SUM(CAST(la.Default_Flag AS INT)) AS DECIMAL(10,4)) / NULLIF(COUNT(la.Loan_ID),0) AS Default_Rate
FROM Customers c
LEFT JOIN Loan_Accounts la ON la.Customer_ID = c.Customer_ID
GROUP BY c.Risk_Category
ORDER BY Default_Rate DESC;


-- Query 6: NPA & Overdue Amount Analysis (Conditional Aggregation + Subquery)
-- Business Question: How much money is currently overdue, and what percentage of loans are NPA?
SELECT 
    COUNT(*) AS Total_Active_Loans,
    SUM(CASE WHEN NPA_Flag = 1 THEN 1 ELSE 0 END) AS Total_NPA_Loans,
    CAST(SUM(CASE WHEN NPA_Flag = 1 THEN 1 ELSE 0 END) AS DECIMAL(10,4)) / COUNT(*) AS NPA_Rate,
    SUM(CASE WHEN Days_Past_Due > 0 THEN Outstanding_Amount ELSE 0 END) AS Total_Overdue_Amount,
    AVG(CASE WHEN Days_Past_Due > 0 THEN Days_Past_Due END) AS Avg_DPD_When_Overdue,
    (SELECT SUM(Outstanding_Amount) FROM Loan_Accounts WHERE Loan_Status = 'Active') AS Total_Active_Outstanding
FROM Loan_Accounts
WHERE Loan_Status IN ('Active', 'Defaulted', 'Written Off');


-- Query 7: Product-Level Profitability & Risk (Loan_Type Comparison)
-- Business Question: Which loan product is most profitable vs. riskiest?
SELECT 
    Loan_Type,
    COUNT(*) AS Total_Loans,
    SUM(Disbursed_Amount) AS Total_Disbursed,
    AVG(Interest_Rate) AS Avg_Interest_Rate,
    SUM(Interest_Paid) AS Total_Interest_Earned,
    SUM(Outstanding_Amount) AS Total_Outstanding,
    CAST(SUM(CAST(Default_Flag AS INT)) AS DECIMAL(10,4)) / COUNT(*) AS Default_Rate,
    CAST(SUM(CAST(NPA_Flag AS INT)) AS DECIMAL(10,4)) / COUNT(*) AS NPA_Rate
FROM Loan_Accounts
GROUP BY Loan_Type
ORDER BY Total_Interest_Earned DESC;



