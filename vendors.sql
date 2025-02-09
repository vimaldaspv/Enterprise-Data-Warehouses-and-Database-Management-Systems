CREATE DATABASE Vendor;
USE Vendor;

-- Create tables
-- Table for suppliers
CREATE TABLE VendorInfo (
    VendorID INT AUTO_INCREMENT PRIMARY KEY,
    VendorName VARCHAR(100) NOT NULL,
    ContactDetails VARCHAR(255)
);

-- Table for products
CREATE TABLE Inventory (
    ItemID INT AUTO_INCREMENT PRIMARY KEY,
    ItemName VARCHAR(255) NOT NULL,
    Category VARCHAR(100),
    Description TEXT
);

-- Table for product-vendor relationships with pricing
CREATE TABLE InventoryVendors (
    InventoryVendorID INT AUTO_INCREMENT PRIMARY KEY,
    ItemID INT NOT NULL,
    VendorID INT NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (ItemID) REFERENCES Inventory(ItemID),
    FOREIGN KEY (VendorID) REFERENCES VendorInfo(VendorID)
);

-- Table for customers
CREATE TABLE ClientInfo (
    ClientID INT AUTO_INCREMENT PRIMARY KEY,
    FullName VARCHAR(100),
    EmailAddress VARCHAR(100) UNIQUE,
    MembershipStatus BOOLEAN NOT NULL DEFAULT FALSE
);

-- Table for client orders
CREATE TABLE ClientOrders (
    OrderID INT AUTO_INCREMENT PRIMARY KEY,
    ClientID INT NOT NULL,
    OrderDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    OrderStatus ENUM('Complete', 'Incomplete') DEFAULT 'Incomplete',
    TotalAmount DECIMAL(10, 2),
    FOREIGN KEY (ClientID) REFERENCES ClientInfo(ClientID)
);

-- Table for order details
CREATE TABLE OrderItems (
    OrderItemID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL,
    InventoryVendorID INT NOT NULL,
    Quantity INT NOT NULL,
    SubTotal DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES ClientOrders(OrderID),
    FOREIGN KEY (InventoryVendorID) REFERENCES InventoryVendors(InventoryVendorID)
);

-- Table for customer feedback (reviews and time spent)
CREATE TABLE ClientFeedback (
    FeedbackID INT AUTO_INCREMENT PRIMARY KEY,
    ClientID INT NOT NULL,
    ItemID INT NOT NULL,
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    ReviewText TEXT,
    TimeSpentMinutes INT NOT NULL,
    FOREIGN KEY (ClientID) REFERENCES ClientInfo(ClientID),
    FOREIGN KEY (ItemID) REFERENCES Inventory(ItemID)
);

-- Table for additional costs
CREATE TABLE ExtraCharges (
    ChargeID INT AUTO_INCREMENT PRIMARY KEY,
    ChargeType ENUM('Delivery Failure', 'Re-Attempt', 'Return Fraud'),
    ChargeAmount DECIMAL(10, 2) NOT NULL,
    OrderID INT,
    FOREIGN KEY (OrderID) REFERENCES ClientOrders(OrderID)
);

-- Table for vendor commissions
CREATE TABLE VendorCommissions (
    CommissionID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL,
    VendorID INT NOT NULL,
    CommissionRate DECIMAL(5, 2) NOT NULL,
    TotalCommission DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES ClientOrders(OrderID),
    FOREIGN KEY (VendorID) REFERENCES VendorInfo(VendorID)
);

DELIMITER //

CREATE TRIGGER BeforeInsertClientFeedback
BEFORE INSERT ON ClientFeedback
FOR EACH ROW
BEGIN
    -- Ensure the rating is between 1 and 5
    IF NEW.Rating < 1 OR NEW.Rating > 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid Rating: Rating must be between 1 and 5.';
    END IF;

    -- Ensure the TimeSpentMinutes is positive
    IF NEW.TimeSpentMinutes <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid TimeSpentMinutes: Must be greater than 0.';
    END IF;

    -- Ensure ClientID exists in ClientInfo table
    IF NOT EXISTS (SELECT 1 FROM ClientInfo WHERE ClientID = NEW.ClientID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid ClientID: Client does not exist.';
    END IF;

    -- Ensure ItemID exists in Inventory table
    IF NOT EXISTS (SELECT 1 FROM Inventory WHERE ItemID = NEW.ItemID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid ItemID: Item does not exist.';
    END IF;
END;
//

DELIMITER ;

-- Insert 100 vendors into the VendorInfo table
INSERT INTO VendorInfo (VendorName, ContactDetails)
SELECT 
    CONCAT('Vendor ', id) AS VendorName,
    CONCAT('contact', id, '@vendor.com') AS ContactDetails
FROM 
    (SELECT @rownum := @rownum + 1 AS id FROM INFORMATION_SCHEMA.COLUMNS, (SELECT @rownum := 0) AS Init LIMIT 100) AS Temp;

-- Insert 1000 items into the Inventory table
INSERT INTO Inventory (ItemName, Category, Description)
SELECT 
    CONCAT('Item ', id) AS ItemName,
    CONCAT('Category ', FLOOR(RAND() * 10) + 1) AS Category,
    CONCAT('Description for Item ', id) AS Description
FROM 
    (SELECT @rownum := @rownum + 1 AS id FROM INFORMATION_SCHEMA.COLUMNS, (SELECT @rownum := 0) AS Init LIMIT 1000) AS Temp;

-- Insert inventory-vendor relationships with pricing into the InventoryVendors table
INSERT INTO InventoryVendors (ItemID, VendorID, Price)
SELECT 
    FLOOR(RAND() * 1000) + 1 AS ItemID,
    FLOOR(RAND() * 100) + 1 AS VendorID,
    ROUND(RAND() * 500, 2) AS Price
FROM 
    (SELECT @rownum := @rownum + 1 AS id FROM INFORMATION_SCHEMA.COLUMNS, (SELECT @rownum := 0) AS Init LIMIT 1000) AS Temp;

-- Insert 1000 clients into the ClientInfo table
INSERT INTO ClientInfo (FullName, EmailAddress, MembershipStatus)
SELECT 
    CONCAT('Client ', id) AS FullName,
    CONCAT('client', id, '@example.com') AS EmailAddress,
    FLOOR(RAND() * 2) AS MembershipStatus
FROM 
    (SELECT @rownum := @rownum + 1 AS id FROM INFORMATION_SCHEMA.COLUMNS, (SELECT @rownum := 0) AS Init LIMIT 1000) AS Temp;

-- Insert 10,000 orders into the ClientOrders table
INSERT INTO ClientOrders (ClientID, OrderDate, OrderStatus, TotalAmount)
SELECT 
    ClientID,
    NOW() - INTERVAL FLOOR(RAND() * 365) DAY AS OrderDate,
    IF(FLOOR(RAND() * 2) = 0, 'Complete', 'Incomplete') AS OrderStatus,
    ROUND(RAND() * 100, 2) AS TotalAmount
FROM 
    (SELECT ClientID FROM ClientInfo LIMIT 100) AS ValidClients
CROSS JOIN 
    (SELECT @rownum := @rownum + 1 AS id FROM INFORMATION_SCHEMA.COLUMNS, (SELECT @rownum := 0) AS Init LIMIT 10000) AS Temp;

-- Insert random order details into the OrderItems table
INSERT INTO OrderItems (OrderID, InventoryVendorID, Quantity, SubTotal)
SELECT 
    OrderID,
    FLOOR(RAND() * (SELECT COUNT(*) FROM InventoryVendors)) + 1 AS InventoryVendorID,
    FLOOR(RAND() * 10) + 1 AS Quantity,
    ROUND(RAND() * 100, 2) AS SubTotal
FROM 
    ClientOrders
LIMIT 100;

-- Insert random client feedback (reviews) into the ClientFeedback table
INSERT INTO ClientFeedback (ClientID, ItemID, Rating, ReviewText, TimeSpentMinutes)
SELECT 
    ClientID,
    FLOOR(RAND() * 100) + 1 AS ItemID,
    FLOOR(RAND() * 5) + 1 AS Rating,
    CONCAT('Review for Item ', FLOOR(RAND() * 100) + 1) AS ReviewText,
    FLOOR(RAND() * 60) + 1 AS TimeSpentMinutes
FROM 
    ClientInfo
CROSS JOIN 
    (SELECT @rownum := @rownum + 1 AS id FROM INFORMATION_SCHEMA.COLUMNS, (SELECT @rownum := 0) AS Init LIMIT 100) AS Temp;

-- Insert 100 random extra charges at a time
INSERT INTO ExtraCharges (ChargeType, ChargeAmount, OrderID)
SELECT 
    CASE 
        WHEN FLOOR(RAND() * 3) = 0 THEN 'Delivery Failure'
        WHEN FLOOR(RAND() * 2) = 0 THEN 'Re-Attempt'
        ELSE 'Return Fraud'
    END AS ChargeType,
    ROUND(RAND() * 100, 2) AS ChargeAmount,
    OrderID
FROM 
    ClientOrders
LIMIT 100;

-- Insert 100 rows into VendorCommissions at a time
INSERT INTO VendorCommissions (OrderID, VendorID, CommissionRate, TotalCommission)
SELECT 
    OrderID,
    (SELECT VendorID FROM VendorInfo ORDER BY RAND() LIMIT 1) AS VendorID,
    ROUND(RAND() * 10, 2) AS CommissionRate,
    ROUND(RAND() * 1000, 2) AS TotalCommission
FROM 
    ClientOrders
LIMIT 100;


-- Query 1: Retrieve all orders and the corresponding product information from each vendor.
SELECT 
    o.OrderID,
    o.OrderDate,
    o.OrderStatus,
    i.ItemName,
    v.VendorName,
    iv.Price
FROM 
    ClientOrders o
INNER JOIN 
    OrderItems oi ON o.OrderID = oi.OrderID
INNER JOIN 
    InventoryVendors iv ON oi.InventoryVendorID = iv.InventoryVendorID
INNER JOIN 
    VendorInfo v ON iv.VendorID = v.VendorID
INNER JOIN 
    Inventory i ON iv.ItemID = i.ItemID
WHERE 
    o.OrderStatus = 'Complete';


-- Query 2: Count of feedback submissions per product (ItemID), grouped by rating.
SELECT 
    f.ItemID,
    f.Rating,
    COUNT(f.FeedbackID) AS FeedbackCount
FROM 
    ClientFeedback f
GROUP BY 
    f.ItemID, f.Rating
ORDER BY 
    f.ItemID, f.Rating DESC;

-- Query 3: Retrieve the average price of products supplied by each vendor.
SELECT 
    v.VendorName,
    AVG(iv.Price) AS AveragePrice
FROM 
    VendorInfo v
INNER JOIN 
    InventoryVendors iv ON v.VendorID = iv.VendorID
GROUP BY 
    v.VendorName
HAVING 
    AVG(iv.Price) > 50;


-- Query 4 : Find the highest order total for each client.
SELECT 
    ClientID,
    OrderID,
    TotalAmount
FROM (
    SELECT 
        ClientID,
        OrderID,
        TotalAmount,
        ROW_NUMBER() OVER (PARTITION BY ClientID ORDER BY TotalAmount DESC) AS RowNum
    FROM 
        ClientOrders
) AS RankedOrders
WHERE 
    RowNum = 1;


DELIMITER $$

CREATE PROCEDURE month_report(IN report_month VARCHAR(7))
BEGIN
    -- Declare variables to store revenue, costs, commissions, and profit
    DECLARE total_revenue DECIMAL(10, 2);
    DECLARE total_extra_costs DECIMAL(10, 2);
    DECLARE total_commissions DECIMAL(10, 2);
    DECLARE total_profit DECIMAL(10, 2);

    -- Calculate total revenue from completed orders
    SELECT 
        SUM(oi.Quantity * iv.Price) 
    INTO total_revenue
    FROM ClientOrders co
    JOIN OrderItems oi ON co.OrderID = oi.OrderID
    JOIN InventoryVendors iv ON oi.InventoryVendorID = iv.InventoryVendorID
    WHERE co.OrderStatus = 'Complete'
    AND DATE_FORMAT(co.OrderDate, '%Y-%m') = report_month;

    -- Calculate total extra costs
    SELECT 
        IFNULL(SUM(ec.ChargeAmount), 0)
    INTO total_extra_costs
    FROM ExtraCharges ec
    JOIN ClientOrders co ON ec.OrderID = co.OrderID
    WHERE DATE_FORMAT(co.OrderDate, '%Y-%m') = report_month;

    -- Calculate total vendor commissions
    SELECT 
        IFNULL(SUM(vc.TotalCommission), 0)
    INTO total_commissions
    FROM VendorCommissions vc
    JOIN ClientOrders co ON vc.OrderID = co.OrderID
    WHERE DATE_FORMAT(co.OrderDate, '%Y-%m') = report_month;

    -- Calculate total profit
    SET total_profit = total_revenue - (total_extra_costs + total_commissions);

    -- Output the results
    SELECT 
        total_revenue AS Revenue,
        total_extra_costs AS ExtraCosts,
        total_commissions AS Commissions,
        total_profit AS Profit;
END $$

DELIMITER ;


-- Call the stored procedure for December 2024
CALL month_report('2024-12');



