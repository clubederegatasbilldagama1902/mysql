-- Banco de Dados II
-- Prática Índices
-- Data: 02-06-2025

CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    cidade VARCHAR(50),
    estado VARCHAR(2)
);

CREATE TABLE pedidos (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER REFERENCES clientes(id),
    data_pedido DATE,
    valor NUMERIC(10,2)
);

--popula a tabela clientes
INSERT INTO clientes (nome, email, cidade, estado)
SELECT
    'Cliente_' || i,
    'cliente' || i || '@teste.com',
    'Cidade_' || (i % 100),
    CASE WHEN i % 2 = 0 THEN 'SP' ELSE 'DF' END
FROM generate_series(1, 10000000) AS s(i);

--popula a tabela pedidos
INSERT INTO pedidos (cliente_id, data_pedido, valor)
SELECT
    (RANDOM() * 9999999 + 1)::INTEGER,  -- cliente_id aleatório
    CURRENT_DATE - (RANDOM() * 365)::INTEGER,
    ROUND((RANDOM() * 1000 + 100)::numeric, 2)
FROM generate_series(1, 1000000) AS s(i);

-- Consulta para analisar desempenho (com erro proposital para demonstração)
-- OBS: Há um erro no nome da coluna (deveria ser cliente_id em vez de clientes_id)
EXPLAIN ANALYZE
SELECT c.nome, p.valor
FROM pedidos p
JOIN clientes c ON c.id = p.clientes_id  -- ERRO: nome incorreto da coluna
WHERE c.email ilike 'cliete50000@teste.com';  -- Busca case-insensitive por email

-- Cria índices para melhorar performance das consultas
CREATE INDEX idx_clientes_email ON clientes(email);      -- Índice no campo email
CREATE INDEX idx_pedidos_cliente_id ON pedidos(cliente_id);  -- Índice na chave estrangeira

CREATE EXTENSION IF NOT EXISTS pg_trgm;

SELECT show_trgm('cliente10@teste.com');

CREATE INDEX idx_email_trgm ON clientes 
USING gin (email gin_trgm_ops);

drop index idx_email_trgm;

EXPLAIN ANALYZE
SELECT c.nome, p.valor
FROM pedidos p, clientes c
WHERE c.id = p.cliente_id
	AND (c.email = 'cliente10@teste.com'
	OR p.data_pedido = '2025-06-02');
