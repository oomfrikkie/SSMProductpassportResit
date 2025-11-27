-- FACTORIES
CREATE TABLE factory (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    location TEXT NOT NULL
);

-- MACHINES
CREATE TABLE machine (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    model TEXT NOT NULL,
    status TEXT NOT NULL,
    factory_id TEXT REFERENCES factory(id)
);

-- MATERIALS
CREATE TABLE material (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    source_factory_id TEXT REFERENCES factory(id)
);

-- PRODUCTS
CREATE TABLE product (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL,
    factory_id TEXT REFERENCES factory(id),
    machine_id TEXT REFERENCES machine(id)
);

-- PRODUCT ↔ MATERIAL (many-to-many)
CREATE TABLE product_material (
    product_id TEXT REFERENCES product(id),
    material_id TEXT REFERENCES material(id),
    PRIMARY KEY (product_id, material_id)
);
