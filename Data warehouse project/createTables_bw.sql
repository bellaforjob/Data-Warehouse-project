--------------create staging tables-----------------------
--create server by csv files
--create tables invoices
create table invoices(
	invoicesID serial primary key, --set invoicesId as pk
	orderID varchar(64) not null, --add orderid 
	date timestamp,
	mealID varchar(64) not null,
	companyID varchar(64) not null,
	dateOfMeal timestamp,
	partcipants varchar(1000) not null,
	servedMealPrice float not null,
	typeOfMeal varchar(64)
	)
	
	
--create tables orderleads
create table orderLeads(
	orderLeadsID serial primary key, --set invoicesId as pk
	orderID varchar(64) not null, --add orderid 
	companyID varchar(64) not null,
	companyName varchar(64) not null,
	date timestamp,
	orderValue float not null,
	Converted Boolean,
	effctive_timestamp timestamp,
	expire_timestamp timestamp,
	status varchar(64)
	)
	
--create tables sales team
create table salesTeam(
	salesTeamID serial primary key, --set invoicesId as pk
	salesName varchar(64) not null,
	salesID varchar(64) not null,
	companyID varchar(64) not null,
	companyName varchar(64) not null,
	effctive_timestamp timestamp,
	expire_timestamp timestamp,
	status varchar(64)
	)
	
	
--create tables location
create table locations(
	locationsID serial primary key, --set invoicesId as pk
	street varchar(100) not null,
	city varchar(64) not null,
	states varchar(64) not null,
	country varchar(32) not null,
	companyID varchar(64) not null,
	companyName varchar(64) not null,
	street_pre  varchar(100),
	city_pre  varchar(64),
	states_pre varchar(64)
	)

	
----------temp use--------------------
drop table orderLeads;

drop table locations;

drop table salesTeam;

drop table invoices;

select * from orderleads

show datestyle;

--set datestyle to ISO, DMY
set datestyle to 'dd-MM-yyyy'
---------------------------------------


--import data into tables 
copy salesTeam(salesName, salesID, companyName, companyID) 
from '/Users/beiwang/Desktop/archive/SalesTeam.csv' 
delimiter ',' 
csv header;

copy orderLeads(orderLeadsID,orderID, companyID,companyName, date, orderValue, Converted) 
from '/Users/beiwang/Desktop/archive/OrderLeads.csv' 
delimiter ',' 
csv header;


copy invoices(invoicesID, orderID, date, mealID, companyID, dateOfMeal, partcipants, servedMealPrice, typeOfMeal) 
from '/Users/beiwang/Desktop/archive/invoices.csv' 
delimiter ',' 
csv header;

copy locations(street, city, states,country,companyName, companyID) 
from '/Users/beiwang/Desktop/archive/Locations.csv' 
delimiter ',' 
csv header;

--------------create dimention tables-----------------------	
--create meal table	
create table meal(
	mealID varchar(64) primary key,
	typeOfMeal varchar(64),
	servedMealPrice float not null
)

insert into meal (mealID, typeOfMeal, servedMealPrice)	
select i.mealid, i.typeofmeal, i.servedmealprice
from invoices i

select * from meal

select * from invoices 

--create companys
create table company(
	companyID varchar(64) primary key, --set pk
	companyName varchar(64),
	street  varchar(100),
	city  varchar(64),
	states varchar(64)
)

insert into company(companyID, companyName, street,city,states)	
select l.companyid, l.companyname, l.street, l.city, l.states
from locations l

select * from company

--create address
create table address(
	addressID int primary key, --set pk,
	street varchar(100),
	city  varchar(64),
	states varchar(64),
	street_pre  varchar(100),
	city_pre  varchar(64),
	states_pre varchar(64)
)

insert into address(addressID, street, city, states, street_pre, city_pre, states_pre)
select l.locationsid, l.street,l.city, l.states, l.street_pre,l.city_pre, l.states_pre 
from locations l

select * from address

--create state
create table states(
	stateID int primary key, --set pk,
	stateName varchar(100))

insert into states(stateID, stateName)
select a.addressid, a.states 
from address a

select * from states

--create date 
create table dates(
	dateID varchar(16) primary key, --set pk,
	date timestamp,
	date_year varchar(16),
	date_month varchar(16),
	date_day varchar(16)
)

insert into dates(dateID, date, date_year, date_month, date_day)
select i.mealid, i.date, date_part('year',i.date) as years, date_part('month',i.date) as month, date_part('day',i.date) as day
from invoices i

select * from dates

--create year
create table years(
	yearID varchar(64) primary key, --set pk,
	date_year varchar(16))

insert into years(yearID, date_year)
select d.dateid , d.date_year 
from dates d

select * from years


--create month from orderleads table
create table months(
	monthID int primary key, --set pk,
	date_month varchar(16))

insert into months(monthID, date_month)
select o.orderleadsid, date_part('month',o."date" ) as date_month
from orderleads o

select * from months


------------------------------------------------------
drop table months;

drop table company;


drop table order_meal;
--------------------------create fact tables-----------------------
--create fact tables
create table order_meal(
	mealID varchar(64),
	dateID varchar(64),
	companyID varchar(64),
	addressID int,
	stateID int,
	TotalMealByType float default 0,
	TotalOrderMealOfState float default 0,
	constraint order_meal_PK primary key(mealID, dateID, companyID, addressID, stateID),
	foreign key (mealID) references meal(mealid),
	foreign key (dateID) references dates(dateID) not valid,
	foreign key (companyID) references company(companyID),
	foreign key (addressID) references address(addressID) not valid,
	foreign key (stateID) references states(stateID) not valid);

select * from order_meal


--insert value to the table
with t1 as (
	select m.typeofmeal, count(m.mealid) as countByType from meal m group by m.typeofmeal
),
t2 as (
	select distinct s.stateid, sum(m.servedmealprice) as TotalOrderMealOfState 
	from meal m
	join invoices i on i.mealid = m.mealid 
	join locations l on l.companyid = i.companyid 
	join address a on a.addressid = l.locationsid 
	join states s on s.stateid  = a.addressid 
	group by s.stateid 
)	
insert into order_meal(mealID, dateID, companyID, addressID, stateID, TotalMealByType,TotalOrderMealOfState)
select distinct m.mealId, d.dateid, c.companyid, a.addressid, s.stateid, t1.countByType, t2.TotalOrderMealOfState
from meal m
join dates d on d.dateid = m.mealid 
join invoices i on i.mealid = m.mealid 
join company c on c.companyid = i.companyid 
join locations l on l.companyid = c.companyid 
join address a on a.addressid = l.locationsid 
join states s on a.addressid = s.stateid 
join t1 on t1.typeofmeal = m.typeofmeal 
join t2 on t2.stateid = s.stateid 
order by TotalOrderMealOfState DESC

--check the table
select * from order_meal

-------------check meatures-------------------
--select the total order meal each state
select distinct s.statename, sum(o.totalordermealofstate)
from order_meal o
join states s on s.stateid =o.stateid
group by s.statename
order by sum(o.totalordermealofstate) desc


--select the total order meal each type of meal
select distinct m.typeofmeal, o.totalmealbytype
from order_meal o
join meal m on m.mealid = o.mealid
order by o.totalmealbytype desc
---------------------------------------------------

--create fact tables
create table sales_invoices(
	mealID varchar(64),
	companyID varchar(64),
	addressID int,
	salesteamid int,
	yearID varchar(64),
	TotalSalesBySP float,
	constraint sales_invoices_PK primary key(mealID, companyID, addressID, salesteamid, yearID),
	foreign key (mealID) references meal(mealid),
	foreign key (companyID) references company(companyID),
	foreign key (addressID) references address(addressID) not valid,
	foreign key (salesteamid) references salesteam(salesteamid) not valid,
	foreign key (yearID) references years(yearID) not valid);


select * from sales_invoices

--insert values
with st1 as(
	select st.salesteamid, sum(m.servedmealprice) as totalSales
	from salesteam st
	join invoices i on i.companyid = st.companyid 
	join meal m on m.mealid = i.mealid 
	group by st.salesteamid 
)
insert into sales_invoices(mealID, companyID, addressID, salesteamid, yearID, TotalSalesBySP)
select m.mealid, c.companyid, a.addressid, st.salesteamid, y.yearid, st1.totalSales
from meal m
join invoices i on i.mealid = m.mealid 
join salesteam st on st.companyid = i.companyid  
join company c on c.companyid = st.companyid 
join locations l on l.companyid  = i.companyid 
join address a on l.locationsid = a.addressid
join years y on y.yearid = m.mealid 
join st1 on st1.salesteamid = st.salesteamid 
order by st1.totalSales

--check table 
select * from sales_invoices

--pull total sales by sp 
select s.salesname, si.totalsalesbysp
from sales_invoices si
join salesteam s on s.salesteamid  = si.salesteamid
join years y on y.yearid = si.mealid
where y.date_year= '2017'
group by s.salesname, si.totalsalesbysp
order by si.totalsalesbysp desc 
limit 10

----creat fact table
create table order_converted(
	companyID varchar(64),
	orderLeadsID int,
	monthID int,
	addressID int,
	CountCoverted int,
	constraint order_converted_PK primary key(companyID, orderLeadsId, monthID, addressID),
	foreign key (companyID) references company(companyID),
	foreign key (orderLeadsId) references orderLeads(orderLeadsId),
	foreign key (monthID) references months(monthID) not valid,
	foreign key (addressID) references address(addressID) not valid);
	
)

with cc as(
	select o.orderleadsid,count(o.converted) as numOfConverted,date_trunc('month',o."date") as year_month
	from orderleads o 
	where (extract('year' from o."date") = 2018 and extract ('month' from o."date") = 12) and o.converted is true
	group by year_month, orderleadsid
)
insert into order_converted(companyID, orderLeadsId, monthID, addressID, CountCoverted) 
select c.companyid, o2.orderleadsid, mt.monthid, a.addressid, cc.numOfConverted
from company c
join orderleads o2 on o2.companyid = c.companyid  
join locations l on l.companyid  =o2.companyid 
join address a on l.locationsid = a.addressid
join months mt on mt.monthid = o2.orderleadsid 
join cc on cc.orderleadsid = o2.orderleadsid  


select * from order_converted

--get the count
select count(oc.CountCoverted)
from order_converted oc



drop table order_converted;