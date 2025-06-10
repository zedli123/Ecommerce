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

-- Calculate total sales for each month
select extract(month from a.created_at) as order_month, sum(a.num_of_item * b.sale_price) as revenue
  from `thelook.orders_2024` as a
    left join `thelook.order_items` as b
      on a.order_id = b.order_id
        group by order_month;

-- Based on the data from 2024, December stands out as the month with the hightest revenue.
-- Let's take a closer look at the revenue on the individual day in December.
select extract(day from a.created_at) as order_day, sum(a.num_of_item * b.sale_price) as revenue
  from `thelook.orders_2024` as a
    left join `thelook.order_items` as b
      on a.order_id = b.order_id
        where extract(month from a.created_at) = 12 
          group by order_day;




