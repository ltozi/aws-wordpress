#!/bin/bash

# Set variables
DOMAIN="mydomain.local" # Replace with your domain or ALB DNS name
CERT_VALID_DAYS=365     # Validity period for the self-signed certificate
PRIVATE_KEY_FILE="private.key"
CERTIFICATE_FILE="certificate.crt"

# Function to clean up temporary files
cleanup() {
    echo "Cleaning up temporary files..."
    rm -f certificate.csr
}

# Trap to ensure cleanup happens on script exit
trap cleanup EXIT

# 1. Generate Private Key
echo "Generating private key..."
openssl genpkey -algorithm RSA -out "$PRIVATE_KEY_FILE" -pkeyopt rsa_keygen_bits:2048

# Check private key size
PRIVATE_KEY_SIZE=$(wc -c < "$PRIVATE_KEY_FILE")
if (( PRIVATE_KEY_SIZE > 5120 )); then
  echo "Error: Private key size exceeds 5KB ($PRIVATE_KEY_SIZE bytes). Please consider using a 2048-bit key."
  exit 1
fi

# 2. Generate Certificate Signing Request (CSR)
echo "Generating Certificate Signing Request (CSR)..."
openssl req -new -key "$PRIVATE_KEY_FILE" -out certificate.csr -subj "/C=US/ST=YourState/L=YourCity/O=YourOrganization/CN=$DOMAIN"

# 3. Generate Self-Signed Certificate
echo "Generating self-signed certificate..."
openssl x509 -req -days "$CERT_VALID_DAYS" -in certificate.csr -signkey "$PRIVATE_KEY_FILE" -out "$CERTIFICATE_FILE"

# Verify Certificate is X.509 v3
VERSION=$(openssl x509 -in "$CERTIFICATE_FILE" -text | grep Version | cut -d ':' -f 2 | xargs)
if [[ "$VERSION" != "3 (0x2)" ]]; then
    echo "Error: Certificate is not X.509 v3. Found Version $VERSION"
    exit 1
fi

# Verify Certificate validity
END_DATE=$(openssl x509 -noout -enddate -in "$CERTIFICATE_FILE" | cut -d '=' -f 2)
END_EPOCH=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$END_DATE" "+%s" 2>/dev/null)
if [[ -z "$END_EPOCH" ]]; then
    END_EPOCH=$(date -d "$END_DATE" +%s)
fi
CURRENT_PLUS_ONE_DAY=$(date -v+1d "+%s")
if [[ -z "$CURRENT_PLUS_ONE_DAY" ]]; then
    CURRENT_PLUS_ONE_DAY=$(date -d "+1 day" +%s)
fi
if [[ "$END_EPOCH" -le "$CURRENT_PLUS_ONE_DAY" ]]; then
    echo "Error: Certificate is not valid. Check date and time settings."
    exit 1
fi

# Output the generated files
echo "Self-signed certificate and private key generated successfully."
echo "Private Key: $PRIVATE_KEY_FILE"
echo "Certificate: $CERTIFICATE_FILE"