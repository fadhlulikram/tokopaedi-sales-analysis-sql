-- =====================================================================================
-- TOKOPAEDI E-COMMERCE PERFORMANCE ANALYSIS (GOOGLE BIGQUERY SQL)
-- Author: Fadhlul Ikram
-- Dataset: tokopaedi (order_detail, product_detail, customer_detail, 
--                     payment_detail, funnel_detail, transaction_detail)
-- =====================================================================================


-- -------------------------------------------------------------------------------------
-- CASE 1: Monthly Sales Report 2024 (Request from Board of Directors)
-- -------------------------------------------------------------------------------------
-- This query calculates the total monthly revenue for the year 2024 based on the total_paid column
-- FORMAT_DATE formats the transaction_date into 'Month Year' (e.g., Jan 2024) for readability
-- EXTRACT(MONTH ...) is used in GROUP BY and ORDER BY to ensure chronological sorting from Jan to Dec
SELECT 
    FORMAT_DATE('%b %Y', transaction_date) AS Bulan,          -- Format date as abbreviated month and year
    SUM(total_paid) AS Total_Revenue                          -- Sum of total amount paid by customers
FROM 
    `tokopaedi.transaction_detail`
WHERE 
    EXTRACT(YEAR FROM transaction_date) = 2024                -- Filter transactions for the year 2024 only
GROUP BY 
    EXTRACT(MONTH FROM transaction_date),                     -- Group by month number for chronological order
    FORMAT_DATE('%b %Y', transaction_date)                    -- Group by formatted month-year string
ORDER BY 
    EXTRACT(MONTH FROM transaction_date) ASC;                 -- Sort results from January (1) to December (12)


-- -------------------------------------------------------------------------------------
-- CASE 2: Category Sales Volume Trend 2020-2024 (Request from Warehouse Manager)
-- -------------------------------------------------------------------------------------
-- This query aggregates the total quantity sold per product category across five years (2020 to 2024)
-- Conditional aggregation (SUM + CASE WHEN) pivots the annual quantities into separate year columns
-- Joins order_detail and product_detail on sku_id and filters only valid (paid) transactions
SELECT 
    pd.category,                                                                                  -- Product category name
    SUM(CASE WHEN EXTRACT(YEAR FROM od.order_date) = 2020 THEN od.quantity ELSE 0 END) AS qty_2020, -- Total quantity sold in 2020
    SUM(CASE WHEN EXTRACT(YEAR FROM od.order_date) = 2021 THEN od.quantity ELSE 0 END) AS qty_2021, -- Total quantity sold in 2021
    SUM(CASE WHEN EXTRACT(YEAR FROM od.order_date) = 2022 THEN od.quantity ELSE 0 END) AS qty_2022, -- Total quantity sold in 2022
    SUM(CASE WHEN EXTRACT(YEAR FROM od.order_date) = 2023 THEN od.quantity ELSE 0 END) AS qty_2023, -- Total quantity sold in 2023
    SUM(CASE WHEN EXTRACT(YEAR FROM od.order_date) = 2024 THEN od.quantity ELSE 0 END) AS qty_2024  -- Total quantity sold in 2024
FROM 
    `tokopaedi.order_detail` AS od
JOIN 
    `tokopaedi.product_detail` AS pd
    ON od.sku_id = pd.sku_id                                                                      -- Join tables using unique product SKU ID
WHERE 
    EXTRACT(YEAR FROM od.order_date) IN (2020, 2021, 2022, 2023, 2024)                            -- Filter orders from 2020 through 2024
    AND od.is_valid = 1                                                                           -- Include only paid/valid transactions
GROUP BY 
    pd.category                                                                                   -- Group results by product category
ORDER BY 
    qty_2020 DESC;                                                                                -- Sort categories by 2020 volume (highest first)


-- -------------------------------------------------------------------------------------
-- CASE 3.1: Monthly Channel Performance in 2024 (Request from Marketing Manager)
-- -------------------------------------------------------------------------------------
-- This query evaluates the monthly performance of each sales channel (Website, App Store, Offline Store) in 2024
-- It calculates distinct orders and total revenue (after_discount) for valid transactions
SELECT
    FORMAT_DATE('%Y-%m', order_date) AS month,                -- Format order_date as 'YYYY-MM'
    channel_type,                                             -- Sales channel (Website, App Store, Offline Store)
    COUNT(DISTINCT order_id) AS total_order,                  -- Number of unique orders per channel and month
    SUM(after_discount) AS revenue                            -- Total revenue after item discounts
FROM 
    `tokopaedi.order_detail`
WHERE 
    EXTRACT(YEAR FROM order_date) = 2024                      -- Filter for orders in 2024
    AND is_valid = 1                                          -- Include only valid (paid) orders
    AND channel_type IN ('Website', 'App Store', 'Offline Store') -- Filter for the three main channels
GROUP BY 
    1, 2                                                      -- Group by month (1) and channel_type (2)
ORDER BY 
    1, 2;                                                     -- Order chronologically by month, then by channel


-- -------------------------------------------------------------------------------------
-- CASE 3.2: Monthly Revenue Growth 2024 vs 2023 Same Month (Request from Marketing Manager)
-- -------------------------------------------------------------------------------------
-- This query uses Common Table Expressions (CTEs) to compare monthly revenue in 2024 against the same month in 2023
-- NULLIF prevents division by zero errors when calculating the percentage growth
WITH tahun2024 AS (
    SELECT
        EXTRACT(MONTH FROM order_date) AS bulan,              -- Extract month number (1-12) for 2024
        SUM(after_discount) AS revenue_2024                   -- Total monthly revenue in 2024
    FROM 
        `tokopaedi.order_detail`
    WHERE 
        order_date >= '2024-01-01'
        AND order_date < '2025-01-01'
        AND is_valid = 1                                      -- Include only valid transactions
    GROUP BY 
        bulan
),
tahun2023 AS (
    SELECT
        EXTRACT(MONTH FROM order_date) AS bulan,              -- Extract month number (1-12) for 2023
        SUM(after_discount) AS revenue_2023                   -- Total monthly revenue in 2023
    FROM 
        `tokopaedi.order_detail`
    WHERE 
        order_date >= '2023-01-01'
        AND order_date < '2024-01-01'
        AND is_valid = 1                                      -- Include only valid transactions
    GROUP BY 
        bulan
)
SELECT
    tahun2023.bulan,                                          -- Month number (1 to 12)
    tahun2024.revenue_2024,                                   -- Revenue in 2024
    tahun2023.revenue_2023,                                   -- Revenue in 2023
    ROUND(
        (tahun2024.revenue_2024 - tahun2023.revenue_2023)
        * 100.0
        / NULLIF(tahun2023.revenue_2023, 0),
        2
    ) AS yoy                                                  -- Percentage growth (2024 vs 2023 in the same month)
FROM 
    tahun2023
JOIN 
    tahun2024
    ON tahun2023.bulan = tahun2024.bulan                      -- Join 2023 and 2024 data on the same month
ORDER BY 
    tahun2023.bulan;                                          -- Sort from January (1) to December (12)


-- -------------------------------------------------------------------------------------
-- CASE 4: Funnel Conversion Analysis - Organic Event 2024 (Request from Marketing Manager)
-- -------------------------------------------------------------------------------------
-- This query evaluates the funnel efficiency for 'Organic' events across different channel sources in 2024
-- SAFE_DIVIDE calculates the conversion rate (unique orders / total events * 100) safely without division-by-zero errors
SELECT
    channel_source,                                                           -- Source channel (Website, App Store, Play Store)
    COUNT(event) AS jumlah_event,                                             -- Total number of organic funnel events
    COUNT(order_id) AS jumlah_order,                                          -- Total orders recorded from organic events
    ROUND(SAFE_DIVIDE(COUNT(DISTINCT order_id), COUNT(event)) * 100, 2) AS rate -- Conversion rate (%) rounded to 2 decimal places
FROM 
    `tokopaedi.funnel_detail`
WHERE 
    EXTRACT(YEAR FROM funnel_date) = 2024                                     -- Filter funnel activity in 2024
    AND event = "Organic"                                                     -- Filter specifically for Organic traffic events
GROUP BY 
    1                                                                         -- Group by channel_source
ORDER BY 
    4 DESC;                                                                   -- Order by conversion rate (highest first)


-- -------------------------------------------------------------------------------------
-- CASE 5.1: Monthly New Customer Registrations by Channel in 2024 (Overview)
-- -------------------------------------------------------------------------------------
-- This query counts the total number of distinct new customers registering each month per channel in 2024
-- It captures all top-of-funnel sign-ups regardless of whether they have completed a purchase
SELECT
    EXTRACT(MONTH FROM registration_date) AS month,           -- Extract registration month (1-12)
    registration_channel,                                     -- Channel where the customer registered
    COUNT(DISTINCT customer_id) AS new_customer               -- Count of unique newly registered customers
FROM 
    `tokopaedi.customer_detail`
WHERE 
    EXTRACT(YEAR FROM registration_date) = 2024               -- Filter registrations in the year 2024
GROUP BY 
    1, 2                                                      -- Group by month and registration channel
ORDER BY 
    1, 2;                                                     -- Sort by month and registration channel


-- -------------------------------------------------------------------------------------
-- CASE 5.2: Converted New Customers & Average Time to First Order 2024 (Request from BI & CRM Lead)
-- -------------------------------------------------------------------------------------
-- This query analyzes 2024 new customers who have made at least one valid purchase
-- The 'first_order' CTE finds the earliest valid order_date for each customer
-- DATE_DIFF calculates the number of days between registration_date and first_order_date
WITH first_order AS (
    SELECT
        customer_id,                                          -- Unique customer identifier
        MIN(DATE(order_date)) AS first_order_date             -- Earliest valid purchase date per customer
    FROM
        `tokopaedi.order_detail`
    WHERE
        is_valid = 1                                          -- Only consider paid/valid transactions
    GROUP BY
        customer_id
)
SELECT
    EXTRACT(MONTH FROM c.registration_date) AS month_regist,  -- Month of customer registration (1-12)
    c.registration_channel,                                   -- Registration channel (Mobile App, Website, Offline Store)
    COUNT(DISTINCT c.customer_id) AS total_new_customers,     -- Unique new customers with at least 1 valid purchase
    ROUND(
        AVG(DATE_DIFF(fo.first_order_date, DATE(c.registration_date), DAY)),
        2
    ) AS avg_days_to_first_order                              -- Average days from registration to first order
FROM
    `tokopaedi.customer_detail` c
INNER JOIN
    first_order fo ON c.customer_id = fo.customer_id          -- Inner join filters only customers who have made a purchase
WHERE
    EXTRACT(YEAR FROM c.registration_date) = 2024             -- Filter customers who registered in 2024
GROUP BY
    1, 2                                                      -- Group by registration month and channel
ORDER BY
    month_regist ASC,                                         -- Sort chronologically by registration month
    total_new_customers DESC;                                 -- Then sort by highest number of new customers
