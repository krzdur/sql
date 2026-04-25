CREATE TABLE [SalesLT].[VendorPriceHistory] (
    [QuoteID]   BIGINT   NULL,
    [VendorID]  INT      NOT NULL,
    [ProductID] INT      NOT NULL,
    [Price]     MONEY    NOT NULL,
    [QuoteDate] DATETIME NOT NULL
);


GO

CREATE CLUSTERED INDEX [CIX_VendorPriceHistory_VendorID_ProductID_Price]
    ON [SalesLT].[VendorPriceHistory]([VendorID] ASC, [ProductID] ASC, [Price] ASC) WITH (FILLFACTOR = 75);


GO

CREATE NONCLUSTERED INDEX [IX_VendorPriceHistory_ProductID]
    ON [SalesLT].[VendorPriceHistory]([ProductID] ASC)
    INCLUDE([Price], [QuoteDate]) WITH (FILLFACTOR = 75);


GO

