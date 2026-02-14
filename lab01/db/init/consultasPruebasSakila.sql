-- ¿Cuáles son las películas con más alquileres por categoría?
SELECT c.name AS categoria, f.title AS pelicula, COUNT(r.rental_id) AS total_alquileres
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN film f ON fc.film_id = f.film_id
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY c.name, f.title
ORDER BY total_alquileres DESC;

-- ¿Cuáles son los clientes cuyo gasto total es superior al promedio?
SELECT c.first_name, c.last_name, SUM(p.amount) AS total_gastado
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id
HAVING SUM(p.amount) > (
    SELECT AVG(total_cliente)
    FROM (
        SELECT SUM(amount) as total_cliente
        FROM payment
        GROUP BY customer_id
    ) as subquery
)
ORDER BY total_gastado DESC;

-- ¿Qué películas fueron alquiladas más veces que el promedio de su categoría?
WITH RentalCounts AS (
    SELECT f.film_id, f.title, c.category_id, COUNT(r.rental_id) as num_rentals
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    GROUP BY f.film_id, f.title, c.category_id
),
CategoryAverages AS (
    SELECT category_id, AVG(num_rentals) as avg_rentals
    FROM RentalCounts
    GROUP BY category_id
)
SELECT rc.title, rc.num_rentals, ca.avg_rentals
FROM RentalCounts rc
JOIN CategoryAverages ca ON rc.category_id = ca.category_id
WHERE rc.num_rentals > ca.avg_rentals;

-- ¿Qué clientes alquilaron en el primer trimestre pero no en el segundo?
SELECT DISTINCT c.customer_id, c.first_name, c.last_name
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
WHERE EXTRACT(MONTH FROM r.rental_date) IN (1, 2, 3)
EXCEPT
-- Clientes del Q2 (Abril - Junio)
SELECT DISTINCT c.customer_id, c.first_name, c.last_name
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
WHERE EXTRACT(MONTH FROM r.rental_date) IN (4, 5, 6);