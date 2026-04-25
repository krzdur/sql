-- =============================================
-- Krzysztof
-- Durbajło
-- 239869
-- =============================================

-- =============================================
-- Zadanie 1
-- =============================================

/*--------- SalesLT.Vendor ---------
Tabela ma już indeks klastrowy (PK).
Tworzymy indeks nieklastrowy dla AccountNumber, bo to unikalny
identyfikator dostawcy, który może być używany do wyszukiwania.
*/
create unique nonclustered index IX_Vendor_AccountNumber
on SalesLT.Vendor (AccountNumber);
go

/*--------- SalesLT.ProductVendor ---------
W tabeli brakuje klucza podstawowego i zarazem indeksu klastrowego.
To tabela łącząca między produktami i dostawcami (relacja wiele do wielu),
więc najlepiej jest utworzyć klucz złożony.
*/
create clustered index CIX_ProductVendor_ProductID_VendorID
on SalesLT.ProductVendor (ProductID, VendorID)
go

/*--------- SalesLT.ProductBOM ---------
BOMID nie nadaje się na indeks klastrowy, bo jest nullowalny
i nie jest unikalny. Dlatego tworzymy złożony indeks klastrowy
*/
create clustered index CIX_ProductBOM_ParentProductID_ComponentProductID
on SalesLT.ProductBOM (ParentProductID, ComponentProductID);
go

/*--------- SalesLT.VendorPriceHistory ---------
Tabela przechowuje historię zmian cen, więc tylko zestaw
VendorID-ProductID-QuoteDate jest unikalny, dlatego dla niego
tworzymy indeks klastrowy.
*/
create clustered index CIX_VendorPriceHistory_VendorID_ProductID_Price
on SalesLT.VendorPriceHistory (VendorID, ProductID, Price);
go

/*--------- SalesLT.ShipmentTrackingEvents ---------
Historia dostawy dla zamówienia, więc najczęściej wyszukiwane będzie konkretne
zamówienie. Tylko SalesOrderID-EventDate jest unikalne, więc taki tworzymy indeks
klastrowy.
*/
create clustered index CIX_ShipmentTrackingEvents_SalesOrderID_EventDate
on SalesLT.ShipmentTrackingEvents (SalesOrderID, EventDate);
go

-- =============================================
-- Zadanie 2
-- =============================================
create nonclustered index IX_Vendor_Active_Name_AccountNumber
on SalesLT.Vendor (Name, AccountNumber)
where ActiveFlag = 1;

go
-- =============================================
-- Zadanie 3
-- =============================================

/*--------- SalesLT.ProductBOM: ZWYKŁY INDEKS NIEKLASTROWY ---------
W tabeli mamy już indeks złożony, w którym ParentProductID jest pierwszym identyfikatorem
(rekordy będą sortowane wg tego identyfikatora). Dlatego dla wyszukiwań wg. ComponentProductID
dodajemy indeks na tym polu
*/
create nonclustered index IX_ProductBOM_ComponentProductID
on SalesLT.ProductBOM (ComponentProductID);
go

/*--------- SalesLT.VendorPriceHistory: INDEKS POKRYWAJĄCY ---------
Przyjmujemy, że tabela będzie używany do wyszukiwania historii cen
konkretnego produktu, dlatego dodajemy indeks z kolumnami dołączonymi.
*/
create nonclustered index IX_VendorPriceHistory_ProductID
on SalesLT.VendorPriceHistory (ProductID)
include (Price, QuoteDate);
go

/*--------- SalesLT.Vendor: INDEKS FILTRUJĄCY ---------
Do łatwego wyszukiwania najlepiej ocenianych dostawców.
*/
create nonclustered index IX_Vendor_TopRated
on SalesLT.Vendor (Name, AccountNumber)
where CreditRating = 1;
go

-- =============================================
-- Zadanie 4
-- =============================================
alter index all on SalesLT.VendorPriceHistory
rebuild with (fillfactor = 75)
go

-- =============================================
-- Zadanie 5
-- =============================================

/*--------- SalesLT.VendorPurchaseOrders ---------
Tabela będzie zawierać zamówienia komponentów od dostawców.
*/
create table SalesLT.VendorPurchaseOrders (
    PurchaseOrderID int identity(1,1) primary key ,   -- tworzy indeks klastrowy
    VendorID int not null,
    ProductID int not null ,
    OrderDate datetime not null,
    Quantity int default 1,
    TotalPrice money not null,
    Status varchar(50),
    constraint FK_VendorID foreign key (VendorID) references SalesLT.Vendor(VendorID),
    constraint FK_ProductID foreign key (ProductID) references SalesLT.Product(ProductID)
);
go

-- 1. Indeks klastrowy utworzony na PurchaseOrderID

-- 2. Indeks nieklastrowy pokrywający - do wyszukiwania wszystkich zamówień dla dostawcy z kosztem i statusem
create nonclustered index IX_VendorPurchaseOrders_VendorID_OrderDate
on SalesLT.VendorPurchaseOrders(VendorID, OrderDate)
include (TotalPrice, Status);
go

-- 3. Indeks nieklastrowy filtrujący - do znajdowania zamówień ze statusem Pending
create nonclustered index IX_VendorPurchaseOrders_OrderDate
on SalesLT.VendorPurchaseOrders(OrderDate)
where Status = 'Pending';
go
