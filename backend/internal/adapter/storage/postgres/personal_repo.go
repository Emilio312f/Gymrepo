package postgres

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"

	"gymcontrol/internal/app/personal"
	"gymcontrol/internal/domain"
)

type PersonalRepo struct {
	pool *pgxpool.Pool
}

func NewPersonalRepo(pool *pgxpool.Pool) *PersonalRepo {
	return &PersonalRepo{pool: pool}
}

var _ personal.Repositorio = (*PersonalRepo)(nil)

func (r *PersonalRepo) Crear(ctx context.Context, u domain.Usuario) (domain.Usuario, error) {
	err := r.pool.QueryRow(ctx,
		`INSERT INTO usuario (gimnasio_id, email, password_hash, rol, nombre)
		 VALUES ($1, $2, $3, $4, $5)
		 RETURNING id`,
		u.GimnasioID, u.Email, u.PasswordHash, string(u.Rol), u.Nombre,
	).Scan(&u.ID)
	if esViolacionUnica(err) {
		return domain.Usuario{}, domain.ErrEmailEnUso
	}
	if err != nil {
		return domain.Usuario{}, err
	}
	return u, nil
}

func (r *PersonalRepo) Listar(ctx context.Context, gimnasioID string) ([]domain.Usuario, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, gimnasio_id, email, rol, nombre, activo
		 FROM usuario WHERE gimnasio_id = $1 ORDER BY created_at ASC`,
		gimnasioID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	lista := make([]domain.Usuario, 0)
	for rows.Next() {
		var u domain.Usuario
		var rol string
		if err := rows.Scan(&u.ID, &u.GimnasioID, &u.Email, &rol, &u.Nombre, &u.Activo); err != nil {
			return nil, err
		}
		u.Rol = domain.Rol(rol)
		lista = append(lista, u)
	}
	return lista, rows.Err()
}
