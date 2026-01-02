# Private key for root CA
openssl genrsa -aes256 -out ca.key 4096
# Sign root CA private key
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 -out ca.crt

# Private key for prod
openssl genrsa -aes256 -out prod.key 4096
# Create CSR (Certificate Signing Request ) w/ prod private key
openssl req -new -key prod.key -out prod.csr -sha256

# --- prod.ext
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

# Allowed List. This cert valid only if you access the server via:
[alt_names]
DNS.1 = localhost
DNS.2 = server
IP.1 = 127.0.0.1
IP.2 = 192.168.100.101

# Self-sign prod cert w/ root CA key, root CA cert, CSR, and ext
openssl x509 -req -in prod.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out prod.crt -days 365 -sha256 -extfile prod.ext