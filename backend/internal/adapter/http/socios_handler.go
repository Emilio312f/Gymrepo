package http

import (
	"encoding/json"
	"errors"
	"net/http"
	"time"

	"gymcontrol/internal/app/socios"
	"gymcontrol/internal/domain"
)

type SociosHandler struct {
	svc *socios.Service
}

func NewSociosHandler(svc *socios.Service) *SociosHandler {
	return &SociosHandler{svc: svc}
}

type socioResp struct {
	ID        string    `json:"id"`
	Codigo    string    `json:"codigo"`
	Nombres   string    `json:"nombres"`
	Apellidos string    `json:"apellidos"`
	Documento string    `json:"documento"`
	Telefono  string    `json:"telefono"`
	Email     string    `json:"email"`
	Activo    bool      `json:"activo"`
	CreatedAt time.Time `json:"created_at"`
}

func aSocioResp(s domain.Socio) socioResp {
	return socioResp{
		ID:        s.ID,
		Codigo:    s.Codigo,
		Nombres:   s.Nombres,
		Apellidos: s.Apellidos,
		Documento: s.Documento,
		Telefono:  s.Telefono,
		Email:     s.Email,
		Activo:    s.Activo,
		CreatedAt: s.CreatedAt,
	}
}

type crearSocioReq struct {
	Nombres   string `json:"nombres"`
	Apellidos string `json:"apellidos"`
	Documento string `json:"documento"`
	Telefono  string `json:"telefono"`
	Email     string `json:"email"`
}

func (h *SociosHandler) Crear(w http.ResponseWriter, r *http.Request) {
	gimnasioID := claimsDe(r.Context()).GimnasioID

	var req crearSocioReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		escribirError(w, http.StatusBadRequest, "JSON inválido")
		return
	}
	if req.Nombres == "" || req.Apellidos == "" || req.Documento == "" {
		escribirError(w, http.StatusBadRequest, "nombres, apellidos y documento son obligatorios")
		return
	}

	socio, err := h.svc.Crear(r.Context(), gimnasioID, socios.EntradaSocio{
		Nombres:   req.Nombres,
		Apellidos: req.Apellidos,
		Documento: req.Documento,
		Telefono:  req.Telefono,
		Email:     req.Email,
	})
	switch {
	case errors.Is(err, domain.ErrSocioDuplicado):
		escribirError(w, http.StatusConflict, "ya existe un socio con ese código o documento")
		return
	case err != nil:
		escribirError(w, http.StatusInternalServerError, "no se pudo crear el socio")
		return
	}

	escribirJSON(w, http.StatusCreated, aSocioResp(socio))
}

func (h *SociosHandler) Listar(w http.ResponseWriter, r *http.Request) {
	gimnasioID := claimsDe(r.Context()).GimnasioID

	lista, err := h.svc.Listar(r.Context(), gimnasioID)
	if err != nil {
		escribirError(w, http.StatusInternalServerError, "no se pudieron listar los socios")
		return
	}

	resp := make([]socioResp, 0, len(lista))
	for _, s := range lista {
		resp = append(resp, aSocioResp(s))
	}
	escribirJSON(w, http.StatusOK, map[string]any{"socios": resp})
}
