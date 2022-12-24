```sql
SET search_path TO dannys_diner; 
```
___

**QUESTION 1**
---
What is the total amount each customer spent at the restaurant?

```sql
SELECT s.customer_id, 
       CONCAT('$', SUM(m.price)) AS total_spent 
FROM sales AS s
JOIN menu as m 
  ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 2 DESC;
```

customer_id | total_spent
------------|-------------
A | $76
B | $74
C | $36

___
**QUESTION 2**
---
How many days has each customer visited the restaurant?

```sql
SELECT customer_id, 
       COUNT(DISTINCT(order_date)) AS count_visit
FROM sales
GROUP BY 1
ORDER BY 2 DESC;
```
customer_id | count_visit
------------|-------------
B | 6
A | 4
C | 2

___
**QUESTION 3**
---
What was the first item from the menu purchased by each customer?

```sql
WITH first_item AS (
     SELECT s.customer_id,
            s.order_date,
            m.product_name,
            DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS ranks
     FROM sales AS S
     JOIN menu AS m
       ON s.product_id = m.product_id)
       
SELECT customer_id, product_name
FROM first_item
WHERE ranks = 1
GROUP BY 1,2
```
customer_id | product_name
------------|-------------
A | curry
A | sushi
B | curry
C | ramen

___
**QUESTION 4**
---
What is the most purchased item on the menu and how many times was it purchased by all customers?

```sql
SELECT m.product_name AS most_purchased_item,
       COUNT(s.product_id) AS quantity
FROM sales as s
JOIN menu as m
  ON m.product_id = s.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;
```
most_purchased_item | quantity
--------------------|---------
ramen | 8

___
**QUESTION 5**
---
Which item was the most popular for each customer?

```sql
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
```
customer_id | product_name | quantity
------------|--------------|---------
A | ramen | 3
B | sushi | 2
B | curry | 2
B | ramen | 2
C | ramen | 3

___
**QUESTION 6**
---
Which item was purchased first by the customer after they became a member?

```sql
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
```
customer_id | product_name | join_date | order_date
------------|--------------|-----------|-----------
A | curry | 2021-01-07 | 2021-01-07
B | sushi | 2021-01-09 | 2021-01-11

___
**QUESTION 7**
---
Which item was purchased just before the customer became a member?

```sql
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
```
customer_id | product_name | order_date | join_date  
------------|--------------|------------|----------
A | sushi | 2021-01-01 | 2021-01-07
A | curry | 2021-01-01 | 2021-01-07
B | sushi | 2021-01-04 | 2021-01-09

___
**QUESTION 8**
---
What is the total items and amount spent for each member before they became a member?

```sql
SELECT s.customer_id,
       COUNT(s.product_id) AS total_items, 
       CONCAT('$', SUM(m.price)) AS amount_spent
FROM sales AS s
JOIN menu AS m ON s.product_id = m.product_id
JOIN members AS mb ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date 
GROUP BY 1
ORDER BY 1;
```
customer_id | total_items | amount_spent  
------------|-------------|-------------
A | 2 | $25
B | 3 | $40

___
**QUESTION 9**
---
If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?

```sql
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
```
customer_id | total_points
------------|-------------
B | 940
A | 860
C | 360

___
**QUESTION 10**
---
In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?

```sql
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
```
customer_id | total_points
------------|-------------
A | 1370
B |  820

___
**BONUS QUESTIONS**
---

**JOIN ALL**
```sql
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
```

---

**RANK ALL**
```sql
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
```

___
