# Stage 1 — Build Python dependencies
FROM python:3.12-slim AS builder

WORKDIR /install
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install/deps -r requirements.txt

# Stage 2 — Final runtime image
FROM python:3.12-slim

# Install curl
RUN apt-get update && apt-get install -y curl

ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Copy dependencies and application code
COPY --from=builder /install/deps /usr/local
COPY app/ .

# # Create an empty migrations folder for docker-compose compatibility
# RUN mkdir -p /app/migrations

# Healthcheck as defined in docker-compose for consistent behavior
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=2 \
  CMD curl -f http://localhost:8080/health || exit 1

# Ports
EXPOSE 8080

# Launch API (Flask via Gunicorn)
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]
