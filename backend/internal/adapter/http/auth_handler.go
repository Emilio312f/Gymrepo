package http

import (
	"encoding/json"
	"errors"
	"net/http"

	"gymcontrol/internal/app/auth"
	"gymcontrol/internal/domain"
)

type AuthHandler struct {
	svc *auth.Service
}

func NewAuthHandler(svc *auth.Service) *AuthHandler {
	return &AuthHandler{svc: svc}
}

type registroReq struct {
	GimnasioNombre string `json:"gimnasio_nombre"`
	Slug           string `json:"slug"`
	AdminNombre    string `json:"admin_nombre"`
	AdminEmail     string `json:"admin_email"`
	AdminPassword  string `json:"admin_password"`
}

func (h *AuthHandler) Registrar(w http.ResponseWriter, r *http.Request) {
	var req registroReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		escribirError(w, http.StatusBadRequest, "JSON inválido")
		return
	}
	if req.GimnasioNombre == "" || req.Slug == "" || req.AdminEmail == "" || len(req.AdminPassword) < 6 {
		escribirError(w, http.StatusBadRequest, "faltan campos o la contraseña es muy corta (mínimo 6)")
		return
	}

	g, err := h.svc.RegistrarGimnasio(r.Context(), auth.EntradaRegistro{
		GimnasioNombre: req.GimnasioNombre,
		Slug:           req.Slug,
		AdminNombre:    req.AdminNombre,
		AdminEmail:     req.AdminEmail,
		AdminPassword:  req.AdminPassword,
	})
	switch {
	case errors.Is(err, domain.ErrSlugEnUso):
		escribirError(w, http.StatusConflict, "el slug ya está en uso")
		return
	case errors.Is(err, domain.ErrEmailEnUso):
		escribirError(w, http.StatusConflict, "el email ya está registrado")
		return
	case err != nil:
		escribirError(w, http.StatusInternalServerError, "no se pudo registrar el gimnasio")
		return
	}

	escribirJSON(w, http.StatusCreated, map[string]any{
		"id":   g.ID,
		"slug": g.Slug,
	})
}

type loginReq struct {
	Slug     string `json:"slug"`
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req loginReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		escribirError(w, http.StatusBadRequest, "JSON inválido")
		return
	}

	token, u, err := h.svc.Login(r.Context(), req.Slug, req.Email, req.Password)
	if err != nil {
		if errors.Is(err, domain.ErrCredencialesInvalidas) {
			escribirError(w, http.StatusUnauthorized, "credenciales inválidas")
			return
		}
		escribirError(w, http.StatusInternalServerError, "error al iniciar sesión")
		return
	}

	escribirJSON(w, http.StatusOK, map[string]any{
		"token": token,
		"usuario": map[string]any{
			"id":     u.ID,
			"nombre": u.Nombre,
			"email":  u.Email,
			"rol":    u.Rol,
		},
	})
}

// Me devuelve los datos del usuario autenticado (lee los claims del token).
func (h *AuthHandler) Me(w http.ResponseWriter, r *http.Request) {
	claims := claimsDe(r.Context())
	escribirJSON(w, http.StatusOK, map[string]any{
		"usuario_id":  claims.UsuarioID,
		"gimnasio_id": claims.GimnasioID,
		"rol":         claims.Rol,
	})
}
