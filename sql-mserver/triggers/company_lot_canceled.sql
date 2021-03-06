USE [tefv2_dev]
GO
/****** Object:  Trigger [dbo].[company_lot_canceled]    Script Date: 27/04/2016 16:23:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER  TRIGGER [dbo].[company_lot_canceled] ON [dbo].[transaction_status] 
 AFTER INSERT 
 AS 
 BEGIN

	DECLARE @_company_lote_id int;
	DECLARE @_status_id int;
	
	select @_status_id = status_id from inserted

	IF (@_status_id = 4)
		BEGIN
				SET @_company_lote_id = (SELECT TOP 1 cl.company_lote_id
				FROM company_lot cl
					INNER JOIN company_payment_lot cpl ON cpl.company_lote_id = cl.company_lote_id
					INNER JOIN transaction_installment ti ON ti.transaction_installment_id = cpl.transaction_installment_id
					INNER JOIN transaction_1 t ON t.transaction_id = ti.transaction_id
					INNER JOIN inserted i on i.transaction_id = t.transaction_id
					INNER JOIN transaction_status ts ON ts.transaction_id = t.transaction_id
					INNER JOIN company_lot_status cls ON cls.company_lote_id = cl.company_lote_id
				WHERE ts.status_id = 6 
                AND cls.status_id <> 13
                AND t.transaction_id = i.transaction_id
				GROUP BY cl.company_lote_id); 
		 -- Verificando se a transação já foi cancelada
		

		 IF (@_company_lote_id IS NOT NULL)
		 	BEGIN
			-- Atualizar o valor do lote, subtraindo a soma dos valor líquido das parcelas (de acordo com o lote)
				-- do valor total do lote.
			UPDATE cl1
			SET cl1.amount = cl1.amount - t1.net_amount
			FROM company_lot cl1
				INNER JOIN
				(SELECT 
				cl.company_lote_id, SUM(ti.net_amount) AS net_amount, ti.transaction_installment_id, 
				cl.amount, t.transaction_id
				FROM company_lot cl
					INNER JOIN company_payment_lot cpl ON cpl.company_lote_id = cl.company_lote_id
					INNER JOIN transaction_installment ti ON ti.transaction_installment_id = cpl.transaction_installment_id
					INNER JOIN transaction_1 t ON t.transaction_id = ti.transaction_id
					INNER JOIN inserted i on i.transaction_id = t.transaction_id
					INNER JOIN transaction_status ts ON ts.transaction_id = t.transaction_id
					INNER JOIN company_lot_status cls ON cls.company_lote_id = cl.company_lote_id
				WHERE ts.status_id = 6 
                AND cls.status_id <> 13 
				AND t.transaction_id = i.transaction_id 
				GROUP BY cl.company_lote_id, ti.net_amount, ti.transaction_installment_id, cl.amount,  t.transaction_id) t1
				ON cl1.company_lote_id = t1.company_lote_id;
				            
				END;
			-- END IF;
       
       -- REMOVE RELATION BETWEEN INSTALLMENT AND LOT
			DELETE cpl FROM company_payment_lot cpl
				INNER JOIN transaction_installment ti 
					ON ti.transaction_installment_id = cpl.transaction_installment_id
				INNER JOIN inserted i 
					ON i.transaction_id = ti.transaction_id
			WHERE ti.transaction_id = i.transaction_id;
	END;
 
		
-- END
END;
