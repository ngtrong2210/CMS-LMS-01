CREATE OR ALTER PROCEDURE dbo.LMS_Auth_GetUserByUsername @Username NVARCHAR(100) AS
BEGIN SET NOCOUNT ON;
 SELECT TOP 1 u.Id,u.Username,u.PasswordHash,u.FullName,u.Email,u.StudentCode,u.TeacherCode,u.Status,r.Code AS Role
 FROM dbo.Users u JOIN dbo.UserRoles ur ON ur.UserId=u.Id JOIN dbo.Roles r ON r.Id=ur.RoleId
 WHERE u.Username=@Username AND u.IsDeleted=0 AND u.Status='ACTIVE';
END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Auth_GetUserById @UserId BIGINT AS
BEGIN SET NOCOUNT ON;
 SELECT TOP 1 u.Id,u.Username,u.PasswordHash,u.FullName,u.Email,u.StudentCode,u.TeacherCode,u.Status,r.Code AS Role
 FROM dbo.Users u JOIN dbo.UserRoles ur ON ur.UserId=u.Id JOIN dbo.Roles r ON r.Id=ur.RoleId
 WHERE u.Id=@UserId AND u.IsDeleted=0 AND u.Status='ACTIVE';
END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Auth_GetUserPermissions @UserId BIGINT AS
BEGIN SET NOCOUNT ON; SELECT DISTINCT p.Code FROM dbo.Permissions p JOIN dbo.RolePermissions rp ON rp.PermissionId=p.Id JOIN dbo.UserRoles ur ON ur.RoleId=rp.RoleId WHERE ur.UserId=@UserId ORDER BY p.Code; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_Auth_UpdateLastLogin @UserId BIGINT AS
BEGIN SET NOCOUNT ON; UPDATE dbo.Users SET LastLoginAt=SYSUTCDATETIME() WHERE Id=@UserId; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_RefreshToken_Create @UserId BIGINT,@TokenHash VARCHAR(128),@ExpiresAt DATETIME2,@CreatedIp VARCHAR(64)=NULL AS
BEGIN SET NOCOUNT ON; INSERT dbo.RefreshTokens(UserId,TokenHash,ExpiresAt,CreatedIp) VALUES(@UserId,@TokenHash,@ExpiresAt,@CreatedIp); SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS Id; END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_RefreshToken_Get @TokenHash VARCHAR(128) AS
BEGIN SET NOCOUNT ON; SELECT * FROM dbo.RefreshTokens WHERE TokenHash=@TokenHash AND IsRevoked=0 AND ExpiresAt>SYSUTCDATETIME(); END
GO
CREATE OR ALTER PROCEDURE dbo.LMS_RefreshToken_Revoke @TokenHash VARCHAR(128),@RevokedIp VARCHAR(64)=NULL AS
BEGIN SET NOCOUNT ON; UPDATE dbo.RefreshTokens SET IsRevoked=1,RevokedAt=SYSUTCDATETIME(),RevokedIp=@RevokedIp WHERE TokenHash=@TokenHash; END
GO
