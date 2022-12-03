
-- Q1 Online Last Digit 6, 8 SQL Solutions

-- Question 3 (3 points)

with temp as (
select SalesPersonID, count(distinct SalesOrderID) TotalOrder
from Sales.SalesOrderHeader
where TotalDue > 100000 and SalesPersonID is not null
group by SalesPersonID)
select sh.SalesPersonID, p.FirstName, p.LastName, cast(sum(TotalDue) as int) TotalSales
from Sales.SalesOrderHeader sh
join temp t
on t.SalesPersonID = sh.SalesPersonID
join Person.Person p
on p.BusinessEntityID = sh.SalesPersonID
where TotalOrder > 15 and sh.SalesPersonID is not null
group by sh.SalesPersonID, p.FirstName, p.LastName
order by sh.SalesPersonID;


-- Question 4 (4 points)

with temp1 as (
select year(OrderDate) Year, sum(UnitPrice * OrderQty) Total,
	   rank() over (partition by year(OrderDate) order by sum(UnitPrice * OrderQty) desc) H
from Sales.SalesOrderHeader sh
join Sales.SalesOrderDetail sd
on sh.SalesOrderID = sd.SalesOrderID
join Production.Product p
on sd.ProductID = p.ProductID
where Color is not null
group by year(OrderDate), Color),

temp2 as (
select year(OrderDate) Year, sum(UnitPrice * OrderQty) Total,
       rank() over (partition by year(OrderDate) order by sum(UnitPrice * OrderQty) asc) L
from Sales.SalesOrderHeader sh
join Sales.SalesOrderDetail sd
on sh.SalesOrderID = sd.SalesOrderID
join Production.Product p
on sd.ProductID = p.ProductID
where Color is not null
group by year(OrderDate), Color)

select top 1 with ties t1.Year,
cast((t1.Total - t2.Total) as int) Diff
from temp1 t1
join temp2 t2
on t1.Year = t2.Year
where t1.H = 1 and t2.L = 1
order by Diff desc;


