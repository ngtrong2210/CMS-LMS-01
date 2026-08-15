Set Nocount On;
Set Xact_abort On;
Go

If Object_id(N'dbo.SYS_Notifications', N'U') Is Null
Begin
    Create Table dbo.SYS_Notifications
    (
        NotificationID Bigint Identity(1, 1) Not Null,
        RecipientUserID Bigint Not Null,
        ActorUserID Bigint Null,
        NotificationType Varchar(50) Not Null,
        Title Nvarchar(250) Not Null,
        Message Nvarchar(1000) Not Null,
        ReferenceType Varchar(50) Null,
        ReferenceID Bigint Null,
        ActionUrl Nvarchar(500) Null,
        MetadataJson Nvarchar(Max) Null,
        IsRead Bit Not Null Constraint DF_SYS_Notifications_IsRead Default (0),
        ReadAt Datetime2(0) Null,
        CreatedAt Datetime2(0) Not Null Constraint DF_SYS_Notifications_CreatedAt Default (Sysutcdatetime()),
        ExpiresAt Datetime2(0) Null,
        Constraint PK_SYS_Notifications Primary Key Clustered (NotificationID),
        Constraint FK_SYS_Notifications_RecipientUser Foreign Key (RecipientUserID) References dbo.SYS_Users(UserID),
        Constraint FK_SYS_Notifications_ActorUser Foreign Key (ActorUserID) References dbo.SYS_Users(UserID),
        Constraint CK_SYS_Notifications_MetadataJson Check (MetadataJson Is Null Or Isjson(MetadataJson) = 1)
    );
End;
Go

If Not Exists
(
    Select
        1
    From sys.indexes
    Where (object_id = Object_id(N'dbo.SYS_Notifications'))
        And (name = N'IX_SYS_Notifications_Recipient_Read_Created')
)
    Create Index IX_SYS_Notifications_Recipient_Read_Created
        On dbo.SYS_Notifications(RecipientUserID, IsRead, CreatedAt Desc)
        Include (NotificationType, Title, ReferenceType, ReferenceID, ActionUrl, ActorUserID);
Go

If Exists
(
    Select
        1
    From sys.extended_properties
    Where (class = 1)
        And (major_id = Object_id(N'dbo.SYS_Notifications'))
        And (minor_id = 0)
        And (name = N'MS_Description')
)
    Exec sys.sp_updateextendedproperty
        @name = N'MS_Description',
        @value = N'[SYS] Thông báo nghiệp vụ gửi đến từng tài khoản, hỗ trợ trạng thái đã đọc và điều hướng đến dữ liệu liên quan.',
        @level0type = N'SCHEMA',
        @level0name = N'dbo',
        @level1type = N'TABLE',
        @level1name = N'SYS_Notifications';
Else
    Exec sys.sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'[SYS] Thông báo nghiệp vụ gửi đến từng tài khoản, hỗ trợ trạng thái đã đọc và điều hướng đến dữ liệu liên quan.',
        @level0type = N'SCHEMA',
        @level0name = N'dbo',
        @level1type = N'TABLE',
        @level1name = N'SYS_Notifications';
Go

Declare @ColumnDescriptions Table
(
    ColumnName Sysname Not Null,
    ColumnDescription Nvarchar(1000) Not Null
);

Insert Into @ColumnDescriptions
(
    ColumnName,
    ColumnDescription
)
Values
    (N'NotificationID', N'Khóa chính tự tăng của thông báo.'),
    (N'RecipientUserID', N'Tài khoản nhận và xem thông báo.'),
    (N'ActorUserID', N'Tài khoản thực hiện hành động phát sinh thông báo; có thể rỗng đối với thông báo hệ thống.'),
    (N'NotificationType', N'Loại nghiệp vụ của thông báo, ví dụ ENROLLMENT, ANSWER_SUBMITTED hoặc LESSON_COMPLETED.'),
    (N'Title', N'Tiêu đề ngắn hiển thị trong danh sách thông báo.'),
    (N'Message', N'Nội dung chi tiết giải thích sự kiện phát sinh thông báo.'),
    (N'ReferenceType', N'Loại dữ liệu nghiệp vụ được tham chiếu như COURSE, LESSON hoặc STUDENT_ANSWER.'),
    (N'ReferenceID', N'Khóa định danh của dữ liệu nghiệp vụ được tham chiếu.'),
    (N'ActionUrl', N'Đường dẫn nội bộ để mở màn hình liên quan khi người dùng chọn thông báo.'),
    (N'MetadataJson', N'Dữ liệu mở rộng dạng JSON phục vụ hiển thị hoặc tích hợp trong tương lai.'),
    (N'IsRead', N'Đánh dấu người nhận đã đọc thông báo hay chưa.'),
    (N'ReadAt', N'Thời điểm UTC người nhận đánh dấu đã đọc thông báo.'),
    (N'CreatedAt', N'Thời điểm UTC thông báo được tạo.'),
    (N'ExpiresAt', N'Thời điểm UTC thông báo hết hiệu lực; rỗng nghĩa là không tự hết hạn.');

Declare @ColumnName Sysname,
    @ColumnDescription Nvarchar(1000);

Declare NotificationColumnDescriptionCursor Cursor Local Fast_forward For
    Select
        ColumnName,
        ColumnDescription
    From @ColumnDescriptions;

Open NotificationColumnDescriptionCursor;

Fetch Next From NotificationColumnDescriptionCursor Into @ColumnName, @ColumnDescription;

While @@Fetch_status = 0
Begin
    If Exists
    (
        Select
            1
        From sys.extended_properties
        Inner Join sys.columns On sys.columns.object_id = sys.extended_properties.major_id And sys.columns.column_id = sys.extended_properties.minor_id
        Where (sys.extended_properties.class = 1)
            And (sys.extended_properties.major_id = Object_id(N'dbo.SYS_Notifications'))
            And (sys.extended_properties.name = N'MS_Description')
            And (sys.columns.name = @ColumnName)
    )
        Exec sys.sp_updateextendedproperty
            @name = N'MS_Description',
            @value = @ColumnDescription,
            @level0type = N'SCHEMA',
            @level0name = N'dbo',
            @level1type = N'TABLE',
            @level1name = N'SYS_Notifications',
            @level2type = N'COLUMN',
            @level2name = @ColumnName;
    Else
        Exec sys.sp_addextendedproperty
            @name = N'MS_Description',
            @value = @ColumnDescription,
            @level0type = N'SCHEMA',
            @level0name = N'dbo',
            @level1type = N'TABLE',
            @level1name = N'SYS_Notifications',
            @level2type = N'COLUMN',
            @level2name = @ColumnName;

    Fetch Next From NotificationColumnDescriptionCursor Into @ColumnName, @ColumnDescription;
End;

Close NotificationColumnDescriptionCursor;
Deallocate NotificationColumnDescriptionCursor;
Go

/* Tạo dữ liệu ban đầu từ hoạt động thực tế để có thể kiểm tra chuông thông báo ngay. */
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
    IsRead,
    CreatedAt
)
Select
    AdministratorUser.UserID,
    dbo.LMS_StudentAnswers.StudentUserID,
    'ANSWER_SUBMITTED',
    N'Học viên đã nộp câu trả lời',
    Concat(StudentUser.FullName, N' đã trả lời câu hỏi trong bài “', dbo.SIM_Lessons.Title, N'”.'),
    'STUDENT_ANSWER',
    dbo.LMS_StudentAnswers.StudentAnswerID,
    N'/cms/reports',
    0,
    dbo.LMS_StudentAnswers.AnsweredAt
From dbo.LMS_StudentAnswers
Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.LessonID = dbo.LMS_StudentAnswers.LessonID
Inner Join dbo.SYS_Users As StudentUser On StudentUser.UserID = dbo.LMS_StudentAnswers.StudentUserID
Cross Join dbo.SYS_Users As AdministratorUser
Inner Join dbo.SYS_UserRoles On dbo.SYS_UserRoles.UserID = AdministratorUser.UserID
Inner Join dbo.SYS_Roles On dbo.SYS_Roles.RoleID = dbo.SYS_UserRoles.RoleID And dbo.SYS_Roles.Code = 'ADMIN'
Where (dbo.LMS_StudentAnswers.StudentAnswerID In
    (
        Select Top (8)
            RecentStudentAnswers.StudentAnswerID
        From dbo.LMS_StudentAnswers As RecentStudentAnswers
        Order By
            RecentStudentAnswers.AnsweredAt Desc,
            RecentStudentAnswers.StudentAnswerID Desc
    ))
    And Not Exists
    (
        Select
            1
        From dbo.SYS_Notifications
        Where (dbo.SYS_Notifications.RecipientUserID = AdministratorUser.UserID)
            And (dbo.SYS_Notifications.NotificationType = 'ANSWER_SUBMITTED')
            And (dbo.SYS_Notifications.ReferenceType = 'STUDENT_ANSWER')
            And (dbo.SYS_Notifications.ReferenceID = dbo.LMS_StudentAnswers.StudentAnswerID)
    );
Go

/* Dữ liệu trình diễn cho quản trị viên: mỗi nhóm nghiệp vụ có ít nhất một thông báo. */
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
    IsRead,
    CreatedAt
)
Select
    AdministratorUser.UserID,
    LessonActivity.StudentUserID,
    'LESSON_COMPLETED',
    N'Học viên đã hoàn thành bài học',
    Concat(Coalesce(LessonActivity.StudentName, N'Một học viên'), N' đã hoàn thành “', Coalesce(LessonActivity.LessonTitle, N'Bài học thực hành'), N'” và kết quả đã được cập nhật.'),
    'LESSON_PROGRESS',
    LessonActivity.StudentLessonProgressID,
    N'/cms/reports',
    N'{"seedKey":"LESSON_COMPLETED_DEMO"}',
    0,
    Dateadd(Minute, -3, Sysutcdatetime())
From dbo.SYS_Users As AdministratorUser
Inner Join dbo.SYS_UserRoles On dbo.SYS_UserRoles.UserID = AdministratorUser.UserID
Inner Join dbo.SYS_Roles On dbo.SYS_Roles.RoleID = dbo.SYS_UserRoles.RoleID And dbo.SYS_Roles.Code = 'ADMIN'
Outer Apply
(
    Select Top (1)
        dbo.LMS_StudentLessonProgress.StudentLessonProgressID,
        dbo.LMS_StudentLessonProgress.StudentUserID,
        StudentUser.FullName StudentName,
        dbo.SIM_Lessons.Title LessonTitle
    From dbo.LMS_StudentLessonProgress
    Inner Join dbo.SYS_Users As StudentUser On StudentUser.UserID = dbo.LMS_StudentLessonProgress.StudentUserID
    Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.LessonID = dbo.LMS_StudentLessonProgress.LessonID
    Order By
        dbo.LMS_StudentLessonProgress.Completed Desc,
        dbo.LMS_StudentLessonProgress.StudentLessonProgressID Desc
) As LessonActivity
Where Not Exists
(
    Select
        1
    From dbo.SYS_Notifications
    Where (dbo.SYS_Notifications.RecipientUserID = AdministratorUser.UserID)
        And (Json_value(dbo.SYS_Notifications.MetadataJson, '$.seedKey') = 'LESSON_COMPLETED_DEMO')
);
Go

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
    IsRead,
    CreatedAt
)
Select
    AdministratorUser.UserID,
    EnrollmentActivity.CreatedByUserID,
    'ENROLLMENT',
    N'Học viên mới được ghi danh',
    Concat(Coalesce(EnrollmentActivity.StudentName, N'Một học viên'), N' vừa được ghi danh vào khóa “', Coalesce(EnrollmentActivity.CourseTitle, N'Khóa học mẫu'), N'”.'),
    'ENROLLMENT',
    EnrollmentActivity.EnrollmentID,
    N'/cms/enrollments',
    N'{"seedKey":"ENROLLMENT_DEMO"}',
    0,
    Dateadd(Minute, -2, Sysutcdatetime())
From dbo.SYS_Users As AdministratorUser
Inner Join dbo.SYS_UserRoles On dbo.SYS_UserRoles.UserID = AdministratorUser.UserID
Inner Join dbo.SYS_Roles On dbo.SYS_Roles.RoleID = dbo.SYS_UserRoles.RoleID And dbo.SYS_Roles.Code = 'ADMIN'
Outer Apply
(
    Select Top (1)
        dbo.LMS_Enrollments.EnrollmentID,
        dbo.LMS_Enrollments.CreatedByUserID,
        StudentUser.FullName StudentName,
        dbo.SIM_Courses.Title CourseTitle
    From dbo.LMS_Enrollments
    Inner Join dbo.SYS_Users As StudentUser On StudentUser.UserID = dbo.LMS_Enrollments.StudentUserID
    Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.LMS_Enrollments.CourseID
    Order By
        dbo.LMS_Enrollments.EnrolledAt Desc,
        dbo.LMS_Enrollments.EnrollmentID Desc
) As EnrollmentActivity
Where Not Exists
(
    Select
        1
    From dbo.SYS_Notifications
    Where (dbo.SYS_Notifications.RecipientUserID = AdministratorUser.UserID)
        And (Json_value(dbo.SYS_Notifications.MetadataJson, '$.seedKey') = 'ENROLLMENT_DEMO')
);
Go

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
    IsRead,
    CreatedAt
)
Select
    AdministratorUser.UserID,
    VideoActivity.CreatedByUserID,
    'VIDEO_SHARED',
    N'Video vừa được chia sẻ',
    Concat(Coalesce(VideoActivity.CreatorName, N'Một giáo viên'), N' đã chia sẻ video “', Coalesce(VideoActivity.VideoTitle, N'Video bài giảng mẫu'), N'” cho đồng nghiệp.'),
    'VIDEO_ASSET',
    VideoActivity.VideoAssetID,
    N'/cms/videos',
    N'{"seedKey":"VIDEO_SHARED_DEMO"}',
    0,
    Dateadd(Minute, -1, Sysutcdatetime())
From dbo.SYS_Users As AdministratorUser
Inner Join dbo.SYS_UserRoles On dbo.SYS_UserRoles.UserID = AdministratorUser.UserID
Inner Join dbo.SYS_Roles On dbo.SYS_Roles.RoleID = dbo.SYS_UserRoles.RoleID And dbo.SYS_Roles.Code = 'ADMIN'
Outer Apply
(
    Select Top (1)
        dbo.SIM_VideoAssets.VideoAssetID,
        dbo.SIM_VideoAssets.CreatedByUserID,
        dbo.SIM_VideoAssets.Title VideoTitle,
        CreatorUser.FullName CreatorName
    From dbo.SIM_VideoAssets
    Inner Join dbo.SYS_Users As CreatorUser On CreatorUser.UserID = dbo.SIM_VideoAssets.CreatedByUserID
    Where (dbo.SIM_VideoAssets.IsDeleted = 0)
    Order By
        dbo.SIM_VideoAssets.CreatedAt Desc,
        dbo.SIM_VideoAssets.VideoAssetID Desc
) As VideoActivity
Where Not Exists
(
    Select
        1
    From dbo.SYS_Notifications
    Where (dbo.SYS_Notifications.RecipientUserID = AdministratorUser.UserID)
        And (Json_value(dbo.SYS_Notifications.MetadataJson, '$.seedKey') = 'VIDEO_SHARED_DEMO')
);
Go

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
    IsRead,
    CreatedAt
)
Select
    AdministratorUser.UserID,
    Null,
    'SYSTEM',
    N'Dữ liệu học tập đã được cập nhật',
    N'Hệ thống đã tổng hợp tiến độ, điểm và hoạt động học tập mới nhất.',
    'SYSTEM',
    Null,
    N'/cms/dashboard',
    N'{"seedKey":"SYSTEM_DEMO"}',
    0,
    Sysutcdatetime()
From dbo.SYS_Users As AdministratorUser
Inner Join dbo.SYS_UserRoles On dbo.SYS_UserRoles.UserID = AdministratorUser.UserID
Inner Join dbo.SYS_Roles On dbo.SYS_Roles.RoleID = dbo.SYS_UserRoles.RoleID And dbo.SYS_Roles.Code = 'ADMIN'
Where Not Exists
(
    Select
        1
    From dbo.SYS_Notifications
    Where (dbo.SYS_Notifications.RecipientUserID = AdministratorUser.UserID)
        And (Json_value(dbo.SYS_Notifications.MetadataJson, '$.seedKey') = 'SYSTEM_DEMO')
);
Go

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
    IsRead,
    CreatedAt
)
Select
    dbo.LMS_Enrollments.StudentUserID,
    dbo.LMS_Enrollments.CreatedByUserID,
    'ENROLLMENT',
    N'Bạn đã được ghi danh khóa học',
    Concat(N'Bạn có thể bắt đầu học khóa “', dbo.SIM_Courses.Title, N'”.'),
    'COURSE',
    dbo.SIM_Courses.CourseID,
    Concat(N'/lms/courses/', dbo.SIM_Courses.CourseID),
    0,
    dbo.LMS_Enrollments.EnrolledAt
From dbo.LMS_Enrollments
Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.LMS_Enrollments.CourseID
Where (dbo.LMS_Enrollments.Status <> 'CANCELLED')
    And Not Exists
    (
        Select
            1
        From dbo.SYS_Notifications
        Where (dbo.SYS_Notifications.RecipientUserID = dbo.LMS_Enrollments.StudentUserID)
            And (dbo.SYS_Notifications.NotificationType = 'ENROLLMENT')
            And (dbo.SYS_Notifications.ReferenceType = 'COURSE')
            And (dbo.SYS_Notifications.ReferenceID = dbo.SIM_Courses.CourseID)
    );
Go
