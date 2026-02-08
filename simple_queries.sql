USE olist_analytics;

-- Row counts for each component
SELECT 'customers' AS components, COUNT(*) AS counts FROM dim_customers
UNION ALL 
	SELECT 'sellers', COUNT(*) FROM dim_sellers
UNION ALL 
	SELECT 'products', COUNT(*) FROM dim_products
UNION ALL 
	SELECT 'orders', COUNT(*) FROM fact_orders
UNION ALL 
	SELECT 'items', COUNT(*) FROM fact_order_items
UNION ALL 
	SELECT 'payments', COUNT(*) FROM fact_payments
UNION ALL 
	SELECT 'reviews', COUNT(*) FROM fact_reviews;
    
-- Number of orders by status
SELECT order_status, COUNT(*) as number_of_orders
FROM fact_orders
GROUP BY order_status
ORDER BY number_of_orders DESC;

-- Number of orders by month and revenue
SELECT DATE_FORMAT(purchase_month, "%Y %b"), 
	ROUND(SUM(gross_revenue),2 ) AS gross_revenue,
    COUNT(*) AS number_of_orders
FROM v_order_revenue
WHERE purchase_ts IS NOT NULL
GROUP BY purchase_month
ORDER BY purchase_month;

-- AOV (avg order value)
SELECT
    ROUND(AVG(gross_revenue), 2) AS avg_order_value
FROM v_order_revenue;

-- MOV (median order value)
SELECT 
    ROUND(AVG(CASE 
                WHEN rn IN (floor((cnt+1)/2), floor((cnt+2)/2)) 
                THEN gross_revenue 
            END), 
    2) AS median_order_value
FROM (SELECT 
        gross_revenue,
        ROW_NUMBER() OVER (ORDER BY gross_revenue) AS rn,
        COUNT(*) OVER () AS cnt
    FROM v_order_revenue
) t;



    