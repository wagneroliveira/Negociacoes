-- v3 - No caso somar apenas quando o tipo da tax (tax_type_id in (1-Parcelado, 2-Agrupado))

ALTER TRIGGER [dbo].[insert_lot]
ON [dbo].[transaction_installment]
AFTER INSERT
AS

-- set xact_abort off;							-- off criar transações mesmo com erro na trigger
BEGIN

	DECLARE @sTMP varchar(1000);				-- acumulador de respostas para log

	DECLARE @_table_lot_with_specified_date TABLE (company_lote_id int, [number] int, schedule_date date) 		-- tabela temporária para armazenar os ids dos lotes com data específica.
	DECLARE @_output_created_clot TABLE (company_lote_id int, [number] int, schedule_date date) 				-- tabela temporária para armazenar os ids dos lotes que foram criados.
	
	DECLARE @_last_clot_number int;				-- numeração do último lote de um EC
	DECLARE @_count_has_clot int				-- contagem do número de lotes criados
	DECLARE @_transaction_id int; 				-- id da transação referente às parcelas inseridas
	DECLARE @_company_id int;					-- id do EC referente a transação
	DECLARE @_status_id int; 					-- último status da transação
	DECLARE @_last_company_lot int;				-- último lote do EC sem data específica (caso haja)
	DECLARE @_last_lot_number int;				-- última numeração sequencial, segundo os lotes do EC
	DECLARE @_company_lot_id_created int;		-- id do lote que foi criado para atender a uma data específica (caso necessário)
	DECLARE @_cl_amount int; 					-- amount do lote antes e depois da inserção de novos pagamentos ao lote
	DECLARE @_count_company_lot int;			-- contagem de registros na tabela company_lot;
	DECLARE @_sum_net_amount decimal(21,6);		-- soma dos valores liquidos (net_amount)
	DECLARE @_tax_type INT;						-- verifica se o tipo de tax:  1- parcelado ou 2- Agrupado
	-- #1 assume-se que todas as parcelas são da mesma transação
	SET @_transaction_id = (
		SELECT TOP 1 i.transaction_id
		FROM inserted i
	);
	
	-- #2 id do EC
	SET @_company_id = (
		SELECT ct.company_id
		FROM company_transaction ct
		WHERE ct.transaction_id = @_transaction_id
	);
	
	-- #3 recuperar o último status da transação referente às parcelas que estão sendo inseridas
	SET @_status_id = (
		SELECT TOP 1
		ts.status_id
		FROM transaction_status ts
		WHERE 
		ts.transaction_id = @_transaction_id
		AND ts.transaction_status_id = 
			(SELECT MAX(transaction_status_id) 
			FROM transaction_status
			WHERE transaction_id = @_transaction_id)
	);
	
	-- DEBUG -------------------------------------------------------------------
	-- listando todas as parcelas recebidas
		
	SET @sTMP = '#0 installment_id ';
	SELECT @sTMP = @sTMP + ISNULL(CONVERT(varchar(100), i.transaction_installment_id), 'NULL') + ' ' 
	FROM inserted i;
	PRINT @sTMP;
		
	PRINT '#1 transaction_id ' + ISNULL(CONVERT(varchar(200), @_transaction_id), 'NULL');
	PRINT '#2 company_id ' + ISNULL(CONVERT(varchar(200), @_company_id), 'NULL');
	PRINT '#3 status_id '  + ISNULL(CONVERT(varchar(200), @_status_id), 'NULL');
	----------------------------------------------------------------------------

	-- prosseguir apenas se a transação tiver sido autorizada
	IF (@_status_id = 6)
	BEGIN

		------------------------------------------------------------------------------------------------------------
		-- CASO 1
		-- Encontrou lotes no dia especificado
		------------------------------------------------------------------------------------------------------------
        -- #4 recuperar os lotes referente às parcelas em uma data específica (installment.payday)
        INSERT INTO @_table_lot_with_specified_date
        SELECT distinct cl.company_lote_id, cl.number, cl.schedule_date
		FROM dbo.company_lot cl
		CROSS JOIN inserted i
		WHERE 
		cl.schedule_date = i.payday AND cl.company_id = @_company_id
		ORDER BY number DESC;

    	-- DEBUG ---------------------------------------------------------------------------------
		SET @sTMP = '#4 _table_lot_with_specified_date ';
		SELECT @sTMP = @sTMP + ISNULL(CONVERT(varchar(100), lsd.company_lote_id), 'NULL') + ' ' 
		FROM @_table_lot_with_specified_date lsd;
		PRINT @sTMP;
		------------------------------------------------------------------------------------------

		-- atualiza o `amount` de cada lote respectivo às parcelas inseridas
		-- soma os valor liquidos das installments
		SET @_sum_net_amount = (SELECT sum(i.net_amount) FROM inserted i 
								join @_table_lot_with_specified_date tl on tl.schedule_date = i.payday);	
		
		-- verifica o tipo de tax 1-parcelado or 2-agrupado
		SET @_tax_type = (select distinct tax_type_id from inserted i);		
					
		IF (@_tax_type = 1)
		BEGIN
			UPDATE cl
			SET cl.amount = cl.amount + ti.net_amount
			FROM dbo.company_lot cl 
			INNER JOIN @_table_lot_with_specified_date lsd ON lsd.company_lote_id = cl.company_lote_id
			CROSS JOIN inserted i
			INNER JOIN transaction_installment ti on i.transaction_id = ti.transaction_id;
		END;
		ELSE
		BEGIN
			update cl 
			set cl.amount = cl.amount + @_sum_net_amount
			from company_lot cl
			INNER JOIN @_table_lot_with_specified_date lsd ON lsd.company_lote_id = cl.company_lote_id;
		END;

		-- estabelece a relação entre a parcela e o lote que foi criado
		INSERT INTO dbo.company_payment_lot (company_lote_id, transaction_installment_id, created_at)
		SELECT distinct
			lsd.company_lote_id,
			i.transaction_installment_id,
			GETDATE()
		FROM @_table_lot_with_specified_date lsd
		INNER JOIN inserted i on lsd.schedule_date = i.payday;

		------------------------------------------------------------------------------------------------------------
		-- CASO 2
		-- EC não possui nenhum lote para a data especificada -- installment.payday
		------------------------------------------------------------------------------------------------------------
		-- #5 retorna os lotes do EC que a data não seja igual a installment.payday
		
		SET @_last_clot_number = (
			SELECT TOP 1 number 
			FROM company_lot cl
			WHERE cl.company_id = @_company_id
			ORDER BY number DESC
		);
		
    	-- DEBUG ---------------------------------------------------------------------------------
		PRINT '#5 _last_clot_number ' + ISNULL(CONVERT(varchar(100), @_last_clot_number), 'NULL');
		------------------------------------------------------------------------------------------

		IF @_last_clot_number IS NOT NULL 
		BEGIN

			-- #6 cria um lote para o EC, atribuindo o incremento de 1 do último lote deste EC
			INSERT INTO dbo.company_lot (number, company_id, created_at, amount, schedule_date)
			OUTPUT inserted.company_lote_id, inserted.number, inserted.schedule_date INTO @_output_created_clot
			SELECT 
				-- somando a última númeração com o número da linha 
				ROW_NUMBER() OVER (ORDER BY i.parcel_number) + @_last_clot_number,	
				@_company_id,
				GETDATE(),
				sum(i.net_amount),
				i.payday
			FROM inserted i
			WHERE i.payday NOT IN (
				SELECT cl.schedule_date
				FROM company_lot cl
				WHERE cl.company_id = @_company_id)
					AND i.tax_type_id = 1
				GROUP BY i.payday, i.parcel_number	 
			UNION
			SELECT 
				-- somando a última númeração com o número da linha 
				@_last_clot_number + 1,	
				@_company_id,
				GETDATE(),
				sum(i.net_amount),
				i.payday
			FROM inserted i
			WHERE i.payday NOT IN (
				SELECT cl.schedule_date
				FROM company_lot cl
				WHERE cl.company_id = @_company_id)
					AND i.tax_type_id = 2
				GROUP BY i.payday;	 
			
			-- DEBUG ---------------------------------------------------------------------------------
			SET @sTMP = '#6 _output_created_clot ';
			SELECT @sTMP = @sTMP + ISNULL(CONVERT(varchar(100), lsd.company_lote_id), 'NULL') + ' ' 
			FROM @_output_created_clot lsd;
			PRINT @sTMP;
			------------------------------------------------------------------------------------------
			
			-- estabelece a relação entre a parcela e o lote que foi criado
			INSERT INTO dbo.company_payment_lot (company_lote_id, transaction_installment_id, created_at)
			SELECT distinct
				o.company_lote_id,
				i.transaction_installment_id,
				GETDATE()
			FROM @_output_created_clot o
			INNER JOIN inserted i on o.schedule_date = i.payday;
		END;

		------------------------------------------------------------------------------------------------------------
		-- CASO 3
		-- EC não possui nenhum lote
		------------------------------------------------------------------------------------------------------------
		
		SET @_count_has_clot = (
			SELECT COUNT(*)
			FROM company_lot cl
			WHERE cl.company_id = @_company_id
		);
		
		--DEBUG ----------------------------------------------------------------------------------------------------
		PRINT '_count_has_clot ' + ISNULL(CONVERT(varchar(100), @_count_has_clot), 'NULL');
		------------------------------------------------------------------------------------------------------------
		
		IF @_count_has_clot = 0 
		BEGIN
			-- cria o primeiro lote do EC, com identificação (number) 1
			INSERT INTO dbo.company_lot (number, company_id, created_at, amount, schedule_date)
			OUTPUT inserted.company_lote_id, inserted.number, inserted.schedule_date INTO @_output_created_clot
			SELECT
				-- utilizando o número da linha como incremento para o número do lote
				ROW_NUMBER() OVER (ORDER BY i.transaction_installment_id),
				@_company_id,
				GETDATE(),
				sum(i.net_amount),
				i.payday
			FROM inserted i
			WHERE i.tax_type_id = 1
			GROUP BY i.payday, i.transaction_installment_id
			UNION
			SELECT
				-- utilizando o número da linha como incremento para o número do lote
				1,
				@_company_id,
				GETDATE(),
				sum(i.net_amount),
				i.payday
			FROM inserted i
			WHERE i.tax_type_id = 2
			GROUP BY i.payday;
	
			-- DEBUG ---------------------------------------------------------------------------------
			SET @sTMP = '#6 _output_created_clot ';
			SELECT @sTMP = @sTMP + ISNULL(CONVERT(varchar(100), lsd.company_lote_id), 'NULL') + ' ' 
			FROM @_output_created_clot lsd;
			PRINT @sTMP;
			------------------------------------------------------------------------------------------
	
			-- estabelece a relação entre a parcela e o lote que foi criado
			INSERT INTO dbo.company_payment_lot (company_lote_id, transaction_installment_id, created_at)
			SELECT distinct
				o.company_lote_id,
				i.transaction_installment_id,
				GETDATE()
			FROM @_output_created_clot o
			INNER JOIN inserted i on o.schedule_date = i.payday;
			------------------------------------------------------------------------------------------------------------	
		END;
	END;
END;
