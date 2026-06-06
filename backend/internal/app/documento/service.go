package documento

import (
	"context"
	"strings"

	"gymcontrol/internal/domain"
)

type Service struct {
	consultor Consultor
}

func NewService(consultor Consultor) *Service {
	return &Service{consultor: consultor}
}

func (s *Service) Consultar(ctx context.Context, dni string) (Persona, error) {
	dni = strings.TrimSpace(dni)
	if len(dni) != 8 {
		return Persona{}, domain.ErrDNIInvalido
	}
	for _, c := range dni {
		if c < '0' || c > '9' {
			return Persona{}, domain.ErrDNIInvalido
		}
	}
	return s.consultor.PorDNI(ctx, dni)
}
