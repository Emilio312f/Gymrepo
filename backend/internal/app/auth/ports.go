// Package auth contiene los casos de uso de autenticación.
//
// Siguiendo la arquitectura hexagonal, este paquete define las INTERFACES
// (puertos) que necesita. La infraestructura (BD, hashing, JWT) las implementa.
// Así el caso de uso no depende de detalles externos y es testeable en aislamiento.
package auth

import (
	"context"

	"gymcontrol/internal/domain"
)

// Repositorio es el puerto de salida hacia el almacenamiento.
type Repositorio interface {
	// CrearGimnasioConAdmin da de alta un gimnasio y su usuario administrador
	// en una sola transacción. Devuelve el gimnasio y el usuario ya con sus IDs.
	CrearGimnasioConAdmin(ctx context.Context, g domain.Gimnasio, admin domain.Usuario) (domain.Gimnasio, domain.Usuario, error)

	// BuscarGimnasioPorSlug localiza el tenant a partir de su slug.
	BuscarGimnasioPorSlug(ctx context.Context, slug string) (domain.Gimnasio, error)

	// BuscarUsuarioPorEmail busca dentro de un gimnasio concreto (aislamiento por tenant).
	BuscarUsuarioPorEmail(ctx context.Context, gimnasioID, email string) (domain.Usuario, error)
}

// Hasher es el puerto para el hashing de contraseñas.
type Hasher interface {
	Hash(plano string) (string, error)
	Comparar(hash, plano string) error
}

// EmisorToken es el puerto para generar tokens de sesión.
type EmisorToken interface {
	Generar(usuarioID, gimnasioID, rol string) (string, error)
}
