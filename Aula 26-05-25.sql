-- Banco de Dados II
-- Prática Índices
-- Aula Indice 26-05-25

-- Criação da tabela de clientes
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,               -- ID auto-incrementado como chave primária
    nome VARCHAR(100),                   -- Nome do cliente (máx 100 caracteres)
    email VARCHAR(100) UNIQUE,           -- Email com restrição de unicidade
    cidade VARCHAR(50),                  -- Cidade do cliente
    estado VARCHAR(2)                    -- Sigla do estado (2 caracteres)
);

-- Criação da tabela de pedidos
CREATE TABLE pedidos (
    id SERIAL PRIMARY KEY,               -- ID auto-incrementado como chave primária
    cliente_id INTEGER REFERENCES clientes(id),  -- Chave estrangeira para clientes
    data_pedido DATE,                    -- Data em que o pedido foi realizado
    valor NUMERIC(10,2)                  -- Valor do pedido (10 dígitos, 2 decimais)
);

-- Popula a tabela clientes com 10 milhões de registros
INSERT INTO clientes (nome, email, cidade, estado)
SELECT
    'Cliente_' || i,                     -- Gera nome no formato Cliente_1, Cliente_2...
    'cliente' || i || '@teste.com',      -- Gera email único para cada cliente
    'Cidade_' || (i % 100),              -- Distribui cidades em 100 valores diferentes (0-99)
    CASE WHEN i % 2 = 0 THEN 'SP' ELSE 'DF' END  -- Alterna entre SP (pares) e DF (ímpares)
FROM generate_series(1, 10000000) AS s(i);  -- Gera série de 1 a 10.000.000

-- Popula a tabela pedidos com 1 milhão de registros
INSERT INTO pedidos (cliente_id, data_pedido, valor)
SELECT
    (RANDOM() * 9999999 + 1)::INTEGER,  -- Seleciona cliente_id aleatório entre 1 e 10.000.000
    CURRENT_DATE - (RANDOM() * 365)::INTEGER,  -- Data aleatória no último ano
    ROUND((RANDOM() * 1000 + 100)::numeric, 2)  -- Valor aleatório entre 100.00 e 1100.00
FROM generate_series(1, 1000000) AS s(i);  -- Gera série de 1 a 1.000.000

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
