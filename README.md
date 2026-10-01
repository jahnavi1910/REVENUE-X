# REVENUE-X — E-Commerce Revenue & Customer Intelligence Platform

## 1. Project Overview
REVENUE-X is an end-to-end PostgreSQL analytics project that models an e-commerce business and turns transactional data into management-ready insights.

It demonstrates relational database design, constraints, CRUD operations, joins, aggregations, CTEs, window functions, analytical views, indexes, data-quality checks, customer segmentation, product performance, revenue analysis and return/refund analysis.

## 2. Business Problem
An online retailer needs a single analytical system to understand revenue, customers, products, payments, returns and customer engagement.

## 3. Business Questions
- What are gross and net revenues by month?
- What is average order value?
- Who are the highest-value customers?
- Which products and categories generate the most revenue/profit?
- Which categories have high return rates?
- Which payment methods dominate successful transactions?
- Which customers are high-value, loyal, promising or at risk?
- How does revenue change month over month?
- Are there data-quality problems?

## 4. Architecture

PostgreSQL
  ├── Transactional tables
  ├── Analytical views
  ├── Indexes
  └── Business analytics SQL
        ↓
   Dashboard / Reporting

## 5. Data Model
Core entities:
customers → orders → order_items → products → categories
orders → payments
order_items → returns
customers/products → reviews
customers → customer_campaigns → campaigns
customers → customer_events

## 6. SQL Concepts Demonstrated
- Primary and foreign keys
- NOT NULL / UNIQUE / CHECK constraints
- INSERT / SELECT / UPDATE / DELETE
- INNER and LEFT JOIN
- GROUP BY / HAVING
- CASE expressions
- CTEs
- Window functions
- NTILE-based RFM segmentation
- Views
- Indexes
- EXPLAIN / query optimization workflow
- Data-quality checks

## 7. How to Run
1. Install PostgreSQL and open pgAdmin or psql.
2. Create a database called `revenue_x`.
3. Run `database/01_schema.sql`.
4. Run `database/02_seed.sql`.
5. Run `database/03_views.sql`.
6. Run `analytics/01_business_analysis.sql`.
7. Query the views in the `ecommerce` schema.

Expected generated dataset: 10,000 customers, 500 products, 50,000 orders, hundreds of thousands of order-item rows, plus payments, returns, reviews, campaigns and customer events.

## 8. Portfolio Talking Points
- Designed a normalized relational schema for an e-commerce business.
- Generated a realistic synthetic dataset to test analytical workloads.
- Built reusable views for monthly revenue, customer 360, product performance and RFM segmentation.
- Used window functions for ranking, running totals and RFM scoring.
- Added indexes on common filtering/join columns.
- Added data-quality validation queries.
- Separated transactional modelling from analytical reporting.

## 9. Future Extensions
- Power BI / Streamlit dashboard
- Materialized views
- Stored procedures
- Slowly Changing Dimensions
- Automated ETL
- Forecasting
- Docker deployment
