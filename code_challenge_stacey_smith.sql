--/ MONTHLY REPORT
--/	Uses:  public.orders
--/ Returns the number of orders for each month, ordered by date (DESC).
--/ Date in YYYY-MM-01 format   /   Number of orders for the month /  Revenue for month in $nn.nn format

SELECT to_char(o."order_date", 'YYYY-MM-01') as orders_month,
COUNT(o."id") as number_of_orders,
to_char(SUM(CAST(o."price_cents" as INT)), 'FM$999,999.90') as revenue
FROM orders o
GROUP BY orders_month
ORDER BY orders_month DESC;


--/ USER SATISFACTION
--/	Uses:  public.ratings, public.orders, public.users
--/ Creates a VIEW public.vw_user_satisfaction 
--/ Shows user information and user satisfaction score, ordered by rank (DESC). 
--/ This assumes that the 4-star ranking works as 1=lowest (least satisfied) and 4=highest (most satisfied)
--/ The score is calculated by taking the average rating for the user's total orders and multiplying by the total number of orders

--DROP VIEW vw_user_satisfaction

CREATE VIEW vw_user_satisfaction AS
SELECT 
	u."id",
	CONCAT (u."last_name", ', ', u."first_name") as full_name,
	u."email",
	u."mobile_number",
	(SUM(r."stars")/COUNT(r."stars")) * COUNT(o."id") as score,
	RANK () OVER ( ORDER BY (SUM(r."stars")/COUNT(r."stars")) * COUNT(o."id") DESC) as "rank"
	
FROM users u
JOIN orders o
ON o."user_id" = u."id"
JOIN ratings r
ON r."order_id" = o."id"
GROUP BY u."id", full_name, u."email", u."mobile_number"

--SELECT * FROM vw_user_satisfaction LIMIT 25




--/ MARKETING DATA
--/ Queries return the users with the 10 highest scores (as shown in vw.user_satisfaction) and the users who have not yet placed an order
--/ The query results are given in JSON format
--/ Both queries are wrapped in functions so they can be easily reused later (also delivering results in JSON)


--/ Top Ten Scores
SELECT row_to_json(top_ten) FROM (SELECT full_name, email FROM vw_user_satisfaction) as top_ten LIMIT 10 

--/ No Orders
SELECT row_to_json(no_orders) FROM (
	
	SELECT * FROM (
		SELECT COUNT(o."id") as order_count,
		CONCAT (u."last_name", ', ', u."first_name") as full_name, 
		u."email"
		FROM orders o
		FULL OUTER JOIN users u
		ON o."user_id" = u."id"
		GROUP BY full_name, u."email"
	) as zero_group WHERE order_count = 0
	
) as no_orders



--/ Functions

--DROP FUNCTION f_top_ten();

CREATE OR REPLACE FUNCTION f_top_ten()
RETURNS TABLE(document json) AS
$$

	SELECT row_to_json(top_ten) FROM (SELECT full_name, email FROM vw_user_satisfaction) as top_ten LIMIT 10 
	
$$ 
LANGUAGE sql;

--SELECT * FROM f_top_ten();



--DROP FUNCTION f_no_orders();

CREATE OR REPLACE FUNCTION f_no_orders()
RETURNS TABLE(document json) AS
$$

	SELECT row_to_json(no_orders) FROM (
	
	SELECT * FROM (
		SELECT COUNT(o."id") as order_count,
		CONCAT (u."last_name", ', ', u."first_name") as full_name, 
		u."email"
		FROM orders o
		FULL OUTER JOIN users u
		ON o."user_id" = u."id"
		GROUP BY full_name, u."email"
	) as zero_group WHERE order_count = 0
	
) as no_orders
 
	
$$ 
LANGUAGE sql;

--SELECT * FROM f_no_orders();


