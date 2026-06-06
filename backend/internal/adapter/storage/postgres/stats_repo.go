package postgres

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"

	"gymcontrol/internal/app/stats"
	"gymcontrol/internal/domain"
)

type StatsRepo struct {
	pool *pgxpool.Pool
}

func NewStatsRepo(pool *pgxpool.Pool) *StatsRepo {
	return &StatsRepo{pool: pool}
}

var _ stats.Repositorio = (*StatsRepo)(nil)

func (r *StatsRepo) Dashboard(ctx context.Context, gimnasioID string) (domain.StatsDashboard, error) {
	var s domain.StatsDashboard

	err := r.pool.QueryRow(ctx,
		`SELECT
		   (SELECT count(*) FROM socio WHERE gimnasio_id = $1 AND activo = true),
		   (SELECT count(*) FROM socio WHERE gimnasio_id = $1),
		   (SELECT COALESCE(SUM(monto), 0)::float8 FROM pago
		      WHERE gimnasio_id = $1
		        AND date_trunc('month', fecha_pago) = date_trunc('month', CURRENT_DATE))`,
		gimnasioID,
	).Scan(&s.SociosActivos, &s.SociosTotal, &s.IngresosMes)
	if err != nil {
		return domain.StatsDashboard{}, err
	}

	err = r.pool.QueryRow(ctx,
		`WITH ultimas AS (
		   SELECT DISTINCT ON (socio_id) fecha_fin
		   FROM membresia WHERE gimnasio_id = $1
		   ORDER BY socio_id, fecha_fin DESC
		 )
		 SELECT
		   COUNT(*) FILTER (WHERE fecha_fin >= CURRENT_DATE AND fecha_fin <= CURRENT_DATE + 7),
		   COUNT(*) FILTER (WHERE fecha_fin < CURRENT_DATE)
		 FROM ultimas`,
		gimnasioID,
	).Scan(&s.VencenSemana, &s.Vencidas)
	if err != nil {
		return domain.StatsDashboard{}, err
	}

	return s, nil
}
