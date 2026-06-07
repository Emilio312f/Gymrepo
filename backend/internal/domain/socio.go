package domain

import "time"

type Socio struct {
	ID              string
	GimnasioID      string
	UsuarioID       string
	Codigo          string
	Nombres         string
	Apellidos       string
	Documento       string
	Telefono        string
	Email           string
	Sexo            string
	Direccion       string
	FechaNacimiento string
	Activo          bool
	CreatedAt       time.Time
}
