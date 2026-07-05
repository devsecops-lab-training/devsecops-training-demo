# =============================================================================
# Dockerfile — DevSecOps Training Demo (Chainguard Production Ready)
# =============================================================================

# ── STAGE 1 : Build ─────────────────────────────────────────────────────────
# On utilise l'image -dev qui contient tous les outils nécessaires (pip, gcc...)
# hadolint ignore=DL3007
FROM cgr.dev/chainguard/python:latest-dev AS builder

# On se place dans le home de l'utilisateur nonroot pour éviter les conflits de droits
WORKDIR /home/nonroot/app

# Création et activation de l'environnement virtuel pour isoler les paquets
RUN python -m venv venv
ENV PATH="/home/nonroot/app/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt


# ── STAGE 2 : Runtime ───────────────────────────────────────────────────────
# Image finale minimale SANS le suffixe -dev : aucune CVE à l'horizon (0 outil superflu)
# hadolint ignore=DL3007
FROM cgr.dev/chainguard/python:latest

WORKDIR /home/nonroot/app

# Copie de l'environnement virtuel et du code avec les bons droits d'exécution
COPY --from=builder /home/nonroot/app/venv ./venv
COPY --chown=nonroot:nonroot app/ ./app/

# Configuration des variables d'environnement pour le venv
ENV VIRTUAL_ENV=/home/nonroot/app/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ENV PYTHONUNBUFFERED=1

# Version de l'application passée au build
ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION}

EXPOSE 8000

# On force l'ENTRYPOINT sur le binaire Python du venv pour court-circuiter celui de Chainguard
ENTRYPOINT ["/home/nonroot/app/venv/bin/python", "-m", "uvicorn"]

# Le CMD ne contient plus que les arguments par défaut transmis à uvicorn
CMD ["app.main:app", "--host", "0.0.0.0", "--port", "8000"]

# Healthcheck utilisant le module natif http.client (compatible avec l'image minimale distroless)
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD /home/nonroot/app/venv/bin/python -c "import http.client; c=http.client.HTTPConnection('localhost', 8000); c.request('GET', '/health'); r=c.getresponse(); exit(0 if r.status==200 else 1)"
