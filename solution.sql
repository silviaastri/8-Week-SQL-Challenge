-----------------------------------
-- CASE STUDY #1: DANNYS'S DINER --
-----------------------------------

-- Author	: Silvia
-- Date		: 24/09/2022
-- Tool used: PostgreSQL

SET search_path TO dannys_diner; 

SELECT * FROM members | --customer_id, join_date
SELECT * FROM menu --product_id, product_name, price
SELECT * FROM sales --customer_id, order_date, product_id

--1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, 
	   CONCAT('$', SUM(m.price)) AS total_spent 
FROM sales AS s
JOIN menu as m 
  ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 2 DESC;

--2. How many days has each customer visited the restaurant?
SELECT customer_id, 
	   COUNT(DISTINCT(order_date)) AS count_visit
FROM sales
GROUP BY 1
ORDER BY 2 DESC;

--3. What was the first item from the menu purchased by each customer?
--3A) Using CTE
WITH first_item AS (
	 SELECT s.customer_id,
			s.order_date,
			m.product_name,
			DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS ranks 
	 FROM sales AS s
	 JOIN menu AS m
	   ON s.product_id = m.product_id)

SELECT customer_id, product_name
FROM first_item
WHERE ranks = 1
GROUP BY 1, 2

====================================================================
--3B) Using Derived Table
SELECT CUSTOMER_ID, PRODUCT_NAME
FROM
	(
	SELECT CUSTOMER_ID, 
		   ORDER_DATE,
		   PRODUCT_NAME,
		   DENSE_RANK() OVER(PARTITION BY S.CUSTOMER_ID
							ORDER BY S.ORDER_DATE) AS RANK
	FROM SALES AS S
	JOIN MENU AS M
	ON S.PRODUCT_ID = M.PRODUCT_ID) AS ITEM_RANK
WHERE RANK = 1
GROUP BY CUSTOMER_ID, PRODUCT_NAME;
====================================================================

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?
--4A) Using LIMIT Clause
SELECT m.product_name AS most_purchased_item,
	   COUNT(s.product_id) AS quantity
FROM sales as s
JOIN menu as m
  ON m.product_id = s.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

============================================================
--4B) Using Derived Table
SELECT MOST_PURCHASED_ITEM, ORDER_COUNT
FROM
	(SELECT PRODUCT_NAME AS MOST_PURCHASED_ITEM,
 	 COUNT(S.PRODUCT_ID) AS ORDER_COUNT,
 	 DENSE_RANK() OVER(
 		   ORDER BY COUNT(S.PRODUCT_ID) DESC) AS ORDER_RANK
	 FROM MENU AS M
	 JOIN SALES AS S
	 ON M.PRODUCT_ID = S.PRODUCT_ID
	 GROUP BY PRODUCT_NAME) ITEM_COUNT
WHERE ORDER_RANK = 1;
============================================================

--5. Which item was the most popular for each customer?
WITH popular_item AS (
	 SELECT s.customer_id, 
	   		m.product_name, 
	   		COUNT(m.product_id) AS quantity,
	   		DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.customer_id) DESC) AS ranks
	 FROM sales AS s
	 JOIN menu AS m 
	   ON s.product_id = m.product_id
	 GROUP BY 1,2
)
SELECT customer_id, product_name, quantity
FROM popular_item
WHERE ranks = 1;

--6. Which item was purchased first by the customer after they became a member?
WITH purchased_first AS(
						SELECT s.customer_id,
	   						   s.order_date,
	   						   m.product_name,
	   						   mb.join_date,
	   						   DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS ranks
	   					FROM sales AS s
						JOIN members AS mb ON s.customer_id = mb.customer_id
						JOIN menu AS m ON s.product_id = m.product_id
						WHERE order_date >= join_date
)
SELECT customer_id, product_name, join_date, order_date
FROM purchased_first
WHERE ranks = 1;

--7. Which item was purchased just before the customer became a member?
WITH purchased_before AS(
						 SELECT s.customer_id,
	   							s.order_date,
	   							m.product_name,
	   							mb.join_date,
	   							DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS ranks
						FROM sales AS s
						JOIN members AS mb ON s.customer_id = mb.customer_id
						JOIN menu AS m ON s.product_id = m.product_id
						WHERE s.order_date < mb.join_date
)
SELECT customer_id, product_name, order_date, join_date
FROM purchased_before
WHERE ranks = 1;

--8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id,
	   COUNT(s.product_id) AS total_items,
	   CONCAT('$', SUM(m.price)) AS amount_spent
FROM sales AS s
JOIN menu AS m ON s.product_id = m.product_id
JOIN members AS mb ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date 
GROUP BY 1
ORDER BY 1;

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?
WITH price_points AS(
					 SELECT *,
					 CASE WHEN product_id = 1 THEN price * 20
					 	  ELSE price * 10
						  END AS points
					 FROM menu)

SELECT s.customer_id, 
	   SUM(p.points) AS total_points
FROM price_points AS p
JOIN sales AS s ON p.product_id = s.product_id
GROUP BY 1
ORDER BY 2 DESC;

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?
WITH points_cte AS(
				   SELECT s.customer_id,
						  s.order_date,
						  s.product_id,
						  CASE WHEN s.product_id = 1 THEN price * 20
							   WHEN s.order_date >= mb.join_date AND s.order_date < (mb.join_date + interval '7 days') THEN price * 20
							   ELSE price * 10 END AS points
				   FROM sales AS s
				   JOIN members AS mb ON s.customer_id = mb.customer_id
				   JOIN menu AS m ON s.product_id = m.product_id
				   WHERE s.order_date <= to_date('2021-01-31','YYYY-MM-DD'))


SELECT customer_id,
	   SUM(points) AS total_points
FROM points_cte
GROUP BY 1;

SELECT * FROM members | --customer_id, join_date
SELECT * FROM menu --product_id, product_name, price
SELECT * FROM sales --customer_id, order_date, product_id
================================
BONUS QUESTIONS
================================
--JOIN ALL
SELECT s.customer_id,
	   s.order_date,
	   m.product_name,
	   m.price,
	   CASE WHEN s.order_date >= mb.join_date THEN 'Y'
	   	    ELSE 'N' END AS member
FROM sales AS s
LEFT JOIN menu AS m ON s.product_id = m.product_id
LEFT JOIN members AS mb ON s.customer_id = mb.customer_id
ORDER BY 1,2 

--RANK ALL
WITH RANKS AS(
			  SELECT s.customer_id,
	   	   	  		 s.order_date,
	       			 m.product_name,
	       			 m.price,
	       			 CASE WHEN s.order_date >= mb.join_date THEN 'Y'
	   	        		  ELSE 'N' END AS member
			  FROM sales AS s
			  LEFT JOIN menu AS m ON s.product_id = m.product_id
			  LEFT JOIN members AS mb ON s.customer_id = mb.customer_id
)
SELECT customer_id,
	   order_date,
	   product_name,
	   price,
	   member,
	   CASE WHEN member = 'Y' THEN RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date) ELSE NULL END AS ranking
FROM ranks;


	   