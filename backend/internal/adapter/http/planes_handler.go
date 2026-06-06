package http

import (
	"encoding/json"
	"net/http"

	"gymcontrol/internal/app/planes"
	"gymcontrol/internal/domain"
)

type PlanesHandler struct {
	svc *planes.Service
}

func NewPlanesHandler(svc *planes.Service) *PlanesHandler {
	return &PlanesHandler{svc: svc}
}

type planResp struct {
	ID           string  `json:"id"`
	Nombre       string  `json:"nombre"`
	Descripcion  string  `json:"descripcion"`
	Precio       float64 `json:"precio"`
	DuracionDias int     `json:"duracion_dias"`
	Activo       bool    `json:"activo"`
}

func aPlanResp(p domain.Plan) planResp {
	return planResp{
		ID:           p.ID,
		Nombre:       p.Nombre,
		Descripcion:  p.Descripcion,
		Precio:       p.Precio,
		DuracionDias: p.DuracionDias,
		Activo:       p.Activo,
	}
}

func (h *PlanesHandler) Listar(w http.ResponseWriter, r *http.Request) {
	gimnasioID := claimsDe(r.Context()).GimnasioID
	soloActivos := r.URL.Query().Get("activos") == "true"

	lista, err := h.svc.Listar(r.Context(), gimnasioID, soloActivos)
	if err != nil {
		escribirError(w, http.StatusInternalServerError, "no se pudieron listar los planes")
		return
	}
	resp := make([]planResp, 0, len(lista))
	for _, p := range lista {
		resp = append(resp, aPlanResp(p))
	}
	escribirJSON(w, http.StatusOK, map[string]any{"planes": resp})
}

type crearPlanReq struct {
	Nombre       string  `json:"nombre"`
	Descripcion  string  `json:"descripcion"`
	Precio       float64 `json:"precio"`
	DuracionDias int     `json:"duracion_dias"`
}

func (h *PlanesHandler) Crear(w http.ResponseWriter, r *http.Request) {
	gimnasioID := claimsDe(r.Context()).GimnasioID

	var req crearPlanReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		escribirError(w, http.StatusBadRequest, "JSON inválido")
		return
	}
	if req.Nombre == "" || req.Precio <= 0 || req.DuracionDias <= 0 {
		escribirError(w, http.StatusBadRequest, "nombre, precio y duración son obligatorios")
		return
	}

	plan, err := h.svc.Crear(r.Context(), gimnasioID, planes.EntradaPlan{
		Nombre:       req.Nombre,
		Descripcion:  req.Descripcion,
		Precio:       req.Precio,
		DuracionDias: req.DuracionDias,
	})
	if err != nil {
		escribirError(w, http.StatusInternalServerError, "no se pudo crear el plan")
		return
	}
	escribirJSON(w, http.StatusCreated, aPlanResp(plan))
}
