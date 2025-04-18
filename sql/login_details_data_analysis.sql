select * from users;
select * from logins;

-- Management wants to see all users that did not login in the past 14 months. -- Check video for another solution

select user_id, MAX(login_timestamp) as last_login_timestamp, DATE_ADD(CURDATE(), INTERVAL -14 MONTH) as current_month
from logins
group by user_id
having last_login_timestamp < current_month
;


-- For the business units' quarterly analysis, calculate how many users and how many sessions were at each quarter
 -- order by quarter from newest to oldest.
 -- Return: first day of the quarter, user_cnt, session_cnt.
 
 with cte as (select COUNT(DISTINCT user_id) as users_count, count(*) as session_count ,quarter(Login_timestamp) as quarter_number
 from logins
 group by quarter(Login_timestamp)
 order by quarter_number
 )
select cte.quarter_number, min(LOGIN_TIMESTAMP) as first_day_of_quarter, cte.session_count , cte.users_count
 from logins
 inner join cte
 on cte.quarter_number = quarter(logins.Login_timestamp)
 group by cte.quarter_number
 order by cte.quarter_number;
 
 /* Diff solution for above is below
 select DATETRUNC(quarter, ,MIN(LOGIN_TIMESTAMP) ) as first_quater_date
 COUNT (*) as session_cnt
  COUNT (distinct USER_ID) as user_cnt
from logins
 group by DATEPART(quarter, LOGIN_TIMESTAMP)
 */
 
-- Display user id's that Log-in in January 2024 and did not Log-in on November 2023.
-- Return: User_id
select distinct user_id
from logins
where LOGIN_TIMESTAMP like '2024-01%' 
-- Jan users = 1,2,3,5
-- Nov users = 2,4,6,7
and user_id not in (
select user_id 
from logins
where LOGIN_TIMESTAMP like '2023-11%'
)
;
  
 /* Another solution below 
  select distinct(user_id)
  from logins
  where LOGIN_TIMESTAMP between '2024-01-01' and '2024-01-31'
  and USER_ID not in (select user_id
  from logins
 where LOGIN_TIMESTAMP between '2023-11-01' and '2023-11-30')
 ;*/
 
-- Add the percentage change in sessions from last quarter to query 2 .
-- Return: first day of the quarter, session_cnt, session_cnt_prev, Session_percent_change.
-- Check video as he has diff answer. His quarter date starts from july and mine from Jan. Dont know if he intended that

with cte as (select COUNT(DISTINCT user_id) as users_count, count(*) as session_count ,quarter(Login_timestamp) as quarter_number
 from logins
 group by quarter(Login_timestamp)
 order by quarter_number
 ),
nest_cte as (
select cte.quarter_number, min(LOGIN_TIMESTAMP) as first_day_of_quarter, cte.session_count , cte.users_count
 from logins
 inner join cte
 on cte.quarter_number = quarter(logins.Login_timestamp)
 group by cte.quarter_number
 order by cte.quarter_number)
 select *, lag(session_count, 1) over(order by quarter_number) as prev_session_count, 
 (session_count - (lag(session_count, 1) over(order by quarter_number))) / lag(session_count, 1) over(order by quarter_number)* 100 as session_percent_change 
 from nest_cte
 ;
 
-- Display users that had highest session score for each day
-- Return date, usernme, score
with cte as (select LOGIN_TIMESTAMP, max(SESSION_SCORE) as max_session_score
from logins
group by LOGIN_TIMESTAMP
)
select distinct(c.LOGIN_TIMESTAMP), c.max_session_score, l.USER_ID
from cte c
inner join logins l
on c.LOGIN_TIMESTAMP = l.LOGIN_TIMESTAMP
order by LOGIN_TIMESTAMP;
 
 /* Below is another version but need to verify with my
 with cte as (
 select USER_ID, CAST(LOGIN_TIMESTAMP AS DATE) AS login_date, SUM(session_score) as score
 from logins
 group by USER_ID, CAST(LOGIN_TIMESTAMP AS DATE)
 -- order by CAST(1ogin_timestamp as date), ,score
 )
 select * from (
 select *, ROW_NUMBER() over(partition by login_date order by score desc) as rn
 from cte
 ) a 
 where rn = 1;
*/
 
 
 -- To identify our best users - Return the users that had a session on every single day since their first login
 -- (make assumptions if needed).
 -- Return: User_id
 
 /* Below diff from video as I do not have data that is up to date. I could add rows to see if below works.
SELECT 
  USER_ID, 
  MIN(DATE(LOGIN_TIMESTAMP)) AS first_login,
  DATEDIFF(CURDATE(), MIN(DATE(LOGIN_TIMESTAMP))) + 1 AS no_of_login_days_required,
  COUNT(DISTINCT DATE(LOGIN_TIMESTAMP)) AS no_of_login_days
FROM logins
GROUP BY USER_ID
HAVING no_of_login_days = no_of_login_days_required
ORDER BY USER_ID;*/


-- On what days were there no logins at all?
WITH RECURSIVE cte AS (
    SELECT MIN(DATE(LOGIN_TIMESTAMP)) AS first_date, DATE(CURDATE()) AS last_date
    FROM logins
    UNION ALL
    SELECT DATE_ADD(first_date, INTERVAL 1 DAY), last_date
    FROM cte
    WHERE first_date < last_date
)
SELECT * 
FROM cte
where first_date not in
(select distinct date(login_timestamp) from logins
)
;



                               



