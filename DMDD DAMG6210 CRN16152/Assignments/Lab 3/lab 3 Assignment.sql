use AdventureWorks2008R2;
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
 use AdventureWorks2008R2;
 WITH worstSelling as 
(SELECT h.OrderDate, i.ProductID, p.Name, SUM(i.OrderQty) as TotalQty,
        DENSE_RANK() OVER (PARTITION BY h.OrderDate ORDER BY SUM(i.OrderQty)) dateRank 
FROM Sales.SalesOrderHeader h 
JOIN Sales.SalesOrderDetail i
   ON h.SalesOrderID  = i.SalesOrderID 
JOIN Production.Product p 
   ON i.ProductID = p.ProductID
GROUP BY h.OrderDate, i.ProductID, p.Name
)
SELECT Cast(OrderDate as Date) as OrderDate,ProductID,
name as ProductName,totalQty
FROM worstSelling
WHERE dateRank = 1
ORDER BY orderDate DESC;

--solution
select * from
   (select CAST(a.OrderDate as DATE) AS OrderDate,
           b.ProductID, c.Name, sum(b.OrderQty) as total,
           RANK() OVER (PARTITION BY a.OrderDate 
	           ORDER BY sum(b.OrderQty)) AS Rank
    from [Sales].[SalesOrderHeader] a
    join [Sales].[SalesOrderDetail] b
         on a.SalesOrderID = b.SalesOrderID
    join [Production].[Product] c
         on c.ProductID = b.ProductID
    group by a.OrderDate, b.ProductID, c.Name
   ) temp
where rank = 1
order by OrderDate desc;
-------------------------------------

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
    SELECT YEAR(h.OrderDate) AS OrderYear, h.SalesPersonID,p.bonus,
    Cast(SUM(h.TotalDue) as int) AS TotalSales, 
    RANK() OVER (PARTITION BY YEAR(h.OrderDate) ORDER BY SUM(h.totalDue) DESC) PersonRank
    FROM Sales.SalesOrderHeader h
    JOIN Sales.SalesPerson p
        ON p.BusinessEntityID = h.SalesPersonID 
	where h.SalesPersonID  is not null	
    GROUP BY YEAR(h.OrderDate), h.SalesPersonID,p.bonus
)
SELECT OrderYear, SalesPersonID, TotalSales,bonus
FROM valuablePerson
WHERE PersonRank = 1 
AND SalesPersonID IS NOT NULL
ORDER BY OrderYear ;

--solution
select Year, temp.SalesPersonID, cast(TotalSale as int) [Total Sales], Bonus 
from
  (
  select year(OrderDate) Year, SalesPersonID, sum(TotalDue) TotalSale,
         rank() over (partition by year(OrderDate) order by sum(TotalDue) desc) as rank
  from Sales.SalesOrderHeader
  where SalesPersonID is not null
  group by year(OrderDate), SalesPersonID
  ) temp
join Sales.SalesPerson s
on temp.SalesPersonID = s.BusinessEntityID
where rank =1
order by Year;

 --------------------------------------------

-- Lab 3-5
/*
Write a query to return the salesperson id, the most sold product id,
and the order id that contained the highest total order quantity for
each salesperson. The most sold product had the highest total order quantity.

Return only the salesperson(s) who had at least one order that contained
a total sold quantity greater than 450. Exclude orders which don't have
a salesperson for this query. Sort the returned data by the salesperson id.
*/

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
and SalesPersonID in ( select SalesPersonID from salesPersons) and SalesPersonID is not null
group by SalesOrderID, ProductID,SalesPersonID,totalQty
order by SalesPersonID,SalesOrderID;

--Solution
with t1 as --mostSoldProductID
(select SalesPersonID, ProductID, sum(OrderQty) ProductQuantity,
 rank() over (partition by SalesPersonID order by sum(OrderQty) desc) rp
 from Sales.SalesOrderHeader sh
 join Sales.SalesOrderDetail sd
 on sh.SalesOrderID = sd.SalesOrderID
 where SalesPersonID is not null
 group by SalesPersonID, ProductID),
t2 as --mostsoldSalesOrder
(select SalesPersonID, sh.SalesOrderID, sum(OrderQty) OrderQuantity,
 rank() over (partition by SalesPersonID order by sum(OrderQty) desc) ro
 from Sales.SalesOrderHeader sh
 join Sales.SalesOrderDetail sd
 on sh.SalesOrderID = sd.SalesOrderID
 where SalesPersonID is not null
 group by SalesPersonID, sh.SalesOrderID)

select t1.SalesPersonID, ProductID, SalesOrderID
from t1 join t2 on t1.SalesPersonID = t2.SalesPersonID
where rp = 1 and ro = 1 and OrderQuantity > 450
order by SalesPersonID;