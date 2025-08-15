#!/bin/bash

# Script para listar versões disponíveis no ECR (Simplificado)
# Projeto BIA - Sistema de Versionamento

REPOSITORY_NAME="bia"
REGION="us-east-1"
ACCOUNT_ID="039612859546"

echo "=== VERSÕES DISPONÍVEIS NO ECR - PROJETO BIA ==="
echo "Repositório: $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME"
echo ""

# Listar todas as imagens ordenadas por data de push (mais recentes primeiro)
echo "📋 Listando versões disponíveis:"
aws ecr describe-images \
    --repository-name $REPOSITORY_NAME \
    --region $REGION \
    --query 'sort_by(imageDetails,&imagePushedAt)[*].[imageTags[0],imagePushedAt,imageSizeInBytes]' \
    --output table

echo ""
echo "🔍 Versões por commit hash (7 caracteres):"

# Versões por commit hash (7 caracteres) - filtrando apenas tags válidas
aws ecr describe-images \
    --repository-name $REPOSITORY_NAME \
    --region $REGION \
    --query 'imageDetails[?imageTags && length(imageTags[0]) == `7`].[imageTags[0],imagePushedAt]' \
    --output table

echo ""
echo "💡 Para fazer rollback: ./scripts/rollback.sh <HASH>"
echo "💡 Para ver detalhes: ./scripts/version-info.sh <HASH>"
echo "💡 Exemplo: ./version-manager.sh rollback a1b2c3d"
