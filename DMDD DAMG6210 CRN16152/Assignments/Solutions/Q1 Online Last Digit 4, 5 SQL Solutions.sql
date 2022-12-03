
-- Q1 Online Last Digit 4, 5 SQL Solutions

-- Question 3 (3 points)

with temp as (
select color, count(distinct sd.SalesOrderID) TotalOrder
from Sales.SalesOrderHeader sh
join Sales.SalesOrderDetail sd
on sh.SalesOrderID = sd.SalesOrderID
join Production.Product p
on p.ProductID = sd.ProductID
where TotalDue > 10000 and Color is not null
group by p.Color)
select p.Color, cast(sum(UnitPrice * OrderQty) as int) TotalSales
from Sales.SalesOrderHeader sh
join Sales.SalesOrderDetail sd
on sh.SalesOrderID = sd.SalesOrderID
join Production.Product p
on p.ProductID = sd.ProductID
join temp t
on t.Color = p.Color
where TotalOrder > 1100 and p.Color is not null
group by p.Color
order by p.Color;


-- Question 4 (4 points)

with temp1 as (
select year(OrderDate) Year, sum(UnitPrice * OrderQty) Total,
	   rank() over (partition by year(OrderDate) order by sum(UnitPrice * OrderQty) desc) H
from Sales.SalesOrderHeader sh
join Sales.SalesOrderDetail sd
on sh.SalesOrderID = sd.SalesOrderID
where TotalDue > 38000
group by year(OrderDate), ProductID),

temp2 as (
select year(OrderDate) Year, sum(UnitPrice * OrderQty) Total,
       rank() over (partition by year(OrderDate) order by sum(UnitPrice * OrderQty) asc) L
from Sales.SalesOrderHeader sh
join Sales.SalesOrderDetail sd
on sh.SalesOrderID = sd.SalesOrderID
where TotalDue > 38000
group by year(OrderDate), ProductID)

select top 1 with ties t1.Year,
cast((t1.Total - t2.Total) as int) Diff
from temp1 t1
join temp2 t2
on t1.Year = t2.Year
where t1.H = 1 and t2.L = 1
order by Diff asc;

