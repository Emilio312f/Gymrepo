package domain

import "time"

type Plan struct {
	ID           string
	GimnasioID   string
	Nombre       string
	Descripcion  string
	Precio       float64
	DuracionDias int
	Activo       bool
	CreatedAt    time.Time
}
