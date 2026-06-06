package http

import (
	"net/http"

	"gymcontrol/internal/app/stats"
)

type StatsHandler struct {
	svc *stats.Service
}

func NewStatsHandler(svc *stats.Service) *StatsHandler {
	return &StatsHandler{svc: svc}
}

func (h *StatsHandler) Dashboard(w http.ResponseWriter, r *http.Request) {
	gimnasioID := claimsDe(r.Context()).GimnasioID

	s, err := h.svc.Dashboard(r.Context(), gimnasioID)
	if err != nil {
		escribirError(w, http.StatusInternalServerError, "no se pudieron obtener las estadísticas")
		return
	}
	escribirJSON(w, http.StatusOK, map[string]any{
		"socios_activos": s.SociosActivos,
		"socios_total":   s.SociosTotal,
		"ingresos_mes":   s.IngresosMes,
		"vencen_semana":  s.VencenSemana,
		"vencidas":       s.Vencidas,
	})
}
