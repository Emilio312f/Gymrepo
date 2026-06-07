package http

import (
	"encoding/json"
	"errors"
	"net/http"
	"time"

	"gymcontrol/internal/app/asistencia"
	"gymcontrol/internal/app/membresias"
	"gymcontrol/internal/app/pagos"
	"gymcontrol/internal/app/socios"
	"gymcontrol/internal/domain"
)

// MiHandler agrupa los endpoints de auto-servicio del socio: cada socio sólo ve
// SUS propios datos. El socio se resuelve desde el token (usuario_id), nunca del cliente.
type MiHandler struct {
	socios     *socios.Service
	membresia  *membresias.Service
	asistencia *asistencia.Service
	pagos      *pagos.Service
}

func NewMiHandler(s *socios.Service, m *membresias.Service, a *asistencia.Service, p *pagos.Service) *MiHandler {
	return &MiHandler{socios: s, membresia: m, asistencia: a, pagos: p}
}

func (h *MiHandler) socioActual(w http.ResponseWriter, r *http.Request) (domain.Socio, bool) {
	claims := claimsDe(r.Context())
	socio, err := h.socios.ObtenerPorUsuario(r.Context(), claims.GimnasioID, claims.UsuarioID)
	if err != nil {
		escribirError(w, http.StatusNotFound, "tu cuenta no está vinculada a un socio")
		return domain.Socio{}, false
	}
	return socio, true
}

func (h *MiHandler) Perfil(w http.ResponseWriter, r *http.Request) {
	socio, ok := h.socioActual(w, r)
	if !ok {
		return
	}
	escribirJSON(w, http.StatusOK, aSocioResp(socio))
}

func (h *MiHandler) Membresia(w http.ResponseWriter, r *http.Request) {
	socio, ok := h.socioActual(w, r)
	if !ok {
		return
	}
	e, err := h.membresia.EstadoActual(r.Context(), socio.GimnasioID, socio.ID)
	if err != nil {
		escribirError(w, http.StatusInternalServerError, "no se pudo obtener tu membresía")
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

func (h *MiHandler) Pendiente(w http.ResponseWriter, r *http.Request) {
	socio, ok := h.socioActual(w, r)
	if !ok {
		return
	}
	m, err := h.membresia.Pendiente(r.Context(), socio.GimnasioID, socio.ID)
	if errors.Is(err, domain.ErrNoEncontrado) {
		escribirJSON(w, http.StatusOK, pendienteResp{TienePendiente: false})
		return
	}
	if err != nil {
		escribirError(w, http.StatusInternalServerError, "no se pudo obtener tu plan pendiente")
		return
	}
	escribirJSON(w, http.StatusOK, aPendienteResp(m))
}

type pagarReq struct {
	Operacion string `json:"operacion"`
}

func (h *MiHandler) Pagar(w http.ResponseWriter, r *http.Request) {
	socio, ok := h.socioActual(w, r)
	if !ok {
		return
	}
	var req pagarReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		escribirError(w, http.StatusBadRequest, "JSON inválido")
		return
	}

	m, err := h.membresia.EnviarConstancia(r.Context(), socio.GimnasioID, socio.ID, req.Operacion)
	switch {
	case errors.Is(err, domain.ErrDatosInvalidos):
		escribirError(w, http.StatusBadRequest, "ingresa el número de operación de tu Yape")
		return
	case errors.Is(err, domain.ErrNoEncontrado):
		escribirError(w, http.StatusNotFound, "no tienes un plan pendiente de pago")
		return
	case err != nil:
		escribirError(w, http.StatusInternalServerError, "no se pudo registrar tu pago")
		return
	}
	escribirJSON(w, http.StatusOK, map[string]string{"estado": m.Estado})
}

type miAsistenciaResp struct {
	FechaHora time.Time `json:"fecha_hora"`
}

func (h *MiHandler) Asistencias(w http.ResponseWriter, r *http.Request) {
	socio, ok := h.socioActual(w, r)
	if !ok {
		return
	}
	lista, err := h.asistencia.ListarPorSocio(r.Context(), socio.GimnasioID, socio.ID)
	if err != nil {
		escribirError(w, http.StatusInternalServerError, "no se pudieron obtener tus asistencias")
		return
	}
	resp := make([]miAsistenciaResp, 0, len(lista))
	for _, a := range lista {
		resp = append(resp, miAsistenciaResp{FechaHora: a.FechaHora})
	}
	escribirJSON(w, http.StatusOK, map[string]any{"asistencias": resp})
}

type miPagoResp struct {
	PlanNombre string    `json:"plan_nombre"`
	Monto      float64   `json:"monto"`
	Metodo     string    `json:"metodo"`
	FechaPago  time.Time `json:"fecha_pago"`
}

func (h *MiHandler) Pagos(w http.ResponseWriter, r *http.Request) {
	socio, ok := h.socioActual(w, r)
	if !ok {
		return
	}
	lista, err := h.pagos.ListarPorSocio(r.Context(), socio.GimnasioID, socio.ID)
	if err != nil {
		escribirError(w, http.StatusInternalServerError, "no se pudieron obtener tus pagos")
		return
	}
	resp := make([]miPagoResp, 0, len(lista))
	for _, p := range lista {
		resp = append(resp, miPagoResp{
			PlanNombre: p.PlanNombre,
			Monto:      p.Monto,
			Metodo:     p.Metodo,
			FechaPago:  p.FechaPago,
		})
	}
	escribirJSON(w, http.StatusOK, map[string]any{"pagos": resp})
}
