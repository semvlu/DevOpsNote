# Cert file ext: .pem, .crt
# Key file ext: .key 
# .csr: certificate signing request
# .crl: certificate revocation list

# openssl.cnf @
# Ubuntu: /etc/ssl/openssl.cnf
# CentOS: /etc/pki/tls/openssl.cnf

cd ./demoCA
# Gen CA Key & Cert
openssl genrsa -aes256 -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 -out ca.crt

# Gen server Key & Cert
openssl genrsa -aes256 -out prod.key 4096
# Create CSR (Certificate Signing Request ) w/ prod private key
openssl req -new -key prod.key -out prod.csr -sha256

# CA env files prep
mkdir -p newcerts
touch index.txt # index.txt: cert log
echo 01 > serial # serial: ver# of next cert


# Sign
openssl ca -in prod.csr -out prod.crt -config openssl.cnf 

# Gen CRL
openssl ca -gencrl -out crl.crl -config openssl.cnf

# Revoke Cert
openssl ca -revoke prod.crt -config openssl.cnf
# Regen CRL
openssl ca -gencrl -out crl.pem -config openssl.cnf

# Reload CRL 
nginx -s reload

# Verify CRL Distribution Points
openssl x509 -in prod.crt -noout -text | grep -A 4 "CRL Distribution Points"
# or:
openssl crl -in crl.crl -noout -text