package dni

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"time"

	"gymcontrol/internal/app/documento"
	"gymcontrol/internal/domain"
)

type Cliente struct {
	http    *http.Client
	baseURL string
	token   string
}

func NewCliente(baseURL, token string) *Cliente {
	return &Cliente{
		http:    &http.Client{Timeout: 12 * time.Second},
		baseURL: baseURL,
		token:   token,
	}
}

var _ documento.Consultor = (*Cliente)(nil)

type respuesta struct {
	Nombres         string `json:"nombres"`
	ApellidoPaterno string `json:"apellidoPaterno"`
	ApellidoMaterno string `json:"apellidoMaterno"`
	Nombre          string `json:"nombre"`
}

func (c *Cliente) PorDNI(ctx context.Context, numero string) (documento.Persona, error) {
	destino := fmt.Sprintf("%s?numero=%s", c.baseURL, url.QueryEscape(numero))
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, destino, nil)
	if err != nil {
		return documento.Persona{}, err
	}
	req.Header.Set("Accept", "application/json")
	if c.token != "" {
		req.Header.Set("Authorization", "Bearer "+c.token)
	}

	resp, err := c.http.Do(req)
	if err != nil {
		return documento.Persona{}, err
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound || resp.StatusCode == http.StatusUnprocessableEntity {
		return documento.Persona{}, domain.ErrNoEncontrado
	}
	if resp.StatusCode != http.StatusOK {
		return documento.Persona{}, fmt.Errorf("api dni respondió %d", resp.StatusCode)
	}

	var r respuesta
	if err := json.NewDecoder(resp.Body).Decode(&r); err != nil {
		return documento.Persona{}, err
	}

	return documento.Persona{
		Nombres:         r.Nombres,
		ApellidoPaterno: r.ApellidoPaterno,
		ApellidoMaterno: r.ApellidoMaterno,
		NombreCompleto:  r.Nombre,
	}, nil
}
