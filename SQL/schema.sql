/* ============================================================
   Retail Banking Credit Risk & Loan Portfolio Analytics
   SQL Server DDL — Star-schema-ready relational model
   ============================================================ */

IF DB_ID('RetailBankingCreditRisk') IS NULL
    CREATE DATABASE RetailBankingCreditRisk;
GO
USE RetailBankingCreditRisk;
GO

/* ---------- Dimension: Loan_Product_Master ---------- */
CREATE TABLE dbo.Loan_Product_Master (
    Loan_Type            VARCHAR(30)   NOT NULL PRIMARY KEY,
    Typical_Min_Amount   DECIMAL(14,2) NOT NULL,
    Typical_Max_Amount   DECIMAL(14,2) NOT NULL,
    Typical_Tenure       INT           NOT NULL,   -- months
    Base_Interest_Rate   DECIMAL(5,2)  NOT NULL,
    Risk_Level           VARCHAR(10)   NOT NULL
);
GO

/* ---------- Dimension: Branches ---------- */
CREATE TABLE dbo.Branches (
    Branch_ID        CHAR(6)       NOT NULL PRIMARY KEY,
    Branch_Name      VARCHAR(100)  NOT NULL,
    City             VARCHAR(50)   NOT NULL,
    State            VARCHAR(50)   NOT NULL,
    Region           VARCHAR(20)   NOT NULL,
    Branch_Type      VARCHAR(20)   NOT NULL,
    Branch_Manager   VARCHAR(100)  NOT NULL,
    Opening_Year     SMALLINT      NOT NULL
);
GO

/* ---------- Dimension: Customers ---------- */
CREATE TABLE dbo.Customers (
    Customer_ID        CHAR(10)      NOT NULL PRIMARY KEY,
    Customer_Name      VARCHAR(100)  NOT NULL,
    Age                TINYINT       NOT NULL CHECK (Age BETWEEN 21 AND 65),
    Gender             VARCHAR(10)   NOT NULL,
    Marital_Status     VARCHAR(15)   NOT NULL,
    Employment_Type    VARCHAR(25)   NOT NULL,
    Occupation         VARCHAR(50)   NULL,
    Annual_Income      DECIMAL(14,2) NOT NULL CHECK (Annual_Income >= 0),
    Years_Employed     TINYINT       NULL,
    City               VARCHAR(50)   NOT NULL,
    State              VARCHAR(50)   NOT NULL,
    Region             VARCHAR(20)   NOT NULL,
    Credit_Score       SMALLINT      NOT NULL CHECK (Credit_Score BETWEEN 300 AND 850),
    Existing_Loans     TINYINT       NOT NULL CHECK (Existing_Loans >= 0),
    Existing_EMI       DECIMAL(12,2) NOT NULL CHECK (Existing_EMI >= 0),
    Customer_Segment   VARCHAR(20)   NOT NULL,
    Risk_Category      VARCHAR(10)   NOT NULL
);
GO

/* ---------- Fact: Loan_Applications ---------- */
CREATE TABLE dbo.Loan_Applications (
    Application_ID      CHAR(10)      NOT NULL PRIMARY KEY,
    Customer_ID          CHAR(10)      NOT NULL,
    Branch_ID             CHAR(6)       NOT NULL,
    Application_Date     DATE          NOT NULL,
    Loan_Type             VARCHAR(30)   NOT NULL,
    Loan_Purpose          VARCHAR(60)   NULL,
    Requested_Amount     DECIMAL(14,2) NOT NULL CHECK (Requested_Amount >= 0),
    Loan_Term_Months     SMALLINT      NOT NULL,
    Interest_Rate         DECIMAL(5,2)  NOT NULL,
    Application_Status   VARCHAR(15)   NOT NULL,
    Approval_Date         DATE          NULL,
    Rejection_Reason     VARCHAR(60)   NULL,
    CONSTRAINT FK_Applications_Customers FOREIGN KEY (Customer_ID) REFERENCES dbo.Customers(Customer_ID),
    CONSTRAINT FK_Applications_Branches  FOREIGN KEY (Branch_ID)   REFERENCES dbo.Branches(Branch_ID),
    CONSTRAINT FK_Applications_Product   FOREIGN KEY (Loan_Type)   REFERENCES dbo.Loan_Product_Master(Loan_Type),
    CONSTRAINT CK_Applications_Dates CHECK (Approval_Date IS NULL OR Approval_Date >= Application_Date)
);
GO
CREATE INDEX IX_Applications_Customer ON dbo.Loan_Applications(Customer_ID);
CREATE INDEX IX_Applications_Branch   ON dbo.Loan_Applications(Branch_ID);
CREATE INDEX IX_Applications_Status   ON dbo.Loan_Applications(Application_Status);
CREATE INDEX IX_Applications_Date     ON dbo.Loan_Applications(Application_Date);
GO

/* ---------- Fact: Loan_Accounts ---------- */
CREATE TABLE dbo.Loan_Accounts (
    Loan_ID              CHAR(11)      NOT NULL PRIMARY KEY,
    Application_ID       CHAR(10)      NOT NULL,
    Customer_ID           CHAR(10)      NOT NULL,
    Branch_ID              CHAR(6)       NOT NULL,
    Loan_Type              VARCHAR(30)   NOT NULL,
    Disbursement_Date     DATE          NOT NULL,
    Disbursed_Amount      DECIMAL(14,2) NOT NULL CHECK (Disbursed_Amount >= 0),
    Interest_Rate          DECIMAL(5,2)  NOT NULL,
    Loan_Term_Months      SMALLINT      NOT NULL,
    EMI                     DECIMAL(12,2) NOT NULL,
    Outstanding_Amount    DECIMAL(14,2) NOT NULL CHECK (Outstanding_Amount >= 0),
    Principal_Repaid      DECIMAL(14,2) NOT NULL CHECK (Principal_Repaid >= 0),
    Interest_Paid          DECIMAL(14,2) NOT NULL CHECK (Interest_Paid >= 0),
    Loan_Status             VARCHAR(15)   NOT NULL,
    Days_Past_Due          SMALLINT      NOT NULL DEFAULT 0,
    Default_Flag           BIT           NOT NULL DEFAULT 0,
    NPA_Flag                BIT           NOT NULL DEFAULT 0,
    CONSTRAINT FK_Accounts_Applications FOREIGN KEY (Application_ID) REFERENCES dbo.Loan_Applications(Application_ID),
    CONSTRAINT FK_Accounts_Customers    FOREIGN KEY (Customer_ID)    REFERENCES dbo.Customers(Customer_ID),
    CONSTRAINT FK_Accounts_Branches     FOREIGN KEY (Branch_ID)      REFERENCES dbo.Branches(Branch_ID),
    CONSTRAINT FK_Accounts_Product      FOREIGN KEY (Loan_Type)      REFERENCES dbo.Loan_Product_Master(Loan_Type),
    CONSTRAINT CK_Accounts_Outstanding  CHECK (Outstanding_Amount <= Disbursed_Amount)
);
GO
CREATE INDEX IX_Accounts_Customer ON dbo.Loan_Accounts(Customer_ID);
CREATE INDEX IX_Accounts_Branch   ON dbo.Loan_Accounts(Branch_ID);
CREATE INDEX IX_Accounts_Status   ON dbo.Loan_Accounts(Loan_Status);
CREATE INDEX IX_Accounts_Disb     ON dbo.Loan_Accounts(Disbursement_Date);
GO

/* ---------- Fact: Loan_Repayments ---------- */
CREATE TABLE dbo.Loan_Repayments (
    Repayment_ID       CHAR(11)      NOT NULL PRIMARY KEY,
    Loan_ID              CHAR(11)      NOT NULL,
    Customer_ID           CHAR(10)      NOT NULL,
    Payment_Date         DATE          NULL,       -- NULL when a scheduled EMI was missed entirely
    Due_Date               DATE          NOT NULL,
    EMI_Amount            DECIMAL(12,2) NOT NULL,
    Paid_Amount            DECIMAL(12,2) NOT NULL CHECK (Paid_Amount >= 0),
    Payment_Status        VARCHAR(15)   NOT NULL,
    Days_Past_Due         SMALLINT      NOT NULL DEFAULT 0,
    Payment_Method        VARCHAR(20)   NULL,
    CONSTRAINT FK_Repayments_Accounts  FOREIGN KEY (Loan_ID)     REFERENCES dbo.Loan_Accounts(Loan_ID),
    CONSTRAINT FK_Repayments_Customers FOREIGN KEY (Customer_ID) REFERENCES dbo.Customers(Customer_ID)
);
GO
CREATE INDEX IX_Repayments_Loan ON dbo.Loan_Repayments(Loan_ID);
CREATE INDEX IX_Repayments_Due  ON dbo.Loan_Repayments(Due_Date);
CREATE INDEX IX_Repayments_Status ON dbo.Loan_Repayments(Payment_Status);
GO

/* ============================================================
   Sample INSERT statements (one representative row per table)
   ============================================================ */

INSERT INTO dbo.Loan_Product_Master
    (Loan_Type, Typical_Min_Amount, Typical_Max_Amount, Typical_Tenure, Base_Interest_Rate, Risk_Level)
VALUES
    ('Home Loan', 500000, 10000000, 240, 8.60, 'Low');

INSERT INTO dbo.Branches
    (Branch_ID, Branch_Name, City, State, Region, Branch_Type, Branch_Manager, Opening_Year)
VALUES
    ('BR0001', 'Kolkata City Branch', 'Kolkata', 'West Bengal', 'East', 'Metro', 'Anil Kumar', 2005);

INSERT INTO dbo.Customers
    (Customer_ID, Customer_Name, Age, Gender, Marital_Status, Employment_Type, Occupation,
     Annual_Income, Years_Employed, City, State, Region, Credit_Score, Existing_Loans,
     Existing_EMI, Customer_Segment, Risk_Category)
VALUES
    ('CUST000001', 'Rohan Sharma', 34, 'Male', 'Married', 'Salaried', 'Software Engineer',
     1250000, 9, 'Kolkata', 'West Bengal', 'East', 742, 1, 8500, 'Mass Affluent', 'Low');

INSERT INTO dbo.Loan_Applications
    (Application_ID, Customer_ID, Branch_ID, Application_Date, Loan_Type, Loan_Purpose,
     Requested_Amount, Loan_Term_Months, Interest_Rate, Application_Status, Approval_Date, Rejection_Reason)
VALUES
    ('APP0000001', 'CUST000001', 'BR0001', '2024-03-14', 'Home Loan', 'Purchase of Flat',
     4500000, 240, 8.75, 'Approved', '2024-03-25', NULL);

INSERT INTO dbo.Loan_Accounts
    (Loan_ID, Application_ID, Customer_ID, Branch_ID, Loan_Type, Disbursement_Date,
     Disbursed_Amount, Interest_Rate, Loan_Term_Months, EMI, Outstanding_Amount,
     Principal_Repaid, Interest_Paid, Loan_Status, Days_Past_Due, Default_Flag, NPA_Flag)
VALUES
    ('LOAN0000001', 'APP0000001', 'CUST000001', 'BR0001', 'Home Loan', '2024-03-30',
     4380000, 8.75, 240, 38452, 4150000, 230000, 95000, 'Active', 0, 0, 0);

INSERT INTO dbo.Loan_Repayments
    (Repayment_ID, Loan_ID, Customer_ID, Payment_Date, Due_Date, EMI_Amount, Paid_Amount,
     Payment_Status, Days_Past_Due, Payment_Method)
VALUES
    ('RPY00000001', 'LOAN0000001', 'CUST000001', '2026-08-04', '2026-08-05', 38452, 38452,
     'Paid On Time', 0, 'Auto Debit');
GO

/* ============================================================
   Example analysis queries (illustrative — not required to run)
   ============================================================ */

-- Approval rate by loan type
SELECT Loan_Type,
       COUNT(*)                                              AS Total_Applications,
       SUM(CASE WHEN Application_Status = 'Approved' THEN 1 ELSE 0 END) AS Approved,
       CAST(SUM(CASE WHEN Application_Status = 'Approved' THEN 1 ELSE 0 END) AS DECIMAL(10,4))
           / COUNT(*) AS Approval_Rate
FROM dbo.Loan_Applications
GROUP BY Loan_Type
ORDER BY Approval_Rate DESC;

-- Default rate by credit-score band (CASE + conditional aggregation)
SELECT CASE
           WHEN c.Credit_Score < 580 THEN '300-579 (Poor)'
           WHEN c.Credit_Score < 670 THEN '580-669 (Fair)'
           WHEN c.Credit_Score < 740 THEN '670-739 (Good)'
           WHEN c.Credit_Score < 800 THEN '740-799 (Very Good)'
           ELSE '800-850 (Excellent)'
       END AS Credit_Score_Band,
       COUNT(*)                              AS Total_Loans,
       SUM(la.Default_Flag)                  AS Defaulted_Loans,
       CAST(SUM(la.Default_Flag) AS DECIMAL(10,4)) / COUNT(*) AS Default_Rate
FROM dbo.Loan_Accounts la
INNER JOIN dbo.Customers c ON c.Customer_ID = la.Customer_ID
GROUP BY CASE
           WHEN c.Credit_Score < 580 THEN '300-579 (Poor)'
           WHEN c.Credit_Score < 670 THEN '580-669 (Fair)'
           WHEN c.Credit_Score < 740 THEN '670-739 (Good)'
           WHEN c.Credit_Score < 800 THEN '740-799 (Very Good)'
           ELSE '800-850 (Excellent)'
       END
ORDER BY Default_Rate DESC;

-- Branch ranking within region by total disbursed amount (window functions)
WITH Branch_Disbursement AS (
    SELECT b.Region, b.Branch_ID, b.Branch_Name, SUM(la.Disbursed_Amount) AS Total_Disbursed
    FROM dbo.Loan_Accounts la
    INNER JOIN dbo.Branches b ON b.Branch_ID = la.Branch_ID
    GROUP BY b.Region, b.Branch_ID, b.Branch_Name
)
SELECT *,
       RANK()       OVER (PARTITION BY Region ORDER BY Total_Disbursed DESC) AS Rank_In_Region,
       DENSE_RANK() OVER (ORDER BY Total_Disbursed DESC)                     AS Overall_Dense_Rank
FROM Branch_Disbursement
ORDER BY Region, Rank_In_Region;

-- Month-over-month repayment trend using LAG
WITH Monthly AS (
    SELECT FORMAT(Due_Date, 'yyyy-MM') AS Due_Month,
           SUM(Paid_Amount)            AS Total_Collected
    FROM dbo.Loan_Repayments
    GROUP BY FORMAT(Due_Date, 'yyyy-MM')
)
SELECT Due_Month,
       Total_Collected,
       LAG(Total_Collected)  OVER (ORDER BY Due_Month) AS Prev_Month_Collected,
       LEAD(Total_Collected) OVER (ORDER BY Due_Month) AS Next_Month_Collected
FROM Monthly
ORDER BY Due_Month;
