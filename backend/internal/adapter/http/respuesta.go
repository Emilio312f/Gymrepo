// Package http expone la API REST: router, handlers y middleware.
package http

import (
	"encoding/json"
	"net/http"
)

func escribirJSON(w http.ResponseWriter, estado int, datos any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(estado)
	if datos != nil {
		_ = json.NewEncoder(w).Encode(datos)
	}
}

// escribirError devuelve un mensaje genérico al cliente, sin filtrar detalles internos.
func escribirError(w http.ResponseWriter, estado int, mensaje string) {
	escribirJSON(w, estado, map[string]string{"error": mensaje})
}
