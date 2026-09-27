# Retail Banking Credit Risk & Loan Portfolio Analytics

## Business Problem
A retail bank operating across India needed to understand whether its loan 
portfolio was healthy, where credit risk was concentrated, and how losses 
could be reduced while continuing to grow responsibly.

## Approach
Built a synthetic but realistic relational dataset (100,000 customers, 
200,000 loan applications, 130,000 loan accounts, 745,482 repayment 
transactions) across 6 SQL Server tables, then analyzed it using SQL, 
Excel, and Power BI.

- SQL Server: designed schema with proper primary/foreign keys, wrote 
  7 analytical queries using joins, CTEs, window functions (RANK, 
  DENSE_RANK, LAG, LEAD), subqueries, and conditional aggregation
- Excel/Power Query: connected directly to SQL Server, cleaned missing 
  values, built pivot tables and charts
- Power BI: built a 3-page interactive dashboard with DAX measures, 
  slicers, and drill-down capability

## Key Findings
1. Portfolio scale: 100,000 customers, 200,000 applications, 68.3% approval rate
2. Credit scoring works: default rate rises from 1.1% (Excellent score) to 
   17.4% (Poor score) - a 15x difference
3. Risk concentration: High-risk customers are only 13% of the base but have 
   a 19.7% default rate (7.6x higher than Low-risk), representing ₹235 Cr 
   in exposure
4. Current portfolio stress: 6.4% NPA rate, ₹1,497.7 Cr overdue, with 
   overdue loans averaging 130+ days past due
5. Product performance: Home Loans are the best asset (lowest default rate 
   2.85%, highest interest earned); Gold Loans carry the highest default 
   rate (6.95%)
6. Self-Employed customers show higher default rates than Salaried/Government 
   employees
7. Low Credit Score is the leading cause of application rejection
8. Default rate is consistent across regions (5.1%-5.3%), showing risk is 
   driven more by individual customer factors than geography

## Recommendations
- Tighten underwriting or require additional collateral for High-risk 
  customers and Gold Loan applicants
- Start collections outreach earlier (30-60 days late) rather than waiting 
  until loans reach 90+ day NPA status
- Continue expanding Home Loan lending given its strong risk-adjusted returns
- Apply stricter income verification for Self-Employed applicants

## Tools & Skills Demonstrated
SQL Server (T-SQL, joins, CTEs, window functions, subqueries), Excel 
(Power Query, Pivot Tables, data cleaning), Power BI (DAX, data modeling, 
interactive dashboards)