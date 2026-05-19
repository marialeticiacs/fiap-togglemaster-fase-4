package main

import (
	"context"
	"database/sql"
	"log"
	"net/http"
	"os"

	_ "github.com/jackc/pgx/v4/stdlib" // Import para registrar o driver pgx
	"github.com/joho/godotenv"

	// Imports do OpenTelemetry
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
)

// App struct (para injeção de dependência)
type App struct {
	DB        *sql.DB
	MasterKey string
}

// Inicializa o provedor de Traces do OpenTelemetry
func initTracer() (*sdktrace.TracerProvider, error) {
	ctx := context.Background()

	// Cria o exportador OTLP via gRPC (vai usar as variáveis de ambiente OTEL_)
	exporter, err := otlptracegrpc.New(ctx)
	if err != nil {
		return nil, err
	}

	// Define os recursos da aplicação (Nome do serviço)
	res, err := resource.New(ctx,
		resource.WithAttributes(
			semconv.ServiceNameKey.String("auth-service"),
		),
	)
	if err != nil {
		return nil, err
	}

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(res),
	)

	// Define o provedor e a propagação global para rastreamento distribuído
	otel.SetTracerProvider(tp)
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(propagation.TraceContext{}, propagation.Baggage{}))

	return tp, nil
}

func main() {
	// Carrega o .env para ambiente local (não interfere em produção)
	_ = godotenv.Load()

	// --- Inicialização do OpenTelemetry ---
	tp, err := initTracer()
	if err != nil {
		log.Printf("Aviso: Falha ao inicializar OpenTelemetry: %v", err)
	} else {
		defer func() {
			if err := tp.Shutdown(context.Background()); err != nil {
				log.Printf("Erro ao desligar TracerProvider: %v", err)
			}
		}()
		log.Println("OpenTelemetry inicializado com sucesso!")
	}

	// --- Configuração ---
	port := os.Getenv("PORT")
	if port == "" {
		port = "8001"
	}

	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		log.Fatal("DATABASE_URL deve ser definida")
	}

	masterKey := os.Getenv("MASTER_KEY")
	if masterKey == "" {
		log.Fatal("MASTER_KEY deve ser definida")
	}

	// --- Conexão com o Banco ---
	db, err := connectDB(databaseURL)
	if err != nil {
		log.Fatalf("Não foi possível conectar ao banco de dados: %v", err)
	}
	defer db.Close()

	app := &App{
		DB:        db,
		MasterKey: masterKey,
	}

	// --- Rotas ---
	mux := http.NewServeMux()

	mux.HandleFunc("/health", app.healthHandler)
	mux.HandleFunc("/validate", app.validateKeyHandler)
	mux.HandleFunc("/test-error", app.testErrorHandler)

	// Rotas de administração (proteção por Master Key)
	mux.Handle("/admin/keys",
		app.masterKeyAuthMiddleware(
			http.HandlerFunc(app.createKeyHandler),
		),
	)

	// NOVO: Embrulhamos o Mux inteiro com o handler do OpenTelemetry!
	// Agora qualquer requisição HTTP será interceptada e gerará um Trace.
	handler := otelhttp.NewHandler(mux, "auth-service-http")

	log.Printf("Serviço de Autenticação rodando na porta %s", port)
	if err := http.ListenAndServe(":"+port, handler); err != nil {
		log.Fatal(err)
	}
}

// connectDB inicializa e testa a conexão com o PostgreSQL
func connectDB(databaseURL string) (*sql.DB, error) {
	db, err := sql.Open("pgx", databaseURL)
	if err != nil {
		return nil, err
	}

	if err = db.Ping(); err != nil {
		return nil, err
	}

	log.Println("Conectado ao PostgreSQL com sucesso!")
	return db, nil
}