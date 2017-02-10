CREATE PROCEDURE [dbo].[SP_ins_transaction_1]  
   @_transaction_type int,
   @_amount double precision,
   @_payment_term_id int,
   @_tax double precision,
  -- @_date datetime,
   @_ainstallment double precision,
   @_netamount double precision,
   @_datepayday date,
   @_taxinstallment double precision,
   @_numberinstallment int
AS 
BEGIN

	DECLARE @_transaction_id int;
	DECLARE @_transaction_installment_id int;

	-- insere nova transacao
	INSERT INTO [dbo].[transaction_1] 
			([transaction_type_id], [amount], [card_number], [date], [tax], [created_at], [pos_id], [number_installments],
			 [payment_term_id], [card_model_id], [card_brands_id], [currency_codes_id], [issuer_id])
			VALUES
			   (@_transaction_type, @_amount, 4096010180401305, getdate(), @_tax, @_datepayday, 1, 1, 1, 6, null, 1, null);

	SET @_transaction_id = SCOPE_IDENTITY();
	-- insere a relação da compania com transação
	INSERT INTO dbo.company_transaction (company_id, transaction_id, created_at) 
			VALUES ('3', @_transaction_id, getdate());
	
	--insere status da transação = '6' (autorizado)
	INSERT INTO dbo.transaction_status (transaction_id, created_at, status_id) 
		VALUES (@_transaction_id, getdate(), 6);

	-- inseri nova transaction_installment
	INSERT INTO [dbo].[transaction_installment]
			   ([transaction_id], [parcel_number], [amount], [net_amount], [acquirer_net_amount], [tax], [tax_acquirer],
				[payday], [acquirer_payday], [tax_type_id], [changed], [movement_date])
			 VALUES
			   (@_transaction_id, 1, @_ainstallment, @_netamount, '0.22', @_taxinstallment, '1.8', @_datepayday, null, 1, 0, null)

		SET @_transaction_installment_id = SCOPE_IDENTITY();
		
		INSERT INTO dbo.transaction_installment_status (transaction_installment_id, status_id, created_at) 
			VALUES ( @_transaction_installment_id, 6, GETDATE());

END