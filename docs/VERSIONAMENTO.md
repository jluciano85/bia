# Sistema de Versionamento Simplificado - Projeto BIA

## Visão Geral

O sistema de versionamento do projeto BIA utiliza Git hash como base para criar versões rastreáveis e permitir rollbacks seguros. **Versão simplificada** que foca apenas no essencial: hash do commit de 7 caracteres.

## Tipos de Tags Geradas (Simplificado)

### 1. Commit Hash (Tag Principal)
- **Formato:** `a1b2c3d` (7 caracteres)
- **Uso:** Tag principal para deploy e rollback
- **Exemplo:** `f4a2b1c`

### 2. Latest
- **Formato:** `latest`
- **Uso:** Sempre aponta para a versão mais recente

## Vantagens da Simplificação

### ✅ ECR Mais Limpo
- Apenas 2 tags por deploy (hash + latest)
- Menos poluição visual no registry
- Foco no essencial

### ✅ Rastreabilidade Mantida
- Hash do commit garante rastreabilidade completa
- Vínculo direto com o código no Git
- Histórico completo preservado

### ✅ Rollback Simples
- Comando direto: `./version-manager.sh rollback a1b2c3d`
- Sem confusão entre múltiplas tags
- Processo mais rápido

## Arquivos do Sistema

### buildspec.yml (Simplificado)
Buildspec que gera apenas as tags essenciais automaticamente.

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
Lista versões disponíveis, focando em hashes de 7 caracteres.

#### scripts/rollback.sh
Faz rollback para uma versão específica.

#### scripts/version-info.sh
Mostra informações detalhadas de uma versão.

#### scripts/compare-versions.sh
Compara duas versões lado a lado.

## Como Usar

### 1. Sistema Já Ativo
O buildspec simplificado já está configurado e ativo.

### 2. Fazer Deploy
O deploy normal via push gerará automaticamente apenas as tags essenciais:

```bash
git add .
git commit -m "Minha alteração"
git push origin main
```

### 3. Listar Versões Disponíveis
```bash
./version-manager.sh list
```

### 4. Ver Informações de uma Versão
```bash
./version-manager.sh info a1b2c3d
```

### 5. Fazer Rollback
```bash
./version-manager.sh rollback a1b2c3d
```

### 6. Comparar Versões
```bash
./version-manager.sh compare latest a1b2c3d
```

### 7. Ver Versão Atual
```bash
./version-manager.sh current
```

## Fluxo de Trabalho Simplificado

### Deploy Normal
1. Desenvolvedor faz push para o repositório
2. CodePipeline detecta mudança
3. CodeBuild executa buildspec simplificado
4. Sistema gera apenas 2 tags: `<hash>` e `latest`
5. Imagem é enviada para ECR
6. ECS é atualizado com a nova versão

### Rollback
1. Identificar versão desejada: `./version-manager.sh list`
2. Executar rollback: `./version-manager.sh rollback <hash>`
3. Sistema atualiza ECS automaticamente

## Comparação: Antes vs Depois

### ❌ Sistema Anterior (Complexo)
- 5 tags por deploy
- ECR poluído com múltiplas tags
- Confusão na escolha da tag
- Mais tempo de push

### ✅ Sistema Atual (Simplificado)
- 2 tags por deploy
- ECR limpo e organizado
- Foco no hash do commit
- Push mais rápido

## Exemplo Prático

### Deploy de uma Alteração
```bash
# Commit: f70f0df
git commit -m "Alterar botão para 'Adicionar Tarefas'"
git push origin main

# Tags geradas automaticamente:
# - 039612859546.dkr.ecr.us-east-1.amazonaws.com/bia:f70f0df
# - 039612859546.dkr.ecr.us-east-1.amazonaws.com/bia:latest
```

### Rollback para Versão Anterior
```bash
# Listar versões
./version-manager.sh list

# Fazer rollback
./version-manager.sh rollback a1b2c3d

# Verificar se funcionou
./version-manager.sh current
```

## Configurações Importantes

### Variáveis do Buildspec
- `COMMIT_HASH`: Hash do commit (7 caracteres)
- `IMAGE_TAG`: Tag principal (igual ao hash)

### Configurações ECS
- **Cluster:** `cluster-bia`
- **Service:** `service-bia`
- **Task Definition:** `task-def-bia`

## Monitoramento

### Logs Importantes
- **CodeBuild:** CloudWatch Logs do projeto
- **ECS:** CloudWatch Logs do service
- **Application:** Logs da aplicação BIA

### Métricas
- Tempo de build (reduzido)
- Tamanho das imagens
- Tempo de deploy (mais rápido)

## Troubleshooting

### Erro: "Versão não encontrada"
- Verificar se o hash existe: `./version-manager.sh list`
- Confirmar que são 7 caracteres exatos

### Rollback não funciona
- Verificar permissões IAM
- Confirmar nomes do cluster e service

## Benefícios da Simplificação

### 🚀 Performance
- Push mais rápido (menos tags)
- Menos operações no ECR
- Deploy mais eficiente

### 🧹 Organização
- ECR mais limpo
- Foco no essencial
- Menos confusão

### 💡 Simplicidade
- Comandos mais diretos
- Menos opções para escolher
- Processo mais claro

### 🔍 Rastreabilidade
- Hash do commit mantém rastreabilidade completa
- Vínculo direto com o Git
- Histórico preservado

## Conclusão

O sistema simplificado mantém todas as funcionalidades essenciais de versionamento e rollback, mas com foco na simplicidade e eficiência. Ideal para o projeto BIA que prioriza clareza e facilidade de uso para fins educacionais.
