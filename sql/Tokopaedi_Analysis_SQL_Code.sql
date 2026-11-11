-- =====================================================================================
-- ANALISIS DATA PENJUALAN TOKOPAEDI (GOOGLE BIGQUERY SQL)
-- Nama: Fadhlul Ikram
-- Tabel: order_detail, product_detail, customer_detail, 
--        payment_detail, funnel_detail, transaction_detail
-- =====================================================================================


-- -------------------------------------------------------------------------------------
-- CASE 1: Laporan Pendapatan Bulanan 2024
-- -------------------------------------------------------------------------------------
-- Menghitung total pendapatan per bulan di tahun 2024 dari kolom total_paid
SELECT 
    FORMAT_DATE('%b %Y', transaction_date) AS Bulan,          -- Ubah format tanggal jadi Bulan Tahun (contoh: Jan 2024)
    SUM(total_paid) AS Total_Revenue                          -- Jumlahkan total bayar
FROM 
    `tokopaedi.transaction_detail`
WHERE 
    EXTRACT(YEAR FROM transaction_date) = 2024                -- Ambil data tahun 2024 saja
GROUP BY 
    EXTRACT(MONTH FROM transaction_date),                     -- Kelompokkan per angka bulan biar urut
    FORMAT_DATE('%b %Y', transaction_date)
ORDER BY 
    EXTRACT(MONTH FROM transaction_date) ASC;                 -- Urutkan dari Januari (1) sampai Desember (12)


-- -------------------------------------------------------------------------------------
-- CASE 2: Tren Jumlah Barang Terjual per Kategori (2020-2024)
-- -------------------------------------------------------------------------------------
-- Menghitung total barang terjual per kategori dari tahun 2020 sampai 2024
-- Pakai CASE WHEN supaya tiap tahun jadi kolom sendiri-sendiri
SELECT 
    pd.category,                                                                                  -- Nama kategori produk
    SUM(CASE WHEN EXTRACT(YEAR FROM od.order_date) = 2020 THEN od.quantity ELSE 0 END) AS qty_2020, -- Total terjual 2020
    SUM(CASE WHEN EXTRACT(YEAR FROM od.order_date) = 2021 THEN od.quantity ELSE 0 END) AS qty_2021, -- Total terjual 2021
    SUM(CASE WHEN EXTRACT(YEAR FROM od.order_date) = 2022 THEN od.quantity ELSE 0 END) AS qty_2022, -- Total terjual 2022
    SUM(CASE WHEN EXTRACT(YEAR FROM od.order_date) = 2023 THEN od.quantity ELSE 0 END) AS qty_2023, -- Total terjual 2023
    SUM(CASE WHEN EXTRACT(YEAR FROM od.order_date) = 2024 THEN od.quantity ELSE 0 END) AS qty_2024  -- Total terjual 2024
FROM 
    `tokopaedi.order_detail` AS od
JOIN 
    `tokopaedi.product_detail` AS pd
    ON od.sku_id = pd.sku_id                                                                      -- Gabungkan tabel pakai sku_id
WHERE 
    EXTRACT(YEAR FROM od.order_date) IN (2020, 2021, 2022, 2023, 2024)                            -- Filter tahun 2020-2024
    AND od.is_valid = 1                                                                           -- Hanya transaksi yang sudah dibayar
GROUP BY 
    pd.category
ORDER BY 
    qty_2020 DESC;                                                                                -- Urutkan dari yang paling laku di 2020


-- -------------------------------------------------------------------------------------
-- CASE 3.1: Performa Channel Penjualan per Bulan di 2024
-- -------------------------------------------------------------------------------------
-- Melihat jumlah order dan pendapatan tiap channel (Website, App Store, Offline Store) di 2024
SELECT
    FORMAT_DATE('%Y-%m', order_date) AS month,                -- Format tanggal jadi Tahun-Bulan
    channel_type,                                             -- Nama channel
    COUNT(DISTINCT order_id) AS total_order,                  -- Hitung jumlah order (tanpa duplikat)
    SUM(after_discount) AS revenue                            -- Total pendapatan setelah diskon
FROM 
    `tokopaedi.order_detail`
WHERE 
    EXTRACT(YEAR FROM order_date) = 2024                      -- Filter tahun 2024
    AND is_valid = 1                                          -- Hanya yang sudah dibayar
    AND channel_type IN ('Website', 'App Store', 'Offline Store')
GROUP BY 
    1, 2                                                      -- Grouping berdasarkan bulan dan channel
ORDER BY 
    1, 2;


-- -------------------------------------------------------------------------------------
-- CASE 3.2: Perbandingan Pendapatan Bulanan 2024 vs 2023
-- -------------------------------------------------------------------------------------
-- Membandingkan pendapatan tiap bulan di 2024 dengan bulan yang sama di 2023
-- Pakai WITH (CTE) untuk memisahkan hitungan tahun 2024 dan 2023 sebelum digabung
WITH tahun2024 AS (
    SELECT
        EXTRACT(MONTH FROM order_date) AS bulan,              -- Ambil angka bulan (1-12) untuk 2024
        SUM(after_discount) AS revenue_2024
    FROM 
        `tokopaedi.order_detail`
    WHERE 
        order_date >= '2024-01-01'
        AND order_date < '2025-01-01'
        AND is_valid = 1
    GROUP BY 
        bulan
),
tahun2023 AS (
    SELECT
        EXTRACT(MONTH FROM order_date) AS bulan,              -- Ambil angka bulan (1-12) untuk 2023
        SUM(after_discount) AS revenue_2023
    FROM 
        `tokopaedi.order_detail`
    WHERE 
        order_date >= '2023-01-01'
        AND order_date < '2024-01-01'
        AND is_valid = 1
    GROUP BY 
        bulan
)
SELECT
    tahun2023.bulan,
    tahun2024.revenue_2024,
    tahun2023.revenue_2023,
    ROUND(
        (tahun2024.revenue_2024 - tahun2023.revenue_2023)
        * 100.0
        / NULLIF(tahun2023.revenue_2023, 0),                  -- NULLIF biar tidak error kalau pembaginya 0
        2
    ) AS yoy                                                  -- Persentase kenaikan/penurunan (%)
FROM 
    tahun2023
JOIN 
    tahun2024
    ON tahun2023.bulan = tahun2024.bulan                      -- Gabungkan berdasarkan bulan yang sama
ORDER BY 
    tahun2023.bulan;


-- -------------------------------------------------------------------------------------
-- CASE 4: Konversi Trafik Organik 2024
-- -------------------------------------------------------------------------------------
-- Menghitung persentase kunjungan organik yang berhasil jadi order di tiap channel
SELECT
    channel_source,                                                           -- Asal channel (Website, App Store, Play Store)
    COUNT(event) AS jumlah_event,                                             -- Total kunjungan organik
    COUNT(order_id) AS jumlah_order,                                          -- Total yang jadi order
    ROUND(SAFE_DIVIDE(COUNT(DISTINCT order_id), COUNT(event)) * 100, 2) AS rate -- Hitung % konversi (SAFE_DIVIDE biar aman dari bagi 0)
FROM 
    `tokopaedi.funnel_detail`
WHERE 
    EXTRACT(YEAR FROM funnel_date) = 2024                                     -- Filter tahun 2024
    AND event = "Organic"                                                     -- Ambil yang organik saja
GROUP BY 
    1
ORDER BY 
    4 DESC;                                                                   -- Urutkan dari persentase tertinggi


-- -------------------------------------------------------------------------------------
-- CASE 5.1: Jumlah Pelanggan Baru per Bulan di 2024
-- -------------------------------------------------------------------------------------
-- Menghitung total user baru yang daftar tiap bulan di masing-masing channel (baik sudah belanja atau belum)
SELECT
    EXTRACT(MONTH FROM registration_date) AS month,           -- Bulan daftar (1-12)
    registration_channel,                                     -- Channel tempat daftar
    COUNT(DISTINCT customer_id) AS new_customer               -- Jumlah pelanggan baru
FROM 
    `tokopaedi.customer_detail`
WHERE 
    EXTRACT(YEAR FROM registration_date) = 2024               -- Filter pendaftar tahun 2024
GROUP BY 
    1, 2
ORDER BY 
    1, 2;


-- -------------------------------------------------------------------------------------
-- CASE 5.2: Pelanggan Baru yang Sudah Belanja & Rata-rata Waktu ke Order Pertama
-- -------------------------------------------------------------------------------------
-- Mencari tanggal belanja pertama tiap user, lalu hitung rata-rata selisih harinya dari tanggal daftar
WITH first_order AS (
    SELECT
        customer_id,
        MIN(DATE(order_date)) AS first_order_date             -- Cari tanggal transaksi pertama per customer
    FROM
        `tokopaedi.order_detail`
    WHERE
        is_valid = 1                                          -- Hanya yang sudah bayar
    GROUP BY
        customer_id
)
SELECT
    EXTRACT(MONTH FROM c.registration_date) AS month_regist,  -- Bulan daftar
    c.registration_channel,                                   -- Channel daftar
    COUNT(DISTINCT c.customer_id) AS total_new_customers,     -- Jumlah user baru yang sudah pernah belanja
    ROUND(
        AVG(DATE_DIFF(fo.first_order_date, DATE(c.registration_date), DAY)),
        2
    ) AS avg_days_to_first_order                              -- Rata-rata selisih hari dari daftar sampai belanja pertama
FROM
    `tokopaedi.customer_detail` c
INNER JOIN
    first_order fo ON c.customer_id = fo.customer_id          -- INNER JOIN otomatis menyaring user yang sudah pernah belanja saja
WHERE
    EXTRACT(YEAR FROM c.registration_date) = 2024             -- Filter yang daftar di 2024
GROUP BY
    1, 2
ORDER BY
    month_regist ASC,
    total_new_customers DESC;
