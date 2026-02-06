#!/bin/bash
# setup-tls.sh - Generate TLS certificates for local HTTPS (free, no external services)
#
# Two options:
#   1. mkcert (recommended) - generates browser-trusted local certificates
#      Install: https://github.com/FiloSottile/mkcert
#   2. openssl (fallback) - generates self-signed certificates (browser shows warning)
#
# Usage:
#   chmod +x setup-tls.sh
#   ./setup-tls.sh
#   # Then set GF_SERVER_PROTOCOL=https in .env and restart

set -e

CERT_DIR="./certs"
mkdir -p "$CERT_DIR"

echo "=== SOC Monitoring Stack - TLS Certificate Setup ==="
echo ""

# Check if mkcert is available (preferred - creates browser-trusted certs)
if command -v mkcert &> /dev/null; then
    echo "Found mkcert - generating browser-trusted certificates..."
    echo ""

    # Install local CA (only needed once, safe to run multiple times)
    mkcert -install

    # Generate certificate for localhost and common local addresses
    mkcert -cert-file "$CERT_DIR/grafana.crt" -key-file "$CERT_DIR/grafana.key" \
        localhost 127.0.0.1 ::1

    echo ""
    echo "Browser-trusted certificates generated with mkcert."
    echo "Your browser will trust these automatically - no security warnings."
else
    echo "mkcert not found - using openssl for self-signed certificates."
    echo ""
    echo "TIP: For browser-trusted certs without warnings, install mkcert:"
    echo "  macOS:  brew install mkcert"
    echo "  Linux:  https://github.com/FiloSottile/mkcert#installation"
    echo "  Windows: choco install mkcert"
    echo ""

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$CERT_DIR/grafana.key" \
        -out "$CERT_DIR/grafana.crt" \
        -subj "/CN=localhost/O=SOC Monitoring Stack/C=US" \
        -addext "subjectAltName=DNS:localhost,IP:127.0.0.1,IP:::1" \
        2>/dev/null

    echo "Self-signed certificates generated."
    echo "Your browser will show a security warning - click 'Advanced' then 'Proceed'."
fi

# Set permissions
chmod 644 "$CERT_DIR/grafana.crt"
chmod 600 "$CERT_DIR/grafana.key"

echo ""
echo "=== Certificates Ready ==="
echo "  Certificate: $CERT_DIR/grafana.crt"
echo "  Key:         $CERT_DIR/grafana.key"
echo ""
echo "=== Next Steps ==="
echo "  1. Add these lines to your .env file:"
echo ""
echo "     GF_SERVER_PROTOCOL=https"
echo "     GF_SERVER_CERT_FILE=/etc/grafana/certs/grafana.crt"
echo "     GF_SERVER_CERT_KEY=/etc/grafana/certs/grafana.key"
echo ""
echo "  2. Restart the stack:"
echo "     docker-compose down && docker-compose up -d"
echo ""
echo "  3. Access Grafana at: https://localhost:3000"
echo ""
