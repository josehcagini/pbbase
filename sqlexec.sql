CREATE SCHEMA DBA;

CREATE TABLE DBA.TB_FUNCIONARIOS(
                                    FUN_CODIGO BIGINT PRIMARY KEY,
                                    FUN_NOME VARCHAR(45),
                                    FUN_CPF VARCHAR(45),
                                    FUN_SENHA VARCHAR(50),
                                    FUN_FUNCAO VARCHAR(50)
);

CREATE TABLE DBA.TB_VENDAS(
                              VEN_CODIGO BIGINT PRIMARY KEY,
                              VEN_HORARIO TIMESTAMP,
                              VEN_VALOR_TOTAL DECIMAL(7,2),
                              TB_FUNCIONARIOS_FUN_CODIGO BIGINT REFERENCES DBA.TB_FUNCIONARIOS(FUN_CODIGO)
);

CREATE TABLE DBA.TB_FORNECEDOR(
                                  FOR_CODIGO BIGINT PRIMARY KEY,
                                  FOR_DESCRICAO VARCHAR(45)
);

CREATE TABLE DBA.TB_PRODUTO(
                               PRO_CODIGO BIGINT PRIMARY KEY,
                               PRO_DESCRICAO VARCHAR(45),
                               PRO_VALOR DECIMAL(7,2),
                               PRO_QUANTIDADE INT,
                               TB_FORNECEDOR_FOR_CODIGO BIGINT REFERENCES DBA.TB_FORNECEDOR(FOR_CODIGO)
);

CREATE TABLE DBA.TB_ITENS(
                             ITE_CODIGO BIGINT PRIMARY KEY,
                             ITE_QUANTIDADE INT,
                             ITE_VALOR_PARCEIAL DECIMAL(7,2),
                             TB_PRODUTO_PRO_CODIGO BIGINT REFERENCES DBA.TB_PRODUTO(PRO_CODIGO),
                             TB_VENDAS_VEN_CODIGO BIGINT REFERENCES DBA.TB_VENDAS(VEN_CODIGO)
);

CREATE TABLE PUBLIC.DUMMY(
    COLDUMMY INTEGER
);

INSERT INTO PUBLIC.DUMMY VALUES (1);
SELECT * FROM PUBLIC.DUMMY;

CREATE VIEW dba.tb_fun_view as SELECT fun_codigo, fun_nome FROM DBA.tb_funcionarios WHERE UPPER(fun_funcao) = 'VENDEDOR';

CREATE SEQUENCE DBA.FUN_CODIGO;
CREATE SEQUENCE DBA.FOR_CODIGO;
CREATE SEQUENCE DBA.PRO_CODIGO;
CREATE SEQUENCE DBA.VEN_CODIGO;
CREATE SEQUENCE DBA.ITE_CODIGO;

SELECT nextval('DBA.ITE_CODIGO');

SELECT nextval('fun_codigo') AS NEXT FROM PUBLIC.DUMMY;

CREATE OR REPLACE FUNCTION DBA.NEXT_VAL( AS_SEQUENCE VARCHAR(50) )
RETURNS BIGINT
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    LI_RETORNO BIGINT;
BEGIN

    SELECT nextval(AS_SEQUENCE) INTO LI_RETORNO;

    --COMMIT;

    RETURN LI_RETORNO;
END;
$BODY$;


CREATE OR REPLACE FUNCTION DBA.CREATE_USERDB(
    v_username NAME,
    v_password TEXT)
    RETURNS smallint AS
$BODY$
DECLARE
BEGIN
    EXECUTE FORMAT('CREATE ROLE "%I" LOGIN PASSWORD %L NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION', v_username, v_password);
    -- Alternative:CREATE ROLE v_username LOGIN PASSWORD v_password NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
    RETURN 1;
    -- Simple Exception Catch
EXCEPTION
    WHEN others THEN
        RETURN 0;
END;
$BODY$
    LANGUAGE plpgsql STRICT VOLATILE SECURITY DEFINER
                     COST 100;
ALTER FUNCTION DBA.CREATE_USERDB(NAME, TEXT) OWNER TO postgres;

CREATE OR REPLACE FUNCTION DBA.DELETE_USERDB(
    v_username NAME)
    RETURNS smallint AS
$BODY$
DECLARE
BEGIN
    EXECUTE FORMAT('DROP USER "%I" ', v_username);
    RETURN 1;
    -- Simple Exception Catch
EXCEPTION
    WHEN others THEN
        RETURN 0;
END;
$BODY$
    LANGUAGE plpgsql STRICT VOLATILE SECURITY DEFINER
                     COST 100;
ALTER FUNCTION DBA.DELETE_USERDB(NAME) OWNER TO postgres;

CREATE OR REPLACE FUNCTION DBA.ALTER_USERDB(
    v_old_username NAME,
    v_new_username NAME,
    v_password TEXT)
    RETURNS smallint AS
$BODY$
DECLARE
    LS_USER NAME;
BEGIN

    IF TRIM(COALESCE(v_old_username, '')) <> '' THEN

        SELECT usename INTO LS_USER FROM pg_catalog.pg_user WHERE usename = v_old_username;

        IF TRIM(COALESCE(v_password, '')) <> '' THEN
            EXECUTE FORMAT('ALTER USER "%I" WITH PASSWORD %L', v_old_username, v_password);
        END IF;

        IF v_old_username <> v_new_username AND TRIM(COALESCE(v_new_username, '')) <> '' THEN
            EXECUTE FORMAT('ALTER ROLE "%I" RENAME TO "%I"', v_old_username, v_new_username);
        END IF;

        RETURN 1;
        -- Simple Exception Catch
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE INFO 'USUARIO NAO ENCONTRADO';
        RETURN 0;
    WHEN others THEN
        RAISE INFO '% %', SQLERRM, SQLSTATE;
        RETURN 0;
END;
$BODY$
    LANGUAGE plpgsql STRICT VOLATILE SECURITY DEFINER
                     COST 100;
ALTER FUNCTION DBA.ALTER_USERDB(NAME, NAME, TEXT) OWNER TO postgres;

CREATE OR REPLACE FUNCTION DBA.ALTERGROUP_USERDB(
    v_username NAME,
    v_new_group NAME,
    v_old_group NAME)
    RETURNS smallint AS
$BODY$
DECLARE
BEGIN

    IF TRIM(COALESCE( v_old_group ,'')) <> '' THEN
        EXECUTE FORMAT('REVOKE "%I" FROM  %I', v_old_group, v_username);
    END IF;

    IF TRIM(COALESCE( v_new_group ,'')) <> '' THEN
        EXECUTE FORMAT('GRANT "%I" TO  %I', v_new_group, v_username);
    END IF;

    RETURN 1;
    -- Simple Exception Catch
EXCEPTION
    WHEN others THEN
        RAISE INFO '% %', SQLERRM, SQLSTATE;
        RETURN 0;
END;
$BODY$
    LANGUAGE plpgsql STRICT VOLATILE SECURITY DEFINER
                     COST 100;
ALTER FUNCTION DBA.ALTERGROUP_USERDB(NAME, NAME, NAME) OWNER TO postgres;

/**/
CREATE GROUP LOGIN;
GRANT USAGE ON SCHEMA DBA TO LOGIN;
GRANT SELECT ON TABLE DBA.TB_FUNCIONARIOS TO LOGIN;
CREATE USER LOGI WITH NOCREATEDB NOCREATEROLE LOGIN PASSWORD 'jw8s0F4';
CREATE GROUP DIRETOR;
GRANT USAGE ON SCHEMA DBA TO DIRETOR;
GRANT pg_read_all_data TO DIRETOR;
GRANT pg_write_all_data TO DIRETOR;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA DBA TO DIRETOR;
GRANT EXECUTE ON FUNCTION DBA.NEXT_VAL(IN AS_SEQUENCE VARCHAR(50) ) TO DIRETOR;
GRANT EXECUTE ON FUNCTION DBA.CREATE_USERDB( IN v_username NAME, IN v_password TEXT) TO DIRETOR;
GRANT EXECUTE ON FUNCTION DBA.DELETE_USERDB( IN v_username NAME) TO DIRETOR;
GRANT EXECUTE ON FUNCTION DBA.ALTER_USERDB( IN v_old_username NAME, IN  v_new_username NAME, IN  v_password TEXT) TO DIRETOR;
CREATE GROUP GERENTE;
GRANT USAGE ON SCHEMA DBA TO GERENTE;
GRANT pg_read_all_data TO GERENTE;
GRANT pg_write_all_data TO GERENTE;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA DBA TO GERENTE;
GRANT EXECUTE ON FUNCTION DBA.NEXT_VAL(IN AS_SEQUENCE VARCHAR(50) ) TO DIRETOR;
GRANT EXECUTE ON FUNCTION DBA.CREATE_USERDB( IN v_username NAME, IN v_password TEXT) TO DIRETOR;
GRANT EXECUTE ON FUNCTION DBA.DELETE_USERDB( IN v_username NAME) TO DIRETOR;
GRANT EXECUTE ON FUNCTION DBA.ALTER_USERDB( IN v_old_username NAME, IN  v_new_username NAME, IN  v_password TEXT) TO DIRETOR;
CREATE GROUP VENDEDOR;
GRANT USAGE ON SCHEMA DBA TO VENDEDOR;
GRANT SELECT, UPDATE, DELETE, INSERT ON dba.tb_fornecedor, dba.tb_produto TO VENDEDOR;
GRANT SELECT, UPDATE, INSERT ON dba.tb_itens, dba.tb_vendas TO VENDEDOR;
GRANT USAGE, SELECT, UPDATE ON DBA.FOR_CODIGO, DBA.PRO_CODIGO, DBA.VEN_CODIGO, DBA.ITE_CODIGO TO VENDEDOR;
GRANT SELECT ON dba.tb_fun_view TO VENDEDOR;
CREATE GROUP ESTOQUISTA;
GRANT USAGE ON SCHEMA DBA TO ESTOQUISTA;
GRANT SELECT, UPDATE, DELETE, INSERT ON dba.tb_fornecedor, dba.tb_produto TO ESTOQUISTA;
GRANT USAGE, SELECT, UPDATE ON DBA.FOR_CODIGO, DBA.PRO_CODIGO TO ESTOQUISTA;
/**/

CREATE OR REPLACE FUNCTION of_processar_saldo() RETURNS trigger AS $of_processar_saldo$
DECLARE
    LI_QTD INTEGER;
BEGIN
    IF TG_OP = 'INSERT' THEN
        SELECT PRO_QUANTIDADE INTO LI_QTD FROM DBA.TB_PRODUTO WHERE PRO_CODIGO = NEW.TB_PRODUTO_PRO_CODIGO FOR UPDATE NOWAIT;

        IF NEW.ITE_QUANTIDADE > LI_QTD THEN
            RAISE EXCEPTION 'NOQTD - %', 'QUANTIDADE DE ESTOQUE INSUFICIENTE';
        END IF;

        UPDATE DBA.TB_PRODUTO SET PRO_QUANTIDADE = PRO_QUANTIDADE - NEW.ITE_QUANTIDADE
        WHERE PRO_CODIGO = NEW.TB_PRODUTO_PRO_CODIGO;

    ELSIF TG_OP = 'UPDATE' THEN

        SELECT PRO_QUANTIDADE INTO LI_QTD FROM DBA.TB_PRODUTO WHERE PRO_CODIGO = NEW.TB_PRODUTO_PRO_CODIGO FOR UPDATE NOWAIT;

        IF OLD.ITE_QUANTIDADE - NEW.ITE_QUANTIDADE > LI_QTD THEN
            RAISE EXCEPTION 'NOQTD - %', 'QUANTIDADE DE ESTOQUE INSUFICIENTE';
        END IF;

        UPDATE DBA.TB_PRODUTO SET PRO_QUANTIDADE = PRO_QUANTIDADE - (OLD.ITE_QUANTIDADE - NEW.ITE_QUANTIDADE)
        WHERE PRO_CODIGO = NEW.TB_PRODUTO_PRO_CODIGO;

    ELSIF TG_OP = 'DELETE' THEN

        SELECT PRO_QUANTIDADE INTO LI_QTD FROM DBA.TB_PRODUTO WHERE PRO_CODIGO = NEW.TB_PRODUTO_PRO_CODIGO FOR UPDATE NOWAIT;

        UPDATE DBA.TB_PRODUTO SET PRO_QUANTIDADE = PRO_QUANTIDADE + OLD.ITE_QUANTIDADE
        WHERE PRO_CODIGO = OLD.TB_PRODUTO_PRO_CODIGO;

    END IF;

    RETURN NEW;

EXCEPTION WHEN SQLSTATE 'NOQTD' THEN
    ROLLBACK;
WHEN SQLSTATE 'EMDEV' THEN
    ROLLBACK;

END;
$of_processar_saldo$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER PROCESSAR_SALDO BEFORE UPDATE OR INSERT OR DELETE
    ON DBA.tb_itens FOR EACH ROW
EXECUTE FUNCTION  of_processar_saldo();


select pwhash, crypt('mypassword', pwhash) as auth, gen
from (select crypt('mypassword', gen_salt('md5')), gen_salt('md5') as gen) as t1(pwhash)
