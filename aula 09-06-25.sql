-- Transações em Banco de Dados
-- Banco de Dados II
-- Aula: 09/06/2025

CREATE TABLE contas (
	id SERIAL PRIMARY KEY,
	nome VARCHAR(100),
	saldo NUMERIC(10,2)
)

INSERT INTO contas (nome, saldo) VALUES
('Alice', 1000.00),
('Bob', 1000.00);

-- -------------------> TRANSAÇÕES COM COMMIT <-------------------

BEGIN;

UPDATE contas SET saldo = saldo - 100 WHERE nome = 'Alice'; -- Atualiza a tabela e tira R$ 100,00 da conta da Alice
UPDATE contas SET saldo = saldo + 100 WHERE nome = 'Bob';	 -- Atualiza a tabela e coloca R$ 100,00 na conta do Bob
UPDATE conta SET saldo = saldo + 100 WHERE nome = 'Bob';

COMMIT;

SELECT * FROM conta; -- Verifica o saldo

-- -------------------> ROLLBACK em caso de erro <-------------------

BEGIN;
UPDATE contas SET saldo = saldo - 50 WHERE nome = 'Alice';
--erro: tabela inexistente
INSERT INTO log_transacoes VALUES ('erro proposital');

ROLLBACK;

SELECT * FROM contas;

-- -------------------> SAVEPOINT e ROLLBACK TO <-------------------

BEGIN;

UPDATE contas SET saldo = saldo - 50 WHERE nome = 'Alice';
SAVEPOINT antes_credito;

UPDATE contas SET saldo = saldo + 50 WHERE nome = 'Bob';

-- desfaz apenas até o ponto salvo
ROLLBACK TO antes_credito;

-- prossegue
COMMIT;

-- -------------------> Concorrência e Problemas <-------------------

-- Terminal 1
BEGIN;
SELECT * FROM contas WHERE nome = 'Alice' FOR UPDATE
-- Espera alteração

-- Terminal 2
BEGIN;
UPDATE contas SET saldo = saldo - 200 WHERE nome = 'Alice';
-- Fica bloqueado até a transação do Terminal 1 finalizar
