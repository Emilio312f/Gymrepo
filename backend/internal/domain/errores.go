package domain

import "errors"

// Errores de dominio. La capa HTTP los traduce a códigos de estado,
// sin filtrar detalles internos al cliente.
var (
	ErrCredencialesInvalidas = errors.New("credenciales inválidas")
	ErrSlugEnUso             = errors.New("el slug del gimnasio ya está en uso")
	ErrEmailEnUso            = errors.New("el email ya está registrado en este gimnasio")
	ErrNoEncontrado          = errors.New("recurso no encontrado")
	ErrRolInvalido           = errors.New("rol inválido")
	ErrSocioDuplicado        = errors.New("ya existe un socio con ese código o documento en este gimnasio")
	ErrAccesoYaExiste        = errors.New("este socio ya tiene una cuenta de acceso")
	ErrYaTienePendiente      = errors.New("el socio ya tiene un plan pendiente de pago")
	ErrDNIInvalido           = errors.New("el DNI debe tener 8 dígitos")
	ErrDatosInvalidos        = errors.New("datos inválidos")
)
