package socios

import (
	"context"

	"gymcontrol/internal/domain"
)

type Repositorio interface {
	Crear(ctx context.Context, s domain.Socio) (domain.Socio, error)
	Listar(ctx context.Context, gimnasioID string) ([]domain.Socio, error)
	Obtener(ctx context.Context, gimnasioID, id string) (domain.Socio, error)
	Actualizar(ctx context.Context, s domain.Socio) (domain.Socio, error)
	CambiarEstado(ctx context.Context, gimnasioID, id string, activo bool) error
	ObtenerPorUsuario(ctx context.Context, gimnasioID, usuarioID string) (domain.Socio, error)
	CrearAcceso(ctx context.Context, gimnasioID, socioID string, u domain.Usuario) (string, error)
}

type Hasher interface {
	Hash(plano string) (string, error)
}
