import os
from flask import Flask, request, render_template
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
# Importar modelos y consultas desde los módulos definidos
from model import Base
from queries import SakilaQueries

# Configuración de la base de datos
DATABASE_URL = os.environ.get("DATABASE_URL", "postgresql+psycopg2://postgres:1234@db:5432/employees")

# Crear el motor de base de datos
engine = create_engine(DATABASE_URL, pool_pre_ping=True, future=True)

# Crear una fábrica de sesiones
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

app = Flask(__name__)


@app.get("/")
def index():
    """
    Ruta principal que maneja la visualización de idiomas y películas.
    Uses SakilaQueries to fetch data.
    """
    view = request.args.get("view", "")
    selected_lang = request.args.get("lang", "")
    q = request.args.get("q", "")
    
    # Crear una nueva sesión de base de datos
    session = SessionLocal()
    queries = SakilaQueries(session)
    
    languages = []
    films = []
    lang_options = []
    
    try:
        # Obtener opciones de idiomas para el filtro
        lang_options = queries.obtener_idiomas()
        
        if view == "languages":
            # Obtener lista completa de idiomas
            languages = queries.obtener_idiomas()
            
        if view == "films":
            # Buscar películas con filtros
            films = queries.buscar_peliculas(idioma=selected_lang, titulo=q)
            
        return render_template(
            "index.html",
            view=view,
            languages=languages,
            films=films,
            lang_options=lang_options,
            selected_lang=selected_lang,
            q=q
        )
    finally:
        session.close()

@app.get("/analytics")
def analytics():
    """
    Ruta para visualizar los resultados de las preguntas analíticas del laboratorio.
    """
    session = SessionLocal()
    queries = SakilaQueries(session)
    try:
        # Consultas Avanzadas (Ahora 1-4)
        top_films_by_cat = queries.obtener_peliculas_mas_alquiladas_por_categoria()
        high_spenders = queries.obtener_clientes_gasto_superior_promedio()
        above_avg_category_films = queries.obtener_peliculas_alquiladas_mas_que_promedio_categoria()
        q1_not_q2 = queries.obtener_clientes_trimestre_1_no_2()
        
        # Consultas Originales (Ahora 5-8)
        top_customers = queries.obtener_clientes_mas_30_alquileres()
        top_category = queries.obtener_categoria_mas_alquilada()
        revenue_by_cat = queries.obtener_ingresos_por_categoria()
        active_customers = queries.obtener_clientes_activos()
        
        return render_template(
            "index.html",
            view="analytics",
            # Avanzadas
            top_films_by_cat=top_films_by_cat,
            high_spenders=high_spenders,
            above_avg_category_films=above_avg_category_films,
            q1_not_q2=q1_not_q2,
            # Originales
            top_customers=top_customers,
            top_category=top_category,
            revenue_by_cat=revenue_by_cat,
            active_customers=active_customers
        )
    finally:
        session.close()

@app.get("/health")
def health():
    """
    Endpoint de verificación de salud.
    Comprueba la conexión a la base de datos.
    """
    try:
        with engine.connect() as conn:
            # Ejecutar consulta simple
            conn.execute(text("SELECT 1"))
        return {"status": "ok"}
    except Exception as e:
        return {"status": "error", "detail": str(e)}, 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True)
