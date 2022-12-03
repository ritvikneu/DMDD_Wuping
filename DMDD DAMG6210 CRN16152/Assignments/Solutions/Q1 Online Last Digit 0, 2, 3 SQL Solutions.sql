
-- Q1 Online Last Digit 0, 2, 3 SQL Solutions

-- Question 3 (3 points)

with temp as (
select ProductID, count(distinct sd.SalesOrderID) TotalOrder
from Sales.SalesOrderHeader sh
join Sales.SalesOrderDetail sd
on sh.SalesOrderID = sd.SalesOrderID
where TotalDue > 10000
group by sd.ProductID)
select sd.ProductID, cast(sum(UnitPrice * OrderQty) as int) TotalSales
from Sales.SalesOrderHeader sh
join Sales.SalesOrderDetail sd
on sh.SalesOrderID = sd.SalesOrderID
join temp t
on t.ProductID = sd.ProductID
where TotalOrder > 880
group by sd.ProductID
order by ProductID;


-- Question 4 (4 points)

with temp1 as (
select TerritoryID, sum(UnitPrice * OrderQty) Total,
	   rank() over (partition by TerritoryID order by sum(UnitPrice * OrderQty) desc) H
from Sales.SalesOrderHeader sh
join Sales.SalesOrderDetail sd
on sh.SalesOrderID = sd.SalesOrderID
where TotalDue > 50000
group by TerritoryID, ProductID),

temp2 as (
select TerritoryID, sum(UnitPrice * OrderQty) Total,
       rank() over (partition by TerritoryID order by sum(UnitPrice * OrderQty) asc) L
from Sales.SalesOrderHeader sh
join Sales.SalesOrderDetail sd
on sh.SalesOrderID = sd.SalesOrderID
where TotalDue > 50000
group by TerritoryID, ProductID)

select top 1 with ties t1.TerritoryID,
cast((t1.Total - t2.Total) as int) Diff
from temp1 t1
join temp2 t2
on t1.TerritoryID = t2.TerritoryID
where t1.H = 1 and t2.L = 1
order by Diff asc;


