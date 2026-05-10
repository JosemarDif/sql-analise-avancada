# 🗄️ Análise Avançada com SQL — Base de Dados de Vendas Angola

![SQL](https://img.shields.io/badge/SQL-PostgreSQL%20%7C%20MySQL%20%7C%20SQLite-336791?style=flat&logo=postgresql&logoColor=white)
![Status](https://img.shields.io/badge/Status-Concluído-4ADE80?style=flat)
![Queries](https://img.shields.io/badge/Queries-25%2B%20avançadas-00C2D4?style=flat)

> 25+ queries SQL avançadas para análise completa de dados de vendas: JOINs múltiplos, CTEs, Window Functions, CASE WHEN, detecção de outliers e Views reutilizáveis.

---

## 📋 Conteúdo do Script

| Bloco | Tema | Queries |
|-------|------|---------|
| 1 | JOINs e Relações | INNER JOIN, LEFT JOIN, múltiplas tabelas |
| 2 | Agregações e KPIs | GROUP BY, HAVING, métricas de negócio |
| 3 | CTEs e Subqueries | WITH, subqueries correlacionadas |
| 4 | Window Functions | RANK, LAG, LEAD, NTILE, SUM OVER |
| 5 | CASE WHEN | Segmentação, Pivot manual |
| 6 | Qualidade de Dados | Outliers IQR, verificação de nulos |
| 7 | Views | Reutilização para Power BI e relatórios |

---

## 🔧 Técnicas SQL Demonstradas

### JOINs
```sql
-- JOIN múltiplo com 4 tabelas
FROM vendas v
INNER JOIN vendedores vd ON v.id_vendedor = vd.id_vendedor
INNER JOIN produtos   p  ON v.id_produto  = p.id_produto
INNER JOIN regioes    r  ON v.id_regiao   = r.id_regiao
```

### CTEs (Common Table Expressions)
```sql
WITH media_vendas AS (
    SELECT AVG(total_por_vendedor) AS media_global
    FROM (SELECT id_vendedor, SUM(total_liquido)
          FROM vendas GROUP BY id_vendedor) sub
)
SELECT * FROM receita_vendedor
WHERE receita_total > (SELECT media_global FROM media_vendas);
```

### Window Functions
```sql
-- Ranking dentro de cada região
RANK() OVER (PARTITION BY id_regiao ORDER BY SUM(total_liquido) DESC)

-- Comparação com mês anterior
LAG(receita) OVER (ORDER BY mes)

-- Crescimento Month-over-Month
ROUND((receita - LAG(receita) OVER (ORDER BY mes)) * 100.0
      / NULLIF(LAG(receita) OVER (ORDER BY mes), 0), 2) AS crescimento_mom_pct

-- Média móvel 3 meses
AVG(receita) OVER (ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
```

### Pivot Manual com CASE WHEN
```sql
SUM(CASE WHEN trimestre = 'T1' THEN total_liquido ELSE 0 END) AS T1,
SUM(CASE WHEN trimestre = 'T2' THEN total_liquido ELSE 0 END) AS T2,
SUM(CASE WHEN trimestre = 'T3' THEN total_liquido ELSE 0 END) AS T3,
SUM(CASE WHEN trimestre = 'T4' THEN total_liquido ELSE 0 END) AS T4
```

### Detecção de Outliers (IQR)
```sql
WITH quartis AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_liquido) AS Q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_liquido) AS Q3
    FROM vendas
)
SELECT * FROM vendas
CROSS JOIN quartis
WHERE total_liquido < Q1 - 1.5*(Q3-Q1)
   OR total_liquido > Q3 + 1.5*(Q3-Q1);
```

---

## 🛠️ Como Executar

### PostgreSQL
```bash
psql -U postgres -d vendas_angola -f analise_avancada_vendas.sql
```

### MySQL
```bash
mysql -u root -p vendas_angola < analise_avancada_vendas.sql
```

### SQLite (mais simples para testar)
```bash
sqlite3 vendas.db < analise_avancada_vendas.sql
```

### Online (sem instalação)
- [DB Fiddle](https://dbfiddle.uk) — colar e executar directamente no browser
- [SQLiteOnline](https://sqliteonline.com) — SQLite no browser

---

## 📊 KPIs Calculados pelas Queries

| KPI | Query |
|-----|-------|
| Receita Total | `SUM(total_liquido)` |
| Ticket Médio | `AVG(total_liquido)` |
| Crescimento MoM | `LAG()` + cálculo percentual |
| Ranking Vendedor | `RANK() OVER (ORDER BY receita DESC)` |
| % do Total | `SUM() OVER ()` para denominador global |
| Receita Acumulada | `SUM() OVER (ROWS UNBOUNDED PRECEDING)` |
| Segmento Vendedor | `NTILE(4)` em quartis |
| Outliers | Método IQR com CTEs |

---

## 📁 Estrutura

```
SQL_Analise/
├── README.md
└── analise_avancada_vendas.sql   ← Script completo (25+ queries)
```

---

## 🏷️ Tecnologias

`SQL` `PostgreSQL` `MySQL` `SQLite` `JOINs` `CTEs` `Window Functions` `RANK` `LAG` `LEAD` `NTILE` `CASE WHEN` `GROUP BY` `HAVING` `Subqueries` `Views` `Outliers` `IQR`

---

*Autor: **Josemar Manuel** · [LinkedIn](https://linkedin.com/in/josemarmanuel) · Luanda, Angola*
