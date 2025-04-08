-- расчет общей выручки за заданный период
CREATE OR REPLACE FUNCTION total_revenue(start_date DATE, end_date DATE)
RETURNS NUMERIC AS $$
DECLARE
    revenue NUMERIC;
BEGIN
    SELECT COALESCE(SUM(Order_Amount), 0)
    INTO revenue
    FROM Orders
    WHERE Order_Date BETWEEN start_date AND end_date
      AND Status = 'Выполнен';
      
    RETURN revenue;
END;
$$ LANGUAGE plpgsql;

--drop function total_revenue

SELECT total_revenue('2025-01-01', '2025-03-10');


---------------------------------------------
---------------------------------------------

-- расчет стоимости заказа с учетом скидки
CREATE OR REPLACE FUNCTION order_with_discount(order_id INT) 
RETURNS FLOAT AS $$
DECLARE
    v_order_amount FLOAT;
    v_discount_size FLOAT DEFAULT 0;
    v_guest_id INT;
BEGIN
    -- берем сумму заказа и ID гостя
    SELECT Order_Amount, Guest_ID
    INTO v_order_amount, v_guest_id
    FROM Orders
    WHERE ID = order_id;
    
    -- проверяем, есть ли у гостя скидка
    SELECT COALESCE(MAX(Discount_Size), 0)
    INTO v_discount_size
    FROM Discounts
    WHERE Guest_ID = v_guest_id;
    
    -- применяем скидку, если она есть
    IF v_discount_size > 0 THEN
        v_order_amount := v_order_amount * (1 - v_discount_size / 100);
    END IF;
    
    RETURN v_order_amount;
END;
$$ LANGUAGE plpgsql;


SELECT order_with_discount(399);
-- 399	123	850	2025-03-07	22:18:10	1867.69	Завершен
-- клиент постоянный -> скидка



---------------------------------------------
---------------------------------------------

-- получение списка просроченных продуктов
CREATE OR REPLACE FUNCTION get_expired_products(check_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE (
    product_id INT,
    product_name VARCHAR(100),
    expiration_date DATE,
    days_expired INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        Products.ID AS product_id,
        Products.Name AS product_name,
        Products.Expiration_Date AS expiration_date,
        (check_date - Products.Expiration_Date) AS days_expired
    FROM Products
    WHERE Products.Expiration_Date < check_date;
END;
$$ LANGUAGE plpgsql;

SELECT get_expired_products('2027-01-20');
SELECT get_expired_products();

---------------------------------------------
---------------------------------------------

-- список поставщиков из определенного региона
CREATE OR REPLACE FUNCTION suppliers_by_region(s_region VARCHAR(100)) 
RETURNS SETOF Suppliers AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM Suppliers
    WHERE Suppliers.Region = s_region;
END;
$$ LANGUAGE plpgsql;

SELECT suppliers_by_region('Саратов');


---------------------------------------------
---------------------------------------------

-- средняя стоимость блюд заданного типа
CREATE OR REPLACE FUNCTION avg_price(p_dish_type VARCHAR(50))
RETURNS FLOAT AS $$
DECLARE
    dish_record RECORD;
    total_price FLOAT := 0;
    dish_count INTEGER := 0;
BEGIN
    -- для всех блюд заданного типа
    FOR dish_record IN 
        SELECT Price FROM Dishes 
        WHERE Dish_Type = p_dish_type
    LOOP
        -- суммируем цены и считаем количество блюд
        total_price := total_price + dish_record.Price;
        dish_count := dish_count + 1;
    END LOOP;
    
    -- возвращаем среднюю цену
    IF dish_count > 0 THEN
        RETURN ROUND(total_price / dish_count);
    ELSE
        RETURN 0;
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT avg_price('Суп');






