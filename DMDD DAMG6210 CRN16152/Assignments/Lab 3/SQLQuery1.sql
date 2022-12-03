USE AdventureWorks2008R2;
--Lab 3-1
/* Modify the following query to add a column that identifies the
 frequency of repeat customers and contains the following values
 based on the number of orders:
 'No Order' for count = 0
 'One Time' for count = 1
 'Regular' for count range of 2-5
 'Often' for count range of 6-10
 'Loyal' for count greater than 10
 Give the new column an alias to make the report more readable. 
*/
SELECT c.CustomerID, c.TerritoryID, FirstName, LastName,
COUNT(o.SalesOrderid) [Total Orders], 
Case
WHEN COUNT(o.SalesOrderid) = 0 
THEN 'No Order'
when COUNT(o.SalesOrderid) = 1
then 'One Time'
when COUNT(o.SalesOrderid) >= 2 AND COUNT(o.SalesOrderid) <= 5 
then 'Regular'
when COUNT(o.SalesOrderid) >= 6 AND COUNT(o.SalesOrderid) <= 10 
then 'Often'
when COUNT(o.SalesOrderid) > 10 
then 'Loyal'
END AS NumberOfOrders
FROM Sales.Customer c
JOIN Sales.SalesOrderHeader o
 ON c.CustomerID = o.CustomerID
JOIN Person.Person p
 ON p.BusinessEntityID = c.PersonID
WHERE c.CustomerID > 25000
GROUP BY c.TerritoryID, c.CustomerID, FirstName, LastName;


-- Lab 3-2
/* Modify the following query to add a rank without gaps in the
 ranking based on total orders in the descending order. Also
 partition by territory.*/
SELECT c.CustomerID, c.TerritoryID, FirstName, LastName,
COUNT(o.SalesOrderid) [Total Orders],
Dense_Rank() over(PARTITION BY c.TerritoryID order by COUNT(o.SalesOrderid) desc ) as Rank
FROM Sales.Customer c
JOIN Sales.SalesOrderHeader o
 ON c.CustomerID = o.CustomerID
JOIN Person.Person p
 ON p.BusinessEntityID = c.PersonID
WHERE c.CustomerID > 25000
GROUP BY c.TerritoryID, c.CustomerID, FirstName, LastName;

-- Lab 3-3
/* Retrieve the date, product id, product name, and the total
 sold quantity of the worst selling (by total quantity sold) 
 product of each date. If there is a tie for a date, it needs
 to be retrieved. 
 Sort the returned data by date in descending. */
 WITH worstSelling as 
(SELECT oh.OrderDate, od.ProductID, p.Name, SUM(od.OrderQty) as TotalQty,
        DENSE_RANK() OVER (PARTITION BY oh.OrderDate ORDER BY SUM(od.OrderQty)) dateRank 
FROM Sales.SalesOrderHeader oh 
JOIN Sales.SalesOrderDetail od 
   ON oh.SalesOrderID  = od.SalesOrderID 
JOIN Production.Product p 
   ON od.ProductID = p.ProductID
GROUP BY oh.OrderDate, od.ProductID, p.Name
)
SELECT Cast(OrderDate as Date) as OrderDate,ProductID,totalQty
FROM worstSelling
WHERE dateRank = 1
ORDER BY orderDate DESC;
-------------------------------------
select * from Sales.SalesOrderDetail;
select * from Sales.SalesOrderHeader;
Select * from Production.Product;

select p.ProductID, p.Name, 
sum(i.OrderQty) as Total_OrderQty,
Cast(h.orderDate as date) as OrderDate
from Production.Product p 
inner join Sales.SalesOrderDetail i
on p.ProductID = i.ProductID
inner join Sales.SalesOrderHeader h
on h.SalesOrderID = i.SalesOrderID
where orderDate = 
(select orderDate, sum(i.orderQty), Rank() over(partition by orderDate order by sum(i.OrderQty) desc) as ranking having min(orderqty))  ) 
group by p.ProductID,p.Name,OrderDate



select
Cast(h.orderDate as date) as OrderDate,
p.productID,
sum(i.OrderQty) as Total_OrderQty
from Production.Product p  
inner join Sales.SalesOrderDetail i
on p.ProductID = i.ProductID
inner join Sales.SalesOrderHeader h
on h.SalesOrderID = i.SalesOrderID 
group by p.ProductID, OrderDate;


-- Lab 3-4
/* Write a query to retrieve the most valuable salesperson of each year.
 The most valuable salesperson for each year is the salesperson who has
 made most sales for AdventureWorks in the year. 
 
 Calculate the yearly total of the TotalDue column of SalesOrderHeader 
 as the yearly total sales for each salesperson. If there is a tie 
 for the most valuable salesperson, your solution should retrieve it.
 Exclude the orders which didn't have a salesperson specified.
 Include the salesperson id, the bonus the salesperson earned,
 and the most valuable salesperson's total sales for the year
 columns in the report. Display the total sales as an integer.hu
 Sort the returned data by the year. */
 WITH valuablePerson AS(
    SELECT YEAR(oh.OrderDate) AS OrderYear, oh.SalesPersonID, p.Bonus,
    CAST(SUM(oh.TotalDue) AS int) AS [TotalSales], 
    RANK() OVER (PARTITION BY YEAR(oh.OrderDate) ORDER BY SUM(od.OrderQty) DESC) PersonRank
    FROM Sales.SalesOrderHeader oh
    JOIN Sales.SalesOrderDetail od 
        ON oh.SalesOrderID  = od.SalesOrderID
    JOIN Sales.SalesPerson p
        ON p.BusinessEntityID = oh.SalesPersonID  
    GROUP BY YEAR(oh.OrderDate), oh.SalesPersonID, [Bonus]
)
SELECT OrderYear, SalesPersonID, TotalSales
FROM valuablePerson
WHERE PersonRank = 1 AND SalesPersonID IS NOT NULL
ORDER BY OrderYear ;
 --------------------------------------------

select TOP 3 * from Sales.SalesOrderDetail;
select TOP 3  * from Sales.SalesOrderHeader;
Select TOP 3  * from Production.Product;

 select h.SalesPersonID, Sum(h.TotalDue) over(partition by YEAR(i.orderDate)) as yearly_totalSales 
 from Sales.SalesOrderHeader h
 inner join sales.SalesOrderDetail i
 on h.SalesOrderID = i.SalesOrderID;


-- Lab 3-5
/*
Write a query to return the salesperson id, the most sold product id,
and the order id that contained the highest total order quantity for
each salesperson. The most sold product had the highest total order quantity.

Return only the salesperson(s) who had at least one order that contained
a total sold quantity greater than 450. Exclude orders which don't have
a salesperson for this query. Sort the returned data by the salesperson id.
*/

select h.salesPersonID
from Sales.SalesOrderHeader h;

with salesPersons as
(select h.salesPersonID,i.SalesOrderID
from Sales.SalesOrderDetail i
inner join Sales.SalesOrderHeader h
on h.SalesOrderID = i.SalesOrderID
where SalesPersonID is not null
group by SalesPersonID,i.SalesOrderID
having sum(i.OrderQty) > 450
),
MaxSalesOrder as
(
select h.salesPersonID,p.productID, sum(i.orderqty) as totalQty,h.SalesOrderID,
rank() over(partition by salesPersonID order by sum(i.orderqty) desc) as rankSales
from Production.Product p 
inner join Sales.SalesOrderDetail i
on i.ProductID = p.ProductID
inner join Sales.SalesOrderHeader h
on h.SalesOrderID = i.SalesOrderID
where h.SalesPersonID is not null
group by p.ProductID,h.SalesOrderID ,SalesPersonID
)
select SalesPersonID, productID,salesorderID,totalQty
from MaxSalesOrder
where rankSales = 1
and SalesPersonID in ( select SalesPersonID from salesPersons)
group by SalesOrderID, ProductID,SalesPersonID,totalQty
order by SalesPersonID,SalesOrderID
----------------------------------------------------------------
select


select h.salesPersonID,i.salesOrderID
from Sales.SalesOrderDetail i
inner join Sales.SalesOrderHeader h
on h.SalesOrderID = i.SalesOrderID
group by SalesPersonID,i.SalesOrderID
having sum(i.OrderQty) > 450
order by salesPersonID

select p.productID, i.salesorderID,sum(i.OrderQty)
from Production.Product p 
inner join Sales.SalesOrderDetail i
on i.ProductID = p.ProductID
where i.salesorderID in (53465,51721,43755)
group by p.productID, i.salesorderID
order by sum(i.OrderQty) desc


--pru
SELECT Z.SalesPerson_ID, Z.Product_ID, Z.Order_ID ,z.orderqty
FROM
	(
	SELECT X.SalesPersonID AS "SalesPerson_ID", Y.ProductID AS "Product_ID", Y.OrderID AS "Order_ID", Y.Total AS "orderqty",
	RANK() OVER (PARTITION BY X.SalesPersonID ORDER BY Y.Total DESC) Rank
	FROM(
		(
		SELECT SalesPersonID, soh.SalesOrderID AS "SalesID", SUM(OrderQty) AS "Total" FROM
		Sales.SalesOrderHeader soh 
		INNER JOIN Sales.SalesOrderDetail sod 
		ON soh.SalesOrderID = sod.SalesOrderID
		GROUP BY SalesPersonID, soh.SalesOrderID
		HAVING SUM(OrderQty)>450) X
		JOIN
			(
			SELECT oh.SalesOrderID AS "OrderID", od.ProductID AS "ProductID", 
			SUM(od.OrderQty) AS "Total", oh.SalesPersonID AS "personID",
			RANK() OVER (PARTITION BY od.ProductID ORDER BY SUM(od.OrderQty) DESC) Rank
			FROM Sales.SalesOrderHeader oh
			JOIN Sales.SalesOrderDetail od 
			ON oh.SalesOrderID  = od.SalesOrderID
			WHERE oh.SalesPersonID IS NOT NULL
			GROUP BY oh.SalesPersonID, oh.SalesOrderID, od.ProductID) Y
			ON X.SalesID = Y.OrderID
			)
		 WHERE Y.Rank = 1
		 ) 
		Z WHERE Z.Rank = 1
	--------------------------





