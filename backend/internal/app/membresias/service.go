package membresias

import (
	"context"
	"strings"

	"gymcontrol/internal/domain"
)

type Repositorio interface {
	RegistrarPago(ctx context.Context, gimnasioID, socioID, planID, metodo, registradoPor string) (domain.Membresia, error)
	EstadoActual(ctx context.Context, gimnasioID, socioID string) (domain.EstadoMembresia, error)
	Historial(ctx context.Context, gimnasioID, socioID string) ([]domain.Membresia, error)
	AsignarPlan(ctx context.Context, gimnasioID, socioID, planID string) (domain.Membresia, error)
	Pendiente(ctx context.Context, gimnasioID, socioID string) (domain.Membresia, error)
	EnviarConstancia(ctx context.Context, gimnasioID, socioID, operacion string) (domain.Membresia, error)
	ConfirmarPago(ctx context.Context, gimnasioID, membresiaID, metodo, registradoPor string) (domain.Membresia, error)
	RechazarPago(ctx context.Context, gimnasioID, membresiaID string) error
	CancelarPendiente(ctx context.Context, gimnasioID, membresiaID string) error
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

// AsignarPlan deja una membresía en estado 'pendiente': el socio la verá y la
// pagará desde su vista. No genera pago todavía.
func (s *Service) AsignarPlan(ctx context.Context, gimnasioID, socioID, planID string) (domain.Membresia, error) {
	return s.repo.AsignarPlan(ctx, gimnasioID, socioID, planID)
}

// Pendiente devuelve el plan que el socio tiene por pagar o en revisión.
func (s *Service) Pendiente(ctx context.Context, gimnasioID, socioID string) (domain.Membresia, error) {
	return s.repo.Pendiente(ctx, gimnasioID, socioID)
}

// EnviarConstancia es la acción del socio: declara su N° de operación Yape y la
// membresía pasa a 'en_revision' hasta que el gimnasio la confirme.
func (s *Service) EnviarConstancia(ctx context.Context, gimnasioID, socioID, operacion string) (domain.Membresia, error) {
	if strings.TrimSpace(operacion) == "" {
		return domain.Membresia{}, domain.ErrDatosInvalidos
	}
	return s.repo.EnviarConstancia(ctx, gimnasioID, socioID, strings.TrimSpace(operacion))
}

// ConfirmarPago es la acción del admin: valida la constancia, activa la
// membresía (recalcula vigencia) y registra el pago.
func (s *Service) ConfirmarPago(ctx context.Context, gimnasioID, membresiaID, metodo, registradoPor string) (domain.Membresia, error) {
	if metodo == "" {
		metodo = "yape_plin"
	}
	return s.repo.ConfirmarPago(ctx, gimnasioID, membresiaID, metodo, registradoPor)
}

// RechazarPago devuelve la membresía a 'pendiente' para que el socio reintente.
func (s *Service) RechazarPago(ctx context.Context, gimnasioID, membresiaID string) error {
	return s.repo.RechazarPago(ctx, gimnasioID, membresiaID)
}

// CancelarPendiente descarta una asignación pendiente o en revisión.
func (s *Service) CancelarPendiente(ctx context.Context, gimnasioID, membresiaID string) error {
	return s.repo.CancelarPendiente(ctx, gimnasioID, membresiaID)
}
