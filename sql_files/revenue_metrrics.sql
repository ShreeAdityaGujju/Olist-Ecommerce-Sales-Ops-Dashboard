USE olist_analytics;

-- Revenue by Category
SELECT 
	COALESCE(p.category_en, p.category_pt, 'Unknown') AS category,
    ROUND(SUM(oi.price),2) AS items_revenue,
    ROUND(SUM(oi.freight_value),2) AS freight,
    ROUND(SUM(oi.price + oi.freight_value),2) AS gross_revenue,
    COUNT(DISTINCT oi.order_id) AS orders
FROM fact_order_items oi
JOIN dim_products p on p.product_id = oi.product_id
GROUP BY category
ORDER BY gross_revenue DESC
LIMIT 15;

-- Revenue by payment type
SELECT
  op.primary_payment_type AS payment_type,
  COUNT(*) AS orders,
  ROUND(SUM(orv.gross_revenue),2) AS gross_revenue,
  ROUND(AVG(orv.gross_revenue),2) AS aov
FROM v_order_revenue orv
JOIN v_order_payments op ON op.order_id = orv.order_id
GROUP BY payment_type
ORDER BY gross_revenue DESC;

-- MoM growth
WITH m AS (
SELECT
    purchase_month,
	SUM(gross_revenue)AS revenue
FROM v_order_revenue
GROUP BY purchase_month
)
SELECT
  purchase_month,
  ROUND(revenue,2)AS revenue,
  ROUND(
	100*(revenue-LAG(revenue) OVER(ORDER BY purchase_month))/NULLIF(LAG(revenue) OVER (ORDER BY purchase_month),0),2
  )AS mom_growth_pct
FROM m
WHERE purchase_month < '2018-09-01'
ORDER BY purchase_month;