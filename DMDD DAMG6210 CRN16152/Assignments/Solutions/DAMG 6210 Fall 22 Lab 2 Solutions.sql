
-- Lab 2

-- 2-1

SELECT SalesPersonID, COUNT(SalesPersonID) AS TotalOrders, 
       CAST(MAX(OrderDate) AS DATE) AS MostRecentOrderDate
FROM Sales.SalesOrderHeader
WHERE SalesPersonID IS NOT NULL
GROUP BY SalesPersonID
ORDER BY TotalOrders DESC;

--2-2

select ProductID, Name, ListPrice
from Production.Product
where ListPrice > (select AVG(ListPrice) from Production.Product)+500
order by ListPrice desc;

-- 2-3

select h.TerritoryID, t.name
from Sales.SalesOrderHeader h
join Sales.SalesTerritory t
on h.TerritoryID = t.TerritoryID
group by h.TerritoryID, t.name
having (count(SalesOrderID) / count(distinct CustomerID)) >= 5
order by TerritoryID;

2-4

Select p.ProductID,
       p.Name,
       sum(sod.OrderQty) as 'Total Sold Quantity'
From Production.Product p 
join Sales.SalesOrderDetail sod
on p.ProductID = sod.ProductID
where Color = 'Black'
Group By p.ProductID, p.Name
Having sum(sod.OrderQty) > 3000
Order by sum(sod.OrderQty) desc;

-- 2-5

SELECT cast(OrderDate as date) Date, sum(OrderQty) TotalProductQuantitySold
FROM Sales.SalesOrderHeader so
JOIN Sales.SalesOrderDetail sd
ON so.SalesOrderID = sd.SalesOrderID
WHERE OrderDate NOT IN
(SELECT OrderDate
 FROM Sales.SalesOrderHeader
 WHERE TotalDue >500)
GROUP BY OrderDate
ORDER BY TotalProductQuantitySold desc;

-- 2-6

with temp as
(select sh.SalesOrderID, count(distinct ProductID) up
 from Sales.SalesOrderHeader sh
 join Sales.SalesOrderDetail sd
 on sh.SalesOrderID =  sd.SalesOrderID
 group by sh.SalesOrderID
 having count(distinct ProductID) >= 42)

select year(OrderDate) Year, cast(sum(TotalDue) as int) TotalPurchase
from Sales.SalesOrderHeader
where month(OrderDate) = 1 and datepart(dd, OrderDate) = 1
      and SalesOrderID in (select SalesOrderID from temp)
group by year(OrderDate)
order by Year;

