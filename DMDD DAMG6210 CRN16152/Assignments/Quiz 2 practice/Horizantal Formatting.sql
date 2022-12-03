use AdventureWorks2008R2;

-- Exercise Question 1
/*
Using an AdventureWorks database, write a query to
retrieve the top 3 products for the customer id's between 30000 and 30005.
The top 3 products have the 3 highest total sold quantities.
The quantity sold for a product included in an order is in SalesOrderDetail.
Use the quantity sold to calculate the total sold quantity. If there is
a tie, your solution must retrieve the tie.
Return the data in the following format.
CustomerID Top3Products
30000 869, 809, 779
30001 813, 794
30002 998, 736, 875, 835, 836
30003 863, 771, 783
30004 709, 778, 776, 777
30005 966, 972, 954, 948, 965
*/
use adv
-- Exercise Question 1 Solution
WITH Temp AS
   (select CustomerID, ProductID, sum(OrderQty) ttl,
    rank() over (partition by CustomerID order by sum(OrderQty) desc) as TopProduct
    from Sales.SalesOrderHeader sh
join Sales.SalesOrderDetail sd
on sh.SalesOrderID = sd.SalesOrderID
where CustomerID between 30000 and 30005
    group by CustomerID, ProductID)
select t1.CustomerID,
STUFF (
      (SELECT  ', '+RTRIM(CAST(ProductID as char))  
       FROM temp 
       WHERE CustomerID = t1.CustomerID and TopProduct <=3
       FOR XML PATH('')
	   ) , 1, 2, '') AS Top3Products
from temp t1
where t1.TopProduct <= 3
group by t1.CustomerID;

-- Exercise Question 2
/*
Using an AdventureWorks database, write a query to
retrieve the top 3 orders for each salesperson.
The top 3 orders have the 3 highest TotalDue values. TotalDue 
is in SalesOrderHeader. If there is a tie, your solution 
must retrieve the tie.
Return the data in the following format. The name is 
a salesperson's name.
SalesPersonID FullName Top3Orders
274 Jiang, Stephen 51830, 57136, 53465
275 Blythe, Michael 47395, 53621, 50289
276 Mitchell, Linda 47355, 51822, 57186
277 Carson, Jillian 46660, 43884, 44528
278 Vargas, Garrett 44534, 43890, 58932
279 Reiter, Tsvi 44518, 43875, 47455
280 Ansman-Wolfe, Pamela 47033, 67297, 53518
281 Ito, Shu 51131, 55282, 47369
282 Saraiva, Jos�53573, 47451, 51823
283 Campbell, David 46643, 51711, 51123
284 Mensa-Annan, Tete 69508, 50297, 48057
285 Abbas, Syed 53485, 53502, 58915
286 Tsoflias, Lynn 53566, 51814, 71805
287 Alberts, Amy 59064, 58908, 51837
288 Valdez, Rachel 55254, 51761, 69454
289 Pak, Jae 46616, 46607, 46645
290 Varkey Chudukatil, Ranjit 46981, 51858, 57150
*/
-- Exercise Question 2 Solution
WITH Temp AS
(select SalesPersonID, SalesOrderID, TotalDue,
 rank() over (partition by SalesPersonID order by TotalDue desc) as TopOrder
 from Sales.SalesOrderHeader
 where SalesPersonID is not null)
select p.BusinessEntityID as 'SalesPersonID', p.Lastname+ ', ' + p.FirstName as 
'FullName',
STUFF((SELECT  ', '+RTRIM(CAST(SalesOrderID as char))  
       FROM temp 
       WHERE SalesPersonID = p.BusinessEntityID and TopOrder <=3
       FOR XML PATH('')) , 1, 2, '') AS Top3Orders
from Person.Person p
where p.BusinessEntityID in 
(select distinct SalesPersonID from Sales.SalesOrderHeader where SalesPersonID is 
not null)
order by SalesPersonID;

-------------------------------------------------------------------------------------------------------------
-- Horizontal format (Short list) using SELECT TOP 1 WITH TIES and FOR XML PATH
SELECT distinct TERRITORYID,
       STUFF(
   (SELECT TOP 1 WITH TIES ', ' + CAST(a.CustomerID AS CHAR(5))
    FROM Sales.SalesOrderHeader a
WHERE a.TERRITORYID = b.TERRITORYID
    GROUP BY TERRITORYID, CustomerID
ORDER BY  COUNT(SalesOrderID) DESC --a.totaldue desc
FOR XML PATH('')
   ), 1, 2, '') OrderCount
FROM Sales.SalesOrderHeader b
ORDER BY TERRITORYID;

-- Horizontal format (Short list) using RANK and FOR XML PATH
WITH temp AS
(SELECT TERRITORYID, CustomerID,
 RANK() OVER (PARTITION BY TERRITORYID  ORDER BY COUNT(SalesOrderID) DESC) AS 
CustomerRank 
 FROM Sales.SalesOrderHeader
 GROUP BY TERRITORYID, CustomerID)
SELECT DISTINCT TERRITORYID, 
        STUFF((SELECT ', ' + CAST(CustomerID AS CHAR(5)) 
    FROM temp 
WHERE TERRITORYID = t1.TERRITORYID AND CustomerRank = 1 
ORDER BY CustomerID
FOR XML PATH('')), 1,2,'') TopCustomers
FROM temp t1;
 
--SELECT TOP 1 WITH TIES in a function and CROSS APPLY
go
create function dbo.ufGetTerritoryTopCustomer
     (@tid int)
  returns table as
    return
         SELECT TOP 1 WITH TIES TERRITORYID, CustomerID
      FROM Sales.SalesOrderHeader
  WHERE TERRITORYID = @tid
     GROUP BY TERRITORYID, CustomerID
 ORDER BY  COUNT(SalesOrderID) DESC;
 go

SELECT distinct s.TERRITORYID, u.CustomerID
FROM Sales.SalesOrderHeader s
CROSS APPLY dbo.ufGetTerritoryTopCustomer(TERRITORYID) u
ORDER BY s.TERRITORYID;

-- Horizontal Format (Short List)
with temp as (
SELECT distinct s.TERRITORYID, u.CustomerID
FROM Sales.SalesOrderHeader s
CROSS APPLY dbo.ufGetTerritoryTopCustomer(TERRITORYID) u)
SELECT DISTINCT TERRITORYID, 
        STUFF((SELECT ', ' + CAST(CustomerID AS CHAR(5)) 
    FROM temp t2
WHERE t2.TERRITORYID = t1.TERRITORYID
ORDER BY CustomerID
FOR XML PATH('')), 1,2,'')
FROM temp t1;

-- Use SELECT TOP 1 WITH TIES in a derived table and CROSS APPLY
with temp as (
SELECT distinct s.TERRITORYID, u.CustomerID
FROM Sales.SalesOrderHeader s
CROSS APPLY
(       SELECT TOP 1 WITH TIES TERRITORYID, CustomerID
    FROM Sales.SalesOrderHeader
WHERE TERRITORYID = s.TERRITORYID
    GROUP BY TERRITORYID, CustomerID
ORDER BY  COUNT(SalesOrderID) DESC) u
)
SELECT DISTINCT TERRITORYID, 
        STUFF((SELECT ', ' + CAST(CustomerID AS CHAR(5)) 
    FROM temp t2
WHERE t2.TERRITORYID = t1.TERRITORYID
ORDER BY CustomerID
FOR XML PATH('')), 1,2,'')
FROM temp t1;


-- RANK works well with PARTITION BY 
SELECT TERRITORYID, CustomerID FROM
(SELECT TERRITORYID, CustomerID, COUNT(SalesOrderID) TotalOrder,
 RANK() OVER (PARTITION BY TERRITORYID  ORDER BY COUNT(SalesOrderID) DESC) AS 
CustomerRank 
 FROM Sales.SalesOrderHeader
 GROUP BY TERRITORYID, CustomerID) temp
WHERE CustomerRank = 1;
-- Can easily add more columns
SELECT TERRITORYID, CustomerID, TotalOrder FROM
(SELECT TERRITORYID, CustomerID, COUNT(SalesOrderID) TotalOrder,
 RANK() OVER (PARTITION BY TERRITORYID  ORDER BY COUNT(SalesOrderID) DESC) AS 
CustomerRank 
 FROM Sales.SalesOrderHeader
 GROUP BY TERRITORYID, CustomerID) temp
WHERE CustomerRank = 1;

