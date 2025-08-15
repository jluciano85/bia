#!/bin/bash

# Script para listar versões disponíveis no ECR
# Projeto BIA - Sistema de Versionamento

REPOSITORY_NAME="bia"
REGION="us-east-1"
ACCOUNT_ID="039612859546"

echo "=== VERSÕES DISPONÍVEIS NO ECR - PROJETO BIA ==="
echo "Repositório: $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME"
echo ""

# Listar todas as imagens ordenadas por data de push (mais recentes primeiro)
echo "📋 Listando todas as versões disponíveis:"
aws ecr describe-images \
    --repository-name $REPOSITORY_NAME \
    --region $REGION \
    --query 'sort_by(imageDetails,&imagePushedAt)[*].[imageTags[0],imagePushedAt,imageSizeInBytes]' \
    --output table

echo ""
echo "🔍 Versões por tipo de tag:"

# Versões por commit hash (7 caracteres)
echo ""
echo "📌 Por Commit Hash:"
aws ecr describe-images \
    --repository-name $REPOSITORY_NAME \
    --region $REGION \
    --query 'imageDetails[?length(imageTags[0]) == `7`].[imageTags[0],imagePushedAt]' \
    --output table

# Versões por branch
echo ""
echo "🌿 Por Branch:"
aws ecr describe-images \
    --repository-name $REPOSITORY_NAME \
    --region $REGION \
    --query 'imageDetails[?contains(imageTags[0], `-`)].[imageTags[0],imagePushedAt]' \
    --output table

# Versões por build number
echo ""
echo "🔢 Por Build Number:"
aws ecr describe-images \
    --repository-name $REPOSITORY_NAME \
    --region $REGION \
    --query 'imageDetails[?starts_with(imageTags[0], `build-`)].[imageTags[0],imagePushedAt]' \
    --output table

echo ""
echo "💡 Para fazer rollback, use: ./scripts/rollback.sh <TAG>"
echo "💡 Para ver detalhes de uma versão: ./scripts/version-info.sh <TAG>"
