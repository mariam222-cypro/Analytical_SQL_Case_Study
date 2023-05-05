#Background:
#Analytical SQL Case Study
#Customers has purchasing transaction that we shall be monitoring to get intuition behind each customer behavior to target the customers in the most efficient and proactive way, to increase sales/revenue , improve customer retention and decrease churn.
#You will be given a dataset, and you will be required to answer using SQL Analytical functions you have learnt in the course.


#Q1- Using OnlineRetail dataset
#• write at least 5 analytical SQL queries that tells a story about the data
#• write small description about the business meaning behind each query

First lets see the the total price and total quantity per each invoice 

SELECT Invoice,customer_id, round(SUM(Price * Quantity)) AS Total_Price, count(stockcode) as Number_of_Products
FROM tableRetail
GROUP BY Invoice,customer_id
order by Total_Price desc;

then we want to see which product is selling the most :
the most selling product 
SELECT 
	StockCode,
	Total_Quantity
FROM 
	(SELECT 
		StockCode, 
		SUM(Quantity) AS Total_Quantity,
		percent_rank() OVER (ORDER BY SUM(Quantity) DESC) AS percent_rank
	FROM 
		tableRetail
	GROUP BY 
		StockCode)t
order by Total_Quantity desc;


then we want to make sure if they are making the most profits or not !

SELECT 
	StockCode,
	Total_Quantity,
	Total_Price
FROM 
	(SELECT 
		StockCode, 
		SUM(Quantity) AS Total_Quantity,
		round(SUM(Price * Quantity)) AS Total_Price,
		percent_rank() OVER (ORDER BY SUM(Quantity) DESC) AS percent_rank
	FROM 
		tableRetail
	GROUP BY 
		StockCode)t
order by Total_Quantity desc;

the answer is no!

then lets see the % of each product from total profits 

SELECT 
	StockCode,
	Total_Quantity,
	Total_Price,
	ROUND(CAST(Total_Price / SUM(Total_Price) OVER () * 100 as numeric),2) || '%' AS Profit_Percentage
FROM 
	(SELECT 
		StockCode, 
		SUM(Quantity) AS Total_Quantity,
		ROUND(SUM(Price * Quantity)) AS Total_Price,
		percent_rank() OVER (ORDER BY SUM(Price * Quantity) DESC) AS Percent_Rank
	FROM 
		tableRetail
	GROUP BY 
		StockCode) t
ORDER BY 
	Total_Price DESC;
	
then lets see which is sold together ?

WITH product_pairs AS (
	SELECT 
		t1.StockCode AS product1, 
		t2.StockCode AS product2, 
		COUNT(DISTINCT t1.Invoice) AS purchase_count
	FROM 
		tableRetail t1
		JOIN tableRetail t2 ON t1.Invoice = t2.Invoice AND t1.StockCode < t2.StockCode
	GROUP BY 
		t1.StockCode, t2.StockCode
)
SELECT 
	product1,product2,purchase_count
FROM 
	product_pairs
ORDER BY 
	purchase_count DESC;
	
ok lets now see wich month is the most selling month :

SELECT 
	Year,Month,round(Cast(Total_Profit as numeric),2) as Total_Profit,
	RANK() OVER (PARTITION BY Year ORDER BY Total_Profit DESC) AS Rank
FROM 
	(SELECT 
		EXTRACT(YEAR FROM TO_DATE(InvoiceDate, 'MM/DD/YYYY'))  AS Year, 
		EXTRACT(MONTH FROM TO_DATE(InvoiceDate, 'MM/DD/YYYY')) AS Month,
		SUM(Price * Quantity) AS Total_Profit
	from tableRetail
	group by Year,Month
	)t
ORDER BY Rank,Year, Month;

now lets go to customer: What is the average order size by customer?

SELECT DISTINCT customer_id,
	round(Cast(Avg(Total_Price) over (partition by customer_id) as numeric),2) As Avg_Order_profit,
    round(Cast(Avg(Sum_Quantity) over (partition by customer_id) as numeric),2) As Avg_Order_size
FROM (SELECT customer_id, Sum_Quantity,
     ROUND(Cast( Total_Price as numeric), 2) AS Total_Price
    FROM (
		select 
		SUM(Price * Quantity) as Total_Price ,
		customer_id,
		count(quantity) as Sum_Quantity
		from tableRetail 
		GROUP BY customer_id )tt)t
ORDER BY Avg_Order_Size DESC;

the whole avg and size 


SELECT DISTINCT customer_id,
	round(Cast(Avg(Total_Price) over (partition by customer_id) as numeric),2) As Avg_Order_profit,
    round(Cast(Avg(Sum_Quantity) over (partition by customer_id) as numeric),2) As Avg_Order_size
FROM (SELECT customer_id, Sum_Quantity,
     ROUND(Cast( Total_Price as numeric), 2) AS Total_Price
    FROM (
		select 
		SUM(Price * Quantity) as Total_Price ,
		customer_id,
		count(quantity) as Sum_Quantity
		from tableRetail 
		GROUP BY customer_id )tt)t
ORDER BY Avg_Order_Size DESC;


SELECT 
	round(Cast(Avg(Total_Price)  as numeric),2) As Avg_Order_profit,
    round(Cast(Avg(Sum_Quantity) as numeric),2) As Avg_Order_size
FROM (SELECT customer_id, Sum_Quantity,
     ROUND(Cast( Total_Price as numeric), 2) AS Total_Price
    FROM (
		select 
		SUM(Price * Quantity) as Total_Price ,
		customer_id,
		count(quantity) as Sum_Quantity
		from tableRetail 
		GROUP BY customer_id )tt)t
ORDER BY Avg_Order_Size DESC;

then lets see what are the top-selling products by month?

SELECT Year, Month, StockCode, Total_Quantity
FROM (
	SELECT 
		EXTRACT(YEAR FROM TO_DATE(InvoiceDate, 'MM/DD/YYYY')) AS Year,
		EXTRACT(MONTH FROM TO_DATE(InvoiceDate, 'MM/DD/YYYY')) AS Month,
		StockCode,
		SUM(Quantity) AS Total_Quantity,
		RANK() OVER (PARTITION BY EXTRACT(YEAR FROM TO_DATE(InvoiceDate, 'MM/DD/YYYY')), EXTRACT(MONTH FROM TO_DATE(InvoiceDate, 'MM/DD/YYYY')) ORDER BY SUM(Quantity) DESC) AS rank
	FROM tableRetail
	GROUP BY Year, Month, StockCode
) t
WHERE rank = 1
ORDER BY Year, Month;

so lets see What is the monthly revenue growth rate?


WITH revenue_monthly AS (
	SELECT
		EXTRACT(YEAR FROM TO_DATE(InvoiceDate, 'MM/DD/YYYY')) AS year,
		EXTRACT(MONTH FROM TO_DATE(InvoiceDate, 'MM/DD/YYYY')) AS month,
		SUM(Price * Quantity) AS revenue
	FROM
		tableRetail
	GROUP BY
		year,month
	ORDER BY
		year,month
),
revenue_previous_month AS (
	SELECT
		year,month,
		revenue,
		LAG(revenue) OVER (ORDER BY year,month) AS previous_revenue
	FROM
		revenue_monthly
)
SELECT
	year,
		month,
	round(revenue) as revenue ,
	round(previous_revenue) as previous_revenue,
	CASE
		WHEN previous_revenue IS NULL THEN 0
		ELSE ROUND(Cast((revenue - previous_revenue) / previous_revenue * 100 as numeric), 2)
	END AS revenue_growth_rate
FROM
	revenue_previous_month
ORDER BY
	year,month;
	
lets see which day usually has high sales Top days in 'day_name' by total 'total_sales'		 

SELECT sale_day, total_sales, day_name, is_weekend
FROM (
	SELECT EXTRACT(DAY FROM TO_DATE(InvoiceDate, 'MM/DD/YYYY')) AS sale_day,
			SUM(quantity * price) AS total_sales,
			to_char(TO_DATE(InvoiceDate, 'MM/DD/YYYY'), 'Day') AS day_name,
			CASE
				WHEN DATE_PART('dow', TO_DATE(InvoiceDate, 'MM/DD/YYYY')) IN (0, 6) THEN 'Weekend'
				ELSE 'Weekday'
			END AS is_weekend,
			RANK() OVER (ORDER BY SUM(quantity * price) DESC) AS sales_rank
	FROM tableretail
	GROUP BY EXTRACT(DAY FROM TO_DATE(InvoiceDate, 'MM/DD/YYYY')), tableretail.InvoiceDate
) AS subquery
order by total_sales desc;
	
--Q2
#After exploring the data now you are required to implement a Monetary model for customers behavior for product purchasing and segment each customer based on the below groups

WITH customer_data AS (
	SELECT 
		Customer_ID, 
		(SELECT MAX(TO_DATE(InvoiceDate, 'MM/DD/YYYY HH24:MI')) FROM tableRetail) - MAX(TO_DATE(InvoiceDate, 'MM/DD/YYYY HH24:MI')) AS Recency,
		COUNT(Distinct Invoice) AS Frequency,
		ROUND(CAST(SUM(Price * Quantity) AS NUMERIC), 2) AS Monetary,
		NTILE(5) OVER (ORDER BY (SELECT MAX(TO_DATE(InvoiceDate, 'MM/DD/YYYY HH24:MI')) 
		FROM tableRetail) - MAX(TO_DATE(InvoiceDate, 'MM/DD/YYYY HH24:MI')) DESC) AS R_Score,
		NTILE(5) OVER (ORDER BY (SELECT NTILE(5) OVER (ORDER BY COUNT(Distinct Invoice) DESC)FROM tableRetail 
    	WHERE Customer_ID = t.Customer_ID) + (SELECT NTILE(5) OVER (ORDER BY SUM(Price * Quantity) DESC) FROM tableRetail WHERE Customer_ID = t.Customer_ID) - 1 DESC) AS F_M_Score	
	FROM 
		tableRetail t
	GROUP BY 
		Customer_ID
	)
	SELECT 
		Customer_ID, 
		Recency, 
		Frequency, 
		Monetary,
		R_Score,
		F_M_Score,
		CASE 
			WHEN R_Score = 5 AND F_M_Score IN (5, 4) THEN 'Champions'
			WHEN R_Score = 5 AND F_M_Score = 2 THEN 'Potential Loyalists'
			WHEN R_Score = 4 AND F_M_Score IN (5, 3) THEN 'Loyal Customers'
			WHEN R_Score = 4 AND F_M_Score = 4 THEN 'Loyal Customers'
			WHEN R_Score = 3 AND F_M_Score IN (3, 4) THEN 'Potential Loyalists'
			WHEN R_Score = 5 AND F_M_Score = 3 THEN 'Loyal Customers'
			WHEN R_Score = 4 AND F_M_Score = 3 THEN 'Potential Loyalists'
			WHEN R_Score = 4 AND F_M_Score = 2 THEN 'Potential Loyalists'
			WHEN R_Score = 3 AND F_M_Score = 5 THEN 'Loyal Customers'
			WHEN R_Score = 5 AND F_M_Score = 1 THEN 'Recent Customers'
			WHEN R_Score = 4 AND F_M_Score = 1 THEN 'Promising'
			WHEN R_Score = 3 AND F_M_Score = 1 THEN 'Promising'
			WHEN R_Score = 2 AND F_M_Score IN (2, 3) THEN 'Customers Needing Attention'
			WHEN R_Score = 2 AND F_M_Score IN (4, 5) THEN 'At Risk'
			WHEN R_Score = 1 AND F_M_Score IN (2, 3) THEN 'Hibernating'
			WHEN R_Score = 1 AND F_M_Score IN (4, 5) THEN 'Cant Lose Them'
			WHEN R_Score = 1 AND F_M_Score = 1 THEN 'Lost'
			ELSE 'Undefined'
		END AS Customer_Segment
	FROM 
		customer_data
	ORDER BY 
		Recency DESC;
--- Q3
	#Q3- You are given the below dataset, Which is the daily purchasing transactions for customers.
	#What is the maximum number of consecutive days a customer made purchases?
A:	
	WITH customer_purchases AS (
		SELECT 
			Cust_Id, 
			Calendar_Dt, 
			Amt_LE, 
			LAG(Calendar_Dt) OVER (PARTITION BY Cust_Id ORDER BY Calendar_Dt) AS prev_date
		FROM 
			transactions
	),
	consecutive_days AS (
		SELECT 
			Cust_Id, 
			Calendar_Dt, 
			Amt_LE, 
			prev_date,
			COALESCE((Calendar_Dt - prev_date)::integer - 1, 0) AS day_diff,
			SUM(CASE WHEN COALESCE((Calendar_Dt - prev_date)::integer - 1, 0) = 1 THEN 1 ELSE 0 END) 
				OVER (PARTITION BY Cust_Id ORDER BY Calendar_Dt) AS consecutive_days
		FROM 
			customer_purchases
	)
	SELECT 
		Cust_Id,
		MAX(consecutive_days) AS max_consecutive_days
	FROM 
		consecutive_days
	GROUP BY
		Cust_Id
	order by max_consecutive_days desc ;
	
	
#On average, How many days/transactions does it take a customer to reach a spent threshold of 250 L.E?
	
B:

WITH customer_totals AS (
	SELECT
		Cust_Id,
		Calendar_Dt,
		Amt_LE,
		SUM(Amt_LE) OVER (PARTITION BY Cust_Id ORDER BY Calendar_Dt) AS running_total_spent
	FROM
		transactions
),
customer_thresholds AS (
	SELECT
		Cust_Id,
		Calendar_Dt,
		running_total_spent
	FROM
		customer_totals
	WHERE
		running_total_spent < 250
),
customer_thresholds_reached AS (
	SELECT
		Cust_Id,
		Calendar_Dt,
		running_total_spent
	FROM
		customer_totals
	WHERE
		running_total_spent >= 250
), 
customer_threshold_counts AS (
	SELECT
		Cust_Id,
		COUNT(Calendar_Dt) AS days_to_threshold
	FROM
		customer_thresholds
	WHERE
		Cust_Id IN (SELECT Cust_Id FROM customer_thresholds_reached)
	GROUP BY
		Cust_Id
	ORDER BY
		Cust_Id
)

SELECT
	ROUND(AVG(days_to_threshold)) AS avg_days_to_threshold
FROM
	customer_threshold_counts;
	
	