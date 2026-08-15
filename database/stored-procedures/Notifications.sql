Set Ansi_nulls On;
Set Quoted_identifier On;
Go

Create Or Alter Procedure dbo.SYS_Notification_GetList
    @RecipientUserID Bigint,
    @Limit Int = 20,
    @UnreadOnly Bit = 0
As
Begin
    Set Nocount On;

    Set @Limit = Case When @Limit < 1 Then 1 When @Limit > 100 Then 100 Else @Limit End;

    Select Top (@Limit)
        dbo.SYS_Notifications.NotificationID Id,
        dbo.SYS_Notifications.NotificationType,
        dbo.SYS_Notifications.Title,
        dbo.SYS_Notifications.Message,
        dbo.SYS_Notifications.ReferenceType,
        dbo.SYS_Notifications.ReferenceID,
        dbo.SYS_Notifications.ActionUrl,
        dbo.SYS_Notifications.IsRead,
        dbo.SYS_Notifications.ReadAt,
        dbo.SYS_Notifications.CreatedAt,
        ActorUser.FullName ActorName,
        ActorUser.AvatarUrl ActorAvatarUrl
    From dbo.SYS_Notifications
    Left Join dbo.SYS_Users As ActorUser On ActorUser.UserID = dbo.SYS_Notifications.ActorUserID
    Where (dbo.SYS_Notifications.RecipientUserID = @RecipientUserID)
        And (@UnreadOnly = 0 Or dbo.SYS_Notifications.IsRead = 0)
        And (dbo.SYS_Notifications.ExpiresAt Is Null Or dbo.SYS_Notifications.ExpiresAt > Sysutcdatetime())
    Order By
        dbo.SYS_Notifications.IsRead,
        dbo.SYS_Notifications.CreatedAt Desc,
        dbo.SYS_Notifications.NotificationID Desc;

    Select
        Count(*)
    From dbo.SYS_Notifications
    Where (dbo.SYS_Notifications.RecipientUserID = @RecipientUserID)
        And (dbo.SYS_Notifications.IsRead = 0)
        And (dbo.SYS_Notifications.ExpiresAt Is Null Or dbo.SYS_Notifications.ExpiresAt > Sysutcdatetime());
End;
Go

Create Or Alter Procedure dbo.SYS_Notification_MarkRead
    @NotificationID Bigint,
    @RecipientUserID Bigint
As
Begin
    Set Nocount On;

    Update dbo.SYS_Notifications
    Set
        IsRead = 1,
        ReadAt = Coalesce(ReadAt, Sysutcdatetime())
    Where (dbo.SYS_Notifications.NotificationID = @NotificationID)
        And (dbo.SYS_Notifications.RecipientUserID = @RecipientUserID);

    Select
        @@Rowcount;
End;
Go

Create Or Alter Procedure dbo.SYS_Notification_MarkAllRead
    @RecipientUserID Bigint
As
Begin
    Set Nocount On;

    Update dbo.SYS_Notifications
    Set
        IsRead = 1,
        ReadAt = Sysutcdatetime()
    Where (dbo.SYS_Notifications.RecipientUserID = @RecipientUserID)
        And (dbo.SYS_Notifications.IsRead = 0);

    Select
        @@Rowcount;
End;
Go

Create Or Alter Procedure dbo.SYS_Notification_Create
    @RecipientUserID Bigint,
    @ActorUserID Bigint = Null,
    @NotificationType Varchar(50),
    @Title Nvarchar(250),
    @Message Nvarchar(1000),
    @ReferenceType Varchar(50) = Null,
    @ReferenceID Bigint = Null,
    @ActionUrl Nvarchar(500) = Null,
    @MetadataJson Nvarchar(Max) = Null,
    @ExpiresAt Datetime2(0) = Null
As
Begin
    Set Nocount On;

    If Not Exists
    (
        Select
            1
        From dbo.SYS_Users
        Where (dbo.SYS_Users.UserID = @RecipientUserID)
            And (dbo.SYS_Users.IsDeleted = 0)
    )
        Throw 50002, N'Tài khoản nhận thông báo không tồn tại.', 1;

    If @MetadataJson Is Not Null And Isjson(@MetadataJson) <> 1
        Throw 50001, N'MetadataJson của thông báo không hợp lệ.', 1;

    Insert Into dbo.SYS_Notifications
    (
        RecipientUserID,
        ActorUserID,
        NotificationType,
        Title,
        Message,
        ReferenceType,
        ReferenceID,
        ActionUrl,
        MetadataJson,
        ExpiresAt
    )
    Values
    (
        @RecipientUserID,
        @ActorUserID,
        @NotificationType,
        @Title,
        @Message,
        @ReferenceType,
        @ReferenceID,
        @ActionUrl,
        @MetadataJson,
        @ExpiresAt
    );

    Select
        Scope_identity();
End;
Go

