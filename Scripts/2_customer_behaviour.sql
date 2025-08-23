SELECT
	*
FROM
	uber_books_staging
LIMIT 10;
-- top 5 customer
SELECT
	customer_id,
	pickup_location,
	sum(booking_value) AS total_bookings
FROM
	uber_books_staging
WHERE
	booking_value IS NOT NULL
GROUP BY
	customer_id,pickup_location 
ORDER BY
	total_bookings DESC
LIMIT 5;
-- 1. total customer dan revenue per tipe kendaraan yang di order
SELECT 
	DISTINCT vehicle_type AS tipe_kendaraan,
	count(DISTINCT booking_id) AS total_pesanan,
	count(DISTINCT customer_id) AS total_customer,
	sum(booking_value) AS total_revenue,
	round(avg(booking_value::NUMERIC), 2) AS avg_revenue,
	round(sum(booking_value::NUMERIC) / count(DISTINCT customer_id), 2) AS avg_rev_per_customer
FROM
	uber_books_staging
GROUP BY
	vehicle_type;
-- 2. Total rides and revenue over time
SELECT
	date,
	count(DISTINCT booking_id) AS total_rides,
	sum(booking_value) AS total_revenue
FROM
	uber_books_staging
WHERE
	date BETWEEN '2024-12-01' AND '2024-12-31'
GROUP BY
	date
ORDER BY
	date;
-- 2. Booking status breakdown
SELECT 
	booking_status,
	count(*)::decimal AS total_booking
FROM
	uber_books_staging
GROUP BY
	booking_status
ORDER BY
	total_booking DESC;
-- 3. vehicle and  customer distribution
SELECT
	vehicle_type,
	count(DISTINCT customer_id) AS customer,
	count(DISTINCT booking_id) AS total_bookings
FROM
	uber_books_staging
GROUP BY
	vehicle_type;
-- 4. top drop location and distribution
WITH drop_location_stats AS (
	SELECT
		drop_location,
		count(DISTINCT booking_id) AS total_bookings,
		count(DISTINCT CASE WHEN booking_status = 'Completed' THEN booking_id END)::decimal AS success_rides
	FROM
		uber_books_staging
	GROUP BY
		drop_location
), total_drop AS (
SELECT 
	drop_location,
	total_bookings ,	
	success_rides,
	concat(round((success_rides::decimal / total_bookings  )* 100, 2), '%') AS contribution_percent
FROM
	drop_location_stats
)
SELECT *
FROM total_drop
ORDER BY total_bookings DESC LIMIT 10;

-- 5. top pick up distribution
WITH pickup_stats AS (
	SELECT
		pickup_location,
		count(DISTINCT booking_id) AS total_bookings,
		count(DISTINCT CASE WHEN booking_status = 'Completed' THEN booking_id END) AS success_ride
	FROM
		uber_books_staging
	GROUP BY
		pickup_location
),
total_success AS (
	SELECT
		pickup_location,
		total_bookings,
		success_ride,
		concat(round((success_ride::decimal / total_bookings )* 100, 2),'%') AS success_rate
	FROM
		pickup_stats
)
SELECT
	*
FROM
	total_success
ORDER BY
	total_bookings DESC
LIMIT 10;
-- v2
SELECT 
	pickup_location,
	count(CASE WHEN booking_status = 'Completed' THEN booking_id END) AS success_rides,
	round(
			count(CASE WHEN booking_status = 'Completed' THEN booking_id END)::decimal * 100 /
			sum(count(CASE WHEN booking_status = 'Completed' THEN booking_id END)) OVER(), 2
	) AS pick_up_percent
FROM
	uber_books_staging
WHERE
	booking_status = 'Completed'
GROUP BY
	pickup_location
ORDER BY
	success_rides DESC
LIMIT 10;
-- 6. Preferensi kendaraan per customer segmentation
SELECT
	vehicle_type,
	count(DISTINCT customer_id) total_customer
FROM
	uber_books_staging
GROUP BY
	vehicle_type;
-- 7. alasan cancel berdasarkan customer (percentage)
SELECT
	reason_for_cancelling_by_customer,
	count(DISTINCT booking_id) AS total_cancel,
	concat(round(
		count(DISTINCT booking_id)* 100 /
		sum(count(DISTINCT booking_id)) OVER(),
		2
	),'%') AS cancel_percentage
FROM
	uber_books_staging
WHERE
	reason_for_cancelling_by_customer IS NOT NULL
GROUP BY
	reason_for_cancelling_by_customer
ORDER BY
	total_cancel DESC;
-- 8. alasan cancel berdasarkan driver per total customer
WITH cancel_counts AS (
	SELECT
		driver_cancellation_reason ,
		count(DISTINCT customer_id) AS total_customer,
		count(booking_id) AS total_cancel
	FROM
		uber_books_staging
	WHERE
		driver_cancellation_reason IS NOT NULL
	GROUP BY
		driver_cancellation_reason
)
SELECT 
	driver_cancellation_reason,
	total_customer,
	total_cancel,
	concat(round(
		total_cancel * 100 /
		sum(total_cancel) OVER(), 2
	),'%') AS cancel_in_percent_by_customer
FROM
	cancel_counts
ORDER BY
	total_cancel DESC;
-- 9.pembatalan order dari alasan driver
WITH percent_count AS (
	SELECT
		driver_cancellation_reason,
		count(DISTINCT booking_id) AS total_cancel
	FROM
		uber_books_staging
	WHERE
		driver_cancellation_reason IS NOT NULL
	GROUP BY
		driver_cancellation_reason
)
SELECT 
	driver_cancellation_reason,
	total_cancel,
	concat(round(
		total_cancel * 100.0 /
		sum(total_cancel) OVER() , 2
	),'%') AS cancel_in_percent_by_driver
FROM
	percent_count
ORDER BY
	total_cancel DESC;
-- 10. perjalanan yg tidak selesai
WITH incomplete_counts AS (
	SELECT
		COALESCE(incomplete_rides_reason, 'Unknown Reason'::text) AS incomplete_rides_reason,
		count(DISTINCT customer_id) AS total_customer,
		count(*) FILTER (
		WHERE
			incomplete_rides = '1'
		) AS total_incomplete_ride
	FROM
		uber_books_staging
	GROUP BY
		COALESCE(incomplete_rides_reason, 'Unknown Reason'::text)
)
SELECT
	incomplete_rides_reason,
	total_customer,
	total_incomplete_ride,
	concat(round(
		total_incomplete_ride * 100.0 /
		sum(total_incomplete_ride) OVER(), 2
	),'%') AS incomplete_in_percent
FROM
	incomplete_counts
ORDER BY
	total_incomplete_ride DESC;
