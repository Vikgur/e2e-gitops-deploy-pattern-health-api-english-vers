#!/bin/bash

ENV="$1"
SSH_KEY="$HOME/.ssh/id_ed25519_yacloud"
MASTER_NAME="k3s-master-$ENV"

if [[ "$ENV" != "stage" && "$ENV" != "prod" ]]; then
  echo "Usage: $0 [stage|prod]"
  exit 1
fi

MASTER_IP=$(yc compute instance get "$MASTER_NAME" --format json | jq -r '.network_interfaces[0].primary_v4_address.one_to_one_nat.address')

if [[ -z "$MASTER_IP" ]]; then
  echo "Failed to get external IP of master $MASTER_NAME"
  exit 1
fi

SSH_PRIV_KEY_CONTENT=$(cat "$SSH_KEY")
PUB_KEY=$(<"$SSH_KEY.pub")

ssh -t -i "$SSH_KEY" ubuntu@"$MASTER_IP" <<EOF
set -e

# # 0. Obtain Let's Encrypt certificate BEFORE starting k3s
# sudo apt-get install -y certbot
#
# sudo certbot certonly --standalone --non-interactive --agree-tos \\
#   -m longlive@inbox.ru -d health-api
#
# # Verify certificate was obtained
# if [ ! -f /etc/letsencrypt/live/health-api/fullchain.pem ]; then
#   echo "Certificate was not obtained"
#   exit 1
# fi

# 1. Copy SSH keys
mkdir -p ~/.ssh
grep -qxF "$PUB_KEY" ~/.ssh/authorized_keys || echo "$PUB_KEY" >> ~/.ssh/authorized_keys
cat > ~/.ssh/id_ed25519_yacloud <<EOKEY
$SSH_PRIV_KEY_CONTENT
EOKEY

chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys ~/.ssh/id_ed25519_yacloud

# 2. Install yq
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq
yq --version

# 3. Get worker IPs from hosts.yaml
WORKER1_IP=\$(yq '.all.children.workers.hosts."k3s-worker-1".ansible_host' ~/health-api/ansible/inventories/$ENV/hosts.yaml)
WORKER2_IP=\$(yq '.all.children.workers.hosts."k3s-worker-2".ansible_host' ~/health-api/ansible/inventories/$ENV/hosts.yaml)

# 4. Install k3s on master
curl -sfL https://get.k3s.io -o /tmp/install-k3s.sh
chmod +x /tmp/install-k3s.sh
sudo /tmp/install-k3s.sh server \\
  --disable traefik \\
  --disable-cloud-controller \\
  --disable-network-policy \\
  --write-kubeconfig-mode 644

# 5. Verify k3s installation
if ! [ -f /usr/local/bin/k3s ]; then
  echo "K3s is NOT installed — aborting"
  exit 1
fi

# 6. Verify k3s kubectl
if ! /usr/local/bin/k3s kubectl get nodes &>/dev/null; then
  echo "FATAL: k3s kubectl is not working!"
  exit 2
fi

# 7. Prepare files to install agent on workers (without internet)
cp /usr/local/bin/k3s ~/k3s-agent

INTERNAL_IP=\$(hostname -I | awk '{print \$1}')
echo "K3S_URL=https://\${INTERNAL_IP}:6443" > ~/k3s-agent.env
echo "K3S_TOKEN=\$(sudo cat /var/lib/rancher/k3s/server/node-token | tr -d '\n')" >> ~/k3s-agent.env

# 8. Save into Ansible role
mkdir -p ~/health-api/ansible/roles/k3s/files/
cp ~/k3s-agent ~/health-api/ansible/roles/k3s/files/k3s
cp ~/k3s-agent.env ~/health-api/ansible/roles/k3s/files/k3s-agent.env

# 9. Clone or update Argo CD config repo (argocd-config-health-api)
if [ ! -d ../argocd-config-health-api ]; then
  git clone https://gitlab.com/vikgur/argocd-config-health-api.git ../argocd-config-health-api
else
  cd ../argocd-config-health-api
  git pull
  cd ../ansible
fi

# 10. Clone or update GitOps apps repo (gitops-apps-health-api)
if [ ! -d ../gitops-apps-health-api ]; then
  git clone https://gitlab.com/vikgur/gitops-apps-health-api.git ../gitops-apps-health-api
else
  cd ../gitops-apps-health-api
  git pull
  cd ../ansible
fi

# 11. Install Ansible and run playbook
sudo apt install -y ansible
cd ~/health-api/ansible

# 12. Run Ansible: install roles and apply playbook (includes argocd-config)
if [ "$ENV" = "prod" ]; then
  VERSION=$(git describe --tags --abbrev=0)
else
  SHORT_SHA=$(git rev-parse --short HEAD)
  VERSION="stage-$SHORT_SHA"
fi

ansible-galaxy collection install -r requirements.yml
ANSIBLE_ROLES_PATH=roles \
ansible-playbook -i inventories/$ENV/hosts.yaml playbook.yaml \
--vault-password-file .vault_pass.txt \
--extra-vars "ENV=$ENV VERSION=$VERSION"
EOF
