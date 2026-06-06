package stats

import (
	"context"

	"gymcontrol/internal/domain"
)

type Repositorio interface {
	Dashboard(ctx context.Context, gimnasioID string) (domain.StatsDashboard, error)
}

type Service struct {
	repo Repositorio
}

func NewService(repo Repositorio) *Service {
	return &Service{repo: repo}
}

func (s *Service) Dashboard(ctx context.Context, gimnasioID string) (domain.StatsDashboard, error) {
	return s.repo.Dashboard(ctx, gimnasioID)
}
