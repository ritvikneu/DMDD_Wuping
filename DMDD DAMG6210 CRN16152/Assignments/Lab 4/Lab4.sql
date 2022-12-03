Use AdventureWorks2008R2;
--Part A

/*
CREATE DATABASE "RitvikDMDD";
GO
Use RitvikDMDD;
CREATE TABLE dbo.Course
(
CourseID int not null Primary Key,
Name varchar(40) not null,
Description varchar(100) not null);

Create Table term
(
TermID int not null Primary key,
Year smallint not null,
Term varchar(10) not null
)

Create table Student
(
StudentID int not null Primary Key,
LastName varchar(40) not null,
Firstname varchar(40) not null,
DateOfBirth date not null
)

Create table Enrollment
(
StudentID int not null
		References dbo.Student(StudentID), 
CourseID int not null 
		References dbo.Course(CourseID),
TermID int not null
		References dbo.term(TermID),
Constraint keys Primary Key (StudentID,CourseID,TermID)
)

*/

--Part B 1
/* Write a query to retrieve the top 3 products for each year.
 Use OrderQty of SalesOrderDetail to calculate the total sold quantity.
 The top 3 products have the 3 highest total sold quantities.
 Also calculate the top 3 products total sold quantity for the year.
 Return the data in the following format.

Year  Total Sale Top5Products
2005  1598		709, 712, 715
2006  5703		863, 715, 712
2007  9750		712, 870, 711
2008  8028		870, 712, 711

*/

Use AdventureWorks2008R2;
-----------------------------------------------------------------------------------------
with ranks as(
select ProductID, sum(OrderQty) as sumProduct ,year(soh.orderDate) as orderYear
,rank() over(partition by year(soh.orderDate) order by sum(orderQty) DESC) as proRank
from sales.SalesOrderDetail sod 
join sales.SalesOrderHeader soh
on soh.SalesOrderID = sod.SalesOrderID
--where ProductID in (709,712,715)
group by ProductID,year(soh.OrderDate)
--order by year(orderDate)
),
TotalSalesForProducts as(
select productID, sumProduct, orderYear
from ranks
where proRank in (1,2,3)
),
OnlySumYear as (
select sum(sumProduct) as top3ProductSum,orderYear 
from TotalSalesForProducts
group by orderYear
)
,Top3andMax as (
Select Distinct(YEAR(soh.OrderDate)) as OrderYear,
Stuff ( 
	  ( select top 3 ',' +Cast(ProductID as varchar)
       from
	   sales.SalesOrderDetail as sod
	   join Sales.SalesOrderHeader as h
       on h.SalesOrderID = sod.SalesOrderID
	   where Year(h.OrderDate) = Year(soh.OrderDate)
	   group by ProductID 
	   order by sum(orderQty) desc
	   FOR XML PATH('')
	   ),1,1,''
	   ) as Top3Products
from Sales.SalesOrderHeader as soh 
join Sales.SalesOrderDetail as sod
on soh.SalesOrderID = sod.SalesOrderID
join TotalSalesForProducts as tsp
on tsp.ProductID = sod.ProductID
group by Year(soh.OrderDate)
--order by Year(soh.OrderDate)
)
Select tm.OrderYear, top3ProductSum as TotalSales,
	tm.Top3Products
	from OnlySumYear osy
	join Top3andMax tm
	on tm.OrderYear = osy.orderYear;

--solution
WITH Temp AS

   (select year(OrderDate) Year, ProductID, sum(OrderQty) ttl,
    rank() over (partition by year(OrderDate) order by sum(OrderQty) desc) as TopProduct
    from Sales.SalesOrderHeader sh
	join Sales.SalesOrderDetail sd
	on sh.SalesOrderID = sd.SalesOrderID
    group by year(OrderDate), ProductID)

select t1.Year, cast(sum(t1.ttl) as decimal) [Total Sale],

STUFF((SELECT  ', '+RTRIM(CAST(ProductID as char))  
       FROM temp 
       WHERE Year = t1.Year and TopProduct <=3
       FOR XML PATH('')) , 1, 2, '') AS Top5Products

from temp t1
where t1.TopProduct <= 3
group by t1.Year;

-----------------------------------------------------------------------------------------
/*
--Part B 2
Using AdventureWorks2008R2, write a query to return the salesperson id,
number of unique products sold, highest order value, total sales amount,
and top 3 orders for each salesperson. Use TotalDue in SalesOrderHeader
when calculating the highest order value and total sales amount. The
top 3 orders have the 3 highest total order quantities. If there is a tie,
the tie must be retrieved. Exclude orders which don't have a salesperson 
for this query.
Return the order value as int. Sort the returned data by SalesPersonID. 
The returned data should have a format displayed below. Use the sample format 
for formatting purposes only.
*/-----------------------------------------------------------------------------------
/*
SalesPersonID TotalUniqueProducts OrderValue Orders
274 216 126852 53465, 51830, 46993
275 242 165029 47395, 47416, 53616
276 244 145742 47400, 51721, 47355
277 246 132728 53530, 51157, 51748
278 234 96937 53483, 46953, 51703
279 245 142312 51147, 53524, 46672
280 222 105494 53518, 51789, 46974
281 241 187488 51131, 47369, 55282
282 250 130249 53458, 53472, 51120
283 240 123497 46957, 51123, 51711
284 207 119641 69508, 53613, 50297
285 68 65911 53485, 53502, 58915
286 117 71730 58931, 71805, 65191
287 196 81030 51837, 58908, 47004
288 182 117506 51751, 51109, 51761
289 221 170513 51160, 46616, 47365
290 219 166537 51739, 46981, 69437
*/use AdventureWorks2008R2;
select soh.SalesPersonID , 
count(distinct(productId)) as UniqueProducts,
Cast(max(TotalDue) as int) as HighestOrderValue,
(select 
sum(TotalDue) 
from Sales.SalesOrderHeader 
 where SalesPersonID = soh.SalesPersonID) 
 as TotalSalesAmount,
Stuff((select top 3 with ties ','+Cast(h.salesOrderId as varchar) --as top3
	 from sales.SalesOrderHeader as h
	 where h.SalesPersonID = soh.SalesPersonID
	 group by h.SalesOrderID
	 order by SUM(TotalDue) DESC
	 FOR XML PATH('')
	 ),1,1,''
	 ) as Top3SalesOrder
from sales.SalesOrderHeader as soh
join sales.SalesOrderDetail as sod
on soh.SalesOrderID = sod.SalesOrderID
where SalesPersonID <> ''
group by soh.SalesPersonID
order by SalesPersonID;

--solution
with t1  as ( -- salesperson maximum ordervalues
select SalesPersonID, TotalDue as OrderValue,
       row_number() over (partition by SalesPersonID order by TotalDue desc) rv
from Sales.SalesOrderHeader
where SalesPersonID is not null),

t2 as ( --salesperson unique products
select SalesPersonID, count(distinct sd.ProductID) TotalUniqueProducts
from Sales.SalesOrderHeader sh
join Sales.SalesOrderDetail sd
on sh.SalesOrderID = sd.SalesOrderID
where SalesPersonID is not null
group by SalesPersonID),

t3 as ( --salesperson - salesorderid sum orderQty
select SalesPersonID, sh.SalesOrderID, 
       sum(sh.totaldue) ooq,
       rank() over (partition by SalesPersonID order by sum(sh.totaldue) desc) ro
from Sales.SalesOrderHeader sh
join Sales.SalesOrderDetail sd
on sh.SalesOrderID = sd.SalesOrderID
where SalesPersonID is not null
group by SalesPersonID, sh.SalesOrderID
)
select distinct t1.SalesPersonID, TotalUniqueProducts, 
       cast(OrderValue as int) OrderValue, 
STUFF((SELECT  TOP 3 WITH TIES ', '+RTRIM(CAST(SalesOrderID as char))  
       FROM t3  
	   WHERE t3.SalesPersonID = t1.SalesPersonID
       ORDER BY ro
       FOR XML PATH('')) , 1, 2, '') AS Orders
from t1 join t2 on t1.SalesPersonID = t2.SalesPersonID
join t3 on t2.SalesPersonID = t3.SalesPersonID
--join t4 on t2.SalesPersonID = t4.SalesPersonID
where rv =1
order by t1.SalesPersonID;

----------------------------------------------------------------------------

select SalesPersonID,SUM(TotalDue)
from Sales.SalesOrderHeader
WHERE SalesPersonID = '274'
group by salesPersonID
;

--Part C
/* Bill of Materials - Recursive */
/* The following code retrieves the components required for manufacturing
 the "Mountain-500 Black, 48" (Product 992). Modify the code to retrieve
 the most expensive component(s) that cannot be manufactured internally.
 Use the list price of a component to determine the most expensive
 component.
 If there is a tie, your solutions must retrieve it. */
--Starter code

--select * from Production.BillOfMaterials;
----------------------------------------------------------------
-- Assuming component(s) that cannot be manufactured internally means a ComponentID cannot be a ProductAssemblyID

WITH Parts(AssemblyID, ComponentID, PerAssemblyQty, EndDate, ComponentLevel) AS
(
SELECT b.ProductAssemblyID, b.ComponentID, b.PerAssemblyQty,
b.EndDate, 0 AS ComponentLevel
FROM Production.BillOfMaterials AS b
WHERE b.ProductAssemblyID = 992 AND b.EndDate IS NULL
UNION ALL
SELECT bom.ProductAssemblyID, bom.ComponentID, p.PerAssemblyQty,
bom.EndDate, ComponentLevel + 1
FROM Production.BillOfMaterials AS bom
INNER JOIN Parts AS p
ON bom.ProductAssemblyID = p.ComponentID AND bom.EndDate IS NULL
),
PartsProducts as(
SELECT AssemblyID, ComponentID, Name, PerAssemblyQty, ComponentLevel
FROM Parts AS p
INNER JOIN Production.Product AS prod
ON p.ComponentID = prod.ProductID
)
,SumListPrice as (
select pr.AssemblyID,pr.ComponentID, pr.Name, pr.PerAssemblyQty,
pr.ComponentLevel, SUM(ListPrice) as ListPrice
from PartsProducts pr
inner join Production.Product prod
on prod.ProductID=pr.ComponentID
where ListPrice<>0
Group By pr.AssemblyID,pr.ComponentID, pr.Name, pr.PerAssemblyQty, pr.ComponentLevel
--order by ListPrice desc
)
select top 1 with ties AssemblyID,
ComponentID, ListPrice 
from SumListPrice
where ComponentID NOT IN ( Select AssemblyID from SumListPrice )
ORDER BY ListPrice DESC, AssemblyID,ComponentID

--solution
IF OBJECT_ID('tempdb..#TempTable') IS NOT NULL
DROP TABLE #TempTable;

WITH Parts(AssemblyID, ComponentID, PerAssemblyQty, EndDate, ComponentLevel) AS
(
    -- Top-level compoments
	SELECT b.ProductAssemblyID, b.ComponentID, b.PerAssemblyQty,
        b.EndDate, 0 AS ComponentLevel
    FROM Production.BillOfMaterials AS b
    WHERE b.ProductAssemblyID = 992
          AND b.EndDate IS NULL

    UNION ALL

	-- All other sub-compoments
    SELECT bom.ProductAssemblyID, bom.ComponentID, p.PerAssemblyQty,
        bom.EndDate, ComponentLevel + 1
    FROM Production.BillOfMaterials AS bom 
        INNER JOIN Parts AS p
        ON bom.ProductAssemblyID = p.ComponentID
        AND bom.EndDate IS NULL
)
SELECT AssemblyID, ComponentID, Name, ListPrice, PerAssemblyQty, 
       ListPrice * PerAssemblyQty SubTotal, ComponentLevel

into #TempTable

FROM Parts AS p
    INNER JOIN Production.Product AS pr
    ON p.ComponentID = pr.ProductID
ORDER BY ComponentLevel, AssemblyID, ComponentID;


/* SELECT the most expensive component(s) that cannot be made internally from the
   temporary table. */

SELECT top 1 with ties AssemblyID, ComponentID, Name, PerAssemblyQty, ComponentLevel,ListPrice
FROM #TempTable
WHERE ComponentLevel = 0 and ComponentID not in
      (select AssemblyID FROM #TempTable where ComponentLevel > 0)
order by ListPrice desc;


--------------------
