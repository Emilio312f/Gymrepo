package domain

// Gimnasio es el tenant raíz: de él cuelgan usuarios, socios, planes, etc.
type Gimnasio struct {
	ID     string
	Nombre string
	Slug   string // identificador legible para el login y la URL
}
