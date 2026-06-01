-- =============================================
-- Krzysztof
-- Durbajło
-- 239869
-- =============================================

-- =============================================
-- Zadanie 1
-- =============================================
select distinct pc.Name                                                  as category_name,
                min(p.ListPrice) over (partition by p.ProductCategoryID) as min_price,
                max(p.ListPrice) over (partition by p.ProductCategoryID) as max_price,
                count(*) over (partition by p.ProductCategoryID)         as product_count
from SalesLT.Product p
         join SalesLT.ProductCategory pc
              on p.ProductCategoryID = pc.ProductCategoryID;

go

-- =============================================
-- Zadanie 2
-- =============================================
/*
 ------------------- !!!!!!!!!! ------------------------
 Konieczne uruchomienie skryptu tworzącego tabele i dane: `lab-9&11-setup.sql`
 ------------------- !!!!!!!!!! ------------------------

 Scenariusz: Planowanie przeglądów floty rowerów miejskich.
 Dla każdego roweru obliczamy łączny przebieg i liczbę przejazdów. Ranking wg przebiegu wskazuje, które
 rowery najszybciej się zużywają. Porównanie ze średnim przebiegiem modelu pozwala oznaczyć egzemplarze
 mocno eksploatowane, które powinny trafić do serwisu w pierwszej kolejności.
 */

with bike_summary as (select r.BikeID,
                             b.Model,
                             b.Status,
                             sum(r.DistanceKm) as total_km,
                             count(*)          as ride_count,
                             max(r.EndTime)    as last_ride
                      from CityBikes.Rides r
                               join CityBikes.Bikes b on r.BikeID = b.BikeID
                      group by r.BikeID, b.Model, b.Status)
select BikeID,
       Model,
       Status,
       total_km,
       -- średni przebieg w ramach modelu
       avg(total_km) over (partition by Model)                       as avg_model_km,
       ride_count,
       last_ride,
       -- ranking rowerów wg łącznego przebiegu
       row_number() over (order by total_km desc)                    as service_priority,
       -- flaga: rower eksploatowany ponadprzeciętnie dla swojego modelu
       iif(total_km > avg(total_km) over (partition by Model), 1, 0) as needs_service
from bike_summary;

go

-- =============================================
-- Zadanie 3
-- =============================================
/*
 Scenariusz PIVOT: Raport serwisowy: ile zgłoszeń każdego typu usterki przypadło na dany model roweru.
 Zamiast filtrować po typie usterki, dostajemy jedną tabelę krzyżową.

 Scenariusz UNPIVOT: Tabela ze statystykami kwartalnymi stacji rowerowych przechowywana w formacie szerokim.
 Normalizujemy ją do postaci wierszowej, żeby łatwo było ją filtrować i agregować.
 */

-- pivot
with src as (select b.Model, ml.IssueType
             from CityBikes.MaintenanceLogs ml
                      join CityBikes.Bikes b on ml.BikeID = b.BikeID),
     pvt as (select *
             from src
                      pivot (
                      count(IssueType)
                      for IssueType in (tire, brake, chain)
                      ) as pivot_result)
select *
from pvt;

go

-- unpivot
select StationName, Quarter, Rides
from CityBikes.StationQuarterlyRides
         unpivot (
         Rides for Quarter in (Q1, Q2, Q3, Q4)
         ) as unpvt
order by StationName, Quarter;

go

-- =============================================
-- Zadanie 4
-- =============================================
/*
 1. Raport finansowy dla zarządu. Zarząd patrzy najpierw na przebieg w całym mieście, a potem w rozbiciu na dzielnice
 i modele. Stosujemy rollup, bo pozwala na zdefiniowanie hierarchii (dzielnica > model > total)
 */
select bs.District       as district,
       b.Model           as bike_model,
       count(*)          as ride_count,
       sum(r.DistanceKm) as total_km
from CityBikes.Rides r
         join CityBikes.Bikes b on r.BikeID = b.BikeID
         join CityBikes.BikeStations bs on r.StartStationID = bs.StationID
group by rollup (bs.District, b.Model)
order by 1, 2
;

go

/*
 2. Dane dla dashboardu BI. Cube wylicza podsumowania dla każdej kombinacji wymiarów z góry,
 dzięki czemu narzędzie BI nie musi ich liczyć w locie przy każdym kliknięciu. W porównaniu do rollup
 dodaje podsumowanie per model (niezależnie od dzielnicy)
 */
select bs.District       as district,
       b.Model           as bike_model,
       count(*)          as ride_count,
       sum(r.DistanceKm) as total_km
from CityBikes.Rides r
         join CityBikes.Bikes b on r.BikeID = b.BikeID
         join CityBikes.BikeStations bs on r.StartStationID = bs.StationID
group by cube (bs.District, b.Model)
order by 1, 2;

go

/*
 Raport dla serwisu. Serwis potrzebuje dwóch widoków do planowania zakupów części zamiennych:
 - ogólny per model - do planowania zakupów części,
 - szczegółowy per model i dzielnica - do planowania dystrybucji zamówionych części
 Grouping sets pozwalają wygenerować tylko te podsumowania, które są potrzebne
 */

select bs.District       as district,
       b.Model           as bike_model,
       count(*)          as ride_count,
       sum(r.DistanceKm) as total_km
from CityBikes.Rides r
         join CityBikes.Bikes b on r.BikeID = b.BikeID
         join CityBikes.BikeStations bs on r.StartStationID = bs.StationID
group by grouping sets ( (bs.District, b.Model),
                         (b.Model)
    )
order by 1, 2
;

go
