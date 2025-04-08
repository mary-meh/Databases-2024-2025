------------------Задание 1------------------

---------------------------------------------
-- представление "меню"

CREATE OR REPLACE VIEW Menu_View AS
SELECT
    Dishes.Name AS Dish_Name,
    Dishes.Dish_Type,
    Dishes.Price,
    Products.Name AS Ingredient,
    Recipes.Product_Quantity,
    Recipes.Unit
FROM
    Dishes
    JOIN Recipes ON Dishes.ID = Recipes.Dish_ID
    JOIN Products ON Recipes.Product_ID = Products.ID;

SELECT * FROM Menu_View;

SELECT pg_get_viewdef('Menu_View', true);

---------------------------------------------
-- представление "счет заказа"

CREATE OR REPLACE VIEW Order_Invoice AS
SELECT
    Orders.ID AS Order_ID,
    Orders.Order_Date,
    Orders.Order_Time,
    Guests.Last_Name || ' ' || Guests.First_Name AS Guest_Name,
    Dishes.Name AS Dish_Name,
    Order_Dishes.Quantity,
    Dishes.Price * Order_Dishes.Quantity AS Dish_Total
FROM
    Orders
    JOIN Guests ON Orders.Guest_ID = Guests.ID
    JOIN Order_Dishes ON Orders.ID = Order_Dishes.Order_ID
    JOIN Dishes ON Order_Dishes.Dish_ID = Dishes.ID;

SELECT * FROM Order_Invoice;

SELECT pg_get_viewdef('Order_Invoice', true);

---------------------------------------------
-- представление "отчет по продуктам на складе"

CREATE OR REPLACE VIEW Stock_Report AS
SELECT
    Products.Name AS Product_Name,
    Products.Expiration_Date,
    Deliveries.Quantity AS Stock_Quantity,
    Products.Unit
FROM
    Products
    JOIN Deliveries ON Products.ID = Deliveries.Product_ID;

SELECT * FROM Stock_Report;

SELECT pg_get_viewdef('Stock_Report', true);

---------------------------------------------
-- представление "отчет по сотрудникам"

CREATE OR REPLACE VIEW Staff_Report AS
SELECT
    ID AS Waiter_ID,
    Last_Name || ' ' || First_Name || COALESCE(' ' || Patronymic, '') AS Full_Name,
    Salary,
    Hiring_Date
FROM
    Waiters;

SELECT * FROM Staff_Report;

SELECT pg_get_viewdef('Staff_Report', true);


---------------------------------------------
---------------------------------------------
---------------------------------------------


------------------Задание 2------------------
-- обновляемое представление

CREATE OR REPLACE VIEW Active_Orders AS
SELECT 
    ID,
    Guest_ID,
    Waiter_ID,
    Order_Date,
    Order_Time,
    Order_Amount,
    Status
FROM Orders
WHERE Status = 'В процессе'
WITH CHECK OPTION;

SELECT * FROM Active_Orders;

SELECT pg_get_serial_sequence('orders', 'id');

SELECT setval(
    'orders_id_seq', 
    (SELECT MAX(id) FROM orders)
);

SELECT nextval('orders_id_seq');




-- хорошая вставка
INSERT INTO Active_Orders (Guest_ID, Waiter_ID, Order_Date, Order_Time, Order_Amount, Status)
VALUES (2, 3, '2024-01-20', '14:30:00', 2500.00, 'В процессе');

-- плохая вставка
-- ERROR:  new row violates check option for view "active_orders"
INSERT INTO Active_Orders (Guest_ID, Waiter_ID, Order_Date, Order_Time, Order_Amount, Status)
VALUES (2, 5, '2024-01-20', '15:00:00', 1800.00, 'Завершен');

SELECT * FROM Active_Orders;

---------------------------------------------
---------------------------------------------
---------------------------------------------

-----------------Задание 2.1-----------------

CREATE OR REPLACE VIEW High_Salary_Waiters AS
SELECT 
    ID,
    Last_Name,
    First_Name,
    Patronymic,
    Salary,
    Hiring_Date
FROM Waiters
WHERE Salary > 40000;

SELECT * from High_Salary_Waiters;

---------------------------------------------

CREATE OR REPLACE VIEW Local_Recent_Hires AS
SELECT *
FROM High_Salary_Waiters
WHERE Hiring_Date > '2023-01-01'
WITH LOCAL CHECK OPTION;

SELECT * FROM Local_Recent_Hires;

---------------------------------------------

CREATE OR REPLACE VIEW Cascaded_Recent_Hires AS
SELECT *
FROM High_Salary_Waiters
WHERE Hiring_Date > '2023-01-01'
WITH CASCADED CHECK OPTION;

SELECT * from Cascaded_Recent_Hires;

---------------------------------------------
---------------------------------------------

-- последовательность id
SELECT pg_get_serial_sequence('waiters', 'id');

SELECT setval(
    'public.waiters_id_seq', 
    (SELECT MAX(id) FROM waiters)
);
---------------------------------------------
---------------------------------------------
SELECT * FROM Local_Recent_Hires;


-- всё окей: зарплата > 40000 и дата найма > 01.01.2023
INSERT INTO Local_Recent_Hires (Last_Name, First_Name, Patronymic, Salary, Hiring_Date)
VALUES ('Иванов', 'Петр', 'Олегович', 45000, '2023-05-15');

-- ошибка: нарушение local check, дата найма < 01.01.2023
INSERT INTO Local_Recent_Hires (Last_Name, First_Name, Patronymic, Salary, Hiring_Date)
VALUES ('Сидорова', 'Мария', 'Максимовна', 45000, '2022-12-31');
-- ERROR: new row violates check option for view "local_recent_hires"

-- опасная вставка: зарплата < 40000, но дата найма удовлетворяет local check
INSERT INTO Local_Recent_Hires (Last_Name, First_Name, Patronymic, Salary, Hiring_Date)
VALUES ('Петров', 'Иван', 'Игоревич', 25000, '2023-06-01'); 
-- вставка пройдет, но строка не будет видна в представлении

DELETE FROM Local_Recent_Hires
WHERE Last_Name = 'Петров' 
  AND First_Name = 'Иван' 
  AND Patronymic = 'Игоревич' 
  AND Hiring_Date = '2023-06-01';


---------------------------------------------
---------------------------------------------
SELECT * from Cascaded_Recent_Hires;


-- всё окей: все условия соблюдены
INSERT INTO Cascaded_Recent_Hires (Last_Name, First_Name, Patronymic, Salary, Hiring_Date)
VALUES ('Сергеев', 'Андрей', 'Владимирович', 42000, '2023-10-10');

-- ошибка 1: нарушение начального требования по зарплате
INSERT INTO Cascaded_Recent_Hires (Last_Name, First_Name, Patronymic, Salary, Hiring_Date)
VALUES ('Кузнецова', 'Ольга', 'Петровна', 25000, '2023-02-02'); 
-- ERROR: new row violates check option for view "high_salary_waiters"

-- ошибка 2: нарушение Cascaded_Recent_Hires - дата < 01.01.2023
INSERT INTO Cascaded_Recent_Hires (Last_Name, First_Name, Patronymic, Salary, Hiring_Date)
VALUES ('Николаев', 'Дмитрий', 'Тимурович', 42000, '2022-05-15'); 
-- ERROR: new row violates check option for view "cascaded_recent_hires"






------------------Задание 3------------------
-- индексированное представление

-- агрегировать данные о поставках продуктов за последний год
CREATE MATERIALIZED VIEW Product_Deliveries AS
SELECT 
    Products.ID AS Product_ID,
    Products.Name,
    SUM(Deliveries.Quantity) AS Total_Delivered,
    MAX(Deliveries.Delivery_Date) AS Last_Delivery_Date
FROM Products
JOIN Deliveries ON Products.ID = Deliveries.Product_ID
WHERE Deliveries.Delivery_Date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY Products.ID, Products.Name;
---------------------------------------------
SELECT * FROM Product_Deliveries;
-------------------------------------------
DROP MATERIALIZED VIEW IF EXISTS Product_Deliveries;



CREATE INDEX idx_product_id ON Product_Deliveries (Product_ID);

EXPLAIN ANALYZE
SELECT * FROM Product_Deliveries 
WHERE Product_ID = 100;

-- Index Scan using idx_product_id on product_deliveries  (cost=0.28..8.30 rows=1 width=32) (actual time=0.021..0.025 rows=1 loops=1)
-- 	Index Cond: (product_id = 100)
-- Planning Time: 0.313 ms
-- Execution Time: 0.053 ms

---------------------------------------------
DROP INDEX IF EXISTS idx_product_id;



EXPLAIN ANALYZE
SELECT 
    Products.ID,
    Products.Name,
    SUM(Deliveries.Quantity) AS Total_Delivered,
    MAX(Deliveries.Delivery_Date) AS Last_Delivery_Date
FROM Products
JOIN Deliveries ON Products.ID = Deliveries.Product_ID
WHERE Deliveries.Delivery_Date >= CURRENT_DATE - INTERVAL '1 year'
  AND Products.ID = 100
GROUP BY Products.ID, Products.Name;

-- Execution Time: 0.642 ms





