package domain

import "time"

type Membresia struct {
	ID           string
	GimnasioID   string
	SocioID      string
	PlanID       string
	PlanNombre   string
	FechaInicio  string
	FechaFin     string
	PrecioPagado float64
	Estado       string
	Operacion    string
	CreatedAt    time.Time
}

type EstadoMembresia struct {
	TieneMembresia bool
	PlanNombre     string
	FechaInicio    string
	FechaFin       string
	AlDia          bool
	DiasRestantes  int
}
