package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"gymcontrol/internal/adapter/dni"
	nethttp "gymcontrol/internal/adapter/http"
	"gymcontrol/internal/adapter/storage/postgres"
	"gymcontrol/internal/app/asistencia"
	"gymcontrol/internal/app/auth"
	"gymcontrol/internal/app/documento"
	"gymcontrol/internal/app/membresias"
	"gymcontrol/internal/app/pagos"
	"gymcontrol/internal/app/personal"
	"gymcontrol/internal/app/planes"
	"gymcontrol/internal/app/socios"
	"gymcontrol/internal/app/stats"
	"gymcontrol/internal/platform/config"
	"gymcontrol/internal/platform/security"
)

func main() {
	cfg := config.Cargar()

	// 1. Aplicar migraciones al arrancar (la BD se pone al día sola).
	log.Println("aplicando migraciones...")
	if err := postgres.Migrar(cfg.MigrateURL()); err != nil {
		log.Fatalf("error en migraciones: %v", err)
	}

	// 2. Conectar a la base de datos.
	ctx := context.Background()
	pool, err := postgres.NuevoPool(ctx, cfg.DSN())
	if err != nil {
		log.Fatalf("error conectando a la BD: %v", err)
	}
	defer pool.Close()

	// 3. Ensamblar dependencias (composición de la app: aquí se "enchufan"
	//    las implementaciones concretas en los puertos).
	authRepo := postgres.NewAuthRepo(pool)
	sociosRepo := postgres.NewSociosRepo(pool)
	planesRepo := postgres.NewPlanesRepo(pool)
	membresiasRepo := postgres.NewMembresiasRepo(pool)
	personalRepo := postgres.NewPersonalRepo(pool)
	statsRepo := postgres.NewStatsRepo(pool)
	asistenciaRepo := postgres.NewAsistenciaRepo(pool)
	pagosRepo := postgres.NewPagosRepo(pool)
	hasher := security.NewBcryptHasher()
	jwt := security.NewJWT(cfg.JWTSecret, cfg.JWTTTL)

	dniCliente := dni.NewCliente(cfg.DNIApiURL, cfg.DNIApiToken)

	authSvc := auth.NewService(authRepo, hasher, jwt)
	sociosSvc := socios.NewService(sociosRepo)
	planesSvc := planes.NewService(planesRepo)
	membresiasSvc := membresias.NewService(membresiasRepo)
	personalSvc := personal.NewService(personalRepo, hasher)
	statsSvc := stats.NewService(statsRepo)
	asistenciaSvc := asistencia.NewService(asistenciaRepo, membresiasRepo)
	pagosSvc := pagos.NewService(pagosRepo)
	documentoSvc := documento.NewService(dniCliente)

	authHandler := nethttp.NewAuthHandler(authSvc)
	sociosHandler := nethttp.NewSociosHandler(sociosSvc)
	planesHandler := nethttp.NewPlanesHandler(planesSvc)
	membresiasHandler := nethttp.NewMembresiasHandler(membresiasSvc)
	personalHandler := nethttp.NewPersonalHandler(personalSvc)
	statsHandler := nethttp.NewStatsHandler(statsSvc)
	asistenciaHandler := nethttp.NewAsistenciaHandler(asistenciaSvc)
	pagosHandler := nethttp.NewPagosHandler(pagosSvc)
	documentoHandler := nethttp.NewDocumentoHandler(documentoSvc)

	router := nethttp.NuevoRouter(authHandler, sociosHandler, documentoHandler, planesHandler, membresiasHandler, personalHandler, statsHandler, asistenciaHandler, pagosHandler, jwt)

	// 4. Servidor HTTP con apagado ordenado.
	srv := &http.Server{
		Addr:         ":" + cfg.APIPort,
		Handler:      router,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 15 * time.Second,
	}

	go func() {
		log.Printf("API escuchando en http://localhost:%s", cfg.APIPort)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("error en el servidor: %v", err)
		}
	}()

	// Esperar señal de apagado.
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)
	<-stop

	log.Println("apagando servidor...")
	ctxApagado, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctxApagado); err != nil {
		log.Printf("apagado forzado: %v", err)
	}
}
