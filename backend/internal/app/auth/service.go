package auth

import (
	"context"
	"errors"
	"strings"

	"gymcontrol/internal/domain"
)

// Service orquesta los casos de uso de autenticación.
type Service struct {
	repo   Repositorio
	hasher Hasher
	tokens EmisorToken
}

func NewService(repo Repositorio, hasher Hasher, tokens EmisorToken) *Service {
	return &Service{repo: repo, hasher: hasher, tokens: tokens}
}

// EntradaRegistro son los datos para dar de alta un gimnasio nuevo en la plataforma.
type EntradaRegistro struct {
	GimnasioNombre string
	Slug           string
	AdminNombre    string
	AdminEmail     string
	AdminPassword  string
}

// RegistrarGimnasio crea un tenant nuevo junto con su usuario administrador.
// Es el onboarding del SaaS: así nace cada gimnasio en el sistema.
func (s *Service) RegistrarGimnasio(ctx context.Context, in EntradaRegistro) (domain.Gimnasio, error) {
	hash, err := s.hasher.Hash(in.AdminPassword)
	if err != nil {
		return domain.Gimnasio{}, err
	}

	g := domain.Gimnasio{
		Nombre: strings.TrimSpace(in.GimnasioNombre),
		Slug:   strings.ToLower(strings.TrimSpace(in.Slug)),
	}
	admin := domain.Usuario{
		Email:        strings.ToLower(strings.TrimSpace(in.AdminEmail)),
		PasswordHash: hash,
		Rol:          domain.RolAdmin,
		Nombre:       strings.TrimSpace(in.AdminNombre),
		Activo:       true,
	}

	creado, _, err := s.repo.CrearGimnasioConAdmin(ctx, g, admin)
	if err != nil {
		return domain.Gimnasio{}, err
	}
	return creado, nil
}

// Login valida las credenciales dentro de un gimnasio (identificado por slug)
// y devuelve un token de sesión.
//
// Se requiere el slug porque el email es único POR gimnasio: el mismo correo
// puede existir en dos gimnasios distintos. El slug desambigua el tenant.
func (s *Service) Login(ctx context.Context, slug, email, password string) (string, domain.Usuario, error) {
	gim, err := s.repo.BuscarGimnasioPorSlug(ctx, strings.ToLower(strings.TrimSpace(slug)))
	if err != nil {
		// No revelamos si fue el gimnasio o la contraseña: siempre "credenciales inválidas".
		if errors.Is(err, domain.ErrNoEncontrado) {
			return "", domain.Usuario{}, domain.ErrCredencialesInvalidas
		}
		return "", domain.Usuario{}, err
	}

	u, err := s.repo.BuscarUsuarioPorEmail(ctx, gim.ID, strings.ToLower(strings.TrimSpace(email)))
	if err != nil {
		if errors.Is(err, domain.ErrNoEncontrado) {
			return "", domain.Usuario{}, domain.ErrCredencialesInvalidas
		}
		return "", domain.Usuario{}, err
	}

	if !u.Activo {
		return "", domain.Usuario{}, domain.ErrCredencialesInvalidas
	}
	if err := s.hasher.Comparar(u.PasswordHash, password); err != nil {
		return "", domain.Usuario{}, domain.ErrCredencialesInvalidas
	}

	token, err := s.tokens.Generar(u.ID, u.GimnasioID, string(u.Rol))
	if err != nil {
		return "", domain.Usuario{}, err
	}
	return token, u, nil
}
