package documento

import "context"

type Persona struct {
	Nombres         string
	ApellidoPaterno string
	ApellidoMaterno string
	NombreCompleto  string
}

type Consultor interface {
	PorDNI(ctx context.Context, dni string) (Persona, error)
}
