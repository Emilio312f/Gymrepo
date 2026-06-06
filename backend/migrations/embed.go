// Package migrations expone los archivos .sql de migración embebidos en el
// binario, para que el backend pueda aplicarlos él mismo al arrancar.
package migrations

import "embed"

//go:embed *.sql
var Files embed.FS
