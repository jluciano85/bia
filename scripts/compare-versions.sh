#!/bin/bash

# Script para comparar duas versões (Simplificado)
# Projeto BIA - Sistema de Versionamento

if [ $# -ne 2 ]; then
    echo "❌ Erro: Dois hashes devem ser fornecidos"
    echo "Uso: $0 <HASH1> <HASH2>"
    echo ""
    echo "Exemplos:"
    echo "  $0 a1b2c3d b4c5d6e               # Comparar dois commits"
    echo "  $0 latest a1b2c3d                # Comparar latest com commit específico"
    echo ""
    exit 1
fi

TAG1=$1
TAG2=$2
REPOSITORY_NAME="bia"
REGION="us-east-1"
ACCOUNT_ID="039612859546"

echo "=== COMPARAÇÃO DE VERSÕES - PROJETO BIA ==="
echo "🔍 Comparando: $TAG1 vs $TAG2"
echo ""

# Função para obter informações de uma tag
get_image_info() {
    local tag=$1
    aws ecr describe-images \
        --repository-name $REPOSITORY_NAME \
        --region $REGION \
        --image-ids imageTag=$tag \
        --query 'imageDetails[0]' \
        --output json 2>/dev/null
}

# Obter informações das duas imagens
echo "📦 Obtendo informações das versões..."

INFO1=$(get_image_info $TAG1)
INFO2=$(get_image_info $TAG2)

# Verificar se ambas as tags existem
if [ "$INFO1" = "null" ] || [ -z "$INFO1" ]; then
    echo "❌ Versão $TAG1 não encontrada no ECR"
    exit 1
fi

if [ "$INFO2" = "null" ] || [ -z "$INFO2" ]; then
    echo "❌ Versão $TAG2 não encontrada no ECR"
    exit 1
fi

# Extrair informações
PUSH_DATE1=$(echo $INFO1 | jq -r '.imagePushedAt')
PUSH_DATE2=$(echo $INFO2 | jq -r '.imagePushedAt')
SIZE1=$(echo $INFO1 | jq -r '.imageSizeInBytes')
SIZE2=$(echo $INFO2 | jq -r '.imageSizeInBytes')
DIGEST1=$(echo $INFO1 | jq -r '.imageDigest')
DIGEST2=$(echo $INFO2 | jq -r '.imageDigest')

# Converter tamanhos para MB
SIZE1_MB=$(echo "scale=2; $SIZE1 / 1024 / 1024" | bc)
SIZE2_MB=$(echo "scale=2; $SIZE2 / 1024 / 1024" | bc)

# Calcular diferença de tamanho
SIZE_DIFF=$(echo "scale=2; $SIZE2_MB - $SIZE1_MB" | bc)

echo "📊 COMPARAÇÃO DETALHADA:"
echo ""
echo "┌─────────────────────┬─────────────────────┬─────────────────────┐"
echo "│ Atributo            │ $TAG1$(printf "%*s" $((19-${#TAG1})) "")│ $TAG2$(printf "%*s" $((19-${#TAG2})) "")│"
echo "├─────────────────────┼─────────────────────┼─────────────────────┤"
echo "│ Data do Push        │ $(echo $PUSH_DATE1 | cut -c1-19) │ $(echo $PUSH_DATE2 | cut -c1-19) │"
echo "│ Tamanho (MB)        │ $(printf "%19s" "${SIZE1_MB}") │ $(printf "%19s" "${SIZE2_MB}") │"
echo "│ Digest (primeiros 8)│ $(echo $DIGEST1 | cut -c8-15)$(printf "%*s" 11 "") │ $(echo $DIGEST2 | cut -c8-15)$(printf "%*s" 11 "") │"
echo "└─────────────────────┴─────────────────────┴─────────────────────┘"

echo ""
echo "📈 ANÁLISE:"

# Comparar datas
if [[ "$PUSH_DATE1" < "$PUSH_DATE2" ]]; then
    echo "  ⏰ $TAG2 é mais recente que $TAG1"
elif [[ "$PUSH_DATE1" > "$PUSH_DATE2" ]]; then
    echo "  ⏰ $TAG1 é mais recente que $TAG2"
else
    echo "  ⏰ Ambas as versões foram criadas no mesmo momento"
fi

# Comparar tamanhos
if (( $(echo "$SIZE_DIFF > 0" | bc -l) )); then
    echo "  📏 $TAG2 é ${SIZE_DIFF}MB maior que $TAG1"
elif (( $(echo "$SIZE_DIFF < 0" | bc -l) )); then
    SIZE_DIFF_ABS=$(echo "$SIZE_DIFF * -1" | bc)
    echo "  📏 $TAG2 é ${SIZE_DIFF_ABS}MB menor que $TAG1"
else
    echo "  📏 Ambas as versões têm o mesmo tamanho"
fi

# Verificar se são a mesma imagem
if [ "$DIGEST1" = "$DIGEST2" ]; then
    echo "  🔗 ATENÇÃO: Ambas as tags apontam para a MESMA imagem!"
else
    echo "  🔗 São imagens diferentes"
fi

# Verificar qual está em produção
echo ""
echo "🚀 STATUS EM PRODUÇÃO:"

CLUSTER_NAME="cluster-bia"
SERVICE_NAME="service-bia"

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
    
    if [[ $CURRENT_IMAGE == *":$TAG1" ]]; then
        echo "  ✅ $TAG1 está ATUALMENTE em produção"
        echo "  💡 Para atualizar para $TAG2: ./scripts/rollback.sh $TAG2"
    elif [[ $CURRENT_IMAGE == *":$TAG2" ]]; then
        echo "  ✅ $TAG2 está ATUALMENTE em produção"
        echo "  💡 Para voltar para $TAG1: ./scripts/rollback.sh $TAG1"
    else
        echo "  ❓ Nenhuma das duas versões está em produção"
        echo "  🚀 Versão atual: $CURRENT_IMAGE"
    fi
else
    echo "  ❓ Não foi possível verificar o status no ECS"
fi

echo ""
echo "💡 COMANDOS ÚTEIS:"
echo "  📋 Ver detalhes de $TAG1: ./scripts/version-info.sh $TAG1"
echo "  📋 Ver detalhes de $TAG2: ./scripts/version-info.sh $TAG2"
echo "  🔄 Deploy $TAG1: ./scripts/rollback.sh $TAG1"
echo "  🔄 Deploy $TAG2: ./scripts/rollback.sh $TAG2"
