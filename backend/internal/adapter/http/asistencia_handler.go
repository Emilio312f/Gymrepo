package http

import (
	"encoding/json"
	"errors"
	"net/http"
	"time"

	"gymcontrol/internal/app/asistencia"
	"gymcontrol/internal/domain"
)

type AsistenciaHandler struct {
	svc *asistencia.Service
}

func NewAsistenciaHandler(svc *asistencia.Service) *AsistenciaHandler {
	return &AsistenciaHandler{svc: svc}
}

type validarAccesoReq struct {
	Consulta string `json:"consulta"`
}

func (h *AsistenciaHandler) Validar(w http.ResponseWriter, r *http.Request) {
	gimnasioID := claimsDe(r.Context()).GimnasioID

	var req validarAccesoReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		escribirError(w, http.StatusBadRequest, "JSON inválido")
		return
	}
	if req.Consulta == "" {
		escribirError(w, http.StatusBadRequest, "ingresa el DNI o código del socio")
		return
	}

	acc, err := h.svc.ValidarAcceso(r.Context(), gimnasioID, req.Consulta)
	if errors.Is(err, domain.ErrNoEncontrado) {
		escribirError(w, http.StatusNotFound, "no se encontró un socio con ese DNI o código")
		return
	}
	if err != nil {
		escribirError(w, http.StatusInternalServerError, "no se pudo validar el acceso")
		return
	}

	escribirJSON(w, http.StatusOK, map[string]any{
		"permitido": acc.Permitido,
		"motivo":    acc.Motivo,
		"socio": map[string]any{
			"id":        acc.Socio.ID,
			"nombres":   acc.Socio.Nombres,
			"apellidos": acc.Socio.Apellidos,
			"documento": acc.Socio.Documento,
			"codigo":    acc.Socio.Codigo,
		},
		"membresia": map[string]any{
			"tiene":          acc.Estado.TieneMembresia,
			"plan_nombre":    acc.Estado.PlanNombre,
			"fecha_fin":      acc.Estado.FechaFin,
			"dias_restantes": acc.Estado.DiasRestantes,
		},
	})
}

type asistenciaResp struct {
	FechaHora time.Time `json:"fecha_hora"`
	Nombres   string    `json:"nombres"`
	Apellidos string    `json:"apellidos"`
	Documento string    `json:"documento"`
	Codigo    string    `json:"codigo"`
}

func (h *AsistenciaHandler) ListarDelDia(w http.ResponseWriter, r *http.Request) {
	gimnasioID := claimsDe(r.Context()).GimnasioID

	lista, err := h.svc.ListarDelDia(r.Context(), gimnasioID)
	if err != nil {
		escribirError(w, http.StatusInternalServerError, "no se pudo obtener la asistencia")
		return
	}
	resp := make([]asistenciaResp, 0, len(lista))
	for _, a := range lista {
		resp = append(resp, asistenciaResp{
			FechaHora: a.FechaHora,
			Nombres:   a.Nombres,
			Apellidos: a.Apellidos,
			Documento: a.Documento,
			Codigo:    a.Codigo,
		})
	}
	escribirJSON(w, http.StatusOK, map[string]any{"asistencias": resp})
}
