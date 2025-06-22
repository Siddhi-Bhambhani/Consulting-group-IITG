use for_ext_use;
-- In SQL (run via script or DB tool)
SELECT * FROM inventory_forecasting WHERE Date IS NULL;
SELECT * FROM inventory_forecasting WHERE Store_ID IS NULL;
SELECT * FROM inventory_forecasting WHERE Product_ID IS NULL;

-- Making Tables according to ERD Diagram
CREATE TABLE Store (
  Store_ID varchar(255) PRIMARY KEY,
  Region varchar(255)
);

CREATE TABLE Product (
  Product_ID varchar(255) PRIMARY KEY,
  Category varchar(255),
  Price float,
  Seasonality varchar(255)
);

CREATE TABLE Inventory (
  Inventory_ID int PRIMARY KEY AUTO_INCREMENT,
  Date date,
  Store_ID varchar(255),
  Product_ID varchar(255),
  Inventory_Level int,
  Units_Sold int,
  Units_Ordered int,
  Demand_Forecast float
);

CREATE TABLE Promotion (
  Promotion_ID int PRIMARY KEY AUTO_INCREMENT,
  Date date,
  Store_ID varchar(255),
  Product_ID varchar(255),
  Discount int,
  Holiday_Promotion boolean
);

CREATE TABLE Weather (
  Weather_ID int PRIMARY KEY AUTO_INCREMENT,
  Date date,
  Store_ID varchar(255),
  Weather_Condition varchar(255)
);

CREATE TABLE CompetitorPricing (
  Competitor_Pricing_ID int PRIMARY KEY AUTO_INCREMENT,
  Date date,
  Product_ID varchar(255),
  Competitor_Pricing float
);

-- Adding foreign keys and insertions
ALTER TABLE Inventory ADD FOREIGN KEY (Store_ID) REFERENCES Store (Store_ID);
ALTER TABLE Inventory ADD FOREIGN KEY (Product_ID) REFERENCES Product (Product_ID);
ALTER TABLE Promotion ADD FOREIGN KEY (Store_ID) REFERENCES Store (Store_ID);
ALTER TABLE Promotion ADD FOREIGN KEY (Product_ID) REFERENCES Product (Product_ID);
ALTER TABLE Weather ADD FOREIGN KEY (Store_ID) REFERENCES Store (Store_ID);
ALTER TABLE CompetitorPricing ADD FOREIGN KEY (Product_ID) REFERENCES Product (Product_ID);

-- Stock level summaries
SELECT Store_ID, Product_ID, SUM(Inventory_Level) AS Total_Inventory
FROM Inventory
GROUP BY Store_ID, Product_ID;

-- Low inventory Detection
SELECT Store_ID, Product_ID, Inventory_Level
FROM Inventory
WHERE Inventory_Level < 1000;

-- Reorder point Estimation
SELECT 
  Store_ID,
  Product_ID,
  ROUND(AVG(daily_units_sold) * 7, 2) AS Reorder_Point
FROM (
  SELECT Store_ID, Product_ID, Date, SUM(Units_Sold) AS daily_units_sold
  FROM Inventory
  GROUP BY Store_ID, Product_ID, Date
) AS daily_sales
GROUP BY Store_ID, Product_ID
ORDER BY Reorder_Point DESC;

-- Inventory Turnover
SELECT 
  s.Product_ID,
  s.total_sold,
  ROUND(i.avg_inventory, 2) AS avg_inventory,
  ROUND(s.total_sold / i.avg_inventory, 2) AS inventory_turnover_ratio
FROM (
  SELECT Product_ID, SUM(Units_Sold) AS total_sold
  FROM Inventory
  GROUP BY Product_ID
) AS s
JOIN (
  SELECT Product_ID, AVG(Inventory_Level) AS avg_inventory
  FROM Inventory
  GROUP BY Product_ID
) AS i ON s.Product_ID = i.Product_ID
ORDER BY inventory_turnover_ratio DESC;

-- Summary KPI Report
SELECT
  COUNT(CASE WHEN Inventory_Level = 0 THEN 1 END) AS stockouts,
  ROUND(AVG(Inventory_Level), 2) AS avg_stock_level,
  ROUND(AVG(DATEDIFF(CURDATE(), Date)), 2) AS avg_inventory_age
FROM Inventory;

-- Fast vs Slow Movers
SELECT 
  Product_ID,
  SUM(Units_Sold) AS total_units_sold,
  CASE 
    WHEN SUM(Units_Sold) > 10000 THEN 'Fast Mover'
    WHEN SUM(Units_Sold) BETWEEN 1000 AND 10000 THEN 'Moderate'
    ELSE 'Slow Mover'
  END AS Category
FROM Inventory
GROUP BY Product_ID
ORDER BY total_units_sold DESC;

-- Promotion Impact on Sales
SELECT 
    p.Discount,
    ROUND(AVG(i.Units_Sold), 2) AS Avg_Units_Sold
FROM Promotion p
JOIN Inventory i ON p.Date = i.Date AND p.Store_ID = i.Store_ID AND p.Product_ID = i.Product_ID
GROUP BY p.Discount
ORDER BY p.Discount DESC;

-- Holiday vs regular Promotions 
SELECT 
    p.Holiday_Promotion,
    ROUND(AVG(i.Units_Sold), 2) AS Avg_Units_Sold
FROM Promotion p
JOIN Inventory i ON p.Date = i.Date AND p.Store_ID = i.Store_ID AND p.Product_ID = i.Product_ID
GROUP BY p.Holiday_Promotion;

-- Weather impact on sales
SELECT 
    w.Weather_Condition,
    ROUND(AVG(i.Units_Sold), 2) AS Avg_Units_Sold
FROM Weather w
JOIN Inventory i ON w.Date = i.Date AND w.Store_ID = i.Store_ID
GROUP BY w.Weather_Condition;





