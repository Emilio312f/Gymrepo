package http

import (
	"encoding/json"
	"errors"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"

	"gymcontrol/internal/app/membresias"
	"gymcontrol/internal/domain"
)

type MembresiasHandler struct {
	svc *membresias.Service
}

func NewMembresiasHandler(svc *membresias.Service) *MembresiasHandler {
	return &MembresiasHandler{svc: svc}
}

type registrarPagoReq struct {
	PlanID string `json:"plan_id"`
	Metodo string `json:"metodo"`
}

func (h *MembresiasHandler) RegistrarPago(w http.ResponseWriter, r *http.Request) {
	claims := claimsDe(r.Context())
	socioID := chi.URLParam(r, "id")

	var req registrarPagoReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		escribirError(w, http.StatusBadRequest, "JSON inválido")
		return
	}
	if req.PlanID == "" {
		escribirError(w, http.StatusBadRequest, "el plan es obligatorio")
		return
	}

	m, err := h.svc.RegistrarPago(r.Context(), claims.GimnasioID, socioID, req.PlanID, req.Metodo, claims.UsuarioID)
	switch {
	case errors.Is(err, domain.ErrNoEncontrado):
		escribirError(w, http.StatusNotFound, "plan no encontrado o inactivo")
		return
	case err != nil:
		escribirError(w, http.StatusInternalServerError, "no se pudo registrar el pago")
		return
	}

	escribirJSON(w, http.StatusCreated, map[string]any{
		"id":            m.ID,
		"fecha_inicio":  m.FechaInicio,
		"fecha_fin":     m.FechaFin,
		"precio_pagado": m.PrecioPagado,
	})
}

func (h *MembresiasHandler) EstadoActual(w http.ResponseWriter, r *http.Request) {
	claims := claimsDe(r.Context())
	socioID := chi.URLParam(r, "id")

	e, err := h.svc.EstadoActual(r.Context(), claims.GimnasioID, socioID)
	if err != nil {
		escribirError(w, http.StatusInternalServerError, "no se pudo obtener la membresía")
		return
	}
	escribirJSON(w, http.StatusOK, map[string]any{
		"tiene_membresia": e.TieneMembresia,
		"plan_nombre":     e.PlanNombre,
		"fecha_inicio":    e.FechaInicio,
		"fecha_fin":       e.FechaFin,
		"al_dia":          e.AlDia,
		"dias_restantes":  e.DiasRestantes,
	})
}

type membresiaResp struct {
	ID           string    `json:"id"`
	PlanNombre   string    `json:"plan_nombre"`
	FechaInicio  string    `json:"fecha_inicio"`
	FechaFin     string    `json:"fecha_fin"`
	PrecioPagado float64   `json:"precio_pagado"`
	Estado       string    `json:"estado"`
	CreatedAt    time.Time `json:"created_at"`
}

func (h *MembresiasHandler) Historial(w http.ResponseWriter, r *http.Request) {
	claims := claimsDe(r.Context())
	socioID := chi.URLParam(r, "id")

	lista, err := h.svc.Historial(r.Context(), claims.GimnasioID, socioID)
	if err != nil {
		escribirError(w, http.StatusInternalServerError, "no se pudo obtener el historial")
		return
	}
	resp := make([]membresiaResp, 0, len(lista))
	for _, m := range lista {
		resp = append(resp, membresiaResp{
			ID:           m.ID,
			PlanNombre:   m.PlanNombre,
			FechaInicio:  m.FechaInicio,
			FechaFin:     m.FechaFin,
			PrecioPagado: m.PrecioPagado,
			Estado:       m.Estado,
			CreatedAt:    m.CreatedAt,
		})
	}
	escribirJSON(w, http.StatusOK, map[string]any{"membresias": resp})
}
