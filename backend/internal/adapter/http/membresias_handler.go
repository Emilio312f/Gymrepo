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

type asignarPlanReq struct {
	PlanID string `json:"plan_id"`
}

func (h *MembresiasHandler) AsignarPlan(w http.ResponseWriter, r *http.Request) {
	claims := claimsDe(r.Context())
	socioID := chi.URLParam(r, "id")

	var req asignarPlanReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		escribirError(w, http.StatusBadRequest, "JSON inválido")
		return
	}
	if req.PlanID == "" {
		escribirError(w, http.StatusBadRequest, "el plan es obligatorio")
		return
	}

	m, err := h.svc.AsignarPlan(r.Context(), claims.GimnasioID, socioID, req.PlanID)
	switch {
	case errors.Is(err, domain.ErrYaTienePendiente):
		escribirError(w, http.StatusConflict, "el socio ya tiene un plan pendiente de pago")
		return
	case errors.Is(err, domain.ErrNoEncontrado):
		escribirError(w, http.StatusNotFound, "plan no encontrado o inactivo")
		return
	case err != nil:
		escribirError(w, http.StatusInternalServerError, "no se pudo asignar el plan")
		return
	}
	escribirJSON(w, http.StatusCreated, map[string]any{
		"membresia_id": m.ID,
		"precio":       m.PrecioPagado,
		"estado":       m.Estado,
	})
}

type pendienteResp struct {
	TienePendiente bool    `json:"tiene_pendiente"`
	MembresiaID    string  `json:"membresia_id"`
	PlanNombre     string  `json:"plan_nombre"`
	Precio         float64 `json:"precio"`
	Estado         string  `json:"estado"`
	Operacion      string  `json:"operacion"`
}

func aPendienteResp(m domain.Membresia) pendienteResp {
	return pendienteResp{
		TienePendiente: true,
		MembresiaID:    m.ID,
		PlanNombre:     m.PlanNombre,
		Precio:         m.PrecioPagado,
		Estado:         m.Estado,
		Operacion:      m.Operacion,
	}
}

func (h *MembresiasHandler) Pendiente(w http.ResponseWriter, r *http.Request) {
	claims := claimsDe(r.Context())
	socioID := chi.URLParam(r, "id")

	m, err := h.svc.Pendiente(r.Context(), claims.GimnasioID, socioID)
	if errors.Is(err, domain.ErrNoEncontrado) {
		escribirJSON(w, http.StatusOK, pendienteResp{TienePendiente: false})
		return
	}
	if err != nil {
		escribirError(w, http.StatusInternalServerError, "no se pudo obtener el plan pendiente")
		return
	}
	escribirJSON(w, http.StatusOK, aPendienteResp(m))
}

type confirmarPagoReq struct {
	Metodo string `json:"metodo"`
}

func (h *MembresiasHandler) Confirmar(w http.ResponseWriter, r *http.Request) {
	claims := claimsDe(r.Context())
	membresiaID := chi.URLParam(r, "mid")

	var req confirmarPagoReq
	_ = json.NewDecoder(r.Body).Decode(&req)

	m, err := h.svc.ConfirmarPago(r.Context(), claims.GimnasioID, membresiaID, req.Metodo, claims.UsuarioID)
	switch {
	case errors.Is(err, domain.ErrNoEncontrado):
		escribirError(w, http.StatusNotFound, "no hay un pago pendiente para confirmar")
		return
	case err != nil:
		escribirError(w, http.StatusInternalServerError, "no se pudo confirmar el pago")
		return
	}
	escribirJSON(w, http.StatusOK, map[string]any{
		"id":        m.ID,
		"fecha_fin": m.FechaFin,
		"estado":    m.Estado,
	})
}

func (h *MembresiasHandler) Rechazar(w http.ResponseWriter, r *http.Request) {
	claims := claimsDe(r.Context())
	membresiaID := chi.URLParam(r, "mid")

	err := h.svc.RechazarPago(r.Context(), claims.GimnasioID, membresiaID)
	switch {
	case errors.Is(err, domain.ErrNoEncontrado):
		escribirError(w, http.StatusNotFound, "no hay un pago en revisión para rechazar")
		return
	case err != nil:
		escribirError(w, http.StatusInternalServerError, "no se pudo rechazar el pago")
		return
	}
	escribirJSON(w, http.StatusOK, map[string]bool{"ok": true})
}

func (h *MembresiasHandler) Cancelar(w http.ResponseWriter, r *http.Request) {
	claims := claimsDe(r.Context())
	membresiaID := chi.URLParam(r, "mid")

	err := h.svc.CancelarPendiente(r.Context(), claims.GimnasioID, membresiaID)
	switch {
	case errors.Is(err, domain.ErrNoEncontrado):
		escribirError(w, http.StatusNotFound, "no hay un plan pendiente para cancelar")
		return
	case err != nil:
		escribirError(w, http.StatusInternalServerError, "no se pudo cancelar el plan")
		return
	}
	escribirJSON(w, http.StatusOK, map[string]bool{"ok": true})
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
