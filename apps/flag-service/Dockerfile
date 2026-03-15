# ----------------------------
# Estágio 1: Builder
# Instala dependências e compila pacotes necessários
# ----------------------------
FROM python:3.12-slim AS builder

WORKDIR /app

# Instala dependências de sistema necessárias para compilar pacotes Python
# (build-essential para C/C++, libpq-dev para o driver do PostgreSQL)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Cria um ambiente virtual para isolar as dependências
RUN python -m venv /opt/venv
# Ativa o venv no PATH para os próximos comandos
ENV PATH="/opt/venv/bin:$PATH"
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Copia e instala os requirements
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# ----------------------------
# Estágio 2: Runner (Imagem Final)
# Imagem limpa apenas com o runtime necessário
# ----------------------------
FROM python:3.12-slim

WORKDIR /app

# Instala apenas as bibliotecas de sistema runtime necessárias
# (libpq é necessário para o PostgreSQL funcionar, mas não precisa do gcc aqui)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copia o ambiente virtual do estágio builder
COPY --from=builder /opt/venv /opt/venv

# Define o PATH para usar o Python do ambiente virtual automaticamente
ENV PATH="/opt/venv/bin:$PATH"
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Cria usuário não-root por segurança
RUN useradd -m appuser

# Copia o código da aplicação
COPY . .

# Ajusta permissões (opcional, mas boa prática)
RUN chown -R appuser:appuser /app

# Muda para o usuário seguro
USER appuser

# Expõe a porta 8002 (padrão do flag-service)
EXPOSE 8002

# Comando de execução usando Gunicorn (Production Server)
# --bind define o host/porta
# --workers define quantos processos (geralmente 2-4 para containers pequenos)
# app:app refere-se ao arquivo app.py e a instância Flask 'app' dentro dele
CMD ["gunicorn", "--bind", "0.0.0.0:8002", "--workers", "2", "app:app"]