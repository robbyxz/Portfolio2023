-- Inspecting data

SELECT *
FROM dbo.sales_data_sample

-- Checking unique values

SELECT DISTINCT status  -- Nice one to plot
FROM dbo.sales_data_sample

SELECT DISTINCT year_id
FROM dbo.sales_data_sample

SELECT DISTINCT productline -- Nice to plot
FROM dbo.sales_data_sample

SELECT DISTINCT country -- Nice to plot
FROM dbo.sales_data_sample

SELECT DISTINCT dealsize -- Nice to plot
FROM dbo.sales_data_sample

SELECT DISTINCT territory -- Nice to plot
FROM dbo.sales_data_sample


-- Analysis
-- Grouping by productline

SELECT Productline, Sum(sales) as Revenue
FROM dbo.sales_data_sample
GROUP BY Productline
ORDER BY 2 desc

SELECT year_id, Sum(sales) as Revenue
FROM dbo.sales_data_sample
GROUP BY year_id
ORDER BY 2 desc

SELECT dealsize, Sum(sales) as Revenue
FROM dbo.sales_data_sample
GROUP BY dealsize
ORDER BY 2 desc

-- WHat was the best month for sales in a specific year? 
-- How much was earned that month?

SELECT month_id, sum(sales) as Revenue, count(ordernumber) as Frequency
FROM dbo.sales_data_sample
WHERE year_id = 2003 -- change year to see another years
GROUP BY month_id
ORDER BY 2 DESC

-- November seems to be the best month, what product do they sell in November?

SELECT Month_id, Productline, sum(sales) as Revenue, count(ordernumber) as Frequency
FROM dbo.sales_data_sample
WHERE Year_id = 2003 AND Month_id = 11
GROUP BY Month_id, Productline
ORDER BY 3 DESC


-- Who is the best customer?


SELECT *
FROM dbo.sales_data_sample


DROP TABLE IF EXISTS #rfm;
WITH rfm as
(
	SELECT
		CUSTOMERNAME,
		SUM(SALES) AS REVENUE,
		AVG(SALES) AS AVGMONETARYVALUE,
		COUNT(ORDERNUMBER) AS FREQUENCY,
		MAX(ORDERDATE) AS LASTORDERDATE,
		(SELECT MAX(ORDERDATE) from dbo.sales_data_sample) as Max_order_date,
		DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM DBO.sales_data_sample)) as RECENCY
	FROM dbo.sales_data_sample
	GROUP BY CUSTOMERNAME
),
rfm_calc as
(
SELECT r.*,
	NTILE(4) OVER (ORDER BY RECENCY DESC) AS RFM_RECENCY,
	NTILE(4) OVER (ORDER BY FREQUENCY ) AS RFM_FREQUENCY,
	NTILE(4) OVER (ORDER BY AVGMONETARYVALUE) AS RFM_MONETARY
FROM rfm r
)
SELECT 
	c.*, rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar) as RFM_CELL_STRING
INTO #rfm
FROM rfm_calc c

SELECT *
FROM #rfm


SELECT CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary,
	CASE
		WHEN rfm_cell <= 3 THEN 'New customer'
		WHEN rfm_cell BETWEEN 3 and 6 THEN 'Lost customer'
		WHEN rfm_cell BETWEEN 6 AND 9 THEN 'Active customer'
		ELSE 'Loyal customer'
	END as rfm_segment
FROM #rfm



-- What products are most often sold together?

SELECT DISTINCT ORDERNUMBER, STUFF(
	(SELECT ',' + PRODUCTCODE
	FROM dbo.sales_data_sample p
	WHERE ORDERNUMBER in
		( 
		SELECT ORDERNUMBER
		FROM (
			SELECT ORDERNUMBER, COUNT(*) rn
			FROM dbo.sales_data_sample
			WHERE STATUS = 'Shipped'
			GROUP BY ORDERNUMBER
			)m
			WHERE rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		FOR XML PATH (''))

		, 1, 1, '') PRODUCTCODES

FROM dbo.sales_data_sample s
ORDER BY 2 DESC