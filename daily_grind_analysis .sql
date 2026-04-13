-- ============================================================
--  Daily Grind Café — Complete SQL Analysis
--  Database : SQLite
--  Tables   : branches · customers · products · orders · orders_details
--
--  Sections
--    1. Schema & Table Creation
--    2. Index Optimisation
--    3. SELECT · WHERE · ORDER BY · GROUP BY
--    4. JOINs  (INNER · LEFT · RIGHT-equivalent · Multi-table)
--    5. Aggregate Functions  (SUM · AVG · COUNT · MAX · MIN)
--    6. Subqueries  (WHERE · IN · EXISTS · Scalar · Correlated · CTE)
--    7. Views for Analysis
-- ============================================================


-- ============================================================
-- SECTION 1 — SCHEMA & TABLE CREATION
-- ============================================================

DROP TABLE IF EXISTS orders_details;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS branches;

-- 1a. Branches — one row per café location
CREATE TABLE branches (
    branch_id    TEXT PRIMARY KEY,
    branch_name  TEXT NOT NULL,
    city         TEXT NOT NULL,
    opening_date DATE
);

-- 1b. Customers
CREATE TABLE customers (
    customer_id       TEXT PRIMARY KEY,
    customer_name     TEXT NOT NULL,
    gender            INTEGER,
    birth_date        DATE,
    registration_date DATE
);

-- 1c. Products menu
CREATE TABLE products (
    product_id   TEXT PRIMARY KEY,
    product_name TEXT NOT NULL,
    category     TEXT NOT NULL,
    unit_price   REAL NOT NULL CHECK (unit_price > 0)
);

-- 1d. Orders header
CREATE TABLE orders (
    order_id       TEXT PRIMARY KEY,
    customer_id    TEXT NOT NULL,
    branch_id      TEXT NOT NULL,
    order_date     DATE NOT NULL,
    payment_method TEXT,
    order_status   TEXT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (branch_id)   REFERENCES branches(branch_id)
);

-- 1e. Order line items
CREATE TABLE orders_details (
    order_details_id TEXT PRIMARY KEY,
    order_id         TEXT    NOT NULL,
    product_id       TEXT    NOT NULL,
    quantity         INTEGER NOT NULL CHECK (quantity > 0),
    unit_price       REAL    NOT NULL,
    total_price      REAL    NOT NULL,
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);


-- ============================================================
-- SECTION 2 — INDEX OPTIMISATION
-- ============================================================
-- Without indexes the engine performs a full table scan (O n)
-- for every JOIN or filter.  B-tree indexes reduce that to O(log n),
-- which matters as orders_details grows into the millions.

-- Foreign-key / JOIN indexes
CREATE INDEX IF NOT EXISTS idx_orders_customer_id
    ON orders(customer_id);

CREATE INDEX IF NOT EXISTS idx_orders_branch_id
    ON orders(branch_id);

CREATE INDEX IF NOT EXISTS idx_od_order_id
    ON orders_details(order_id);

CREATE INDEX IF NOT EXISTS idx_od_product_id
    ON orders_details(product_id);

-- Filter / GROUP BY indexes
CREATE INDEX IF NOT EXISTS idx_orders_date
    ON orders(order_date);

CREATE INDEX IF NOT EXISTS idx_orders_status
    ON orders(order_status);

CREATE INDEX IF NOT EXISTS idx_products_category
    ON products(category);

-- Composite index: speeds up branch + date range queries together
CREATE INDEX IF NOT EXISTS idx_orders_branch_date
    ON orders(branch_id, order_date);

-- Verify all indexes
SELECT name        AS index_name,
       tbl_name    AS on_table
FROM   sqlite_master
WHERE  type = 'index'
ORDER  BY tbl_name, name;

-- Inspect the query plan to confirm index usage
EXPLAIN QUERY PLAN
    SELECT b.branch_name, SUM(od.total_price) AS revenue
    FROM   branches b
    LEFT JOIN orders          o  ON b.branch_id = o.branch_id
    LEFT JOIN orders_details  od ON o.order_id  = od.order_id
    GROUP  BY b.branch_id;


-- ============================================================
-- SECTION 3 — SELECT · WHERE · ORDER BY · GROUP BY
-- ============================================================

-- 3a. Simple SELECT * — every branch
SELECT * FROM branches;

-- 3b. SELECT specific columns with ORDER BY
SELECT product_name,
       category,
       unit_price
FROM   products
ORDER  BY category  ASC,
          unit_price DESC;

-- 3c. WHERE — single condition
SELECT product_name,
       unit_price
FROM   products
WHERE  category = 'Coffee'
ORDER  BY unit_price DESC;

-- 3d. WHERE with AND / OR
SELECT order_id,
       customer_id,
       order_date,
       payment_method,
       order_status
FROM   orders
WHERE  order_status   = 'Completed'
  AND  payment_method = 'Card'
ORDER  BY order_date DESC;

-- 3e. WHERE with BETWEEN (date range)
SELECT order_id,
       customer_id,
       branch_id,
       order_date
FROM   orders
WHERE  order_date BETWEEN '2025-01-01' AND '2025-12-31'
ORDER  BY order_date;

-- 3f. WHERE with IN (multiple values)
SELECT product_name,
       category,
       unit_price
FROM   products
WHERE  category IN ('Coffee', 'Cold Drinks')
ORDER  BY category, unit_price;

-- 3g. WHERE with LIKE (pattern match)
SELECT customer_name,
       registration_date
FROM   customers
WHERE  customer_name LIKE 'A%'
ORDER  BY customer_name;

-- 3h. GROUP BY — order count per status
SELECT order_status,
       COUNT(*) AS total_orders
FROM   orders
GROUP  BY order_status
ORDER  BY total_orders DESC;

-- 3i. GROUP BY with HAVING — months that exceed 10 orders
SELECT strftime('%Y-%m', order_date) AS month,
       COUNT(*)                      AS order_count
FROM   orders
GROUP  BY month
HAVING COUNT(*) > 10
ORDER  BY month;

-- 3j. GROUP BY — payment method share
SELECT payment_method,
       COUNT(*)                                                   AS order_count,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 1) AS pct
FROM   orders
GROUP  BY payment_method
ORDER  BY order_count DESC;


-- ============================================================
-- SECTION 4 — JOINS
-- ============================================================

-- ── 4a. INNER JOIN ─────────────────────────────────────────
-- Only rows that match in BOTH tables are returned.

-- Products with their sales totals (unordered products are excluded)
SELECT p.product_name,
       p.category,
       SUM(od.quantity)    AS units_sold,
       SUM(od.total_price) AS total_revenue
FROM   products p
INNER JOIN orders_details od ON p.product_id = od.product_id
GROUP  BY p.product_id
ORDER  BY total_revenue DESC;

-- ── 4b. LEFT JOIN ──────────────────────────────────────────
-- ALL rows from the left table; NULLs where the right table has no match.

-- All branches, including any with no orders (revenue shows NULL → 0 via COALESCE)
SELECT b.branch_id,
       b.branch_name,
       b.city,
       COALESCE(COUNT(o.order_id), 0)   AS total_orders,
       COALESCE(SUM(od.total_price), 0) AS total_revenue
FROM   branches b
LEFT JOIN orders          o  ON b.branch_id = o.branch_id
LEFT JOIN orders_details  od ON o.order_id  = od.order_id
GROUP  BY b.branch_id
ORDER  BY total_revenue DESC;

-- All customers, showing NULL for those who never ordered
SELECT c.customer_id,
       c.customer_name,
       c.registration_date,
       o.order_id,
       o.order_date
FROM   customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
ORDER  BY c.customer_id, o.order_date
LIMIT  20;

-- ── 4c. RIGHT JOIN (simulated) ─────────────────────────────
-- SQLite has no RIGHT JOIN keyword; flip the table order instead.
-- Goal: all order-detail lines, plus product info when available.

SELECT od.order_details_id,
       od.order_id,
       od.product_id,
       p.product_name,
       p.category,
       od.quantity,
       od.total_price
FROM   products          p           -- was the "right" table → now left
LEFT JOIN orders_details od ON p.product_id = od.product_id
ORDER  BY od.order_id NULLS LAST;

-- ── 4d. Multi-table INNER JOIN (5 tables) ──────────────────
-- Full order detail with every human-readable name

SELECT o.order_id,
       c.customer_name,
       b.branch_name,
       b.city,
       p.product_name,
       p.category,
       od.quantity,
       od.total_price,
       o.order_date,
       o.payment_method,
       o.order_status
FROM   orders            o
INNER JOIN customers      c  ON o.customer_id  = c.customer_id
INNER JOIN branches       b  ON o.branch_id    = b.branch_id
INNER JOIN orders_details od ON o.order_id     = od.order_id
INNER JOIN products       p  ON od.product_id  = p.product_id
ORDER  BY o.order_date DESC;

-- ── 4e. JOIN with aggregation — revenue per customer per branch ─
SELECT c.customer_name,
       b.branch_name,
       COUNT(DISTINCT o.order_id)  AS visits,
       SUM(od.total_price)         AS spend_at_branch
FROM   customers      c
INNER JOIN orders          o  ON c.customer_id = o.customer_id
INNER JOIN branches        b  ON o.branch_id   = b.branch_id
INNER JOIN orders_details  od ON o.order_id    = od.order_id
GROUP  BY c.customer_id, b.branch_id
ORDER  BY spend_at_branch DESC
LIMIT  15;


-- ============================================================
-- SECTION 5 — AGGREGATE FUNCTIONS  (SUM · AVG · COUNT · MAX · MIN)
-- ============================================================

-- 5a. Overall business KPIs in one query
SELECT COUNT(DISTINCT c.customer_id)  AS total_customers,
       COUNT(DISTINCT b.branch_id)    AS total_branches,
       COUNT(DISTINCT p.product_id)   AS total_products,
       COUNT(DISTINCT o.order_id)     AS total_orders,
       SUM(od.total_price)            AS grand_revenue,
       ROUND(AVG(od.total_price), 2)  AS avg_item_value,
       MAX(od.total_price)            AS max_single_item,
       MIN(od.unit_price)             AS min_unit_price
FROM   customers c, branches b, products p, orders o, orders_details od;

-- 5b. Revenue & volume by product category
SELECT p.category,
       COUNT(od.order_details_id)    AS line_items,
       SUM(od.quantity)              AS units_sold,
       SUM(od.total_price)           AS total_revenue,
       ROUND(AVG(od.unit_price), 2)  AS avg_unit_price,
       MAX(od.unit_price)            AS max_price,
       MIN(od.unit_price)            AS min_price
FROM   products p
JOIN   orders_details od ON p.product_id = od.product_id
GROUP  BY p.category
ORDER  BY total_revenue DESC;

-- 5c. Monthly revenue trend with SUM and COUNT
SELECT strftime('%Y-%m', o.order_date) AS month,
       COUNT(DISTINCT o.order_id)      AS orders,
       SUM(od.quantity)                AS units_sold,
       SUM(od.total_price)             AS revenue,
       ROUND(AVG(od.total_price), 2)   AS avg_item_value
FROM   orders o
JOIN   orders_details od ON o.order_id = od.order_id
GROUP  BY month
ORDER  BY month;

-- 5d. Top 10 customers by lifetime spend
SELECT c.customer_name,
       COUNT(DISTINCT o.order_id)     AS num_orders,
       SUM(od.quantity)               AS items_bought,
       SUM(od.total_price)            AS lifetime_spend,
       ROUND(AVG(od.total_price), 2)  AS avg_item_value,
       MAX(o.order_date)              AS last_order_date
FROM   customers c
INNER JOIN orders          o  ON c.customer_id = o.customer_id
INNER JOIN orders_details  od ON o.order_id    = od.order_id
GROUP  BY c.customer_id
ORDER  BY lifetime_spend DESC
LIMIT  10;

-- 5e. Full branch performance with all aggregates
SELECT b.branch_name,
       b.city,
       COUNT(DISTINCT o.order_id)     AS total_orders,
       COUNT(DISTINCT o.customer_id)  AS unique_customers,
       SUM(od.total_price)            AS total_revenue,
       ROUND(AVG(od.total_price), 2)  AS avg_item_value,
       MAX(od.total_price)            AS max_single_item,
       MIN(od.unit_price)             AS min_unit_price,
       SUM(od.quantity)               AS total_units_sold
FROM   branches b
LEFT JOIN orders          o  ON b.branch_id = o.branch_id
LEFT JOIN orders_details  od ON o.order_id  = od.order_id
GROUP  BY b.branch_id
ORDER  BY total_revenue DESC;

-- 5f. Conditional aggregation — completed vs cancelled per branch
SELECT b.branch_name,
       SUM(CASE WHEN o.order_status = 'Completed'  THEN 1 ELSE 0 END) AS completed,
       SUM(CASE WHEN o.order_status = 'Cancalled'  THEN 1 ELSE 0 END) AS cancelled,
       COUNT(o.order_id)                                                AS total,
       ROUND(
           SUM(CASE WHEN o.order_status = 'Completed' THEN 1 ELSE 0 END)
           * 100.0 / NULLIF(COUNT(o.order_id), 0), 1
       )                                                                AS completion_rate_pct
FROM   branches b
LEFT JOIN orders o ON b.branch_id = o.branch_id
GROUP  BY b.branch_id
ORDER  BY completion_rate_pct DESC;


-- ============================================================
-- SECTION 6 — SUBQUERIES
-- ============================================================

-- ── 6a. Subquery in WHERE — compare to aggregate ───────────
-- Products priced above the average product price

SELECT product_name,
       category,
       unit_price
FROM   products
WHERE  unit_price > (SELECT AVG(unit_price) FROM products)
ORDER  BY unit_price DESC;

-- ── 6b. Subquery in WHERE with IN ──────────────────────────
-- Orders that contain at least one Dessert item

SELECT DISTINCT o.order_id,
                o.customer_id,
                o.order_date,
                o.order_status
FROM   orders o
WHERE  o.order_id IN (
    SELECT od.order_id
    FROM   orders_details od
    JOIN   products p ON od.product_id = p.product_id
    WHERE  p.category = 'Desserts'
)
ORDER  BY o.order_date DESC;

-- ── 6c. Subquery with NOT IN ───────────────────────────────
-- Customers who have never ordered a Coffee

SELECT customer_name
FROM   customers
WHERE  customer_id NOT IN (
    SELECT DISTINCT o.customer_id
    FROM   orders o
    JOIN   orders_details  od ON o.order_id    = od.order_id
    JOIN   products        p  ON od.product_id = p.product_id
    WHERE  p.category = 'Coffee'
)
ORDER  BY customer_name;

-- ── 6d. Subquery with EXISTS ───────────────────────────────
-- Products that were NEVER ordered (potential dead stock)

SELECT product_id,
       product_name,
       category,
       unit_price
FROM   products p
WHERE  NOT EXISTS (
    SELECT 1
    FROM   orders_details od
    WHERE  od.product_id = p.product_id
);

-- ── 6e. Derived table subquery ─────────────────────────────
-- Customers who spent more than the average customer lifetime value

SELECT customer_name,
       total_spent
FROM (
    SELECT c.customer_name,
           SUM(od.total_price) AS total_spent
    FROM   customers c
    JOIN   orders          o  ON c.customer_id = o.customer_id
    JOIN   orders_details  od ON o.order_id    = od.order_id
    GROUP  BY c.customer_id
) AS customer_totals
WHERE total_spent > (
    SELECT AVG(spend)
    FROM (
        SELECT SUM(od.total_price) AS spend
        FROM   orders o
        JOIN   orders_details od ON o.order_id = od.order_id
        GROUP  BY o.customer_id
    )
)
ORDER  BY total_spent DESC;

-- ── 6f. Scalar subquery in SELECT column ───────────────────
-- Show each product's revenue alongside the overall average

SELECT p.product_name,
       p.category,
       SUM(od.total_price)                    AS product_revenue,
       (SELECT ROUND(AVG(sub.total_price), 2)
        FROM   orders_details sub)             AS overall_avg_item,
       ROUND(SUM(od.total_price) - (
           SELECT AVG(rev)
           FROM (
               SELECT SUM(x.total_price) AS rev
               FROM   orders_details x
               GROUP  BY x.product_id
           )
       ), 2)                                   AS vs_product_avg
FROM   products p
JOIN   orders_details od ON p.product_id = od.product_id
GROUP  BY p.product_id
ORDER  BY product_revenue DESC;

-- ── 6g. Correlated subquery ────────────────────────────────
-- Best-selling product (by quantity) at each branch

SELECT b.branch_name,
       p.product_name,
       top.total_qty
FROM   branches b
JOIN (
    SELECT o.branch_id,
           od.product_id,
           SUM(od.quantity) AS total_qty
    FROM   orders o
    JOIN   orders_details od ON o.order_id = od.order_id
    GROUP  BY o.branch_id, od.product_id
) top ON b.branch_id = top.branch_id
JOIN products p ON top.product_id = p.product_id
WHERE top.total_qty = (
    SELECT MAX(inner_t.total_qty)
    FROM (
        SELECT o2.branch_id,
               od2.product_id,
               SUM(od2.quantity) AS total_qty
        FROM   orders o2
        JOIN   orders_details od2 ON o2.order_id = od2.order_id
        GROUP  BY o2.branch_id, od2.product_id
    ) inner_t
    WHERE inner_t.branch_id = b.branch_id
)
ORDER  BY b.branch_name;

-- ── 6h. CTE (Common Table Expression) ──────────────────────
-- Revenue share of each product within its category

WITH product_revenue AS (
    SELECT p.product_name,
           p.category,
           SUM(od.total_price) AS revenue,
           SUM(od.quantity)    AS units
    FROM   products p
    JOIN   orders_details od ON p.product_id = od.product_id
    GROUP  BY p.product_id
),
category_totals AS (
    SELECT category,
           SUM(revenue) AS cat_revenue
    FROM   product_revenue
    GROUP  BY category
)
SELECT pr.category,
       pr.product_name,
       pr.revenue,
       pr.units,
       ROUND(pr.revenue * 100.0 / ct.cat_revenue, 1) AS pct_of_category
FROM   product_revenue   pr
JOIN   category_totals   ct ON pr.category = ct.category
ORDER  BY pr.category, pr.revenue DESC;


-- ============================================================
-- SECTION 7 — VIEWS FOR ANALYSIS
-- ============================================================

-- ── View 1: Customer Lifetime Value ────────────────────────
DROP VIEW IF EXISTS vw_customer_lifetime_value;
CREATE VIEW vw_customer_lifetime_value AS
SELECT c.customer_id,
       c.customer_name,
       c.registration_date,
       COUNT(DISTINCT o.order_id)    AS total_orders,
       SUM(od.total_price)           AS lifetime_value,
       ROUND(AVG(od.total_price), 2) AS avg_basket_item,
       SUM(od.quantity)              AS total_items_bought,
       MAX(o.order_date)             AS last_order_date,
       MIN(o.order_date)             AS first_order_date
FROM   customers c
LEFT JOIN orders          o  ON c.customer_id = o.customer_id
LEFT JOIN orders_details  od ON o.order_id    = od.order_id
GROUP  BY c.customer_id;

-- Use the view
SELECT * FROM vw_customer_lifetime_value
ORDER  BY lifetime_value DESC
LIMIT  15;

-- ── View 2: Branch Performance Dashboard ───────────────────
DROP VIEW IF EXISTS vw_branch_performance;
CREATE VIEW vw_branch_performance AS
SELECT b.branch_id,
       b.branch_name,
       b.city,
       b.opening_date,
       COUNT(DISTINCT o.order_id)    AS total_orders,
       COUNT(DISTINCT o.customer_id) AS unique_customers,
       SUM(od.total_price)           AS total_revenue,
       ROUND(AVG(od.total_price), 2) AS avg_item_value,
       SUM(od.quantity)              AS total_units_sold
FROM   branches b
LEFT JOIN orders          o  ON b.branch_id = o.branch_id
LEFT JOIN orders_details  od ON o.order_id  = od.order_id
GROUP  BY b.branch_id;

-- Use the view
SELECT * FROM vw_branch_performance
ORDER  BY total_revenue DESC;

-- ── View 3: Product Sales Performance ──────────────────────
DROP VIEW IF EXISTS vw_product_performance;
CREATE VIEW vw_product_performance AS
SELECT p.product_id,
       p.product_name,
       p.category,
       p.unit_price                  AS list_price,
       COUNT(od.order_details_id)    AS times_ordered,
       SUM(od.quantity)              AS units_sold,
       SUM(od.total_price)           AS total_revenue,
       ROUND(AVG(od.quantity), 2)    AS avg_qty_per_line
FROM   products p
LEFT JOIN orders_details od ON p.product_id = od.product_id
GROUP  BY p.product_id;

-- Use the view
SELECT * FROM vw_product_performance
ORDER  BY total_revenue DESC;

-- ── View 4: Monthly Revenue Summary ────────────────────────
DROP VIEW IF EXISTS vw_monthly_revenue;
CREATE VIEW vw_monthly_revenue AS
SELECT strftime('%Y-%m', o.order_date)                                  AS month,
       COUNT(DISTINCT o.order_id)                                       AS total_orders,
       COUNT(DISTINCT o.customer_id)                                    AS active_customers,
       SUM(od.total_price)                                              AS revenue,
       ROUND(AVG(od.total_price), 2)                                    AS avg_item_value,
       SUM(CASE WHEN o.payment_method = 'Card' THEN 1 ELSE 0 END)      AS card_payments,
       SUM(CASE WHEN o.payment_method = 'Cash' THEN 1 ELSE 0 END)      AS cash_payments
FROM   orders o
JOIN   orders_details od ON o.order_id = od.order_id
GROUP  BY month;

-- Use the view
SELECT * FROM vw_monthly_revenue
ORDER  BY month;

-- ── View 5: Full Order Status Report ───────────────────────
DROP VIEW IF EXISTS vw_order_status_report;
CREATE VIEW vw_order_status_report AS
SELECT o.order_id,
       c.customer_name,
       b.branch_name,
       o.order_date,
       o.order_status,
       o.payment_method,
       COUNT(od.order_details_id) AS line_items,
       SUM(od.total_price)        AS order_total
FROM   orders         o
JOIN   customers      c  ON o.customer_id = c.customer_id
JOIN   branches       b  ON o.branch_id   = b.branch_id
JOIN   orders_details od ON o.order_id    = od.order_id
GROUP  BY o.order_id;

-- Filter the view — cancelled orders only
SELECT * FROM vw_order_status_report
WHERE  order_status = 'Cancalled'
ORDER  BY order_date DESC;

-- ── Cross-view analysis ─────────────────────────────────────
-- Revenue per unique customer at each branch
SELECT bp.branch_name,
       bp.city,
       bp.total_revenue,
       bp.unique_customers,
       ROUND(bp.total_revenue / NULLIF(bp.unique_customers, 0), 2) AS revenue_per_customer
FROM   vw_branch_performance bp
ORDER  BY revenue_per_customer DESC;

-- ============================================================
-- END OF SCRIPT
-- ============================================================
