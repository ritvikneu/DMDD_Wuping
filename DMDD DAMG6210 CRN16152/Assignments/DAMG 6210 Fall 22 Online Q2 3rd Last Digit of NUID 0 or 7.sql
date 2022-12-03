
-- DAMG 6210 Fall 22 Online Q2 3rd Last Digit of NUID 0 or 7

-- Your Name:
-- Your NUID:

-- Question 1 (4 points)

/* Rewrite the following query to present the same data in a horizontal format, 
   using the SQL PIVOT command. Also, add a total column for the total of numbers
   displayed in each horizontal row, as demonstrated below. Use the sample format 
   for formatting purposes only.

   Please use AdventureWorks2008R2 for this question. */

select datepart(qq, OrderDate) Quarter,
       ProductID,
       cast(sum(UnitPrice*OrderQty) as int) as TotalSales
from Sales.SalesOrderHeader sh
join Sales.SalesOrderDetail sd
on sh.SalesOrderID =  sd.SalesOrderID
where datepart(qq, OrderDate) in (2, 4) and ProductID between 954 and 958
group by ProductID,  datepart(qq, OrderDate)
having sum(UnitPrice*OrderQty) > 200000;

/*
Quarter	954		955		956		957		958		Total
2		450446	287996	220288	450446	 		1409176
4		391464	273691	 		424007	 		1089162
*/



-- Question 2 (5 points)

/* Using AdventureWorks2008R2, write a query to retrieve the top 2 customers, 
   based on the total purchase, for each year. Use TotalDue of SalesOrderHeader 
   to calculate the total purchase. The top 2 customers have the two highest 
   total purchase amounts in the year. If there is a tie your solution needs 
   to retrieve the tie. Return only the top 2 customers who have also purchased 
   more than 65 unique products in the same year.
   
   Return the data in the following format. The 5-digit number is the customer id.
   The email address is the customer's email address. The number after "Unique Products:" 
   is the number of unique products.
   
   Sort the returned data by the year. Use the format below only for formatting purposes.
*/

/*
Year	Top2Customers
2006	29614  ryan1@adventure-works.com Unique Products: 74, 29716  blaine0@adventure-works.com Unique Products: 68
2007	29913  anton0@adventure-works.com Unique Products: 86
*/



-- Question 3 (6 points)

/* 
Given 3 tables listed below for operating seminars, there is a business rule
about the seminar registration fees.

Here is the rule:
a) The first client that signs up for a seminar can attend the seminar for free
b) After the first attendant, the next 9 attendants (from the 2nd to the 10th) 
   only need to pay 50% of the regular registration fee
c) All other attendants after the 10th attendant will pay the regular 
   registration fee

The registration is processed one attendant at a time. You don't need to consider
cancellation. Only an active seminar can accept registration. An active seminar
has the value "Active" in the status column.

Please write an AFTER trigger to accept registration and implement the business 
rule.   
*/

CREATE TABLE Client
(ClientID INT PRIMARY KEY,
 LastName VARCHAR(50),
 FirsName VARCHAR(50),
 Email VARCHAR(30),
 Phone VARCHAR(20));

CREATE TABLE Seminar
(SeminarID INT PRIMARY KEY,
 Name VARCHAR(50),
 Description VARCHAR(500),
 StartDate DATE,
 Fee MONEY,
 EndDate DATE,
 Status VARCHAR(10));

CREATE TABLE Registration
(ClientID INT REFERENCES Client(ClientID),
 SeminarID INT REFERENCES Seminar(SeminarID),
 PaidFee MONEY,
 Notes VARCHAR(1000)
 PRIMARY KEY (ClientID, SeminarID));



