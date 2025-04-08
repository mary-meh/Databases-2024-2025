



-- Простой индекс
-- базовый индекс, который создаётся на одном столбце таблицы 
-- без дополнительных модификаторов или условий

-- В случае B-Tree он строится по алгоритму сбалансированного дерева, 
-- что позволяет эффективно искать, сортировать и фильтровать данные.
-- В случае Hash он строится по принципу хэш-таблицы, что делает его 
-- оптимальным для поиска по точному совпадению.

-- B-Tree индекс
-- Подходит для:
--   Поиска по равенству (=).
--   Поиска по диапазону (<, >, BETWEEN).
--   Сортировки (ORDER BY).
--   Поиска по шаблонам (LIKE '...%').
--   Поиска уникальных значений (DISTINCT).

CREATE INDEX idx_product_name ON Products (Name);



EXPLAIN ANALYZE
SELECT * FROM Products
WHERE Name IN ('Салат', 'Ананас', 'Креветки');



CREATE INDEX idx_products_id ON Products (ID);
CREATE INDEX idx_deliveries_product_id ON Deliveries (Product_ID);

-- продукты, для которых есть хотя бы одна поставка
EXPLAIN ANALYZE
SELECT *
FROM Products
WHERE EXISTS (
    SELECT 1
    FROM Deliveries
    WHERE Deliveries.Product_ID = Products.ID
);


-- все продукты, для которых в каждой поставке количество больше 10
--EXPLAIN ANALYZE
--SELECT *
--FROM Products
--WHERE Products.ID = ALL (
--    SELECT Deliveries.Product_ID
--    FROM Deliveries
--    WHERE Deliveries.Quantity > 10
--);


-- все продукты, для которых в каждой поставке количество больше 10
EXPLAIN ANALYZE
SELECT Products.*
FROM Products
JOIN Deliveries ON Products.ID = Deliveries.Product_ID
WHERE Deliveries.Quantity > 10;



DROP INDEX IF EXISTS idx_product_name;
DROP INDEX IF EXISTS idx_products_id;
DROP INDEX IF EXISTS idx_deliveries_product_id;


---------------------------------------------------------
---------------------Хэш-индекс--------------------------
---------------------------------------------------------

CREATE INDEX idx_product_code_hash ON Products USING hash (ID); -- уже создала
CREATE INDEX idx_deliveries_product_id_hash ON Deliveries USING hash (Product_ID); -- уже создала


CREATE INDEX idx_orders_guest_id_hash ON Orders USING hash (Guest_ID);
CREATE INDEX idx_dishes_id_hash ON Dishes USING hash (ID);
CREATE INDEX idx_order_dishes_dish_id_hash ON Order_Dishes USING hash (Dish_ID);



-- получение всех доставок продуктов с ID из списка
EXPLAIN ANALYZE
SELECT * FROM Deliveries
WHERE Product_ID IN (1, 2, 5, 1000);



 -- получение всех гостей, которые сделали заказы с блюдами из списка
EXPLAIN ANALYZE
SELECT * FROM Guests
WHERE EXISTS (
    SELECT 1 
    FROM Orders
    JOIN Order_Dishes ON Orders.ID = Order_Dishes.Order_ID
    WHERE Orders.Guest_ID = Guests.ID
    AND Order_Dishes.Dish_ID IN (3, 7, 259, 1521, 4955)
);


EXPLAIN ANALYZE
SELECT *
FROM Guests
WHERE ID IN (
    SELECT Orders.Guest_ID
    FROM Orders
    WHERE EXISTS (
        SELECT 1
        FROM Order_Dishes
        WHERE Order_Dishes.Order_ID = Orders.ID
        AND Order_Dishes.Dish_ID = ANY ('{3, 7, 259, 1521, 4955}'::integer[])
    )
);


EXPLAIN ANALYZE
SELECT *
FROM Guests
WHERE EXISTS (
    SELECT 1
    FROM Orders
    JOIN Order_Dishes ON Orders.ID = Order_Dishes.Order_ID
    WHERE Orders.Guest_ID = Guests.ID
    AND (
        Order_Dishes.Dish_ID = 3
        OR Order_Dishes.Dish_ID = 7
        OR Order_Dishes.Dish_ID = 259
        OR Order_Dishes.Dish_ID = 1521
        OR Order_Dishes.Dish_ID = 4955
    )
);

EXPLAIN ANALYZE
SELECT * FROM Orders WHERE Guest_ID = 123;





DROP INDEX IF EXISTS idx_product_code_hash;
DROP INDEX IF EXISTS idx_deliveries_product_id_hash;
DROP INDEX IF EXISTS idx_orders_guest_id_hash;
DROP INDEX IF EXISTS idx_dishes_id_hash;
DROP INDEX IF EXISTS idx_order_dishes_dish_id_hash;




-----------------------------------------
-----------Уникальный индекс-------------
-----------------------------------------

CREATE UNIQUE INDEX idx_products_id ON Products (ID);




EXPLAIN ANALYZE
SELECT Products.Name, Deliveries.Delivery_Date, Deliveries.Quantity
FROM Products
INNER JOIN Deliveries ON Products.ID = Deliveries.Product_ID
WHERE Products.ID IN (1, 2, 50, 325, 1500, 4500);




-- выбираем имя продукта и суммируем количество поставок для каждого продукта

CREATE UNIQUE INDEX idx_products_id ON Products (ID);


EXPLAIN ANALYZE
SELECT Products.Name, SUM(Deliveries.Quantity) AS total_quantity
FROM Products
INNER JOIN Deliveries ON Products.ID = Deliveries.Product_ID
GROUP BY Products.ID;


-- выбираем ID продуктов, количество в поставках которых > 100
-- и те, которые начинаются с "Салат"

CREATE INDEX idx_deliveries_quantity ON Deliveries (Quantity);
CREATE INDEX idx_products_name ON Products (Name);

EXPLAIN ANALYZE
SELECT Product_ID FROM Deliveries WHERE Quantity > 100
UNION ALL
SELECT ID FROM Products WHERE Name LIKE 'Салат%';




DROP INDEX IF EXISTS idx_products_id;
DROP INDEX IF EXISTS idx_deliveries_quantity;
DROP INDEX IF EXISTS idx_products_name;




-----------------------------------------
-----------Составной индекс--------------
-----------------------------------------
-- охватывают более одного столбца в таблице. В отличие от простых индексов, 
-- которые индексируют только один столбец, составной индекс индексирует 
-- несколько столбцов в заданном порядке


--  узнать среднюю сумму заказа по каждому официанту для заказов со статусом "Выполнен"
CREATE INDEX idx_orders_status_waiter ON Orders (Status, Waiter_ID);

EXPLAIN ANALYZE
SELECT Orders.Waiter_ID, AVG(Orders.Order_Amount)
FROM Orders
WHERE Orders.Status = 'Выполнен'
GROUP BY Orders.Waiter_ID
HAVING AVG(Orders.Order_Amount) > 100;



-- выбрать продукты, которые были поставлены поставщиком из Москвы, 
-- у которого есть как минимум один заказ, сделанный в 
-- течение 30 дней
CREATE INDEX idx_deliveries_product_supplier ON Deliveries(Product_ID, Supplier_ID);
CREATE INDEX idx_suppliers_region ON Suppliers(Region);
CREATE INDEX idx_orders_order_date ON Orders(Order_Date);



EXPLAIN ANALYZE
SELECT Products.Name
FROM Products
WHERE EXISTS (
    SELECT 1
    FROM Deliveries
    JOIN Suppliers ON Deliveries.Supplier_ID = Suppliers.ID
    WHERE Products.ID = Deliveries.Product_ID
    AND EXISTS (
        SELECT 1
        FROM Orders
        WHERE Orders.Order_Date > CURRENT_DATE - INTERVAL '100 days'
    )
);

DROP INDEX IF EXISTS idx_deliveries_product_supplier;
DROP INDEX IF EXISTS idx_suppliers_region;
DROP INDEX IF EXISTS idx_orders_order_date;






CREATE INDEX idx_deliveries_product_date ON Deliveries (Product_ID, Delivery_Date);
CREATE INDEX idx_suppliers_region ON Suppliers (Region);
CREATE INDEX idx_dishes_name ON Dishes (Name);


DROP INDEX IF EXISTS idx_deliveries_product_date;
DROP INDEX IF EXISTS idx_suppliers_region;
DROP INDEX IF EXISTS idx_dishes_name;





CREATE INDEX idx_deliveries_supplier_product ON Deliveries(Supplier_ID, Product_ID);
CREATE INDEX idx_products_id ON Products(ID);
CREATE INDEX idx_suppliers_id ON Suppliers(ID);



DROP INDEX IF exists idx_deliveries_supplier_product;
DROP INDEX IF exists idx_products_id;
DROP INDEX IF exists idx_suppliers_id;



EXPLAIN ANALYZE
SELECT Suppliers.Name AS Supplier_Name, Products.Name AS Product_Name, SUM(Deliveries.Quantity * Products.Unit_Price) AS Total_Value
FROM Suppliers
JOIN Deliveries ON Suppliers.ID = Deliveries.Supplier_ID
JOIN Products ON Products.ID = Deliveries.Product_ID
GROUP BY Suppliers.ID, Products.ID
HAVING SUM(Deliveries.Quantity * Products.Unit_Price) > 10000;



-- найти поставщиков, которые поставили продукты на сумму более 10000, 
-- и сгруппировать данные по поставщикам и продуктам
CREATE INDEX idx_deliveries_supplier_product_quantity 
ON Deliveries (Supplier_ID, Product_ID, Quantity);

CREATE INDEX idx_products_id_unit_price 
ON Products (ID) 
INCLUDE (Unit_Price, Name); 

EXPLAIN ANALYZE
SELECT 
    Suppliers.Name, 
    Products.Name, 
    SUM(Deliveries.Quantity * Products.Unit_Price)
FROM Suppliers
JOIN Deliveries ON Suppliers.ID = Deliveries.Supplier_ID
JOIN Products ON Products.ID = Deliveries.Product_ID
GROUP BY Suppliers.ID, Products.ID, Suppliers.Name, Products.Name
HAVING SUM(Deliveries.Quantity * Products.Unit_Price) > 10000;





----------------------------------
----С использованием выражений----
----------------------------------

-- вычислить разницу между текущей датой и датой доставки
--CREATE INDEX idx_delivery_date_diff ON Deliveries ((CURRENT_DATE - Delivery_Date));
--
--
--EXPLAIN ANALYZE
--SELECT * FROM Deliveries
--WHERE CURRENT_DATE > Delivery_Date + INTERVAL '30 days';




-- год доставки = 2025
CREATE INDEX idx_delivery_year ON Deliveries ((DATE_PART('year', Delivery_Date)));

EXPLAIN ANALYZE
SELECT * FROM Deliveries
WHERE DATE_PART('year', Delivery_Date) = 2025;

DROP INDEX IF exists idx_delivery_year




-- выбрать компании для поставки
CREATE INDEX idx_suppliers_substr ON Suppliers (SUBSTRING(Name, 1, 3));

EXPLAIN ANALYZE
SELECT Name
FROM Suppliers 
WHERE SUBSTRING(Name, 1, 3) = 'ООО';

DROP INDEX IF exists idx_suppliers_substr






-- список типов блюд, для которых средняя цена больше 500
CREATE index idx_type_price on Dishes(Dish_Type, Price)

EXPLAIN ANALYZE
SELECT Dish_Type, AVG(Price) 
FROM Dishes 
GROUP BY Dish_Type 
HAVING AVG(Price) > 500;

DROP INDEX IF exists idx_type_price






----------------------------------
-----------Покрывающий------------
----------------------------------


-- дата заказа меньше 15.07.2025
CREATE INDEX idx_orders_guest_covering 
ON Orders (Order_Date) 
INCLUDE (Order_Amount, Guest_ID);

EXPLAIN ANALYZE
SELECT Orders.Order_Date, Orders.Order_Amount, Guests.Last_Name 
FROM Orders
JOIN Guests ON Orders.Guest_ID = Guests.ID
WHERE Orders.Order_Date < '2025-07-15';

DROP INDEX IF exists idx_orders_guest_covering



-- срок годности между какими-то датами
CREATE INDEX idx_products_expiration_covering 
ON Products (Expiration_Date) 
INCLUDE (Name);

EXPLAIN ANALYZE
SELECT Name, Expiration_Date 
FROM Products 
WHERE Expiration_Date BETWEEN '2024-01-01' AND '2026-12-31';

drop index if exists idx_products_expiration_covering;



-- поставщики "ООО"
CREATE INDEX idx_suppliers_substr_covering 
ON Suppliers (SUBSTRING(Name, 1, 3)) 
INCLUDE (Name);

EXPLAIN ANALYZE
SELECT Name 
FROM Suppliers 
WHERE SUBSTRING(Name, 1, 3) = 'ООО';

drop index if exists idx_suppliers_substr_covering;




----------------------------------
-----------Частичный--------------
----------------------------------

-- постоянные клиенты с фамилией на А
CREATE INDEX idx_guests_regular_initial 
ON Guests (Last_Name) 
WHERE SUBSTRING(Last_Name FROM 1 FOR 1) = 'А' AND Regular_Client = TRUE;

EXPLAIN analyze
SELECT * FROM Guests 
WHERE SUBSTRING(Last_Name FROM 1 FOR 1) = 'А' 
AND Regular_Client = TRUE;

drop index if exists idx_guests_regular_initial 




-- сумма заказа > 500
-- + официанты с > 2 заказами
CREATE INDEX idx_orders_high_amount 
ON Orders (Waiter_ID) 
WHERE Order_Amount > 500;

EXPLAIN analyze
SELECT Waiter_ID, COUNT(*) 
FROM Orders 
WHERE Order_Amount > 500
GROUP BY Waiter_ID 
HAVING COUNT(*) > 2;

drop index if exists idx_orders_high_amount;



-- постоянный клиент с нужным ID
CREATE INDEX idx_guests_regular_hash 
ON Guests USING HASH (ID) 
WHERE Regular_Client = TRUE;

EXPLAIN analyze
SELECT Guests.Last_Name, Orders.Order_Amount 
FROM Guests
JOIN Orders ON Guests.ID = Orders.Guest_ID 
WHERE Guests.ID = 1528
  AND Guests.Regular_Client = TRUE;
drop index if exists idx_guests_regular_hash;




-- есть ли рецепты, в которых единица измерения продукта = кг,
-- и продукт используется в рецепте
CREATE INDEX idx_recipes_kg_products 
ON Recipes (Product_ID) 
WHERE Unit = 'кг';

EXPLAIN analyze
SELECT * FROM Products
WHERE EXISTS (
  SELECT 1 FROM Recipes 
  WHERE Recipes.Product_ID = Products.ID 
  AND Recipes.Unit = 'кг'
);

drop index if exists idx_recipes_kg_products;





----------------------------------
-------Частичный покрывающий------
----------------------------------


-- количество > 100 и поставщик из Москвы
CREATE INDEX idx_deliveries_moscow_covering 
ON Deliveries (Supplier_ID) 
INCLUDE (Delivery_Date) -- покрывает столбец Delivery_Date
WHERE Quantity > 100; -- только поставки > 100

EXPLAIN analyze
SELECT Suppliers.Name, Deliveries.Delivery_Date 
FROM Suppliers
JOIN Deliveries ON Suppliers.ID = Deliveries.Supplier_ID 
WHERE Deliveries.Quantity > 100 AND Suppliers.Region = 'Москва';

drop index if exists idx_deliveries_moscow_covering;





-- срок годности в границах и единица измерения = шт
CREATE INDEX idx_products_expiration_covering 
ON Products (Expiration_Date) 
INCLUDE (Name)  -- покрывает столбец Name
WHERE Unit = 'шт';  -- только с ед. измерения = шт

EXPLAIN analyze
SELECT Name, Expiration_Date 
FROM Products 
WHERE Expiration_Date BETWEEN '2024-01-01' AND '2026-12-31' 
AND Unit = 'шт';

drop index if exists idx_products_expiration_covering; 





-- выполненные заказы в 2025 году
CREATE INDEX idx_orders_2025_covering 
ON Orders (DATE_PART('year', Order_Date)) 
INCLUDE (Order_Amount) -- покрывает сумму заказа
WHERE Status = 'Выполнен'; -- только завершенные заказы

EXPLAIN analyze
SELECT Order_Date, Order_Amount 
FROM Orders 
WHERE DATE_PART('year', Order_Date) = 2025 
AND Status = 'Выполнен';

drop index if exists idx_orders_2025_covering 




-- заказы на сумму > 1000
-- и официанты с > 2 заказами
CREATE INDEX idx_orders_high_amount_covering 
ON Orders (Waiter_ID) 
INCLUDE (Order_Amount)  -- покрывает сумму для фильтрации
WHERE Order_Amount > 1000;  -- только сумма > 1000

EXPLAIN analyze
SELECT Waiter_ID, COUNT(*) 
FROM Orders 
WHERE Order_Amount > 1000 
GROUP BY Waiter_ID 
HAVING COUNT(*) > 2;

drop index if exists idx_orders_high_amount_covering;




-- тип блюда = суп, цена > 300, страна = Россия
CREATE INDEX idx_dishes_russian_soups 
ON Dishes (Name) 
INCLUDE (Dish_Type, Price, Country_of_Origin) 
WHERE Dish_Type = 'Суп' OR Country_of_Origin = 'Россия';

EXPLAIN analyze
SELECT Name FROM Dishes 
WHERE Dish_Type = 'Суп' AND Price > 300 
INTERSECT 
SELECT Name FROM Dishes 
WHERE Country_of_Origin = 'Россия';



---------------------------------
---------------------------------

-- выключить индексы
SET enable_seqscan = ON;
SET enable_indexscan = OFF;
SET enable_bitmapscan = OFF;
SET enable_hashjoin = OFF;
SET enable_mergejoin = OFF;
SET enable_nestloop = OFF;

--SET enable_seqscan = ON;
--SET enable_indexscan = OFF;
--SET enable_bitmapscan = OFF;
--SET enable_hashjoin = OFF;


-- уникальные
SET enable_seqscan = OFF;
SET enable_indexscan = ON;
SET enable_bitmapscan = ON;


-- включить индексы
SET enable_seqscan = OFF;
SET enable_indexscan = ON;
SET enable_bitmapscan = ON;
SET enable_hashjoin = ON;


-- включить хэш-индексы
SET enable_seqscan = OFF;
SET enable_indexscan = ON;
SET enable_bitmapscan = OFF;
SET enable_hashjoin = ON;

--SET enable_mergejoin = OFF;
--SET enable_nestloop = OFF;








EXPLAIN ANALYZE
SELECT * FROM Products 
WHERE Name LIKE 'Салат%';

EXPLAIN ANALYZE
SELECT * FROM Products 
WHERE ID = 5;

EXPLAIN ANALYZE
SELECT * FROM Products 
WHERE Unit_Price BETWEEN 10 AND 40;












