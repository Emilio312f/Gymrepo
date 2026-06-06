package http

import (
	"errors"
	"net/http"

	"github.com/go-chi/chi/v5"

	"gymcontrol/internal/app/documento"
	"gymcontrol/internal/domain"
)

type DocumentoHandler struct {
	svc *documento.Service
}

func NewDocumentoHandler(svc *documento.Service) *DocumentoHandler {
	return &DocumentoHandler{svc: svc}
}

func (h *DocumentoHandler) Consultar(w http.ResponseWriter, r *http.Request) {
	dni := chi.URLParam(r, "dni")

	persona, err := h.svc.Consultar(r.Context(), dni)
	switch {
	case errors.Is(err, domain.ErrDNIInvalido):
		escribirError(w, http.StatusBadRequest, "el DNI debe tener 8 dígitos")
		return
	case errors.Is(err, domain.ErrNoEncontrado):
		escribirError(w, http.StatusNotFound, "no se encontraron datos para ese DNI")
		return
	case err != nil:
		escribirError(w, http.StatusBadGateway, "no se pudo consultar el documento")
		return
	}

	escribirJSON(w, http.StatusOK, map[string]any{
		"nombres":          persona.Nombres,
		"apellido_paterno": persona.ApellidoPaterno,
		"apellido_materno": persona.ApellidoMaterno,
		"nombre_completo":  persona.NombreCompleto,
	})
}
