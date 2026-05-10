-- ============================================================
--  ANÁLISE AVANÇADA COM SQL — Base de Dados de Vendas Angola
--  Autor  : Josemar Manuel
--  Email  : josemardiferencial@gmail.com
--  LinkedIn: @josemarmanuel
--  Data   : Abril 2026
-- ============================================================
--
--  Técnicas aplicadas:
--    - JOINs (INNER, LEFT, FULL OUTER)
--    - Subqueries e CTEs (WITH)
--    - Window Functions (ROW_NUMBER, RANK, LAG, LEAD, SUM OVER)
--    - Funções de Agregação (GROUP BY, HAVING)
--    - CASE WHEN para segmentação
--    - Análise temporal (YoY, MoM)
--    - Detecção de outliers
--
--  Compatível com: PostgreSQL · MySQL · SQLite
-- ============================================================


-- ── CRIAÇÃO DAS TABELAS ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS vendas (
    id_venda      VARCHAR(10)    PRIMARY KEY,
    data_venda    DATE           NOT NULL,
    mes           INTEGER        NOT NULL,
    trimestre     VARCHAR(2)     NOT NULL,
    id_vendedor   VARCHAR(10)    NOT NULL,
    id_produto    VARCHAR(10)    NOT NULL,
    id_regiao     VARCHAR(10)    NOT NULL,
    quantidade    INTEGER        NOT NULL,
    preco_unit    DECIMAL(12,2)  NOT NULL,
    desconto_pct  DECIMAL(5,2)   DEFAULT 0,
    total_bruto   DECIMAL(15,2)  NOT NULL,
    total_liquido DECIMAL(15,2)  NOT NULL,
    margem_pct    DECIMAL(5,2),
    lucro         DECIMAL(15,2)
);

CREATE TABLE IF NOT EXISTS vendedores (
    id_vendedor   VARCHAR(10)    PRIMARY KEY,
    nome          VARCHAR(100)   NOT NULL,
    departamento  VARCHAR(50),
    nivel         VARCHAR(20),
    regiao_base   VARCHAR(50),
    data_admissao DATE,
    salario_kz    DECIMAL(12,2)
);

CREATE TABLE IF NOT EXISTS produtos (
    id_produto    VARCHAR(10)    PRIMARY KEY,
    nome          VARCHAR(100)   NOT NULL,
    categoria     VARCHAR(50),
    subcategoria  VARCHAR(50),
    preco_lista   DECIMAL(12,2),
    custo_medio   DECIMAL(12,2),
    fornecedor    VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS regioes (
    id_regiao     VARCHAR(10)    PRIMARY KEY,
    nome          VARCHAR(50)    NOT NULL,
    provincia     VARCHAR(50),
    zona          VARCHAR(30),
    populacao_m   DECIMAL(5,2)
);


-- ════════════════════════════════════════════════════════════
-- BLOCO 1 — ANÁLISE BÁSICA COM JOINs
-- ════════════════════════════════════════════════════════════

-- 1.1 — Receita total com informações completas (INNER JOIN múltiplo)
SELECT
    v.id_venda,
    v.data_venda,
    vd.nome                         AS vendedor,
    p.nome                          AS produto,
    p.categoria,
    r.nome                          AS regiao,
    v.quantidade,
    v.preco_unit,
    v.desconto_pct,
    v.total_liquido,
    v.margem_pct,
    v.lucro
FROM vendas v
INNER JOIN vendedores vd ON v.id_vendedor = vd.id_vendedor
INNER JOIN produtos   p  ON v.id_produto  = p.id_produto
INNER JOIN regioes    r  ON v.id_regiao   = r.id_regiao
ORDER BY v.data_venda DESC
LIMIT 20;


-- 1.2 — Vendedores sem vendas (LEFT JOIN para identificar inactividade)
SELECT
    vd.id_vendedor,
    vd.nome,
    vd.nivel,
    COUNT(v.id_venda)           AS total_vendas,
    COALESCE(SUM(v.total_liquido), 0) AS receita_total
FROM vendedores vd
LEFT JOIN vendas v ON vd.id_vendedor = v.id_vendedor
GROUP BY vd.id_vendedor, vd.nome, vd.nivel
ORDER BY total_vendas ASC;


-- ════════════════════════════════════════════════════════════
-- BLOCO 2 — AGREGAÇÕES E ANÁLISE DE PERFORMANCE
-- ════════════════════════════════════════════════════════════

-- 2.1 — KPIs Globais de Vendas
SELECT
    COUNT(*)                          AS total_transacoes,
    COUNT(DISTINCT id_vendedor)       AS vendedores_activos,
    COUNT(DISTINCT id_produto)        AS produtos_vendidos,
    COUNT(DISTINCT id_regiao)         AS regioes_cobertas,
    SUM(total_liquido)                AS receita_total_kz,
    AVG(total_liquido)                AS ticket_medio_kz,
    MAX(total_liquido)                AS maior_venda_kz,
    MIN(total_liquido)                AS menor_venda_kz,
    AVG(margem_pct)                   AS margem_media_pct,
    SUM(lucro)                        AS lucro_total_kz
FROM vendas;


-- 2.2 — Ranking de vendedores (com HAVING para filtrar mínimo)
SELECT
    vd.nome                           AS vendedor,
    vd.nivel,
    COUNT(v.id_venda)                 AS num_vendas,
    SUM(v.total_liquido)              AS receita_total,
    AVG(v.total_liquido)              AS ticket_medio,
    AVG(v.margem_pct)                 AS margem_media,
    SUM(v.lucro)                      AS lucro_total,
    ROUND(
        SUM(v.total_liquido) * 100.0 /
        SUM(SUM(v.total_liquido)) OVER(), 2
    )                                 AS pct_do_total
FROM vendas v
INNER JOIN vendedores vd ON v.id_vendedor = vd.id_vendedor
GROUP BY vd.id_vendedor, vd.nome, vd.nivel
HAVING COUNT(v.id_venda) >= 5
ORDER BY receita_total DESC;


-- 2.3 — Performance por Produto e Categoria
SELECT
    p.categoria,
    p.nome                            AS produto,
    COUNT(v.id_venda)                 AS num_vendas,
    SUM(v.quantidade)                 AS qtd_total,
    SUM(v.total_liquido)              AS receita_total,
    AVG(v.preco_unit)                 AS preco_medio,
    AVG(v.desconto_pct)               AS desconto_medio_pct,
    AVG(v.margem_pct)                 AS margem_media_pct,
    ROUND(
        SUM(v.total_liquido) * 100.0 /
        SUM(SUM(v.total_liquido)) OVER (PARTITION BY p.categoria), 2
    )                                 AS pct_dentro_categoria
FROM vendas v
INNER JOIN produtos p ON v.id_produto = p.id_produto
GROUP BY p.categoria, p.id_produto, p.nome
ORDER BY p.categoria, receita_total DESC;


-- 2.4 — Análise por Região e Província
SELECT
    r.nome                            AS regiao,
    r.provincia,
    r.populacao_m,
    COUNT(v.id_venda)                 AS num_vendas,
    SUM(v.total_liquido)              AS receita_total,
    ROUND(SUM(v.total_liquido) / r.populacao_m, 0)
                                      AS receita_por_habitante_kz
FROM vendas v
INNER JOIN regioes r ON v.id_regiao = r.id_regiao
GROUP BY r.id_regiao, r.nome, r.provincia, r.populacao_m
ORDER BY receita_total DESC;


-- ════════════════════════════════════════════════════════════
-- BLOCO 3 — SUBQUERIES E CTEs
-- ════════════════════════════════════════════════════════════

-- 3.1 — CTE: Vendedores acima da média (WITH)
WITH media_vendas AS (
    SELECT AVG(total_por_vendedor) AS media_global
    FROM (
        SELECT id_vendedor, SUM(total_liquido) AS total_por_vendedor
        FROM vendas
        GROUP BY id_vendedor
    ) sub
),
receita_vendedor AS (
    SELECT
        v.id_vendedor,
        vd.nome,
        SUM(v.total_liquido)   AS receita_total,
        COUNT(v.id_venda)      AS num_vendas
    FROM vendas v
    INNER JOIN vendedores vd ON v.id_vendedor = vd.id_vendedor
    GROUP BY v.id_vendedor, vd.nome
)
SELECT
    rv.nome,
    rv.receita_total,
    rv.num_vendas,
    mv.media_global,
    ROUND((rv.receita_total - mv.media_global) * 100.0 / mv.media_global, 2)
        AS pct_acima_media
FROM receita_vendedor rv
CROSS JOIN media_vendas mv
WHERE rv.receita_total > mv.media_global
ORDER BY rv.receita_total DESC;


-- 3.2 — CTE Recursiva: Análise acumulada mensal
WITH vendas_mensais AS (
    SELECT
        mes,
        SUM(total_liquido)   AS receita_mes,
        COUNT(*)             AS num_transacoes
    FROM vendas
    GROUP BY mes
)
SELECT
    mes,
    receita_mes,
    num_transacoes,
    SUM(receita_mes) OVER (ORDER BY mes ROWS UNBOUNDED PRECEDING)
        AS receita_acumulada,
    ROUND(receita_mes * 100.0 / SUM(receita_mes) OVER (), 2)
        AS pct_do_ano
FROM vendas_mensais
ORDER BY mes;


-- 3.3 — Subquery: Produtos cujo desconto médio supera a média global
SELECT
    p.nome          AS produto,
    p.categoria,
    AVG(v.desconto_pct)  AS desconto_medio,
    (SELECT AVG(desconto_pct) FROM vendas) AS media_global_desc
FROM vendas v
INNER JOIN produtos p ON v.id_produto = p.id_produto
GROUP BY p.id_produto, p.nome, p.categoria
HAVING AVG(v.desconto_pct) > (SELECT AVG(desconto_pct) FROM vendas)
ORDER BY desconto_medio DESC;


-- ════════════════════════════════════════════════════════════
-- BLOCO 4 — WINDOW FUNCTIONS (FUNÇÕES DE JANELA)
-- ════════════════════════════════════════════════════════════

-- 4.1 — RANK: Ranking por receita dentro de cada região
SELECT
    r.nome                        AS regiao,
    vd.nome                       AS vendedor,
    SUM(v.total_liquido)          AS receita_total,
    RANK() OVER (
        PARTITION BY v.id_regiao
        ORDER BY SUM(v.total_liquido) DESC
    )                             AS rank_na_regiao,
    ROW_NUMBER() OVER (
        ORDER BY SUM(v.total_liquido) DESC
    )                             AS rank_global
FROM vendas v
INNER JOIN vendedores vd ON v.id_vendedor = vd.id_vendedor
INNER JOIN regioes    r  ON v.id_regiao   = r.id_regiao
GROUP BY v.id_regiao, r.nome, v.id_vendedor, vd.nome
ORDER BY r.nome, rank_na_regiao;


-- 4.2 — LAG/LEAD: Comparação com mês anterior (crescimento MoM)
WITH mensal AS (
    SELECT
        mes,
        SUM(total_liquido) AS receita
    FROM vendas
    GROUP BY mes
)
SELECT
    mes,
    receita                                             AS receita_atual,
    LAG(receita)  OVER (ORDER BY mes)                  AS receita_mes_anterior,
    LEAD(receita) OVER (ORDER BY mes)                  AS receita_mes_seguinte,
    ROUND(
        (receita - LAG(receita) OVER (ORDER BY mes)) * 100.0
        / NULLIF(LAG(receita) OVER (ORDER BY mes), 0), 2
    )                                                  AS crescimento_mom_pct,
    AVG(receita)  OVER (ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
                                                       AS media_movel_3m
FROM mensal
ORDER BY mes;


-- 4.3 — NTILE: Segmentação de vendedores em quartis de performance
SELECT
    vd.nome                        AS vendedor,
    SUM(v.total_liquido)           AS receita_total,
    NTILE(4) OVER (ORDER BY SUM(v.total_liquido))
                                   AS quartil,
    CASE NTILE(4) OVER (ORDER BY SUM(v.total_liquido))
        WHEN 4 THEN 'Top Performer'
        WHEN 3 THEN 'Bom Desempenho'
        WHEN 2 THEN 'Desempenho Médio'
        WHEN 1 THEN 'Necessita Apoio'
    END                            AS segmento
FROM vendas v
INNER JOIN vendedores vd ON v.id_vendedor = vd.id_vendedor
GROUP BY v.id_vendedor, vd.nome
ORDER BY receita_total DESC;


-- 4.4 — SUM/AVG OVER: Percentagem acumulada e participação
SELECT
    p.nome                         AS produto,
    SUM(v.total_liquido)           AS receita,
    ROUND(
        SUM(v.total_liquido) * 100.0 / SUM(SUM(v.total_liquido)) OVER (),
        2
    )                              AS pct_do_total,
    ROUND(
        SUM(SUM(v.total_liquido)) OVER (ORDER BY SUM(v.total_liquido) DESC
        ROWS UNBOUNDED PRECEDING) * 100.0
        / SUM(SUM(v.total_liquido)) OVER (),
        2
    )                              AS pct_acumulada
FROM vendas v
INNER JOIN produtos p ON v.id_produto = p.id_produto
GROUP BY p.id_produto, p.nome
ORDER BY receita DESC;


-- ════════════════════════════════════════════════════════════
-- BLOCO 5 — ANÁLISE AVANÇADA COM CASE WHEN
-- ════════════════════════════════════════════════════════════

-- 5.1 — Segmentação de vendas por ticket
SELECT
    CASE
        WHEN total_liquido < 50000      THEN 'Pequena  (< 50K Kz)'
        WHEN total_liquido < 200000     THEN 'Média    (50K–200K Kz)'
        WHEN total_liquido < 1000000   THEN 'Grande   (200K–1M Kz)'
        ELSE                                'Premium  (> 1M Kz)'
    END                                AS segmento_ticket,
    COUNT(*)                           AS num_vendas,
    SUM(total_liquido)                 AS receita_total,
    AVG(margem_pct)                    AS margem_media,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_transacoes
FROM vendas
GROUP BY 1
ORDER BY receita_total DESC;


-- 5.2 — Pivot manual: Receita por Produto × Trimestre
SELECT
    p.nome                       AS produto,
    SUM(CASE WHEN v.trimestre = 'T1' THEN v.total_liquido ELSE 0 END) AS T1,
    SUM(CASE WHEN v.trimestre = 'T2' THEN v.total_liquido ELSE 0 END) AS T2,
    SUM(CASE WHEN v.trimestre = 'T3' THEN v.total_liquido ELSE 0 END) AS T3,
    SUM(CASE WHEN v.trimestre = 'T4' THEN v.total_liquido ELSE 0 END) AS T4,
    SUM(v.total_liquido)         AS total_anual,
    ROUND(
        (SUM(CASE WHEN v.trimestre = 'T4' THEN v.total_liquido ELSE 0 END)
        - SUM(CASE WHEN v.trimestre = 'T1' THEN v.total_liquido ELSE 0 END))
        * 100.0
        / NULLIF(SUM(CASE WHEN v.trimestre = 'T1' THEN v.total_liquido ELSE 0 END), 0),
        2
    )                            AS crescimento_t1_t4_pct
FROM vendas v
INNER JOIN produtos p ON v.id_produto = p.id_produto
GROUP BY p.id_produto, p.nome
ORDER BY total_anual DESC;


-- ════════════════════════════════════════════════════════════
-- BLOCO 6 — DETECÇÃO DE OUTLIERS E QUALIDADE DE DADOS
-- ════════════════════════════════════════════════════════════

-- 6.1 — Outliers usando IQR (Interquartile Range)
WITH quartis AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_liquido) AS Q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_liquido) AS Q3
    FROM vendas
),
limites AS (
    SELECT
        Q1,
        Q3,
        Q3 - Q1               AS IQR,
        Q1 - 1.5 * (Q3 - Q1) AS limite_inferior,
        Q3 + 1.5 * (Q3 - Q1) AS limite_superior
    FROM quartis
)
SELECT
    v.id_venda,
    vd.nome           AS vendedor,
    p.nome            AS produto,
    v.total_liquido,
    l.limite_inferior,
    l.limite_superior,
    CASE
        WHEN v.total_liquido < l.limite_inferior THEN 'Outlier Baixo'
        WHEN v.total_liquido > l.limite_superior THEN 'Outlier Alto'
    END               AS tipo_outlier
FROM vendas v
CROSS JOIN limites l
INNER JOIN vendedores vd ON v.id_vendedor = vd.id_vendedor
INNER JOIN produtos   p  ON v.id_produto  = p.id_produto
WHERE v.total_liquido < l.limite_inferior
   OR v.total_liquido > l.limite_superior
ORDER BY v.total_liquido DESC;


-- 6.2 — Verificação de qualidade dos dados
SELECT
    'vendas'                   AS tabela,
    COUNT(*)                   AS total_linhas,
    COUNT(CASE WHEN total_liquido IS NULL THEN 1 END) AS nulos_total,
    COUNT(CASE WHEN total_liquido <= 0    THEN 1 END) AS valores_invalidos,
    COUNT(CASE WHEN data_venda IS NULL    THEN 1 END) AS datas_nulas,
    MIN(data_venda)            AS data_minima,
    MAX(data_venda)            AS data_maxima,
    COUNT(DISTINCT id_vendedor) AS vendedores_distintos,
    COUNT(DISTINCT id_produto)  AS produtos_distintos
FROM vendas;


-- ════════════════════════════════════════════════════════════
-- BLOCO 7 — VIEWS PARA REUTILIZAÇÃO
-- ════════════════════════════════════════════════════════════

-- 7.1 — View: Dashboard executivo
CREATE OR REPLACE VIEW vw_dashboard_executivo AS
SELECT
    v.mes,
    v.trimestre,
    vd.nome                        AS vendedor,
    vd.nivel,
    p.nome                         AS produto,
    p.categoria,
    r.nome                         AS regiao,
    v.quantidade,
    v.total_liquido,
    v.margem_pct,
    v.lucro,
    SUM(v.total_liquido) OVER (PARTITION BY v.mes)        AS receita_mensal,
    SUM(v.total_liquido) OVER (PARTITION BY v.trimestre)  AS receita_trimestral,
    SUM(v.total_liquido) OVER ()                          AS receita_anual,
    RANK() OVER (
        PARTITION BY v.mes ORDER BY v.total_liquido DESC
    )                              AS rank_no_mes
FROM vendas v
INNER JOIN vendedores vd ON v.id_vendedor = vd.id_vendedor
INNER JOIN produtos   p  ON v.id_produto  = p.id_produto
INNER JOIN regioes    r  ON v.id_regiao   = r.id_regiao;


-- 7.2 — View: Resumo por vendedor para Power BI
CREATE OR REPLACE VIEW vw_performance_vendedores AS
SELECT
    vd.id_vendedor,
    vd.nome,
    vd.nivel,
    COUNT(v.id_venda)                   AS num_vendas,
    SUM(v.total_liquido)                AS receita_total,
    AVG(v.total_liquido)                AS ticket_medio,
    SUM(v.lucro)                        AS lucro_total,
    AVG(v.margem_pct)                   AS margem_media,
    AVG(v.desconto_pct)                 AS desconto_medio,
    RANK() OVER (ORDER BY SUM(v.total_liquido) DESC) AS ranking_geral
FROM vendedores vd
LEFT JOIN vendas v ON vd.id_vendedor = v.id_vendedor
GROUP BY vd.id_vendedor, vd.nome, vd.nivel;


-- ════════════════════════════════════════════════════════════
-- FIM DO SCRIPT
-- Josemar Manuel · josemardiferencial@gmail.com · Abril 2026
-- ════════════════════════════════════════════════════════════
