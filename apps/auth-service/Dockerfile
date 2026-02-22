# ----------------------------
# Estágio 1: Builder
# Compila o código Go
# ----------------------------
FROM golang:1.22-alpine AS builder

# Instala dependências de sistema necessárias
RUN apk add --no-cache git ca-certificates tzdata && update-ca-certificates

# Cria um usuário não-root
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid 10001 \
    appuser

WORKDIR /app

# Copia apenas os arquivos de módulo (mais rápido e cacheável)
COPY go.mod go.sum ./
RUN go mod download

# Copia o restante do código
COPY . .

# Compila a aplicação para binário estático
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-w -s" -o auth-service .

# ----------------------------
# Estágio 2: Runner
# Imagem mínima scratch
# ----------------------------
FROM scratch


# Copia timezone e certificados SSL
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# Copia o binário final
COPY --from=builder /app/auth-service /app/auth-service

# Usa o usuário não-root
USER appuser:appuser

# Expõe a porta do serviço
EXPOSE 8001

# Executa o serviço
ENTRYPOINT ["/app/auth-service"]
