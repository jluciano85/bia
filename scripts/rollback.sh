#!/bin/bash

# Script para fazer rollback de versões
# Projeto BIA - Sistema de Versionamento

if [ $# -eq 0 ]; then
    echo "❌ Erro: Tag da versão não fornecida"
    echo "Uso: $0 <TAG>"
    echo ""
    echo "Exemplos:"
    echo "  $0 a1b2c3d                    # Rollback para commit hash"
    echo "  $0 main-a1b2c3d               # Rollback para versão de branch"
    echo "  $0 build-123-a1b2c3d          # Rollback para build específico"
    echo ""
    echo "Para ver versões disponíveis: ./scripts/list-versions.sh"
    exit 1
fi

TARGET_TAG=$1
REPOSITORY_NAME="bia"
REGION="us-east-1"
ACCOUNT_ID="039612859546"
REPOSITORY_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME"

# Configurações ECS
CLUSTER_NAME="cluster-bia"
SERVICE_NAME="service-bia"
TASK_DEFINITION_FAMILY="bia-tf"

echo "=== ROLLBACK DO PROJETO BIA ==="
echo "🎯 Target Tag: $TARGET_TAG"
echo "📦 Repository: $REPOSITORY_URI"
echo ""

# Verificar se a tag existe no ECR
echo "🔍 Verificando se a versão existe no ECR..."
IMAGE_EXISTS=$(aws ecr describe-images \
    --repository-name $REPOSITORY_NAME \
    --region $REGION \
    --image-ids imageTag=$TARGET_TAG \
    --query 'imageDetails[0].imageTags[0]' \
    --output text 2>/dev/null)

if [ "$IMAGE_EXISTS" = "None" ] || [ -z "$IMAGE_EXISTS" ]; then
    echo "❌ Erro: Versão $TARGET_TAG não encontrada no ECR"
    echo "💡 Use ./scripts/list-versions.sh para ver versões disponíveis"
    exit 1
fi

echo "✅ Versão encontrada no ECR"

# Confirmar rollback
echo ""
echo "⚠️  ATENÇÃO: Você está prestes a fazer rollback para a versão: $TARGET_TAG"
echo "🔄 Isso irá atualizar o serviço ECS para usar esta versão"
echo ""
read -p "Deseja continuar? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Rollback cancelado"
    exit 1
fi

echo ""
echo "🚀 Iniciando rollback..."

# Obter a task definition atual
echo "📋 Obtendo task definition atual..."
CURRENT_TASK_DEF=$(aws ecs describe-task-definition \
    --task-definition $TASK_DEFINITION_FAMILY \
    --region $REGION \
    --query 'taskDefinition' \
    --output json)

if [ $? -ne 0 ]; then
    echo "❌ Erro ao obter task definition atual"
    exit 1
fi

# Criar nova task definition com a imagem do rollback
echo "🔧 Criando nova task definition com a versão $TARGET_TAG..."

# Extrair informações necessárias e criar nova task definition
NEW_TASK_DEF=$(echo $CURRENT_TASK_DEF | jq --arg image "$REPOSITORY_URI:$TARGET_TAG" '
    .containerDefinitions[0].image = $image |
    del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .placementConstraints, .compatibilities, .registeredAt, .registeredBy)
')

# Registrar nova task definition
NEW_TASK_DEF_ARN=$(echo $NEW_TASK_DEF | aws ecs register-task-definition \
    --region $REGION \
    --cli-input-json file:///dev/stdin \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)

if [ $? -ne 0 ]; then
    echo "❌ Erro ao registrar nova task definition"
    exit 1
fi

echo "✅ Nova task definition criada: $NEW_TASK_DEF_ARN"

# Atualizar o serviço ECS
echo "🔄 Atualizando serviço ECS..."
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --task-definition $NEW_TASK_DEF_ARN \
    --region $REGION \
    --query 'service.serviceName' \
    --output text

if [ $? -ne 0 ]; then
    echo "❌ Erro ao atualizar serviço ECS"
    exit 1
fi

echo "✅ Serviço ECS atualizado com sucesso"

# Aguardar estabilização do serviço
echo "⏳ Aguardando estabilização do serviço (isso pode levar alguns minutos)..."
aws ecs wait services-stable \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --region $REGION

if [ $? -eq 0 ]; then
    echo "✅ Rollback concluído com sucesso!"
    echo "🎯 Versão atual: $TARGET_TAG"
    echo "🌐 Teste a aplicação: curl http://SEU_ALB_URL/api/versao"
else
    echo "⚠️  Rollback iniciado, mas houve timeout na estabilização"
    echo "💡 Verifique o status no console AWS ECS"
fi

echo ""
echo "📊 Status do serviço:"
aws ecs describe-services \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --region $REGION \
    --query 'services[0].[serviceName,status,runningCount,desiredCount]' \
    --output table
