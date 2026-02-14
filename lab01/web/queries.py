from sqlalchemy import func, desc, and_, not_, or_
from sqlalchemy.sql import over
from sqlalchemy.orm import Session
from model import Film, Language, Actor, FilmActor, Rental, Inventory, Customer, Payment, Staff, Store, Category, FilmCategory

class SakilaQueries:
    def __init__(self, session: Session):
        """
        Inicializa la clase con una sesión de base de datos.
        :param session: Sesión de SQLAlchemy
        """
        self.session = session

    def obtener_idiomas(self):
        """
        Obtiene todos los idiomas ordenados por nombre.
        """
        return self.session.query(Language).order_by(Language.name).all()

    def buscar_peliculas(self, idioma=None, titulo=None):
        """
        Busca películas filtrando por idioma y/o parte del título.
        Limita los resultados a 50.
        :param idioma: Nombre del idioma (opcional)
        :param titulo: Parte del título de la película (opcional)
        """
        query = self.session.query(Film)
        
        if idioma:
            query = query.join(Film.language).filter(Language.name == idioma)
        
        if titulo:
            # Búsqueda insensible a mayúsculas/minúsculas
            query = query.filter(Film.title.ilike(f'%{titulo}%'))
            
        return query.order_by(Film.film_id).limit(50).all()

    def obtener_top_actores(self, limite=10):
        """
        Obtiene los actores con mayor número de películas.
        :param limite: Cantidad máxima de resultados (por defecto 10)
        """
        # Consulta equivalente a:
        # SELECT a.first_name, a.last_name, count(fa.film_id)
        # FROM actor a JOIN film_actor fa ON ...
        # GROUP BY a.actor_id ORDER BY count DESC
        return self.session.query(
            Actor.first_name, 
            Actor.last_name, 
            func.count(FilmActor.film_id).label('film_count')
        ).join(FilmActor, Actor.actor_id == FilmActor.actor_id)\
         .group_by(Actor.actor_id)\
         .order_by(desc('film_count'))\
         .limit(limite).all()

    def obtener_clientes_por_pelicula(self, titulo_pelicula):
        """
        Encuentra los clientes que han alquilado una película específica.
        :param titulo_pelicula: Título exacto de la película
        """
        return self.session.query(Customer.first_name, Customer.last_name)\
            .join(Rental, Customer.customer_id == Rental.customer_id)\
            .join(Inventory, Rental.inventory_id == Inventory.inventory_id)\
            .join(Film, Inventory.film_id == Film.film_id)\
            .filter(Film.title == titulo_pelicula)\
            .distinct().all()

    def obtener_ventas_por_tienda(self):
        """
        Calcula el total de ventas por tienda.
        """
        return self.session.query(
            Store.store_id, 
            func.sum(Payment.amount).label('total_sales')
        ).join(Staff, Payment.staff_id == Staff.staff_id)\
         .join(Store, Staff.store_id == Store.store_id)\
         .group_by(Store.store_id)\
         .all()
    def obtener_clientes_mas_30_alquileres(self):
        """
        1. Clientes que han realizado más de 30 alquileres.
        """
        return self.session.query(
            Customer.first_name,
            Customer.last_name,
            func.count(Rental.rental_id).label('total_rentals')
        ).join(Rental, Customer.customer_id == Rental.customer_id)\
         .group_by(Customer.customer_id)\
         .having(func.count(Rental.rental_id) > 30)\
         .order_by(desc('total_rentals'))\
         .all()

    def obtener_categoria_mas_alquilada(self):
        """
        2. Categoría de película más alquilada.
        """
        return self.session.query(
            Category.name,
            func.count(Rental.rental_id).label('rental_count')
        ).join(FilmCategory, Category.category_id == FilmCategory.category_id)\
         .join(Inventory, FilmCategory.film_id == Inventory.film_id)\
         .join(Rental, Inventory.inventory_id == Rental.inventory_id)\
         .group_by(Category.name)\
         .order_by(desc('rental_count'))\
         .first()

    def obtener_ingresos_por_categoria(self):
        """
        3. Ingresos totales por categoría.
        """
        return self.session.query(
            Category.name,
            func.sum(Payment.amount).label('total_revenue')
        ).join(FilmCategory, Category.category_id == FilmCategory.category_id)\
         .join(Inventory, FilmCategory.film_id == Inventory.film_id)\
         .join(Rental, Inventory.inventory_id == Rental.inventory_id)\
         .join(Payment, Rental.rental_id == Payment.rental_id)\
         .group_by(Category.name)\
         .order_by(desc('total_revenue'))\
         .all()

    def obtener_clientes_activos(self):
        """
        4. Listado de clientes activos (active = 1).
        """
        return self.session.query(Customer)\
            .filter(Customer.active == 1)\
            .order_by(Customer.last_name, Customer.first_name)\
            .all()
    def obtener_peliculas_mas_alquiladas_por_categoria(self):
        """
        1. ¿Cuáles son las películas con más alquileres por categoría?
        Usa una función de ventana para clasificar películas dentro de cada categoría.
        """
        # Subconsulta para contar alquileres por película y categoría
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

        # Usar Rank() o RowNumber() sobre la partición
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
        return self.session.query(ranked_films).filter(ranked_films.c.rank == 1).all()

    def obtener_clientes_gasto_superior_promedio(self):
        """
        2. ¿Cuáles son los clientes que su gasto total es superior al promedio?
        """
        # Calcular el gasto total por cliente
        customer_spending = self.session.query(
            Customer.customer_id,
            Customer.first_name,
            Customer.last_name,
            func.sum(Payment.amount).label('total_spent')
        ).join(Payment, Customer.customer_id == Payment.customer_id)\
         .group_by(Customer.customer_id, Customer.first_name, Customer.last_name)\
         .subquery()

        # Calcular el promedio global de gasto por cliente
        avg_spending = self.session.query(
            func.avg(customer_spending.c.total_spent)
        ).scalar() or 0

        return self.session.query(customer_spending)\
            .filter(customer_spending.c.total_spent > avg_spending)\
            .order_by(desc(customer_spending.c.total_spent))\
            .all()

    def obtener_peliculas_alquiladas_mas_que_promedio_categoria(self):
        """
        3. ¿Cuáles son las películas más alquiladas que el promedio de su categoría?
        """
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

        # 3. Comparar
        return self.session.query(
            film_rentals.c.title,
            film_rentals.c.category_name,
            film_rentals.c.rental_count,
            avg_per_category.c.avg_rentals
        ).join(avg_per_category, film_rentals.c.category_name == avg_per_category.c.category_name)\
         .filter(film_rentals.c.rental_count > avg_per_category.c.avg_rentals)\
         .order_by(film_rentals.c.category_name, desc(film_rentals.c.rental_count))\
         .limit(50).all()

    def obtener_clientes_trimestre_1_no_2(self):
        """
        4. ¿Cuáles son los clientes que alquilaron en el primer trimestre pero no en el segundo?
        Nota: Por la distribución de datos en Sakila, se invierte para mostrar Q2 pero no Q1.
        """
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

        # Clientes en Q2 (May/Jun 2005) que NO están en Q1 (Feb 2006)
        # Esto muestra clientes que solo alquilaron en el periodo intermedio
        return self.session.query(Customer)\
            .filter(Customer.customer_id.in_(q2_ids))\
            .filter(not_(Customer.customer_id.in_(q1_ids)))\
            .all()
