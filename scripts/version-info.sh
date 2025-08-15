#!/bin/bash

# Script para obter informações detalhadas de uma versão (Simplificado)
# Projeto BIA - Sistema de Versionamento

if [ $# -eq 0 ]; then
    echo "❌ Erro: Hash da versão não fornecido"
    echo "Uso: $0 <HASH>"
    echo ""
    echo "Exemplos:"
    echo "  $0 a1b2c3d                    # Info do commit hash"
    echo "  $0 latest                     # Info da versão latest"
    echo ""
    echo "Para ver versões disponíveis: ./scripts/list-versions.sh"
    exit 1
fi

TARGET_TAG=$1
REPOSITORY_NAME="bia"
REGION="us-east-1"
ACCOUNT_ID="039612859546"

echo "=== INFORMAÇÕES DA VERSÃO - PROJETO BIA ==="
echo "🏷️  Tag: $TARGET_TAG"
echo ""

# Obter informações da imagem no ECR
echo "📦 Informações no ECR:"
IMAGE_INFO=$(aws ecr describe-images \
    --repository-name $REPOSITORY_NAME \
    --region $REGION \
    --image-ids imageTag=$TARGET_TAG \
    --query 'imageDetails[0]' \
    --output json 2>/dev/null)

if [ $? -ne 0 ] || [ "$IMAGE_INFO" = "null" ]; then
    echo "❌ Versão $TARGET_TAG não encontrada no ECR"
    echo "💡 Use ./scripts/list-versions.sh para ver versões disponíveis"
    exit 1
fi

# Extrair informações
PUSH_DATE=$(echo $IMAGE_INFO | jq -r '.imagePushedAt')
IMAGE_SIZE=$(echo $IMAGE_INFO | jq -r '.imageSizeInBytes')
IMAGE_DIGEST=$(echo $IMAGE_INFO | jq -r '.imageDigest')
ALL_TAGS=$(echo $IMAGE_INFO | jq -r '.imageTags[]' | tr '\n' ' ')

# Converter tamanho para formato legível
IMAGE_SIZE_MB=$(echo "scale=2; $IMAGE_SIZE / 1024 / 1024" | bc)

echo "  📅 Data do Push: $PUSH_DATE"
echo "  📏 Tamanho: ${IMAGE_SIZE_MB} MB"
echo "  🔐 Digest: $IMAGE_DIGEST"
echo "  🏷️  Todas as Tags: $ALL_TAGS"

# Verificar se é a versão atual no ECS
echo ""
echo "🔍 Status no ECS:"

# Configurações ECS
CLUSTER_NAME="cluster-bia"
SERVICE_NAME="service-bia"
TASK_DEFINITION_FAMILY="task-def-bia"

# Obter task definition atual do serviço
CURRENT_SERVICE_INFO=$(aws ecs describe-services \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --region $REGION \
    --query 'services[0].taskDefinition' \
    --output text 2>/dev/null)

if [ $? -eq 0 ] && [ "$CURRENT_SERVICE_INFO" != "None" ]; then
    # Obter imagem atual da task definition
    CURRENT_IMAGE=$(aws ecs describe-task-definition \
        --task-definition $CURRENT_SERVICE_INFO \
        --region $REGION \
        --query 'taskDefinition.containerDefinitions[0].image' \
        --output text 2>/dev/null)
    
    if [[ $CURRENT_IMAGE == *":$TARGET_TAG" ]]; then
        echo "  ✅ Esta é a versão ATUAL em produção"
        echo "  🚀 Imagem: $CURRENT_IMAGE"
    else
        echo "  ⏸️  Esta NÃO é a versão atual em produção"
        echo "  🚀 Versão atual: $CURRENT_IMAGE"
        echo "  💡 Para fazer rollback: ./scripts/rollback.sh $TARGET_TAG"
    fi
else
    echo "  ❓ Não foi possível verificar o status no ECS"
fi

# Análise da tag
echo ""
echo "🔍 Análise da Tag:"

if [[ $TARGET_TAG =~ ^[a-f0-9]{7}$ ]]; then
    echo "  📌 Tipo: Commit Hash (7 caracteres)"
    echo "  🔗 Git Commit: $TARGET_TAG"
elif [[ $TARGET_TAG == "latest" ]]; then
    echo "  📌 Tipo: Latest (versão mais recente)"
else
    echo "  📌 Tipo: Tag customizada"
fi

echo ""
echo "💡 Comandos úteis:"
echo "  📋 Listar todas as versões: ./scripts/list-versions.sh"
echo "  🔄 Fazer rollback: ./scripts/rollback.sh $TARGET_TAG"
echo "  🧪 Testar localmente: docker run -p 3000:8080 $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME:$TARGET_TAG"
