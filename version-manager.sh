#!/bin/bash

# Script principal para gerenciamento de versões (Simplificado)
# Projeto BIA - Sistema de Versionamento

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    echo "=== GERENCIADOR DE VERSÕES - PROJETO BIA (SIMPLIFICADO) ==="
    echo ""
    echo "Uso: $0 <comando> [argumentos]"
    echo ""
    echo "📋 COMANDOS DISPONÍVEIS:"
    echo ""
    echo "  list                          Lista todas as versões disponíveis no ECR"
    echo "  info <hash>                   Mostra informações detalhadas de uma versão"
    echo "  rollback <hash>               Faz rollback para uma versão específica"
    echo "  compare <hash1> <hash2>       Compara duas versões"
    echo "  current                       Mostra a versão atual em produção"
    echo "  help                          Mostra esta ajuda"
    echo ""
    echo "📝 EXEMPLOS:"
    echo ""
    echo "  $0 list                       # Lista todas as versões"
    echo "  $0 info a1b2c3d               # Info do commit a1b2c3d"
    echo "  $0 rollback a1b2c3d           # Rollback para commit a1b2c3d"
    echo "  $0 compare latest a1b2c3d     # Compara latest com a1b2c3d"
    echo "  $0 current                    # Mostra versão atual"
    echo ""
    echo "🔧 SISTEMA DE TAGS SIMPLIFICADO:"
    echo ""
    echo "  a1b2c3d                       Commit hash (7 caracteres)"
    echo "  latest                        Versão mais recente"
    echo ""
    echo "💡 VANTAGENS DA SIMPLIFICAÇÃO:"
    echo ""
    echo "  ✅ Menos tags no ECR (mais limpo)"
    echo "  ✅ Foco no essencial (hash do commit)"
    echo "  ✅ Rastreabilidade completa mantida"
    echo "  ✅ Rollback simples e direto"
    echo ""
}

show_current() {
    echo "=== VERSÃO ATUAL EM PRODUÇÃO ==="
    
    CLUSTER_NAME="cluster-bia"
    SERVICE_NAME="service-bia"
    REGION="us-east-1"
    
    CURRENT_SERVICE_INFO=$(aws ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION \
        --query 'services[0].taskDefinition' \
        --output text 2>/dev/null)
    
    if [ $? -eq 0 ] && [ "$CURRENT_SERVICE_INFO" != "None" ]; then
        CURRENT_IMAGE=$(aws ecs describe-task-definition \
            --task-definition $CURRENT_SERVICE_INFO \
            --region $REGION \
            --query 'taskDefinition.containerDefinitions[0].image' \
            --output text 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            CURRENT_TAG=$(echo $CURRENT_IMAGE | cut -d':' -f2)
            echo "🚀 Versão atual: $CURRENT_TAG"
            echo "🖼️  Imagem: $CURRENT_IMAGE"
            echo "📋 Task Definition: $CURRENT_SERVICE_INFO"
            echo ""
            echo "💡 Para ver detalhes: $0 info $CURRENT_TAG"
        else
            echo "❌ Erro ao obter informações da task definition"
        fi
    else
        echo "❌ Erro ao obter informações do serviço ECS"
    fi
}

# Verificar se há argumentos
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

COMMAND=$1
shift

case $COMMAND in
    "list")
        $SCRIPT_DIR/scripts/list-versions.sh
        ;;
    "info")
        if [ $# -eq 0 ]; then
            echo "❌ Erro: Hash não fornecido"
            echo "Uso: $0 info <hash>"
            exit 1
        fi
        $SCRIPT_DIR/scripts/version-info.sh $1
        ;;
    "rollback")
        if [ $# -eq 0 ]; then
            echo "❌ Erro: Hash não fornecido"
            echo "Uso: $0 rollback <hash>"
            exit 1
        fi
        $SCRIPT_DIR/scripts/rollback.sh $1
        ;;
    "compare")
        if [ $# -ne 2 ]; then
            echo "❌ Erro: Dois hashes devem ser fornecidos"
            echo "Uso: $0 compare <hash1> <hash2>"
            exit 1
        fi
        $SCRIPT_DIR/scripts/compare-versions.sh $1 $2
        ;;
    "current")
        show_current
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo "❌ Comando desconhecido: $COMMAND"
        echo ""
        show_help
        exit 1
        ;;
esac
