CREATE TABLE IF NOT exists Products (
    ID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Expiration_Date DATE,
    Unit VARCHAR(20) NOT null check (
    	Unit in ('кг', 'л', 'г', 'мл', 'шт')
    ),
    Unit_Price FLOAT NOT NULL 
);


CREATE TABLE IF NOT exists Suppliers (
    ID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Contact_Info VARCHAR(255) NOT NULL,
    Region VARCHAR(100) NOT NULL
);


CREATE table IF NOT EXISTS Deliveries (
    ID SERIAL PRIMARY KEY,
    Supplier_ID INTEGER NOT NULL,
    Product_ID INTEGER NOT NULL,
    Delivery_Date DATE NOT NULL,
    Quantity INTEGER NOT NULL,
    FOREIGN KEY (Supplier_ID) REFERENCES Suppliers(ID),
    FOREIGN KEY (Product_ID) references Products(ID)
);


CREATE TABLE IF NOT exists Storage_Time (
    ID SERIAL PRIMARY KEY,
    Product_ID INTEGER NOT NULL,
    Storage_Duration INTEGER NOT NULL,
    Time_Unit VARCHAR(20) NOT NULL CHECK (
        Time_Unit IN ('ч', 'дн', 'нед', 'г')
    ),
    FOREIGN KEY (Product_ID) REFERENCES Products(ID)
);


CREATE TABLE IF NOT exists Dishes (
    ID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Dish_Type VARCHAR(50) NOT NULL CHECK (
        Dish_Type IN ('Десерт', 'Суп', 'Горячее', 'Салат', 'Закуска', 'Фастфуд', 'Гарнир')
    ),
    Price FLOAT NOT NULL,
    Country_of_Origin VARCHAR(100)
);


CREATE TABLE IF NOT exists Recipes (
    ID SERIAL PRIMARY KEY,
    Dish_ID INTEGER NOT NULL,
    Product_ID INTEGER NOT NULL,
    Product_Quantity FLOAT NOT NULL,
    Unit VARCHAR(50) NOT NULL,
    FOREIGN KEY (Dish_ID) REFERENCES Dishes(ID),
    FOREIGN KEY (Product_ID) REFERENCES Products(ID)
);

 
CREATE TABLE IF NOT exists Waiters (
    ID SERIAL PRIMARY KEY,
    Last_Name VARCHAR(50) NOT NULL,
    First_Name VARCHAR(50) NOT NULL,
    Patronymic VARCHAR(50),
    Salary FLOAT NOT null,
    Hiring_Date DATE NOT NULL
);


CREATE TABLE IF NOT exists Guests (
    ID SERIAL PRIMARY KEY,
    Last_Name VARCHAR(50) NOT NULL,
    first_Name VARCHAR(50) NOT NULL,
    Patronymic VARCHAR(50),
    Birth_Date DATE NOT NULL,
    Total_Order_Amount Float DEFAULT 0 NOT NULL,
    Regular_Client BOOLEAN DEFAULT FALSE NOT NULL
);


CREATE TABLE IF NOT exists Orders (
    ID SERIAL PRIMARY KEY,
    Guest_ID INT NOT NULL,
    Waiter_ID INT NOT NULL,
    Order_Date DATE NOT NULL,
    Order_Time TIME NOT NULL,
    Order_Amount Float NOT NULL,
    Status VARCHAR(20) NOT NULL,
    FOREIGN KEY (Guest_ID) REFERENCES Guests(ID),
    FOREIGN KEY (Waiter_ID) REFERENCES Waiters(ID)
);


CREATE TABLE IF NOT EXISTS Discounts (
    ID SERIAL PRIMARY KEY,
    Guest_ID INTEGER NOT NULL,
    Discount_Type VARCHAR(50) NOT null,
    Discount_Size FLOAT NOT NULL,
    FOREIGN KEY (Guest_ID) REFERENCES Guests(ID)
);


CREATE TABLE IF NOT EXISTS Order_Dishes (
    Order_ID INT NOT NULL,
    Dish_ID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    PRIMARY KEY (Order_ID, Dish_ID),
    FOREIGN KEY (Order_ID) REFERENCES Orders(ID),
    FOREIGN KEY (Dish_ID) REFERENCES Dishes(ID)
);






