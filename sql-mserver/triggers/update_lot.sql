USE [tefv2]
GO
/****** Object:  Trigger [dbo].[update_lot]    Script Date: 29/04/2016 07:52:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER  TRIGGER [dbo].[update_lot] ON [dbo].[transaction_installment] 
AFTER UPDATE
 AS 
 BEGIN

	
	 DECLARE @_transaction_status_id int;
	 DECLARE @_company_lote_id int;
	 DECLARE @_transaction_installment_id int;
	 DECLARE @_newpayday date;
	 DECLARE @_oldpayday date;
	 DECLARE @_oldnet_amount decimal(8,2);
	 DECLARE @result_lot int;

	 select @_newpayday=payday from inserted;
	 select @_oldpayday=payday from deleted;
	

	IF @_newpayday <> @_oldpayday 
	    
	-- I. UPDATE CURRENT LOT
		select @_oldnet_amount = net_amount from deleted
		-- DECREMENT AMOUNT FROM LOT
		UPDATE cl
		SET cl.amount = cl.amount - @_oldnet_amount
		FROM company_lot cl
		INNER JOIN dbo.company_payment_lot cpl
			ON cpl.company_lote_id = cl.company_lote_id
		INNER JOIN inserted i 
			ON cpl.transaction_installment_id = i.transaction_installment_id
		WHERE cpl.transaction_installment_id = i.transaction_installment_id;

		-- REMOVE RELATION BETWEEN INSTALLMENT AND LOT
		DELETE cpl FROM dbo.company_payment_lot cpl
			INNER JOIN inserted i ON i.transaction_installment_id = cpl.transaction_installment_id
			WHERE cpl.transaction_installment_id =  i.transaction_installment_id; 

	-- II. ALLOCATE LOT
	
			-- FIND AN EXISTING LOT WITH SCHEDULE == INSTALLMENT.PAYDAY
			SET @result_lot = (SELECT TOP 1 company_lote_id  FROM dbo.company_lot cl
						INNER JOIN inserted i 
							ON i.transaction_installment_id = i.transaction_installment_id
						INNER JOIN dbo.transaction_installment tri
							ON tri.transaction_installment_id = i.transaction_installment_id
						INNER JOIN dbo.company_transaction ct 
							ON ct.transaction_id = tri.transaction_id 
						AND cl.company_id = ct.company_id
						WHERE schedule_date = i.payday
						ORDER BY number DESC)	
									
				IF  (@result_lot IS NOT NULL)
			
				BEGIN
					-- UPDATE AMOUNT FROM LOT FOUND 
					UPDATE  cl
					SET cl.amount = cl.amount + i.net_amount
					FROM dbo.company_lot cl
						INNER JOIN dbo.company c 
							ON cl.company_id = c.company_id
						INNER JOIN inserted i 
							ON i.transaction_installment_id = i.transaction_installment_id
						INNER JOIN dbo.transaction_installment tri 
							ON tri.transaction_installment_id = i.transaction_installment_id	
					WHERE	cl.company_lote_id = @result_lot;	

					-- ESTABILISHES A RELATION BETWEEN INSTALLMENT AND LOT FOUND
					INSERT INTO dbo.company_payment_lot (company_lote_id, transaction_installment_id , created_at)
						SELECT @result_lot, i.transaction_installment_id, GETDATE()
						FROM inserted i  
				END;
			--END
			ELSE 
			 	BEGIN

					SET  @_company_lote_id = (SELECT TOP 1 cl.company_lote_id FROM dbo.company_lot cl
					INNER JOIN inserted i 
							ON i.transaction_installment_id = i.transaction_installment_id
					INNER JOIN dbo.transaction_installment tri
						ON tri.transaction_installment_id = i.transaction_installment_id
					INNER JOIN dbo.company_transaction ct 
						ON ct.transaction_id = tri.transaction_id
					WHERE ct.company_id = cl.company_id
					ORDER BY number DESC); 

					IF (@_company_lote_id IS NOT NULL)
					BEGIN 
						-- CREATES A NEW LOT
						INSERT INTO dbo.company_lot (number, company_id, created_at, amount, schedule_date)
						SELECT TOP 1 number + 1, ct.company_id, GETDATE(), i.net_amount, i.payday
						FROM dbo.company_lot cl
						INNER JOIN inserted i
							ON i.transaction_installment_id = i.transaction_installment_id
						INNER JOIN dbo.transaction_installment tri
							ON tri.transaction_installment_id = i.transaction_installment_id
						INNER JOIN dbo.company_transaction ct 
							ON ct.transaction_id = tri.transaction_id
						WHERE @_company_lote_id = cl.company_lote_id
						ORDER BY number DESC; 

					END;
					ELSE 
						-- CREATES A NEW COMPANY_LOT
						INSERT INTO dbo.company_lot (number, company_id, created_at, amount, schedule_date)
						SELECT 1, c.company_id, GETDATE(), i.net_amount, i.payday
						FROM dbo.company c
						INNER JOIN inserted i
							ON i.transaction_installment_id = i.transaction_installment_id				
						INNER JOIN dbo.transaction_installment tr 
							ON tr.transaction_installment_id = i.transaction_installment_id	 		
						INNER JOIN dbo.company_transaction ct 
							ON ct.transaction_id = i.transaction_id	
						WHERE ct.company_id = c.company_id; 
				 
					 	
					-- ESTABILISHES A RELATION BETWEEN INSTALLMENT AND THE NEW LOT
					SET @_company_lote_id = SCOPE_IDENTITY()
					INSERT INTO dbo.company_payment_lot (company_lote_id, transaction_installment_id , created_at)
						SELECT @_company_lote_id, i.transaction_installment_id, GETDATE()
						FROM inserted i  
					    
				 END;
			--END IF;
		  --END
		--END IF;
END;

