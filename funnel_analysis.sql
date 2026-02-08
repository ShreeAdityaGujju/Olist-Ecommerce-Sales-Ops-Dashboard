USE olist_analytics;

-- Funnel stages (Order Created -> Approved -> Shipped -> Delivered -> Reviewed)
-- Created: has purchase_ts
-- Approved: approved_ts not null
-- Shipped: carrier_ts not null
-- Delivered: delivered_ts not null
-- Reviewed: has a review record

WITH curated_table AS (
  SELECT
	o.order_id,
    o.purchase_ts,
    o.approved_ts,
    o.carrier_ts,
    o.delivered_ts,
    MAX(r.review_id IS NOT NULL) AS has_review
  FROM fact_orders o
  LEFT JOIN fact_reviews r
    ON r.order_id = o.order_id
  WHERE o.purchase_ts IS NOT NULL
  GROUP BY
    o.order_id, o.purchase_ts, o.approved_ts, o.carrier_ts, o.delivered_ts
)

SELECT
  COUNT(*) AS created_orders,
  SUM(approved_ts IS NOT NULL) AS approved_orders,
  SUM(carrier_ts IS NOT NULL) AS shipped_orders,
  SUM(delivered_ts IS NOT NULL) AS delivered_orders,
  SUM(has_review = 1) AS reviewed_orders,
  ROUND(100 * SUM(approved_ts IS NOT NULL) / COUNT(*), 2) AS created_to_approved_pct,
  ROUND(100 * SUM(carrier_ts IS NOT NULL) / NULLIF(SUM(approved_ts IS NOT NULL),0), 2) AS approved_to_shipped_pct,
  ROUND(100 * SUM(delivered_ts IS NOT NULL) / NULLIF(SUM(carrier_ts IS NOT NULL),0), 2) AS shipped_to_delivered_pct,
  ROUND(100 * SUM((delivered_ts IS NOT NULL) AND (has_review = 1))/ NULLIF(SUM(delivered_ts IS NOT NULL), 0),2) AS delivered_to_reviewed_pct

FROM curated_table;

-- FUNNEL BY MONTH

WITH curated_table2 AS (
  SELECT
	DATE_FORMAT(o.purchase_ts, "%Y-%m-01") as month_start,
	o.order_id,
    o.purchase_ts,
    o.approved_ts,
    o.carrier_ts,
    o.delivered_ts,
    MAX(r.review_id IS NOT NULL) AS has_review
  FROM fact_orders o
  LEFT JOIN fact_reviews r
    ON r.order_id = o.order_id
  WHERE o.purchase_ts IS NOT NULL
  GROUP BY
    month_start,o.order_id, o.approved_ts, o.carrier_ts, o.delivered_ts
)

SELECT
  month_start,
  DATE_FORMAT(month_start, '%Y %M') AS month_label,
  COUNT(*) AS created_orders,
  
  SUM(approved_ts IS NOT NULL) AS approved_orders,
  SUM(carrier_ts IS NOT NULL) AS shipped_orders,
  SUM(delivered_ts IS NOT NULL) AS delivered_orders,
  SUM(has_review = 1) AS reviewed_orders,
  
  ROUND(100 * SUM(approved_ts IS NOT NULL) / COUNT(*), 2) AS created_to_approved_pct,
  ROUND(100 * SUM(carrier_ts IS NOT NULL) / NULLIF(SUM(approved_ts IS NOT NULL),0), 2) AS approved_to_shipped_pct,
  ROUND(100 * SUM(delivered_ts IS NOT NULL) / NULLIF(SUM(carrier_ts IS NOT NULL),0), 2) AS shipped_to_delivered_pct,
  ROUND(100 * SUM((delivered_ts IS NOT NULL) AND (has_review = 1))/ NULLIF(SUM(delivered_ts IS NOT NULL), 0),2) AS delivered_to_reviewed_pct

FROM curated_table2
GROUP BY month_start,month_label
ORDER BY month_start;