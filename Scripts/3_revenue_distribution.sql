-- 1. distribusi jarak perjalanan per hari dan per metode pembayaran
SELECT
	payment_method,
	EXTRACT(DAY FROM "date") AS daily_rides,
	ROUND(SUM(ride_distance::NUMERIC), 0) AS total_distance_covered
FROM
	uber_books_staging
WHERE
	payment_method IS NOT NULL
GROUP BY
	payment_method,
	EXTRACT(DAY FROM "date")
ORDER BY
	payment_method DESC;
-- 2. Revenue distribution berdasarkan metode pembayaran (dalam persen)
WITH payment_status AS (
	SELECT
		payment_method,
		count(DISTINCT booking_id) AS total_bookings,
		round(sum(booking_value::NUMERIC), 2) AS booking_revenue,
		count(DISTINCT booking_id) FILTER (
		WHERE
			booking_status = 'Completed'
		) AS completed_bookings
	FROM
		uber_books_staging
	WHERE
		payment_method IS NOT NULL
	GROUP BY
		payment_method
)
SELECT 
	payment_method,
	total_bookings,
	round(booking_revenue, 2) AS booking_revenue,
	round((completed_bookings::decimal / total_bookings::decimal)* 100, 2) AS success_rate,
	round((booking_revenue / sum(booking_revenue) OVER())* 100 , 2) AS revenue_shared
FROM
	payment_status
ORDER BY
	booking_revenue DESC;
-- 3. Cancel pattern by customer
WITH cancel_status AS (
	SELECT
		reason_for_cancelling_by_customer,
		count(DISTINCT booking_id) AS cancel_count
	FROM
		uber_books_staging
	WHERE
		reason_for_cancelling_by_customer IS NOT NULL
		AND cancelled_rides_by_customer IS NOT NULL
	GROUP BY
		reason_for_cancelling_by_customer
)
SELECT
	reason_for_cancelling_by_customer,
	round(
		(cancel_count::decimal / sum(cancel_count) OVER())* 100, 1
	) AS cancel_percentage
FROM
	cancel_status
ORDER BY
	cancel_percentage DESC;
-- 4. Cancel pattern by driver
WITH driver_cancel AS (
	SELECT
		driver_cancellation_reason,
		count(DISTINCT booking_id) AS driver_cancel
	FROM
		uber_books_staging
	WHERE
		driver_cancellation_reason IS NOT NULL
		AND cancelled_rides_by_driver IS NOT NULL
	GROUP BY
		driver_cancellation_reason
)
SELECT 
	driver_cancellation_reason,
	round(
		(driver_cancel::decimal / sum(driver_cancel) OVER()) * 100, 1
	) AS driver_cancel_per_percent
FROM
	driver_cancel
ORDER BY
	driver_cancel_per_percent DESC;
-- 5. Rating analysis
/*
 *	Goals :
 *		- Customer Rating
 *		- Driver Ratings
 *		- Highest Rated
 * 		- Most statisfied Drivers
 */
WITH summary_ratings AS (
	SELECT
		vehicle_type,
		round(avg(customer_rating::NUMERIC), 2) AS avg_customer_rating,
		round(avg(driver_ratings::NUMERIC), 2) AS avg_driver_rating
	FROM
		uber_books_staging
	WHERE
		customer_rating IS NOT NULL
		AND driver_ratings IS NOT NULL
	GROUP BY
		vehicle_type
)
SELECT
	*,
	CASE 
		WHEN avg_customer_rating = max(avg_customer_rating) OVER() THEN 'High Customer Rated'
	END AS customer_rating_flag,
	CASE
		WHEN avg_driver_rating = max(avg_driver_rating) OVER() THEN 'Most Statisfied Drivers'
	END AS driver_rating_flag
FROM
	summary_ratings
ORDER BY
	avg_customer_rating DESC,
	avg_driver_rating DESC;

-- rating distribution
-- driver ratings distribution
SELECT
	driver_ratings,
	count(*) AS frequency
FROM uber_books_staging
WHERE driver_ratings IS NOT null
GROUP BY driver_ratings 
ORDER BY driver_ratings;
--GROUP BY booking_id;

-- customer ratings distribution
SELECT
	customer_rating,
	count(*) AS frequencys_rating
FROM uber_books_staging
WHERE
	customer_rating IS NOT null
GROUP BY customer_rating 
ORDER BY customer_rating ;

-- churn customer rating
SELECT 
	count(*) AS total_ratings,
	sum(
		CASE
			WHEN customer_rating < 4.0 THEN 1 ELSE 0 END 
		) AS low_rating_count,
	round(
		(sum(CASE WHEN customer_rating < 4.0 THEN 1 ELSE 0 END )* 100
	) /count(*),2) AS low_ratings_percentage
FROM uber_books_staging
WHERE customer_rating IS NOT NULL;


SELECT 
	count(*) AS total_order,
	sum(
		CASE
			WHEN driver_ratings < 4.0 THEN 1 ELSE 0 END 
		) AS low_rating_count,
	round(
		(sum(CASE WHEN driver_ratings < 4.0 THEN 1 ELSE 0 END )* 100
	) /count(*),2) AS low_ratings_percentage
FROM uber_books_staging
WHERE driver_ratings IS NOT NULL;

