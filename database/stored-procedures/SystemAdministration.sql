Create Or Alter Procedure dbo.SYS_User_GetList
    @Search Nvarchar(250) = Null,
    @RoleCode Varchar(50) = Null,
    @Status Varchar(30) = Null,
    @Page Int = 1,
    @PageSize Int = 20
As
Begin
    Set Nocount On;

    Select
        SYS_Users.UserID,
        SYS_Users.Username,
        SYS_Users.FullName,
        SYS_Users.Email,
        SYS_Users.StudentCode,
        SYS_Users.TeacherCode,
        SYS_Users.AvatarUrl,
        SYS_Users.Status,
        SYS_Users.LastLoginAt,
        SYS_Users.CreatedAt,
        Isnull
        (
            (
                Select String_Agg(SYS_Roles.Code, ',') Within Group (Order By SYS_Roles.Code)
                From dbo.SYS_UserRoles
                Inner Join dbo.SYS_Roles On SYS_Roles.RoleID = SYS_UserRoles.RoleID
                Where (SYS_UserRoles.UserID = SYS_Users.UserID)
            ),
            ''
        ) As RoleCodes,
        Isnull
        (
            (
                Select String_Agg(SYS_Roles.Name, N', ') Within Group (Order By SYS_Roles.Name)
                From dbo.SYS_UserRoles
                Inner Join dbo.SYS_Roles On SYS_Roles.RoleID = SYS_UserRoles.RoleID
                Where (SYS_UserRoles.UserID = SYS_Users.UserID)
            ),
            N'Chưa phân vai trò'
        ) As RoleNames
    From dbo.SYS_Users
    Where (SYS_Users.IsDeleted = 0)
        And (@Search Is Null Or SYS_Users.Username Like N'%' + @Search + N'%' Or SYS_Users.FullName Like N'%' + @Search + N'%' Or SYS_Users.Email Like N'%' + @Search + N'%')
        And (@Status Is Null Or SYS_Users.Status = @Status)
        And
        (
            @RoleCode Is Null
            Or Exists
            (
                Select 1
                From dbo.SYS_UserRoles
                Inner Join dbo.SYS_Roles On SYS_Roles.RoleID = SYS_UserRoles.RoleID
                Where (SYS_UserRoles.UserID = SYS_Users.UserID)
                    And (SYS_Roles.Code = @RoleCode)
            )
        )
    Order By SYS_Users.CreatedAt Desc, SYS_Users.UserID Desc
    Offset (@Page - 1) * @PageSize Rows Fetch Next @PageSize Rows Only;

    Select
        Count(1)
    From dbo.SYS_Users
    Where (SYS_Users.IsDeleted = 0)
        And (@Search Is Null Or SYS_Users.Username Like N'%' + @Search + N'%' Or SYS_Users.FullName Like N'%' + @Search + N'%' Or SYS_Users.Email Like N'%' + @Search + N'%')
        And (@Status Is Null Or SYS_Users.Status = @Status)
        And
        (
            @RoleCode Is Null
            Or Exists
            (
                Select 1
                From dbo.SYS_UserRoles
                Inner Join dbo.SYS_Roles On SYS_Roles.RoleID = SYS_UserRoles.RoleID
                Where (SYS_UserRoles.UserID = SYS_Users.UserID)
                    And (SYS_Roles.Code = @RoleCode)
            )
        );
End;
Go

Create Or Alter Procedure dbo.SYS_User_GetByID
    @UserID Bigint
As
Begin
    Set Nocount On;

    Select
        SYS_Users.UserID,
        SYS_Users.Username,
        SYS_Users.FullName,
        SYS_Users.Email,
        SYS_Users.StudentCode,
        SYS_Users.TeacherCode,
        SYS_Users.AvatarUrl,
        SYS_Users.Status,
        SYS_Users.LastLoginAt,
        SYS_Users.CreatedAt,
        SYS_Users.UpdatedAt
    From dbo.SYS_Users
    Where (SYS_Users.UserID = @UserID)
        And (SYS_Users.IsDeleted = 0);

    Select
        SYS_Roles.Code
    From dbo.SYS_UserRoles
    Inner Join dbo.SYS_Roles On SYS_Roles.RoleID = SYS_UserRoles.RoleID
    Where (SYS_UserRoles.UserID = @UserID)
    Order By SYS_Roles.Code;
End;
Go

Create Or Alter Procedure dbo.SYS_User_Create
    @Username Nvarchar(100),
    @PasswordHash Nvarchar(500),
    @FullName Nvarchar(250),
    @Email Nvarchar(250),
    @StudentCode Nvarchar(100) = Null,
    @TeacherCode Nvarchar(100) = Null,
    @AvatarUrl Nvarchar(1000) = Null,
    @Status Varchar(30),
    @RoleCodesJson Nvarchar(Max),
    @ActorUserID Bigint
As
Begin
    Set Nocount On;
    Set Xact_Abort On;

    If Exists
    (
        Select 1
        From dbo.SYS_Users
        Where (Username = @Username Or Email = @Email)
            And (IsDeleted = 0)
    )
        Throw 50004, N'Tên đăng nhập hoặc email đã tồn tại.', 1;

    If Not Exists (Select 1 From Openjson(@RoleCodesJson))
        Throw 50001, N'Người dùng phải có ít nhất một vai trò.', 1;

    Begin Transaction;

    Insert Into dbo.SYS_Users
    (
        Username,
        PasswordHash,
        FullName,
        Email,
        StudentCode,
        TeacherCode,
        AvatarUrl,
        Status,
        CreatedByUserID
    )
    Values
    (
        @Username,
        @PasswordHash,
        @FullName,
        @Email,
        @StudentCode,
        @TeacherCode,
        @AvatarUrl,
        @Status,
        @ActorUserID
    );

    Declare @UserID Bigint = Scope_Identity();

    Insert Into dbo.SYS_UserRoles
    (
        UserID,
        RoleID
    )
    Select
        @UserID,
        SYS_Roles.RoleID
    From dbo.SYS_Roles
    Inner Join Openjson(@RoleCodesJson) As RoleCodes On RoleCodes.[value] = SYS_Roles.Code
    Where (SYS_Roles.Status = 'ACTIVE');

    If Not Exists (Select 1 From dbo.SYS_UserRoles Where (UserID = @UserID))
        Throw 50001, N'Không tìm thấy vai trò hợp lệ.', 1;

    Commit Transaction;

    Select @UserID;
End;
Go

Create Or Alter Procedure dbo.SYS_User_Update
    @UserID Bigint,
    @FullName Nvarchar(250),
    @Email Nvarchar(250),
    @StudentCode Nvarchar(100) = Null,
    @TeacherCode Nvarchar(100) = Null,
    @AvatarUrl Nvarchar(1000) = Null,
    @Status Varchar(30),
    @PasswordHash Nvarchar(500) = Null,
    @RoleCodesJson Nvarchar(Max),
    @ActorUserID Bigint
As
Begin
    Set Nocount On;
    Set Xact_Abort On;

    If Not Exists (Select 1 From dbo.SYS_Users Where (UserID = @UserID) And (IsDeleted = 0))
        Return;

    If (@UserID = @ActorUserID And @Status <> 'ACTIVE')
        Throw 50003, N'Bạn không thể khóa tài khoản đang đăng nhập.', 1;

    If Exists
    (
        Select 1
        From dbo.SYS_Users
        Where (Email = @Email)
            And (UserID <> @UserID)
            And (IsDeleted = 0)
    )
        Throw 50004, N'Email đã được tài khoản khác sử dụng.', 1;

    If Not Exists (Select 1 From Openjson(@RoleCodesJson))
        Throw 50001, N'Người dùng phải có ít nhất một vai trò.', 1;

    Begin Transaction;

    Update dbo.SYS_Users
    Set
        FullName = @FullName,
        Email = @Email,
        StudentCode = @StudentCode,
        TeacherCode = @TeacherCode,
        AvatarUrl = @AvatarUrl,
        Status = @Status,
        PasswordHash = Case When @PasswordHash Is Null Then PasswordHash Else @PasswordHash End,
        UpdatedAt = Sysutcdatetime(),
        UpdatedByUserID = @ActorUserID
    Where (UserID = @UserID)
        And (IsDeleted = 0);

    Delete From dbo.SYS_UserRoles
    Where (UserID = @UserID);

    Insert Into dbo.SYS_UserRoles
    (
        UserID,
        RoleID
    )
    Select
        @UserID,
        SYS_Roles.RoleID
    From dbo.SYS_Roles
    Inner Join Openjson(@RoleCodesJson) As RoleCodes On RoleCodes.[value] = SYS_Roles.Code
    Where (SYS_Roles.Status = 'ACTIVE');

    If Not Exists (Select 1 From dbo.SYS_UserRoles Where (UserID = @UserID))
        Throw 50001, N'Không tìm thấy vai trò hợp lệ.', 1;

    Commit Transaction;

    Select 1;
End;
Go

Create Or Alter Procedure dbo.SYS_User_SetStatus
    @UserID Bigint,
    @Status Varchar(30),
    @ActorUserID Bigint
As
Begin
    Set Nocount On;

    If (@UserID = @ActorUserID And @Status <> 'ACTIVE')
        Throw 50003, N'Bạn không thể khóa tài khoản đang đăng nhập.', 1;

    Update dbo.SYS_Users
    Set
        Status = @Status,
        UpdatedAt = Sysutcdatetime(),
        UpdatedByUserID = @ActorUserID
    Where (UserID = @UserID)
        And (IsDeleted = 0);

    Select @@Rowcount;
End;
Go

Create Or Alter Procedure dbo.SYS_Role_GetList
As
Begin
    Set Nocount On;

    Select
        SYS_Roles.RoleID,
        SYS_Roles.Code,
        SYS_Roles.Name,
        SYS_Roles.[Description],
        SYS_Roles.Status,
        (Select Count(1) From dbo.SYS_UserRoles Where (SYS_UserRoles.RoleID = SYS_Roles.RoleID)) As UserCount,
        (Select Count(1) From dbo.SYS_RolePermissions Where (SYS_RolePermissions.RoleID = SYS_Roles.RoleID)) As PermissionCount
    From dbo.SYS_Roles
    Order By Case SYS_Roles.Code When 'ADMIN' Then 1 When 'TEACHER' Then 2 Else 3 End, SYS_Roles.Name;
End;
Go

Create Or Alter Procedure dbo.SYS_Role_GetPermissions
    @RoleID Bigint
As
Begin
    Set Nocount On;

    Select
        SYS_Permissions.PermissionID,
        SYS_Permissions.Code,
        SYS_Permissions.Name,
        SYS_Permissions.Module,
        SYS_Permissions.[Description],
        Cast(Case When SYS_RolePermissions.PermissionID Is Null Then 0 Else 1 End As Bit) As IsGranted
    From dbo.SYS_Permissions
    Left Join dbo.SYS_RolePermissions On SYS_RolePermissions.PermissionID = SYS_Permissions.PermissionID And SYS_RolePermissions.RoleID = @RoleID
    Order By SYS_Permissions.Module, SYS_Permissions.Name;
End;
Go

Create Or Alter Procedure dbo.SYS_Role_SavePermissions
    @RoleID Bigint,
    @PermissionCodesJson Nvarchar(Max),
    @ActorUserID Bigint
As
Begin
    Set Nocount On;
    Set Xact_Abort On;

    If Exists (Select 1 From dbo.SYS_Roles Where (RoleID = @RoleID) And (Code = 'ADMIN'))
        Throw 50003, N'Vai trò Quản trị viên luôn có toàn quyền và không được giảm quyền.', 1;

    If Not Exists (Select 1 From dbo.SYS_Roles Where (RoleID = @RoleID))
        Return;

    Begin Transaction;

    Delete From dbo.SYS_RolePermissions
    Where (RoleID = @RoleID);

    Insert Into dbo.SYS_RolePermissions
    (
        RoleID,
        PermissionID
    )
    Select
        @RoleID,
        SYS_Permissions.PermissionID
    From dbo.SYS_Permissions
    Inner Join Openjson(@PermissionCodesJson) As PermissionCodes On PermissionCodes.[value] = SYS_Permissions.Code;

    Insert Into dbo.SYS_AuditLogs
    (
        UserID,
        Action,
        Module,
        EntityName,
        EntityID,
        NewValuesJson
    )
    Values
    (
        @ActorUserID,
        'UPDATE_PERMISSIONS',
        'SYSTEM',
        'SYS_Roles',
        Convert(Nvarchar(100), @RoleID),
        @PermissionCodesJson
    );

    Commit Transaction;

    Select 1;
End;
Go

Create Or Alter Procedure dbo.SYS_SystemSetting_GetList
As
Begin
    Set Nocount On;

    Select
        SYS_SystemSettings.SystemSettingID,
        SYS_SystemSettings.SettingKey,
        SYS_SystemSettings.SettingName,
        SYS_SystemSettings.SettingValue,
        SYS_SystemSettings.DataType,
        SYS_SystemSettings.Category,
        SYS_SystemSettings.[Description],
        SYS_SystemSettings.SortOrder,
        SYS_SystemSettings.IsPublic,
        SYS_SystemSettings.UpdatedAt,
        SYS_Users.FullName As UpdatedByName
    From dbo.SYS_SystemSettings
    Left Join dbo.SYS_Users On SYS_Users.UserID = SYS_SystemSettings.UpdatedByUserID
    Order By SYS_SystemSettings.Category, SYS_SystemSettings.SortOrder, SYS_SystemSettings.SettingName;
End;
Go

Create Or Alter Procedure dbo.SYS_SystemSetting_Update
    @SettingKey Varchar(100),
    @SettingValue Nvarchar(Max),
    @ActorUserID Bigint
As
Begin
    Set Nocount On;

    Update dbo.SYS_SystemSettings
    Set
        SettingValue = @SettingValue,
        UpdatedAt = Sysutcdatetime(),
        UpdatedByUserID = @ActorUserID
    Where (SettingKey = @SettingKey);

    Select @@Rowcount;
End;
Go
