package http

import (
	"encoding/json"
	"errors"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"

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
	ID              string    `json:"id"`
	Codigo          string    `json:"codigo"`
	Nombres         string    `json:"nombres"`
	Apellidos       string    `json:"apellidos"`
	Documento       string    `json:"documento"`
	Telefono        string    `json:"telefono"`
	Email           string    `json:"email"`
	Sexo            string    `json:"sexo"`
	Direccion       string    `json:"direccion"`
	FechaNacimiento string    `json:"fecha_nacimiento"`
	Activo          bool      `json:"activo"`
	TieneAcceso     bool      `json:"tiene_acceso"`
	CreatedAt       time.Time `json:"created_at"`
}

func aSocioResp(s domain.Socio) socioResp {
	return socioResp{
		ID:              s.ID,
		Codigo:          s.Codigo,
		Nombres:         s.Nombres,
		Apellidos:       s.Apellidos,
		Documento:       s.Documento,
		Telefono:        s.Telefono,
		Email:           s.Email,
		Sexo:            s.Sexo,
		Direccion:       s.Direccion,
		FechaNacimiento: s.FechaNacimiento,
		Activo:          s.Activo,
		TieneAcceso:     s.UsuarioID != "",
		CreatedAt:       s.CreatedAt,
	}
}

type crearSocioReq struct {
	Nombres         string `json:"nombres"`
	Apellidos       string `json:"apellidos"`
	Documento       string `json:"documento"`
	Telefono        string `json:"telefono"`
	Email           string `json:"email"`
	Sexo            string `json:"sexo"`
	Direccion       string `json:"direccion"`
	FechaNacimiento string `json:"fecha_nacimiento"`
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
		Nombres:         req.Nombres,
		Apellidos:       req.Apellidos,
		Documento:       req.Documento,
		Telefono:        req.Telefono,
		Email:           req.Email,
		Sexo:            req.Sexo,
		Direccion:       req.Direccion,
		FechaNacimiento: req.FechaNacimiento,
	})
	switch {
	case errors.Is(err, domain.ErrDatosInvalidos):
		escribirError(w, http.StatusBadRequest, "datos inválidos: revisa nombres, apellidos y documento")
		return
	case errors.Is(err, domain.ErrSocioDuplicado):
		escribirError(w, http.StatusConflict, "ya existe un socio con ese código o documento")
		return
	case err != nil:
		escribirError(w, http.StatusInternalServerError, "no se pudo crear el socio")
		return
	}

	escribirJSON(w, http.StatusCreated, aSocioResp(socio))
}

func (h *SociosHandler) Obtener(w http.ResponseWriter, r *http.Request) {
	gimnasioID := claimsDe(r.Context()).GimnasioID
	id := chi.URLParam(r, "id")

	socio, err := h.svc.Obtener(r.Context(), gimnasioID, id)
	switch {
	case errors.Is(err, domain.ErrNoEncontrado):
		escribirError(w, http.StatusNotFound, "socio no encontrado")
		return
	case err != nil:
		escribirError(w, http.StatusInternalServerError, "no se pudo obtener el socio")
		return
	}
	escribirJSON(w, http.StatusOK, aSocioResp(socio))
}

func (h *SociosHandler) Actualizar(w http.ResponseWriter, r *http.Request) {
	gimnasioID := claimsDe(r.Context()).GimnasioID
	id := chi.URLParam(r, "id")

	var req crearSocioReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		escribirError(w, http.StatusBadRequest, "JSON inválido")
		return
	}
	if req.Nombres == "" || req.Apellidos == "" || req.Documento == "" {
		escribirError(w, http.StatusBadRequest, "nombres, apellidos y documento son obligatorios")
		return
	}

	socio, err := h.svc.Actualizar(r.Context(), gimnasioID, id, socios.EntradaSocio{
		Nombres:         req.Nombres,
		Apellidos:       req.Apellidos,
		Documento:       req.Documento,
		Telefono:        req.Telefono,
		Email:           req.Email,
		Sexo:            req.Sexo,
		Direccion:       req.Direccion,
		FechaNacimiento: req.FechaNacimiento,
	})
	switch {
	case errors.Is(err, domain.ErrDatosInvalidos):
		escribirError(w, http.StatusBadRequest, "datos inválidos: revisa nombres, apellidos y documento")
		return
	case errors.Is(err, domain.ErrNoEncontrado):
		escribirError(w, http.StatusNotFound, "socio no encontrado")
		return
	case errors.Is(err, domain.ErrSocioDuplicado):
		escribirError(w, http.StatusConflict, "ya existe un socio con ese documento")
		return
	case err != nil:
		escribirError(w, http.StatusInternalServerError, "no se pudo actualizar el socio")
		return
	}
	escribirJSON(w, http.StatusOK, aSocioResp(socio))
}

type crearAccesoReq struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (h *SociosHandler) CrearAcceso(w http.ResponseWriter, r *http.Request) {
	gimnasioID := claimsDe(r.Context()).GimnasioID
	id := chi.URLParam(r, "id")

	var req crearAccesoReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		escribirError(w, http.StatusBadRequest, "JSON inválido")
		return
	}

	err := h.svc.CrearAcceso(r.Context(), gimnasioID, id, socios.EntradaAcceso{
		Email:    req.Email,
		Password: req.Password,
	})
	switch {
	case errors.Is(err, domain.ErrDatosInvalidos):
		escribirError(w, http.StatusBadRequest, "correo inválido o contraseña muy corta (mínimo 6)")
		return
	case errors.Is(err, domain.ErrNoEncontrado):
		escribirError(w, http.StatusNotFound, "socio no encontrado")
		return
	case errors.Is(err, domain.ErrAccesoYaExiste):
		escribirError(w, http.StatusConflict, "este socio ya tiene acceso a la app")
		return
	case errors.Is(err, domain.ErrEmailEnUso):
		escribirError(w, http.StatusConflict, "ese correo ya está registrado en el gimnasio")
		return
	case err != nil:
		escribirError(w, http.StatusInternalServerError, "no se pudo crear el acceso")
		return
	}
	escribirJSON(w, http.StatusCreated, map[string]bool{"ok": true})
}

type estadoSocioReq struct {
	Activo bool `json:"activo"`
}

func (h *SociosHandler) CambiarEstado(w http.ResponseWriter, r *http.Request) {
	gimnasioID := claimsDe(r.Context()).GimnasioID
	id := chi.URLParam(r, "id")

	var req estadoSocioReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		escribirError(w, http.StatusBadRequest, "JSON inválido")
		return
	}

	err := h.svc.CambiarEstado(r.Context(), gimnasioID, id, req.Activo)
	switch {
	case errors.Is(err, domain.ErrNoEncontrado):
		escribirError(w, http.StatusNotFound, "socio no encontrado")
		return
	case err != nil:
		escribirError(w, http.StatusInternalServerError, "no se pudo cambiar el estado")
		return
	}
	escribirJSON(w, http.StatusOK, map[string]bool{"activo": req.Activo})
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
