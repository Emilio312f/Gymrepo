package asistencia

import (
	"context"
	"strings"
	"time"

	"gymcontrol/internal/domain"
)

type Repositorio interface {
	BuscarSocio(ctx context.Context, gimnasioID, consulta string) (domain.Socio, error)
	Registrar(ctx context.Context, gimnasioID, socioID string) (time.Time, error)
	ListarDelDia(ctx context.Context, gimnasioID string) ([]Asistencia, error)
}

type ConsultorMembresia interface {
	EstadoActual(ctx context.Context, gimnasioID, socioID string) (domain.EstadoMembresia, error)
}

type Asistencia struct {
	FechaHora time.Time
	Nombres   string
	Apellidos string
	Documento string
	Codigo    string
}

type Acceso struct {
	Socio     domain.Socio
	Estado    domain.EstadoMembresia
	Permitido bool
	Motivo    string
}

type Service struct {
	repo      Repositorio
	membresia ConsultorMembresia
}

func NewService(repo Repositorio, membresia ConsultorMembresia) *Service {
	return &Service{repo: repo, membresia: membresia}
}

func (s *Service) ValidarAcceso(ctx context.Context, gimnasioID, consulta string) (Acceso, error) {
	socio, err := s.repo.BuscarSocio(ctx, gimnasioID, strings.TrimSpace(consulta))
	if err != nil {
		return Acceso{}, err
	}

	estado, err := s.membresia.EstadoActual(ctx, gimnasioID, socio.ID)
	if err != nil {
		return Acceso{}, err
	}

	acc := Acceso{Socio: socio, Estado: estado}
	switch {
	case !socio.Activo:
		acc.Motivo = "Socio deshabilitado"
	case !estado.TieneMembresia:
		acc.Motivo = "Sin membresía registrada"
	case !estado.AlDia:
		acc.Motivo = "Membresía vencida"
	default:
		acc.Permitido = true
	}

	if acc.Permitido {
		if _, err := s.repo.Registrar(ctx, gimnasioID, socio.ID); err != nil {
			return Acceso{}, err
		}
	}
	return acc, nil
}

func (s *Service) ListarDelDia(ctx context.Context, gimnasioID string) ([]Asistencia, error) {
	return s.repo.ListarDelDia(ctx, gimnasioID)
}
