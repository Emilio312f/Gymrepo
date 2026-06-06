package postgres

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"gymcontrol/internal/app/membresias"
	"gymcontrol/internal/domain"
)

type MembresiasRepo struct {
	pool *pgxpool.Pool
}

func NewMembresiasRepo(pool *pgxpool.Pool) *MembresiasRepo {
	return &MembresiasRepo{pool: pool}
}

var _ membresias.Repositorio = (*MembresiasRepo)(nil)

func (r *MembresiasRepo) RegistrarPago(ctx context.Context, gimnasioID, socioID, planID, metodo, registradoPor string) (domain.Membresia, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return domain.Membresia{}, err
	}
	defer tx.Rollback(ctx)

	m := domain.Membresia{
		GimnasioID: gimnasioID,
		SocioID:    socioID,
		PlanID:     planID,
		Estado:     "activa",
	}

	err = tx.QueryRow(ctx,
		`WITH p AS (
		   SELECT precio, duracion_dias FROM plan
		   WHERE gimnasio_id = $1 AND id = $3 AND activo = true
		 ),
		 ini AS (
		   SELECT GREATEST(CURRENT_DATE, COALESCE(
		     (SELECT MAX(fecha_fin) FROM membresia
		      WHERE gimnasio_id = $1 AND socio_id = $2
		        AND estado = 'activa' AND fecha_fin >= CURRENT_DATE),
		     CURRENT_DATE)) AS fi
		 )
		 INSERT INTO membresia (gimnasio_id, socio_id, plan_id, fecha_inicio, fecha_fin, precio_pagado, estado)
		 SELECT $1, $2, $3, ini.fi, ini.fi + p.duracion_dias, p.precio, 'activa'
		 FROM p, ini
		 RETURNING id, to_char(fecha_inicio, 'YYYY-MM-DD'), to_char(fecha_fin, 'YYYY-MM-DD'), precio_pagado::float8`,
		gimnasioID, socioID, planID,
	).Scan(&m.ID, &m.FechaInicio, &m.FechaFin, &m.PrecioPagado)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Membresia{}, domain.ErrNoEncontrado
	}
	if err != nil {
		return domain.Membresia{}, err
	}

	_, err = tx.Exec(ctx,
		`INSERT INTO pago (gimnasio_id, membresia_id, monto, metodo, registrado_por)
		 VALUES ($1, $2, $3, $4::metodo_pago, $5)`,
		gimnasioID, m.ID, m.PrecioPagado, metodo, registradoPor,
	)
	if err != nil {
		return domain.Membresia{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return domain.Membresia{}, err
	}
	return m, nil
}

func (r *MembresiasRepo) EstadoActual(ctx context.Context, gimnasioID, socioID string) (domain.EstadoMembresia, error) {
	var e domain.EstadoMembresia
	err := r.pool.QueryRow(ctx,
		`SELECT p.nombre,
		        to_char(m.fecha_inicio, 'YYYY-MM-DD'),
		        to_char(m.fecha_fin, 'YYYY-MM-DD'),
		        (m.estado = 'activa' AND m.fecha_fin >= CURRENT_DATE) AS al_dia,
		        (m.fecha_fin - CURRENT_DATE) AS dias
		 FROM membresia m JOIN plan p ON p.id = m.plan_id
		 WHERE m.gimnasio_id = $1 AND m.socio_id = $2
		 ORDER BY m.fecha_fin DESC LIMIT 1`,
		gimnasioID, socioID,
	).Scan(&e.PlanNombre, &e.FechaInicio, &e.FechaFin, &e.AlDia, &e.DiasRestantes)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.EstadoMembresia{TieneMembresia: false}, nil
	}
	if err != nil {
		return domain.EstadoMembresia{}, err
	}
	e.TieneMembresia = true
	return e, nil
}

func (r *MembresiasRepo) Historial(ctx context.Context, gimnasioID, socioID string) ([]domain.Membresia, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT m.id, m.plan_id, p.nombre,
		        to_char(m.fecha_inicio, 'YYYY-MM-DD'),
		        to_char(m.fecha_fin, 'YYYY-MM-DD'),
		        m.precio_pagado::float8, m.estado, m.created_at
		 FROM membresia m JOIN plan p ON p.id = m.plan_id
		 WHERE m.gimnasio_id = $1 AND m.socio_id = $2
		 ORDER BY m.created_at DESC`,
		gimnasioID, socioID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	lista := make([]domain.Membresia, 0)
	for rows.Next() {
		var m domain.Membresia
		m.GimnasioID = gimnasioID
		m.SocioID = socioID
		if err := rows.Scan(&m.ID, &m.PlanID, &m.PlanNombre, &m.FechaInicio,
			&m.FechaFin, &m.PrecioPagado, &m.Estado, &m.CreatedAt); err != nil {
			return nil, err
		}
		lista = append(lista, m)
	}
	return lista, rows.Err()
}
