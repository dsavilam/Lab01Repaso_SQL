from sqlalchemy import Column, Integer, String, ForeignKey, Numeric, DateTime, Text, Date
from sqlalchemy.orm import declarative_base, relationship

# Base declarativa para los modelos
Base = declarative_base()

class Language(Base):
    """
    Modelo para la tabla 'language' (idioma).
    Representa los idiomas disponibles para las películas.
    """
    __tablename__ = 'language'
    
    language_id = Column(Integer, primary_key=True)
    name = Column(String(20), nullable=False)
    
    # Relación con películas (un idioma tiene muchas películas)
    films = relationship("Film", back_populates="language")

class Film(Base):
    """
    Modelo para la tabla 'film' (película).
    Contiene la información principal de cada película.
    """
    __tablename__ = 'film'

    film_id = Column(Integer, primary_key=True)
    title = Column(String, nullable=False)
    description = Column(Text)
    release_year = Column(Integer)
    language_id = Column(Integer, ForeignKey('language.language_id'), nullable=False)
    rental_duration = Column(Integer, default=3)
    rental_rate = Column(Numeric(4, 2), default=4.99)
    length = Column(Integer)
    replacement_cost = Column(Numeric(5, 2), default=19.99)
    rating = Column(String) # Enum en DB, lo tratamos como String aquí por simplicidad
    
    # Relación con idioma
    language = relationship("Language", back_populates="films")
    # Relación con inventario
    inventory = relationship("Inventory", back_populates="film")

class Actor(Base):
    """
    Modelo para la tabla 'actor'.
    """
    __tablename__ = 'actor'
    
    actor_id = Column(Integer, primary_key=True)
    first_name = Column(String, nullable=False)
    last_name = Column(String, nullable=False)

class FilmActor(Base):
    """
    Modelo para la tabla de unión 'film_actor'.
    """
    __tablename__ = 'film_actor'
    
    actor_id = Column(Integer, ForeignKey('actor.actor_id'), primary_key=True)
    film_id = Column(Integer, ForeignKey('film.film_id'), primary_key=True)

class Inventory(Base):
    """
    Modelo para la tabla 'inventory' (inventario).
    """
    __tablename__ = 'inventory'
    
    inventory_id = Column(Integer, primary_key=True)
    film_id = Column(Integer, ForeignKey('film.film_id'), nullable=False)
    store_id = Column(Integer, ForeignKey('store.store_id'), nullable=False)
    
    film = relationship("Film", back_populates="inventory")
    rentals = relationship("Rental", back_populates="inventory_item")

class Customer(Base):
    """
    Modelo para la tabla 'customer' (cliente).
    """
    __tablename__ = 'customer'
    
    customer_id = Column(Integer, primary_key=True)
    store_id = Column(Integer, ForeignKey('store.store_id'))
    first_name = Column(String, nullable=False)
    last_name = Column(String, nullable=False)
    email = Column(String)
    active = Column(Integer)

class Rental(Base):
    """
    Modelo para la tabla 'rental' (alquiler).
    """
    __tablename__ = 'rental'
    
    rental_id = Column(Integer, primary_key=True)
    rental_date = Column(DateTime, nullable=False)
    inventory_id = Column(Integer, ForeignKey('inventory.inventory_id'), nullable=False)
    customer_id = Column(Integer, ForeignKey('customer.customer_id'), nullable=False)
    return_date = Column(DateTime)
    staff_id = Column(Integer, ForeignKey('staff.staff_id'))
    
    inventory_item = relationship("Inventory", back_populates="rentals")
    customer = relationship("Customer")

class Staff(Base):
    """
    Modelo para la tabla 'staff' (empleados).
    """
    __tablename__ = 'staff'
    
    staff_id = Column(Integer, primary_key=True)
    first_name = Column(String)
    last_name = Column(String)
    store_id = Column(Integer, ForeignKey('store.store_id'))

class Store(Base):
    """
    Modelo para la tabla 'store' (tienda).
    """
    __tablename__ = 'store'
    
    store_id = Column(Integer, primary_key=True)
    manager_staff_id = Column(Integer, ForeignKey('staff.staff_id'))

class Payment(Base):
    """
    Modelo para la tabla 'payment' (pagos).
    """
    __tablename__ = 'payment'
    
    payment_id = Column(Integer, primary_key=True)
    customer_id = Column(Integer, ForeignKey('customer.customer_id'))
    staff_id = Column(Integer, ForeignKey('staff.staff_id'))
    rental_id = Column(Integer, ForeignKey('rental.rental_id'))
    amount = Column(Numeric(5, 2))
    payment_date = Column(DateTime)

class Category(Base):
    """
    Modelo para la tabla 'category'.
    """
    __tablename__ = 'category'
    
    category_id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False)

class FilmCategory(Base):
    """
    Modelo para la tabla de unión 'film_category'.
    """
    __tablename__ = 'film_category'
    
    film_id = Column(Integer, ForeignKey('film.film_id'), primary_key=True)
    category_id = Column(Integer, ForeignKey('category.category_id'), primary_key=True)
