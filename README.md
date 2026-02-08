# Olist E-Commerce Sales & Operations Performance Dashboard (MySQL + Tableau)


---

## 1. Executive Summary
This project builds an end-to-end analytics workflow on the Olist e-commerce dataset: raw CSVs are staged in MySQL, transformed into a star-schema (dimensions + facts), and exposed through reusable SQL views for KPI tracking and Tableau dashboards. The final dashboard monitors revenue trends, order fulfillment funnel, category revenue mix, and how delivery time impacts customer review scores.

---

## 2. Problem
E-commerce teams need a single, reliable view of:
- Revenue performance over time (trend + growth)
- Operational efficiency (order funnel from purchase → delivery → review)
- Customer experience drivers (delivery time and lateness vs ratings)
- Revenue concentration (top categories, payment types)
- Customer behavior (repeat rate, high-value customers)

Raw transactional data is messy (strings, missing timestamps, multiple tables), so the goal is to model it cleanly and produce decision-ready KPIs.

---

## 3. Methodology
### Data Modeling (MySQL)
1) **Staging tables** (raw CSV format as strings)  
   - Script: `sql/01_setup.sql`

2) **Load CSVs into staging** via `LOAD DATA LOCAL INFILE`  
   - Script: `sql/02_load_stage_tables.sql`  
   - Note: Update file paths to your local CSV locations.

3) **Transform + type casting into analytics schema**  
   - Dimensions: `dim_customers`, `dim_products`, `dim_sellers`  
   - Facts: `fact_orders`, `fact_order_items`, `fact_payments`, `fact_reviews`  
   - Script: `sql/03_build_views.sql`

### Analytics Layer (Reusable Views)
Created views to simplify dashboarding:
- `v_order_revenue` (order-level gross revenue = items + freight)
- `v_order_payments` (payment aggregation per order)
- `v_customer_orders` (customer order sequence / repeat logic)
- `v_delivery_metrics` (delivery duration + late flag)
- `v_kpi` (top-line KPI tiles)
- `v_monthly_perf` (monthly orders + revenue + AOV)
- `v_category_perf` (category revenue ranking)
- `v_delivery_review` (delivery time vs review score)

### Visualization (Tableau)
The dashboard includes:
- Revenue Trend (monthly gross revenue)
- KPI Tiles (orders, customers, total revenue, AOV, delivery days, late %)
- Delivery Time vs Ratings scatterplot
- Order Fulfillment Funnel (created vs delivered)
- Top Categories by Revenue bar chart
**Tableau Public:** https://public.tableau.com/views/E-CommerceSalesOperationsPerformanceDashboard/Dashboard1?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link

### Dataset taken from Kaggle

---

## 4. Skills
- **SQL (MySQL):** CTEs, window functions, conditional aggregation, date functions
- **Data Modeling:** star schema, fact/dimension design, keys + indexes
- **ETL:** staging → typed tables, null handling, type casting, timestamp parsing
- **Analytics Engineering:** reusable semantic views for BI
- **BI / Tableau:** KPI design, dashboard layout, operational + revenue storytelling

  
**Tech:** MySQL (data modeling + SQL views), Tableau (dashboarding), CSV ingestion (LOAD DATA LOCAL INFILE)

---

## 5. Next Steps (future improvements)
- Build **cohort retention** + **RFM segmentation** to quantify repeat behavior over time
- Add **seller/state** drilldowns to identify late-delivery root causes
- Create a **late delivery prediction** model (features: route, seller, category, distance proxies)

---

