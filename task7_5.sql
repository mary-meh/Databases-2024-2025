-- before insert
-- проверка срока годности продукта при добавлении поставки
CREATE OR REPLACE FUNCTION check_expiry_date()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Expiration_Date < CURRENT_DATE THEN
        RAISE EXCEPTION 'Нельзя добавить продукт с истекшим сроком годности';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_products_expiry_check
BEFORE INSERT ON Products
FOR EACH ROW EXECUTE FUNCTION check_expiry_date();



-- ошибка
INSERT INTO Products (Name, Expiration_Date, Unit, Unit_Price)
VALUES ('Молоко', '2023-01-01', 'л', 80.50);

-- норм
INSERT INTO Products (Name, Expiration_Date, Unit, Unit_Price)
VALUES ('Сок', '2027-01-01', 'л', 120.00);



---------------------------------------------
---------------------------------------------

-- after insert (компенсирующий... вроде...)

-- обновление суммы заказа при добавлении блюда
CREATE OR REPLACE FUNCTION update_order_total()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Orders 
    SET Order_Amount = Order_Amount + (
        SELECT Price FROM Dishes WHERE ID = NEW.Dish_ID) * NEW.Quantity
    WHERE ID = NEW.Order_ID;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_order_dishes_update_total
AFTER INSERT ON Order_Dishes
FOR EACH ROW EXECUTE FUNCTION update_order_total();



-- блюдо
INSERT INTO Dishes (Name, Dish_Type, Price) 
VALUES ('Стейк', 'Горячее', 1200.00) 
RETURNING ID;

-- создаем заказ (изначально сумма 0)
INSERT INTO Orders (Guest_ID, Waiter_ID, Order_Date, Order_Time, Order_Amount, Status) 
VALUES (5000, 2, CURRENT_DATE, CURRENT_TIME, 0, 'В процессе') 
RETURNING ID;

---

-- добавляем блюдо в заказ
INSERT INTO Order_Dishes (Order_ID, Dish_ID, Quantity) 
VALUES (5009, 5002, 2);

-- проверяем сумму заказа
SELECT Order_Amount FROM Orders WHERE ID = 5006;


---------------------------------------------
---------------------------------------------

-- instead of insert
-- проверка, что цена блюда указана
-- если нет - ошибка

CREATE VIEW Dishes_Insert_View AS
SELECT * FROM Dishes;

CREATE OR REPLACE FUNCTION insert_dish()
RETURNS TRIGGER AS $$
BEGIN
    -- проверяем цену на нулл
    IF NEW.Price IS NULL THEN
        RAISE EXCEPTION 'Цена блюда "%" не может быть NULL', NEW.Name;
    END IF;
    
    -- вставляем в нашу таблицу
    INSERT INTO Dishes (Name, Dish_Type, Price, Country_of_Origin)
    VALUES (NEW.Name, NEW.Dish_Type, NEW.Price, NEW.Country_of_Origin);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_insert_dish
INSTEAD OF INSERT ON Dishes_Insert_View
FOR EACH ROW EXECUTE FUNCTION insert_dish();




-- ошибка
INSERT INTO Dishes_Insert_View (Name, Dish_Type, Country_of_Origin) 
VALUES ('Салат Греческий', 'Салат', 'Греция');

-- норм
INSERT INTO Dishes_Insert_View (Name, Dish_Type, Price, Country_of_Origin) 
VALUES ('Стейк Рибай', 'Горячее', 1200, 'США');

---------------------------------------------
---------------------------------------------

-- before update
-- запрет изменения типа блюда
CREATE OR REPLACE FUNCTION type_change()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Dish_Type != OLD.Dish_Type THEN
        RAISE EXCEPTION 'Нельзя изменять тип блюда';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_type_check
BEFORE UPDATE ON Dishes
FOR EACH ROW EXECUTE FUNCTION type_change();

-- ошибка
UPDATE Dishes
SET Dish_Type = 'Салат'
WHERE ID = 1;


---------------------------------------------
---------------------------------------------

-- after update (и компенсирующий)
-- при изменении кол-ва блюд корректирует сумму заказа
CREATE OR REPLACE FUNCTION recalculate_order()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Orders
    SET Order_Amount = (
        SELECT SUM(Dishes.Price * Order_Dishes.Quantity)
        FROM Order_Dishes
        JOIN Dishes ON Order_Dishes.Dish_ID = Dishes.ID
        WHERE Order_Dishes.Order_ID = NEW.Order_ID
    )
    WHERE ID = NEW.Order_ID;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_recalculate_order
AFTER UPDATE ON Order_Dishes
FOR EACH ROW
EXECUTE FUNCTION recalculate_order();




UPDATE Order_Dishes
SET Quantity = 3
WHERE Order_ID = 5000 AND Dish_ID = 3474;

-- изначально заказ был
-- id заказа 5000, id блюда 3474, кол-во 1
-- id заказа 5000, id блюда 316, кол-во	6
-- сумма = 1545

-- заказ стал
-- id заказа 5000, id блюда 3474, кол-во 3 (изменили)
-- id заказа 5000, id блюда 316, кол-во	6
-- сумма = 9813


-- проверим сумму заказа в таблице Orders
SELECT Order_Amount FROM Orders WHERE ID = 5000;


---------------------------------------------
---------------------------------------------


-- instead of update
-- запрещаем обновлять айди блюда

-- представление для работы
CREATE VIEW Dishes_View AS
SELECT * FROM Dishes;

CREATE OR REPLACE FUNCTION instead_of_update_dish()
RETURNS TRIGGER AS $$
BEGIN
    
    IF NEW.ID <> OLD.ID THEN
        RAISE EXCEPTION 'Изменение ID блюда запрещено';
    END IF;
    
    -- разрешаем обновление только "разрешенных" полей
    UPDATE Dishes SET
        Name = NEW.Name,
        Dish_Type = NEW.Dish_Type,
        Price = NEW.Price,
        Country_of_Origin = NEW.Country_of_Origin
    WHERE ID = OLD.ID;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_instead_of_update_dish
INSTEAD OF UPDATE ON Dishes_View
FOR EACH ROW EXECUTE FUNCTION instead_of_update_dish();


INSERT INTO Dishes (Name, Dish_Type, Price) 
VALUES ('Паста Карбонара', 'Горячее', 450.00);

-- ошибка
UPDATE Dishes_View 
SET ID = 100 
WHERE Name = 'Паста Карбонара';

-- норм
UPDATE Dishes_View 
SET Price = 500.00, Country_of_Origin = 'Италия' 
WHERE Name = 'Паста Карбонара';


---------------------------------------------
---------------------------------------------


-- before delete
-- запрет удаления продуктов, используемых в рецептах 
CREATE OR REPLACE FUNCTION product_delete()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM Recipes WHERE Product_ID = OLD.ID) THEN
        RAISE EXCEPTION 'Нельзя удалить продукт, используемый в рецептах';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_products_delete
BEFORE DELETE ON Products
FOR EACH ROW EXECUTE FUNCTION product_delete();

-- ошибка
DELETE FROM Products WHERE ID = 1;


---------------------------------------------
---------------------------------------------

-- after delete (и компенсирующий)
-- уволенных официантов складываем в отдельную таблицу

-- "архивная" таблица
CREATE TABLE Waiters_Archive (
    ID INT,
    Last_Name VARCHAR(50),
    First_Name VARCHAR(50),
    Patronymic VARCHAR(50),
    Salary FLOAT,
    Hiring_Date DATE,
    Deleted_At TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE OR REPLACE FUNCTION archive_deleted_waiter()
RETURNS TRIGGER AS $$
BEGIN
    -- удаленные данные - в архив
    INSERT INTO Waiters_Archive (ID, Last_Name, First_Name, Patronymic, Salary, Hiring_Date)
    VALUES (
        OLD.ID,
        OLD.Last_Name,
        OLD.First_Name,
        OLD.Patronymic,
        OLD.Salary,
        OLD.Hiring_Date
    );
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_after_delete_waiter
AFTER DELETE ON Waiters
FOR EACH ROW EXECUTE FUNCTION archive_deleted_waiter();


INSERT INTO Waiters (Last_Name, First_Name, Patronymic, Salary, Hiring_Date)
VALUES ('Воробышев', 'Алексей', 'Валерьевич', 35000, '2023-01-15');

DELETE FROM Waiters 
WHERE Last_Name = 'Воробышев'
  AND First_Name = 'Алексей'
  AND Patronymic = 'Валерьевич'
  AND Salary = 35000
  AND Hiring_Date = '2023-01-15';

SELECT * FROM Waiters_Archive;

---------------------------------------------
---------------------------------------------


-- instead of delete
-- если у официанта есть заказы, его удалить нельзя
-- если нету - можно


CREATE VIEW Waiters_View AS
SELECT * FROM Waiters;

CREATE OR REPLACE FUNCTION waiter_delete()
RETURNS TRIGGER AS $$
BEGIN
    -- проверка, есть ли заказы у официанта
    IF EXISTS (
        SELECT 1 FROM Orders 
        WHERE Waiter_ID = OLD.ID
    ) THEN
        RAISE EXCEPTION 'Нельзя удалить официанта "% %": у него есть заказы', 
                        OLD.First_Name, OLD.Last_Name;
    END IF;
    
    -- если заказов нет, то удаление
    DELETE FROM Waiters WHERE ID = OLD.ID;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_instead_of_delete_waiter
INSTEAD OF DELETE ON Waiters_View
FOR EACH ROW EXECUTE FUNCTION waiter_delete();




-- без заказов
INSERT INTO Waiters (Last_Name, First_Name, Patronymic, Salary, Hiring_Date)
VALUES ('Иванов', 'Петр', 'Сидорович', 30000, '2023-01-15');

SELECT * from Waiters_View 


-- удаляем через представлени
DELETE FROM Waiters_View 
WHERE Last_Name = 'Иванов'
AND First_Name = 'Петр'
AND Patronymic = 'Сидорович'
AND Hiring_Date = '2023-01-15';


-- официант с заказами
-- ошибка
DELETE FROM Waiters_View WHERE ID = 3;











