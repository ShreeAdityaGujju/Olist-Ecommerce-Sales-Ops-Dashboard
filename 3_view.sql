USE olist_analytics;

-- Customers
INSERT INTO dim_customers (customer_id, customer_unique_id, zip_prefix, city, state)
SELECT 
  DISTINCT customer_id,
  customer_unique_id,
  NULLIF(customer_zip_code_prefix, '') + 0,
  NULLIF(customer_city, ''),
  NULLIF(customer_state, '')
FROM stg_customers;

-- Sellers
INSERT INTO dim_sellers (seller_id, zip_prefix, city, state)
SELECT
  seller_id,
  NULLIF(seller_zip_code_prefix, '') + 0,
  NULLIF(seller_city, ''),
  NULLIF(seller_state, '')
FROM stg_sellers;

-- Products + category translation
INSERT INTO dim_products (product_id, category_pt, category_en, weight_g, length_cm, height_cm, width_cm)
SELECT
  p.product_id,
  NULLIF(p.product_category_name, '') AS category_pt,
  NULLIF(t.product_category_name_english, '') AS category_en,
  NULLIF(p.product_weight_g, '') + 0,
  NULLIF(p.product_length_cm, '') + 0,
  NULLIF(p.product_height_cm, '') + 0,
  NULLIF(p.product_width_cm, '') + 0
FROM stg_products p
LEFT JOIN stg_category_translation t
  ON p.product_category_name = t.product_category_name;

-- Orders 
INSERT INTO fact_orders (
  order_id, customer_id, order_status,
  purchase_ts, approved_ts, carrier_ts, delivered_ts, estimated_delivery_date
)
SELECT
  order_id,
  customer_id,
  order_status,
  STR_TO_DATE(NULLIF(order_purchase_timestamp, ''), '%Y-%m-%d %H:%i:%s'),
  STR_TO_DATE(NULLIF(order_approved_at, ''), '%Y-%m-%d %H:%i:%s'),
  STR_TO_DATE(NULLIF(order_delivered_carrier_date, ''), '%Y-%m-%d %H:%i:%s'),
  STR_TO_DATE(NULLIF(order_delivered_customer_date, ''), '%Y-%m-%d %H:%i:%s'),
  STR_TO_DATE(NULLIF(order_estimated_delivery_date, ''), '%Y-%m-%d %H:%i:%s')
FROM stg_orders;

-- Items
INSERT INTO fact_order_items (
  order_id, order_item_id, product_id, seller_id, shipping_limit_ts, price, freight_value
)
SELECT
  order_id,
  NULLIF(order_item_id, '') + 0,
  product_id,
  seller_id,
  STR_TO_DATE(NULLIF(shipping_limit_date, ''), '%Y-%m-%d %H:%i:%s'),
  CAST(NULLIF(price, '') AS DECIMAL(10,2)),
  CAST(NULLIF(freight_value, '') AS DECIMAL(10,2))
FROM stg_order_items;

-- Payments
INSERT INTO fact_payments (
  order_id, payment_seq, payment_type, installments, payment_value
)
SELECT
  order_id,
  NULLIF(payment_sequential, '') + 0,
  NULLIF(payment_type, ''),
  NULLIF(payment_installments, '') + 0,
  CAST(NULLIF(payment_value, '') AS DECIMAL(12,2))
FROM stg_payments;

-- Reviews
INSERT INTO fact_reviews (
  review_id, order_id, review_score, review_created_date, review_answer_ts
)
SELECT
  review_id,
  MAX(order_id) AS order_id,
  MAX(NULLIF(review_score, '') + 0) AS review_score,

  MAX(
    DATE(
      STR_TO_DATE(
        SUBSTRING(NULLIF(review_creation_date, ''), 1, 19),
        '%Y-%m-%d %H:%i:%s'
      )
    )
  ) AS review_created_date,

  MAX(
    STR_TO_DATE(
      SUBSTRING(NULLIF(review_answer_timestamp, ''), 1, 19),
      '%Y-%m-%d %H:%i:%s'
    )
  ) AS review_answer_ts
FROM stg_reviews
GROUP BY review_id;



-- Order-level revenue (items + freight)
DROP VIEW IF EXISTS v_order_revenue;
CREATE VIEW v_order_revenue AS
SELECT
  o.order_id,
  o.customer_id,
  o.order_status,
  o.purchase_ts,
  DATE(o.purchase_ts) AS purchase_date,
  DATE_FORMAT(o.purchase_ts, '%Y-%m-01') AS purchase_month,
  SUM(oi.price) AS items_revenue,
  SUM(oi.freight_value) AS freight_revenue,
  SUM(oi.price + oi.freight_value) AS gross_revenue,
  COUNT(*) AS items_count
FROM fact_orders o
JOIN fact_order_items oi
  ON oi.order_id = o.order_id
GROUP BY o.order_id, o.customer_id, o.order_status, o.purchase_ts;

-- Payment total per order
DROP VIEW IF EXISTS v_order_payments;
CREATE VIEW v_order_payments AS
SELECT
  order_id,
  SUM(payment_value) AS paid_value,
  MAX(payment_type) AS primary_payment_type,
  MAX(installments) AS max_installments,
  COUNT(*) AS payment_records
FROM fact_payments
GROUP BY order_id;

-- Customer order sequence 
DROP VIEW IF EXISTS v_customer_orders;

CREATE VIEW v_customer_orders AS
SELECT
    c.customer_unique_id,
    o.order_id,
    o.purchase_ts,
    ROW_NUMBER() OVER (
        PARTITION BY c.customer_unique_id
        ORDER BY o.purchase_ts, o.order_id
    ) AS order_number
FROM fact_orders o
JOIN dim_customers c
    ON c.customer_id = o.customer_id
WHERE o.purchase_ts IS NOT NULL;


-- Delivery performance
DROP VIEW IF EXISTS v_delivery_metrics;
CREATE VIEW v_delivery_metrics AS
SELECT
  order_id,
  purchase_ts,
  approved_ts,
  carrier_ts,
  delivered_ts,
  estimated_delivery_date,
  TIMESTAMPDIFF(DAY, purchase_ts, delivered_ts) AS days_purchase_to_delivery,
  CASE
    WHEN delivered_ts IS NULL THEN NULL
    WHEN estimated_delivery_date IS NULL THEN NULL
    WHEN DATE(delivered_ts) > estimated_delivery_date THEN 1
    ELSE 0
  END AS is_late
FROM fact_orders;

-- KPI summary for the top of dashboard
DROP VIEW IF EXISTS v_kpi;
CREATE VIEW v_kpi AS
SELECT
  COUNT(DISTINCT o.order_id) AS total_orders,
  COUNT(DISTINCT c.customer_unique_id) AS total_customers,
  ROUND(SUM(orv.gross_revenue), 2) AS total_gross_revenue,
  ROUND(AVG(orv.gross_revenue), 2) AS avg_order_value,
  ROUND(AVG(dm.days_purchase_to_delivery), 2) AS avg_delivery_days,
  ROUND(100 * AVG(dm.is_late), 2) AS late_delivery_rate_pct
FROM fact_orders o
JOIN dim_customers c
  ON c.customer_id = o.customer_id
JOIN v_order_revenue orv
  ON orv.order_id = o.order_id
LEFT JOIN v_delivery_metrics dm
  ON dm.order_id = o.order_id
WHERE o.purchase_ts IS NOT NULL  AND dm.delivered_ts IS NOT NULL;

-- Monthly Performance
DROP VIEW IF EXISTS v_monthly_perf;
CREATE VIEW v_monthly_perf AS
SELECT
  DATE_FORMAT(o.purchase_ts, '%Y-%m-01') AS month,
  COUNT(*) AS created_orders,
  SUM(o.approved_ts IS NOT NULL) AS approved_orders,
  SUM(o.carrier_ts IS NOT NULL) AS shipped_orders,
  SUM(o.delivered_ts IS NOT NULL) AS delivered_orders,
  ROUND(SUM(orv.gross_revenue), 2) AS gross_revenue,
  ROUND(AVG(orv.gross_revenue), 2) AS aov
FROM fact_orders o
JOIN v_order_revenue orv
  ON orv.order_id = o.order_id
WHERE o.purchase_ts IS NOT NULL
GROUP BY month;

-- Category Performance
DROP VIEW IF EXISTS v_category_perf;
CREATE VIEW v_category_perf AS
SELECT
  COALESCE(p.category_en, p.category_pt, 'Unknown') AS category,
  COUNT(DISTINCT oi.order_id) AS orders,
  ROUND(SUM(oi.price), 2) AS items_revenue,
  ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
  ROUND(SUM(oi.price + oi.freight_value), 2) AS gross_revenue
FROM fact_order_items oi
JOIN dim_products p
  ON p.product_id = oi.product_id
GROUP BY category;

-- Delivery vs Review
DROP VIEW IF EXISTS v_delivery_review;
CREATE VIEW v_delivery_review AS
SELECT
  dm.order_id,
  dm.days_purchase_to_delivery,
  dm.is_late,
  MAX(r.review_score) AS review_score
FROM v_delivery_metrics dm
JOIN fact_reviews r
  ON r.order_id = dm.order_id
WHERE dm.days_purchase_to_delivery IS NOT NULL
GROUP BY dm.order_id, dm.days_purchase_to_delivery, dm.is_late;
