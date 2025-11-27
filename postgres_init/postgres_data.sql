-- FACTORIES
INSERT INTO factory (id, name, location) VALUES
('F001', 'Burger Factory', 'Berlin'),
('F002', 'Veggie Factory', 'Amsterdam'),
('F003', 'Chicken Factory', 'Warsaw'),
('F004', 'Sandwich Factory', 'Copenhagen');

-- MACHINES
INSERT INTO machine (id, name, model, status, factory_id) VALUES
('M001', 'GrillMaster 3000', 'GMX-3000', 'Active', 'F001'),
('M002', 'VeggiePress 2000', 'VPX-2000', 'Active', 'F002'),
('M003', 'ChickenRoast 150', 'CR-150', 'Active', 'F003'),
('M004', 'Toaster Elite', 'TE-500', 'Active', 'F004');

-- MATERIALS
INSERT INTO material (id, name, category, source_factory_id) VALUES
('MAT001', 'Beef Patty', 'Meat', 'F001'),
('MAT002', 'Sesame Bun', 'Bread', 'F001'),
('MAT003', 'Tofu Patty', 'Plant Protein', 'F002'),
('MAT004', 'Lettuce', 'Vegetable', 'F002'),
('MAT005', 'Chicken Fillet', 'Meat', 'F003'),
('MAT006', 'Wholegrain Bread', 'Bread', 'F004');

-- PRODUCTS
INSERT INTO product (id, name, type, created_at, factory_id, machine_id) VALUES
('P001', 'Classic Burger', 'Food', '2025-10-29T12:00:00Z', 'F001', 'M001'),
('P002', 'Veggie Burger', 'Food', '2025-10-29T13:00:00Z', 'F002', 'M002'),
('P003', 'Chicken Burger', 'Food', '2025-10-29T14:00:00Z', 'F003', 'M003'),
('P004', 'Club Sandwich', 'Food', '2025-10-29T15:00:00Z', 'F004', 'M004');

-- PRODUCT ↔ MATERIAL RELATIONS
INSERT INTO product_material (product_id, material_id) VALUES
('P001', 'MAT001'),
('P001', 'MAT002'),
('P002', 'MAT003'),
('P002', 'MAT004'),
('P003', 'MAT005'),
('P003', 'MAT002'),
('P004', 'MAT006'),
('P004', 'MAT005'),
('P004', 'MAT004');
