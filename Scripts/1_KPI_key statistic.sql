-- Exploratory Data Analysis
-- total bookings
SELECT
	count(DISTINCT booking_id) AS total_bookings
FROM
	uber_books_staging;
-- total customer
SELECT
	count(customer_id) AS total_customer
FROM
	uber_books_staging;
-- success rate -> rumus (jumlah booking complete / total booking * 100)
SELECT 
	vehicle_type,
	sum(booking_value) AS revenue,
	count(*) FILTER(WHERE booking_status = 'Completed')::decimal AS complete_ride,
	round((
		count(*) FILTER(WHERE booking_status = 'Completed')::decimal /
	count(*)::decimal
	)* 100,2) AS success_rate
FROM
	uber_books_staging
GROUP BY vehicle_type
ORDER BY vehicle_type;
-- incomplete booking status
SELECT 
	count(*) FILTER (
	WHERE
		booking_status = 'Incomplete'
	)::decimal AS incomplete_ride,
	(
		count(*) FILTER (
		WHERE
			booking_status = 'Incomplete'
		)::decimal /
		count(*)::decimal
	) * 100 AS failed_rate
FROM
	uber_books_staging;

-- cancelled percentage
SELECT
    COUNT(*) FILTER (
        WHERE
            booking_status IN (
                'No Driver Found',
                'Incomplete',
                'Cancelled by Driver',
                'Cancelled by Customer'
            )
    ) AS cancelled_bookings,
    COUNT(DISTINCT booking_id) AS total_bookings,
    ROUND(
        COUNT(*) FILTER (
            WHERE
                booking_status IN (
                    'No Driver Found',
                    'Incomplete',
                    'Cancelled by Driver',
                    'Cancelled by Customer'
                )
        )::DECIMAL * 100 / COUNT(booking_id), 2
    ) AS cancellation_rate_percent
FROM
    uber_books_staging;
-- customer cancellation or cancel by customer
SELECT
	COUNT(*) FILTER (
	WHERE
		booking_status = 'Cancelled by Customer'
	)::DECIMAL AS customer_cancellation,
	round(
    	(count(*) FILTER(WHERE booking_status = 'Cancelled by Customer')::decimal /
    	count(*)::decimal) * 100, 2
    ) AS customer_cancel_rates
FROM
	uber_books_staging;
-- no driver found percentage
SELECT
	COUNT(*) FILTER (
	WHERE
		booking_status = 'No Driver Found'
	)::DECIMAL AS no_driver,
	round(
    	(count(*) FILTER(WHERE booking_status = 'No Driver Found')::decimal /
    	count(*)::decimal) * 100, 2
    ) AS no_driver_found_rate
FROM
		uber_books_staging;

-- driver cancellation or cancel by driver
SELECT
	count(*) FILTER(WHERE booking_status = 'Cancelled by Driver')::decimal AS driver_cancellation,
	round(
		(count(*) FILTER(WHERE booking_status = 'Cancelled by Driver')::decimal /
		count(*)::decimal) * 100, 2
	) AS driver_cancel_rate
FROM
	uber_books_staging;

-- total revenue
SELECT
	sum(booking_value) AS booking_revenue,
	round(avg(ride_distance::NUMERIC), 2) AS avg_distance
FROM
	uber_books_staging;

-- volumer perjalan over time
SELECT
	EXTRACT(MONTH FROM date) AS MONTH,
	count(DISTINCT booking_id) AS count_of_booking_id
FROM
	uber_books_staging
GROUP BY
	MONTH;

/*
 * Statistical insight
 * Total Bookings : 148,767K atau 148.77k perjalanan/rides
 * Success Rate/complete books : 62% (total of dari 93k perjalanan)
 * Cancellation Rate/cancel books: 38% (46.500 booking yang di cancel)
 * Driver Cancellation/driver cancel : 18%(total 27k perjalanan di cancel oleh driver)
 * No Driver Found : 7% (dari 10.5k pelanggan tidak menemukan driver yg sesuai)
 * Customer Cancelation: 7% (total dari 10.5k perjalanan di cancel oleh customer)
 * * incomplete rate/books : 6% (total dari 9k perjalanan yg tidak selesai)
 */

-- KPI and funnels insight
-- 1. vehicle fleet coverage (untuk table)
WITH fleet_coverage AS (
	SELECT
		vehicle_type,
		booking_value,
		booking_status,
		booking_id,
		ride_distance,
		driver_ratings,
		customer_rating
	FROM
		uber_books_staging
)
SELECT 
	vehicle_type AS tipe_kendaraan,
	count(booking_id) AS total_pemesanan,
	round(count(DISTINCT booking_id) FILTER (WHERE booking_status = 'Completed'), 2) AS completed,
	round(sum(booking_value::NUMERIC), 0) AS booking_revenue,
		round(avg(ride_distance::NUMERIC), 2) AS avg_distance,
			round(sum(ride_distance::NUMERIC), 0) AS total_distance_covered,
	round(avg(driver_ratings::NUMERIC), 2) AS avg_driver_ratings,
	round(avg(customer_rating::NUMERIC), 2) AS avg_customer_ratings,
	round(
		(count(*) FILTER (WHERE booking_status = 'Completed')::decimal
		/ count(*)::decimal
	)* 100, 2) AS rate_pemesanan_sukses
FROM
	fleet_coverage
GROUP BY
	vehicle_type
HAVING
	avg(ride_distance) IS NOT NULL
	AND sum(ride_distance) IS NOT NULL
ORDER BY
	booking_revenue DESC;
-- 2. booking status mix and percentage status
WITH total AS (
	SELECT
		COUNT(*)::decimal AS total_bookings
	FROM
		uber_books_staging
)
SELECT
	booking_status,
	COUNT(*)::decimal AS total_bookings,
	ROUND((COUNT(*)::decimal / total.total_bookings) * 100, 2) AS percentage_status
FROM
	uber_books_staging,
	total
GROUP BY
	booking_status,
	total.total_bookings
ORDER BY
	total_bookings DESC;

--3. coversion funnel
SELECT
    booking_category,
    COUNT(booking_id) AS total_bookings_by_category,
    ROUND(
        COUNT(booking_id)::DECIMAL * 100 / (SELECT COUNT(*) FROM uber_books_staging), 2
    ) AS percentage_of_total
FROM (
    SELECT
        booking_id,
        CASE
            WHEN booking_status = 'Completed' THEN 'Completed'
            WHEN booking_status = 'Incomplete' THEN 'Incomplete'
            WHEN booking_status IN ('Cancelled by Customer', 'Cancelled by Driver') THEN 'Cancelled'
            ELSE 'Others'
        END AS booking_category
    FROM
        uber_books_staging
) AS categorized_bookings
GROUP BY
    booking_category
ORDER BY
    total_bookings_by_category DESC;
