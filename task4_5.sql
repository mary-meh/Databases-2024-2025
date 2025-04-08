-----------------------------------------
----------------Блок 1-------------------
-----------------------------------------


------------Inner Join--------------
-- используется для соединения строк из двух таблиц, 
-- которые имеют совпадающие значения в указанных полях

-- связываем таблицы Orders и Guests по полю Guest_ID
SELECT 
    Orders.ID,
    Orders.Order_Date,
    Orders.Order_Time,
    Orders.Order_Amount,
    Guests.Last_Name,
    Guests.First_Name
FROM 
    Orders
INNER JOIN 
    Guests ON Orders.Guest_ID = Guests.ID;



------------Left Join--------------
-- возвращает все записи из левой таблицы и совпадающие 
-- записи из правой таблицы

-- связываем таблицы Orders и Guests по полю Guest_ID
SELECT 
    Orders.ID, 
    Orders.Order_Date, 
    Orders.Order_Amount,
    Guests.Last_Name
FROM 
    Orders
-- берет все записи из таблицы Orders и добавляет 
-- к ним фамилию гостя, если она найдена по условию
LEFT JOIN Guests ON Orders.Guest_ID = Guests.ID;



------------Right Join--------------
-- возвращает все записи из правой таблицы и совпадающие 
-- записи из левой таблицы

-- связываем таблицы Products и Deliveries по полю Product_ID
SELECT 
    Products.Name,
    Deliveries.Delivery_Date,
    Deliveries.Quantity
FROM 
    Products
RIGHT JOIN Deliveries ON Products.ID = Deliveries.Product_ID;	-- берет все записи из таблицы Deliveries и добавляет к ним 
																-- название продукта, если оно есть в таблице Products


------------Full Join--------------
-- объединяет результаты LEFT JOIN и RIGHT JOIN
-- возвращает все записи из обеих таблиц

SELECT 
    Suppliers.ID,
    Suppliers.Name,
    Products.ID,
    Products.Name,
    Deliveries.Delivery_Date,
    Deliveries.Quantity
FROM 
    Suppliers
FULL JOIN Deliveries ON Suppliers.ID = Deliveries.Supplier_ID	-- добавляет к поставщикам их поставки
FULL JOIN Products ON Deliveries.Product_ID = Products.ID;		-- добавляет к поставкам информацию о продуктах



------------Cross Join--------------
-- каждая строка из первой таблицы соединяется с каждой
-- строкой из второй таблицы

SELECT D.Name AS Dish_Name, P.Name AS Product_Name
FROM Dishes D
CROSS JOIN Products P;


------------Cross Join Lateral--------------
-- позволяет использовать данные из внешней таблицы 
-- внутри подзапроса


-- ищем самый дорогой продукт для каждого блюда
SELECT 
    Dishes.Name AS Dish_Name,			-- название блюда
    Expensive_Product.Name AS Most_Expensive_Product,	-- самый дорогой продукт
    Expensive_Product.Unit_Price AS Max_Price			-- его цена
FROM 
    Dishes				-- берем все строки из таблицы Блюда
CROSS JOIN LATERAL (	-- подзапрос ссылается на строки из основной таблицы (Блюда) в каждой итерации
    SELECT 
        Products.Name,
        Products.Unit_Price
    FROM 
        Recipes	 -- данные из таблицы Рецепты
    JOIN Products ON Recipes.Product_ID = Products.ID	-- соединяем таблицы Рецепты и Продукты
    WHERE Recipes.Dish_ID = Dishes.ID
    ORDER BY Products.Unit_Price DESC	-- сортируем по убыванию цены
    LIMIT 1		-- выбираем только один продукт
) AS Expensive_Product;



------------Самосоединение--------------
-- используется, когда нужно сравнить данные внутри одной таблицы

-- выводим официантов, нанятых на работу в один день
SELECT
    w1.Last_Name || ' ' || w1.First_Name AS Waiter1, -- конкатенируем фамилию и имя
    w2.Last_Name || ' ' || w2.First_Name AS Waiter2,
    w1.Hiring_Date
-- таблица Официанты подключена к самой себе
FROM 
    Waiters w1
-- соединяем строки по одинаковой дате приема на работу
JOIN 
    Waiters w2
    ON w1.Hiring_Date = w2.Hiring_Date
    AND w1.ID < w2.ID;	-- убираем дубликаты


-----------------------------------------
----------------Блок 2-------------------
-----------------------------------------
    
------------UNION--------------
-- используется для объединения результатов двух или более запросов 
-- в один общий набор данных
-- количество столбцов в объединяемых запросах должно совпадать 
-- типы данных в соответствующих столбцах также должны быть совместимы

-- вывести все продукты с ценой > 50р и блюда с ценой > 500р
SELECT
    'Продукт' AS Item_Type,
    Products.Name AS Item_Name,
    Products.Unit_Price AS Price
FROM 
    Products
WHERE 
    Products.Unit_Price > 50

UNION

SELECT 
    'Блюдо' AS Item_Type,
    Dishes.Name AS Item_Name,
    Dishes.Price AS Price
FROM 
    Dishes
WHERE 
    Dishes.Price > 500;


------------UNION ALL--------------
-- объединяет результаты двух или более запросов без удаления дубликатов

-- вывести список всех наименований продуктов и блюд, 
-- вне зависимости от того, повторяются они или нет
SELECT 
    'Продукт' AS Item_Type,
    Products.Name AS Item_Name
FROM 
    Products

UNION ALL

SELECT 
    'Блюдо' AS Item_Type,
    Dishes.Name AS Item_Name
FROM 
    Dishes;


------------EXCEPT--------------
-- для получения записей, которые есть в одном запросе, но отсутствуют в другом

-- найти поставщиков, которые ещё не осуществляли поставки
SELECT 
    Suppliers.Name AS Supplier_Without_Deliveries  -- берем всех поставщиков
FROM 
    Suppliers

EXCEPT
-- находим тех, кто сделал хотя бы одну поставку
-- и делаем except к ним

SELECT 
    Suppliers.Name
FROM 
    Suppliers
JOIN Deliveries ON Suppliers.ID = Deliveries.Supplier_ID;


------------INTERSECT--------------
-- возвращает общие элементы из двух или более запросов

-- найти блюда, которые были заказаны и у которых есть рецепты
SELECT Dishes.ID, Dishes.Name  -- ID и имя блюда
FROM Dishes

-- находим блюда, которые есть и в Order_Dishes, и в Recipes
WHERE Dishes.ID IN (
    SELECT Order_Dishes.Dish_ID
    FROM Order_Dishes
    -- ищем общие значения между двумя запросами
    INTERSECT
    SELECT Recipes.Dish_ID
    FROM Recipes
);


-----------------------------------------
----------------Блок 3-------------------
-----------------------------------------

------------EXISTS--------------
-- для проверки существования записей, соответствующих 
-- заданному условию в подзапросе

-- вывести список блюд, которые хоть раз были заказаны
SELECT Dishes.ID, Dishes.Name
FROM Dishes
WHERE EXISTS (
    SELECT 1	-- проверяем наличие строк; exists требует select внутри
    FROM Order_Dishes
    WHERE Order_Dishes.Dish_ID = Dishes.ID 	-- есть ли в Order_Dishes запись с таким же Dish_ID
);










SELECT Dishes.ID, Dishes.Name
FROM Dishes
WHERE NOT EXISTS (
    SELECT 1
    FROM Order_Dishes
    WHERE Order_Dishes.Dish_ID = Dishes.ID
);



------------IN--------------
-- для проверки, содержится ли значение в указанном списке 
-- значений или в результате подзапроса

-- найти блюда, которые относятся к типам "Десерт", "Салат" или "Закуска"
SELECT ID, Name, Dish_Type
FROM Dishes
WHERE Dish_Type IN ('Десерт', 'Салат', 'Закуска');


------------ALL--------------
-- проверяет, что выражение соответствует всем значениям, возвращаемым подзапросом
-- + требует оператор сравнения

-- найти официантов, которые получают зарплату ниже, чем все официанты, нанятые до 2023 года
--SELECT ID, Last_Name, Salary
--FROM Waiters
--WHERE Salary > ALL (
--    SELECT Salary 
--    FROM Waiters
--    -- выбираем только тех, чья зарплата выше максимальной среди тех,
--    -- кто был нанят до 2023 года
--    WHERE Hiring_Date > '2023-01-01'
--);


-- найти официантов, которые получают зарплату ниже, чем все официанты, нанятые до 2020 года
SELECT ID, Last_Name, Salary
FROM Waiters
WHERE Salary < ALL (
    SELECT Salary 
    FROM Waiters
    WHERE Hiring_Date < '2020-01-01'
);


------------SOME/ANY--------------
-- идентичные предикаты
-- проверяют, что условие выполняется хотя бы для одного 
-- значения из результатов подзапроса

-- найти официантов, у которых зарплата меньше, чем хотя 
-- бы у одного официанта, нанятого после 2023 года.
SELECT ID, Last_Name, Salary
FROM Waiters
WHERE Salary < ANY (
    SELECT Salary
    FROM Waiters
    WHERE Hiring_Date > '2023-01-01'
);


------------BETWEEN--------------
-- для фильтрации значений в заданном диапазоне, включая границы

-- вывести блюда, цена которых от 300 до 700 рублей
SELECT ID, Name, Price
FROM Dishes
WHERE Price BETWEEN 300 AND 700;


------------LIKE--------------
-- для поиска строковых данных по шаблону

-- найти блюда, в названии которых третий символ — буква "р"
SELECT ID, Name
FROM Dishes
WHERE Name LIKE '__р%';


------------ILIKE--------------
-- то же самое, что LIKE, но без учета регистра

-- поиск всех гостей с фамилией, начинающейся на "иван"
SELECT ID, Last_Name, First_Name
FROM Guests
WHERE Last_Name ILIKE 'иван%';


-----------------------------------------
----------------Блок 4-------------------
-----------------------------------------

------------CASE--------------
-- используется для выполнения логических проверок и 
-- возврата значений на основе условий (аналог if...else)

-- показать список блюд и указать категорию их стоимости
SELECT Name,
       Price,
       CASE
           WHEN Price < 500 THEN 'Дешевое'
           WHEN Price BETWEEN 500 AND 900 THEN 'Среднее'
           ELSE 'Дорогое'
       END
FROM Dishes;


-----------------------------------------
----------------Блок 5-------------------
-----------------------------------------

------------CAST--------------
-- используется для явного преобразования данных из одного типа в другой

-- нужно вывести дату заказа в текстовом формате
SELECT ID, CAST(Order_Date AS VARCHAR) AS Order_Date_Text
FROM Orders;


------------::--------------
-- используется как краткая форма для приведения типов данных
-- по сути то же, что и CAST

-- нужно вывести дату заказа в текстовом формате
SELECT ID, Order_Date::VARCHAR AS Order_Date_Text
FROM Orders;


------------COALESCE--------------
-- возвращает первое ненулевое значение из списка аргументов

INSERT INTO Guests (
    Last_Name, First_Name, Patronymic, Birth_Date, Total_Order_Amount, Regular_Client
) VALUES (
    'Смирнов', 'Алексей', NULL, '1990-05-15', 1500.00, TRUE
);

 -- заменяем NULL на '—'
SELECT ID, Last_Name, First_Name, 
       COALESCE(Patronymic, '—') AS Patronymic
FROM Guests;

DELETE FROM Guests
WHERE Last_Name = 'Смирнов'
  AND First_Name = 'Алексей'
  AND Patronymic IS NULL
  AND Birth_Date = '1990-05-15';


------------NULLIF--------------
-- используется для сравнения двух значений: если они равны, функция 
-- возвращает NULL; если значения не равны, она возвращает первое значение

-- хотим вычислить средний чек по заказам
SELECT AVG(NULLIF(Order_Amount, 0)) AS Avg_Order_Amount
FROM Orders;


------------GREATEST--------------
-- возвращает наибольшее значение из переданных аргументов

-- если у гостя сумма заказов < 5000, выводится 5000
-- если > 5000, то выводится эта сумма
-- где-то может быть нужен минимальный порог...
SELECT ID, Last_Name, First_Name, 
       GREATEST(Total_Order_Amount, 5000) AS Adjusted_Amount
FROM Guests;


------------LEAST--------------
-- возвращает наименьшее значение из переданных аргументов

-- если у гостя сумма заказов > 2000, выводится 2000
-- если < 5000, то выводится эта сумма
-- где-то может быть нужен максимальный порог...
SELECT ID, Last_Name, First_Name, 
       LEAST(Total_Order_Amount, 2000) AS Discount_Base
FROM Guests;


-----------------------------------------
----------------Блок 6-------------------
-----------------------------------------

------------LENGTH--------------
-- возвращает количество символов в строке

-- найти поставщиков с самым длинным названием компании
SELECT ID, Name, LENGTH(Name) AS Name_Length
FROM Suppliers
ORDER BY Name_Length DESC;


------------CHR(n)--------------
-- возвращает символ, соответствующий указанному коду Unicode 

-- цены из таблицы Products будут выводиться с символом валюты
SELECT Name, 
       Unit_Price || ' ' || CHR(8381) AS Price_With_Ruble
FROM Products;


------------STRPOS--------------
-- используется для поиска позиции первого вхождения подстроки в строке

-- ищем заказы, сделанные в промежутке с 12:00 до 14:00
SELECT ID, Order_Date, Order_Time
FROM Orders
WHERE STRPOS(Order_Time::TEXT, '12') = 1 
   OR STRPOS(Order_Time::TEXT, '13') = 1 
   OR STRPOS(Order_Time::TEXT, '14') = 1;


------------OVERLAY--------------
-- позволяет заменить часть строки на другую строку, 
-- начиная с указанной позиции и на указанное количество символов

-- номера телефонов поставщиков нужно частично скрыть
SELECT Contact_Info,
       OVERLAY(Contact_Info PLACING '***-**' FROM 5 FOR 5) AS Masked_Contact
FROM Suppliers;


------------SUBSTRING--------------
-- позволяет извлечь часть строки из указанной позиции 
-- на указанное количество символов

-- хотим извлечь из даты только год
SELECT Expiration_Date,
       SUBSTRING(CAST(Expiration_Date AS VARCHAR) FROM 1 FOR 4) AS Year
FROM Products;


------------POSITION--------------
-- используется для поиска индекса первого вхождения подстроки в строке

-- определить, на какой позиции в строке с общей суммой заказов 
-- находится точка, чтобы понять порядок величины суммы
-- я ничего лучше не придумала...
SELECT ID,
       Last_Name,
       First_Name,
       Total_Order_Amount,
       POSITION('.' IN Total_Order_Amount::TEXT) AS Point_Position
FROM Guests;


------------REPLACE--------------
-- заменяет в строке все вхождения указанной подстроки на другую подстроку

-- исправляем неправильно написанные единицы измерения продуктов
SELECT ID, 
       Name, 
       REPLACE(REPLACE(Unit, 'кг.', 'кг'), 'л.', 'л') AS Corrected_Unit
FROM Products;


------------STUFF--------------
-- не поддерживается в PostgreSQL?


------------LOWER--------------
-- преобразует все символы строки к нижнему регистру

-- нужно сравнить названия без учета регистра или просто привести их к общему виду
SELECT ID, 
       Name,
       LOWER(Name) AS Normalized_Name
FROM Dishes;


------------UPPER--------------
-- преобразует все символы строки к верхнему регистру

-- в целом, то же самое
SELECT ID, 
       Name,
       UPPER(Name) AS Normalized_Name
FROM Dishes;


------------BTRIM/LTRIM--------------
-- BTRIM - обрезает символы с обоих концов строки
-- LTRIM - обрезает символы только с начала строки

-- удаляем пробелы с обеих сторон
SELECT ID, 
       Name, 
       BTRIM(Name) AS Trimmed_Name
FROM Dishes;


 -- убрать "+" в номерах телефонов поставщиков
SELECT ID, 
       Contact_Info, 
       LTRIM(Contact_Info, '+') AS Corrected_Contact
FROM Suppliers;


-----------------------------------------
----------------Блок 7-------------------
-----------------------------------------

------------NOW--------------
-- возвращает текущие дату и время в формате, например, 2025-03-20 13:42:07.54321

-- получить список заказов, которые были оформлены за последние 6 дней
SELECT ID, Guest_ID, Order_Time, Order_Amount
FROM Orders
WHERE (Order_Date + Order_Time) >= NOW() - (INTERVAL '6 days');


------------CURRENT_DATE--------------
-- возвращает текущую дату без учета времени

-- получить список всех заказов, сделанных сегодня
SELECT ID, Guest_ID, Order_Date, Order_Time
FROM Orders
WHERE Order_Date = CURRENT_DATE;


------------CURRENT_TIME--------------
-- текущее время без учета даты

-- найти все заказы, сделанные после 18:00
SELECT ID, Guest_ID, Order_Date, Order_Time
FROM Orders
WHERE Order_Time > '18:00:00';


------------CURRENT_TIMESTAMP--------------
-- возвращает текущее значение даты и времени
-- может быть с временной зоной (YYYY-MM-DD hh:mm:ss.ssssss+timezone) и без
-- учитывает установленный часовой пояс в системе

SELECT CURRENT_TIMESTAMP;

-- исключить временную зону
SELECT CURRENT_TIMESTAMP::timestamp;


------------AGE--------------
-- вычисляет разницу между двумя датами и возвращает её в виде интервала

-- рассчитать возраст гостей по их дате рождения
SELECT ID, 
       Last_Name, 
       First_Name, 
       AGE(CURRENT_DATE, Birth_Date) AS Guest_Age
FROM Guests;


------------DATE_PART--------------
-- извлекает определенную часть даты/времени, например, год, месяц, день, час, минута

-- извлечь месяц и день для анализа сезонности заказов
SELECT ID, 
       Order_Amount,
       DATE_PART('month', Order_Date) AS Order_Month,
       DATE_PART('day', Order_Date) AS Order_Day
FROM Orders;


------------EXTRACT--------------
-- используется для извлечения определенной части даты или времени, аналогично DATE_PART()

-- извлечь год из даты рождения гостей
SELECT ID, 
       Last_Name, 
       First_Name, 
       EXTRACT(YEAR FROM Birth_Date) AS Birth_Year
FROM Guests;


------------LOCALTIMESTAMP--------------
-- возвращает текущие дату и время без указания часового пояса

-- получить все заказы, сделанные за последние 3 дня
SELECT ID, Guest_ID, Order_Amount, Order_Date
FROM Orders
WHERE Order_Date >= LOCALTIMESTAMP - INTERVAL '3 days';

-----------------------------------------
----------------Блок 8-------------------
-----------------------------------------


------------MIN/MAX--------------
-- поиск минимального и максимального значений в указанном столбце

-- минимальная и максимальная стоимость блюд
SELECT 
    MIN(Price) AS Min_Price, 
    MAX(Price) AS Max_Price
FROM Dishes;


------------AVG--------------
-- вычисляет среднее арифметическое значений в указанном столбце

-- найти среднюю зарплату среди всех официантов
SELECT AVG(Salary) AS Avg_Waiter_Salary
FROM Waiters;

------------SUM--------------
-- вычисляет сумму значений в указанном столбце

-- общее количество всех доставленных товаров
SELECT SUM(Quantity) AS Total_Products_Received
FROM Deliveries;

------------COUNT--------------
-- используется для подсчета количества строк или значений в указанном столбце

-- посчитаем, сколько поставщиков работают в определённом регионе
SELECT COUNT(*) AS Moscow_Suppliers 	-- COUNT(*) - общее количество строк в таблице
FROM Suppliers
WHERE Region = 'Москва';


------------GROUPBY--------------
-- группирует строки по значениям в указанных столбцах
-- (часто используется вместе с агрегатными функциями (COUNT, SUM, AVG, MIN, MAX))

-- сколько заказов выполнил каждый официант
SELECT 
    Waiters.Last_Name,
    Orders.Waiter_ID,
    COUNT(*) AS Total_Orders	-- количество заказов
FROM Orders
JOIN Waiters 
	ON Orders.Waiter_ID = Waiters.ID	-- объединяем таблицы по ID официанта
GROUP BY Waiters.Last_Name, 	-- группируем по фамилии и ID официанта
		 Orders.Waiter_ID;


------------HAVING--------------
-- используется для фильтрации групп данных после выполнения GROUP BY

-- показать официантов, которые выполнили 3 и более заказов
SELECT 
 	Waiters.ID,
    Waiters.Last_Name,
    COUNT(Orders.ID) AS Total_Orders
FROM Orders
JOIN Waiters ON Orders.Waiter_ID = Waiters.ID
GROUP BY Waiters.ID, 		-- группируем по ID и фамилии официанта
		 Waiters.Last_Name	
HAVING COUNT(Orders.ID) >= 3;	-- оставляем тех, у кого >= 3 заказов





