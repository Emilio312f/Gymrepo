package personal

import (
	"context"
	"strings"

	"gymcontrol/internal/domain"
)

type Repositorio interface {
	Crear(ctx context.Context, u domain.Usuario) (domain.Usuario, error)
	Listar(ctx context.Context, gimnasioID string) ([]domain.Usuario, error)
}

type Hasher interface {
	Hash(plano string) (string, error)
}

type Service struct {
	repo   Repositorio
	hasher Hasher
}

func NewService(repo Repositorio, hasher Hasher) *Service {
	return &Service{repo: repo, hasher: hasher}
}

type Entrada struct {
	Nombre   string
	Email    string
	Password string
	Rol      string
}

func (s *Service) Crear(ctx context.Context, gimnasioID string, in Entrada) (domain.Usuario, error) {
	rol := domain.Rol(strings.TrimSpace(in.Rol))
	if rol != domain.RolAdmin && rol != domain.RolRecepcion {
		return domain.Usuario{}, domain.ErrRolInvalido
	}

	hash, err := s.hasher.Hash(in.Password)
	if err != nil {
		return domain.Usuario{}, err
	}

	u := domain.Usuario{
		GimnasioID:   gimnasioID,
		Email:        strings.ToLower(strings.TrimSpace(in.Email)),
		PasswordHash: hash,
		Rol:          rol,
		Nombre:       strings.TrimSpace(in.Nombre),
		Activo:       true,
	}
	return s.repo.Crear(ctx, u)
}

func (s *Service) Listar(ctx context.Context, gimnasioID string) ([]domain.Usuario, error) {
	return s.repo.Listar(ctx, gimnasioID)
}
