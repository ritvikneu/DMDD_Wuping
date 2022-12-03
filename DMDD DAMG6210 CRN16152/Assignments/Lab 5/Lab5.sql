--Use AdventureWorks2008R2;


/*
CREATE FUNCTION GetLastOrdersForCustomer
(@CustomerID int, @NumberOfOrders int)
RETURNS TABLE
AS
RETURN (SELECT TOP(@NumberOfOrders)
 SalesOrderID,
 OrderDate,
 PurchaseOrderNumber
 FROM AdventureWorks2008R2.Sales.SalesOrderHeader
 WHERE CustomerID = @CustomerID
 ORDER BY OrderDate DESC, SalesOrderID DESC
 );
GO
-- Execute the new function
SELECT * FROM GetLastOrdersForCustomer(17288,2);
*/


use RitvikDMDD;
--Lab 5-1---------------------------------------------------------------------------------------------------------------/* Create a function in your own database that takes two
 parameters:
 A year parameter 
 A month parameter
 The function then calculates and returns the total sales 
 of the requested period for each territory. Include the
 territory id, territory name, and total sales dollar amount
 in the returned data. Format the total sales as an integer.
 Hints: a) Use the TotalDue column of the 
 Sales.SalesOrderHeader table in an
 AdventureWorks database for
 calculating the total sale.
 b) The year and month parameters should have 
 the SMALLINT data type.
*/
drop function PeriodTotalSales;
Go
Create Function PeriodTotalSales
(@periodYear smallint, @periodMonth smallint)
returns table
as
Return(Select sh.TerritoryID,st.Name as TerritoryName, Cast(sum(TotalDue) as int) as TotalSales
		from AdventureWorks2008R2.sales.SalesOrderHeader sh
	  inner join AdventureWorks2008R2.Sales.SalesTerritory st
	on sh.TerritoryID = st.TerritoryID
		where Year(OrderDate) = @periodYear
		 and  Month(OrderDate) = @periodMonth
		 group by sh.TerritoryID,st.name
	  );
Go
select * from periodtotalSALES(2007,09);
--solution
CREATE FUNCTION dbo.ufGetTerritorySale
(@y SMALLINT, @m SMALLINT)
RETURNS TABLE
AS
RETURN
SELECT t.TerritoryID, t.Name, 
      CAST(SUM(sh.TotalDue) AS int) TotalSale
FROM Sales.SalesOrderHeader sh
JOIN Sales.SalesTerritory t
ON sh.TerritoryID = t.TerritoryID
WHERE YEAR(sh.OrderDate) = @y and MONTH(sh.OrderDate) = @m
GROUP BY t.TerritoryID, t.Name;

------------------------------------------------------------------------------------------------------------
--Lab 5-2---------------------------------------------------------------------------------------------------
/*
Create a table in your own database using the following statement.

Write a stored procedure that accepts two parameters:
 A starting date 
 The number of the consecutive dates beginning with the starting date
The stored procedure then inserts data into all columns of the
DateRange table according to the two provided parameters.
*/


CREATE TABLE DateRange
(DateID INT IDENTITY, 
DateValue DATE,
DayOfWeek SMALLINT,
Week SMALLINT,
Month SMALLINT,
Quarter SMALLINT,
Year SMALLINT
);
drop proc procDateRange;
go
Create procedure procDateRange
	@StartDate date,
	@conDates int
	as
	DECLARE @counter INT;
	declare @dateID INT;
	SET @counter = 0;
	WHILE @counter < @conDates
	Begin 
	--date ID is a counter which will be uniquely adding entries to the table 
	Set @dateID = (select max(DateID) as NumRows from RitvikDMDD.dbo.DateRange) + 1;
	insert into RitvikDMDD.dbo.DateRange
	(DateID,DateValue,DayOfWeek,Week,Month,Quarter,Year)
	values
	(@dateID,@StartDate,DATEPART(WEEKDAY,@StartDate),DATEPART(WEEK,@StartDate),DATEPART(MONTH,@StartDate),DATEPART(QUARTER,@StartDate),DATEPART(YEAR,@StartDate))
	SET @counter = @counter + 1;
	set @StartDate =  DATEADD(d,1,@StartDate);
	set @dateID = @dateID + 1;
	end;
go
set identity_insert RitvikDMDD.dbo.DateRange on;
Declare @startDate date;
declare @days int;
set @startDate = '2022-01-01';
exec procDateRange @startDate,5;


select * from RitvikDMDD.dbo.DateRange;
--solution
CREATE PROC dbo.uspDate
@d DATE, @n INT
AS
BEGIN
  WHILE @n <>0
    BEGIN
      INSERT INTO dbo.DateRange (DateValue, DayOfWeek,
	         Week, Month, Quarter, Year)
      SELECT @d, DATEPART(dw, @d), DATEPART(wk, @d),
	         MONTH(@d), DATEPART(q, @d), YEAR(@d)
      SET @d = DATEADD(d, 1, @d);
      SET @n = @n -1;
    END
END

-------------------------------------------------------------------------------------------------------------------------
--Lab 5-3----------------------------------------------------------------------------------------------------------------
/* Given the following tables, there is a university rule
 preventing a student from enrolling in a new class if there is
 an unpaid fine. Please write a table-level CHECK constraint
 to implement the rule. */
use RitvikDMDD;
create table Fine
(StudentID int references Student(StudentID),
IssueDate date,
Amount money,
PaidDate date
primary key (StudentID, IssueDate));goCreate Function checkUnpaidFine (@studentId int)returns smallintas begin DECLARE @Count smallint=0;
   SELECT @Count = COUNT(StudentID) 
          FROM dbo.Fine
          WHERE StudentID = @StudentID
		  and PaidDate = null;
   RETURN @Count;   end;goAlter table Ritvikdmdd.dbo.Enrollment add constraint UnpaidFine Check(dbo.checkUnpaidFine(StudentID) = 0);--solutioncreate function ufLookUpFine (@StID int)
returns money
begin
   declare @amt money;
   select @amt = sum(Amount)
      from Fine
      where StudentID = @StID and PaidDate is null;
   return @amt;
end

alter table Enrollment add CONSTRAINT ckfine CHECK (dbo.ufLookUpFine (StudentID) = 0);


----------------------------------------------------------------------------------------------------------------
--lab 5-4---------------------------------------------------------------------------------------------------
/* Write a trigger to put the total sale order amount before tax
 (unit price * quantity for all items included in an order) 
 in the OrderAmountBeforeTax column of SaleOrder. */

use RitvikDMDD;

CREATE TABLE Customer
(CustomerID VARCHAR(20) PRIMARY KEY,
CustomerLName VARCHAR(30),
CustomerFName VARCHAR(30),
CustomerStatus VARCHAR(10));
CREATE TABLE SaleOrder
(OrderID INT IDENTITY PRIMARY KEY,
CustomerID VARCHAR(20) REFERENCES Customer(CustomerID),
OrderDate DATE,
OrderAmountBeforeTax INT);
CREATE TABLE SaleOrderDetail
(OrderID INT REFERENCES SaleOrder(OrderID),
ProductID INT,
Quantity INT,
UnitPrice INT,
PRIMARY KEY (OrderID, ProductID));
go

CREATE TRIGGER TriggerSalesOrder
ON dbo.SaleOrderDetail
AFTER INSERT AS
BEGIN
 DECLARE @Amount INT=0;
 SELECT @Amount = SUM(UnitPrice * Quantity)
 FROM SaleOrderDetail
 WHERE OrderID = (SELECT OrderID FROM Inserted);
 UPDATE SaleOrder
 SET OrderAmountBeforeTax = @Amount
 WHERE OrderID = (SELECT OrderID FROM Inserted)
END


--solution
/* Write a trigger to put the total sale order amount before tax
 (unit price * quantity for all items included in an order) 
 in the OrderAmountBeforeTax column of SaleOrder. */


CREATE TRIGGER UpdateOrderAmount
    ON SaleOrderDetail
    FOR INSERT, UPDATE, DELETE
AS
BEGIN
   SET NOCOUNT ON;

   declare @oid int, @total int;

   select @oid = isnull(i.OrderID, d.OrderID)
          from inserted i full join deleted d
          ON i.OrderID = d.OrderID and i.ProductID = d.ProductID;

   select @total = sum(UnitPrice*Quantity)
          from SaleOrderDetail
		  where OrderID = @oid;

   UPDATE SaleOrder SET OrderAmountBeforeTax = @total
          WHERE OrderID = @oid;
END
