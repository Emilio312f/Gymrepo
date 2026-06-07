package postgres

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"

	"gymcontrol/internal/app/pagos"
	"gymcontrol/internal/domain"
)

type PagosRepo struct {
	pool *pgxpool.Pool
}

func NewPagosRepo(pool *pgxpool.Pool) *PagosRepo {
	return &PagosRepo{pool: pool}
}

var _ pagos.Repositorio = (*PagosRepo)(nil)

func (r *PagosRepo) Listar(ctx context.Context, gimnasioID, desde, hasta string) ([]domain.Pago, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT p.id, s.nombres || ' ' || s.apellidos, s.documento, pl.nombre,
		        p.monto::float8, p.metodo, p.fecha_pago
		 FROM pago p
		 JOIN membresia m ON m.id = p.membresia_id
		 JOIN socio s ON s.id = m.socio_id
		 JOIN plan pl ON pl.id = m.plan_id
		 WHERE p.gimnasio_id = $1
		   AND ($2 = '' OR p.fecha_pago::date >= $2::date)
		   AND ($3 = '' OR p.fecha_pago::date <= $3::date)
		 ORDER BY p.fecha_pago DESC`,
		gimnasioID, desde, hasta,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	lista := make([]domain.Pago, 0)
	for rows.Next() {
		var p domain.Pago
		if err := rows.Scan(&p.ID, &p.SocioNombre, &p.Documento, &p.PlanNombre,
			&p.Monto, &p.Metodo, &p.FechaPago); err != nil {
			return nil, err
		}
		lista = append(lista, p)
	}
	return lista, rows.Err()
}
