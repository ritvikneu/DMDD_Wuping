
--Lab 4 Solutions
-- Part A
CREATE TABLE dbo.Student
 (
 StudentID varchar(10) NOT NULL PRIMARY KEY,
 FirstName varchar(40) NOT NULL,
 LastName varchar(40) NOT NULL,
 DateOfBirth date NOT NULL
);

CREATE TABLE dbo.Term
 (
 TermID varchar(10) NOT NULL PRIMARY KEY ,
 Year varchar(40) NOT NULL,
 Term varchar(40) NOT NULL
 );

CREATE TABLE dbo.Course
 (
 CourseID varchar(10) NOT NULL PRIMARY KEY ,
 Name varchar(40) NOT NULL,
 Description varchar(40) NOT NULL
 );
 
 CREATE TABLE dbo.Enrollment
 (
 StudentID varchar(10) NOT NULL REFERENCES dbo.Student(StudentID),
 CourseID varchar(10) NOT NULL REFERENCES dbo.Course(CourseID),
 TermID varchar(10) NOT NULL REFERENCES dbo.Term(TermID)
	CONSTRAINT PKItem PRIMARY KEY CLUSTERED (StudentID, CourseID, TermID)
 );


-- Part B-1 (2 points)

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


-- Part B-2 (2 points)

with t1 as (
select SalesPersonID, TotalDue OrderValue,
       row_number() over (partition by SalesPersonID order by TotalDue desc) rv
from Sales.SalesOrderHeader
where SalesPersonID is not null),

t2 as (
select SalesPersonID, count(distinct sd.ProductID) TotalUniqueProducts
from Sales.SalesOrderHeader sh
join Sales.SalesOrderDetail sd
on sh.SalesOrderID = sd.SalesOrderID
where SalesPersonID is not null
group by SalesPersonID),

t3 as (
select SalesPersonID, sh.SalesOrderID, 
       sum(sd.OrderQty) ooq,
       rank() over (partition by SalesPersonID order by sum(sd.OrderQty) desc) ro
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
where rv =1
order by t1.SalesPersonID;


-- Part C (2 points)

-- Create a temporary table with additional data

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

