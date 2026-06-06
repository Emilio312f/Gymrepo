package http

import (
	"encoding/json"
	"errors"
	"net/http"

	"gymcontrol/internal/app/personal"
	"gymcontrol/internal/domain"
)

type PersonalHandler struct {
	svc *personal.Service
}

func NewPersonalHandler(svc *personal.Service) *PersonalHandler {
	return &PersonalHandler{svc: svc}
}

type usuarioResp struct {
	ID     string `json:"id"`
	Nombre string `json:"nombre"`
	Email  string `json:"email"`
	Rol    string `json:"rol"`
	Activo bool   `json:"activo"`
}

func aUsuarioResp(u domain.Usuario) usuarioResp {
	return usuarioResp{
		ID:     u.ID,
		Nombre: u.Nombre,
		Email:  u.Email,
		Rol:    string(u.Rol),
		Activo: u.Activo,
	}
}

func (h *PersonalHandler) Listar(w http.ResponseWriter, r *http.Request) {
	gimnasioID := claimsDe(r.Context()).GimnasioID
	lista, err := h.svc.Listar(r.Context(), gimnasioID)
	if err != nil {
		escribirError(w, http.StatusInternalServerError, "no se pudo listar el personal")
		return
	}
	resp := make([]usuarioResp, 0, len(lista))
	for _, u := range lista {
		resp = append(resp, aUsuarioResp(u))
	}
	escribirJSON(w, http.StatusOK, map[string]any{"personal": resp})
}

type crearPersonalReq struct {
	Nombre   string `json:"nombre"`
	Email    string `json:"email"`
	Password string `json:"password"`
	Rol      string `json:"rol"`
}

func (h *PersonalHandler) Crear(w http.ResponseWriter, r *http.Request) {
	gimnasioID := claimsDe(r.Context()).GimnasioID

	var req crearPersonalReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		escribirError(w, http.StatusBadRequest, "JSON inválido")
		return
	}
	if req.Nombre == "" || req.Email == "" || len(req.Password) < 6 {
		escribirError(w, http.StatusBadRequest, "nombre, email y contraseña (mínimo 6) son obligatorios")
		return
	}

	u, err := h.svc.Crear(r.Context(), gimnasioID, personal.Entrada{
		Nombre:   req.Nombre,
		Email:    req.Email,
		Password: req.Password,
		Rol:      req.Rol,
	})
	switch {
	case errors.Is(err, domain.ErrRolInvalido):
		escribirError(w, http.StatusBadRequest, "el rol debe ser admin o recepcion")
		return
	case errors.Is(err, domain.ErrEmailEnUso):
		escribirError(w, http.StatusConflict, "ese email ya está registrado")
		return
	case err != nil:
		escribirError(w, http.StatusInternalServerError, "no se pudo crear el usuario")
		return
	}
	escribirJSON(w, http.StatusCreated, aUsuarioResp(u))
}
