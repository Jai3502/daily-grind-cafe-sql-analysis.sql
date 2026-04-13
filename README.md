# daily-grind-cafe-sql-analysis.sql
A complete SQL analysis project for a café business using SQLite. Covers schema design, indexing, joins, aggregations, subqueries, and analytical views for business insights.
#  Daily Grind Café — SQL Analysis Project

A **comprehensive SQL project** designed to analyze a café business database using **SQLite**.
This project demonstrates real-world SQL skills including **schema design, indexing, joins, aggregations, subqueries, and analytical views**.

---

##  Project Overview

This SQL script simulates a café business database and performs advanced analysis on:

* Customers 👤
* Orders 🧾
* Products 🍩
* Branches 🏪

It is structured as a **step-by-step learning and portfolio-ready project**. 

---

##  Database Schema

The database consists of **5 main tables**:

* `branches` → Café locations
* `customers` → Customer information
* `products` → Menu items
* `orders` → Order headers
* `orders_details` → Line-level order data

---

##  Key Features & Concepts

###  1. Schema & Table Creation

* Fully normalized relational database
* Primary & foreign key relationships
* Data validation using constraints

---

###  2. Index Optimization

* Improves query performance (O(n) → O(log n))
* Includes:

  * Foreign key indexes
  * Composite indexes
  * Query plan analysis

---

###  3. Core SQL Operations

* `SELECT`, `WHERE`, `ORDER BY`
* `GROUP BY`, `HAVING`
* Filtering, sorting, and aggregation

---

###  4. Joins

* INNER JOIN
* LEFT JOIN
* Simulated RIGHT JOIN (SQLite workaround)
* Multi-table joins

---

###  5. Aggregate Functions

* `SUM`, `AVG`, `COUNT`, `MAX`, `MIN`
* Business KPIs:

  * Revenue
  * Orders
  * Customer metrics

---

###  6. Advanced SQL (Subqueries)

* Scalar subqueries
* Correlated subqueries
* `IN`, `EXISTS`, `NOT IN`
* Derived tables
* CTEs (Common Table Expressions)

---

###  7 Analytical Views

Pre-built views for real-world insights:

* `vw_customer_lifetime_value` → Customer spending behavior
* `vw_branch_performance` → Branch-level performance
* `vw_product_performance` → Product sales analysis
* `vw_monthly_revenue` → Time-based trends
* `vw_order_status_report` → Order tracking

---

##  Business Insights You Can Derive

* 💰 Total revenue and sales trends
* 🏆 Top customers by lifetime value
* 📍 Best-performing branches
* 📦 Best-selling products
* 📅 Monthly revenue patterns
* ❌ Dead stock (products never ordered)

---

##  Tools & Technologies

* **Database:** SQLite
* **Language:** SQL
* **Concepts:** Data Analysis, Relational Modeling

---

##  How to Use

1. Open SQLite (DB Browser or CLI)
2. Run the SQL file:

   ```sql
   .read daily-grind-cafe-sql-analysis.sql
   ```
3. Explore:

   * Tables
   * Queries
   * Views

---

##  File Included

* `daily-grind-cafe-sql-analysis.sql` — Complete SQL script

---

##  Who This Project Is For

* Beginners learning SQL
* Data Analysts building portfolios
* Students preparing for interviews
* Anyone interested in business data analysis

---

##  Highlights

* Real-world business scenario
* Clean, structured SQL
* Covers beginner → advanced concepts
* Portfolio-ready project

---

##  Support

If you found this helpful, consider giving this repo a ⭐!

---

## 👨‍💻 Author

SQL Data Analysis Project — Café Business Case Study

---
