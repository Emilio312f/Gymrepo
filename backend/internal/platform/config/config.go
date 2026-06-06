// Package config carga la configuración desde variables de entorno.
package config

import (
	"fmt"
	"os"
	"time"

	"github.com/joho/godotenv"
)

type Config struct {
	DBHost     string
	DBPort     string
	DBUser     string
	DBPassword string
	DBName     string
	APIPort     string
	JWTSecret   string
	JWTTTL      time.Duration
	DNIApiURL   string
	DNIApiToken string
}

// Cargar lee el entorno (y un archivo .env si existe) con valores por defecto
// pensados para desarrollo local contra la base de datos en Docker (puerto 5433).
func Cargar() Config {
	// Intenta cargar .env desde el directorio actual o la raíz del proyecto.
	// Si no existe, no pasa nada: se usan las variables de entorno reales.
	_ = godotenv.Load(".env", "../.env")

	return Config{
		DBHost:     env("DB_HOST", "localhost"),
		DBPort:     env("DB_PORT", "5434"),
		DBUser:     env("DB_USER", "gym"),
		DBPassword: env("DB_PASSWORD", "gym"),
		DBName:     env("DB_NAME", "gymcontrol"),
		APIPort:    env("API_PORT", "8080"),
		JWTSecret:   env("JWT_SECRET", "dev-secret-no-usar-en-produccion"),
		JWTTTL:      24 * time.Hour,
		DNIApiURL:   env("DNI_API_URL", "https://api.apis.net.pe/v1/dni"),
		DNIApiToken: env("DNI_API_TOKEN", ""),
	}
}

// DSN para conexiones de la aplicación (pgxpool).
func (c Config) DSN() string {
	return fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=disable",
		c.DBUser, c.DBPassword, c.DBHost, c.DBPort, c.DBName)
}

// MigrateURL usa el esquema pgx5:// que entiende golang-migrate.
func (c Config) MigrateURL() string {
	return fmt.Sprintf("pgx5://%s:%s@%s:%s/%s?sslmode=disable",
		c.DBUser, c.DBPassword, c.DBHost, c.DBPort, c.DBName)
}

func env(clave, porDefecto string) string {
	if v := os.Getenv(clave); v != "" {
		return v
	}
	return porDefecto
}
