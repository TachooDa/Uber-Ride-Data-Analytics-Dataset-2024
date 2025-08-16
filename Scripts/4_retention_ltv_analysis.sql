-- section for customer segmentation
-- to find total life time value untuk customer
WITH customer_ltv as(
SELECT
	customer_id,
	sum(booking_value) AS total_ltv
FROM uber_books_staging
WHERE
	booking_value IS NOT null
GROUP BY customer_id
), customer_quarter AS (
SELECT
	percentile_cont(0.25) WITHIN GROUP (ORDER BY total_ltv) AS ltv_q1,
	percentile_cont(0.75) WITHIN GROUP (ORDER BY total_ltv) AS ltv_q3
FROM customer_ltv
), segmenting_customer AS (
	SELECT
		cl.*,
		CASE
			WHEN cl.total_ltv < cq.ltv_q1 THEN '1-- Low-value'
			WHEN cl.total_ltv <= cq.ltv_q3 THEN '2-- Mid-value'
			ELSE '3-- High-value'
		END AS customer_segment
	FROM customer_ltv AS cl,
	customer_quarter AS cq
)
SELECT
	customer_segment,
	round(sum(total_ltv::numeric),2) AS total_ltv,
	count(DISTINCT customer_id) AS customer_count,
	round(sum(total_ltv::numeric) / count(customer_id::text),2) AS avg_ltv
FROM segmenting_customer
GROUP BY customer_segment
ORDER BY customer_segment DESC;


-- retention analysis untuk cek churned customer order dalam kurun waktu terakhir ( 6 bulan di 2024)
WITH customer_order_info AS (
    -- Dapatkan tanggal pesanan terakhir untuk setiap pelanggan
    SELECT
        customer_id,
        MAX(date) AS last_order_date,
        MIN(date) AS first_order_date
    FROM uber_books_staging
    GROUP BY customer_id
),
customer_status AS (
    -- Hitung status pelanggan berdasarkan tanggal pesanan terakhir mereka.
    SELECT
        customer_id,
        first_order_date,
        EXTRACT(YEAR FROM first_order_date) AS cohort_year,
        CASE
           /*Seorang pelanggan dianggap ‘Churned’ jika pesanan terakhirnya lebih dari 6 bulan yang lalu
            -- dari akhir periode analisis (dalam hal ini, akhir tahun 2024).
            */
            WHEN last_order_date < '2024-12-31'::DATE - INTERVAL '6 months'
                 AND last_order_date >= '2024-01-01'::DATE
            THEN 'Churned'

            -- Seorang pelanggan dianggap ‘Aktif’ jika mereka melakukan pemesanan dalam 6 bulan terakhir tahun 2024.
            WHEN last_order_date >= '2024-12-31'::DATE - INTERVAL '6 months'
                 AND last_order_date <= '2024-12-31'::DATE
            THEN 'Active'
            
            /* Pelanggan yang pesanan terakhirnya sebelum 2024 dikategorikan sebagai ‘Lapsed’ atau ‘Inaktif’.
            -- Kategori ini mencakup pelanggan yang belum melakukan pesanan dalam waktu lama tetapi
             tidak selalu merupakan ‘churn’ baru dalam periode target.
            */
            ELSE 'Lapsed'
        END AS customer_status
    FROM customer_order_info
)
-- Penggabungan akhir untuk mendapatkan jumlah dan persentase untuk setiap segmen
SELECT
    cohort_year,
    customer_status,
    COUNT(customer_id) AS jumlah_customer,
    ROUND(
        COUNT(customer_id)::DECIMAL * 100 / SUM(COUNT(customer_id)) OVER (PARTITION BY cohort_year), 2
    ) AS percentage
FROM customer_status
WHERE cohort_year IS NOT NULL
GROUP BY
    cohort_year,
    customer_status
ORDER BY
    cohort_year,
    customer_status DESC;