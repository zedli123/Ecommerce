
-- For this practice, I'll use the Google BigQuery to explore and extract valuable information from ecommerce data.
-- The data collection date is between 2020-11-01 to 2021-01-31.

-- Case 1: Count Unique Events by Date and by Event Name from 2020-12-01 to 2020-12-02.
SELECT
  event_date,
  event_name,
  COUNT(*) AS event_count
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE
  event_name IN ('page_view', 'session_start', 'purchase')
  AND _TABLE_SUFFIX BETWEEN '20201201' AND '20201202'
GROUP BY 1, 2;

-- In this query, we selected the frequency of each event type that occurred on 2020-12-01 to 2020-12-02.
-- As showing on query result, on December 1st, 2020, there were 21511 page view, 4912 session start, and 107 purchases.
-- On December 2nd, 2020, there were 19866 page views, 4759 session starts, and 82 purchases.

--Case 2: User count and new user count.
WITH
  UserInfo AS (
    SELECT
      user_pseudo_id,
      MAX(IF(event_name IN ('first_visit', 'first_open'), 1, 0)) AS is_new_user
    -- Replace table name.
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    -- Replace date range.
    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
    GROUP BY 1
  )
SELECT
  COUNT(*) AS user_count,
  SUM(is_new_user) AS new_user_count
FROM UserInfo;

-- In this query, we selected the total user count, and also the number of users who open the account for the very first time.
-- There are total 79421 users and 71734 new users.  

--Case 3: Average number of transactions per purchases.
SELECT
  ROUND(COUNT(*) / COUNT(DISTINCT user_pseudo_id), 2) AS avg_transaction_per_purchaser
FROM
  -- Replace table name.
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE
  event_name IN ('in_app_purchase', 'purchase')
  -- Replace date range.
  AND _TABLE_SUFFIX BETWEEN '20201201' AND '20201231';

-- 

--Case 4: Values for a specific event name.
SELECT
  event_timestamp,
  (
    SELECT COALESCE(value.int_value, value.float_value, value.double_value)
    FROM UNNEST(event_params)
    WHERE key = 'value'
  ) AS event_value
FROM
  -- Replace table name.
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE
  event_name = 'purchase'
  -- Replace date range.
  AND _TABLE_SUFFIX BETWEEN '20201201' AND '20201202';

--Case 5: Top 10 items added to cart:
SELECT
  item_id,
  item_name,
  COUNT(DISTINCT user_pseudo_id) AS user_count
FROM
  -- Replace table name.
   `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`, UNNEST(items)
WHERE
  -- Replace date range.
  _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  AND event_name IN ('add_to_cart')
GROUP BY
  1, 2
ORDER BY
  user_count DESC
LIMIT 10;

--Case 6: Average number of pageviews by purchaser type（purchasers vs non-purchasers）
WITH
  UserInfo AS (
    SELECT
      user_pseudo_id,
      COUNTIF(event_name = 'page_view') AS page_view_count,
      COUNTIF(event_name IN ('in_app_purchase', 'purchase')) AS purchase_event_count
    -- Replace table name.
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    -- Replace date range.
    WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201202'
    GROUP BY 1
  )
SELECT
  (purchase_event_count > 0) AS purchaser,
  COUNT(*) AS user_count,
  SUM(page_view_count) AS total_page_views,
  SUM(page_view_count) / COUNT(*) AS avg_page_views,
FROM UserInfo
GROUP BY 1;

--Case 7: Sequence of pageviews
SELECT
  user_pseudo_id,
  FORMAT_DATE('%d-%m-%Y', PARSE_DATE('%Y%m%d', event_date)) AS date, 
  FORMAT_TIME('%T', TIME(TIMESTAMP_MICROS(event_timestamp))) time,
  (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location')
    AS page_location,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_title') AS page_title
FROM
  -- Replace table name.
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE
  event_name = 'page_view'
  -- Replace date range.
  AND _TABLE_SUFFIX BETWEEN '20201201' AND '20201202'
ORDER BY
  user_pseudo_id,
  ga_session_id,
  date,
  time ASC;

--Case 8: Event Parameter List
SELECT
  EP.key AS event_param_key,
  COUNT(*) AS occurrences
FROM
  -- Replace table name.
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`, UNNEST(event_params) AS EP
WHERE
  -- Replace date range.
  _TABLE_SUFFIX BETWEEN '20201201' AND '20201202'
GROUP BY
  event_param_key
ORDER BY
  event_param_key ASC;

--Case 9: Product purchased by customers who purchased a certain product
WITH
  Params AS (
    -- Replace with selected item_name or item_id.
    SELECT 'Google Navy Speckled Tee' AS selected_product
  ),
  PurchaseEvents AS (
    SELECT
      user_pseudo_id,
      items
    FROM
      -- Replace table name.
      `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    WHERE
      -- Replace date range.
      _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
      AND event_name = 'purchase'
  ),
  ProductABuyers AS (
    SELECT DISTINCT
      user_pseudo_id
    FROM
      Params,
      PurchaseEvents,
      UNNEST(items) AS items
    WHERE
      -- item.item_id can be used instead of items.item_name.
      items.item_name = selected_product
  )
SELECT
  items.item_name AS item_name,
  SUM(items.quantity) AS item_quantity
FROM
  Params,
  PurchaseEvents,
  UNNEST(items) AS items
WHERE
  user_pseudo_id IN (SELECT user_pseudo_id FROM ProductABuyers)
  -- item.item_id can be used instead of items.item_name
  AND items.item_name != selected_product
GROUP BY 1
ORDER BY item_quantity DESC;

--Case 10: Average amount of money spent per purchase session by user
-- Example: Average amount of money spent per purchase session by user.

SELECT
  user_pseudo_id,
  COUNT(
    DISTINCT(SELECT EP.value.int_value FROM UNNEST(event_params) AS EP WHERE key = 'ga_session_id'))
    AS session_count,
  AVG(
    (
      SELECT COALESCE(EP.value.int_value, EP.value.float_value, EP.value.double_value)
      FROM UNNEST(event_params) AS EP
      WHERE key = 'value'
    )) AS avg_spend_per_session_by_user,
FROM
  -- Replace table name.
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE
  event_name = 'purchase'
  -- Replace date range.
  AND _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY 1;