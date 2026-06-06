package http

import (
	"context"
	"net/http"
	"strings"

	"gymcontrol/internal/platform/security"
)

type claveCtx string

const claveClaims claveCtx = "claims"

// Autenticar valida el token Bearer y guarda los claims en el contexto.
// A partir de aquí, el tenant (GimnasioID) y el rol vienen del token firmado.
func Autenticar(jwt *security.JWT) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			encabezado := r.Header.Get("Authorization")
			partes := strings.SplitN(encabezado, " ", 2)
			if len(partes) != 2 || !strings.EqualFold(partes[0], "Bearer") {
				escribirError(w, http.StatusUnauthorized, "falta el token de autenticación")
				return
			}

			claims, err := jwt.Verificar(partes[1])
			if err != nil {
				escribirError(w, http.StatusUnauthorized, "token inválido o expirado")
				return
			}

			ctx := context.WithValue(r.Context(), claveClaims, claims)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// RequiereRol restringe el acceso a los roles indicados (RBAC).
// La autorización se verifica SIEMPRE en el backend, no se confía en el frontend.
func RequiereRol(roles ...string) func(http.Handler) http.Handler {
	permitidos := make(map[string]bool, len(roles))
	for _, r := range roles {
		permitidos[r] = true
	}
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			claims := claimsDe(r.Context())
			if claims == nil || !permitidos[claims.Rol] {
				escribirError(w, http.StatusForbidden, "no tienes permiso para esta acción")
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}

func claimsDe(ctx context.Context) *security.Claims {
	c, _ := ctx.Value(claveClaims).(*security.Claims)
	return c
}
