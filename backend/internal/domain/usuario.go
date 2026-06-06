package domain

// Rol define qué puede hacer un usuario dentro de su gimnasio.
type Rol string

const (
	RolAdmin     Rol = "admin"     // dueño: reportes, planes, personal
	RolRecepcion Rol = "recepcion" // alta de socios, cobros, validar acceso
	RolSocio     Rol = "socio"     // consulta su propia membresía
)

// Valido indica si el rol es uno de los reconocidos.
func (r Rol) Valido() bool {
	switch r {
	case RolAdmin, RolRecepcion, RolSocio:
		return true
	default:
		return false
	}
}

// Usuario es quien puede iniciar sesión en el sistema.
// Pertenece siempre a un gimnasio (tenant): GimnasioID nunca va vacío.
type Usuario struct {
	ID           string
	GimnasioID   string
	Email        string
	PasswordHash string
	Rol          Rol
	Nombre       string
	Activo       bool
}
