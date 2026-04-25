
IF OBJECT_ID('SalesLT.Vendor', 'U') IS NOT NULL
    DROP TABLE SalesLT.Vendor;
GO
CREATE TABLE SalesLT.Vendor (
    VendorID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    AccountNumber NVARCHAR(20) NOT NULL,
    CreditRating TINYINT NOT NULL, -- 1 do 5
    ActiveFlag BIT DEFAULT 1
);

IF OBJECT_ID('SalesLT.ProductVendor', 'U') IS NOT NULL
    DROP TABLE SalesLT.ProductVendor;
GO
CREATE TABLE SalesLT.ProductVendor (
    ProductID INT NOT NULL,
    VendorID INT NOT NULL,
    StandardPrice MONEY NOT NULL,
    AverageLeadTime INT NOT NULL, -- Czas dostawy w dniach
);

IF OBJECT_ID('SalesLT.ProductBOM', 'U') IS NOT NULL
    DROP TABLE SalesLT.ProductBOM;
GO
CREATE TABLE SalesLT.ProductBOM (
    BOMID INT,
    ParentProductID INT NOT NULL,    -- Rower
    ComponentProductID INT NOT NULL, -- Rama
    Quantity DECIMAL(18,2) DEFAULT 1.0,
    InstructionStep INT,             -- Kolejno?? monta?u
    CONSTRAINT FK_BOM_Parent FOREIGN KEY (ParentProductID) REFERENCES SalesLT.Product(ProductID),
    CONSTRAINT FK_BOM_Component FOREIGN KEY (ComponentProductID) REFERENCES SalesLT.Product(ProductID)
);
GO


IF OBJECT_ID('SalesLT.VendorPriceHistory', 'U') IS NOT NULL
    DROP TABLE SalesLT.VendorPriceHistory;
GO
CREATE TABLE SalesLT.VendorPriceHistory (
    QuoteID BIGINT,
    VendorID INT NOT NULL,
    ProductID INT NOT NULL,
    Price MONEY NOT NULL,
    QuoteDate DATETIME NOT NULL
);
GO



IF OBJECT_ID('SalesLT.ShipmentTrackingEvents', 'U') IS NOT NULL
    DROP TABLE SalesLT.ShipmentTrackingEvents;
GO
CREATE TABLE SalesLT.ShipmentTrackingEvents (
    EventID BIGINT,
    SalesOrderID INT NOT NULL, -- FK do istniej?cych zamówie?
    EventDate DATETIME NOT NULL,
    Location VARCHAR(100),
    Status VARCHAR(50),
    Notes VARCHAR(200)
);
GO


INSERT INTO SalesLT.Vendor (Name, AccountNumber, CreditRating, ActiveFlag)
SELECT TOP 500000
    'Dostawca ' + CAST(ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS NVARCHAR(10)),
    'ACT' + CAST(10000 + ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS NVARCHAR(10)),
    (ABS(CHECKSUM(NEWID())) % 5) + 1,
    1
FROM sys.all_objects a CROSS JOIN sys.all_objects b;
GO


INSERT INTO SalesLT.ProductVendor (ProductID, VendorID, StandardPrice, AverageLeadTime)
SELECT 
    p.ProductID,
    v.VendorID,
    p.ListPrice * RAND(10000) * 0.1, -- Cena zakupu to 60% ceny sprzeda?y
    (ABS(CHECKSUM(NEWID())) % 15) + 1 -- Czas dostawy 1-15 dni
FROM SalesLT.Product p
CROSS APPLY (
    -- Wybierz 10 losowych dostawców dla ka?dego produktu
    SELECT TOP 15 VendorID 
    FROM SalesLT.Vendor 
    ORDER BY NEWID()
) v;
GO


-- Generowanie milionów rekordów
INSERT INTO SalesLT.VendorPriceHistory (VendorID, ProductID, Price, QuoteDate)
SELECT 
    pv.VendorID,
    pv.ProductID,
    pv.StandardPrice * (1 + (CAST(ABS(CHECKSUM(NEWID())) % 20 AS FLOAT) - 10) / 100), -- Fluktuacja ceny +/- 10%
    DATEADD(DAY, -n.Number, GETDATE()) -- Cena z ka?dego z ostatnich 'N' dni
FROM SalesLT.ProductVendor pv
CROSS JOIN (
    SELECT TOP 1000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS Number
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
) n;
GO

INSERT INTO SalesLT.ProductBOM (ParentProductID, ComponentProductID, Quantity, InstructionStep)
SELECT 
    p_parent.ProductID,
    p_child.ProductID,
    1,
    1
FROM SalesLT.Product p_parent
CROSS JOIN SalesLT.Product p_child
WHERE p_parent.Name LIKE '%Bike%' 
  AND (p_child.Name LIKE '%Frame%' OR p_child.Name LIKE '%Wheel%')
  AND p_parent.ProductID <> p_child.ProductID;
GO




INSERT INTO SalesLT.ShipmentTrackingEvents (SalesOrderID, EventDate, Location, Status, Notes)
SELECT 
    soh.SalesOrderID,
    -- Data zdarzenia przesuni?ta wzgl?dem daty zamówienia
    DATEADD(HOUR, x.HoursOffset, soh.OrderDate),
    -- Losowa lokalizacja z listy
    x.Location,
    -- Status
    x.Status,
    -- Dodatkowa notatka
    x.Note
FROM SalesLT.SalesOrderHeader soh
CROSS JOIN (
    -- Symulujemy 5 etapów podró?y dla KA?DEGO zamówienia
    SELECT 2 AS HoursOffset, 'Magazyn Centralny' AS Location, 'Picked' AS Status, 'Skompletowano' AS Note UNION ALL
    SELECT 6, 'Magazyn Centralny', 'Shipped', 'Wydano kurierowi' UNION ALL
    SELECT 18, 'Sortownia Regionalna Wawa', 'Arrived', 'Skanowanie w sortowni' UNION ALL
    SELECT 24, 'Sortownia Regionalna Wawa', 'Departed', 'Wyjazd z sortowni' UNION ALL
    SELECT 30, 'Lokalny Oddzia?', 'OutForDelivery', 'Wydano do dor?czenia' UNION ALL
    SELECT 32, 'Adres Klienta', 'Delivered', 'Pozostawiono pod drzwiami'
) AS x