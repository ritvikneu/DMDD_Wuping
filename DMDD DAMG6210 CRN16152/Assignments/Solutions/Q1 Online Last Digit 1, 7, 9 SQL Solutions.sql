
-- Q1 Online Last Digit 1, 7, 9 SQL Solutions

-- Question 3 (3 points)

with temp as (
select CustomerID, count(distinct SalesOrderID) TotalOrder
from Sales.SalesOrderHeader
where TotalDue > 100000
group by CustomerID)
select sh.CustomerID, p.FirstName, p.LastName, cast(sum(TotalDue) as int) TotalPurchase
from Sales.SalesOrderHeader sh
join temp t
on t.CustomerID = sh.CustomerID
join Sales.Customer c
on c.CustomerID = sh.CustomerID
join Person.Person p
on p.BusinessEntityID = c.PersonID
where TotalOrder > 3
group by sh.CustomerID, p.FirstName, p.LastName
order by sh.CustomerID;


-- Question 4 (4 points)

with temp1 as (
select TerritoryID, sum(UnitPrice * OrderQty) Total,
	   rank() over (partition by TerritoryID order by sum(UnitPrice * OrderQty) desc) H
from Sales.SalesOrderHeader sh
join Sales.SalesOrderDetail sd
on sh.SalesOrderID = sd.SalesOrderID
join Production.Product p
on sd.ProductID = p.ProductID
where Color is not null
group by TerritoryID, Color),

temp2 as (
select TerritoryID, sum(UnitPrice * OrderQty) Total,
       rank() over (partition by TerritoryID order by sum(UnitPrice * OrderQty) asc) L
from Sales.SalesOrderHeader sh
join Sales.SalesOrderDetail sd
on sh.SalesOrderID = sd.SalesOrderID
join Production.Product p
on sd.ProductID = p.ProductID
where Color is not null
group by TerritoryID, Color)

select top 1 with ties t1.TerritoryID,
cast((t1.Total - t2.Total) as int) Diff
from temp1 t1
join temp2 t2
on t1.TerritoryID = t2.TerritoryID
where t1.H = 1 and t2.L = 1
order by Diff desc;

