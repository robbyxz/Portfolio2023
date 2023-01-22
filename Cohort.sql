-- Cleaning Data


-- Total records - 541909
-- 135080 records have no customerID
-- 406829 records have customerID

;with Online_Retail$ as
(
	SELECT [InvoiceNo]
		  ,[StockCode]
		  ,[Description]
		  ,[Quantity]
		  ,[InvoiceDate]
		  ,[UnitPrice]
		  ,[CustomerID]
		  ,[Country]
	  FROM [PortfolioProject].[dbo].[Online_Retail$]
	  WHERE customerID IS NOT NULL
), quantity_unit_price as 
(

	-- 397884 records with quantity and unit price 
	SELECT *
	FROM Online_Retail$
	WHERE quantity > 0 and UnitPrice > 0 
), dup_check as

(
	-- Duplicate check
	SELECT *, ROW_NUMBER() over (partition by InvoiceNo, StockCode, Quantity order by InvoiceDate)dup_flag
	FROM quantity_unit_price
)

-- 392669 Clean data
-- 5215 duplicate records

SELECT *
INTO #online_retail_main -- Creating temp table
FROM dup_check
WHERE dup_flag = 1


--- CLEAN DATA
--- BEGIN ANALYSIS

SELECT * 
FROM #online_retail_main


-- Unique identifier (CUSTOMERID)
-- Initial Start Date (First Invoice Date)
-- Revenue Data

SELECT
	CustomerID,
	min(InvoiceDAte) as first_purchase_date,
	DATEFROMPARTS(YEAR(min(InvoiceDAte)), MONTH(min(InvoiceDAte)), 1) AS Cohort_Date
INTO #cohort																		-- Temp table
FROM #online_retail_main
GROUP BY CustomerID


SELECT *
FROM #cohort


-- Create Cohort Index

SELECT
	mmm.*,
	cohort_index = year_diff * 12 + month_diff + 1
INTO #cohort_retention
FROM 
	(
	SELECT
		mm.*,
		year_diff = invoice_year - cohort_year,
		month_diff = invoice_month - cohort_month
	FROM
		(
			SELECT
				m.*,
				c.Cohort_Date,
				year(m.InvoiceDate) as Invoice_Year,
				month(m.InvoiceDate) as Invoice_Month,
				year(c.Cohort_Date) as Cohort_Year,
				month(c.Cohort_Date) as Cohort_Month
			FROM #online_retail_main m
			LEFT JOIN #cohort c
				ON m.CustomerID = c.CustomerID
		)mm
	)mmm

SELECT *
FROM #cohort_retention


-- Pivot data to see cohort table

SELECT *
INTO #cohort_pivot
FROM
(

	SELECT DISTINCT
		CUSTOMERID,
		COHORT_DATE,
		COHORT_INDEX
	FROM #cohort_retention
)tbl

pivot(
	COUNT(CustomerID)
	FOR Cohort_Index In
			(
			[1],
			[2],
			[3],
			[4],
			[5],
			[6],
			[7],
			[8],
			[9],
			[10],
			[11],
			[12],
			[13]
			)
) as pivot_table

SELECT *

FROM #cohort_pivot
ORDER BY Cohort_Date

SELECT Cohort_Date,
		1.0*[1]/[1] * 100 as [1], 
		1.0*[2]/[1] * 100 as [2],
		1.0*[3]/[1] * 100 as [3], 
		1.0*[4]/[1] * 100 as [4],
		1.0*[5]/[1] * 100 as [5], 
		1.0*[6]/[1] * 100 as [6],
		1.0*[7]/[1] * 100 as [7], 
		1.0*[8]/[1] * 100 as [8],
		1.0*[9]/[1] * 100 as [9], 
		1.0*[10]/[1] * 100 as [10],
		1.0*[11]/[1] * 100 as [11], 
		1.0*[12]/[1] * 100 as [12],
		1.0*[13]/[1] * 100 as [13]
FROM #cohort_pivot
ORDER BY Cohort_Date