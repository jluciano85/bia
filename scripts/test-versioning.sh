#!/bin/bash

# Script de teste para o sistema de versionamento
# Projeto BIA - Sistema de Versionamento

echo "=== TESTE DO SISTEMA DE VERSIONAMENTO - PROJETO BIA ==="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}🔍 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Função para verificar se um comando existe
check_command() {
    if command -v $1 &> /dev/null; then
        print_success "Comando $1 encontrado"
        return 0
    else
        print_error "Comando $1 não encontrado"
        return 1
    fi
}

# Função para testar conectividade AWS
test_aws_connectivity() {
    print_step "Testando conectividade com AWS..."
    
    if aws sts get-caller-identity &> /dev/null; then
        print_success "Conectividade AWS OK"
        return 0
    else
        print_error "Falha na conectividade AWS"
        return 1
    fi
}

# Função para verificar se o ECR repository existe
check_ecr_repository() {
    print_step "Verificando repositório ECR..."
    
    if aws ecr describe-repositories --repository-names bia --region us-east-1 &> /dev/null; then
        print_success "Repositório ECR 'bia' encontrado"
        return 0
    else
        print_error "Repositório ECR 'bia' não encontrado"
        return 1
    fi
}

# Função para verificar ECS cluster
check_ecs_cluster() {
    print_step "Verificando cluster ECS..."
    
    # Tentar primeiro com ALB
    if aws ecs describe-clusters --clusters bia-cluster-alb --region us-east-1 &> /dev/null; then
        print_success "Cluster ECS 'bia-cluster-alb' encontrado"
        return 0
    # Tentar sem ALB
    elif aws ecs describe-clusters --clusters cluster-bia --region us-east-1 &> /dev/null; then
        print_success "Cluster ECS 'cluster-bia' encontrado"
        return 0
    else
        print_error "Nenhum cluster ECS encontrado (bia-cluster-alb ou cluster-bia)"
        return 1
    fi
}

# Função para verificar ECS service
check_ecs_service() {
    print_step "Verificando serviço ECS..."
    
    # Tentar primeiro com ALB
    if aws ecs describe-services --cluster bia-cluster-alb --services bia-service --region us-east-1 &> /dev/null; then
        print_success "Serviço ECS 'bia-service' encontrado no cluster bia-cluster-alb"
        return 0
    # Tentar sem ALB
    elif aws ecs describe-services --cluster cluster-bia --services bia-service --region us-east-1 &> /dev/null; then
        print_success "Serviço ECS 'bia-service' encontrado no cluster cluster-bia"
        return 0
    else
        print_error "Serviço ECS 'bia-service' não encontrado"
        return 1
    fi
}

# Função para testar scripts
test_scripts() {
    print_step "Testando scripts do sistema..."
    
    local scripts=(
        "list-versions.sh"
        "version-info.sh"
        "rollback.sh"
        "compare-versions.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -x "$SCRIPT_DIR/$script" ]; then
            print_success "Script $script é executável"
        else
            print_error "Script $script não é executável ou não existe"
        fi
    done
    
    # Testar script principal
    if [ -x "$PROJECT_DIR/version-manager.sh" ]; then
        print_success "Script principal version-manager.sh é executável"
    else
        print_error "Script principal version-manager.sh não é executável ou não existe"
    fi
}

# Função para testar buildspec
test_buildspec() {
    print_step "Verificando buildspec versionado..."
    
    if [ -f "$PROJECT_DIR/buildspec-versioned.yml" ]; then
        print_success "buildspec-versioned.yml encontrado"
        
        # Verificar se contém as variáveis de versionamento
        if grep -q "COMMIT_HASH" "$PROJECT_DIR/buildspec-versioned.yml"; then
            print_success "Variáveis de versionamento encontradas no buildspec"
        else
            print_warning "Variáveis de versionamento não encontradas no buildspec"
        fi
    else
        print_error "buildspec-versioned.yml não encontrado"
    fi
}

# Função para simular teste de versionamento
simulate_versioning() {
    print_step "Simulando sistema de versionamento..."
    
    # Simular variáveis que seriam definidas no CodeBuild
    export CODEBUILD_RESOLVED_SOURCE_VERSION="f4a2b1c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4"
    export CODEBUILD_WEBHOOK_HEAD_REF="refs/heads/main"
    export CODEBUILD_BUILD_NUMBER="123"
    
    # Extrair informações como no buildspec
    COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
    BRANCH_NAME=$(echo $CODEBUILD_WEBHOOK_HEAD_REF | sed 's/refs\/heads\///' | sed 's/[^a-zA-Z0-9]/-/g')
    BUILD_DATE=$(date +%Y%m%d-%H%M%S)
    BUILD_NUMBER=${CODEBUILD_BUILD_NUMBER:-1}
    
    # Tags que seriam geradas
    IMAGE_TAG_HASH=${COMMIT_HASH}
    IMAGE_TAG_BRANCH=${BRANCH_NAME:-main}-${COMMIT_HASH}
    IMAGE_TAG_BUILD=build-${BUILD_NUMBER}-${COMMIT_HASH}
    IMAGE_TAG_DATE=${BUILD_DATE}-${COMMIT_HASH}
    
    echo ""
    print_success "Simulação de tags geradas:"
    echo "  📌 Hash: $IMAGE_TAG_HASH"
    echo "  🌿 Branch: $IMAGE_TAG_BRANCH"
    echo "  🔢 Build: $IMAGE_TAG_BUILD"
    echo "  📅 Date: $IMAGE_TAG_DATE"
    echo "  🏷️  Latest: latest"
}

# Função principal de teste
run_tests() {
    echo "🚀 Iniciando testes do sistema de versionamento..."
    echo ""
    
    local failed_tests=0
    
    # Teste 1: Verificar comandos necessários
    print_step "TESTE 1: Verificando dependências..."
    check_command "aws" || ((failed_tests++))
    check_command "docker" || ((failed_tests++))
    check_command "jq" || ((failed_tests++))
    check_command "bc" || ((failed_tests++))
    echo ""
    
    # Teste 2: Conectividade AWS
    print_step "TESTE 2: Conectividade AWS..."
    test_aws_connectivity || ((failed_tests++))
    echo ""
    
    # Teste 3: Recursos AWS
    print_step "TESTE 3: Recursos AWS..."
    check_ecr_repository || ((failed_tests++))
    check_ecs_cluster || ((failed_tests++))
    check_ecs_service || ((failed_tests++))
    echo ""
    
    # Teste 4: Scripts
    print_step "TESTE 4: Scripts do sistema..."
    test_scripts || ((failed_tests++))
    echo ""
    
    # Teste 5: Buildspec
    print_step "TESTE 5: Configuração do buildspec..."
    test_buildspec || ((failed_tests++))
    echo ""
    
    # Teste 6: Simulação
    print_step "TESTE 6: Simulação de versionamento..."
    simulate_versioning
    echo ""
    
    # Resultado final
    echo "=== RESULTADO DOS TESTES ==="
    if [ $failed_tests -eq 0 ]; then
        print_success "Todos os testes passaram! Sistema pronto para uso."
        echo ""
        echo "💡 PRÓXIMOS PASSOS:"
        echo "  1. Substitua o buildspec.yml pelo buildspec-versioned.yml"
        echo "  2. Faça um commit e push para testar o pipeline"
        echo "  3. Use ./version-manager.sh para gerenciar versões"
    else
        print_error "$failed_tests teste(s) falharam. Verifique os erros acima."
        echo ""
        echo "💡 CORREÇÕES NECESSÁRIAS:"
        echo "  - Instale dependências faltantes"
        echo "  - Configure credenciais AWS"
        echo "  - Verifique recursos AWS existentes"
    fi
}

# Executar testes
run_tests
