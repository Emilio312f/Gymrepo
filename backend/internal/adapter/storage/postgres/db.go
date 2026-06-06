// Package postgres implementa los puertos de almacenamiento sobre PostgreSQL.
package postgres

import (
	"context"
	"errors"
	"fmt"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/pgx/v5" // driver pgx5://
	"github.com/golang-migrate/migrate/v4/source/iofs"
	"github.com/jackc/pgx/v5/pgxpool"

	"gymcontrol/migrations"
)

// NuevoPool abre el pool de conexiones y verifica que la BD responde.
func NuevoPool(ctx context.Context, dsn string) (*pgxpool.Pool, error) {
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		return nil, fmt.Errorf("creando pool: %w", err)
	}
	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("ping a la BD: %w", err)
	}
	return pool, nil
}

// Migrar aplica las migraciones embebidas al arrancar. Si la BD ya está al día,
// no hace nada (no es error).
//
// Nota de diseño: auto-migrar al arrancar es cómodo para desarrollo y para una
// sola instancia. En producción con múltiples instancias se ejecutaría como un
// paso separado del despliegue para evitar condiciones de carrera.
func Migrar(migrateURL string) error {
	src, err := iofs.New(migrations.Files, ".")
	if err != nil {
		return fmt.Errorf("cargando migraciones embebidas: %w", err)
	}
	m, err := migrate.NewWithSourceInstance("iofs", src, migrateURL)
	if err != nil {
		return fmt.Errorf("inicializando migrate: %w", err)
	}
	defer m.Close()

	if err := m.Up(); err != nil && !errors.Is(err, migrate.ErrNoChange) {
		return fmt.Errorf("aplicando migraciones: %w", err)
	}
	return nil
}
