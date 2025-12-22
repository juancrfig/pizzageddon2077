-------------------------------------------------------------------------------
-- SEED DATA: PIZZAS (Cyberpunk 2077 Style)
-------------------------------------------------------------------------------
INSERT INTO pizzas (name, prep_time_seconds, initial_stock, current_stock) VALUES
('The Arasaka Special', 480, 50, 50),
('Maelstrom Meat-Lover', 600, 30, 30),
('Netrunner’s Delight', 300, 100, 100),
('Chooh2 Spicy BBQ', 420, 40, 40),
('Braindance Basil & Mozz', 360, 60, 60),
('Edgerunner Supreme', 540, 25, 25),
('Kiroshi Olive Mix', 300, 80, 80),
('Sandevistan Salami', 240, 50, 50),
('Chrome & Crust', 450, 35, 35),
('Pacifico Pineapple', 390, 45, 45);

-------------------------------------------------------------------------------
-- SEED DATA: OVENS
-------------------------------------------------------------------------------
INSERT INTO ovens (status, current_temperature_celsius) VALUES
('idle', 180),
('idle', 180),
('idle', 180),
('idle', 200),
('idle', 200),
('idle', 200),
('idle', 220),
('idle', 220),
('idle', 220);
