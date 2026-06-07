package postgres

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"gymcontrol/internal/app/asistencia"
	"gymcontrol/internal/domain"
)

type AsistenciaRepo struct {
	pool *pgxpool.Pool
}

func NewAsistenciaRepo(pool *pgxpool.Pool) *AsistenciaRepo {
	return &AsistenciaRepo{pool: pool}
}

var _ asistencia.Repositorio = (*AsistenciaRepo)(nil)

func (r *AsistenciaRepo) BuscarSocio(ctx context.Context, gimnasioID, consulta string) (domain.Socio, error) {
	var s domain.Socio
	err := r.pool.QueryRow(ctx,
		`SELECT id, gimnasio_id, codigo, nombres, apellidos, documento, activo
		 FROM socio
		 WHERE gimnasio_id = $1 AND (documento = $2 OR codigo = $2)
		 LIMIT 1`,
		gimnasioID, consulta,
	).Scan(&s.ID, &s.GimnasioID, &s.Codigo, &s.Nombres, &s.Apellidos,
		&s.Documento, &s.Activo)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Socio{}, domain.ErrNoEncontrado
	}
	if err != nil {
		return domain.Socio{}, err
	}
	return s, nil
}

func (r *AsistenciaRepo) Registrar(ctx context.Context, gimnasioID, socioID string) (time.Time, error) {
	var t time.Time
	err := r.pool.QueryRow(ctx,
		`INSERT INTO asistencia (gimnasio_id, socio_id) VALUES ($1, $2)
		 RETURNING fecha_hora`,
		gimnasioID, socioID,
	).Scan(&t)
	return t, err
}

func (r *AsistenciaRepo) ListarDelDia(ctx context.Context, gimnasioID string) ([]asistencia.Asistencia, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT a.fecha_hora, s.nombres, s.apellidos, s.documento, s.codigo
		 FROM asistencia a JOIN socio s ON s.id = a.socio_id
		 WHERE a.gimnasio_id = $1 AND a.fecha_hora::date = CURRENT_DATE
		 ORDER BY a.fecha_hora DESC`,
		gimnasioID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	lista := make([]asistencia.Asistencia, 0)
	for rows.Next() {
		var a asistencia.Asistencia
		if err := rows.Scan(&a.FechaHora, &a.Nombres, &a.Apellidos,
			&a.Documento, &a.Codigo); err != nil {
			return nil, err
		}
		lista = append(lista, a)
	}
	return lista, rows.Err()
}
