
-- Question 3 (6 points)

/* In an investment company, bonuses are handed out to the top-performing
   employees every quarter. There is a business rule that no employee can
   be granted more than a total of $200,000 as bonuses per year and a single
   bonus can't exceed $50,000. Any attempt to give an employee more than 
   $200,000 for bonuses in a year and/or a single bonus more than $50,000
   must be logged in an audit table and the violating bonus is not allowed.

   Given the following 3 tables, please write a trigger to implement
   the business rule. The rule must be enforced every year automatically.
   Assume only one bonus is entered in the database at a time.
   You can just consider the INSERT scenarios.
*/

create table Employee
(EmployeeID int primary key,
 EmpLastName varchar(50),
 EmpFirstName varchar(50),
 DepartmentID smallint);

create table Bonus
(BonusID int identity primary key,
 BonusAmount int,
 BonusDate date NOT NULL,
 EmployeeID int NOT NULL REFERENCES Employee(EmployeeID));

create table BonusAudit  -- Audit Table
(AuditID int identity primary key,
 EnteredBy varchar(50) default original_login(),
 EnterTime datetime default getdate(),
 EnteredAmount int not null,
 EmployeeID int NOT NULL REFERENCES Employee(EmployeeID));
 
 go
 create trigger insertTrigger on dbo.Bonus
 INSTEAD OF INSERT AS
 BEGIN
 DECLARE @Bonus int = 0;
 SET @Bonus =  (select BonusAmount from inserted);
	IF @Bonus > 50000
	BEGIN
	INSERT INTO BonusAudit (EnteredAmount,EmployeeID) VALUES (@Bonus,(select EmployeeID from inserted))
	END
	IF @Bonus > 50000
	BEGIN
		RAISERROR ('BONUS IS GREATER THAN LIMIT', 16, 1);
	END;

	DECLARE @yearBonus int = 0;
	set @yearBonus = (select sum(BonusAmount) from dbo.Bonus where (EmployeeID = (select EmployeeID from inserted)) AND (DATEPART(year,BonusDate) = DATEPART(year,(select BonusDate from inserted))));
	IF @yearBonus > 200000
	BEGIN
	INSERT INTO BonusAudit (EnteredAmount,EmployeeID) VALUES (@Bonus,(select EmployeeID from inserted))
	END
	IF @yearBonus > 200000
	BEGIN
		RAISERROR ('BONUS IS GREATER THAN YEARLY LIMIT', 16, 1);
		RETURN 
	END;
	IF @Bonus <= 50000 AND @yearBonus <= 200000
	BEGIN
	INSERT INTO dbo.Bonus(BonusAmount,BonusDate,EmployeeID) values ((select BonusAmount from inserted),(select BonusDate from inserted),(select EmployeeID from inserted));
	END
 END


--trigger to add chargedhours when employee is inserted 
GO
ALTER TRIGGER [dbo].[calculateClientCH] ON [dbo].[Employee]
AFTER INSERT AS
BEGIN
 DECLARE @chargedhours float = 0;
 
 SET @chargedhours = (SELECT ChargedHours from Employee where EmployeeID = (SELECT EmployeeID FROM Inserted));

 DECLARE @existing float = 0;
 SET @existing = 
 (SELECT ChargedHours from Client where ClientID = (SELECT ClientID from Project where ProjectID = (select ProjectID FROM Inserted))); 
 UPDATE Client
 SET ChargedHours = @chargedhours + @existing
 WHERE ClientID = (SELECT ClientID from Project where ProjectID = (select ProjectID FROM Inserted));
END
go

------------------------------------------

-- Use SQL TRIGGER to implement business rules
-- Create a demo database
CREATE DATABASE Flight;
-- Switch to the new database
USE Flight;
-- Create demo tables 
CREATE TABLE Reservation (PassengerName varchar(30), FlightNo smallint, FlightDate date);
CREATE TABLE Behavior (PassengerName varchar(30), BehaviorType varchar(20), 
BehaviorDate date);
/* If a passenger has ever had any previuos abusive behavior, 
   don't allow the passenger to make a reservation again. */

-- Create TRIGGER to implement the business rule
CREATE TRIGGER TR_CheckBehavior
ON dbo.Reservation
AFTER INSERT AS 
BEGIN
   DECLARE @Count smallint=0;
   SELECT @Count = COUNT(PassengerName) 
      FROM Behavior
      WHERE PassengerName = (SELECT PassengerName FROM Inserted)
      AND BehaviorType = 'Abusive';
   IF @Count > 0 
      BEGIN
     Rollback;
      END
END;
-- Put some data in the new tables
INSERT INTO Behavior (PassengerName, BehaviorType, BehaviorDate)
VALUES ('Mary', 'Helpful', '08-10-2012'),
       ('Peter', 'Abusive', '4-13-2014');
INSERT INTO Reservation (PassengerName, FlightNo, FlightDate)
VALUES ('Mary', 12, '12-20-2015');
INSERT INTO Reservation (PassengerName, FlightNo, FlightDate)
VALUES ('Peter', 33, '12-30-2015');
-- See what we have in Reservation
SELECT * FROM Reservation;
-- Do housekeeping
USE MASTER;
DROP DATABASE Flight;