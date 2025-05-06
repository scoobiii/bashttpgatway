# Propostas de Otimização para Rinha de Backend - Versão Bash (leandronsp)

Baseado nas análises de Fabio Akita e nos resultados da Rinha de Backend 2023.

## Contexto

O projeto `leandronsp/rinha-backend-bash` utiliza Bash scripts, `netcat` (ou `socat`), Nginx, PgBouncer e PostgreSQL. O próprio autor reconhece as limitações de performance. As otimizações propostas visam mitigar os gargalos inerentes ao Bash e aplicar princípios de performance observados por Fabio Akita em outras implementações.

## Propostas de Otimização

1.  **Ajustes no Nginx (`nginx.conf`):**
    *   **Reduzir `worker_processes`:** Conforme observado por Akita e Leandro, um número excessivo de workers no Nginx pode sobrecarregar backends mais lentos. Reduzir para 1 ou 2 pode ser benéfico, dado que o processamento em Bash é provavelmente o gargalo.
    *   **Ajustar `worker_connections`:** Dimensionar de acordo com os workers e a capacidade esperada.
    *   **Otimizar Keep-Alive:** Ajustar `keepalive_timeout` e `keepalive_requests` para reutilizar conexões eficientemente sem sobrecarregar o backend.
    *   **Limitar Taxa (Opcional):** Se o Nginx ainda estiver enviando requisições mais rápido do que o Bash consegue processar, considerar `proxy_limit_rate` para controlar o fluxo.
    *   **Justificativa:** Evitar que o Nginx sature o backend Bash, aplicando diretamente as lições de Akita sobre balanceamento entre proxy e aplicação.

2.  **Otimização da Interação com Banco de Dados:**
    *   **Tuning do PgBouncer:** Revisar a configuração do PgBouncer (`pool_mode = transaction` é provavelmente o mais adequado). Ajustar o `default_pool_size` e `max_client_conn` conforme a capacidade do Postgres e o número de workers Nginx/Bash. Akita enfatizou a importância do tuning de pools.
    *   **Simulação de Batch Insert (`create.bash`):** Esta é a otimização com maior potencial de ganho, mas complexa em Bash. Modificar o script para:
        *   Receber a requisição.
        *   Acumular os dados de várias requisições (ex: em um arquivo temporário ou variável, com cuidado para concorrência).
        *   Periodicamente (ou por contagem), executar um único comando `psql` usando `COPY FROM STDIN` para inserir múltiplos registros de uma vez. Isso reduz drasticamente o overhead de comunicação com o banco e o número de transações.
    *   **Otimização de SQL (`init.sql` e scripts):**
        *   Garantir índices eficientes na tabela `pessoas`, especialmente em `apelido` (para unicidade) e nos campos buscados por `t` (`apelido`, `nome`, `stack`). Usar índices GIN/GiST para busca em `stack` (array) pode ser vantajoso.
        *   Minimizar consultas: Evitar consultas separadas para verificar unicidade antes do INSERT; tratar a violação de constraint (`ON CONFLICT DO NOTHING` ou similar, se aplicável).
    *   **Tuning do PostgreSQL (`postgresql.conf`):** Aplicar configurações recomendadas por Akita (se aplicável ao hardware da Rinha), como `shared_buffers`, `work_mem`, `maintenance_work_mem`, `fsync=off` (durante a carga, se a perda de dados não for crítica no contexto da Rinha), `commit_delay`, `max_wal_size`.
    *   **Justificativa:** Atacar o gargalo do banco de dados, aplicando os princípios de batching, pooling e tuning de SQL/DB observados por Akita como cruciais para performance.

3.  **Otimização dos Scripts Bash e Concorrência:**
    *   **Minimizar Chamadas a Processos Externos:** Cada chamada a `psql`, `jq`, `sed`, `awk`, `netcat` dentro do loop de tratamento de requisição gera overhead. Tentar:
        *   Usar built-ins do Bash sempre que possível.
        *   Combinar operações em uma única chamada (ex: múltiplas ações `psql -c "...; ..."`).
        *   Para JSON, `jq` é potente, mas seu custo deve ser considerado. Avaliar se a manipulação básica pode ser feita com `read` e substituição de strings do Bash.
    *   **Modelo de Concorrência:** O modelo `netcat` + `mkfifo` é inerentemente bloqueante e lento. A tentativa com `socat` + `fork` falhou. Alternativas (complexas e podem fugir do espírito "puro Bash"):
        *   Usar `xinetd` para gerenciar conexões e invocar o script handler.
        *   Criar um pequeno servidor em C (ou outra linguagem compilada) que lide com HTTP/conexões e invoque os scripts Bash apenas para a lógica, reduzindo o overhead do Bash na rede.
    *   **Justificativa:** Reduzir o custo de criação de processos e otimizar a execução dos scripts, pontos fundamentais em ambientes de alta carga.

4.  **Configuração do Docker (`docker-compose.yml`):**
    *   **Aplicar `network_mode: host`:** Usar esta configuração pode reduzir a latência de rede entre os contêineres e o host, conforme descoberto na Rinha.
    *   **Ajuste Fino de Recursos:** Rever a alocação de CPU/Memória entre os serviços (Nginx, PgBouncer, Postgres, App Bash) para garantir que o gargalo (provavelmente Bash/Postgres) tenha recursos adequados.
    *   **Justificativa:** Aplicar otimizações de infraestrutura comprovadas durante a Rinha.

## Próximos Passos

Detalhar a implementação de cada proposta, começando pelas mais impactantes e viáveis (Nginx tuning, `network_mode: host`, PgBouncer tuning, SQL indexing) e avançando para as mais complexas (Batch Insert em Bash, revisão do modelo de concorrência).

