CREATE TABLE [SalesLT].[VendorPurchaseOrders] (
    [PurchaseOrderID] INT          IDENTITY (1, 1) NOT NULL,
    [VendorID]        INT          NOT NULL,
    [ProductID]       INT          NOT NULL,
    [OrderDate]       DATETIME     NOT NULL,
    [Quantity]        INT          DEFAULT ((1)) NULL,
    [TotalPrice]      MONEY        NOT NULL,
    [Status]          VARCHAR (50) NULL,
    PRIMARY KEY CLUSTERED ([PurchaseOrderID] ASC),
    CONSTRAINT [FK_ProductID] FOREIGN KEY ([ProductID]) REFERENCES [SalesLT].[Product] ([ProductID]),
    CONSTRAINT [FK_VendorID] FOREIGN KEY ([VendorID]) REFERENCES [SalesLT].[Vendor] ([VendorID])
);


GO

CREATE NONCLUSTERED INDEX [IX_VendorPurchaseOrders_VendorID_OrderDate]
    ON [SalesLT].[VendorPurchaseOrders]([VendorID] ASC, [OrderDate] ASC)
    INCLUDE([TotalPrice], [Status]);


GO

CREATE NONCLUSTERED INDEX [IX_VendorPurchaseOrders_OrderDate]
    ON [SalesLT].[VendorPurchaseOrders]([OrderDate] ASC) WHERE ([Status]='Pending');


GO

