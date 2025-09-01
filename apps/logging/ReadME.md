Use these commands to generate the main CA cert chain


openssl genrsa -out ca.key 4096


openssl req -x509 -new -nodes -key ca.key \
  -sha256 -days 3650 \
  -subj "/CN=Hubble-Root-CA" \
  -out ca.crt


cat ca.crt | base64 -w0 >> ca_cert.txt
cat ca.key | base64 -w0 >> ca_key.txt



below yaml we can use and replace the keys base64 encoded string

apiVersion: v1
kind: Secret
metadata:
  name: hubble-ca
  namespace: kube-system
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCg...   # <base64 of ca.crt>
  tls.key: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQo...   # <base64 of ca.key>
