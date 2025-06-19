-- Question 2 :

CREATE TABLE Customer (
    customerId INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(100) NOT NULL
);
GO

CREATE TABLE Address (
    addressId INT PRIMARY KEY IDENTITY(1,1),
    city NVARCHAR(100) NOT NULL,
    postalCode NVARCHAR(10) NOT NULL
);
GO

CREATE TABLE CustomerAddressMapping (
    customerId INT CONSTRAINT FK_CustomerAddressMapping_Customer FOREIGN KEY REFERENCES Customer(customerId),
    addressId INT CONSTRAINT FK_CustomerAddressMapping_Address FOREIGN KEY REFERENCES Address(addressId),
    PRIMARY KEY (customerId, addressId)
);
GO

CREATE TABLE Products (
    productId INT PRIMARY KEY IDENTITY(101,1),
    productName NVARCHAR(100) NOT NULL,
	unitPrice DECIMAL(10,2)
);
GO

CREATE TABLE Orders (
    orderId INT PRIMARY KEY IDENTITY(1001,1),
    customerId INT CONSTRAINT FK_Orders_Customer FOREIGN KEY REFERENCES Customer(customerId),
    orderDate DATE NOT NULL,
    totalAmount DECIMAL(10, 2)
);
GO

CREATE TABLE OrderDetails (
    orderId INT CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY REFERENCES Orders(orderId),
    productId INT CONSTRAINT FK_OrderDetails_Products FOREIGN KEY REFERENCES Products(productId),
    quantity INT NOT NULL CHECK (quantity > 0),
);
GO


-- Question 3 :

SELECT customerId
FROM Orders
WHERE orderDate >= DATEFROMPARTS(YEAR(GETDATE()), MONTH(DATEADD(MONTH, -5, GETDATE())), 1)
GROUP BY customerId
HAVING COUNT(DISTINCT DATEFROMPARTS(YEAR(orderDate), MONTH(orderDate), 1)) = 6;

-- Question 6 :

SELECT 
    s.productId,
    s.salesDate,
    s.amount,
    (
        SELECT AVG(s2.amount)
        FROM Sales s2
        WHERE s2.productId = s.productId
          AND s2.salesDate <= s.salesDate 
          AND s2.salesDate >= DATEADD(DAY, -6, s.salesDate)
    ) AS Rolling7DayAvg
FROM Sales s
ORDER BY s.productId, s.salesDate;

-- Question 8 :

CREATE FUNCTION dbo.GetInactiveCustomers
(
    @Months INT -- number of months to check
)
RETURNS TABLE
AS
RETURN
(
    SELECT c.customerId, c.name
    FROM Customer c
    WHERE NOT EXISTS (
        SELECT 1
        FROM Orders o
        WHERE o.customerId = c.customerId
          AND o.orderDate >= DATEADD(MONTH, -@Months, GETDATE())
    )
);


-- Question 10 :

CREATE FUNCTION dbo.Square
(
    @Value INT
)
RETURNS INT
WITH SCHEMABINDING
AS
BEGIN
    RETURN @Value * @Value
END;


-- Question 9 :

CREATE VIEW dbo.vw_LastOrders
AS
WITH OrderCount AS (
    SELECT customerId, MAX(orderDate) AS LastOrderDate
    FROM Orders
    GROUP BY customerId
    HAVING COUNT(*) > 5
)
SELECT 
    o.customerId,
    o.orderId,
    o.orderDate,
    o.totalAmount
FROM OrderCount v
JOIN Orders o 
    ON o.customerId = v.customerId
   AND o.orderDate = v.LastOrderDate;

-- question 11 :

CREATE TRIGGER trg_PreventExcessivePriceDrop
ON Products
AFTER UPDATE
AS
BEGIN
    DECLARE @oldPrice DECIMAL(10,2);
    DECLARE @newPrice DECIMAL(10,2);
    DECLARE @productId INT;
    DECLARE @priceDropPercent DECIMAL(5,2);

    -- Get values from inserted/deleted (assuming only 1 row is updated)
    SELECT 
        @productId = i.productId,
        @oldPrice = d.unitPrice,
        @newPrice = i.unitPrice
    FROM inserted i
    JOIN deleted d ON i.productId = d.productId;

    -- Prevent division by zero
    IF @oldPrice > 0
    BEGIN
        SET @priceDropPercent = ((@oldPrice - @newPrice) * 100.0) / @oldPrice;

        IF @priceDropPercent > 20
        BEGIN
            RAISERROR(
                'ProductId %d: Price drop of %.2f%% exceeds allowed 20%% limit.',
                16, 1, @productId, @priceDropPercent
            );
            ROLLBACK TRANSACTION;
        END
    END
END;





-- Set your target manager ID here
DECLARE @ManagerId INT = 101; -- Example: Manager with ID 101

WITH EmployeeHierarchy AS (
    -- Anchor member: Direct reports
    SELECT 
        EmployeeId,
        Name,
        ManagerId
    FROM Employees
    WHERE ManagerId = @ManagerId

    UNION ALL

    -- Recursive member: Indirect reports
    SELECT 
        e.EmployeeId,
        e.Name,
        e.ManagerId
    FROM Employees e
    INNER JOIN EmployeeHierarchy eh ON e.ManagerId = eh.EmployeeId
)
SELECT * FROM EmployeeHierarchy;
