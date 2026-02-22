# ----------------------------
# Estágio 1: Builder
# Compila o binário Go estaticamente
# ----------------------------
FROM golang:1.23-alpine AS builder

# Instala dependências de sistema (necessário para certificados HTTPS da AWS)
RUN apk add --no-cache git ca-certificates tzdata && update-ca-certificates

# Cria usuário não-root
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid 10001 \
    appuser

WORKDIR /app

# Gerenciamento de cache de dependências
COPY go.mod go.sum ./
RUN go mod download

# Copia código fonte
COPY . .

# Compilação Otimizada
# CGO_ENABLED=0: Gera binário estático (vital para rodar no 'scratch')
# -ldflags="-w -s": Remove debug symbols (reduz tamanho)
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-w -s" -o evaluation-service .

# ----------------------------
# Estágio 2: Runner (Imagem Final)
# Imagem 'scratch' (vazia) para máxima performance
# ----------------------------
FROM scratch

# Copia arquivos essenciais do builder
# 1. Certificados SSL (CRÍTICO: Necessário para conectar na AWS SQS e APIs HTTPS)
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
# 2. Informações de Timezone
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
# 3. Informações de usuário
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# Copia o binário
COPY --from=builder /app/evaluation-service /app/evaluation-service

# Define usuário seguro
USER appuser:appuser

# Expõe a porta 8004
EXPOSE 8004

# Executa
ENTRYPOINT ["/app/evaluation-service"]