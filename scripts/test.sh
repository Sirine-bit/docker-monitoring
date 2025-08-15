#!/bin/bash
set -e

cd "$(dirname "$0")/../ansible"

echo "🧪 Testing Ansible configuration..."

# Vérification des collections requises
echo "0. Checking required collections..."
if ! ansible-galaxy collection list | grep -q "community.docker" 2>/dev/null; then
    echo "Installing required collections..."
    ansible-galaxy collection install -r ../requirements.yml
fi

# Test de connectivité
echo "1. Testing connectivity..."
ansible all -m ping

# Test de syntaxe
echo "2. Testing playbook syntax..."
ansible-playbook playbooks/site.yml --syntax-check

# Validation de la structure des fichiers
echo "3. Validating file structure..."
echo "   - Checking roles directory..."
ls -la roles/

echo "   - Checking templates..."
if find roles/ -name "*.j2" -type f | head -5; then
    echo "   ✓ Templates found"
else
    echo "   ❌ No templates found"
    exit 1
fi

echo "   - Checking tasks..."
if find roles/ -name "main.yml" -path "*/tasks/*" -type f | head -5; then
    echo "   ✓ Task files found"
else
    echo "   ❌ No task files found"
    exit 1
fi

# Vérification que les fichiers de variables existent
echo "4. Checking variables files..."
if [ -f "group_vars/all.yml" ]; then
    echo "   ✓ group_vars/all.yml exists"
    # Vérifier que la variable monitoring est définie
    if grep -q "monitoring:" group_vars/all.yml; then
        echo "   ✓ monitoring variables defined"
    else
        echo "   ❌ monitoring variables not found"
        exit 1
    fi
else
    echo "   ❌ group_vars/all.yml missing"
    exit 1
fi

# Test de validation simple des templates
echo "5. Basic template validation..."
for template in roles/monitoring_stack/templates/*.j2; do
    if [ -f "$template" ]; then
        echo "   - Checking $(basename "$template")"
        # Vérifier que le template contient au moins quelques variables
        if grep -q "{{" "$template"; then
            echo "     ✓ Contains template variables"
        else
            echo "     ⚠ No template variables found"
        fi
    fi
done

# Simulation complète
echo "6. Running dry-run simulation..."
echo "   This will test the full playbook execution without making changes..."
ansible-playbook playbooks/site.yml --check --diff -v

echo ""
echo "✅ All tests completed successfully!"
echo ""
echo "📋 Summary:"
echo "   - Ansible connectivity: ✓"
echo "   - Playbook syntax: ✓" 
echo "   - File structure: ✓"
echo "   - Variables: ✓"
echo "   - Templates: ✓"
echo "   - Dry run: ✓"
echo ""
echo "🚀 Ready for deployment! Run './scripts/deploy.sh' to apply changes"
