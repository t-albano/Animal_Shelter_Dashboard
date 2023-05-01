CREATE DATABASE sql_Animal_Shelter;

-- access desired database
USE sql_Animal_Shelter;

-- ------------------------------------------- Create table --------------------------------------------------------------------------
-- create table to store csv data
-- not all dates are valid, so will need to clean them later and adjust data types
CREATE TABLE  animal_shelter ( ID TEXT, ANIMAL TEXT,
	BREED TEXT, KENNEL TEXT, KEN_STATUS TEXT, INTAKE TEXT, 
	IN_SUBTYPE TEXT, REASON TEXT, IN_DATE TEXT, IN_CONDITION TEXT,
	OUTCOME TEXT, OUT_DATE TEXT);

-- load data into table
-- much faster approach. Requires to set secure-file-priv="" and to reset MySQL service
LOAD DATA INFILE '\Dallas_Animal_Shelter_Data_Fiscal_Year_2022_-_2023.txt'
	INTO TABLE animal_shelter
    FIELDS TERMINATED BY '\t'
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES;

LOAD DATA INFILE '\Dallas_Animal_Shelter_Data_Fiscal_Year_2021_-_2022.txt'
	INTO TABLE animal_shelter
    FIELDS TERMINATED BY '\t'
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES;

LOAD DATA INFILE '\Dallas_Animal_Shelter_Data_Fiscal_Year_2020_-_2021.txt'
	INTO TABLE animal_shelter
    FIELDS TERMINATED BY '\t'
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES;

LOAD DATA INFILE '\Dallas_Animal_Shelter_Data_Fiscal_Year_2019_-_2020.txt'
	INTO TABLE animal_shelter
    FIELDS TERMINATED BY '\t'
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES;

LOAD DATA INFILE '\Dallas_Animal_Shelter_Data_Fiscal_Year_2018_-_2019.txt'
	INTO TABLE animal_shelter
    FIELDS TERMINATED BY '\t'
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES;

-- -------------------------------------------Data cleaning --------------------------------------------------------------------------

-- Explore and clean data.

-- INTAKE. Try to reduce to general categories. Focus on animals new to the system
set sql_safe_updates = 0;
delete from animal_shelter
where INTAKE not in ('STRAY', 'OWNER SURRENDER', 'CONFISCATED', 'FOSTER', 'TRANSFER');
set sql_safe_updates = 1;

-- OUTCOMES. Try to reduce general categories. Focus on where animals were sent. 
set sql_safe_updates = 0;
delete from animal_shelter
where OUTCOME not in ('FOSTER', 'EUTHANIZED', 'ADOPTION', 'RETURNED TO OWNER', 'TRANSFER');
set sql_safe_updates = 1;

-- ANIMAL. Focus on cats and dogs.
set sql_safe_updates = 0;
delete from animal_shelter
where ANIMAL not in ('CAT', 'DOG');
set sql_safe_updates = 1;

-- clean formatting of dates and convert to date type
set sql_safe_updates = 0;
update animal_shelter
set IN_DATE = str_to_date(IN_DATE, '%m/%d/%Y');
set sql_safe_updates = 1;

-- found invalid dates - blanks and 1/1/2000
select OUT_DATE
from animal_shelter
order by 1;

set sql_safe_updates = 0;
delete from animal_shelter
where OUT_DATE < '1/1/2019';
set sql_safe_updates = 1;

set sql_safe_updates = 0;
update animal_shelter
set OUT_DATE = str_to_date(OUT_DATE, '%m/%d/%Y');
set sql_safe_updates = 1;

-- now strings are in correct format. Convert to date datatype.
set sql_safe_updates = 0;
alter table animal_shelter modify IN_DATE date;
alter table animal_shelter modify OUT_DATE date;
set sql_safe_updates = 1;

-- add month and year columns for simpler grouping later on
-- add column for number of days in shelter for survival analysis
set sql_safe_updates = 0;
alter table animal_shelter
add in_month INT,
add in_year INT,
add out_month INT, 
add out_year INT,
add days_in INT;
set sql_safe_updates = 1;

set sql_safe_updates = 0;
update animal_shelter 
set in_month = extract(MONTH FROM IN_DATE),
in_year = extract(YEAR FROM IN_DATE),
out_month = extract(MONTH FROM OUT_DATE),
out_year = extract(YEAR FROM OUT_DATE),
days_in = datediff(OUT_DATE, IN_DATE);
set sql_safe_updates = 1;

-- check that there are no weird cutoffs from in to out months
-- December arrivals were still cataloged correctly, even though the years were different
select distinct in_month, out_month
from animal_shelter
order by 1, 2;

----------------------------------------------- Data Exploration -------------------------------------------------------------------

-- explore survival analysis
-- works, consider segmenting by year and outcome type for visualization
create table animal_survival as
with tiers as (select ANIMAL, out_year, days_in, count(*) as rel_total
	from animal_shelter
	group by ANIMAL, out_year, days_in),
animal_total as (select ANIMAL, out_year, count(*) as total
	from animal_shelter 
	group by ANIMAL, out_year),
survival as(select t.ANIMAL, t.out_year, t.days_in, sum(g.rel_total) as surv_total
	from tiers t
	inner join tiers g using(ANIMAL, out_year)
	where t.days_in <= g.days_in
	group by t.ANIMAL, t.out_year, t.days_in
	order by 1, 2)
select ANIMAL, out_year, days_in, surv_total, surv_total/total as surv_rate
from survival
left join animal_total using(ANIMAL, out_year)
order by 1, 2;

-- explore residual over time for OUTCOME
-- works, but consider adjusting 2023 and 2018 as part of this when visualizing since data doesn't reflect their full years
-- adjust based on average difference on a monthly basis, 
-- or scale the values since a full year has not occured yet
with av as (select OUTCOME, avg(out_amt) as avg_out
	from (select OUTCOME, out_year, count(*) as out_amt
		from animal_shelter
        group by OUTCOME, out_year) t
    group by OUTCOME),
ct as ( select OUTCOME, out_year, count(*) as y_amt
	from animal_shelter
	left join av using(OUTCOME)
	group by OUTCOME, out_year)
select OUTCOME, out_year, y_amt, avg_out, y_amt - avg_out as resid
from ct
left join av using(OUTCOME)
order by 1, 2;

-- explore stacked bar graph data for INTAKE
-- works. From values, the proportions are supprisingly not too different, despite crazy increase in inputs over years
create table animal_proportion_intake as
with tot as (select ANIMAL, in_year, count(*) as amt
	from animal_shelter
    group by ANIMAL, in_year),
sub as ( select ANIMAL, INTAKE, in_year, count(*) as sub_amt
	from animal_shelter
    group by ANIMAL, in_year, INTAKE)
select ANIMAL, INTAKE, in_year, sub_amt/amt as proportion
from sub
left join tot using(ANIMAL, in_year)
order by 1, 3, 2;

-- explore stacked bar graph data for OUTTAKE
-- works. From values, the proportions are supprisingly not too different, despite crazy increase in inputs over years
create table animal_proportion_outtake as
with tot as (select ANIMAL, out_year, count(*) as amt
	from animal_shelter
    group by ANIMAL, out_year),
sub as ( select ANIMAL, OUTCOME, out_year, count(*) as sub_amt
	from animal_shelter
    group by ANIMAL, out_year, OUTCOME)
select ANIMAL, OUTCOME, out_year, sub_amt/amt as proportion
from sub
left join tot using(ANIMAL, out_year)
order by 1, 3, 2;

-- explore time graph
-- consideration: Should I wrangle the noise using some aggregations or smoothing the curve?
-- Note that many holidays do not fall on the same day of the week/same day of the year
with d as (select INTAKE, in_year, IN_DATE, weekofyear(IN_DATE) as in_week
	from animal_shelter)
select INTAKE, in_year, in_week, count(*) as totals
from animal_shelter
left join d using(INTAKE, in_year, IN_DATE)
group by INTAKE, in_year, in_week
order by 1, 2, 3;

-- explore intake outtake difference
-- consider omitting all dates leading up to when reopened for covid for forecasting 
-- Could be result of not having roll over data from previous months. 
create table animal_differences as
with in_amt as (select ANIMAL, in_month, in_year, count(*) as an_in
	from animal_shelter
    group by ANIMAL, in_month, in_year),
out_amt as (select ANIMAL, out_month, out_year, count(*) as an_out
	from animal_shelter
    group by ANIMAL, out_month, out_year)
select o.ANIMAL, in_month as `month`, in_year as `year`, an_in - an_out as diff
from in_amt i
left join out_amt o on o.ANIMAL = i.ANIMAL and o.out_month = i.in_month and o.out_year = i.in_year
where (o.out_month >= 6 and o.out_year >=2020) or (o.out_year >=2021)
order by 2, 1;