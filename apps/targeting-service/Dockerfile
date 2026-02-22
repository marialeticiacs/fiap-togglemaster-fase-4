# ----------------------------
# Estágio 1: Builder
# Compila dependências que precisam de C/C++ (Postgres driver)
# ----------------------------
FROM python:3.12-slim AS builder

WORKDIR /app

# Instala compiladores e headers do Postgres
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Cria ambiente virtual
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Instala dependências
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# ----------------------------
# Estágio 2: Runner (Imagem Final)
# Apenas runtime necessário
# ----------------------------
FROM python:3.12-slim

WORKDIR /app

# Instala libpq (runtime do Postgres) e certificados de CA para HTTPS
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copia o venv do estágio anterior
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Cria usuário de aplicação (segurança)
RUN useradd -m appuser

# Copia o código fonte
COPY . .

# Ajusta permissões
RUN chown -R appuser:appuser /app

# Troca para usuário seguro
USER appuser

# Expõe a porta 8003 (padrão do targeting-service)
EXPOSE 8003

# Executa com Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8003", "--workers", "2", "app:app"]