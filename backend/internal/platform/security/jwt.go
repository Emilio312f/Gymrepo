package security

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Claims viaja dentro del token. Incluye el GimnasioID (tenant): así el tenant
// se deriva SIEMPRE del token firmado, nunca de un parámetro que mande el cliente.
type Claims struct {
	UsuarioID  string `json:"uid"`
	GimnasioID string `json:"gid"`
	Rol        string `json:"rol"`
	jwt.RegisteredClaims
}

type JWT struct {
	secret []byte
	ttl    time.Duration
}

func NewJWT(secret string, ttl time.Duration) *JWT {
	return &JWT{secret: []byte(secret), ttl: ttl}
}

func (j *JWT) Generar(usuarioID, gimnasioID, rol string) (string, error) {
	ahora := time.Now()
	claims := Claims{
		UsuarioID:  usuarioID,
		GimnasioID: gimnasioID,
		Rol:        rol,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   usuarioID,
			IssuedAt:  jwt.NewNumericDate(ahora),
			ExpiresAt: jwt.NewNumericDate(ahora.Add(j.ttl)),
		},
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(j.secret)
}

func (j *JWT) Verificar(tokenStr string) (*Claims, error) {
	claims := &Claims{}
	_, err := jwt.ParseWithClaims(tokenStr, claims, func(t *jwt.Token) (any, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("método de firma inesperado")
		}
		return j.secret, nil
	})
	if err != nil {
		return nil, err
	}
	return claims, nil
}
