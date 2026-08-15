Create Or Alter Procedure dbo.LMS_Auth_GetUserByUsername
    @Username Nvarchar(100)
As
Begin
    Set Nocount On;

    Select Top 1
        dbo.Users.Id,
        dbo.Users.Username,
        dbo.Users.PasswordHash,
        dbo.Users.FullName,
        dbo.Users.Email,
        dbo.Users.StudentCode,
        dbo.Users.TeacherCode,
        dbo.Users.Status,
        dbo.Roles.Code As Role
    From dbo.Users
    Inner Join dbo.UserRoles On dbo.UserRoles.UserId = dbo.Users.Id
    Inner Join dbo.Roles On dbo.Roles.Id = dbo.UserRoles.RoleId
    Where (dbo.Users.Username = @Username)
        And (dbo.Users.IsDeleted = 0)
        And (dbo.Users.Status = 'ACTIVE');
End
Go

Create Or Alter Procedure dbo.LMS_Auth_GetUserById
    @UserId Bigint
As
Begin
    Set Nocount On;

    Select Top 1
        dbo.Users.Id,
        dbo.Users.Username,
        dbo.Users.PasswordHash,
        dbo.Users.FullName,
        dbo.Users.Email,
        dbo.Users.StudentCode,
        dbo.Users.TeacherCode,
        dbo.Users.Status,
        dbo.Roles.Code As Role
    From dbo.Users
    Inner Join dbo.UserRoles On dbo.UserRoles.UserId = dbo.Users.Id
    Inner Join dbo.Roles On dbo.Roles.Id = dbo.UserRoles.RoleId
    Where (dbo.Users.Id = @UserId)
        And (dbo.Users.IsDeleted = 0)
        And (dbo.Users.Status = 'ACTIVE');
End
Go

Create Or Alter Procedure dbo.LMS_Auth_GetUserPermissions
    @UserId Bigint
As
Begin
    Set Nocount On;

    Select Distinct
        dbo.Permissions.Code
    From dbo.Permissions
    Inner Join dbo.RolePermissions On dbo.RolePermissions.PermissionId = dbo.Permissions.Id
    Inner Join dbo.UserRoles On dbo.UserRoles.RoleId = dbo.RolePermissions.RoleId
    Where (dbo.UserRoles.UserId = @UserId)
    Order By dbo.Permissions.Code;
End
Go

Create Or Alter Procedure dbo.LMS_Auth_UpdateLastLogin
    @UserId Bigint
As
Begin
    Set Nocount On;

    Update dbo.Users
    Set LastLoginAt = Sysutcdatetime()
    Where (Id = @UserId);
End
Go

Create Or Alter Procedure dbo.LMS_RefreshToken_Create
    @UserId Bigint,
    @TokenHash Varchar(128),
    @ExpiresAt Datetime2,
    @CreatedIp Varchar(64) = Null
As
Begin
    Set Nocount On;

    Insert dbo.RefreshTokens
    (
        UserId,
        TokenHash,
        ExpiresAt,
        CreatedIp
    )
    Values
    (
        @UserId,
        @TokenHash,
        @ExpiresAt,
        @CreatedIp
    );

    Select
        Cast(Scope_identity() As Bigint) As Id;
End
Go

Create Or Alter Procedure dbo.LMS_RefreshToken_Get
    @TokenHash Varchar(128)
As
Begin
    Set Nocount On;

    Select
        *
    From dbo.RefreshTokens
    Where (TokenHash = @TokenHash)
        And (IsRevoked = 0)
        And (ExpiresAt > Sysutcdatetime());
End
Go

Create Or Alter Procedure dbo.LMS_RefreshToken_Revoke
    @TokenHash Varchar(128),
    @RevokedIp Varchar(64) = Null
As
Begin
    Set Nocount On;

    Update dbo.RefreshTokens
    Set IsRevoked = 1,
        RevokedAt = Sysutcdatetime(),
        RevokedIp = @RevokedIp
    Where (TokenHash = @TokenHash);
End
Go
