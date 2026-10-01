import os
import pandas as pd
import streamlit as st
import psycopg2

st.set_page_config(
    page_title="REVENUE-X",
    page_icon="📊",
    layout="wide"
)

# -----------------------------
# Database connection
# -----------------------------
db_url = os.getenv("DB_URL")

st.title("REVENUE-X")
st.caption("E-Commerce Revenue & Customer Intelligence Platform")

if not db_url:
    st.error("Database connection is not configured.")
    st.code("postgresql://postgres:YOUR_PASSWORD@localhost:5432/revenue_x")
    st.stop()

conn = psycopg2.connect(db_url)

# -----------------------------
# KPI section
# -----------------------------
kpi = pd.read_sql("""
SELECT
    ROUND(SUM(total_amount) FILTER (WHERE order_status='COMPLETED'), 2) AS revenue,
    COUNT(*) FILTER (WHERE order_status='COMPLETED') AS orders,
    COUNT(DISTINCT customer_id)
        FILTER (WHERE order_status='COMPLETED') AS customers,
    ROUND(
        AVG(total_amount) FILTER (WHERE order_status='COMPLETED'),
        2
    ) AS aov
FROM ecommerce.orders;
""", conn).iloc[0]

st.markdown("### Executive Overview")

c1, c2, c3, c4 = st.columns(4)

c1.metric(
    "Total Revenue",
    f"₹{kpi.revenue:,.2f}"
)

c2.metric(
    "Completed Orders",
    f"{int(kpi.orders):,}"
)

c3.metric(
    "Active Customers",
    f"{int(kpi.customers):,}"
)

c4.metric(
    "Average Order Value",
    f"₹{kpi.aov:,.2f}"
)

st.divider()

# -----------------------------
# Monthly revenue
# -----------------------------
monthly = pd.read_sql("""
SELECT
    month,
    gross_revenue
FROM ecommerce.vw_monthly_revenue
ORDER BY month;
""", conn)

left, right = st.columns([2, 1])

with left:
    st.subheader("📈 Revenue Trend")
    st.line_chart(
        monthly.set_index("month")["gross_revenue"],
        use_container_width=True
    )

with right:
    st.subheader("Revenue Summary")

    if not monthly.empty:
        st.metric(
            "Highest Monthly Revenue",
            f"₹{monthly.gross_revenue.max():,.2f}"
        )

        st.metric(
            "Average Monthly Revenue",
            f"₹{monthly.gross_revenue.mean():,.2f}"
        )

st.divider()

# -----------------------------
# Product intelligence
# -----------------------------
st.subheader("🛍️ Product Intelligence")

top = pd.read_sql("""
SELECT
    product_name,
    category_name,
    revenue,
    units_sold,
    estimated_profit,
    avg_rating,
    return_count
FROM ecommerce.vw_product_performance
ORDER BY revenue DESC NULLS LAST
LIMIT 10;
""", conn)

st.dataframe(
    top,
    use_container_width=True,
    hide_index=True
)

st.divider()

# -----------------------------
# Customer intelligence
# -----------------------------
st.subheader("👥 Customer Intelligence")

customers = pd.read_sql("""
SELECT
    customer_id,
    customer_name,
    revenue,
    orders_count,
    customer_segment
FROM ecommerce.vw_customer_360
ORDER BY revenue DESC
LIMIT 10;
""", conn)

st.dataframe(
    customers,
    use_container_width=True,
    hide_index=True
)

st.divider()

# -----------------------------
# Business insights
# -----------------------------
st.subheader("💡 Business Insights")

col1, col2, col3 = st.columns(3)

with col1:
    st.info(
        "Revenue performance is monitored through monthly "
        "sales trends and completed orders."
    )

with col2:
    st.info(
        "Customer 360 analysis identifies high-value customers "
        "and customer segments."
    )

with col3:
    st.info(
        "Product intelligence combines revenue, profit, ratings "
        "and return activity."
    )

st.caption(
    "REVENUE-X | PostgreSQL • SQL Analytics • Python • Streamlit"
)

conn.close()