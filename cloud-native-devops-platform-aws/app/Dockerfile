# Small, secure production image for the Flask app
FROM python:3.12-slim

# Don't write .pyc files, flush logs straight to stdout
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install dependencies first so Docker can cache this layer
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# Run as a non-root user (security best practice)
RUN useradd --create-home appuser
USER appuser

EXPOSE 5000

# Gunicorn = production-grade WSGI server (Flask's dev server is not for production)
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]
