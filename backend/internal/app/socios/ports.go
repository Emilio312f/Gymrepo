package socios

import (
	"context"

	"gymcontrol/internal/domain"
)

type Repositorio interface {
	Crear(ctx context.Context, s domain.Socio) (domain.Socio, error)
	Listar(ctx context.Context, gimnasioID string) ([]domain.Socio, error)
	Obtener(ctx context.Context, gimnasioID, id string) (domain.Socio, error)
}
