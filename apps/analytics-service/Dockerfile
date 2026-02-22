# ----------------------------
# Estágio 1: Builder
# Prepara as dependências
# ----------------------------
FROM python:3.12-slim AS builder

WORKDIR /app

# Instala compiladores (necessário para algumas deps de criptografia/boto3)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libffi-dev \
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
# ----------------------------
FROM python:3.12-slim

WORKDIR /app

# Instala certificados de CA (Crucial para conectar na AWS via HTTPS)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copia o venv do builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Cria usuário não-root
RUN useradd -m appuser

# Copia o código
COPY . .

# Ajusta permissões
RUN chown -R appuser:appuser /app

# Define usuário seguro
USER appuser

# Expõe a porta 8005 (Health Check)
EXPOSE 8005

# Executa com Gunicorn
# Nota: --workers 1 é recomendado aqui pois o serviço roda uma thread
# de consumo de fila em background. Múltiplos workers poderiam duplicar o consumo.
CMD ["gunicorn", "--bind", "0.0.0.0:8005", "--workers", "1", "app:app"]