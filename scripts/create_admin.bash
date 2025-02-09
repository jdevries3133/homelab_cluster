#!/bin/bash

set -eux

# Create an admin user

USERNAME="$1"

# ~90 days
EXPIRATION_SECONDS="3600"

if [ -z "$USERNAME" ]
then
    echo "Fatal: provide a username as \$1"
    exit 1
fi

if [ ! -d ~/.kube ]
then
    mkdir ~/.kube
fi

if [ ! -f ~/.kube/${USERNAME}_id_rsa ]
then
    openssl genrsa -out ~/.kube/${USERNAME}_id_rsa 2048
fi

openssl \
    req \
    -new \
    -key ~/.kube/${USERNAME}_id_rsa \
    -out ~/.kube/${USERNAME}-csr \
    -subj "/CN=${USERNAME}"


cat <<EOF | ssh big-boi kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${USERNAME}
spec:
  request: $(cat ~/.kube/${USERNAME}-csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: ${EXPIRATION_SECONDS}
  usages:
  - client auth
EOF

ssh big-boi kubectl certificate approve ${USERNAME}

while [ ! -z "$(ssh big-boi kubectl get csr | grep Pending)" ]
do
    echo "waiting for CSR approval..."
    sleep 1
done

ssh big-boi \
    "kubectl get certificatesigningrequests ${USERNAME} -o jsonpath=\"{ .status.certificate }\"" \
    | base64 --decode \
    | tee ~/.kube/${USERNAME}.crt


echo "$(cat <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $(ssh big-boi cat /etc/kubernetes/pki/ca.crt | base64 | tr -d '\n')
    server: https://cluster.jackdevries.com:6443
  name: cluster.jackdevries.com
contexts:
- context:
    cluster: cluster.jackdevries.com
    user: ${USERNAME}
  name: ${USERNAME}@cluster.jackdevries.com
current-context: ${USERNAME}@cluster.jackdevries.com
kind: Config
preferences: {}
users:
- name: ${USERNAME}
  user:
    client-certificate-data: $(cat ~/.kube/${USERNAME}.crt | base64 | tr -d '\n')
    client-key-data: $(cat ~/.kube/${USERNAME}_id_rsa | base64 | tr -d '\n')

---

User was created successfully! Use the above kubectl config to talk to the API
server as the new user. Note that no roles have been applied to the user yet.
Try \`kubectl auth whoami\`, and then add roles to the user as needed.
EOF
)"
