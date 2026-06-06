package postgres

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"

	"gymcontrol/internal/app/planes"
	"gymcontrol/internal/domain"
)

type PlanesRepo struct {
	pool *pgxpool.Pool
}

func NewPlanesRepo(pool *pgxpool.Pool) *PlanesRepo {
	return &PlanesRepo{pool: pool}
}

var _ planes.Repositorio = (*PlanesRepo)(nil)

func (r *PlanesRepo) Crear(ctx context.Context, p domain.Plan) (domain.Plan, error) {
	err := r.pool.QueryRow(ctx,
		`INSERT INTO plan (gimnasio_id, nombre, descripcion, precio, duracion_dias)
		 VALUES ($1, $2, NULLIF($3, ''), $4, $5)
		 RETURNING id, activo, created_at`,
		p.GimnasioID, p.Nombre, p.Descripcion, p.Precio, p.DuracionDias,
	).Scan(&p.ID, &p.Activo, &p.CreatedAt)
	if err != nil {
		return domain.Plan{}, err
	}
	return p, nil
}

func (r *PlanesRepo) Listar(ctx context.Context, gimnasioID string, soloActivos bool) ([]domain.Plan, error) {
	consulta := `SELECT id, gimnasio_id, nombre, COALESCE(descripcion, ''),
	                    precio::float8, duracion_dias, activo, created_at
	             FROM plan WHERE gimnasio_id = $1`
	if soloActivos {
		consulta += ` AND activo = true`
	}
	consulta += ` ORDER BY precio ASC`

	rows, err := r.pool.Query(ctx, consulta, gimnasioID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	lista := make([]domain.Plan, 0)
	for rows.Next() {
		var p domain.Plan
		if err := rows.Scan(&p.ID, &p.GimnasioID, &p.Nombre, &p.Descripcion,
			&p.Precio, &p.DuracionDias, &p.Activo, &p.CreatedAt); err != nil {
			return nil, err
		}
		lista = append(lista, p)
	}
	return lista, rows.Err()
}
