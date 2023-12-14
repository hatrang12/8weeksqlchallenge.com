/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
	customer_id
    , sum(price) as total_amount
FROM dannys_diner.sales as sales
LEFT JOIN dannys_diner.menu as menu
ON sales.product_id=menu.product_id
GROUP BY customer_id
order by customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT
	customer_id
    , count(order_date) as total_visited_days
FROM dannys_diner.sales as sales
LEFT JOIN dannys_diner.menu as menu
ON sales.product_id=menu.product_id
GROUP BY customer_id
order by customer_id;

-- 3. What was the first item from the menu purchased by each customer?
with cte_cau_3 as(
      SELECT 
          customer_id
          , rank() over(partition by customer_id order by order_date) as appearance
          , product_name
      FROM dannys_diner.sales as sales
      LEFT JOIN dannys_diner.menu as menu
      ON sales.product_id=menu.product_id
      order by customer_id)
 SELECT customer_id
 		, product_name
 FROM cte_cau_3
 WHERE appearance =1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name
		, count(product_name) as frequency
FROM dannys_diner.sales as sales
LEFT JOIN dannys_diner.menu as menu
ON sales.product_id=menu.product_id
GROUP BY product_name
ORDER BY frequency desc;

-- 5. Which item was the most popular for each customer?
with cte_cau_5_y1 as(
  SELECT customer_id
		, product_name
        , count(product_name) as frequency
  FROM dannys_diner.sales as sales
  LEFT JOIN dannys_diner.menu as menu
  ON sales.product_id=menu.product_id
  GROUP BY customer_id, product_name
  ORDER BY frequency desc)
, cte_cau_5_y2 as(
  SELECT customer_id
          , product_name
          , rank() over(partition by customer_id order by frequency desc) as rank_popular
  FROM cte_cau_5_y1)

SELECT customer_id
		, product_name as popular_item
FROM cte_cau_5_y2
where rank_popular=1;

-- 6. Which item was purchased first by the customer after they became a member?
with cte_cau6_y1 as(
    SELECT sales.customer_id
          , order_date
          , join_date
          , join_date-order_date as gap
  		  , product_name
    FROM dannys_diner.sales as sales
    LEFT JOIN dannys_diner.menu as menu
    ON sales.product_id=menu.product_id
    LEFT JOIN dannys_diner.members as members
    ON sales.customer_id=members.customer_id)

, cte_cau6_y2 as(
  SELECT customer_id
		, product_name
        , gap
        , rank() over(partition by customer_id order by gap desc) as recent_order_membership
	FROM cte_cau6_y1
	where gap<=0)
    
SELECT customer_id
		, product_name
FROM cte_cau6_y2
where recent_order_membership=1;

-- 7. Which item was purchased just before the customer became a member?
----tìm ra gap của cột join_date và order_date
with cte_cau7_y1 as(
    SELECT sales.customer_id
          , order_date
          , join_date
          , join_date-order_date as gap
  		  , product_name
    FROM dannys_diner.sales as sales
    LEFT JOIN dannys_diner.menu as menu
    ON sales.product_id=menu.product_id
    LEFT JOIN dannys_diner.members as members
    ON sales.customer_id=members.customer_id)
----chọn các hiệu số của gap >0 chính là khi chưa là member
, cte_cau7_y2 as(
  SELECT customer_id
		, product_name
        , gap
        , rank() over(partition by customer_id order by gap) as before_membership
	FROM cte_cau7_y1
	where gap>0)

---ta dùng hàm rank để chọn ra thời điểm ngay trước khi là member, khi có hiệu số gần 0 nhất tương đương với có rank before_membership=1; do C vẫn chưa là member nên ta lấy thời điểm sp order lần cuối cùng và union với A và B
SELECT customer_id
		, product_name
FROM cte_cau7_y2
where before_membership=1

union

SELECT customer_id, product_name 
FROM (
       SELECT customer_id
              , product_name
       FROM (SELECT 
                customer_id
                , rank() over(partition by customer_id order by order_date desc) as appearance
                , product_name
            FROM dannys_diner.sales as sales
            LEFT JOIN dannys_diner.menu as menu
            ON sales.product_id=menu.product_id
            order by customer_id) cte_cau3_y1
       WHERE appearance =1) as cte_cau3_y2
WHERE customer_id='C'

order by customer_id;

-- 8. What is the total items and amount spent for each member before they became a member?

----chọn các trường để tạo bảng bao gồm các dữ liệu trước khi là member (A,B với gap>0 + all C)

with cte_cau8 as(SELECT customer_id
		, product_name
        , price
        , gap
	FROM (SELECT sales.customer_id
          , order_date
          , join_date
          , join_date-order_date as gap
  		  , product_name
          , price
    FROM dannys_diner.sales as sales
    LEFT JOIN dannys_diner.menu as menu
    ON sales.product_id=menu.product_id
    LEFT JOIN dannys_diner.members as members
    ON sales.customer_id=members.customer_id) as cte
where gap>0

union

SELECT customer_id
      , product_name
      , price
      , NULL as gap
FROM (SELECT 
       customer_id
       , product_name
       , price
      FROM dannys_diner.sales as sales
      LEFT JOIN dannys_diner.menu as menu
      ON sales.product_id=menu.product_id
      order by customer_id) as cte2)
      
----tính total items, amount spent theo customer
select customer_id
		, count(product_name) as total_items
        , sum(price) as total_amount
from cte_cau8
group by customer_id
order by customer_id;
    
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

----chọn các trường bao gồm customer_id, product_id và số tiền tương ứng
with cte_cau9_y1 as(
      SELECT customer_id
              , product_name
              , sum(price) as total_amount
      FROM dannys_diner.sales as sales
      LEFT JOIN dannys_diner.menu as menu
      ON sales.product_id=menu.product_id
      GROUP BY customer_id, product_name
      order by customer_id, product_name)

----dùng case when để tính số điểm tương ứng
, cte_cau9_y2 as(
      SELECT *
              , (CASE WHEN product_name='sushi' THEN total_amount*20
                  ELSE total_amount*10 END) as total_point
      FROM cte_cau9_y1)

----dùng hàm group by để tính số điểm tương ứng mỗi customer
SELECT customer_id
		, sum(total_point) as total_points
FROM cte_cau9_y2
GROUP BY customer_id
ORDER BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

----> do thời gian chỉ sau khi làm member 1 tuần, ta chia làm 2 giai đoạn tính điểm trước và sau khi là member như sau:
	SELECT customer_id, sum(point) as total_point
    FROM
    (SELECT customer_id
		, product_name
        , price
        , gap
        , (CASE WHEN product_name='sushi' THEN price*20
                WHEN gap<=0 THEN price*20  
           		ELSE price*10 END) as point
     	, month
	FROM (SELECT sales.customer_id
          , order_date
          , join_date
          , join_date-order_date as gap
  		  , product_name
          , price
          , extract(month from order_date) as month
    FROM dannys_diner.sales as sales
    LEFT JOIN dannys_diner.menu as menu
    ON sales.product_id=menu.product_id
    LEFT JOIN dannys_diner.members as members
    ON sales.customer_id=members.customer_id) as cte) as cte2
	where month=1
    group by customer_id
    order by customer_id;







