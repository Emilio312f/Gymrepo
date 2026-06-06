// Package security agrupa hashing de contraseñas y emisión/validación de JWT.
package security

import "golang.org/x/crypto/bcrypt"

// BcryptHasher implementa el hashing de contraseñas con bcrypt.
// Nunca se almacenan contraseñas en texto plano.
type BcryptHasher struct {
	cost int
}

func NewBcryptHasher() BcryptHasher {
	return BcryptHasher{cost: bcrypt.DefaultCost}
}

func (h BcryptHasher) Hash(plano string) (string, error) {
	b, err := bcrypt.GenerateFromPassword([]byte(plano), h.cost)
	return string(b), err
}

// Comparar devuelve nil si la contraseña coincide, o un error si no.
func (h BcryptHasher) Comparar(hash, plano string) error {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(plano))
}
