-- Staging the tables 
DROP TABLE IF EXISTS stg_orders;
CREATE TABLE stg_orders (
  order_id VARCHAR(64),
  customer_id VARCHAR(64),
  order_status VARCHAR(32),
  order_purchase_timestamp VARCHAR(32),
  order_approved_at VARCHAR(32),
  order_delivered_carrier_date VARCHAR(32),
  order_delivered_customer_date VARCHAR(32),
  order_estimated_delivery_date VARCHAR(32)
);

DROP TABLE IF EXISTS stg_order_items;
CREATE TABLE stg_order_items (
  order_id VARCHAR(64),
  order_item_id VARCHAR(32),
  product_id VARCHAR(64),
  seller_id VARCHAR(64),
  shipping_limit_date VARCHAR(32),
  price VARCHAR(32),
  freight_value VARCHAR(32)
);
DROP TABLE IF EXISTS stg_payments;
CREATE TABLE stg_payments (
  order_id VARCHAR(64),
  payment_sequential VARCHAR(32),
  payment_type VARCHAR(32),
  payment_installments VARCHAR(32),
  payment_value VARCHAR(32)
);

DROP TABLE IF EXISTS stg_reviews;
CREATE TABLE stg_reviews (
  review_id VARCHAR(64),
  order_id VARCHAR(64),
  review_score VARCHAR(32),
  review_comment_title TEXT,
  review_comment_message TEXT,
  review_creation_date VARCHAR(32),
  review_answer_timestamp VARCHAR(32)
);

DROP TABLE IF EXISTS stg_customers;
CREATE TABLE stg_customers (
  customer_id VARCHAR(64),
  customer_unique_id VARCHAR(64),
  customer_zip_code_prefix VARCHAR(32),
  customer_city VARCHAR(64),
  customer_state VARCHAR(16)
);

DROP TABLE IF EXISTS stg_products;
CREATE TABLE stg_products (
  product_id VARCHAR(64),
  product_category_name VARCHAR(128),
  product_name_lenght VARCHAR(32),
  product_description_lenght VARCHAR(32),
  product_photos_qty VARCHAR(32),
  product_weight_g VARCHAR(32),
  product_length_cm VARCHAR(32),
  product_height_cm VARCHAR(32),
  product_width_cm VARCHAR(32)
);

DROP TABLE IF EXISTS stg_sellers;
CREATE TABLE stg_sellers (
  seller_id VARCHAR(64),
  seller_zip_code_prefix VARCHAR(32),
  seller_city VARCHAR(64),
  seller_state VARCHAR(16)
);

DROP TABLE IF EXISTS stg_category_translation;
CREATE TABLE stg_category_translation (
  product_category_name VARCHAR(128),
  product_category_name_english VARCHAR(128)
);

-- ANALYTICS TABLES (typed)

DROP TABLE IF EXISTS dim_customers;
CREATE TABLE dim_customers (
  customer_id VARCHAR(64) PRIMARY KEY,
  customer_unique_id VARCHAR(64) NOT NULL,
  zip_prefix INT NULL,
  city VARCHAR(64) NULL,
  state CHAR(2) NULL,
  INDEX idx_customer_unique (customer_unique_id),
  INDEX idx_customer_state (state)
);

DROP TABLE IF EXISTS dim_products;
CREATE TABLE dim_products(
	product_id VARCHAR(64) PRIMARY KEY,
    category_pt VARCHAR(128) NULL,
    category_en VARCHAR(128) NULL,
    weight_g INT NULL,
    length_cm INT NULL,
    height_cm INT NULL,
    width_cm INT NULL,
    INDEX idx_products_category_en (category_en) 
     
);

DROP TABLE IF EXISTS dim_sellers;
CREATE TABLE dim_sellers (
  seller_id VARCHAR(64) PRIMARY KEY,
  zip_prefix INT NULL,
  city VARCHAR(64) NULL,
  state CHAR(2) NULL,
  INDEX idx_seller_state (state)
);

DROP TABLE IF EXISTS fact_orders;
CREATE TABLE fact_orders (
  order_id VARCHAR(64) PRIMARY KEY,
  customer_id VARCHAR(64) NOT NULL,
  order_status VARCHAR(32) NOT NULL,

  purchase_ts DATETIME NULL,
  approved_ts DATETIME NULL,
  carrier_ts DATETIME NULL,
  delivered_ts DATETIME NULL,
  estimated_delivery_date DATE NULL,

FOREIGN KEY (customer_id)REFERENCES dim_customers(customer_id),

  INDEX idx_orders_customer (customer_id),
  INDEX idx_orders_status (order_status),
  INDEX idx_orders_purchase_ts (purchase_ts)
);

DROP TABLE IF EXISTS fact_order_items;
CREATE TABLE fact_order_items (
  order_id VARCHAR(64) NOT NULL,
  order_item_id INT NOT NULL,
  product_id VARCHAR(64) NOT NULL,
  seller_id VARCHAR(64) NOT NULL,
  shipping_limit_ts DATETIME NULL,
  price DECIMAL(10,2) NOT NULL,
  freight_value DECIMAL(10,2) NOT NULL,

PRIMARY KEY (order_id, order_item_id),
FOREIGN KEY (order_id)REFERENCES fact_orders(order_id),
FOREIGN KEY (product_id)REFERENCES dim_products(product_id),
FOREIGN KEY (seller_id)REFERENCES dim_sellers(seller_id),

  INDEX idx_items_product (product_id),
  INDEX idx_items_seller (seller_id)
);

DROP TABLE IF EXISTS fact_payments;
CREATE TABLE fact_payments (
  order_id VARCHAR(64) NOT NULL,
  payment_seq INT NOT NULL,
  payment_type VARCHAR(32) NULL,
  installments INT NULL,
  payment_value DECIMAL(12,2) NOT NULL,

PRIMARY KEY (order_id, payment_seq),
FOREIGN KEY (order_id)REFERENCES fact_orders(order_id),

  INDEX idx_pay_type (payment_type)
);

DROP TABLE IF EXISTS fact_reviews;
CREATE TABLE fact_reviews (
  review_id VARCHAR(64)PRIMARY KEY,
  order_id VARCHAR(64)NOT NULL,
  review_score INT NULL,
  review_created_date DATE NULL,
  review_answer_ts DATETIME NULL,

FOREIGN KEY (order_id) REFERENCES fact_orders(order_id),
  INDEX idx_review_score (review_score)
);
