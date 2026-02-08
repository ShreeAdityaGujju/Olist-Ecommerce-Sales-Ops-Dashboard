USE olist_analytics;

-- Repeat customer rate
WITH cust AS (
SELECT customer_unique_id,MAX(order_number)AS total_orders
FROM v_customer_orders
GROUP BY customer_unique_id
)
SELECT
	COUNT(*)AS customers,
	SUM(total_orders=1)AS one_time_customers,
	SUM(total_orders>=2)AS repeat_customers,
	ROUND(100*SUM(total_orders>=2)/COUNT(*),2)AS repeat_rate_pct
FROM cust;

-- High Value Customers

SELECT
  c.customer_unique_id,
  COUNT(DISTINCT orv.order_id)AS orders,
  ROUND(SUM(orv.gross_revenue),2)AS total_revenue,
  ROUND(AVG(orv.gross_revenue),2)AS avg_order_value
FROM v_order_revenue orv
JOIN dim_customers c ON c.customer_id= orv.customer_id
GROUP BY c.customer_unique_id
ORDER BY total_revenue DESC
LIMIT 20;

-- DELIVERY DELAY
SELECT
  dm.is_late,
  COUNT(*)AS reviewed_orders,
  ROUND(AVG(r.review_score),2)AS avg_review_score
FROM v_delivery_metrics dm
JOIN fact_reviews r ON r.order_id= dm.order_id
WHERE dm.delivered_ts IS NOT NULL
GROUP BY dm.is_late
ORDER BY dm.is_late;

-- DELIVERY TUME BUCKETS
SELECT
	CASE
		WHEN dm.days_purchase_to_delivery<=3 THEN '0-3 days'
		WHEN dm.days_purchase_to_delivery<=7 THEN '4-7 days'
		WHEN dm.days_purchase_to_delivery<=14 THEN '8-14 days'
		ELSE '15+ days'
	END AS delivery_bucket,
COUNT(*)AS reviewed_orders,
  ROUND(AVG(r.review_score),2)AS avg_review_score
FROM v_delivery_metrics dm
JOIN fact_reviews r ON r.order_id= dm.order_id
WHERE dm.days_purchase_to_delivery IS NOT NULL
GROUP BY delivery_bucket
ORDER BY
CASE delivery_bucket
	WHEN'0-3 days' THEN 1
	WHEN'4-7 days' THEN 2 
	WHEN'8-14 days' THEN 3
	ELSE 4
END;