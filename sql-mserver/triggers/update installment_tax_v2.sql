-- v2 - Validação de (débito e credito a vista) de acordo coma tax_acquirer 
-- (join tax_acquirer txa on txa.acquirer_id = att.acquirer_id and txa.transaction_type_id = t.transaction_type_id)

ALTER TRIGGER [dbo].[update_installmet_tax]
ON [dbo].[transaction_installment]
INSTEAD OF INSERT 
AS

BEGIN
	--  atualização dos valores e tax de acordo com o plano do EC
	DECLARE @_table_transaction_installment TABLE (
													transaction_id bigint, 
													parcel_number int , 
													amount decimal(21,6), 
													net_amount decimal(21,6), 
													acquirer_net_amout decimal(21,6), 
													tax float,
													tax_acquirer float,
													payday date,
													acquirer_payday date, 
													tax_type_id int , 
													changed smallint, 
													movement_date  datetime);
	
	INSERT INTO @_table_transaction_installment
	-- debito e credito a vista (1,2)
    SELECT 
		i.transaction_id, i.parcel_number, i.amount , (i.amount - i.amount * tx.percentage / 100), (i.amount * txa.percentage / 100), 
		tx.percentage, txa.percentage, 
		(t.date + pt.number_days), 
		(t.date + pt1.number_days), 
		ta.tax_type_id, i.changed, i.movement_date 
	 FROM company_transaction ct 
		join transaction_1 t on ct.transaction_id = t.transaction_id
		join inserted i on i.transaction_id = t.transaction_id 
		join company_tax tx on ct.company_id = tx.company_id
		join tax ta on tx.tax_id = ta.tax_id 
			and t.transaction_type_id = ta.transaction_type_id
		join transaction_type tt on t.transaction_type_id = tt.transaction_type_id 
		join payment_term pt on pt.payment_term_id = ta.payment_term_id
		join acquirer_transaction_type att on att.transaction_type_id = t.transaction_type_id
		join acquirer_payment_term2 apt on apt.transaction_type_id = att.transaction_type_id 
		join payment_term pt1 on pt1.payment_term_id = apt.payment_term_id
		join tax_acquirer txa on txa.acquirer_id = att.acquirer_id 
			and txa.transaction_type_id = t.transaction_type_id
	WHERE t.transaction_type_id in (1,2)
	UNION 
	-- credito parcelado = 3
	SELECT
		i.transaction_id, i.parcel_number, i.amount , (i.amount - i.amount * cti.percentage / 100), (i.amount * tai.percentage / 100), 
		cti.percentage,	tai.percentage, 
		(case ta.tax_type_id when 1 then (t.date + pt.number_days * i.parcel_number) when 2 then (t.date + pt.number_days) end), 
		(t.date + pt1.number_days * i.parcel_number), 
		ta.tax_type_id, i.changed, i.movement_date
	FROM company_transaction ct 
		join transaction_1 t on ct.transaction_id = t.transaction_id
		join inserted i on i.transaction_id = t.transaction_id 
		join company_tax tx on ct.company_id = tx.company_id
		join tax ta on tx.tax_id = ta.tax_id 
			and t.transaction_type_id = ta.transaction_type_id
		join transaction_type tt on t.transaction_type_id = tt.transaction_type_id 
		join payment_term pt on pt.payment_term_id = ta.payment_term_id
		join company_tax_installment cti on  cti.tax_id = ta.tax_id
			and cti.company_id = ct.company_id
		join installment_number ins on ins.number = t.number_installments
			and ins.installment_number_id = cti.installment_number_id
		join acquirer_transaction_type att on att.transaction_type_id = t.transaction_type_id
		join acquirer_payment_term2 apt on apt.transaction_type_id = att.transaction_type_id 
		join payment_term pt1 on pt1.payment_term_id = apt.payment_term_id
		join tax_acquirer txa on txa.acquirer_id= att.acquirer_id
		join tax_acquirer_installment tai on tai.tax_acquirer_id = txa.tax_acquirer_id
			and tai.installment_number_id = cti.installment_number_id 
	WHERE t.transaction_type_id = 3;

	INSERT INTO transaction_installment (transaction_id , 
										parcel_number  , 
										amount , 
										net_amount, 
										acquirer_net_amount, 
										tax ,
										tax_acquirer ,
										payday ,
										acquirer_payday , 
										tax_type_id  , 
										changed , 
										movement_date)
	SELECT * 
	FROM @_table_transaction_installment;

	-- atualiza o valor da tax na tabela 'transaction_1' de acorda com o plano específico
	UPDATE t
	SET t.tax = ti.tax, t.payment_term_id = tx.payment_term_id
	FROM transaction_1 t
		JOIN @_table_transaction_installment ti ON t.transaction_id = ti.transaction_id
		JOIN tax tx ON tx.transaction_type_id = t.transaction_type_id
		JOIN company_tax ct ON ct.tax_id = tx.tax_id
		JOIN company_transaction ctr ON ctr.company_id = ct.company_id 
			AND t.transaction_id = ctr.transaction_id;

END;

-- habilitando a trigger
 --ENABLE TRIGGER insert_lot ON transaction_installment;
