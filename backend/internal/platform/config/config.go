// Package config carga la configuración desde variables de entorno.
package config

import (
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/joho/godotenv"
)

type Config struct {
	DatabaseURL string
	DBHost      string
	DBPort      string
	DBUser      string
	DBPassword  string
	DBName      string
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
		DatabaseURL: env("DATABASE_URL", ""),
		DBHost:      env("DB_HOST", "localhost"),
		DBPort:      env("DB_PORT", "5434"),
		DBUser:      env("DB_USER", "gym"),
		DBPassword:  env("DB_PASSWORD", "gym"),
		DBName:      env("DB_NAME", "gymcontrol"),
		APIPort:     env("PORT", env("API_PORT", "8080")),
		JWTSecret:   env("JWT_SECRET", "dev-secret-no-usar-en-produccion"),
		JWTTTL:      24 * time.Hour,
		DNIApiURL:   env("DNI_API_URL", "https://api.apis.net.pe/v1/dni"),
		DNIApiToken: env("DNI_API_TOKEN", ""),
	}
}

// DSN para conexiones de la aplicación (pgxpool).
// En la nube se usa DATABASE_URL; en local se arma desde las variables DB_*.
func (c Config) DSN() string {
	if c.DatabaseURL != "" {
		return c.DatabaseURL
	}
	return fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=disable",
		c.DBUser, c.DBPassword, c.DBHost, c.DBPort, c.DBName)
}

// MigrateURL usa el esquema pgx5:// que entiende golang-migrate.
func (c Config) MigrateURL() string {
	if c.DatabaseURL != "" {
		url := c.DatabaseURL
		url = strings.Replace(url, "postgresql://", "pgx5://", 1)
		url = strings.Replace(url, "postgres://", "pgx5://", 1)
		return url
	}
	return fmt.Sprintf("pgx5://%s:%s@%s:%s/%s?sslmode=disable",
		c.DBUser, c.DBPassword, c.DBHost, c.DBPort, c.DBName)
}

func env(clave, porDefecto string) string {
	if v := os.Getenv(clave); v != "" {
		return v
	}
	return porDefecto
}
