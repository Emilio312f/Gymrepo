package socios

import (
	"context"
	"strings"

	"gymcontrol/internal/domain"
)

type Service struct {
	repo Repositorio
}

func NewService(repo Repositorio) *Service {
	return &Service{repo: repo}
}

type EntradaSocio struct {
	Codigo    string
	Nombres   string
	Apellidos string
	Documento string
	Telefono  string
	Email     string
}

func (s *Service) Crear(ctx context.Context, gimnasioID string, in EntradaSocio) (domain.Socio, error) {
	socio := domain.Socio{
		GimnasioID: gimnasioID,
		Codigo:     strings.TrimSpace(in.Codigo),
		Nombres:    strings.TrimSpace(in.Nombres),
		Apellidos:  strings.TrimSpace(in.Apellidos),
		Documento:  strings.TrimSpace(in.Documento),
		Telefono:   strings.TrimSpace(in.Telefono),
		Email:      strings.ToLower(strings.TrimSpace(in.Email)),
		Activo:     true,
	}
	return s.repo.Crear(ctx, socio)
}

func (s *Service) Listar(ctx context.Context, gimnasioID string) ([]domain.Socio, error) {
	return s.repo.Listar(ctx, gimnasioID)
}

func (s *Service) Obtener(ctx context.Context, gimnasioID, id string) (domain.Socio, error) {
	return s.repo.Obtener(ctx, gimnasioID, id)
}
