Create secret in the kubernetes by following command:

kubectl create secret generic aws-creds \
  --from-literal=AWS_ACCESS_KEY_ID=key_id \
  --from-literal=AWS_SECRET_ACCESS_KEY=key_secret \
  -n logging