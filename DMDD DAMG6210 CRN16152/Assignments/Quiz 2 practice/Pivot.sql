/* PIVOT rotates a table-valued expression by turning the unique values 
   from one column in the expression into multiple columns in the output, 
   and performs aggregations where they are required on any remaining column values
   that are wanted in the final output. */
-- SQL statement to create the vertical format
use AdventureWorks2008R2;

SELECT DaysToManufacture, AVG(StandardCost) AS AverageCost   
FROM Production.Product  
GROUP BY DaysToManufacture; 

select 'avgCost' as avgCost , [0],[1],[2],[3]
from
(
SELECT DaysToManufacture, StandardCost AS AverageCost 
FROM Production.Product
) as source_table
pivot
(
AVG(AverageCost) for DaysToManufacture in ([0],[1],[2],[3],[4],[5])
)as pivot_Table;


-- Pivot table with one row and five columns
SELECT 'AverageCost' AS Cost_Sorted_By_Production_Days, 
[0], [1], [2], [3], [4]
FROM
(SELECT DaysToManufacture, StandardCost 
    FROM Production.Product) AS SourceTable
PIVOT
(
AVG(StandardCost)
FOR DaysToManufacture IN ([0], [1], [2], [3], [4])
) AS PivotTable;

-- SQL statement to create the vertical format
SELECT EmployeeID, COUNT(PurchaseOrderID) AS [Order Count]
FROM Purchasing.PurchaseOrderHeader
WHERE EmployeeID IN (250, 251, 256, 257, 260)
GROUP BY EmployeeID
ORDER BY EmployeeID;

-- Pivot table with one row and six columns
SELECT 'Order Count' AS ' ', [250] AS Emp1, [251] AS Emp2, [256] AS Emp3, [257] AS 
Emp4, [260] AS Emp5
FROM 
(SELECT PurchaseOrderID, EmployeeID
FROM Purchasing.PurchaseOrderHeader) SourceTable
PIVOT
(
COUNT (PurchaseOrderID)
FOR EmployeeID IN
( [250], [251], [256], [257], [260] )
) AS PivotTable;
-- SQL statement to create the vertical format
SELECT EmployeeID, VendorID, COUNT(PurchaseOrderID) AS [Order Count]
FROM Purchasing.PurchaseOrderHeader
WHERE EmployeeID IN (250, 251, 256, 257, 260)
GROUP BY EmployeeID, VendorID
ORDER BY EmployeeID, VendorID;
-- Pivot table with multiple rows and six columns
SELECT VendorID, [250] AS Emp1, [251] AS Emp2, [256] AS Emp3, [257] AS Emp4, [260] 
AS Emp5
FROM 
(SELECT PurchaseOrderID, EmployeeID, VendorID
FROM Purchasing.PurchaseOrderHeader) SourceTable
PIVOT
(
COUNT (PurchaseOrderID)
FOR EmployeeID IN
( [250], [251], [256], [257], [260] )
) AS PivotTable
ORDER BY PivotTable.VendorID

/* PIVOT Exercise Questions */
-- Question 1
/* Rewrite the following query to present the same data in a horizontal format,
   as listed below, using the SQL PIVOT command. */
SELECT TerritoryID, SalesPersonID, COUNT(SalesOrderID) AS [Order Count]
FROM Sales.SalesOrderHeader
WHERE SalesPersonID IN (280, 281, 282, 283, 284, 285)
GROUP BY TerritoryID, SalesPersonID
ORDER BY TerritoryID, SalesPersonID;

--My Solution
select TerritoryID, [280], [281], [282], [283], [284], [285]
from
(SELECT TerritoryID, SalesPersonID, SalesOrderID AS [OrderCount]
FROM Sales.SalesOrderHeader
)as source_table
pivot
(
count(OrderCount)  for SalesPersonID in ([280], [281], [282], [283], [284], [285])
) as pivot_table
order by TerritoryID;

--Solution
SELECT TerritoryID, [280], [281], [282], [283], [284], [285]
FROM 
(SELECT TerritoryID, SalesPersonID, SalesOrderID
FROM Sales.SalesOrderHeader) SourceTable
PIVOT
(
COUNT (SalesOrderID)
FOR SalesPersonID IN
( [280], [281], [282], [283], [284], [285] )
) AS PivotTable;
/*
TerritoryID 280 281 282 283 284 285
1 95 30 0 189 140
0
2 0 0 0 0 0
0
3 0 19 0 0 0
0
4 0 193 0 0 0
0
5 0 0 0 0 0
0
6 0 0 100 0 0
0
7 0 0 0 0 0
0
8 0 0 0 0 0
0
9 0 0 0 0 0
16
10 0 0 171 0 0
0
*/
-- Question 2
/* Rewrite the following query to present the same data in a horizontal format,
   as listed below, using the SQL PIVOT command. */
SELECT DATENAME(mm, OrderDate) AS [Month], CustomerID,
       SUM(TotalDue) AS TotalOrder
FROM   Sales.SalesOrderHeader
WHERE CustomerID BETWEEN 30020 AND 30024
GROUP BY CustomerID, DATENAME(mm, OrderDate), MONTH(OrderDate)
ORDER BY MONTH(OrderDate);

--My Solution
select [Month], [30020],[30021],[30022],[30023],[30024]
from
(SELECT DATENAME(mm, OrderDate) AS [Month], CustomerID,
       TotalDue AS TotalOrder
FROM   Sales.SalesOrderHeader) SourceTable
--WHERE CustomerID BETWEEN 30020 AND 30024
pivot
(
sum(TotalOrder) for CustomerID in ([30020],[30021],[30022],[30023],[30024])
) as pivot_table
order by [Month]

--Solution
SELECT [Month],
   ISNULL(cast([30020] as int), 0) '30020',
   ISNULL(cast([30021] as int), 0) '30021',
   ISNULL(cast([30022] as int), 0) '30022',
   ISNULL(cast([30023] as int), 0) '30023',
   ISNULL(cast([30024] as int), 0) '30024'
FROM (SELECT DATENAME(mm, OrderDate) AS [Month], CustomerID, TotalDue
      FROM Sales.SalesOrderHeader
      WHERE CustomerID BETWEEN 30020 AND 30024
  ) AS SourceTable
PIVOT
     (SUM(TotalDue) 
      FOR CustomerID IN ([30020], [30021], [30022], [30023], [30024])
     ) AS PivotTable
ORDER BY MONTH([Month]+ ' 21 2019');
/*
Month 30020 30021 30022 30023 30024
February 0 3195 9067 181 3335
March 19254 0 0 0 0
May 0 1925 9276 1323 327
June 12905 0 0 0 0
August 0 851 11448 9007 2998
September 26919 0 0 0 0
November 0 6716 6149 734 4979
December 15693 0 0 0 0
*/
/* Hint: Use the month name to build a date. Then use MONTH() to get
         the month number from the date for sorting. */

with sourceTemp as
(
select datepart(mm, OrderDate) Monthly,
       SalesPersonID,
       cast(sum(TotalDue) as int) as TotalSales
from Sales.SalesOrderHeader
where month(OrderDate) in (1,3,5,7,9,11) and SalesPersonID between 275 and 280
group by SalesPersonID,  datepart(mm, OrderDate)
having sum(TotalDue) > 350000)

Select monthly, isnull([275],0) '275',isnull([276],0) '276',isnull([277],0) '277',
isnull([278],0) '278',isnull([279],0) '279',isnull([280],0) '280'
from
(
select Monthly,salesPersonId,totalSales
from sourceTemp ) sourceTable
pivot
(
sum(TotalSales) for SalesPersonID in([275],[276],[277],[278],[279],[280])
) as pivotTable


/* Rewrite the following query to present the same data in a horizontal format,
   as listed below, using the SQL PIVOT command. 
   Please use AdventureWorks2008R2 for this question. */

with sourceTemp as (
select datepart(yy, OrderDate) Yearly,
       datepart(dw, OrderDate) as WeekDays,
       cast(sum(TotalDue) as int) as TotalSales
from Sales.SalesOrderHeader
where year(OrderDate) between 2006 and 2008
group by datepart(dw, OrderDate),  datepart(yy, OrderDate)
having sum(TotalDue) > 5500000
)
select yearly, isnull([1],0),isnull([2],0),isnull([3],0),isnull([4],0),isnull([5],0),isnull([6],0),isnull([7],0)
from
(select yearly,totalSales,WeekDays
from sourceTemp ) as sourceTable
pivot 
(
sum(totalsales) for weekdays in([1],[2],[3],[4],[5],[6],[7])
) as pivotTable



