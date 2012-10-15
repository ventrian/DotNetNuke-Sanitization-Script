-- #################################
-- Sanitization Script
-- Scott McCulloch (10/1/2012)
-- #################################

-- Setup utility functions

CREATE FUNCTION fn_RandomString(@length tinyint = 8)	
RETURNS varchar(255)
AS
BEGIN
-- Strings to be at least 8 characters and no more than 15 in length
SET @length =	CASE 
WHEN @length < 8 THEN 8
WHEN @length > 15 THEN 15
ELSE @length
END	

DECLARE @pool varchar(100)
DECLARE @counter int
DECLARE @rand float
DECLARE @pos int
DECLARE @rstring varchar(15)

SET @pool = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
SET @counter = 1
SET @rstring = ''

WHILE @counter <= @length
BEGIN
SET @counter = @counter + 1
SET @rand = (SELECT random from vw_random)
SET @pos = ceiling(@rand *(len(@pool)))
SET @rstring = @rstring + substring(@pool, @pos, 1)
END

RETURN (@rstring)
END
GO

CREATE VIEW vw_Random
AS
SELECT rand() as Random
GO

-- Instructions:
-- Make sure you specify the roles to Exclude (if any)
--

DECLARE @rolesToExclude varchar(max)
SET @rolesToExclude = 'Administrators'',''Some Role Name'

DECLARE @profileFieldsToExclude varchar(max)
SET @profileFieldsToExclude = 'TimeZone'',''PreferredLocale'',''PreferredTimeZone'',''Photo'

-- Updating profile Fields

EXEC
('
UPDATE
	UserProfile  
SET
	PropertyValue = dbo.fn_RandomString(8)
WHERE
	UserID NOT IN 
		(
		SELECT 
			ur.UserID
		FROM
			UserRoles ur INNER JOIN
				Roles r ON r.RoleID = ur.RoleID	
		WHERE
			RoleName IN (''' + @rolesToExclude + ''')
		GROUP BY
			ur.UserID
		) 
	AND 
	PropertyDefinitionID NOT IN (SELECT pd.PropertyDefinitionID FROM ProfilePropertyDefinition pd WHERE pd.PropertyName IN (''' + @profileFieldsToExclude + ''')) 
	AND
	PropertyValue <> ''''
')

-- Updating firstname, lastname, displayname

EXEC
('
UPDATE
	Users  
SET
	FirstName = dbo.fn_RandomString(8),
	LastName = dbo.fn_RandomString(8),
	DisplayName = dbo.fn_RandomString(8),
	UserName = dbo.fn_RandomString(8),
	Email =  (dbo.fn_RandomString(8) + ''@'' + dbo.fn_RandomString(8) + ''.com'') 
WHERE
	UserID NOT IN  
		(
		SELECT 
			ur.UserID
		FROM
			UserRoles ur INNER JOIN
				Roles r ON r.RoleID = ur.RoleID	
		WHERE
			RoleName IN (''' + @rolesToExclude + ''')
		GROUP BY
			ur.UserID
		) 
')

-- Remove utility functions

DROP VIEW vw_Random
GO
DROP FUNCTION fn_RandomString
GO

