USE olist_analytics;


LOAD DATA LOCAL INFILE '/Users/Aditya/Desktop/SUB/SQL/olist/olist_orders_dataset.csv'
INTO TABLE stg_orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE '/Users/Aditya/Desktop/SUB/SQL/olist/olist_order_items_dataset.csv'
INTO TABLE stg_order_items
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE '/Users/Aditya/Desktop/SUB/SQL/olist/olist_order_payments_dataset.csv'
INTO TABLE stg_payments
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE '/Users/Aditya/Desktop/SUB/SQL/olist/olist_order_reviews_dataset.csv'
INTO TABLE stg_reviews
FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(review_id, order_id, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp);

LOAD DATA LOCAL INFILE '/Users/Aditya/Desktop/SUB/SQL/olist/olist_customers_dataset.csv'
INTO TABLE stg_customers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE '/Users/Aditya/Desktop/SUB/SQL/olist/olist_products_dataset.csv'
INTO TABLE stg_products
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE '/Users/Aditya/Desktop/SUB/SQL/olist/olist_sellers_dataset.csv'
INTO TABLE stg_sellers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE '/Users/Aditya/Desktop/SUB/SQL/olist/product_category_name_translation.csv'
INTO TABLE stg_category_translation
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
