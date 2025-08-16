-- buat table
CREATE TABLE uber_books (
    date TEXT,
    time TEXT,
    booking_id TEXT,
    booking_status TEXT,
    customer_id TEXT,
    vehicle_type TEXT,
    pickup_location TEXT,
    drop_location TEXT,
    avg_vtat REAL,
    avg_ctat REAL,
    cancelled_rides_by_customer REAL,
    reason_for_cancelling_by_customer TEXT,
    cancelled_rides_by_driver REAL,
    driver_cancellation_reason TEXT,
    incomplete_rides REAL,
    incomplete_rides_reason TEXT,
    booking_value REAL,
    ride_distance REAL,
    driver_ratings REAL,
    customer_rating REAL,
    payment_method TEXT
);


-- load file csv ke pgadmin tools
\copy uber_books FROM 'C:\Users\USER\Documents\Data Analyst Course\archive\ncr_ride_bookings.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8', NULL 'null');


-- tes load data (apakah berhasil)
SELECT *
FROM uber_books 
LIMIT 10;