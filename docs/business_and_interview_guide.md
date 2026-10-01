# Business & Interview Guide

## 60-second explanation
"I built REVENUE-X, a PostgreSQL-based e-commerce revenue intelligence platform. I designed a relational model for customers, products, orders, payments, returns and engagement data, generated synthetic transactional data, and created analytical views for revenue, product performance, customer 360 and RFM segmentation. I used joins, CTEs and window functions and added indexes and data-quality checks so the project demonstrates both database engineering and business analytics."

## Why PostgreSQL?
It supports strong relational constraints, advanced SQL, window functions, CTEs, date functions and analytical workloads.

## Why RFM?
RFM converts transaction history into three interpretable measures:
- Recency: how recently a customer purchased
- Frequency: how often they purchased
- Monetary: how much they spent

## Why indexes?
Indexes can reduce the work needed for frequent filters and joins. In a production environment, query plans should be checked with EXPLAIN ANALYZE before and after adding an index.

## Important caveat
The dataset is synthetic. Results are demonstrations of the analytical workflow, not claims about a real company.
