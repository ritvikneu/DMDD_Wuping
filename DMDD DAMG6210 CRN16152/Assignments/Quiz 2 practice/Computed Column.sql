use AdventureWorks2008R2;

/* How to Create Computed Colimns */
-- Example 1
-- Create a demo table with a computed column
CREATE TABLE dbo.ProductDemo
(
    ProductID INT IDENTITY (1,1) NOT NULL
  , QtyAvailable SMALLINT
  , UnitPrice MONEY
  , InventoryValue AS QtyAvailable * UnitPrice
);
-- Insert some data into the table
INSERT INTO dbo.ProductDemo (QtyAvailable, UnitPrice)
VALUES (25, 2.00), (10, 1.5);
-- See what the computed column looks like
SELECT ProductID, QtyAvailable, UnitPrice, InventoryValue
FROM dbo.ProductDemo;
-- Clean up what we just created
DROP TABLE dbo.ProductDemo;
-- Example 2
-- Create a function
go
CREATE FUNCTION fn_CalcPurchase_v2(@CustID INT)
RETURNS MONEY
AS
   BEGIN
      DECLARE @total MONEY =
         (SELECT SUM(Totaldue)
          FROM Sales.SalesOrderHeader
          WHERE CustomerID =@CustID);
      SET @total = ISNULL(@total, 0);
      RETURN @total;
END
go
-- Add a computed column to the Sales.Customer
ALTER TABLE Sales.Customer
ADD TotalPurchase AS (dbo.fn_calcPurchase_v2(CustomerID));
-- See what the computed column looks like
SELECT TOP 10 *
FROM AdventureWorks2008R2.Sales.Customer
WHERE TotalPurchase > 0
ORDER BY TotalPurchase DESC;
-- Clean up what we just created
-- Must drop the computed column before dropping the function
ALTER TABLE Sales.Customer DROP COLUMN TotalPurchase;
DROP FUNCTION dbo.fn_CalcPurchase_v2;


---------------------AGE column--------------------------------------

-- Create a table with a computed column for age
USE Demo;
-- Create the table
-- Pay attention to how the Age column is defined
CREATE TABLE PersonnelData
(PersonnelID int IDENTITY Primary Key,
 LastName varchar(50),
 FirstName varchar(50),
 DateOfBirth Date,
 Age AS DATEDIFF(hour,DateOfBirth,GETDATE())/8766);
-- There are 8,766 hours for a year because there is a leap yaer every four years
SELECT (365*4+1)*24/4; 
-- 8766
-- Put some data in the table
INSERT INTO PersonnelData
Values ('Smith' , 'Mary' , '01-02-1990') ,
       ('Black' , 'Peter' , '02-02-1988') ,
   ('Glory' , 'Rob' , '05-11-1991');
-- See what we got in the table
-- Pay attention to the computed Age column
SELECT * FROM PersonnelData;
-- Do housekeeping
DROP TABLE PersonnelData;



