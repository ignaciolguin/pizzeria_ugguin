CREATE TYPE order_status_enum AS ENUM ('pending', 'preparing', 'in_transit', 'delivered', 'cancelled');
CREATE TYPE payment_method_enum AS ENUM ('cash', 'debit', 'credit', 'app', 'crypto');

CREATE TABLE "customers" (
  "customer_id" serial PRIMARY KEY,
  "first_name" varchar(200) NOT NULL,
  "last_name" varchar(200) NOT NULL,
  "email" varchar(200) UNIQUE,
  "phone" varchar(200),
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "is_active" boolean NOT NULL DEFAULT TRUE
);

CREATE TABLE "addresses" (
  "address_id" serial PRIMARY KEY,
  "customer_id" int NOT NULL,
  "address_line1" varchar(200) NOT NULL,
  "address_line2" varchar(200),
  "city" varchar(50),
  "zipcode" varchar(20),
  "is_primary" boolean DEFAULT false
);

CREATE TABLE "items" (
  "item_id" serial PRIMARY KEY,
  "sku" varchar(20) UNIQUE NOT NULL,
  "name" varchar(100) NOT NULL,
  "type" varchar(100),
  "size" varchar(20),
  "base_price" decimal(10,2) NOT NULL,
  "is_active" boolean NOT NULL DEFAULT TRUE
);

CREATE TABLE "ingredients" (
  "ingredient_id" serial PRIMARY KEY,
  "name" varchar(200) NOT NULL,
  "weight" int,
  "measure" varchar(20),
  "price" decimal(10,2) NOT NULL
);

CREATE TABLE "recipes" (
  "item_id" int NOT NULL,
  "ingredient_id" int NOT NULL,
  "quantity" int NOT NULL,
  PRIMARY KEY ("item_id", "ingredient_id"),
  CONSTRAINT chk_recipes_quantity CHECK (quantity > 0)
);

CREATE TABLE "ingredient_inventory" (
  "ingredient_id" int NOT NULL,
  "quantity" int NOT NULL DEFAULT 0,
  PRIMARY KEY ("ingredient_id")
);

CREATE TABLE "shifts" (
  "shift_id" serial PRIMARY KEY,
  "day_of_week" varchar(10) NOT NULL,
  "start_time" time NOT NULL,
  "end_time" time NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "staff" (
  "staff_id" serial PRIMARY KEY,
  "first_name" varchar(100) NOT NULL,
  "last_name" varchar(100) NOT NULL,
  "position" varchar(100) NOT NULL,
  "hourly_rate" decimal(10,2) NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "rotations" (
  "rotation_id" serial PRIMARY KEY,
  "date" date NOT NULL,
  "shift_id" int NOT NULL,
  "staff_id" int NOT NULL
);

CREATE UNIQUE INDEX ON "rotations" ("date", "shift_id", "staff_id");

CREATE TABLE "orders" (
  "order_id" serial PRIMARY KEY,
  "order_number" varchar(50) UNIQUE NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz NOT NULL DEFAULT (now()),
  "customer_id" int NOT NULL,
  "address_id" int NOT NULL,
  "order_status" order_status_enum NOT NULL,
  "subtotal" decimal(10,2) NOT NULL,
  "tax_amount" decimal(10,2) NOT NULL DEFAULT 0,
  "delivery_fee" decimal(10,2) NOT NULL DEFAULT 0,
  "discount_amount" decimal(10,2) NOT NULL DEFAULT 0,
  "payment_method" payment_method_enum,
  "shift_id" int NOT NULL
);

CREATE INDEX "idx_order_customer_status_date" ON "orders" ("customer_id", "order_status", "created_at");
CREATE INDEX ON "orders" ("created_at");

CREATE TABLE "order_items" (
  "order_id" int NOT NULL,
  "item_id" int NOT NULL,
  "quantity" int NOT NULL,
  "unit_price" decimal(10,2) NOT NULL,
  PRIMARY KEY ("order_id", "item_id"),
  CONSTRAINT chk_order_items_quantity CHECK (quantity > 0)
);

CREATE TABLE "option_types" (
  "option_type_id" serial PRIMARY KEY,
  "name" varchar(50) UNIQUE NOT NULL
);

CREATE TABLE "options" (
  "option_id" serial PRIMARY KEY,
  "option_type_id" int NOT NULL,
  "name" varchar(100) UNIQUE NOT NULL,
  "price" decimal(10,2) NOT NULL DEFAULT 0
);

CREATE TABLE "order_item_options" (
  "order_id" int NOT NULL,
  "item_id" int NOT NULL,
  "option_id" int NOT NULL,
  "price_adjustment" decimal(10,2),
  "quantity" int NOT NULL DEFAULT 1,
  PRIMARY KEY ("order_id", "item_id", "option_id"),
  CONSTRAINT chk_order_item_options_quantity CHECK (quantity > 0)
);

ALTER TABLE "addresses" 
  ADD CONSTRAINT fk_addresses_customer FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id") ON DELETE RESTRICT;

ALTER TABLE "recipes" 
  ADD CONSTRAINT fk_recipes_item FOREIGN KEY ("item_id") REFERENCES "items" ("item_id") ON DELETE RESTRICT;

ALTER TABLE "recipes" 
  ADD CONSTRAINT fk_recipes_ingredient FOREIGN KEY ("ingredient_id") REFERENCES "ingredients" ("ingredient_id") ON DELETE RESTRICT;

ALTER TABLE "ingredient_inventory" 
  ADD CONSTRAINT fk_inventory_ingredient FOREIGN KEY ("ingredient_id") REFERENCES "ingredients" ("ingredient_id") ON DELETE RESTRICT;

ALTER TABLE "rotations" 
  ADD CONSTRAINT fk_rotations_shift FOREIGN KEY ("shift_id") REFERENCES "shifts" ("shift_id") ON DELETE RESTRICT;

ALTER TABLE "rotations" 
  ADD CONSTRAINT fk_rotations_staff FOREIGN KEY ("staff_id") REFERENCES "staff" ("staff_id") ON DELETE RESTRICT;

ALTER TABLE "orders" 
  ADD CONSTRAINT fk_orders_customer FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id") ON DELETE RESTRICT;

ALTER TABLE "orders" 
  ADD CONSTRAINT fk_orders_address FOREIGN KEY ("address_id") REFERENCES "addresses" ("address_id") ON DELETE RESTRICT;

ALTER TABLE "orders" 
  ADD CONSTRAINT fk_orders_shift FOREIGN KEY ("shift_id") REFERENCES "shifts" ("shift_id") ON DELETE RESTRICT;

ALTER TABLE "order_items" 
  ADD CONSTRAINT fk_order_items_order FOREIGN KEY ("order_id") REFERENCES "orders" ("order_id") ON DELETE RESTRICT;

ALTER TABLE "order_items" 
  ADD CONSTRAINT fk_order_items_item FOREIGN KEY ("item_id") REFERENCES "items" ("item_id") ON DELETE RESTRICT;

ALTER TABLE "options" 
  ADD CONSTRAINT fk_options_option_type FOREIGN KEY ("option_type_id") REFERENCES "option_types" ("option_type_id") ON DELETE RESTRICT;

ALTER TABLE "order_item_options" 
  ADD CONSTRAINT fk_order_item_options_option FOREIGN KEY ("option_id") REFERENCES "options" ("option_id") ON DELETE RESTRICT;

ALTER TABLE "order_item_options" 
  ADD CONSTRAINT fk_order_item_options_order_item FOREIGN KEY ("order_id", "item_id") REFERENCES "order_items" ("order_id", "item_id") ON DELETE RESTRICT;
