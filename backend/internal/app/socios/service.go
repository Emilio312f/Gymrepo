package socios

import (
	"context"
	"regexp"
	"strings"

	"gymcontrol/internal/domain"
)

var reSoloLetras = regexp.MustCompile(`^[\p{L} ]+$`)
var reDigitos = regexp.MustCompile(`^[0-9]+$`)

func validarDatos(in EntradaSocio) error {
	if !reSoloLetras.MatchString(strings.TrimSpace(in.Nombres)) ||
		!reSoloLetras.MatchString(strings.TrimSpace(in.Apellidos)) {
		return domain.ErrDatosInvalidos
	}
	doc := strings.TrimSpace(in.Documento)
	if len(doc) != 8 || !reDigitos.MatchString(doc) {
		return domain.ErrDatosInvalidos
	}
	return nil
}

type Service struct {
	repo   Repositorio
	hasher Hasher
}

func NewService(repo Repositorio, hasher Hasher) *Service {
	return &Service{repo: repo, hasher: hasher}
}

type EntradaSocio struct {
	Nombres         string
	Apellidos       string
	Documento       string
	Telefono        string
	Email           string
	Sexo            string
	Direccion       string
	FechaNacimiento string
}

func (s *Service) Crear(ctx context.Context, gimnasioID string, in EntradaSocio) (domain.Socio, error) {
	if err := validarDatos(in); err != nil {
		return domain.Socio{}, err
	}
	socio := domain.Socio{
		GimnasioID:      gimnasioID,
		Nombres:         strings.TrimSpace(in.Nombres),
		Apellidos:       strings.TrimSpace(in.Apellidos),
		Documento:       strings.TrimSpace(in.Documento),
		Telefono:        strings.TrimSpace(in.Telefono),
		Email:           strings.ToLower(strings.TrimSpace(in.Email)),
		Sexo:            strings.TrimSpace(in.Sexo),
		Direccion:       strings.TrimSpace(in.Direccion),
		FechaNacimiento: strings.TrimSpace(in.FechaNacimiento),
		Activo:          true,
	}
	return s.repo.Crear(ctx, socio)
}

func (s *Service) Listar(ctx context.Context, gimnasioID string) ([]domain.Socio, error) {
	return s.repo.Listar(ctx, gimnasioID)
}

func (s *Service) Obtener(ctx context.Context, gimnasioID, id string) (domain.Socio, error) {
	return s.repo.Obtener(ctx, gimnasioID, id)
}

func (s *Service) Actualizar(ctx context.Context, gimnasioID, id string, in EntradaSocio) (domain.Socio, error) {
	if err := validarDatos(in); err != nil {
		return domain.Socio{}, err
	}
	socio := domain.Socio{
		ID:              id,
		GimnasioID:      gimnasioID,
		Nombres:         strings.TrimSpace(in.Nombres),
		Apellidos:       strings.TrimSpace(in.Apellidos),
		Documento:       strings.TrimSpace(in.Documento),
		Telefono:        strings.TrimSpace(in.Telefono),
		Email:           strings.ToLower(strings.TrimSpace(in.Email)),
		Sexo:            strings.TrimSpace(in.Sexo),
		Direccion:       strings.TrimSpace(in.Direccion),
		FechaNacimiento: strings.TrimSpace(in.FechaNacimiento),
	}
	return s.repo.Actualizar(ctx, socio)
}

func (s *Service) CambiarEstado(ctx context.Context, gimnasioID, id string, activo bool) error {
	return s.repo.CambiarEstado(ctx, gimnasioID, id, activo)
}

func (s *Service) ObtenerPorUsuario(ctx context.Context, gimnasioID, usuarioID string) (domain.Socio, error) {
	return s.repo.ObtenerPorUsuario(ctx, gimnasioID, usuarioID)
}

type EntradaAcceso struct {
	Email    string
	Password string
}

func (s *Service) CrearAcceso(ctx context.Context, gimnasioID, socioID string, in EntradaAcceso) error {
	email := strings.ToLower(strings.TrimSpace(in.Email))
	if !strings.Contains(email, "@") || len(strings.TrimSpace(in.Password)) < 6 {
		return domain.ErrDatosInvalidos
	}
	socio, err := s.repo.Obtener(ctx, gimnasioID, socioID)
	if err != nil {
		return err
	}
	hash, err := s.hasher.Hash(strings.TrimSpace(in.Password))
	if err != nil {
		return err
	}
	u := domain.Usuario{
		GimnasioID:   gimnasioID,
		Email:        email,
		PasswordHash: hash,
		Rol:          domain.RolSocio,
		Nombre:       strings.TrimSpace(socio.Nombres + " " + socio.Apellidos),
		Activo:       true,
	}
	_, err = s.repo.CrearAcceso(ctx, gimnasioID, socioID, u)
	return err
}
