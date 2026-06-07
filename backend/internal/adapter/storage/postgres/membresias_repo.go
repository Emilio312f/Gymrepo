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
		        (m.fecha_fin >= CURRENT_DATE) AS al_dia,
		        (m.fecha_fin - CURRENT_DATE) AS dias
		 FROM membresia m JOIN plan p ON p.id = m.plan_id
		 WHERE m.gimnasio_id = $1 AND m.socio_id = $2 AND m.estado = 'activa'
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

func (r *MembresiasRepo) AsignarPlan(ctx context.Context, gimnasioID, socioID, planID string) (domain.Membresia, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return domain.Membresia{}, err
	}
	defer tx.Rollback(ctx)

	var existe bool
	if err := tx.QueryRow(ctx,
		`SELECT EXISTS(
		   SELECT 1 FROM membresia
		   WHERE gimnasio_id = $1 AND socio_id = $2 AND estado IN ('pendiente', 'en_revision'))`,
		gimnasioID, socioID,
	).Scan(&existe); err != nil {
		return domain.Membresia{}, err
	}
	if existe {
		return domain.Membresia{}, domain.ErrYaTienePendiente
	}

	m := domain.Membresia{GimnasioID: gimnasioID, SocioID: socioID, PlanID: planID, Estado: "pendiente"}
	err = tx.QueryRow(ctx,
		`WITH p AS (
		   SELECT precio, duracion_dias FROM plan
		   WHERE gimnasio_id = $1 AND id = $3 AND activo = true
		 )
		 INSERT INTO membresia (gimnasio_id, socio_id, plan_id, fecha_inicio, fecha_fin, precio_pagado, estado)
		 SELECT $1, $2, $3, CURRENT_DATE, CURRENT_DATE + p.duracion_dias, p.precio, 'pendiente'
		 FROM p
		 RETURNING id, precio_pagado::float8`,
		gimnasioID, socioID, planID,
	).Scan(&m.ID, &m.PrecioPagado)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Membresia{}, domain.ErrNoEncontrado
	}
	if err != nil {
		return domain.Membresia{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return domain.Membresia{}, err
	}
	return m, nil
}

func (r *MembresiasRepo) Pendiente(ctx context.Context, gimnasioID, socioID string) (domain.Membresia, error) {
	m := domain.Membresia{GimnasioID: gimnasioID, SocioID: socioID}
	err := r.pool.QueryRow(ctx,
		`SELECT m.id, m.plan_id, p.nombre, m.precio_pagado::float8, m.estado, COALESCE(m.operacion_yape, '')
		 FROM membresia m JOIN plan p ON p.id = m.plan_id
		 WHERE m.gimnasio_id = $1 AND m.socio_id = $2 AND m.estado IN ('pendiente', 'en_revision')
		 ORDER BY m.created_at DESC LIMIT 1`,
		gimnasioID, socioID,
	).Scan(&m.ID, &m.PlanID, &m.PlanNombre, &m.PrecioPagado, &m.Estado, &m.Operacion)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Membresia{}, domain.ErrNoEncontrado
	}
	if err != nil {
		return domain.Membresia{}, err
	}
	return m, nil
}

func (r *MembresiasRepo) EnviarConstancia(ctx context.Context, gimnasioID, socioID, operacion string) (domain.Membresia, error) {
	m := domain.Membresia{GimnasioID: gimnasioID, SocioID: socioID, Operacion: operacion, Estado: "en_revision"}
	err := r.pool.QueryRow(ctx,
		`UPDATE membresia SET estado = 'en_revision', operacion_yape = $3
		 WHERE gimnasio_id = $1 AND socio_id = $2 AND estado IN ('pendiente', 'en_revision')
		 RETURNING id`,
		gimnasioID, socioID, operacion,
	).Scan(&m.ID)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Membresia{}, domain.ErrNoEncontrado
	}
	if err != nil {
		return domain.Membresia{}, err
	}
	return m, nil
}

func (r *MembresiasRepo) ConfirmarPago(ctx context.Context, gimnasioID, membresiaID, metodo, registradoPor string) (domain.Membresia, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return domain.Membresia{}, err
	}
	defer tx.Rollback(ctx)

	m := domain.Membresia{GimnasioID: gimnasioID, Estado: "activa"}
	err = tx.QueryRow(ctx,
		`WITH obj AS (
		   SELECT mm.socio_id, pl.duracion_dias
		   FROM membresia mm JOIN plan pl ON pl.id = mm.plan_id
		   WHERE mm.gimnasio_id = $1 AND mm.id = $2 AND mm.estado IN ('pendiente', 'en_revision')
		 ),
		 ini AS (
		   SELECT GREATEST(CURRENT_DATE, COALESCE(
		     (SELECT MAX(fecha_fin) FROM membresia
		      WHERE gimnasio_id = $1 AND socio_id = (SELECT socio_id FROM obj)
		        AND estado = 'activa' AND fecha_fin >= CURRENT_DATE),
		     CURRENT_DATE)) AS fi
		 )
		 UPDATE membresia SET
		   estado = 'activa',
		   fecha_inicio = ini.fi,
		   fecha_fin = ini.fi + obj.duracion_dias
		 FROM obj, ini
		 WHERE membresia.id = $2 AND membresia.gimnasio_id = $1
		 RETURNING membresia.id, membresia.socio_id,
		           to_char(membresia.fecha_inicio, 'YYYY-MM-DD'),
		           to_char(membresia.fecha_fin, 'YYYY-MM-DD'),
		           membresia.precio_pagado::float8`,
		gimnasioID, membresiaID,
	).Scan(&m.ID, &m.SocioID, &m.FechaInicio, &m.FechaFin, &m.PrecioPagado)
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

func (r *MembresiasRepo) RechazarPago(ctx context.Context, gimnasioID, membresiaID string) error {
	tag, err := r.pool.Exec(ctx,
		`UPDATE membresia SET estado = 'pendiente', operacion_yape = NULL
		 WHERE gimnasio_id = $1 AND id = $2 AND estado = 'en_revision'`,
		gimnasioID, membresiaID,
	)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return domain.ErrNoEncontrado
	}
	return nil
}

func (r *MembresiasRepo) CancelarPendiente(ctx context.Context, gimnasioID, membresiaID string) error {
	tag, err := r.pool.Exec(ctx,
		`UPDATE membresia SET estado = 'cancelada'
		 WHERE gimnasio_id = $1 AND id = $2 AND estado IN ('pendiente', 'en_revision')`,
		gimnasioID, membresiaID,
	)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return domain.ErrNoEncontrado
	}
	return nil
}
