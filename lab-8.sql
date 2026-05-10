-- =============================================
-- Krzysztof
-- Durbajło
-- 239869
-- =============================================

-- =============================================
-- Zadanie 1
-- =============================================
create table SalesLT.ProductPriceHistory
(
    ProductPriceChangeID int identity (1,1) primary key,
    ProductID            int not null,
    ListPriceOld         money,
    ListPriceNew         money
);

go;

create trigger SalesLT.trg_Product_Price_History
    on SalesLT.Product
    after update
    as
begin
    set nocount on;

    if exists(select 1
              from deleted d
                       join inserted i on d.ProductID = i.ProductId
              where d.ListPrice <> i.ListPrice)
        begin
            insert into SalesLT.ProductPriceHistory (ProductID, ListPriceOld, ListPriceNew)
            select d.ProductID, d.ListPrice, i.ListPrice
            from deleted d
                     join inserted i on d.ProductID = i.ProductID
            where d.ListPrice <> i.ListPrice
        end

end;

go;

-- =============================================
-- Zadanie 2
-- =============================================
create table SalesLT.DeletedCustomersLog
(
    CustomerDeletionID int identity (1,1) primary key,
    CustomerID         int,
    Title              nvarchar(6),
    FirstName          nvarchar(50),
    MiddleName         nvarchar(50),
    LastName           nvarchar(50),
    DeletedAt          datetime default getdate()
);

go;

/*
 Trigger musi obsługiwać operacje, które usuwają >1 rekord, np:

    delete from SalesLT.Customer
    where CustomerID in (
        1,      <- klient bez zamówienia, zostaje usunięty
        29485   <- klient z zamówieniem, trafia do DeletedCustomersLog
    );
 */

create trigger SalesLT.trg_Log_Deleted_Customers
    on SalesLT.Customer
    instead of delete
    as
begin
    set nocount on;

    insert into SalesLT.DeletedCustomersLog (CustomerID, Title, FirstName, MiddleName, LastName)
    select d.CustomerID, d.Title, d.FirstName, d.MiddleName, d.LastName
    from deleted d
    where exists(select 1
                 from SalesLT.SalesOrderHeader o
                 where o.CustomerID = d.CustomerID);

    delete c
    from SalesLT.Customer c
             join deleted d on c.CustomerID = d.CustomerID
    where not exists(select 1
                     from SalesLT.SalesOrderHeader o
                     where o.CustomerID = d.CustomerID);
end;

go;

-- =============================================
-- Zadanie 3
-- =============================================
/*
 Wygląda na to, że drzewko kategorii jest płytsze niż w opisie zadania i ma tylko 2 poziomy.
 Zmodyfikowałem dane, żeby wygenerować ścieżkę jak w opisie.
 */

-- Żeby udowodnić, że rekurencja działa zmieniamy parenta dla Road Frames:
update SalesLT.ProductCategory
set ParentProductCategoryID = 6 -- Road Bikes
where Name = 'Road Frames';

go;

-- Oczekiwany wynik w wierszu 17
with categories as (
    -- anchor: parents
    select ProductCategoryID,
           cast(Name as nvarchar(200)) as Name
    from SalesLT.ProductCategory
    where ParentProductCategoryID is null

    union all
    -- recursive: podkategorie
    select pc.ProductCategoryID,
           cast(concat(c.Name, N' → ', pc.Name) as nvarchar(200)) as Name
    from SalesLT.ProductCategory pc
             join categories c
                  on pc.ParentProductCategoryID = c.ProductCategoryID)

select Name
from categories
order by Name;

go;

-- =============================================
-- Zadanie 4
-- =============================================
/*
 Podejście podobne do tego w Zadaniu 2, żeby obsłużyć operacje z >1 zmianą, np:

     update SalesLT.Product
     set ListPrice = 50
     where ProductID in (
                        707, <- oryginalna cena 34.99; wzrost o 42%
                        713  <- oryginalna cena 49.99; niewielki wzrost
        )

 Zmiana w 707 zablokowana i zapisana w logu, zmiana w 713 przechodzi.

 */

create table SalesLT.ProductPriceChangeTrialLog
(
    ProductPriceChangeTrialID int identity (1,1) primary key,
    ProductID                 int not null,
    ListPriceTried            money,
    TriedAt                   datetime default getdate()
);

go;

create trigger trg_Price_Increase_Blockade
    on SalesLT.Product
    instead of update
    as
begin
    set nocount on;

    insert into SalesLT.ProductPriceChangeTrialLog (ProductID, ListPriceTried)
    select i.ProductID,
           i.ListPrice
    from inserted i
    where exists(select 1
                 from deleted d
                 where i.ProductID = d.ProductID
                   and i.ListPrice > d.ListPrice * 1.2);

    update SalesLT.Product
    set Name                   = i.Name,
        ProductNumber          = i.ProductNumber,
        Color                  = i.Color,
        StandardCost           = i.StandardCost,
        ListPrice              = i.ListPrice,
        Size                   = i.Size,
        Weight                 = i.Weight,
        ProductCategoryID      = i.ProductCategoryID,
        ProductModelID         = i.ProductModelID,
        SellStartDate          = i.SellStartDate,
        SellEndDate            = i.SellEndDate,
        DiscontinuedDate       = i.DiscontinuedDate,
        ThumbNailPhoto         = i.ThumbNailPhoto,
        ThumbnailPhotoFileName = i.ThumbnailPhotoFileName,
        rowguid                = i.rowguid,
        ModifiedDate           = i.ModifiedDate
    from inserted i
             join SalesLT.Product p on i.ProductID = p.ProductID
    where not exists(select 1
                     from deleted d
                     where i.ProductID = d.ProductID
                       and i.ListPrice > d.ListPrice * 1.2);

end;

go;

-- =============================================
-- Zadanie 5
-- =============================================
create table dbo.DatabaseAuditLog
(
    ChangeID    int identity (1,1) primary key,
    EventType   nvarchar(50) not null,
    SchemaName  nvarchar(50),
    ObjectName  nvarchar(50),
    ObjectType  nvarchar(50),
    LoginName   nvarchar(50),
    UserName    nvarchar(50),
    CommandText nvarchar(max),
    PostTime    datetime,
);

go;

create trigger trg_Database_Change_Log
    on database
    for create_table, alter_table, drop_table
    as
begin
    set nocount on;

    declare @data xml = eventdata();

    insert into dbo.DatabaseAuditLog (EventType, SchemaName, ObjectName, ObjectType, LoginName, UserName, CommandText,
                                      PostTime)
    values (@data.value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(50)'),
            @data.value('(/EVENT_INSTANCE/SchemaName)[1]', 'nvarchar(50)'),
            @data.value('(/EVENT_INSTANCE/ObjectName)[1]', 'nvarchar(50)'),
            @data.value('(/EVENT_INSTANCE/ObjectType)[1]', 'nvarchar(50)'),
            @data.value('(/EVENT_INSTANCE/LoginName)[1]', 'nvarchar(50)'),
            @data.value('(/EVENT_INSTANCE/UserName)[1]', 'nvarchar(50)'),
            @data.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'nvarchar(max)'),
            @data.value('(/EVENT_INSTANCE/PostTime)[1]', 'datetime'))
end;

go;

-- =============================================
-- Zadanie 6
-- =============================================

-- Tabela z recenzjami produktów, do których można dodawać komentarze
create table SalesLT.ProductReview
(
    ReviewID       int identity (1,1) primary key,
    ProductID      int not null,
    ParentReviewID int null,
    Author         nvarchar(50),
    Content        nvarchar(500),
    constraint FK_ReviewProductID foreign key (ProductID) references SalesLT.Product (ProductID),
    constraint FK_ParentReview foreign key (ParentReviewID) references SalesLT.ProductReview (ReviewID)
);

insert into SalesLT.ProductReview (ProductID, ParentReviewID, Author, Content)
values (680, null, 'Adam', 'Super rama!'),
       (680, 1, N'Bożena', N'Zgadzam się!'),
       (680, 1, 'Celina', N'Nie zgadzam się!'),
       (680, 3, 'Dawid', 'Dlaczego?'),
       (706, null, 'Ewa', 'Fajny kolor'),
       (706, 5, 'Filip', N'Wolę różowy');

go;

-- CTE z rekurencją
with combine_author_and_content as (select ReviewID,
                                           ProductID,
                                           ParentReviewID,
                                           concat(Author, ': ', Content) as DisplayContent
                                    from SalesLT.ProductReview),
     threads as (select ReviewID,
                        ProductID,
                        cast(DisplayContent as nvarchar(500)) as Thread
                 from combine_author_and_content
                 where ParentReviewID is null

                 union all

                 select r.ReviewID,
                        r.ProductID,
                        cast(concat(t.Thread, N' ← ', r.DisplayContent) as nvarchar(500))
                 from combine_author_and_content r
                          join threads t on r.ParentReviewID = t.ReviewID),
     report as (select ReviewID,
                       ProductID,
                       Thread
                from threads)
select *
from report
order by ReviewID;

go;
