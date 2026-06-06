package membresias

import (
	"context"

	"gymcontrol/internal/domain"
)

type Repositorio interface {
	RegistrarPago(ctx context.Context, gimnasioID, socioID, planID, metodo, registradoPor string) (domain.Membresia, error)
	EstadoActual(ctx context.Context, gimnasioID, socioID string) (domain.EstadoMembresia, error)
	Historial(ctx context.Context, gimnasioID, socioID string) ([]domain.Membresia, error)
}

type Service struct {
	repo Repositorio
}

func NewService(repo Repositorio) *Service {
	return &Service{repo: repo}
}

func (s *Service) RegistrarPago(ctx context.Context, gimnasioID, socioID, planID, metodo, registradoPor string) (domain.Membresia, error) {
	if metodo == "" {
		metodo = "efectivo"
	}
	return s.repo.RegistrarPago(ctx, gimnasioID, socioID, planID, metodo, registradoPor)
}

func (s *Service) EstadoActual(ctx context.Context, gimnasioID, socioID string) (domain.EstadoMembresia, error) {
	return s.repo.EstadoActual(ctx, gimnasioID, socioID)
}

func (s *Service) Historial(ctx context.Context, gimnasioID, socioID string) ([]domain.Membresia, error) {
	return s.repo.Historial(ctx, gimnasioID, socioID)
}
