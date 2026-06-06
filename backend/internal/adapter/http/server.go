package http

import (
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"

	"gymcontrol/internal/domain"
	"gymcontrol/internal/platform/security"
)

// NuevoRouter arma todas las rutas de la API.
func NuevoRouter(authH *AuthHandler, sociosH *SociosHandler, docH *DocumentoHandler, jwt *security.JWT) http.Handler {
	r := chi.NewRouter()

	r.Use(middleware.RequestID)
	r.Use(middleware.RealIP)
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)
	r.Use(middleware.Timeout(15 * time.Second))

	// CORS: necesario porque el cliente Flutter web llamará desde otro origen.
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"*"}, // en producción: lista concreta de orígenes
		AllowedMethods:   []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Authorization", "Content-Type"},
		AllowCredentials: false,
		MaxAge:           300,
	}))

	r.Get("/health", func(w http.ResponseWriter, _ *http.Request) {
		escribirJSON(w, http.StatusOK, map[string]string{"status": "ok"})
	})

	r.Route("/api/v1", func(r chi.Router) {
		// Rutas públicas
		r.Post("/signup", authH.Registrar) // onboarding de un gimnasio nuevo
		r.Post("/login", authH.Login)

		// Rutas protegidas (requieren token válido)
		r.Group(func(r chi.Router) {
			r.Use(Autenticar(jwt))

			r.Get("/me", authH.Me)

			r.With(RequiereRol(string(domain.RolAdmin))).
				Get("/admin/ping", func(w http.ResponseWriter, _ *http.Request) {
					escribirJSON(w, http.StatusOK, map[string]string{"msg": "hola admin"})
				})

			r.With(RequiereRol(string(domain.RolAdmin), string(domain.RolRecepcion))).
				Route("/socios", func(r chi.Router) {
					r.Get("/", sociosH.Listar)
					r.Post("/", sociosH.Crear)
				})

			r.With(RequiereRol(string(domain.RolAdmin), string(domain.RolRecepcion))).
				Get("/documento/{dni}", docH.Consultar)
		})
	})

	return r
}
