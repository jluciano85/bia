# Sistema de Versionamento - Projeto BIA

## Visão Geral

O sistema de versionamento do projeto BIA utiliza Git hash como base para criar versões rastreáveis e permitir rollbacks seguros. Cada deploy gera múltiplas tags no ECR para facilitar a identificação e gerenciamento de versões.

## Tipos de Tags Geradas

### 1. Commit Hash (Tag Principal)
- **Formato:** `a1b2c3d` (7 caracteres)
- **Uso:** Tag principal para deploy
- **Exemplo:** `f4a2b1c`

### 2. Branch + Commit
- **Formato:** `{branch}-{hash}`
- **Uso:** Identificar de qual branch veio o commit
- **Exemplo:** `main-f4a2b1c`, `develop-f4a2b1c`

### 3. Build Number + Commit
- **Formato:** `build-{number}-{hash}`
- **Uso:** Rastrear builds sequenciais
- **Exemplo:** `build-123-f4a2b1c`

### 4. Data/Hora + Commit
- **Formato:** `{YYYYMMDD-HHMMSS}-{hash}`
- **Uso:** Timestamp exato do build
- **Exemplo:** `20250131-143022-f4a2b1c`

### 5. Latest
- **Formato:** `latest`
- **Uso:** Sempre aponta para a versão mais recente

## Arquivos do Sistema

### buildspec-versioned.yml
Buildspec aprimorado que gera todas as tags de versionamento automaticamente.

### Scripts de Gerenciamento

#### version-manager.sh (Script Principal)
```bash
./version-manager.sh list                    # Lista todas as versões
./version-manager.sh info a1b2c3d            # Info de uma versão
./version-manager.sh rollback a1b2c3d        # Rollback para versão
./version-manager.sh compare latest a1b2c3d  # Compara versões
./version-manager.sh current                 # Versão atual
```

#### scripts/list-versions.sh
Lista todas as versões disponíveis no ECR, organizadas por tipo.

#### scripts/rollback.sh
Faz rollback para uma versão específica, atualizando o serviço ECS.

#### scripts/version-info.sh
Mostra informações detalhadas de uma versão específica.

#### scripts/compare-versions.sh
Compara duas versões lado a lado.

## Como Usar

### 1. Configurar o Pipeline
Substitua o `buildspec.yml` atual pelo `buildspec-versioned.yml`:

```bash
mv buildspec.yml buildspec-original.yml
mv buildspec-versioned.yml buildspec.yml
```

### 2. Fazer Deploy
O deploy normal via CodePipeline agora gerará automaticamente todas as tags:

```bash
git add .
git commit -m "Implementar sistema de versionamento"
git push origin main
```

### 3. Listar Versões Disponíveis
```bash
./version-manager.sh list
```

### 4. Ver Informações de uma Versão
```bash
./version-manager.sh info f4a2b1c
```

### 5. Fazer Rollback
```bash
./version-manager.sh rollback f4a2b1c
```

### 6. Comparar Versões
```bash
./version-manager.sh compare latest f4a2b1c
```

### 7. Ver Versão Atual
```bash
./version-manager.sh current
```

## Fluxo de Trabalho

### Deploy Normal
1. Desenvolvedor faz push para o repositório
2. CodePipeline detecta mudança
3. CodeBuild executa buildspec-versioned.yml
4. Sistema gera múltiplas tags baseadas no Git hash
5. Imagem é enviada para ECR com todas as tags
6. ECS é atualizado com a nova versão

### Rollback
1. Identificar versão desejada: `./version-manager.sh list`
2. Verificar informações: `./version-manager.sh info <tag>`
3. Executar rollback: `./version-manager.sh rollback <tag>`
4. Sistema atualiza ECS automaticamente
5. Aguardar estabilização do serviço

## Vantagens do Sistema

### Rastreabilidade Completa
- Cada versão é vinculada a um commit específico
- Múltiplas formas de identificar a mesma versão
- Histórico completo no ECR

### Rollback Seguro
- Rollback para qualquer versão anterior
- Verificação automática de existência da versão
- Atualização automática do ECS

### Facilidade de Uso
- Scripts automatizados para todas as operações
- Interface unificada via version-manager.sh
- Informações detalhadas de cada versão

### Compatibilidade
- Funciona com a infraestrutura ECS existente
- Não quebra o pipeline atual
- Mantém compatibilidade com `latest`

## Configurações Importantes

### Variáveis do Buildspec
- `COMMIT_HASH`: Hash do commit (7 caracteres)
- `BRANCH_NAME`: Nome do branch (sanitizado)
- `BUILD_NUMBER`: Número sequencial do build
- `BUILD_DATE`: Data/hora do build

### Configurações ECS
- **Cluster:** `bia-cluster-alb` (ou `cluster-bia`)
- **Service:** `bia-service`
- **Task Definition:** `bia-tf`

### Permissões Necessárias
- ECR: `GetAuthorizationToken`, `BatchCheckLayerAvailability`, `GetDownloadUrlForLayer`, `BatchGetImage`, `PutImage`
- ECS: `DescribeServices`, `DescribeTaskDefinition`, `RegisterTaskDefinition`, `UpdateService`

## Troubleshooting

### Erro: "Versão não encontrada"
- Verificar se a tag existe: `./version-manager.sh list`
- Confirmar ortografia da tag

### Erro: "Falha ao atualizar ECS"
- Verificar permissões IAM
- Confirmar nomes do cluster e service
- Verificar logs do CloudWatch

### Rollback não estabiliza
- Verificar health checks da aplicação
- Confirmar conectividade com RDS
- Verificar logs do container

## Monitoramento

### Logs Importantes
- **CodeBuild:** CloudWatch Logs do projeto
- **ECS:** CloudWatch Logs do service
- **Application:** Logs da aplicação BIA

### Métricas
- Tempo de build
- Tamanho das imagens
- Tempo de deploy
- Health check status

## Próximos Passos

### Melhorias Futuras
- Integração com notificações (SNS/Slack)
- Cleanup automático de versões antigas
- Métricas de rollback
- Interface web para gerenciamento

### Automação Adicional
- Rollback automático em caso de falha
- Testes automatizados pós-deploy
- Aprovações para rollback em produção
