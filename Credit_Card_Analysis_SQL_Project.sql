select * from Credit_card_transactions;

--Q1: write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends.

--Solution-01

select top 5 city, sum(amount) as total_spend,
sum(amount)*100/(select SUM(amount) as total_amount from Credit_card_transactions) as percentage_contribution
from Credit_card_transactions
group by city
order by percentage_contribution desc;

--Solution-02

select SUM(amount) as total_amount from Credit_card_transactions;

with cte1 as
(
select city, SUM(amount) as total_spend
from Credit_card_transactions
GROUP by city )
, total as (select SUM(amount) as total_amount from Credit_card_transactions)
select top 5 city, total_spend, total_amount, total_spend*100/total_amount as percentage_contribution
from cte1, total
order by total_spend desc;

--Q2: write a query to print highest spend month and amount spent in that month for each card type.

select * from Credit_card_transactions;

--solution-01

with cte as
(
select card_type, DATEPART(month, Date) as month_of_date, DATEPART(year, Date) as year_of_date,
ROW_NUMBER() over (partition by card_type order by SUM(amount) desc) as rn,
SUM(amount) as total_spend
from Credit_card_transactions
group by card_type, DATEPART(month, Date), DATEPART(year, Date) )
select * from cte 
where rn = 1;

--solution-02

with cte as
(
select card_type, DATEPART(month, Date) as month_of_date, DATEPART(year, Date) as year_of_date, SUM(amount) as total_spend
from Credit_card_transactions
group by card_type, DATEPART(month, Date), DATEPART(year, Date))
select * from (select *, rank() over (partition by card_type order by total_spend desc) as rn from cte) a
where rn=1;

--Q3: write a query to print the transaction details (all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends (We should have 4 rows in the o/p one for each card type).

select * from Credit_card_transactions;

with cte as
(
select * from (
select *,
SUM(amount) over (partition by card_type order by amount) as running_sum
--rank() over (partition by card_type order by amount) as rn
from Credit_card_transactions) a
--where running_sum>=1000000
)
select * from (select *, RANK() over (PARTITION by card_type order by running_sum) as rnn
from cte where running_sum>=1000000) a where rnn=1;

--solution-02

with cte as
(
select *, SUM(amount) over (partition by card_type order by amount) as total_spend
from Credit_card_transactions)

select * from (select *, ROW_NUMBER() over (PARTITION by card_type order by total_spend) as rn
from cte where total_spend>=1000000) a
where rn=1;

--Q4: write a query to find city which had lowest percentage spend for gold card type

select * from Credit_card_transactions;

with cte as
(
select City, Card_Type, SUM(amount) as amount,
sum(case when Card_Type='gold' then amount end) as gold_amount
from Credit_card_transactions
group by City, Card_Type
--order by City, Card_Type
)

select top 1 city, SUM(gold_amount)*1.0/SUM(amount) as gold_ratio
from cte
group by city
having sum(gold_amount) is not null
order by gold_ratio;

--Q5: write a query to print 3 columns: city, highest_expense_type, lowest_expense_type (example format: Delhi, bills, Fuel)

select * from Credit_card_transactions;

select distinct exp_type from Credit_card_transactions;

--Solution-01

with cte as
(
select city
, (case when rn_asc=1 then exp_type end) as min_city
, (case when rn_desc=1 then exp_type end) max_city
from
(
select city, exp_type, SUM(amount) as total_spend
,rank() over (partition by city order by SUM(amount)) as rn_asc
,rank() over (partition by city order by SUM(amount) desc) as rn_desc
from Credit_card_transactions
group by city, exp_type) A)
select City, MAX(min_city) as lowest_expense_type, MAX(max_city) as highest_expense_type
from cte 
group by City;

--Solution-02

select * from Credit_card_transactions;

with cte as
(
select city, exp_type, SUM(amount) as total_spend
from Credit_card_transactions
group by city, exp_type)
select city
, max(case when rn_asc=1 then exp_type end) as lowest_expense_type
, min(case when rn_desc=1 then exp_type end) as highest_expense_type
from
(
select *,
RANK() over (partition by city order by total_spend asc) as rn_asc
, RANK() over (partition by city order by total_spend desc) as rn_desc
from cte) b
group by city;

--Q6: write a query to find percentage contribution of spends by females for each expense type.

--Solution-01

with cte as
(
select exp_type, SUM(amount) as total_spend
from (
select * from Credit_card_transactions
where Gender='f') a
group by exp_type
)
select exp_type, total_spend*100/(select SUM(amount) from Credit_card_transactions) as percentage_female_contribution
from cte;

--Solution-02

select * from Credit_card_transactions;

select exp_type, SUM(case when gender='f' then amount end)*100/SUM(amount) as percent_female_contribution
from Credit_card_transactions
group by exp_type
order by exp_type;

--Q7: which card and expense type combination saw highest month over month growth in Jan-2014.

--Solution-01

select * from Credit_card_transactions;

with cte as
(
select card_type, exp_type, DATEPART(month,transaction_date) as monthh,DATEPART(year, transaction_date) as yearr,
SUM(amount) as total_spend
from Credit_card_transactions
group by card_type, exp_type, DATEPART(month,transaction_date),DATEPART(year, transaction_date))

select top 1*, (total_spend-previous_spend)*100/previous_spend as percentage_increase
from
(
select *, lag(total_spend) over (partition by card_type, exp_type order by yearr, monthh) as previous_spend
from cte) a
where previous_spend is not null and yearr=2014 and monthh=1
order by percentage_increase desc;

--Q8: during weekends which city has highest total spend to total no of transcations ratio?

--Solution-01

select * from Credit_card_transactions;

with cte as
(
select city, count(Transaction_id) as count_of_Transaction_id, SUM(amount) as total_spend from
(
select *, DATEname(WEEKDAY , transaction_date) as weekdayy
from Credit_card_transactions
where DATEname(WEEKDAY , transaction_date)='Saturday' or DATEname(WEEKDAY , transaction_date)='Sunday') a
group by city)

select top 1*, total_spend/count_of_Transaction_id as ratio
from cte
order by ratio desc;

--Solution-02 

select top 1 city, SUM(amount)*1.0/count(1) as ratio
from Credit_card_transactions
where DATEPART(weekday,transaction_date) in (1,7)
--where DATEname(weekday,transaction_date) in ('saturday','sunday')
group by city
order by ratio desc;

--Q9: which city took least number of days to reach its 500th transaction after the first transaction in that city

select * from Credit_card_transactions;

with cte as (
select *, ROW_NUMBER() over (partition by city order by transaction_date, transaction_id) as rn
from Credit_card_transactions)
select top 1 city, datediff(day,min(transaction_date), max(transaction_date)) as time_taken
from cte
where rn=1 or rn=500 
group by city
having count(1)>1
order by time_taken;







