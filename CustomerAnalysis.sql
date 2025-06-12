/* Customer analysis is a critical component of the business process in e-commerce. To better understand our customers’ behavior, 
we will perform customer segmentation to identify different types of customers, the products they purchase, and their purchasing 
patterns.This segmentation will help us tailor marketing strategies, optimize product offerings, and improve overall customer 
experience. We'll analyze the orders from "2024-01-01" to "2024-12-31" */

-- Select the orders from `2024-01-01` to `2024-12-31` and save as table
-- Create table `thelook.orders_2024` as  
select *
  from `thelookecommerce-462517.thelook.orders`
    where date(created_at)
      between '2024-01-01' and '2024-12-31';

-- Calculate total order for each month in 2024
select extract(month from a.created_at) as order_month, sum(a.num_of_item) as total_order
  from `thelook.orders_2024` as a
    left join `thelook.order_items` as b
      on a.order_id = b.order_id
        group by order_month;

-- Based on the data from 2024, December stands out as the month with the most number of orders.
-- We can see there is an increase in order receives leading up to December.

-- Let's take a closer look at the revenue on the individual day in December.
select extract(day from a.created_at) as order_day, sum(a.num_of_item) as total_order
  from `thelook.orders_2024` as a
    left join `thelook.order_items` as b
      on a.order_id = b.order_id
        where extract(month from a.created_at) = 12 
          group by order_day;

-- Some insights: there are sales spike in 26 December, 2024, the day after the Christmas. Usually, there is the 
-- post-holiday promotion after Christmas. This might be the cause of the huge spike.

-- Calculate the Average daily orders received in 2024
select avg(quantity) as daily_order
  from (
    select extract(day from a.created_at) as day, sum(a.num_of_item) as quantity
      from `thelook.orders_2024` as a 
        left join `thelook.order_items` as b
          on a.order_id = b.order_id
            group by day 
  ) as dailysum;

-- The average daily orders in 2024 is 3299. 
-- Now we would love to take a look at the top 10 popular products in 2024.
select b.product_name, sum(a.num_of_item) as number_of_order
  from `thelook.orders_2024` as a
    left join
      (select b.name as product_name, a.order_id
        from `thelook.order_items` as a
          inner join `thelook.products` as b
            on a.product_id = b.id) as b
              on a.order_id = b.order_id
                group by product_name
                  order by number_of_order desc
                    limit 10;


-- After the sale analysis in 2024, we move on to the customer analysis
-- In this section, we'll find the insights on
-- 1. What is customer retention rate from ecommerce user

  -- Lifetime orders 
  select a.id, a.first_name, a.last_name, sum(b.num_of_item) as lifetime_orders
    from `thelook.users` as a
      right join `thelook.orders` as b
        on a.id = b.user_id
          group by a.id, a.first_name, a.last_name
            order by lifetime_orders desc;


  -- Number of User who only purchased one time on the ecommerce and Users who purchases more than one time
  select (select count(distinct id) from 
    (select a.id, a.first_name, a.last_name, count(a.id) as lifetime_orders
      from `thelook.users` as a
        right join `thelook.orders` as b
          on a.id = b.user_id
              group by a.id, a.first_name, a.last_name) as a
                where lifetime_orders >1 ) as users_more_than_one;

  -- Retention Rate
  select (select count(distinct id) from 
    (select a.id, a.first_name, a.last_name, sum(a.id) as lifetime_orders
      from `thelook.users` as a
        right join `thelook.orders` as b
          on a.id = b.user_id
              group by a.id, a.first_name, a.last_name) as a
                where lifetime_orders >1 ) / (select count(distinct id) from `thelook.users`) * 100 as retention_rate;

  -- Majority of users (around 70000) only purchases one time on the Ecommerce. Meanwhile, there are about 29979 user who purchase more than one time.
  -- The retention rate is about 30%

-- Understanding Interval between purchases for users who purchase more than one time.
select *
  from `thelook.orders` as orders
    where user_id in 
      (select user_id
          from `thelook`.orders
            group by user_id 
              having count(user_id) > 1);
  





