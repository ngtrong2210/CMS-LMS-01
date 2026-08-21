Set Nocount On;
Set Xact_Abort On;

If Object_Id(N'dbo.SYS_SystemSettings', N'U') Is Null
Begin
    Create Table dbo.SYS_SystemSettings
    (
        SystemSettingID Bigint Identity(1, 1) Not Null,
        SettingKey Varchar(100) Not Null,
        SettingName Nvarchar(200) Not Null,
        SettingValue Nvarchar(Max) Null,
        DataType Varchar(30) Not Null Constraint DF_SYS_SystemSettings_DataType Default ('TEXT'),
        Category Varchar(50) Not Null,
        [Description] Nvarchar(1000) Null,
        SortOrder Int Not Null Constraint DF_SYS_SystemSettings_SortOrder Default (1),
        IsPublic Bit Not Null Constraint DF_SYS_SystemSettings_IsPublic Default (0),
        CreatedAt Datetime2 Not Null Constraint DF_SYS_SystemSettings_CreatedAt Default (Sysutcdatetime()),
        UpdatedAt Datetime2 Null,
        UpdatedByUserID Bigint Null,
        Constraint PK_SYS_SystemSettings Primary Key (SystemSettingID),
        Constraint UQ_SYS_SystemSettings_SettingKey Unique (SettingKey),
        Constraint CK_SYS_SystemSettings_DataType Check (DataType In ('TEXT', 'NUMBER', 'BOOLEAN', 'EMAIL', 'URL')),
        Constraint FK_SYS_SystemSettings_UpdatedByUser Foreign Key (UpdatedByUserID) References dbo.SYS_Users(UserID)
    );
End;

If Not Exists
(
    Select 1
    From sys.extended_properties
    Where (class = 1)
        And (major_id = Object_Id(N'dbo.SYS_SystemSettings'))
        And (minor_id = 0)
        And (name = N'MS_Description')
)
Begin
    Exec sys.sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'[SYS] Cấu hình vận hành và hiển thị dùng chung của hệ thống.',
        @level0type = N'SCHEMA', @level0name = N'dbo',
        @level1type = N'TABLE', @level1name = N'SYS_SystemSettings';
End;

If Object_Id(N'tempdb..#tblColumnDescriptions', N'U') Is Not Null
    Drop Table #tblColumnDescriptions;

Create Table #tblColumnDescriptions
(
    ColumnName Sysname Not Null,
    [Description] Nvarchar(1000) Not Null
);

Insert Into #tblColumnDescriptions
(
    ColumnName,
    [Description]
)
Values
    (N'SystemSettingID', N'Khóa chính định danh cấu hình hệ thống.'),
    (N'SettingKey', N'Mã cấu hình duy nhất dùng trong mã nguồn và API.'),
    (N'SettingName', N'Tên tiếng Việt hiển thị cho quản trị viên.'),
    (N'SettingValue', N'Giá trị cấu hình được lưu dưới dạng chuỗi và diễn giải theo DataType.'),
    (N'DataType', N'Kiểu dữ liệu của giá trị: TEXT, NUMBER, BOOLEAN, EMAIL hoặc URL.'),
    (N'Category', N'Nhóm cấu hình phục vụ phân loại trên giao diện.'),
    (N'Description', N'Mô tả ý nghĩa và phạm vi ảnh hưởng của cấu hình.'),
    (N'SortOrder', N'Thứ tự hiển thị cấu hình trong cùng nhóm.'),
    (N'IsPublic', N'Cho biết cấu hình có được phép công khai cho giao diện người dùng hay không.'),
    (N'CreatedAt', N'Thời điểm cấu hình được tạo theo UTC.'),
    (N'UpdatedAt', N'Thời điểm cấu hình được cập nhật gần nhất theo UTC.'),
    (N'UpdatedByUserID', N'Tài khoản quản trị cập nhật cấu hình gần nhất; liên kết SYS_Users.UserID.');

Declare @ColumnName Sysname;
Declare @Description Nvarchar(1000);

Declare SystemSettingDescriptionCursor Cursor Local Fast_Forward For
    Select
        ColumnName,
        [Description]
    From #tblColumnDescriptions;

Open SystemSettingDescriptionCursor;
Fetch Next From SystemSettingDescriptionCursor Into @ColumnName, @Description;

While @@Fetch_Status = 0
Begin
    If Not Exists
    (
        Select 1
        From sys.extended_properties
        Where (class = 1)
            And (major_id = Object_Id(N'dbo.SYS_SystemSettings'))
            And (minor_id = Columnproperty(Object_Id(N'dbo.SYS_SystemSettings'), @ColumnName, 'ColumnId'))
            And (name = N'MS_Description')
    )
    Begin
        Exec sys.sp_addextendedproperty
            @name = N'MS_Description',
            @value = @Description,
            @level0type = N'SCHEMA', @level0name = N'dbo',
            @level1type = N'TABLE', @level1name = N'SYS_SystemSettings',
            @level2type = N'COLUMN', @level2name = @ColumnName;
    End;

    Fetch Next From SystemSettingDescriptionCursor Into @ColumnName, @Description;
End;

Close SystemSettingDescriptionCursor;
Deallocate SystemSettingDescriptionCursor;
Drop Table #tblColumnDescriptions;

Merge dbo.SYS_SystemSettings As Target
Using
(
    Values
        ('SYSTEM_NAME', N'Tên hệ thống', N'Elearning', 'TEXT', 'GENERAL', N'Tên hiển thị chung của hệ thống.', 1, 1),
        ('ORGANIZATION_NAME', N'Tên đơn vị', N'Trường học trực tuyến Eduvers', 'TEXT', 'GENERAL', N'Tên trường hoặc đơn vị vận hành hệ thống.', 2, 1),
        ('SUPPORT_EMAIL', N'Email hỗ trợ', N'support@eduvers.vn', 'EMAIL', 'GENERAL', N'Địa chỉ tiếp nhận yêu cầu hỗ trợ người dùng.', 3, 1),
        ('DEFAULT_PAGE_SIZE', N'Số dòng mặc định', N'20', 'NUMBER', 'LEARNING', N'Số dòng mặc định trên các danh sách quản trị.', 1, 0),
        ('DEFAULT_PASSING_SCORE', N'Điểm đạt mặc định', N'50', 'NUMBER', 'LEARNING', N'Điểm tối thiểu mặc định để hoàn thành bài học hoặc khóa học.', 2, 0),
        ('ALLOW_STUDENT_SEEK', N'Cho phép tua video', N'false', 'BOOLEAN', 'LEARNING', N'Giá trị mặc định khi tạo cấu hình xem video cho học viên.', 3, 0),
        ('MAINTENANCE_MODE', N'Chế độ bảo trì', N'false', 'BOOLEAN', 'SECURITY', N'Đánh dấu hệ thống đang trong thời gian bảo trì.', 1, 0),
        ('SESSION_TIMEOUT_MINUTES', N'Thời gian hết phiên', N'120', 'NUMBER', 'SECURITY', N'Số phút tối đa của một phiên đăng nhập.', 2, 0)
) As Source(SettingKey, SettingName, SettingValue, DataType, Category, [Description], SortOrder, IsPublic)
On (Target.SettingKey = Source.SettingKey)
When Not Matched Then
    Insert
    (
        SettingKey,
        SettingName,
        SettingValue,
        DataType,
        Category,
        [Description],
        SortOrder,
        IsPublic
    )
    Values
    (
        Source.SettingKey,
        Source.SettingName,
        Source.SettingValue,
        Source.DataType,
        Source.Category,
        Source.[Description],
        Source.SortOrder,
        Source.IsPublic
    );
Go
