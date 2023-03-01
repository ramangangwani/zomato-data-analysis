
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');


CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');


CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);



CREATE TABLE product1(product_id integer,product_name varchar(50),price integer); 

INSERT INTO product1(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;


--what is the total amount each customer spend on zomato
select userid,sum(price) from product
inner join sales
on product.product_id=sales.product_id
group by userid

--how many days has each customer visited zomato
select userid,count(distinct created_date) from sales
group by userid

--what was the first product puchased by each customer
with cte as 
(
select *,DENSE_RANK() over(partition by userid order by created_date) as rank_1 from sales
)
select * from cte
where rank_1 = 1

--what is the most purchased item on the menu and how many times was it purchased by all customer
select userid,count(product_id) from sales where product_id =
(
select top 1 sales.product_id from sales
inner join product1 
on sales.product_id=product1.product_id
group by sales.product_id
order by count(sales.product_id) desc)
group by userid
--which item was the most popular for each customer
with cte as
(
select  sales.userid,product1.product_name,COUNT(product1.product_id) as count_1,dense_rank() over(partition by userid order by COUNT(product1.product_id) desc) as rank_1  from sales
inner join product1 
on sales.product_id=product1.product_id
group by sales.userid,product1.product_name
)
select * from cte 
where rank_1 =1

--which item was purchased first by the customer after they became a member 
with cte as 
(
select x.userid,gold_signup_date,created_date,product_id,dense_rank() over(partition by x.userid order by created_date) as rank_1 from goldusers_signup as x
inner join sales as y
on x.userid=y.userid
where gold_signup_date < created_date
)
select * from cte 
where rank_1=1

--which item was purchased just before the customer became a member 
with cte as
(
select x.userid,created_date,gold_signup_date,product_id,dense_rank() over(partition by x.userid order by created_date desc) as rank_1 from sales as x
inner join goldusers_signup as y
on x.userid =y.userid
where gold_signup_date > created_date
)
select * from cte
where rank_1 = 1

--what is the total orders and amount spend fro each member before they became a member
select x.userid,count(*),sum(price) from sales as x
inner join goldusers_signup as y
on x.userid=y.userid
inner join product1 as z
on x.product_id=z.product_id
where gold_signup_date>=created_date
group by x.userid

select * from sales

--if  buying each product generates points for eg 5rs - 2 zomato point and each product has 
--differnt purchasing points for eg for p1 5rs =1 zomato point  f
--or p2 10rs = 5 zomato point and p3 5rs =1 zomato point  2 rs =1 zomato point
with cte as
(
select userid, y.product_id as prod_id,sum(price) as tot, case when y.product_id =1 then 5 when y.product_id =2 then 2 when y.product_id = 3 then 5 else 0 end as point from sales as x
inner join product1 as y
on x.product_id = y.product_id
group by userid,y.product_id
)
,pop as
(
select *,(tot/point) as total_points from cte
)
select userid ,(sum(total_points)*2.5) as tot_points from pop
group by userid

--In the first one year after a customer joins the gold program (including their join date) irrespective of what the 
--customer has purchased they earn 5 zomato points for every 
--10 rs spent who earned more 1 or 3 and what was their points earnings in thier first yr?
with cte as
(
select x.userid,created_date,gold_signup_date,x.product_id,product_name,price from sales as x
inner join goldusers_signup as y
on x.userid = y.userid
inner join product1 as z
on x.product_id = z.product_id
where created_date >= gold_signup_date and  created_date <= DATEADD(year,1,gold_signup_date)
)
select *,price*0.5 from cte

-- rank all the transaction of the customer
select *,dense_rank() over(partition by userid order  by created_date) from sales

--rank all the transaction for each member whenever 
--they are a zomato gold member for every non gold memeber mark as na
select *, case when created_date >= gold_signup_date then dense_RANK() over(partition by x.userid order by created_date desc) else 0 end  from sales as x
inner join goldusers_signup as y
on x.userid = y.userid
