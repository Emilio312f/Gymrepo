package postgres

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"gymcontrol/internal/app/auth"
	"gymcontrol/internal/domain"
)

// AuthRepo implementa auth.Repositorio sobre PostgreSQL.
type AuthRepo struct {
	pool *pgxpool.Pool
}

func NewAuthRepo(pool *pgxpool.Pool) *AuthRepo {
	return &AuthRepo{pool: pool}
}

// Verificación en tiempo de compilación de que cumplimos el puerto.
var _ auth.Repositorio = (*AuthRepo)(nil)

func (r *AuthRepo) CrearGimnasioConAdmin(ctx context.Context, g domain.Gimnasio, admin domain.Usuario) (domain.Gimnasio, domain.Usuario, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return domain.Gimnasio{}, domain.Usuario{}, err
	}
	defer tx.Rollback(ctx) // no-op si ya se hizo Commit

	err = tx.QueryRow(ctx,
		`INSERT INTO gimnasio (nombre, slug) VALUES ($1, $2) RETURNING id`,
		g.Nombre, g.Slug,
	).Scan(&g.ID)
	if err != nil {
		if esViolacionUnica(err) {
			return domain.Gimnasio{}, domain.Usuario{}, domain.ErrSlugEnUso
		}
		return domain.Gimnasio{}, domain.Usuario{}, err
	}

	admin.GimnasioID = g.ID
	err = tx.QueryRow(ctx,
		`INSERT INTO usuario (gimnasio_id, email, password_hash, rol, nombre)
		 VALUES ($1, $2, $3, $4, $5) RETURNING id`,
		admin.GimnasioID, admin.Email, admin.PasswordHash, string(admin.Rol), admin.Nombre,
	).Scan(&admin.ID)
	if err != nil {
		if esViolacionUnica(err) {
			return domain.Gimnasio{}, domain.Usuario{}, domain.ErrEmailEnUso
		}
		return domain.Gimnasio{}, domain.Usuario{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return domain.Gimnasio{}, domain.Usuario{}, err
	}
	return g, admin, nil
}

func (r *AuthRepo) BuscarGimnasioPorSlug(ctx context.Context, slug string) (domain.Gimnasio, error) {
	var g domain.Gimnasio
	err := r.pool.QueryRow(ctx,
		`SELECT id, nombre, slug FROM gimnasio WHERE slug = $1 AND activo = true`,
		slug,
	).Scan(&g.ID, &g.Nombre, &g.Slug)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Gimnasio{}, domain.ErrNoEncontrado
	}
	return g, err
}

func (r *AuthRepo) BuscarUsuarioPorEmail(ctx context.Context, gimnasioID, email string) (domain.Usuario, error) {
	var u domain.Usuario
	var rol string
	err := r.pool.QueryRow(ctx,
		`SELECT id, gimnasio_id, email, password_hash, rol, nombre, activo
		 FROM usuario WHERE gimnasio_id = $1 AND email = $2`,
		gimnasioID, email,
	).Scan(&u.ID, &u.GimnasioID, &u.Email, &u.PasswordHash, &rol, &u.Nombre, &u.Activo)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Usuario{}, domain.ErrNoEncontrado
	}
	if err != nil {
		return domain.Usuario{}, err
	}
	u.Rol = domain.Rol(rol)
	return u, nil
}

// esViolacionUnica detecta el error de PostgreSQL por clave única duplicada (23505).
func esViolacionUnica(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23505"
}
