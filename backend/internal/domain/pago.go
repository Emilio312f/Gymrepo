package domain

import "time"

type Pago struct {
	ID          string
	SocioNombre string
	Documento   string
	PlanNombre  string
	Monto       float64
	Metodo      string
	FechaPago   time.Time
}
