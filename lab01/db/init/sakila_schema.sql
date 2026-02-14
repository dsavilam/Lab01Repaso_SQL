-- Tipo ENUM para clasificaciones MPAA
CREATE TYPE mpaa_rating AS ENUM (
    'G',        -- General Audiences
    'PG',       -- Parental Guidance Suggested
    'PG-13',    -- Parents Strongly Cautioned
    'R',        -- Restricted
    'NC-17'     -- Adults Only
);

-- Dominio para años válidos
CREATE DOMAIN year AS integer
    CONSTRAINT year_check CHECK ((VALUE >= 1901) AND (VALUE <= 2155));

-- =====================================================
-- SECUENCIAS
-- =====================================================

CREATE SEQUENCE actor_actor_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE category_category_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE film_film_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE customer_customer_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE address_address_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE city_city_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE country_country_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE inventory_inventory_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE language_language_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE payment_payment_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE rental_rental_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE staff_staff_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE store_store_id_seq START WITH 1 INCREMENT BY 1;

-- =====================================================
-- TABLAS DE CATÁLOGO
-- =====================================================

-- Tabla de idiomas
CREATE TABLE language (
    language_id INTEGER DEFAULT nextval('language_language_id_seq') NOT NULL,
    name CHARACTER(20) NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    PRIMARY KEY (language_id)
);

-- Tabla de categorías de películas
CREATE TABLE category (
    category_id INTEGER DEFAULT nextval('category_category_id_seq') NOT NULL,
    name TEXT NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    PRIMARY KEY (category_id)
);

-- Tabla de países
CREATE TABLE country (
    country_id INTEGER DEFAULT nextval('country_country_id_seq') NOT NULL,
    country TEXT NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    PRIMARY KEY (country_id)
);

-- Tabla de ciudades
CREATE TABLE city (
    city_id INTEGER DEFAULT nextval('city_city_id_seq') NOT NULL,
    city TEXT NOT NULL,
    country_id INTEGER NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    PRIMARY KEY (city_id),
    FOREIGN KEY (country_id) REFERENCES country(country_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- =====================================================
-- TABLAS PRINCIPALES
-- =====================================================

-- Tabla de direcciones
CREATE TABLE address (
    address_id INTEGER DEFAULT nextval('address_address_id_seq') NOT NULL,
    address TEXT NOT NULL,
    address2 TEXT,
    district TEXT NOT NULL,
    city_id INTEGER NOT NULL,
    postal_code TEXT,
    phone TEXT NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    PRIMARY KEY (address_id),
    FOREIGN KEY (city_id) REFERENCES city(city_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Tabla de actores
CREATE TABLE actor (
    actor_id INTEGER DEFAULT nextval('actor_actor_id_seq') NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    PRIMARY KEY (actor_id)
);

-- Tabla de películas
CREATE TABLE film (
    film_id INTEGER DEFAULT nextval('film_film_id_seq') NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    release_year year,
    language_id INTEGER NOT NULL,
    original_language_id INTEGER,
    rental_duration SMALLINT DEFAULT 3 NOT NULL,
    rental_rate NUMERIC(4,2) DEFAULT 4.99 NOT NULL,
    length SMALLINT,
    replacement_cost NUMERIC(5,2) DEFAULT 19.99 NOT NULL,
    rating mpaa_rating DEFAULT 'G',
    special_features TEXT,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    PRIMARY KEY (film_id),
    FOREIGN KEY (language_id) REFERENCES language(language_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (original_language_id) REFERENCES language(language_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Tabla de tiendas
CREATE TABLE store (
    store_id INTEGER DEFAULT nextval('store_store_id_seq') NOT NULL,
    manager_staff_id INTEGER NOT NULL,
    address_id INTEGER NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    PRIMARY KEY (store_id),
    FOREIGN KEY (address_id) REFERENCES address(address_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Tabla de personal
CREATE TABLE staff (
    staff_id INTEGER DEFAULT nextval('staff_staff_id_seq') NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    address_id INTEGER NOT NULL,
    email TEXT,
    store_id INTEGER NOT NULL,
    active BOOLEAN DEFAULT true NOT NULL,
    username TEXT NOT NULL,
    password TEXT,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    picture BYTEA,
    PRIMARY KEY (staff_id),
    FOREIGN KEY (address_id) REFERENCES address(address_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (store_id) REFERENCES store(store_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Tabla de clientes
CREATE TABLE customer (
    customer_id INTEGER DEFAULT nextval('customer_customer_id_seq') NOT NULL,
    store_id INTEGER NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT,
    address_id INTEGER NOT NULL,
    active INTEGER DEFAULT 1 NOT NULL,
    create_date DATE DEFAULT CURRENT_DATE NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now(),
    PRIMARY KEY (customer_id),
    FOREIGN KEY (address_id) REFERENCES address(address_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (store_id) REFERENCES store(store_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Tabla de inventario
CREATE TABLE inventory (
    inventory_id INTEGER DEFAULT nextval('inventory_inventory_id_seq') NOT NULL,
    film_id INTEGER NOT NULL,
    store_id INTEGER NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    PRIMARY KEY (inventory_id),
    FOREIGN KEY (film_id) REFERENCES film(film_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (store_id) REFERENCES store(store_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Tabla de alquileres
CREATE TABLE rental (
    rental_id INTEGER DEFAULT nextval('rental_rental_id_seq') NOT NULL,
    rental_date TIMESTAMP WITH TIME ZONE NOT NULL,
    inventory_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    return_date TIMESTAMP WITH TIME ZONE,
    staff_id INTEGER NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    PRIMARY KEY (rental_id),
    FOREIGN KEY (inventory_id) REFERENCES inventory(inventory_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Tabla de pagos
CREATE TABLE payment (
    payment_id INTEGER DEFAULT nextval('payment_payment_id_seq') NOT NULL,
    customer_id INTEGER NOT NULL,
    staff_id INTEGER NOT NULL,
    rental_id INTEGER NOT NULL,
    amount NUMERIC(5,2) NOT NULL,
    payment_date TIMESTAMP WITH TIME ZONE NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    PRIMARY KEY (payment_id),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (rental_id) REFERENCES rental(rental_id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- =====================================================
-- TABLAS DE RELACIÓN (MUCHOS A MUCHOS)
-- =====================================================

-- Relación peliculas-actores
CREATE TABLE film_actor (
    actor_id INTEGER NOT NULL,
    film_id INTEGER NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    PRIMARY KEY (actor_id, film_id),
    FOREIGN KEY (actor_id) REFERENCES actor(actor_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (film_id) REFERENCES film(film_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Relación películas-categorías
CREATE TABLE film_category (
    film_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    PRIMARY KEY (film_id, category_id),
    FOREIGN KEY (film_id) REFERENCES film(film_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (category_id) REFERENCES category(category_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- =====================================================
-- ÍNDICES
-- =====================================================

CREATE INDEX idx_fk_address_id ON customer(address_id);
CREATE INDEX idx_fk_city_id ON address(city_id);
CREATE INDEX idx_fk_country_id ON city(country_id);
CREATE INDEX idx_fk_customer_id ON payment(customer_id);
CREATE INDEX idx_fk_film_id ON inventory(film_id);
CREATE INDEX idx_fk_inventory_id ON rental(inventory_id);
CREATE INDEX idx_fk_language_id ON film(language_id);
CREATE INDEX idx_fk_original_language_id ON film(original_language_id);
CREATE INDEX idx_fk_staff_id ON payment(staff_id);
CREATE INDEX idx_fk_store_id ON customer(store_id);
CREATE INDEX idx_fk_store_id_inventory ON inventory(store_id);
CREATE INDEX idx_last_name ON customer(last_name);
CREATE INDEX idx_rental_date ON rental(rental_date);
CREATE INDEX idx_title ON film(title);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Función para actualizar last_update
CREATE OR REPLACE FUNCTION last_updated() 
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_update = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para actualización automática
CREATE TRIGGER last_updated_actor BEFORE UPDATE ON actor FOR EACH ROW EXECUTE FUNCTION last_updated();
CREATE TRIGGER last_updated_address BEFORE UPDATE ON address FOR EACH ROW EXECUTE FUNCTION last_updated();
CREATE TRIGGER last_updated_category BEFORE UPDATE ON category FOR EACH ROW EXECUTE FUNCTION last_updated();
CREATE TRIGGER last_updated_city BEFORE UPDATE ON city FOR EACH ROW EXECUTE FUNCTION last_updated();
CREATE TRIGGER last_updated_country BEFORE UPDATE ON country FOR EACH ROW EXECUTE FUNCTION last_updated();
CREATE TRIGGER last_updated_customer BEFORE UPDATE ON customer FOR EACH ROW EXECUTE FUNCTION last_updated();
CREATE TRIGGER last_updated_film BEFORE UPDATE ON film FOR EACH ROW EXECUTE FUNCTION last_updated();
CREATE TRIGGER last_updated_film_actor BEFORE UPDATE ON film_actor FOR EACH ROW EXECUTE FUNCTION last_updated();
CREATE TRIGGER last_updated_film_category BEFORE UPDATE ON film_category FOR EACH ROW EXECUTE FUNCTION last_updated();
CREATE TRIGGER last_updated_inventory BEFORE UPDATE ON inventory FOR EACH ROW EXECUTE FUNCTION last_updated();
CREATE TRIGGER last_updated_language BEFORE UPDATE ON language FOR EACH ROW EXECUTE FUNCTION last_updated();
CREATE TRIGGER last_updated_rental BEFORE UPDATE ON rental FOR EACH ROW EXECUTE FUNCTION last_updated();
CREATE TRIGGER last_updated_staff BEFORE UPDATE ON staff FOR EACH ROW EXECUTE FUNCTION last_updated();
CREATE TRIGGER last_updated_store BEFORE UPDATE ON store FOR EACH ROW EXECUTE FUNCTION last_updated();

-- =====================================================
-- FIN DEL ESQUEMA SAKILA
-- =====================================================
