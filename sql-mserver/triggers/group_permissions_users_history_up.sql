CREATE  TRIGGER [dbo].[group_permissions_users_history_up] ON [dbo].[group_permissions_users] 
FOR UPDATE  AS

BEGIN
    
	-- verificar se a new_password <> old_password 
	IF  (select i.password from inserted i) <> (select d.password from deleted d)
	-- inseere na tabela password_history 

	INSERT INTO password_history(password, group_permissions_users_id) 
	SELECT i.password, i.group_permissions_users_id
	from inserted i   
	
END;