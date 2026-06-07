package pagos

import (
	"context"

	"gymcontrol/internal/domain"
)

type Repositorio interface {
	Listar(ctx context.Context, gimnasioID, desde, hasta string) ([]domain.Pago, error)
	ListarPorSocio(ctx context.Context, gimnasioID, socioID string) ([]domain.Pago, error)
}

type Service struct {
	repo Repositorio
}

func NewService(repo Repositorio) *Service {
	return &Service{repo: repo}
}

func (s *Service) Listar(ctx context.Context, gimnasioID, desde, hasta string) ([]domain.Pago, float64, error) {
	lista, err := s.repo.Listar(ctx, gimnasioID, desde, hasta)
	if err != nil {
		return nil, 0, err
	}
	var total float64
	for _, p := range lista {
		total += p.Monto
	}
	return lista, total, nil
}

func (s *Service) ListarPorSocio(ctx context.Context, gimnasioID, socioID string) ([]domain.Pago, error) {
	return s.repo.ListarPorSocio(ctx, gimnasioID, socioID)
}
