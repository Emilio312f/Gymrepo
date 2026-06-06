package planes

import (
	"context"
	"strings"

	"gymcontrol/internal/domain"
)

type Repositorio interface {
	Crear(ctx context.Context, p domain.Plan) (domain.Plan, error)
	Listar(ctx context.Context, gimnasioID string, soloActivos bool) ([]domain.Plan, error)
}

type Service struct {
	repo Repositorio
}

func NewService(repo Repositorio) *Service {
	return &Service{repo: repo}
}

type EntradaPlan struct {
	Nombre       string
	Descripcion  string
	Precio       float64
	DuracionDias int
}

func (s *Service) Crear(ctx context.Context, gimnasioID string, in EntradaPlan) (domain.Plan, error) {
	plan := domain.Plan{
		GimnasioID:   gimnasioID,
		Nombre:       strings.TrimSpace(in.Nombre),
		Descripcion:  strings.TrimSpace(in.Descripcion),
		Precio:       in.Precio,
		DuracionDias: in.DuracionDias,
		Activo:       true,
	}
	return s.repo.Crear(ctx, plan)
}

func (s *Service) Listar(ctx context.Context, gimnasioID string, soloActivos bool) ([]domain.Plan, error) {
	return s.repo.Listar(ctx, gimnasioID, soloActivos)
}
