--Part A
/*
CREATE DATABASE "RitvikDMDD";
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

Use AdventureWorks2008R2;

select SalesPersonID,count(distinct(productId))
--count(Distinct(ProductID)),
--soh.SalesOrderID
from Sales.SalesOrderHeader soh
join Sales.SalesOrderDetail sod
on sod.SalesOrderID = soh.SalesOrderID
where SalesPersonID = '275'
group by salesPersonID
--,soh.SalesOrderID,ProductID
order by TotalDue desc
;
select * from Production.Product;

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
Stuff( 
	 (select top 3 ',' +Cast(ProductID as varchar)
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
	on tm.OrderYear = osy.orderYear
	--where osy.orderYear = orderYear



	-------------------------------
use AdventureWorks2008R2;
WITH Parts(AssemblyID, ComponentID, PerAssemblyQty, EndDate, ComponentLevel) AS
(
SELECT b.ProductAssemblyID, b.ComponentID, b.PerAssemblyQty,
b.EndDate, 0 AS ComponentLevel
FROM Production.BillOfMaterials AS b
WHERE b.ProductAssemblyID = 992 AND b.EndDate IS NULL

UNION ALL

SELECT bom.ProductAssemblyID, bom.ComponentID, bom.PerAssemblyQty,
bom.EndDate, ComponentLevel + 1
FROM Production.BillOfMaterials AS bom
INNER JOIN Parts AS p ON bom.ProductAssemblyID = p.ComponentID
AND bom.EndDate IS NULL
),

Parts_Components AS
(
SELECT ListPrice, ComponentID, Name, PerAssemblyQty, ComponentLevel,
DENSE_RANK() OVER (ORDER BY ListPrice DESC) AS 'Rnk_'
FROM Parts AS PT
INNER JOIN Production.Product PR ON PT.ComponentID = PR.ProductID
)

SELECT PC.ListPrice, PC.ComponentID, PC.Name AS 'Name',
PC.PerAssemblyQty, PC.ComponentLevel, PC.Rnk_  AS 'Rank'
FROM Parts_Components PC
WHERE Rnk_ = 1



-- Part C

WITH Parts(AssemblyID, ComponentID, PerAssemblyQty, EndDate, ComponentLevel) AS 
( 
    SELECT b.ProductAssemblyID, b.ComponentID, b.PerAssemblyQty, 
           b.EndDate, 0 AS ComponentLevel 
    FROM Production.BillOfMaterials AS b 
    WHERE b.ProductAssemblyID = 992 AND b.EndDate IS NULL 
    UNION ALL 
    SELECT bom.ProductAssemblyID, bom.ComponentID, bom.PerAssemblyQty, 
           bom.EndDate, ComponentLevel + 1 
    FROM Production.BillOfMaterials AS bom  
    INNER JOIN Parts AS p 
    ON bom.ProductAssemblyID = p.ComponentID AND bom.EndDate IS NULL 
),
temp2 as 
(
select DISTINCT p.AssemblyID, p.ComponentID, p.ComponentLevel, MAX(pd.ListPrice) as "Most_Expensive_Component" 
from Parts p
join Production.Product pd
on p.ComponentID = pd.ProductID 
group by p.AssemblyID, p.ComponentID, p.ComponentLevel
),
temp3 as 
(
SELECT AssemblyID, ComponentID, ComponentLevel, MAX(Most_Expensive_Component) as "Price", RANK() OVER(ORDER BY MAX(Most_Expensive_Component) DESC) as "Rank" 
FROM temp2 t2
group by AssemblyID, ComponentID, ComponentLevel
)
SELECT AssemblyID, ComponentID as "Most_Expensive_ComponentID" , ComponentLevel, Price
FROM temp3 t3
WHERE Rank = 1
