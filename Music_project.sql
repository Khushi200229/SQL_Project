USE music_database;

# SET 1 - Easy

# Who is the senior most employee based on job title?
SELECT * FROM employee
ORDER BY levels DESC
LIMIT 1;

# Which countries have the most Invoices?
SELECT COUNT(*) AS Total, billing_country FROM invoice
GROUP BY billing_country
ORDER BY Total DESC;

# What are top 3 values of total invoice?
SELECT total FROM invoice
ORDER BY total DESC
LIMIT 3;

# Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money.
-- Write a query that returns one city that has the highest sum of invoice totals. Return both the city name and sum of all invoice totals.
SELECT SUM(total) AS Invoice_total, billing_city 
FROM invoice
GROUP BY billing_city
ORDER BY Invoice_total DESC
LIMIT 1;

# Who is the best customer? the customer who has spent the most money will be declared the best customer. 
-- Write a query that returns the person who has spent the most money. 
SELECT customer.customer_id, customer.first_name, customer.last_name, SUM(invoice.total) AS Total
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id, customer.first_name, customer.last_name
ORDER BY Total DESC
limit 1;

# SET 2 - Moderate

# Write query to return the email, first name, last name and genre of all Rock music listeners. Return your list ordered alphabetically by email starting with A 
#SELECT customer.email, customer.first_name, customer.last_name, genre.name
SELECT DISTINCT email, first_name, last_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track
	JOIN genre ON track.genre_id = genre.genre_id 
    WHERE genre.name = 'ROCK' 
)
ORDER BY email;

# Let's invite the artists who have written the most rock music in our dataset. Write a query that returns the Artist name and total track count of the top 10 rock bands
SELECT artist.artist_id, artist.name, COUNT(artist.artist_id) AS Number_of_songs
FROM track
JOIN album2 ON album2.album_id = track.album_id
JOIN artist ON artist.artist_id = album2.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id, artist.name
ORDER BY Number_of_songs DESC
LIMIT 10;

# Alternate Method
SELECT artist.artist_id, artist.name, COUNT(artist.artist_id) AS Number_of_songs
FROM artist
JOIN album2 ON artist.artist_id = album2.artist_id
JOIN track ON album2.album_id = track.album_id
WHERE track_id IN (
	SELECT track_id FROM track 
    JOIN genre ON track.genre_id = genre.genre_id
    WHERE genre.name = 'Rock'
)
GROUP BY artist.artist_id, artist.name
ORDER BY Number_of_songs DESC
LIMIT 10;

# Return all the track names that have a song length longer than the average song length. Return the name and Milliseconds for each track. 
-- Order by the song length with the longest songs listed first. 
SELECT name, milliseconds
FROM track 
WHERE milliseconds > (
	SELECT AVG (milliseconds) AS avg_song_length
    FROM track
    )
ORDER BY milliseconds DESC;

# SET 3 - Advance

# Find how much amount is spent by each customer on artists? Write a query to return customer name, artist name and total spent
WITH best_selling_artist AS (
	SELECT artist.artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
    FROM invoice_line
    JOIN track ON track.track_id = invoice_line.track_id
    join album2 ON album2.album_id = track.album_id
    JOIN artist ON artist.artist_id = album2.artist_id
    GROUP BY 1,2
    ORDER BY 3 DESC
    LIMIT 1
)
-- SELECT c.customer_id, c.first_name, c.last_name, art.name,
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name,
SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i 
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album2 alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
-- JOIN artist art ON art.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

# We want to find out the most popular music genre for each country. We determine the most popular genre as the genre with the highest amount of purchases. 
-- Write a query that returns each country along with the top genre. For countries where the maximum number of purchases is shared return all genres. 
WITH popular_genre AS
(
	SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id,
    ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo
    FROM invoice_line
    JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
    JOIN customer ON customer.customer_id = invoice.customer_id 
    JOIN track ON track.track_id = invoice_line.track_id
    JOIN genre ON genre.genre_id = track.genre_id
    GROUP BY 2,3,4
    ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1;

# Alternate Method
WITH sales_per_country AS(
		SELECT COUNT(*) AS purchase_per_genre, customer.country, genre.name, genre.genre_id
        FROM invoice_line
        JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
        JOIN customer ON customer.customer_id = invoice.customer_id
        JOIN track ON track.track_id = invoice_line.track_id
        JOIN genre ON genre.genre_id = track.genre_id
        GROUP BY 2,3,4
        ORDER BY 2
),
max_genre_per_country AS (SELECT MAX(purchase_per_genre) AS max_genre_number, country
	FROM sales_per_country
    GROUP BY 2
    ORDER BY 2
)
SELECT sales_per_country.*
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country 
WHERE sales_per_country.purchase_per_genre = max_genre_per_country.max_genre_number;

# Write a query that determines the customer that has spent the most on music for each country. 
-- Write a query that returns the country along with the top customer and how much they spent. 
-- For countries where the top amount spent is shared, provide all customers who spent this amount. 
WITH Customer_with_country AS (
	SELECT customer.customer_id, first_name, last_name, billing_country, SUM(total) AS Total_Spending,
    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo
    FROM invoice
    JOIN customer ON customer.customer_id = invoice.customer_id
    GROUP BY 1,2,3,4
    ORDER BY 4 ASC, 5 DESC)
SELECT * FROM Customer_with_country WHERE RowNo <= 1;
