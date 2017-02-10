CREATE  TRIGGER [dbo].[password_history_ins] ON [dbo].[password_history] 
FOR INSERT  AS
-- delete the first 'password' when group_permissions_users_id > 4

BEGIN
	DECLARE @firstPassword int;
	DECLARE @PasswordNumbers int;

    -- count the numbers of password inserted
    SET @PasswordNumbers = 
		(SELECT COUNT(i.group_permissions_users_id)
		  FROM password_history ph1 
		  INNER JOIN inserted i ON i.group_permissions_users_id = ph1.group_permissions_users_id);

	-- verify if the number of password > 4
	IF @PasswordNumbers > 4 
		BEGIN
			-- select the first password older
			SET @firstPassword = 
				(SELECT TOP 1 ph.password_history_id 
				 FROM password_history ph
					INNER JOIN inserted i ON i.group_permissions_users_id = ph.group_permissions_users_id
				 WHERE ph.group_permissions_users_id = i.group_permissions_users_id ORDER BY ph.password_history_id ASC); 
		        
		        -- delete the password older (mais antigo)
				DELETE ph FROM password_history ph		
				WHERE ph.password_history_id = @firstPassword; 
		END;
END;
