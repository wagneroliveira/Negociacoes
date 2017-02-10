-- atualização das triggers para alteração de plano do EC em 
-- date: 2016-12-22
-- habilitar trigger: ENABLE TRIGGER tax_history_up ON dbo.tax;

-- gravar ao atualizar na tabela 'company_tax_installment_history'

ALTER  TRIGGER [dbo].[company_tax_installment_up] ON [dbo].[company_tax_installment]
FOR UPDATE  AS
BEGIN
    
	INSERT INTO company_tax_installment_history(tax_id, installment_number_id, company_id, percentage) 
	SELECT d.tax_id, d.installment_number_id, d.company_id, d.percentage 
	FROM deleted d
END; 


-- gravar ao inserir na tabela 'company_tax_installment_history'
CREATE  TRIGGER [dbo].[company_tax_installment_ins] ON [dbo].[company_tax_installment]
FOR INSERT  AS
BEGIN
    
	INSERT INTO company_tax_installment_history(tax_id, installment_number_id, company_id, percentage) 
	SELECT i.tax_id, i.installment_number_id, i.company_id, i.percentage
	FROM inserted i
END; 

####################################################  trigger table tax #########################################################

-- ao inserir na tabela 'tax'
CREATE  TRIGGER [dbo].[tax_history_ins] ON [dbo].[tax] 
FOR INSERT  AS
BEGIN
   
	INSERT INTO tax_history(tax_id, name, percentage_default, payment_term_id, transaction_type_id, tax_type_id, category_id, percentage_minimum, percentage_maximum ) 
	SELECT i.tax_id, i.name, i.percentage_default, i.payment_term_id, i.transaction_type_id, i.tax_type_id, i.category_id, i.percentage_minimum, i.percentage_maximum
	from inserted i  

END;

-- ao atualizar dados na tabela 'tax'
ALTER  TRIGGER [dbo].[tax_history_up] ON [dbo].[tax] 
FOR UPDATE  AS
BEGIN
   
	INSERT INTO tax_history(tax_id, name, percentage_default, payment_term_id, transaction_type_id, tax_type_id, category_id, percentage_minimum, percentage_maximum ) 
	SELECT d.tax_id, d.name, d.percentage_default, d.payment_term_id, d.transaction_type_id, d.tax_type_id, d.category_id, d.percentage_minimum, d.percentage_maximum
	from deleted d  

END;


####################################################  trigger table tax_installment #########################################################
-- ao atualizar dados na tabela 'tax_installment'
ALTER  TRIGGER [dbo].[tax_installment_history_up] ON [dbo].[tax_installment] 
FOR UPDATE  AS
BEGIN
    
	INSERT INTO dbo.tax_installment_history(tax_id, installment_number_id, percentage, percentage_minimum, percentage_maximum ) 
	SELECT d.tax_id, d.installment_number_id, d.percentage, d.percentage_minimum, d.percentage_maximum
	from deleted d  

END;

-- ao inserir novos dados na tabela 'tax_installment'
CREATE  TRIGGER [dbo].[tax_installment_history_ins] ON [dbo].[tax_installment] 
FOR INSERT  AS
BEGIN
    
	INSERT INTO dbo.tax_installment_history(tax_id, installment_number_id, percentage, percentage_minimum, percentage_maximum ) 
	SELECT i.tax_id, i.installment_number_id, i.percentage, i.percentage_minimum, i.percentage_maximum
	from inserted i  

END;

####################################################  trigger table company_tax #########################################################

-- ao atualizar dados na tabela 'company_tax'
ALTER  TRIGGER [dbo].[company_tax_history_up] ON [dbo].[company_tax] 
FOR UPDATE  AS
BEGIN
    
	INSERT INTO dbo.company_tax_history(company_id, tax_id, percentage, custom) 
	 SELECT d.company_id, d.tax_id, d.percentage, d.custom 
	 from deleted d  

END; 

-- ao inserir dados na tabela 'company_tax'
CREATE  TRIGGER [dbo].[company_tax_history_ins] ON [dbo].[company_tax] 
FOR INSERT  AS
BEGIN
    
	INSERT INTO dbo.company_tax_history(company_id, tax_id, percentage, custom) 
	 SELECT i.company_id, i.tax_id, i.percentage, i.custom 
	 from inserted i  

END; 


####################################################  trigger table company_mirror_plan #########################################################
-- ao inserir dados na tabela 'company_mirror_plan'
CREATE  TRIGGER [dbo].[company_mirror_plan_history_ins] ON [dbo].[company_mirror_plan] 
FOR INSERT  AS
BEGIN
    
	INSERT INTO dbo.company_mirror_plan_history(company_id, 
												value_debit_instal,
												value_credit_cash_instal,
												value_2to6_instal,
												value_7to12_instal,
												days_debit,
												days_credit_cash,
												days_credit_2to6,
												anticipated,
												name,
												enabled_debit,
												enabled_credit_cash,
												enabled_credit_2to6,
												enabled_credit_7to12,
												enabled_anticipated) 
	 SELECT i.company_id, 
			i.value_debit_instal,
			i.value_credit_cash_instal,
			i.value_2to6_instal,
			i.value_7to12_instal,
			i.days_debit,
			i.days_credit_cash,
			i.days_credit_2to6,
			i.anticipated,
			i.name,
			i.enabled_debit,
			i.enabled_credit_cash,
			i.enabled_credit_2to6,
			i.enabled_credit_7to12,
			i.enabled_anticipated  
	 FROM inserted i  

END; 


-- ao atualizar dados na tabela 'company_mirror_plan'
CREATE  TRIGGER [dbo].[company_mirror_plan_history_up] ON [dbo].[company_mirror_plan] 
FOR UPDATE  AS
BEGIN
    
	INSERT INTO dbo.company_mirror_plan_history(company_id, 
												value_debit_instal,
												value_credit_cash_instal,
												value_2to6_instal,
												value_7to12_instal,
												days_debit,
												days_credit_cash,
												days_credit_2to6,
												anticipated,
												name,
												enabled_debit,
												enabled_credit_cash,
												enabled_credit_2to6,
												enabled_credit_7to12,
												enabled_anticipated) 
	 SELECT d.company_id, 
			d.value_debit_instal,
			d.value_credit_cash_instal,
			d.value_2to6_instal,
			d.value_7to12_instal,
			d.days_debit,
			d.days_credit_cash,
			d.days_credit_2to6,
			d.anticipated,
			d.name,
			d.enabled_debit,
			d.enabled_credit_cash,
			d.enabled_credit_2to6,
			d.enabled_credit_7to12,
			d.enabled_anticipated  
	 FROM deleted d  

END; 