--maintainess stored proceduce for type 2 SCD tables if add a new sales runs old company
create or replace procedure sp_saleManagement(
	sales in varchar(64), 
	sales_id in varchar(64),
	company_id in varchar(64),
	company in varchar(64),
	isCompanyLeft boolean   --if company left
)
language plpgsql
as
$sales$ 
 begin  --manage the history if sales changed
	 if exists(select expire_timestamp, status  --check if the company exist
			from salesteam
			where companyid = company_id)then 
			update salesteam    --update the record with effctive/expire timestamp and set status is old
			set effctive_timestamp= '2014-01-01 00:00:00.000', expire_timestamp = current_date, status= 'old';
	end if;	 --end if loop
 	if(isCompanyLeft = FALSE)then  --if company do not left, add new record with status 'current'
 		insert into salesteam(salesname, salesid, companyid, companyname, effctive_timestamp, expire_timestamp, status)
		values(sales, sales_id, company_id, company, current_date, '9999-12-31 00:00:00.000','current');
	end if;
 end; 
$sales$


--call stored proceduce when changed the sales man for the company
call sp_saleManagement('Louis Vitton','20230220xxxx','KGJBNJQHPF0WZ6SI','Dandy Fist', FALSE);
 
--call stored proceduce when changed the sales man for the company
call sp_saleManagement('Temple','TEMPID','GZXOG3NKG0YH1W0D','Funniest Enfield', TRUE);
 
--check table
select * from salesteam where companyname ='Dandy Fist' 

select * from salesteam s where s.companyid = 'GZXOG3NKG0YH1W0D'

--maintainess type 3 SCD tables if add new sales runs old company
create or replace procedure sp_addressManagement(
	st_in in varchar(100),
	city_in in varchar(64),
	states_in in varchar(64),
	company_id varchar(64),
	company_Name varchar(64)
)
language plpgsql
as
$location$
begin 
	--manage the address if changed
	if exists (select from locations where companyid = company_id) then  --if record exist
			update locations  
			set street = st_in, city = city_in, states =states_in, street_pre = street, city_pre = city, states_pre = states
			where companyid = company_id;
	else --if cannot find the address
		insert into locations(street, city, states, country, companyid, companyname, street_pre, city_pre, states_pre)
		values(st_in, city_in, states_in,'US', company_id, company_Name, null,null,null);
	end if;	 --end if loop
end; 
$location$

--insert the new address with call
call sp_addressManagement('LJKS5NK6788CYMUU', '3333 high st', 'Lexington', 'MA');

--insert the new address with call
call sp_addressManagement('233 Bay State Road', 'Boston', 'MA', 'lllll','BU');


select * from locations order by locationsid desc limit 1

--drop sp
drop procedure sp_addressManagement


