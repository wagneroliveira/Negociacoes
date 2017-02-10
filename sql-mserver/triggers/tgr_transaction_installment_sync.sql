ALTER TRIGGER [dbo].[tgr_transaction_installment_sync] ON [dbo].[transaction_synchronization]
AFTER INSERT 
AS 
BEGIN

	-- transaction_installment and table temporary '@_table_trans_installmet_temp'
	DECLARE @tran_inst_id int;
	DECLARE @sTMP varchar(1000);
	DECLARE @tran_id bigint;
	DECLARE @p_number int;
	DECLARE @amount decimal(21,6);
	DECLARE @net_amount decimal(21,6);
	DECLARE @ac_net_amount decimal(21,6);
	DECLARE @tax float;
	DECLARE @tax_ac decimal(21,6); 
	DECLARE @payday date; 
	DECLARE @ac_payday date; 
	DECLARE @tax_type float; 
	DECLARE @changed smallint;
	DECLARE @movement_date datetime;
	DECLARE @_table_trans_installmet_temp TABLE (transaction_id bigint, parcel_number int, amount decimal(21,6), net_amount decimal(21,6), acquirer_net_amount decimal(21,6), 
												 tax float, tax_acquirer float, payday date, acquirer_payday date, tax_type_id int, changed smallint, movement_date datetime);

	-- transaction_synchronization
	DECLARE @tran_sync_id bigint;

	-- transaction_status
	DECLARE @trans_status int;

	SELECT @tran_sync_id = transaction_synchronization_id
	FROM transaction_synchronization;
	--WHERE transaction_id = @tran_id;

	PRINT '#1 transaction_synchronization_id ' + ISNULL(CONVERT(varchar(200), @tran_sync_id), 'NULL');
		
	-- #1 consulta as parcelas da transação na tabela 'transaction_installment'
 	SELECT  @tran_id = transaction_id,
			@p_number = parcel_number, 
			@amount = amount, 
			@net_amount = net_amount, 
			@ac_net_amount = acquirer_net_amount, 
			@tax = tax, 
			@tax_ac = tax_acquirer,
			@payday = payday, 
			@ac_payday = acquirer_payday, 
			@tax_type = tax_type_id
	FROM transaction_installment;

/* imprime os dados das installments
	PRINT '#2 transaction_id ' + ISNULL(CONVERT(varchar(200), @tran_id), 'NULL');
	PRINT '#3 parcel_number ' + ISNULL(CONVERT(varchar(200), @p_number), 'NULL');
	PRINT '#4 amount ' + ISNULL(CONVERT(varchar(200), @amount), 'NULL');
	PRINT '#5 net_amount ' + ISNULL(CONVERT(varchar(200), @net_amount), 'NULL');
	PRINT '#6 acquirer_net_amount ' + ISNULL(CONVERT(varchar(200), @ac_net_amount), 'NULL');
	PRINT '#7 tax_id ' + ISNULL(CONVERT(varchar(200), @tax), 'NULL');
	PRINT '#8 tax_acquirer ' + ISNULL(CONVERT(varchar(200), @tax_ac), 'NULL');
	PRINT '#9 payday ' + ISNULL(CONVERT(varchar(200), @payday), 'NULL');
	PRINT '#10 acquirer_payday ' + ISNULL(CONVERT(varchar(200), @ac_payday), 'NULL');
	PRINT '#11 tax_type_id ' + ISNULL(CONVERT(varchar(200), @tax_type), 'NULL');
*/
	-- #2 armanzena todas as parcelas da transaction_installment nessa tabela temporária '@_table_trans_installmet_temp'
	INSERT INTO @_table_trans_installmet_temp
    SELECT ti.transaction_id, ti.parcel_number, ti.amount, ti.net_amount, ti.acquirer_net_amount, ti.tax, 
		   ti.tax_acquirer, ti.payday, ti.acquirer_payday, ti.tax_type_id, ti.changed, ti.movement_date
	FROM dbo.transaction_installment ti 
	where ti.transaction_id = @tran_id;

	-- #3 insere as parcelas da transação na tabela 'transaction_installment_synchronization'
	INSERT INTO transaction_installment_synchronization (transaction_synchronization_id, parcel_number, amount, 
				net_amount, acquirer_net_amount, tax, tax_acquirer, payday, acquirer_payday, tax_type)
	SELECT @tran_sync_id, tti.parcel_number, tti.amount, tti.net_amount, tti.acquirer_net_amount, 
		   tti.tax, tti.tax_acquirer, tti.payday, tti.acquirer_payday, tti.tax_type_id
	FROM @_table_trans_installmet_temp tti;

	-- #4 imprime todas as parcelas da transação
	SET @sTMP = '#2 table_trans_installmet_temp ';
	SELECT @sTMP = @sTMP + ISNULL(CONVERT(varchar(100), tit.parcel_number), 'NULL') + ' ' 
	FROM @_table_trans_installmet_temp tit;
	PRINT @sTMP;

	-- #5 consulta o status da transação
	select @trans_status = status_id 
	from transaction_status
	where transaction_id = @tran_id;

	-- #6 insere o status da transação na tabela 'transaction_status_synchronization'
	INSERT INTO transaction_status_synchronization (transaction_status, created_at, transaction_synchronization_id)
	VALUES (@trans_status, getdate(), @tran_sync_id);

	PRINT '#3 trans_status ' + ISNULL(CONVERT(varchar(200), @trans_status), 'NULL');
END

		