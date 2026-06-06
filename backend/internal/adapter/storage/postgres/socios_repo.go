package postgres

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"gymcontrol/internal/app/socios"
	"gymcontrol/internal/domain"
)

type SociosRepo struct {
	pool *pgxpool.Pool
}

func NewSociosRepo(pool *pgxpool.Pool) *SociosRepo {
	return &SociosRepo{pool: pool}
}

var _ socios.Repositorio = (*SociosRepo)(nil)

func (r *SociosRepo) Crear(ctx context.Context, s domain.Socio) (domain.Socio, error) {
	err := r.pool.QueryRow(ctx,
		`INSERT INTO socio (gimnasio_id, codigo, nombres, apellidos, documento, telefono, email)
		 VALUES ($1, $2, $3, $4, $5, NULLIF($6, ''), NULLIF($7, ''))
		 RETURNING id, activo, created_at`,
		s.GimnasioID, s.Codigo, s.Nombres, s.Apellidos, s.Documento, s.Telefono, s.Email,
	).Scan(&s.ID, &s.Activo, &s.CreatedAt)
	if esViolacionUnica(err) {
		return domain.Socio{}, domain.ErrSocioDuplicado
	}
	if err != nil {
		return domain.Socio{}, err
	}
	return s, nil
}

func (r *SociosRepo) Listar(ctx context.Context, gimnasioID string) ([]domain.Socio, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, gimnasio_id, codigo, nombres, apellidos, documento,
		        COALESCE(telefono, ''), COALESCE(email, ''), activo, created_at
		 FROM socio WHERE gimnasio_id = $1 ORDER BY created_at DESC`,
		gimnasioID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	lista := make([]domain.Socio, 0)
	for rows.Next() {
		var s domain.Socio
		if err := rows.Scan(&s.ID, &s.GimnasioID, &s.Codigo, &s.Nombres, &s.Apellidos,
			&s.Documento, &s.Telefono, &s.Email, &s.Activo, &s.CreatedAt); err != nil {
			return nil, err
		}
		lista = append(lista, s)
	}
	return lista, rows.Err()
}

func (r *SociosRepo) Obtener(ctx context.Context, gimnasioID, id string) (domain.Socio, error) {
	var s domain.Socio
	err := r.pool.QueryRow(ctx,
		`SELECT id, gimnasio_id, codigo, nombres, apellidos, documento,
		        COALESCE(telefono, ''), COALESCE(email, ''), activo, created_at
		 FROM socio WHERE gimnasio_id = $1 AND id = $2`,
		gimnasioID, id,
	).Scan(&s.ID, &s.GimnasioID, &s.Codigo, &s.Nombres, &s.Apellidos,
		&s.Documento, &s.Telefono, &s.Email, &s.Activo, &s.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Socio{}, domain.ErrNoEncontrado
	}
	if err != nil {
		return domain.Socio{}, err
	}
	return s, nil
}
