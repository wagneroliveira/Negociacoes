ALTER TRIGGER [dbo].[tgr_transaction_api_synchronization] ON [dbo].[transaction_response]
AFTER INSERT 
AS 
BEGIN
		-- transaction and trasaction_external and pos
		DECLARE @tran_id bigint; 
		DECLARE @tran_type_id bigint; 
 		DECLARE @card_number varchar(30); 
 		DECLARE @amount decimal(21,6);
		DECLARE @data_tran datetime; 
		DECLARE @tax decimal(21,6); 
		DECLARE @created_at datetime;
		DECLARE @pos_id int; 
		DECLARE @num_installments int;
		DECLARE @pay_term_id int; 
		DECLARE @card_model_id int;
		DECLARE @card_brand_id int;
		DECLARE @currency_codes_id int; 
		DECLARE @issue_id int;
		DECLARE @serial_number varchar(255);
		DECLARE @doc_number varchar(255);
		DECLARE @acquirer_code varchar (6);
		DECLARE @ac_tran_key varchar(255);
		DECLARE @ac_log_number varchar(255);


		-- consulta os dados da transação
		SELECT 
			@tran_id = transaction_id,
			@tran_type_id = transaction_type_id,
			@amount = amount,
			@card_number = card_number,
			@data_tran = date,
			@tax = tax,
			@created_at = created_at,
			@pos_id = pos_id,
			@num_installments = number_installments,
			@pay_term_id = payment_term_id,
			@card_model_id = card_model_id,
			@card_brand_id = card_brands_id,
			@currency_codes_id = currency_codes_id,
			@issue_id = issuer_id 
		FROM transaction_1;
		
		SELECT @serial_number = serial_number, @ac_log_number = sak 
		FROM pos
		WHERE pos_id = @pos_id;
		
		-- consulta a transação na tabela 'transaction_external'
		SELECT @ac_tran_key = acquirer_transaction_key, @doc_number = document_number,  @acquirer_code = acquirer_code
		FROM transaction_external
		WHERE transaction_id = @tran_id;
	
		-- insere na tabela 'transaction_synchronization'
		INSERT INTO transaction_synchronization
		VALUES (@serial_number, @pos_id, @ac_log_number, @tran_id, @doc_number, 
				@ac_tran_key, @tran_type_id, @pay_term_id, @card_number, @amount, @num_installments, 
				@card_model_id, @card_brand_id, @currency_codes_id, @tax, @data_tran, @created_at, @acquirer_code
			   );

END;




-- dism.exe /online /cleanup-image /restorehealth

-- Get-AppXPackage -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register “$($_.InstallLocation)\AppXManifest.xml”}

