-- =============================================
-- Krzysztof
-- Durbajło
-- 239869
-- =============================================

-- =============================================
-- Zadanie 1
-- =============================================
/*
1. Pełny odczyt (Clustered Index Scan) tabeli SalesOrderHeader (32 wiersze) i filtrowanie do tych, które mają wartość
    inna niż null w polu ShipDate (nadal 32 wiersze).
2. Operacja złączenia do tabeli Address w Nested Loops: dla każdego wiersza z SalesOrderHeader silnik szuka
    odpowiadającego mu AddressID (Clustered Index Seek - wyszukiwanie po indeksie klastrowym). Jeśli znajduje
    pasujące ID, sprawdza, czy dany address spełnia warunek z klauzuli WHERE (miasto to Londyn, Oxford lub Cambridge) -
    jeśli nie, wiersz nie jest zwracany w wynikach. Operacja jest powtórzona dla każdego z 32 wierszy. W wyniku
    dostajemy 3 wiersze.
3. Podobna operacja jest wykonywana dla wyniku (3 wiersze) i tabeli SalesOrderDetail - dla każdego z 3 wierszy
    po kolei szukamy odpowiadającego mu SalesOrderID (znów przy pomocy indeksu klastrowego). Dla pasującego wiersza
    silnik oblicza wartość kolumny LineTotal (SQL Server nie przechowuje fizycznie wartości kolumn obliczanych).
    W wyniku otrzymujemy 92 wiersze - zamówienie + adres + szczegóły zamówienia.
4. Pełny odczyt tabeli Product (Clustered Index Scan) załadowanie 295 wierszy do tabeli haszującej.
5. Join wyniku z kroku 3. i tabeli Product przy pomocy ProductID i operacji Hash Match. Compute Scalar przed operacją
    Hash Match (chyba) odnosi się do wcześniej obliczanego LineTotal.
6. Kroki 4 i 5 powtórzone są kolejno dla tabel
    - ProductModelProductDescription - po skanowaniu wierszy do tabeli haszującej trafiają tylko rekordy spełniające
        warunek Culture = 'en'
    - ProductDescription (brak warunków w WHERE)
7. Sortowanie wyników wg ShipDate (malejąco) i City (rosnąco)
8. Zwrócenie wyniku - 92 wiersze
 */

-- =============================================
-- Zadanie 2
-- =============================================
create nonclustered index IX_Product_ProductNumber
on SalesLT.Product(ProductNumber)
include (ProductCategoryID, StandardCost, Name);
go

-- dodajemy kolumny do indeksu IX_SalesOrderDetail_ProductID
drop index IX_SalesOrderDetail_ProductID on SalesLT.SalesOrderDetail;
go

create nonclustered index IX_SalesOrderDetail_ProductID
on SalesLT.SalesOrderDetail(ProductID)
include (UnitPrice, OrderQty, UnitPriceDiscount, LineTotal);
go

-- po zmianach i ponownym wykonaniu plan silnik wykonuje Index Seek na wszystkich tabelach

-- =============================================
-- Zadanie 3
-- =============================================
/*
 Brak Profilera na macOS
 */

-- =============================================
-- Zadanie 4
-- =============================================
/*
Diagnostyka nie wykazała żadnych problemów, więc odświeżymy statystyki w SalesOrderDetail,
bo to tabela, do której wpada najwięcej wierszy z każdym nowym zamówieniem.
*/
update statistics SalesLT.SalesOrderDetail with fullscan;
go

