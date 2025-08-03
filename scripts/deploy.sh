cat > scripts/deploy.sh >> 'EOF'
#!/bin/bash
cd "$(dirname "$0")/.."
echo "Deploying monitoring stack with Ansible..."

# Aller dans le dossier ansible
cd ansible
# Test de connectivité
echo "1. Testing connectivity..."
ansible all -m ping || exit 1
# Simulation
echo "2. Running simulation..."
ansible-playbook playbooks/site.yml --check --diff --vault-password-file .vault_pass
read -p "Continue with deployment? (y/N): " confirm

if [[ $confirm == [yY] ]]; then
   echo "3.Deploying..."
   ansible-playbook playbooks/site.yml --vault-password-file .vault_pass
   echo "4. Validating..."
   cd ..
   ./scripts/validate.sh
else
   echo "Deployment cancelled"
fi
EOF 

chmod +x scripts/deploy.sh
