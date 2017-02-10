ALTER VIEW [dbo].[vw_transaction_installment] (
   transaction_installment_id, 
   transaction_id , 
   parcel_number,
   amount,
   net_amount, 
   acquirer_net_amount,
   tax,
   tax_acquirer,
   payday,
   acquirer_payday,
   tax_type_id,
   changed,
   movement_date)
AS 
	    select ti1.transaction_installment_id, ti1.transaction_id, ti1.parcel_number, ti1.amount
                , round(case max(ti2.parcel_number) when  1 then max(ti2.net_amount)
                    else sum(ti2.net_amount)-sum(round(ti2.net_amount,2,1))+round(max(ti2.net_amount),2,1) end,2) as net_amount
                , round(case max(ti2.parcel_number) when  1 then max(ti2.acquirer_net_amount)
                    else sum(ti2.acquirer_net_amount)-sum(round(ti2.acquirer_net_amount,2,1))+round(max(ti2.acquirer_net_amount),2,1) end,2) as acquirer_net_amount
                , ti1.tax, ti1.tax_acquirer, ti1.payday, ti1.acquirer_payday
                , ti1.tax_type_id, ti1.changed, ti1.movement_date
        from transaction_installment ti1, transaction_installment ti2
        where ti1.parcel_number = 1 and ti1.transaction_id = ti2.transaction_id
        group by ti1.transaction_installment_id, ti1.transaction_id, ti1.parcel_number, ti1.amount
                , ti1.tax, ti1.tax_acquirer, ti1.payday, ti1.acquirer_payday
                , ti1.tax_type_id, ti1.changed, ti1.movement_date
        union all
        select transaction_installment_id, transaction_id, parcel_number, amount
                , round(net_amount,2,1) as net_amount
                , round(acquirer_net_amount,2,1) as acquirer_net_amount
                , tax, tax_acquirer, payday, acquirer_payday, tax_type_id, changed, movement_date
        from transaction_installment
        where parcel_number > 1
        
GO