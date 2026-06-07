package http

import (
	"net/http"
	"time"

	"gymcontrol/internal/app/pagos"
)

type PagosHandler struct {
	svc *pagos.Service
}

func NewPagosHandler(svc *pagos.Service) *PagosHandler {
	return &PagosHandler{svc: svc}
}

type pagoResp struct {
	ID          string    `json:"id"`
	SocioNombre string    `json:"socio_nombre"`
	Documento   string    `json:"documento"`
	PlanNombre  string    `json:"plan_nombre"`
	Monto       float64   `json:"monto"`
	Metodo      string    `json:"metodo"`
	FechaPago   time.Time `json:"fecha_pago"`
}

func (h *PagosHandler) Listar(w http.ResponseWriter, r *http.Request) {
	gimnasioID := claimsDe(r.Context()).GimnasioID
	desde := r.URL.Query().Get("desde")
	hasta := r.URL.Query().Get("hasta")

	lista, total, err := h.svc.Listar(r.Context(), gimnasioID, desde, hasta)
	if err != nil {
		escribirError(w, http.StatusInternalServerError, "no se pudieron listar los pagos")
		return
	}

	resp := make([]pagoResp, 0, len(lista))
	for _, p := range lista {
		resp = append(resp, pagoResp{
			ID:          p.ID,
			SocioNombre: p.SocioNombre,
			Documento:   p.Documento,
			PlanNombre:  p.PlanNombre,
			Monto:       p.Monto,
			Metodo:      p.Metodo,
			FechaPago:   p.FechaPago,
		})
	}
	escribirJSON(w, http.StatusOK, map[string]any{
		"pagos": resp,
		"total": total,
	})
}
