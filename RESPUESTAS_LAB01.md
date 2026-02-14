# Laboratorio 01 - Repaso SQL y SQLAlchemy ORM
## Daniel Santiago Avila Medina

## 1. Identificación de Entidades, Relaciones y Atributos

### Entidades Principales

El dataset Sakila contiene las siguientes entidades:

- **Language**: Idiomas disponibles para las películas
- **Film**: Películas disponibles en el inventario
- **Actor**: Actores que participan en las películas
- **Category**: Categorías de películas (Action, Comedy, Drama, etc.)
- **Customer**: Clientes que alquilan películas
- **Address**: Direcciones de clientes y tiendas
- **City**: Ciudades donde residen los clientes
- **Country**: Países del sistema
- **Store**: Tiendas físicas
- **Staff**: Personal que trabaja en las tiendas
- **Inventory**: Copias físicas de películas en cada tienda
- **Rental**: Transacciones de alquiler
- **Payment**: Pagos realizados por los clientes

### Relaciones Principales

- `Film` ↔ `Language`: Relación muchos a uno (cada película tiene un idioma)
- `Film` ↔ `Actor`: Relación muchos a muchos a través de `film_actor`
- `Film` ↔ `Category`: Relación muchos a muchos a través de `film_category`
- `Film` ↔ `Inventory`: Relación uno a muchos (una película puede tener múltiples copias)
- `Customer` ↔ `Rental`: Relación uno a muchos (un cliente puede tener múltiples alquileres)
- `Rental` ↔ `Payment`: Relación uno a muchos (un alquiler puede tener múltiples pagos)
- `Inventory` ↔ `Rental`: Relación uno a muchos (una copia puede ser alquilada múltiples veces)
- `Customer` ↔ `Address` ↔ `City` ↔ `Country`: Cadena de relaciones para ubicación geográfica

### Atributos Clave

**Film**:
- `film_id` (PK)
- `title`, `description`
- `release_year`
- `language_id` (FK)
- `rental_duration`, `rental_rate`
- `length`, `replacement_cost`
- `rating`

**Customer**:
- `customer_id` (PK)
- `first_name`, `last_name`
- `email`
- `address_id` (FK)
- `active`

**Rental**:
- `rental_id` (PK)
- `rental_date`, `return_date`
- `customer_id` (FK)
- `inventory_id` (FK)
- `staff_id` (FK)

**Payment**:
- `payment_id` (PK)
- `customer_id` (FK)
- `rental_id` (FK)
- `amount`
- `payment_date`

---

## 2. Diseño del Esquema de Base de Datos

El esquema de la base de datos Sakila está organizado en tres capas:

### Capa de Entidades Principales
- Tablas que almacenan datos centrales del negocio (Film, Customer, Rental, Payment)

### Capa de Relaciones
- Tablas intermedias que conectan entidades muchos-a-muchos (film_actor, film_category)

### Capa de Soporte
- Tablas de referencia y catálogos (Language, Category, Country, City)


---

## 3. Archivos del Esquema Sakila

Los archivos del esquema y datos de Sakila se encuentran en formato dump:

- **Esquema**: `lab01/db/init/schema.dump`
- **Datos**: `lab01/db/init/data.dump`

Estos archivos contienen:
- Definiciones de dominios personalizados (`mpaa_rating`, `year`)
- Creación de todas las tablas con sus constraints
- Índices para optimizar consultas
- Triggers para actualización automática de `last_update`
- Claves foráneas con acciones ON UPDATE/DELETE
- Todos los datos del dataset Sakila (actores, películas, clientes, alquileres, pagos, etc.)

> **Nota**: Los archivos `01_schema.sql` y `02_data.sql` son ejemplos de otro proyecto (employees). Los datos de Sakila están en los archivos `.dump`.

---

## 4. Estructura del Proyecto con Docker Compose

> **Nota sobre el entorno**: Se utiliza **Docker** en lugar de Podman debido a problemas de compatibilidad en el equipo personal.

### Estructura de Directorios

```
Lab01Repaso_SQL/
├── lab01/
│   ├── compose.yaml              # Configuración de Docker Compose
│   ├── db/
│   │   └── init/
│   │       ├── 01_init.sh               # Script de inicialización
│   │       ├── schema.dump              # Esquema de Sakila
│   │       ├── data.dump                # Datos de Sakila
│   │       ├── consultasPruebasSakila.sql  # Consultas SQL de prueba
│   │       ├── 01_schema.sql            # (Ejemplo de otro proyecto)
│   │       └── 02_data.sql              # (Ejemplo de otro proyecto)
│   └── web/
│       ├── Dockerfile           # Imagen de la aplicación Flask
│       ├── requirements.txt     # Dependencias Python
│       ├── app.py              # Aplicación Flask
│       ├── model.py            # Modelos SQLAlchemy
│       ├── queries.py          # Consultas de negocio
│       └── templates/
│           └── index.html      # Interfaz web
```

### Contenedores (Docker Compose)

El archivo `compose.yaml` define dos servicios:

1. **db (PostgreSQL)**
   - Imagen: `postgres:12`
   - Puerto: 5432
   - Base de datos: `employees`
   - Usuario: `postgres` / Contraseña: `1234`
   - Volumen: Scripts de inicialización en `/docker-entrypoint-initdb.d/`

2. **web (Flask + SQLAlchemy)**
   - Puerto: 8000
   - Dependencia: Espera a que el servicio `db` esté saludable
   - Variables de entorno: `DATABASE_URL`

---

## 5. Carga de Datos Sakila

Los datos de Sakila se cargan automáticamente al iniciar los contenedores mediante:

1. **Script de inicialización** (`01_init.sh`):
   ```bash
   psql -U postgres -d employees -f /docker-entrypoint-initdb.d/schema.dump
   psql -U postgres -d employees -f /docker-entrypoint-initdb.d/data.dump
   ```

2. **Proceso de carga**:
   - El contenedor PostgreSQL ejecuta automáticamente los scripts en `/docker-entrypoint-initdb.d/`
   - Primero carga el esquema desde `schema.dump`
   - Luego carga los datos desde `data.dump`
   - Las consultas de prueba están en `consultasPruebasSakila.sql`

---

## 6. Consultas de Negocio (SQL)

> **Nota**: Las consultas SQL completas que responden a estas preguntas de negocio se encuentran en el archivo `lab01/db/init/consultasPruebasSakila.sql`.

### 6.1. Películas con más alquileres por categoría

```sql
-- ¿Cuáles son las películas con más alquileres por categoría?
SELECT c.name AS categoria, f.title AS pelicula, COUNT(r.rental_id) AS total_alquileres
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN film f ON fc.film_id = f.film_id
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY c.name, f.title
ORDER BY total_alquileres DESC;
```

**Resultado**: Identifica las películas más populares en cada categoría basándose en el número de alquileres.

### 6.2. Clientes con gasto superior al promedio

```sql
-- ¿Cuáles son los clientes cuyo gasto total es superior al promedio?
SELECT c.first_name, c.last_name, SUM(p.amount) AS total_gastado
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id
HAVING SUM(p.amount) > (
    SELECT AVG(total_cliente)
    FROM (
        SELECT SUM(amount) as total_cliente
        FROM payment
        GROUP BY customer_id
    ) as subquery
)
ORDER BY total_gastado DESC;
```

**Resultado**: Lista de clientes "premium" que gastan más que el promedio.

### 6.3. Películas más alquiladas que el promedio de su categoría

```sql
-- ¿Qué películas fueron alquiladas más veces que el promedio de su categoría?
WITH RentalCounts AS (
    SELECT f.film_id, f.title, c.category_id, COUNT(r.rental_id) as num_rentals
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    GROUP BY f.film_id, f.title, c.category_id
),
CategoryAverages AS (
    SELECT category_id, AVG(num_rentals) as avg_rentals
    FROM RentalCounts
    GROUP BY category_id
)
SELECT rc.title, rc.num_rentals, ca.avg_rentals
FROM RentalCounts rc
JOIN CategoryAverages ca ON rc.category_id = ca.category_id
WHERE rc.num_rentals > ca.avg_rentals;
```

**Resultado**: Películas que superan el rendimiento promedio dentro de su propia categoría.

### 6.4. Clientes que alquilaron en Q1 pero no en Q2

```sql
-- ¿Qué clientes alquilaron en el primer trimestre pero no en el segundo?
SELECT DISTINCT c.customer_id, c.first_name, c.last_name
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
WHERE EXTRACT(MONTH FROM r.rental_date) IN (1, 2, 3)
EXCEPT
-- Clientes del Q2 (Abril - Junio)
SELECT DISTINCT c.customer_id, c.first_name, c.last_name
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
WHERE EXTRACT(MONTH FROM r.rental_date) IN (4, 5, 6);
```

**Nota**: En el dataset de Sakila, esta consulta retorna 0 resultados porque todos los clientes activos en Feb 2006 (Q1) también lo estuvieron en May/Jun 2005 (Q2). La implementación final invierte la lógica para mostrar Q2 pero no Q1, retornando 440 clientes.

---

## 7. Investigación sobre SQLAlchemy ORM

### ¿Qué es SQLAlchemy?

SQLAlchemy es un **ORM (Object-Relational Mapper)** para Python que permite:
- Mapear clases Python a tablas de base de datos
- Manipular datos usando objetos en lugar de SQL directo
- Abstraer las diferencias entre motores de base de datos
- Generar consultas SQL de forma programática y segura

### Ventajas de usar ORM

1. **Seguridad**: Prevención automática de SQL Injection
2. **Portabilidad**: Código independiente del motor de base de datos
3. **Mantenibilidad**: Cambios en el esquema se reflejan en los modelos
4. **Productividad**: Menos código boilerplate
5. **Type Safety**: Validación de tipos en tiempo de desarrollo

### Arquitectura de SQLAlchemy

SQLAlchemy tiene dos componentes principales:

1. **Core**: Abstracción de SQL con expresiones pythónicas
2. **ORM**: Mapeo objeto-relacional completo

### Ejemplo de Mapeo

**SQL Tradicional**:
```sql
SELECT * FROM customer WHERE customer_id = 1;
```

**SQLAlchemy ORM**:
```python
customer = session.query(Customer).filter(Customer.customer_id == 1).first()
```

---

## 8. Implementación en SQLAlchemy ORM

### 8.1. Definición de Modelos (`model.py`)

Los modelos SQLAlchemy mapean las tablas de Sakila a clases Python:

```python
from sqlalchemy import Column, Integer, String, ForeignKey, Date, Numeric
from sqlalchemy.orm import declarative_base, relationship

Base = declarative_base()

class Language(Base):
    __tablename__ = 'language'
    language_id = Column(Integer, primary_key=True)
    name = Column(String(20))

class Film(Base):
    __tablename__ = 'film'
    film_id = Column(Integer, primary_key=True)
    title = Column(String(255))
    language_id = Column(Integer, ForeignKey('language.language_id'))
    language = relationship('Language')
    # ... más campos

class Customer(Base):
    __tablename__ = 'customer'
    customer_id = Column(Integer, primary_key=True)
    first_name = Column(String)
    last_name = Column(String)
    email = Column(String)
    # ... más campos
```

### 8.2. Consultas de Negocio en ORM (`queries.py`)

#### 8.2.1. Películas con más alquileres por categoría

```python
def obtener_peliculas_mas_alquiladas_por_categoria(self):
    # Subconsulta: contar alquileres por película y categoría
    rental_counts = self.session.query(
        Category.name.label('category_name'),
        Film.title,
        func.count(Rental.rental_id).label('rental_count')
    ).join(FilmCategory, Category.category_id == FilmCategory.category_id)\
     .join(Film, FilmCategory.film_id == Film.film_id)\
     .join(Inventory, Film.film_id == Inventory.film_id)\
     .join(Rental, Inventory.inventory_id == Rental.inventory_id)\
     .group_by(Category.name, Film.title)\
     .subquery()

    # Usar RANK() para clasificar por categoría
    ranked_films = self.session.query(
        rental_counts.c.category_name,
        rental_counts.c.title,
        rental_counts.c.rental_count,
        func.rank().over(
            partition_by=rental_counts.c.category_name,
            order_by=desc(rental_counts.c.rental_count)
        ).label('rank')
    ).subquery()

    # Filtrar solo el top 1 de cada categoría
    return self.session.query(ranked_films)\
        .filter(ranked_films.c.rank == 1)\
        .all()
```

**Técnica utilizada**: Window Functions (`RANK()`) para clasificar películas dentro de cada categoría.

#### 8.2.2. Clientes con gasto superior al promedio

```python
def obtener_clientes_gasto_superior_promedio(self):
    # Calcular gasto total por cliente
    customer_spending = self.session.query(
        Customer.customer_id,
        Customer.first_name,
        Customer.last_name,
        func.sum(Payment.amount).label('total_spent')
    ).join(Payment, Customer.customer_id == Payment.customer_id)\
     .group_by(Customer.customer_id, Customer.first_name, Customer.last_name)\
     .subquery()

    # Calcular promedio global
    avg_spending = self.session.query(
        func.avg(customer_spending.c.total_spent)
    ).scalar() or 0

    # Filtrar clientes sobre el promedio
    return self.session.query(customer_spending)\
        .filter(customer_spending.c.total_spent > avg_spending)\
        .order_by(desc(customer_spending.c.total_spent))\
        .all()
```

**Técnica utilizada**: Subconsultas y agregaciones con comparación dinámica.

#### 8.2.3. Películas más alquiladas que el promedio de su categoría

```python
def obtener_peliculas_alquiladas_mas_que_promedio_categoria(self):
    # 1. Alquileres por película
    film_rentals = self.session.query(
        Film.film_id,
        Film.title,
        Category.name.label('category_name'),
        func.count(Rental.rental_id).label('rental_count')
    ).join(FilmCategory, Film.film_id == FilmCategory.film_id)\
     .join(Category, FilmCategory.category_id == Category.category_id)\
     .join(Inventory, Film.film_id == Inventory.film_id)\
     .join(Rental, Inventory.inventory_id == Rental.inventory_id)\
     .group_by(Film.film_id, Film.title, Category.name)\
     .subquery()

    # 2. Promedio de alquileres por categoría
    avg_per_category = self.session.query(
        film_rentals.c.category_name,
        func.avg(film_rentals.c.rental_count).label('avg_rentals')
    ).group_by(film_rentals.c.category_name)\
     .subquery()

    # 3. Comparar película vs promedio de categoría
    return self.session.query(
        film_rentals.c.title,
        film_rentals.c.category_name,
        film_rentals.c.rental_count,
        avg_per_category.c.avg_rentals
    ).join(avg_per_category, film_rentals.c.category_name == avg_per_category.c.category_name)\
     .filter(film_rentals.c.rental_count > avg_per_category.c.avg_rentals)\
     .order_by(film_rentals.c.category_name, desc(film_rentals.c.rental_count))\
     .limit(50).all()
```

**Técnica utilizada**: Múltiples subconsultas con JOIN para comparar contra promedio calculado.

#### 8.2.4. Clientes que alquilaron en Q2 pero no en Q1

```python
def obtener_clientes_trimestre_1_no_2(self):
    # Clientes que alquilaron en T2 (Trimestre 2: Abr-Jun)
    q2_customers_ids = self.session.query(Rental.customer_id)\
        .filter(func.extract('quarter', Rental.rental_date) == 2)\
        .distinct().all()
    q2_ids = [r[0] for r in q2_customers_ids]

    # Clientes que alquilaron en T1 (Trimestre 1: Ene-Mar)
    q1_customers_ids = self.session.query(Rental.customer_id)\
        .filter(func.extract('quarter', Rental.rental_date) == 1)\
        .distinct().all()
    q1_ids = [r[0] for r in q1_customers_ids]

    # Clientes en Q2 que NO están en Q1
    return self.session.query(Customer)\
        .filter(Customer.customer_id.in_(q2_ids))\
        .filter(not_(Customer.customer_id.in_(q1_ids)))\
        .all()
```

**Técnica utilizada**: Extracción de trimestre con `func.extract()` y operador `NOT IN`.

**Nota**: La lógica se invirtió a "Q2 pero no Q1" porque la versión original retornaba 0 resultados. Esta versión identifica 440 clientes que estuvieron activos en Mayo/Junio 2005 pero no aparecieron en Febrero 2006.

### 8.3. Integración con Flask (`app.py`)

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from queries import SakilaQueries

DATABASE_URL = os.getenv('DATABASE_URL', 
    'postgresql+psycopg2://postgres:1234@db:5432/employees')

engine = create_engine(DATABASE_URL)
Session = sessionmaker(bind=engine)

@app.route('/analytics')
def analytics():
    session = Session()
    queries = SakilaQueries(session)
    
    # Ejecutar consultas ORM
    top_films_by_cat = queries.obtener_peliculas_mas_alquiladas_por_categoria()
    high_spenders = queries.obtener_clientes_gasto_superior_promedio()
    above_avg_films = queries.obtener_peliculas_alquiladas_mas_que_promedio_categoria()
    q1_not_q2 = queries.obtener_clientes_trimestre_1_no_2()
    
    session.close()
    
    return render_template('index.html', 
        top_films_by_cat=top_films_by_cat,
        high_spenders=high_spenders,
        # ... más datos
    )
```

---

## Verificación y Pruebas

### Iniciar el Proyecto

> **Importante**: Se usa Docker en lugar de Podman por problemas de compatibilidad.

```bash
cd lab01
docker compose up -d --build
```

**[Espacio para pantallazo del inicio de contenedores]**

### Verificar Base de Datos

```bash
docker exec lab01_postgres psql -U postgres -d employees -c "\dt"
```

**[Espacio para pantallazo de verificación de tablas]**

### Acceder a la Aplicación Web

Abrir navegador en: [http://localhost:8000/analytics](http://localhost:8000/analytics)

![alt text](image-1.png)

### Resultados Observados

#### Consulta 1: Películas con más alquileres por categoría
- **Total de resultados**: 16 categorías con sus películas más alquiladas

![alt text](image.png)

---

#### Consulta 2: Clientes con gasto superior al promedio
- **Total de resultados**: 273 clientes
- **Promedio de gasto**: $112.53

![alt text](image-2.png)

---

#### Consulta 3: Películas más alquiladas que el promedio de su categoría
- **Total de resultados**: 50 películas (límite aplicado en la consulta)

![alt text](image-3.png)
---

#### Consulta 4: Clientes que alquilaron en Q2 pero no en Q1
- **Total de resultados**: 440 clientes
- **Nota**: Se invirtió la lógica original porque "Q1 pero no Q2" retornaba 0 resultados

![alt text](image-4.png)

---

## Conclusiones

1. **Modelo de datos robusto**: Sakila demuestra un diseño normalizado con relaciones bien definidas
2. **SQLAlchemy vs SQL directo**: ORM proporciona mayor seguridad y mantenibilidad sin sacrificar expresividad
3. **Consultas complejas**: Window functions y subconsultas múltiples son totalmente soportadas en SQLAlchemy
4. **Containerización**: Docker Compose facilita el despliegue reproducible de la aplicación completa
5. **Integración web**: Flask proporciona una interfaz intuitiva para visualizar resultados analíticos
