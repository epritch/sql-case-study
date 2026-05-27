# SQL Case Study: Superstore Sales Analysis

**Author:** Evan Pritchard · [epritch.github.io](https://epritch.github.io) · [LinkedIn](https://www.linkedin.com/in/evan-pritchard-9a0922168/)

An end-to-end SQL analysis of the public Tableau Superstore dataset, demonstrating
proficiency with relational schemas, aggregations, CTEs, and window functions to
answer real business questions about sales performance, customer behavior, and
profitability.

---

## Business Questions Answered

| # | Question | SQL Concepts |
|---|----------|-------------|
| 1 | Which product categories generate the most revenue and profit? | Aggregation, JOIN |
| 2 | How has revenue grown year-over-year per category? | CTE, `LAG()` |
| 3 | Who are the top 10 customers by lifetime value? | Multi-CTE, `RANK()` |
| 4 | Does offering discounts hurt profitability? | CASE bucketing, aggregation |
| 5 | How do regions compare on revenue, margin, and customer value? | Multi-metric aggregation |
| 6 | What does the smoothed revenue trend look like? | `AVG() OVER (ROWS BETWEEN…)` |
| 7 | What share of customers are repeat vs one-time buyers? | CTE, window `SUM() OVER()` |
| 8 | Which sub-categories rank best within their category by profit? | `DENSE_RANK() PARTITION BY` |

---

## Key Findings

### 1. Technology leads revenue but Office Supplies wins on volume
Technology generated ~36% of total revenue ($836K) but only 1,847 orders.
Office Supplies made up 6,026 orders — the highest volume — at a comparable margin of 17%.

### 2. Discounts over 20% reliably destroy profit
Items with 21–30% discounts averaged **–2.3% margin**. Items with no discount averaged **+18.4% margin**.
This is the single largest controllable driver of profit leakage in the dataset.

### 3. The West region outperforms on revenue per customer
West: $725K revenue / ~312 customers = **$2,323 per customer**
South: $396K revenue / ~290 customers = **$1,366 per customer**
The gap suggests an opportunity to apply the West's product mix or pricing strategy in the South.

### 4. 62% of customers placed only one order
One-time buyers represent the majority of the customer base — a clear retention opportunity.
Targeting this cohort with re-engagement campaigns could significantly lift LTV.

---

## Schema

```
orders
├── order_id (PK)
├── order_date, ship_date, ship_mode
├── customer_id, customer_name, segment
└── region, state, city

order_items
├── item_id (PK)
├── order_id (FK → orders)
├── product_id, category, sub_category, product_name
├── sales, quantity, discount, profit
```

---

## SQL Concepts Demonstrated

- **Joins:** `INNER JOIN` across normalized tables
- **Aggregations:** `SUM`, `COUNT DISTINCT`, `AVG`, `ROUND`
- **CTEs:** Multi-step logic with `WITH` clauses
- **Window Functions:** `LAG`, `RANK`, `DENSE_RANK`, `AVG OVER (ROWS BETWEEN…)`
- **Conditional Logic:** `CASE WHEN` for custom bucketing
- **NULL Safety:** `NULLIF` to prevent divide-by-zero errors
- **Date Functions:** `EXTRACT(YEAR)`, `DATE_TRUNC`

---

## Tools

- **SQL dialect:** PostgreSQL (compatible with SQL Server with minor syntax changes)
- **Data source:** [Tableau Superstore Dataset](https://public.tableau.com/app/learn/sample-data) (public domain)
- **Visualization of results:** See companion [BI Dashboard](https://epritch.github.io/bi-dashboard/)

---

## Files

```
sql-case-study/
└── superstore_analysis.sql    # All 8 queries, fully commented
```

---

*Part of my data analytics portfolio. See also:*
*[AI Job Market Dashboard](https://github.com/epritch/ai-job-market-dashboard) · [Automation Risk Dashboard](https://github.com/epritch/epritch.github.io)*
