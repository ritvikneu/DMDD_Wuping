

-- Lab 5-1

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


-- Lab 5-2

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


-- Lab 5-3

create function ufLookUpFine (@StID int)
returns money
begin
   declare @amt money;
   select @amt = sum(Amount)
      from Fine
      where StudentID = @StID and PaidDate is null;
   return @amt;
end

alter table Enrollment add CONSTRAINT ckfine CHECK (dbo.ufLookUpFine (StudentID) = 0);


-- Lab 5-4

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




