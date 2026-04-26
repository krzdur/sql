-- =============================================
-- Krzysztof
-- Durbajło
-- 239869
-- =============================================

-- =============================================
-- Zadanie 1
-- =============================================

-- =============================================
-- Zadanie 2
-- =============================================
/*
 Wg dokumentacji: https://learn.microsoft.com/en-us/sql/relational-databases/tables/creating-a-system-versioned-temporal-table?view=sql-server-ver17#add-versioning-to-non-temporal-tables
 */
ALTER TABLE [239869].Customer ADD
ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START HIDDEN
    CONSTRAINT DF_Customer_ValidFrom DEFAULT SYSUTCDATETIME(),
ValidTo DATETIME2 GENERATED ALWAYS AS ROW END HIDDEN
    CONSTRAINT DF_Customer_ValidTo DEFAULT CONVERT (DATETIME2, '9999-12-31 23:59:59.9999999'),
PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo);
GO

ALTER TABLE [239869].Customer
    SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [239869].CustomerHistory));

go
-- =============================================
-- Zadanie 3
-- =============================================
update [239869].[Customer] set EmailAddress = 'updated1@example.com', ModifiedDate = GETDATE() where CustomerID = 1;
update [239869].[Customer] set EmailAddress = 'updated2@example.com', ModifiedDate = GETDATE() where CustomerID = 2;
update [239869].[Customer] set EmailAddress = 'updated3@example.com', ModifiedDate = GETDATE() where CustomerID = 3;
update [239869].[Customer] set EmailAddress = 'updated4@example.com', ModifiedDate = GETDATE() where CustomerID = 4;
update [239869].[Customer] set EmailAddress = 'updated5@example.com', ModifiedDate = GETDATE() where CustomerID = 5;
update [239869].[Customer] set EmailAddress = 'updated6@example.com', ModifiedDate = GETDATE() where CustomerID = 6;
update [239869].[Customer] set EmailAddress = 'updated7@example.com', ModifiedDate = GETDATE() where CustomerID = 7;
update [239869].[Customer] set EmailAddress = 'updated8@example.com', ModifiedDate = GETDATE() where CustomerID = 8;
update [239869].[Customer] set EmailAddress = 'updated9@example.com', ModifiedDate = GETDATE() where CustomerID = 9;
update [239869].[Customer] set EmailAddress = 'updated10@example.com', ModifiedDate = GETDATE() where CustomerID = 10;

update [239869].[Customer] set Title = 'Ms.', ModifiedDate = GETDATE() where CustomerID = 1;
update [239869].[Customer] set CompanyName = 'Company Name', ModifiedDate = GETDATE() where CustomerID = 1;
update [239869].[Customer] set Phone = '000-111-2222', ModifiedDate = GETDATE() where CustomerID = 1;

-- Zapis timestampa sprzed dodania wierzszy
create table ##run_state (ts datetime2);
insert into ##run_state values (getdate());

-- Dodanie wierszy
insert into [239869].[Customer]
    (NameStyle, Title, FirstName, MiddleName, LastName, Suffix,
     CompanyName, SalesPerson, EmailAddress, Phone,
     PasswordHash, PasswordSalt)
values
    (0, 'Mr.',  'Adam',   null,  'Kaczmarek',  null, 'Kaczmarek Co.',       'adventure-works\linda3', 'adam.xander@example.com',   '123-456-7890', 'AL5KVrOc1gYSmb/zWcpZ4w==', 'abc123'),
    (0, 'Ms.',  'Beata',  'K.', 'Kaczorowski',  null, 'Kacprzak Group',    'adventure-works\linda3', 'beata.xaviera@example.com', '234-567-8901', 'BL5KVrOc1gYSmb/zWcpZ4w==', 'bcd234'),
    (0, 'Mr.',  'Cezary', null,  'Kacprzak',   null, 'Kacprzak Solutions',  'adventure-works\linda3', 'cezary.xenos@example.com',  '345-678-9012', 'CL5KVrOc1gYSmb/zWcpZ4w==', 'cde345'),
    (0, 'Mrs.', 'Diana',  'M.', 'Kalinowski',    null, 'Kalinowski Enterprises','adventure-works\linda3', 'diana.xiong@example.com',   '456-789-0123', 'DL5KVrOc1gYSmb/zWcpZ4w==', 'def456'),
    (0, 'Dr.',  'Emil',   null,  'Kamiński',      'Jr.','Kamiński Technologies',  'adventure-works\linda3', 'emil.xu@example.com',       '567-890-1234', 'EL5KVrOc1gYSmb/zWcpZ4w==', 'efg567');

go
-- =============================================
-- Zadanie 4
-- =============================================
select *
from [239869].Customer
for system_time all
where 1=1
    and CustomerID = 1

-- =============================================
-- Zadanie 5
-- =============================================
-- Wczytanie timestampa sprzed dodania wierzszy
declare @ts datetime2 = (select top 1 ts from ##run_state);

select * from [239869].Customer
for system_time as of @ts

go
-- =============================================
-- Zadanie 6
-- =============================================
create xml schema collection SalesLT.ProductAttributesSchema as N'
    <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
        <xs:element name="ProductAttributes">
            <xs:complexType>
                <xs:sequence>
                    <xs:element name="Name" type="xs:string"/>
                    <xs:element name="ProductNumber" type="xs:string"/>
                    <xs:element name="Color" type="xs:string"/>
                    <xs:element name="Weight" type="xs:decimal"/>
                    <xs:element name="Size" type="xs:string"/>
                </xs:sequence>
            </xs:complexType>
        </xs:element>
    </xs:schema>
';

create table SalesLT.ProductAttribute (
    ProductID int primary key,
    Attributes xml(SalesLT.ProductAttributesSchema) null,
    constraint FK_ProductAttributeProductID foreign key (ProductID) references SalesLT.Product(ProductID)
);

go
-- =============================================
-- Zadanie 7
-- =============================================
insert into SalesLT.ProductAttribute
select top 10
    ProductID,
    (select
        Name,
        ProductNumber,
        Color,
        isnull(Weight, 0) as Weight,
        isnull(Size, 0) as Size
    for xml path('ProductAttributes'), type -- TYPE zwraca wartość jako xml
    )
from SalesLT.Product

go
-- =============================================
-- Zadanie 8
-- =============================================
update SalesLT.ProductAttribute
set Attributes.modify('
    replace value of (/ProductAttributes/Name)[1] with concat ("K", (/ProductAttributes/Name)[1])'
    );

update SalesLT.ProductAttribute
set Attributes.modify('
    replace value of (/ProductAttributes/ProductNumber)[1] with concat ("K", (/ProductAttributes/ProductNumber)[1])'
    );

update SalesLT.ProductAttribute
set Attributes.modify('
    replace value of (/ProductAttributes/Color)[1] with concat ("K", (/ProductAttributes/Color)[1])'
    );

go
-- =============================================
-- Zadanie 9
-- =============================================
declare @MyJSON nvarchar(max) = N'{"my_json": {"dowolny_klucz": "dowolna_wartość"}}'

set @MyJSON = json_modify(@MyJSON, '$.my_json.dowolny_klucz', 'K');
select @MyJSON;

go

