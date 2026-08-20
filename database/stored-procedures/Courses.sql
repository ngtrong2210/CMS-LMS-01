Create Or Alter Procedure dbo.LMS_Course_GetList
    @Search Nvarchar(500) = Null,
    @Status Varchar(30) = Null,
    @Page Int = 1,
    @PageSize Int = 20,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    ;

    With
        Data As (
            Select
                dbo.Courses.Id,
                dbo.Courses.Code,
                dbo.Courses.Title,
                dbo.Courses.Slug,
                dbo.Courses.ThumbnailUrl,
                dbo.Courses.ShortDescription,
                dbo.Courses.TeacherId,
                dbo.Courses.CategoryId,
                dbo.Users.FullName TeacherName,
                dbo.Courses.Level,
                dbo.Courses.PassingScore,
                dbo.Courses.Status,
                dbo.Courses.CreatedAt,
                (
                    Select
                        Count(*)
                    From dbo.Lessons
                    Where (dbo.Lessons.CourseId = dbo.Courses.Id)
                        And (dbo.Lessons.IsDeleted = 0)
    ) LessonCount,
                (
                    Select
                        Count(*)
                    From dbo.Enrollments
                    Where (dbo.Enrollments.CourseId = dbo.Courses.Id)
                        And (dbo.Enrollments.Status <> 'CANCELLED')
    ) StudentCount
            From dbo.Courses
                Inner Join dbo.Users On dbo.Users.Id = dbo.Courses.TeacherId
            Where (dbo.Courses.IsDeleted = 0)
                And (@IsAdmin = 1 Or dbo.Courses.TeacherId = @ActorId)
                And (@Status Is Null Or @Status = '' Or dbo.Courses.Status = @Status)
                And (@Search Is Null Or @Search = '' Or dbo.Courses.Title Like '%' + @Search + '%' Or dbo.Courses.Code Like '%' + @Search + '%')
    )
    Select
        *
    From Data
    Order By
        CreatedAt Desc
    Offset
        (@Page -1) * @PageSize Rows
    Fetch Next
        @PageSize Rows Only;

    Select
        Count(*)
    From dbo.Courses
    Where (dbo.Courses.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.Courses.TeacherId = @ActorId)
        And (@Status Is Null Or @Status = '' Or dbo.Courses.Status = @Status)
        And (@Search Is Null Or @Search = '' Or dbo.Courses.Title Like '%' + @Search + '%' Or dbo.Courses.Code Like '%' + @Search + '%');

End
Go
Create Or Alter Procedure dbo.LMS_Course_GetById
    @Id Bigint,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    If Exists (
        Select
            1
        From dbo.Courses
        Where (Id = @Id)
            And (IsDeleted = 0)
    )
    And Not Exists (
        Select
            1
        From dbo.Courses
        Where (Id = @Id)
            And (IsDeleted = 0)
            And (@IsAdmin = 1 Or TeacherId = @ActorId)
    ) Throw 50003,
    N'Bạn không có quyền quản lý khóa học này.',
    1;

    Select
        dbo.Courses.*,
        dbo.Users.FullName TeacherName,
        dbo.CourseCategories.Name CategoryName
    From dbo.Courses
        Inner Join dbo.Users On dbo.Users.Id = dbo.Courses.TeacherId
        Left Join dbo.CourseCategories On dbo.CourseCategories.Id = dbo.Courses.CategoryId
    Where (dbo.Courses.Id = @Id)
        And (dbo.Courses.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.Courses.TeacherId = @ActorId);

End
Go
Create Or Alter Procedure dbo.LMS_Course_GetContent
    @CourseId Bigint,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    If Not Exists (
        Select
            1
        From dbo.Courses
        Where (Id = @CourseId)
            And (IsDeleted = 0)
            And (@IsAdmin = 1 Or TeacherId = @ActorId)
    ) Throw 50003,
    N'Bạn không có quyền quản lý khóa học này.',
    1;

    Select
        Id,
        CourseId,
        Title,
        Description,
        SortOrder,
        Status
    From dbo.Chapters
    Where (CourseId = @CourseId)
        And (IsDeleted = 0)
    Order By
        SortOrder;

    Select
        dbo.Lessons.Id,
        dbo.Lessons.CourseId,
        dbo.Lessons.ChapterId,
        dbo.Lessons.Title,
        dbo.Lessons.Description,
        dbo.Lessons.LessonType,
        dbo.Lessons.DurationSeconds,
        dbo.Lessons.SortOrder,
        dbo.Lessons.IsRequired,
        dbo.Lessons.PassingScore,
        dbo.Lessons.Status,
        dbo.Lessons.VideoId,
        dbo.Videos.VideoAssetId,
        dbo.Videos.Title VideoTitle,
        dbo.Videos.SourceType,
        dbo.Videos.VideoUrl,
        Cast(
            Iif(
        @IsAdmin = 1
                Or dbo.VideoAssets.CreatedBy = @ActorId,
                1,
                0
    ) As Bit
    ) CanEditVideo
    From dbo.Lessons
        Left Join dbo.Videos On dbo.Videos.Id = dbo.Lessons.VideoId
        Left Join dbo.VideoAssets On dbo.VideoAssets.Id = dbo.Videos.VideoAssetId
    Where (dbo.Lessons.CourseId = @CourseId)
        And (dbo.Lessons.IsDeleted = 0)
    Order By
        dbo.Lessons.ChapterId,
        dbo.Lessons.SortOrder;

End
Go
Create Or Alter Procedure dbo.LMS_Course_Create
    @Code Nvarchar(100),
    @Title Nvarchar(500),
    @Slug Nvarchar(500) = Null,
    @ThumbnailUrl Nvarchar(1000) = Null,
    @ShortDescription Nvarchar(1000) = Null,
    @Description Nvarchar(Max) = Null,
    @TeacherId Bigint,
    @CategoryId Bigint = Null,
    @Level Varchar(50),
    @PassingScore Decimal(5, 2),
    @Status Varchar(30),
    @ActorId Bigint
As
Begin
    Set Nocount On;

    Set Xact_abort On;

    Set @Code = Ltrim(Rtrim(@Code));

    Set @Title = Ltrim(Rtrim(@Title));

    Set @Slug = Coalesce(Nullif(Ltrim(Rtrim(@Slug)), ''), Lower(Replace(@Code, ' ', '-')));

    If @Code = ''
    Or @Title = ''
    Or @PassingScore < 0
    Or @PassingScore > 100
    Or @Status Not In ('DRAFT', 'PUBLISHED', 'ARCHIVED') Throw 50001,
    N'Dữ liệu khóa học không hợp lệ.',
    1;

    If Not Exists (
        Select
            1
        From dbo.Users
        Where (Id = @TeacherId)
            And (TeacherCode Is Not Null)
            And (IsDeleted = 0)
    ) Throw 50002,
    N'Giảng viên không tồn tại.',
    1;

    If @CategoryId Is Not Null
    And Not Exists (
        Select
            1
        From dbo.CourseCategories
        Where (Id = @CategoryId)
            And (Status = 'ACTIVE')
    ) Throw 50002,
    N'Danh mục không tồn tại.',
    1;

    If Exists (
        Select
            1
        From dbo.Courses
        Where (
                Code = @Code
                Or (Slug = @Slug)
    )
            And (IsDeleted = 0)
    ) Throw 50006,
    N'Mã hoặc slug khóa học đã tồn tại.',
    1;

    Begin Transaction;

    Insert dbo.Courses (Code, Title, Slug, ThumbnailUrl, ShortDescription, Description, TeacherId, CategoryId, Level, PassingScore, Status, PublishedAt, CreatedBy)
    Values
        (@Code, @Title, @Slug, @ThumbnailUrl, @ShortDescription, @Description, @TeacherId, @CategoryId, @Level, @PassingScore, @Status, Iif(@Status = 'PUBLISHED', Sysutcdatetime(), Null), @ActorId);

    Declare @Id Bigint = Scope_identity();

    Insert dbo.AuditLogs (UserId, Action, Module, EntityName, EntityId, NewValuesJson, CreatedAt)
    Values
        (
        @ActorId,
            'CREATE',
            'COURSE',
            'Course',
            Convert(Nvarchar(100), @Id),
            (
                Select
        @Code code,
        @Title title,
        @Status status
                For Json
                    Path,
                    Without_array_wrapper
    ),
            Sysutcdatetime()
    );

    Commit Transaction;

    Select
        @Id;

End
Go
Create Or Alter Procedure dbo.LMS_Course_Update
    @Id Bigint,
    @Code Nvarchar(100),
    @Title Nvarchar(500),
    @Slug Nvarchar(500) = Null,
    @ThumbnailUrl Nvarchar(1000) = Null,
    @ShortDescription Nvarchar(1000) = Null,
    @Description Nvarchar(Max) = Null,
    @TeacherId Bigint,
    @CategoryId Bigint = Null,
    @Level Varchar(50),
    @PassingScore Decimal(5, 2),
    @Status Varchar(30),
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Set Xact_abort On;

    Set @Code = Ltrim(Rtrim(@Code));

    Set @Title = Ltrim(Rtrim(@Title));

    Set @Slug = Coalesce(Nullif(Ltrim(Rtrim(@Slug)), ''), Lower(Replace(@Code, ' ', '-')));

    If @Code = ''
    Or @Title = ''
    Or @PassingScore < 0
    Or @PassingScore > 100
    Or @Status Not In ('DRAFT', 'PUBLISHED', 'ARCHIVED') Throw 50001,
    N'Dữ liệu khóa học không hợp lệ.',
    1;

    If Not Exists (
        Select
            1
        From dbo.Users
        Where (Id = @TeacherId)
            And (TeacherCode Is Not Null)
            And (IsDeleted = 0)
    ) Throw 50002,
    N'Giảng viên không tồn tại.',
    1;

    If @CategoryId Is Not Null
    And Not Exists (
        Select
            1
        From dbo.CourseCategories
        Where (Id = @CategoryId)
            And (Status = 'ACTIVE')
    ) Throw 50002,
    N'Danh mục không tồn tại.',
    1;

    If Exists (
        Select
            1
        From dbo.Courses
        Where (Id <> @Id)
            And (Code = @Code Or Slug = @Slug)
            And (IsDeleted = 0)
    ) Throw 50006,
    N'Mã hoặc slug khóa học đã tồn tại.',
    1;

    Declare @Old Nvarchar(Max) = (
        Select
            Code code,
            Title title,
            Status status
        From dbo.Courses
        Where (Id = @Id)
        For Json
            Path,
            Without_array_wrapper
    );

    Begin Transaction;

    Update dbo.Courses
    Set
        Code = @Code,
        Title = @Title,
        Slug = @Slug,
        ThumbnailUrl = @ThumbnailUrl,
        ShortDescription = @ShortDescription,
        Description = @Description,
        TeacherId = @TeacherId,
        CategoryId = @CategoryId,
        Level = @Level,
        PassingScore = @PassingScore,
        Status = @Status,
        PublishedAt = Iif(@Status = 'PUBLISHED', Coalesce(PublishedAt, Sysutcdatetime()), PublishedAt),
        UpdatedAt = Sysutcdatetime(),
        UpdatedBy = @ActorId
    Where (Id = @Id)
        And (IsDeleted = 0)
        And (@IsAdmin = 1 Or TeacherId = @ActorId);

    Declare @Rows Int = @@Rowcount;

    If @Rows > 0
    Insert dbo.AuditLogs (UserId, Action, Module, EntityName, EntityId, OldValuesJson, NewValuesJson, CreatedAt)
    Values
        (
        @ActorId,
            'UPDATE',
            'COURSE',
            'Course',
            Convert(Nvarchar(100), @Id),
        @Old,
            (
                Select
        @Code code,
        @Title title,
        @Status status
                For Json
                    Path,
                    Without_array_wrapper
    ),
            Sysutcdatetime()
    );

    Commit Transaction;

    Select
        @Rows;

End
Go
Create Or Alter Procedure dbo.LMS_Course_ChangeStatus
    @Id Bigint,
    @Status Varchar(30),
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Set Xact_abort On;

    If @Status Not In ('PUBLISHED', 'ARCHIVED', 'DRAFT') Throw 50001,
    N'Trạng thái khóa học không hợp lệ.',
    1;

    Declare @OldStatus Varchar(30) = (
        Select
            Status
        From dbo.Courses
        Where (Id = @Id)
            And (IsDeleted = 0)
    );

    Begin Transaction;

    Update dbo.Courses
    Set
        Status = @Status,
        PublishedAt = Iif(@Status = 'PUBLISHED', Coalesce(PublishedAt, Sysutcdatetime()), PublishedAt),
        UpdatedAt = Sysutcdatetime(),
        UpdatedBy = @ActorId
    Where (Id = @Id)
        And (IsDeleted = 0)
        And (@IsAdmin = 1 Or TeacherId = @ActorId);

    Declare @Rows Int = @@Rowcount;

    If @Rows > 0
    Insert dbo.AuditLogs (UserId, Action, Module, EntityName, EntityId, OldValuesJson, NewValuesJson, CreatedAt)
    Values
        (
        @ActorId,
        @Status,
            'COURSE',
            'Course',
            Convert(Nvarchar(100), @Id),
            (
                Select
        @OldStatus status
                For Json
                    Path,
                    Without_array_wrapper
    ),
            (
                Select
        @Status status
                For Json
                    Path,
                    Without_array_wrapper
    ),
            Sysutcdatetime()
    );

    Commit Transaction;

    Select
        @Rows;

End
Go
Create Or Alter Procedure dbo.LMS_Course_Publish
    @Id Bigint,
    @UserId Bigint
As
Begin
    Set Nocount On;

    Exec dbo.LMS_Course_ChangeStatus @Id,
    'PUBLISHED',
        @UserId,
    1;

End
Go
Create Or Alter Procedure dbo.LMS_Course_Delete
    @Id Bigint,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Set Xact_abort On;

    If Not Exists (
        Select
            1
        From dbo.Courses
        Where (Id = @Id)
            And (IsDeleted = 0)
            And (@IsAdmin = 1 Or TeacherId = @ActorId)
    ) Begin
    Select
        0;

    Return;

End;

Begin Transaction;

Update dbo.Courses
Set
    IsDeleted = 1,
    UpdatedAt = Sysutcdatetime(),
    UpdatedBy = @ActorId
Where (Id = @Id);

Update dbo.Chapters
Set
    IsDeleted = 1,
    UpdatedAt = Sysutcdatetime()
Where (CourseId = @Id);

Update dbo.Lessons
Set
    IsDeleted = 1,
    UpdatedAt = Sysutcdatetime()
Where (CourseId = @Id);

Insert dbo.AuditLogs (UserId, Action, Module, EntityName, EntityId, NewValuesJson, CreatedAt)
Values
    (@ActorId, 'DELETE', 'COURSE', 'Course', Convert(Nvarchar(100), @Id), N'{"isDeleted":true}', Sysutcdatetime());

Commit Transaction;

Select
    1;

End
Go
