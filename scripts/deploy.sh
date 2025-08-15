#!/bin/bash
set -e

cd "$(dirname "$0")/../ansible"

echo "Deploying monitoring stack with Ansible..."

# Test de connectivité
echo "1. Testing connectivity..."
ansible all -m ping || {
    echo "❌ Connection failed. Check your inventory configuration."
    exit 1
}

# Simulation avec confirmation
echo "2. Running simulation..."
ansible-playbook playbooks/site.yml --check --diff

echo ""
read -p "Continue with deployment? (y/N): " confirm

if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    echo "3. Deploying..."
    ansible-playbook playbooks/site.yml -v
    
    echo "4. Validating deployment..."
    cd ..
    ./scripts/validate.sh
    
    echo " Deployment completed successfully!"
else
    echo "❌ Deployment cancelled"
    exit 1
fi
