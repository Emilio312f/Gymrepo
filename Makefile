# Atajos para el desarrollo de GymControl.
# Uso: make <objetivo>

.PHONY: up down migrate logs psql reset

# Levanta la base de datos y aplica las migraciones.
up:
	docker compose up -d db
	docker compose run --rm migrate

# Detiene los contenedores (conserva los datos).
down:
	docker compose down

# Vuelve a aplicar las migraciones (útil tras añadir una nueva).
migrate:
	docker compose run --rm migrate

# Ver los logs de la base de datos.
logs:
	docker compose logs -f db

# Abrir una consola SQL dentro de la base de datos.
psql:
	docker compose exec db psql -U gym -d gymcontrol

# CUIDADO: borra todos los datos y vuelve a migrar desde cero.
reset:
	docker compose down -v
	docker compose up -d db
	docker compose run --rm migrate
