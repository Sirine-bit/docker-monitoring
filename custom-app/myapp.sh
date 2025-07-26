#!/bin/bash

# Fonction d'aide
show_help() {
    echo "🚀 Custom Metrics App Manager"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --rebuild           Force rebuild of the image"
    echo "  --cleanup          Clean up all exited containers"
    echo "  --cleanup-all      Clean up exited containers + unused images/networks"
    echo "  --help, -h         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                 # Run with existing image"
    echo "  $0 --rebuild       # Rebuild image then run"
    echo "  $0 --cleanup       # Clean exited containers then run"
    echo "  $0 --cleanup-all   # Full cleanup then run"
    echo ""
}

# Fonction de nettoyage des conteneurs exités
cleanup_exited_containers() {
    echo "🧹 Cleaning up exited containers..."
    
    # Compter les conteneurs exités
    EXITED_COUNT=$(docker ps -a -f status=exited -q | wc -l)
    
    if [ "$EXITED_COUNT" -gt 0 ]; then
        echo "📋 Found $EXITED_COUNT exited containers"
        
        # Afficher les conteneurs qui vont être supprimés
        echo "🔍 Containers to be removed:"
        docker ps -a -f status=exited --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.CreatedAt}}"
        
        echo ""
        read -p "❓ Do you want to remove these containers? (y/N): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "🗑️  Removing exited containers..."
            docker container prune -f
            echo "✅ Exited containers cleaned up!"
        else
            echo "❌ Cleanup cancelled"
        fi
    else
        echo "✅ No exited containers found"
    fi
    echo ""
}

# Fonction de nettoyage complet
cleanup_all() {
    echo "🧹 Full Docker cleanup..."
    
    echo "📊 Current Docker usage:"
    docker system df
    echo ""
    
    read -p "❓ Proceed with full cleanup? This will remove unused images, networks, and build cache (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Removing exited containers..."
        docker container prune -f
        
        echo "🗑️  Removing unused images..."
        docker image prune -a -f
        
        echo "🗑️  Removing unused networks..."
        docker network prune -f
        
        echo "🗑️  Removing build cache..."
        docker builder prune -f
        
        echo "✅ Full cleanup completed!"
        echo "📊 New Docker usage:"
        docker system df
    else
        echo "❌ Full cleanup cancelled"
    fi
    echo ""
}

# Parser les arguments
REBUILD=false
CLEANUP=false
CLEANUP_ALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --rebuild)
            REBUILD=true
            shift
            ;;
        --cleanup)
            CLEANUP=true
            shift
            ;;
        --cleanup-all)
            CLEANUP_ALL=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Exécuter le nettoyage si demandé
if [ "$CLEANUP_ALL" = true ]; then
    cleanup_all
elif [ "$CLEANUP" = true ]; then
    cleanup_exited_containers
fi
echo "🔨 Building custom-metrics-app image..."

# Construire l'image custom si elle n'existe pas ou si on force la reconstruction
if [[ "$1" == "--rebuild" ]] || ! docker image inspect custom-metrics-app > /dev/null 2>&1; then
    echo "📦 Building custom-metrics-app image..."
    docker build -t custom-metrics-app .
    
    if [ $? -eq 0 ]; then
        echo "✅ custom-metrics-app image built successfully!"
    else
        echo "❌ Failed to build custom-metrics-app image"
        exit 1
    fi
else
    echo "📦 custom-metrics-app image already exists (use --rebuild to force rebuild)"
fi

echo ""
echo "🚀 Creating containers that expose Prometheus metrics..."

#  Votre application custom avec métriques
docker run -d \
    --label monitored=true \
    --label "image=custom-metrics-app" \
    --label "prometheus_port=8080" \
    --label "metrics_path=/metrics" \
    --network desktop_monitoring \
    --name "custom-app-$(date +%s)" \
    custom-metrics-app:latest



echo ""
echo "🎯 Your custom app exposes these metrics:"
echo "  • my_app_requests_total - Counter for HTTP requests"
echo "  • Default Node.js metrics (memory, CPU, etc.)"
echo ""
echo "🧪 Test your custom app:"
echo "  • Find container IP: docker inspect <container_name> | grep IPAddress"
echo "  • Or access via Docker network from other containers"
echo ""
echo "📊 In Prometheus UI (localhost:9090):"
echo "1. Go to Status → Targets"
echo "2. Look for 'monitored-containers-real-metrics' job" 
echo "3. Your custom-app should be UP 🟢"
echo "4. Query: my_app_requests_total"
echo ""
echo "Current monitored containers:"
docker ps --filter "label=monitored=true" --format "→ {{.Names}} ({{.Image}}) - {{.Status}}"

# Générer du trafic vers l'app custom
echo ""
echo "🔥 Generating some traffic to create metrics..."
CUSTOM_CONTAINER=$(docker ps --filter "label=monitored=true" --filter "label=image=custom-metrics-app" --format "{{.Names}}" | head -1)

if [ ! -z "$CUSTOM_CONTAINER" ]; then
    echo "📡 Sending requests to $CUSTOM_CONTAINER..."
    
    # Obtenir l'IP du conteneur
    CONTAINER_IP=$(docker inspect $CUSTOM_CONTAINER | grep '"IPAddress"' | tail -1 | cut -d'"' -f4)
    
    if [ ! -z "$CONTAINER_IP" ]; then
        echo "🌐 Container IP: $CONTAINER_IP"
        echo "🚀 Sending 10 requests to generate metrics..."
        
        for i in {1..10}; do
            docker run --rm --network desktop_monitoring alpine/curl:latest \
                curl -s "http://$CONTAINER_IP:8080/" > /dev/null
            echo -n "."
        done
        echo ""
        echo "✅ Traffic generated! Check metrics at http://$CONTAINER_IP:8080/metrics"
        echo "📊 Query 'my_app_requests_total' in Prometheus to see the counter!"
    fi
fi
