-- select semua
SELECT * FROM uber_books LIMIT 10;
/*
 * CAUTION ::
 * DONT USE THE RAW DATA IF YOU WORK WITH DATA CREATE STAGING FIRST AND YOU FEEL FREE TO DO EKSPLOR YOUR ANALYTICS
 */
-- buat staging table
CREATE TABLE uber_books_staging
(LIKE uber_books INCLUDING ALL);
-- pindah data ke staging table
INSERT  INTO uber_books_staging 
SELECT * from uber_books;
-- 1. cek duplicates data
WITH duplicate_value AS (
SELECT 
	*,
	row_number() over(PARTITION BY booking_id, customer_id  ORDER BY date desc) AS rn
FROM uber_books_staging
)
SELECT *
FROM duplicate_value
WHERE rn >=1
LIMIT 10;
/* conclusion
	seluruh kolom yg ada pada dataset uber_books(ncr_ride_bookings) bersifat unique dan tidak ada duplicate values 
*/

-- 2 Standardize the data
SELECT 
	date,
	booking_id,
	customer_id
FROM uber_books_staging;
-- update date columns to DATE datatype
ALTER TABLE uber_books_staging ALTER COLUMN date type DATE USING date::DATE;

-- trim dan rapihkan booking_id
SELECT  customer_id,booking_id
FROM uber_books_staging;
-- update booking_id
UPDATE uber_books_staging
SET booking_id = trim(BOTH '"' FROM booking_id)
WHERE booking_id LIKE '%"%';
-- update customer_id
UPDATE uber_books_staging 
SET customer_id = trim(BOTH '"' FROM customer_id)
WHERE customer_id LIKE '%"%';

-- update dan ubah tipe data 'time' ke TIME
ALTER TABLE uber_books_staging 
ALTER COLUMN time TYPE TIME USING "time"::TIME;
-- handle the nulls value
SELECT 
	COALESCE(avg_vtat::text, 'Unknown') AS cleaned_avg_vtat,
	COALESCE(cancelled_rides_by_customer::text, 'Unknown') AS cleaned_avg_ctat,
	COALESCE(reason_for_cancelling_by_customer, 'Unknown') AS cleaned_avg_ctat
FROM uber_books_staging;
SELECT * FROM uber_books_staging LIMIT 10;