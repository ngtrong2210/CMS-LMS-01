Create Or Alter Procedure dbo.LMS_Chapter_GetByCourse
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
        SortOrder,
        Id;

End
Go
Create Or Alter Procedure dbo.LMS_Chapter_Create
    @CourseId Bigint,
    @Title Nvarchar(500),
    @Description Nvarchar(1000) = Null,
    @SortOrder Int,
    @Status Varchar(30),
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    If Nullif(Ltrim(Rtrim(@Title)), '') Is Null
    Or @SortOrder < 1 Throw 50001,
    N'Dữ liệu chương không hợp lệ.',
    1;

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

    Insert dbo.Chapters (CourseId, Title, Description, SortOrder, Status)
    Values
        (@CourseId, @Title, @Description, @SortOrder, @Status);

    Declare @Id Bigint = Scope_identity();

    Insert dbo.AuditLogs (UserId, Action, Module, EntityName, EntityId, NewValuesJson)
    Values
        (
        @ActorId,
            'CREATE',
            'CHAPTER',
            'Chapter',
            Convert(Nvarchar(100), @Id),
            (
                Select
        @Title title
                For Json
                    Path,
                    Without_array_wrapper
    )
    );

    Select
        @Id;

End
Go
Create Or Alter Procedure dbo.LMS_Chapter_Update
    @Id Bigint,
    @Title Nvarchar(500),
    @Description Nvarchar(1000) = Null,
    @SortOrder Int,
    @Status Varchar(30),
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    If Nullif(Ltrim(Rtrim(@Title)), '') Is Null
    Or @SortOrder < 1 Throw 50001,
    N'Dữ liệu chương không hợp lệ.',
    1;

    Update dbo.Chapters
    Set
        Title = @Title,
        Description = @Description,
        SortOrder = @SortOrder,
        Status = @Status,
        UpdatedAt = Sysutcdatetime()
    From dbo.Chapters
        Inner Join dbo.Courses On dbo.Courses.Id = dbo.Chapters.CourseId
    Where (dbo.Chapters.Id = @Id)
        And (dbo.Chapters.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.Courses.TeacherId = @ActorId);

    Declare @Rows Int = @@Rowcount;

    If @Rows > 0
    Insert dbo.AuditLogs (UserId, Action, Module, EntityName, EntityId)
    Values
        (@ActorId, 'UPDATE', 'CHAPTER', 'Chapter', Convert(Nvarchar(100), @Id));

    Select
        @Rows;

End
Go
Create Or Alter Procedure dbo.LMS_Chapter_Delete
    @Id Bigint,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Set Xact_abort On;

    Begin Transaction;

    Update dbo.Chapters
    Set
        IsDeleted = 1,
        UpdatedAt = Sysutcdatetime()
    From dbo.Chapters
        Inner Join dbo.Courses On dbo.Courses.Id = dbo.Chapters.CourseId
    Where (dbo.Chapters.Id = @Id)
        And (dbo.Chapters.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.Courses.TeacherId = @ActorId);

    Declare @Rows Int = @@Rowcount;

    If @Rows > 0
    Begin
        Update dbo.Lessons
        Set
            IsDeleted = 1,
            UpdatedAt = Sysutcdatetime()
        Where (ChapterId = @Id);

        Insert dbo.AuditLogs (UserId, Action, Module, EntityName, EntityId)
        Values
            (@ActorId, 'DELETE', 'CHAPTER', 'Chapter', Convert(Nvarchar(100), @Id));

    End;

    Commit;

    Select
        @Rows;

End
Go
Create Or Alter Procedure dbo.LMS_Chapter_Reorder
    @Id Bigint,
    @SortOrder Int,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Update dbo.Chapters
    Set
        SortOrder = @SortOrder,
        UpdatedAt = Sysutcdatetime()
    From dbo.Chapters
        Inner Join dbo.Courses On dbo.Courses.Id = dbo.Chapters.CourseId
    Where (dbo.Chapters.Id = @Id)
        And (dbo.Chapters.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.Courses.TeacherId = @ActorId);

    If @@Rowcount = 0 Throw 50003,
    N'Không thể sắp xếp chương này.',
    1;

End
Go
Create Or Alter Procedure dbo.LMS_Lesson_GetById
    @Id Bigint,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Select
        dbo.Lessons.*
    From dbo.Lessons
        Inner Join dbo.Courses On dbo.Courses.Id = dbo.Lessons.CourseId
    Where (dbo.Lessons.Id = @Id)
        And (dbo.Lessons.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.Courses.TeacherId = @ActorId);

End
Go
Create Or Alter Procedure dbo.LMS_Lesson_Create
    @ChapterId Bigint,
    @Title Nvarchar(500),
    @Description Nvarchar(1000) = Null,
    @LessonType Varchar(50),
    @DurationSeconds Int,
    @SortOrder Int,
    @IsRequired Bit,
    @PassingScore Decimal(5, 2) = Null,
    @ContentHtml Nvarchar(Max) = Null,
    @DocumentUrl Nvarchar(1000) = Null,
    @AssignmentFolderName Nvarchar(250) = Null,
    @AssignmentStartAt Datetime2 = Null,
    @DueAt Datetime2 = Null,
    @AssignmentMaxScore Decimal(8, 2) = 100,
    @MaxSubmissionAttempts Int = 3,
    @MaxSubmissionFileSizeMB Int = 50,
    @AllowLateSubmission Bit = 0,
    @Status Varchar(30),
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Declare @CourseId Bigint = (
        Select
            dbo.Chapters.CourseId
        From dbo.Chapters
            Inner Join dbo.Courses On dbo.Courses.Id = dbo.Chapters.CourseId
        Where (dbo.Chapters.Id = @ChapterId)
            And (dbo.Chapters.IsDeleted = 0)
            And (@IsAdmin = 1 Or dbo.Courses.TeacherId = @ActorId)
    );

    If @CourseId Is Null Throw 50003,
    N'Bạn không có quyền quản lý chương này.',
    1;

    If Nullif(Ltrim(Rtrim(@Title)), '') Is Null
    Or @LessonType Not In ('VIDEO', 'INTERACTIVE_VIDEO', 'QUIZ', 'DOCUMENT', 'EDITOR', 'ASSIGNMENT')
    Or @DurationSeconds < 0
    Or @SortOrder < 1
    Or @AssignmentMaxScore Not Between 1 And 10000
    Or @MaxSubmissionAttempts Not Between 1 And 20
    Or @MaxSubmissionFileSizeMB Not Between 1 And 200
    Or @PassingScore Not Between 0 And 100  Throw 50001,
    N'Dữ liệu bài học không hợp lệ.',
    1;

    Insert dbo.Lessons (CourseId, ChapterId, Title, Description, LessonType, DurationSeconds, SortOrder, IsRequired, PassingScore, ContentHtml, DocumentUrl, AssignmentFolderName, AssignmentStartAt, DueAt, AssignmentMaxScore, MaxSubmissionAttempts, MaxSubmissionFileSizeMB, AllowLateSubmission, Status)
    Values
        (@CourseId, @ChapterId, @Title, @Description, @LessonType, @DurationSeconds, @SortOrder, @IsRequired, @PassingScore, @ContentHtml, @DocumentUrl, @AssignmentFolderName, @AssignmentStartAt, @DueAt, @AssignmentMaxScore, @MaxSubmissionAttempts, @MaxSubmissionFileSizeMB, @AllowLateSubmission, @Status);

    Declare @Id Bigint = Scope_identity();

    Insert dbo.AuditLogs (UserId, Action, Module, EntityName, EntityId)
    Values
        (@ActorId, 'CREATE', 'LESSON', 'Lesson', Convert(Nvarchar(100), @Id));

    Select
        @Id;

End
Go
Create Or Alter Procedure dbo.LMS_Lesson_Update
    @Id Bigint,
    @Title Nvarchar(500),
    @Description Nvarchar(1000) = Null,
    @LessonType Varchar(50),
    @DurationSeconds Int,
    @SortOrder Int,
    @IsRequired Bit,
    @PassingScore Decimal(5, 2) = Null,
    @ContentHtml Nvarchar(Max) = Null,
    @DocumentUrl Nvarchar(1000) = Null,
    @AssignmentFolderName Nvarchar(250) = Null,
    @AssignmentStartAt Datetime2 = Null,
    @DueAt Datetime2 = Null,
    @AssignmentMaxScore Decimal(8, 2) = 100,
    @MaxSubmissionAttempts Int = 3,
    @MaxSubmissionFileSizeMB Int = 50,
    @AllowLateSubmission Bit = 0,
    @Status Varchar(30),
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    If Nullif(Ltrim(Rtrim(@Title)), '') Is Null
    Or @LessonType Not In ('VIDEO', 'INTERACTIVE_VIDEO', 'QUIZ', 'DOCUMENT', 'EDITOR', 'ASSIGNMENT')
    Or @DurationSeconds < 0
    Or @SortOrder < 1
    Or @AssignmentMaxScore Not Between 1 And 10000
    Or @MaxSubmissionAttempts Not Between 1 And 20
    Or @MaxSubmissionFileSizeMB Not Between 1 And 200
    Or @PassingScore Not Between 0 And 100  Throw 50001,
    N'Dữ liệu bài học không hợp lệ.',
    1;

    Update dbo.Lessons
    Set
        Title = @Title,
        Description = @Description,
        LessonType = @LessonType,
        DurationSeconds = @DurationSeconds,
        SortOrder = @SortOrder,
        IsRequired = @IsRequired,
        PassingScore = @PassingScore,
        ContentHtml = @ContentHtml,
        DocumentUrl = @DocumentUrl,
        AssignmentFolderName = @AssignmentFolderName,
        AssignmentStartAt = @AssignmentStartAt,
        DueAt = @DueAt,
        AssignmentMaxScore = @AssignmentMaxScore,
        MaxSubmissionAttempts = @MaxSubmissionAttempts,
        MaxSubmissionFileSizeMB = @MaxSubmissionFileSizeMB,
        AllowLateSubmission = @AllowLateSubmission,
        Status = @Status,
        UpdatedAt = Sysutcdatetime()
    From dbo.Lessons
        Inner Join dbo.Courses On dbo.Courses.Id = dbo.Lessons.CourseId
    Where (dbo.Lessons.Id = @Id)
        And (dbo.Lessons.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.Courses.TeacherId = @ActorId);

    Declare @Rows Int = @@Rowcount;

    If @Rows > 0
    Insert dbo.AuditLogs (UserId, Action, Module, EntityName, EntityId)
    Values
        (@ActorId, 'UPDATE', 'LESSON', 'Lesson', Convert(Nvarchar(100), @Id));

    Select
        @Rows;

End
Go
Create Or Alter Procedure dbo.LMS_Lesson_Delete
    @Id Bigint,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Update dbo.Lessons
    Set
        IsDeleted = 1,
        UpdatedAt = Sysutcdatetime()
    From dbo.Lessons
        Inner Join dbo.Courses On dbo.Courses.Id = dbo.Lessons.CourseId
    Where (dbo.Lessons.Id = @Id)
        And (dbo.Lessons.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.Courses.TeacherId = @ActorId);

    Declare @Rows Int = @@Rowcount;

    If @Rows > 0
    Insert dbo.AuditLogs (UserId, Action, Module, EntityName, EntityId)
    Values
        (@ActorId, 'DELETE', 'LESSON', 'Lesson', Convert(Nvarchar(100), @Id));

    Select
        @Rows;

End
Go
Create Or Alter Procedure dbo.LMS_Lesson_Reorder
    @Id Bigint,
    @SortOrder Int,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Update dbo.Lessons
    Set
        SortOrder = @SortOrder,
        UpdatedAt = Sysutcdatetime()
    From dbo.Lessons
        Inner Join dbo.Courses On dbo.Courses.Id = dbo.Lessons.CourseId
    Where (dbo.Lessons.Id = @Id)
        And (dbo.Lessons.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.Courses.TeacherId = @ActorId);

    If @@Rowcount = 0 Throw 50003,
    N'Không thể sắp xếp bài học này.',
    1;

End
Go
Create Or Alter Procedure dbo.LMS_Video_GetById
    @Id Bigint,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    If Exists (
        Select
            1
        From dbo.Videos
        Where (Id = @Id)
    )
    And Not Exists (
        Select
            1
        From dbo.Videos
            Inner Join dbo.VideoAssets On dbo.VideoAssets.Id = dbo.Videos.VideoAssetId
        Where (dbo.Videos.Id = @Id)
            And (dbo.VideoAssets.IsDeleted = 0)
            And (@IsAdmin = 1 Or dbo.VideoAssets.CreatedBy = @ActorId)
    ) Throw 50003,
    N'Bạn không có quyền quản lý video này.',
    1;

    Select
        dbo.Videos.*,
        dbo.VideoAssets.CreatedBy,
        dbo.VideoAssets.ShareScope,
        (
            Select
                Count(*)
            From dbo.Lessons
            Where (dbo.Lessons.VideoId = dbo.Videos.Id)
                And (dbo.Lessons.IsDeleted = 0)
    ) AssetUsageCount
    From dbo.Videos
        Inner Join dbo.VideoAssets On dbo.VideoAssets.Id = dbo.Videos.VideoAssetId
    Where (dbo.Videos.Id = @Id)
        And (dbo.VideoAssets.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.VideoAssets.CreatedBy = @ActorId);

End
Go
Create Or Alter Procedure dbo.LMS_Video_Create
    @Id Bigint = Null,
    @LessonId Bigint,
    @Title Nvarchar(500),
    @VideoUrl Nvarchar(1000) = Null,
    @PosterUrl Nvarchar(1000) = Null,
    @DurationSeconds Int,
    @AllowSeek Bit,
    @AllowSpeed Bit,
    @RequiredWatchPercent Decimal(5, 2),
    @Status Varchar(30),
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Set Xact_abort On;

    If @DurationSeconds <= 0
    Or @RequiredWatchPercent Not Between 0 And 100  Throw 50001,
    N'Dữ liệu video không hợp lệ.',
    1;

    If @VideoUrl Is Not Null
    And (@VideoUrl Not Like '/Media/Video/%' Or @VideoUrl Like '%..%' Or @VideoUrl Like '%\%' Or @VideoUrl Like '%?%' Or @VideoUrl Like '%#%') Throw 50001,
    N'VideoUrl phải là URL tương đối an toàn trong /Media/Video/.',
    1;

    If Not Exists (
        Select
            1
        From dbo.Lessons
            Inner Join dbo.Courses On dbo.Courses.Id = dbo.Lessons.CourseId
        Where (dbo.Lessons.Id = @LessonId)
            And (dbo.Lessons.IsDeleted = 0)
            And (@IsAdmin = 1 Or dbo.Courses.TeacherId = @ActorId)
    ) Throw 50003,
    N'Bạn không có quyền quản lý bài học này.',
    1;

    Begin Transaction;

    Insert dbo.VideoAssets (Title, VideoUrl, PosterUrl, DurationSeconds, CreatedBy, Status)
    Values
        (@Title, @VideoUrl, @PosterUrl, @DurationSeconds, @ActorId, @Status);

    Declare @AssetId Bigint = Scope_identity();

    Insert dbo.Videos (VideoAssetId, Title, VideoUrl, PosterUrl, DurationSeconds, AllowSeek, AllowSpeed, RequiredWatchPercent, Status)
    Values
        (@AssetId, @Title, @VideoUrl, @PosterUrl, @DurationSeconds, @AllowSeek, @AllowSpeed, @RequiredWatchPercent, @Status);

    Declare @VideoId Bigint = Scope_identity();

    Update dbo.Lessons
    Set
        VideoId = @VideoId,
        DurationSeconds = @DurationSeconds,
        UpdatedAt = Sysutcdatetime()
    Where (Id = @LessonId);

    Insert dbo.AuditLogs (UserId, Action, Module, EntityName, EntityId)
    Values
        (@ActorId, 'CREATE', 'VIDEO', 'Video', Convert(Nvarchar(100), @VideoId));

    Commit;

    Select
        @VideoId;

End
Go
Create Or Alter Procedure dbo.LMS_Video_Update
    @Id Bigint,
    @LessonId Bigint,
    @Title Nvarchar(500),
    @VideoUrl Nvarchar(1000) = Null,
    @PosterUrl Nvarchar(1000) = Null,
    @DurationSeconds Int,
    @AllowSeek Bit,
    @AllowSpeed Bit,
    @RequiredWatchPercent Decimal(5, 2),
    @Status Varchar(30),
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Set Xact_abort On;

    If @DurationSeconds <= 0
    Or @RequiredWatchPercent Not Between 0 And 100  Throw 50001,
    N'Dữ liệu video không hợp lệ.',
    1;

    If @VideoUrl Is Not Null
    And (@VideoUrl Not Like '/Media/Video/%' Or @VideoUrl Like '%..%' Or @VideoUrl Like '%\%' Or @VideoUrl Like '%?%' Or @VideoUrl Like '%#%') Throw 50001,
    N'VideoUrl phải là URL tương đối an toàn trong /Media/Video/.',
    1;

    Declare @AssetId Bigint = (
        Select
            dbo.Videos.VideoAssetId
        From dbo.Videos
            Inner Join dbo.VideoAssets On dbo.VideoAssets.Id = dbo.Videos.VideoAssetId
        Where (dbo.Videos.Id = @Id)
            And (dbo.VideoAssets.IsDeleted = 0)
            And (@IsAdmin = 1 Or dbo.VideoAssets.CreatedBy = @ActorId)
    );

    If @AssetId Is Null Throw 50003,
    N'Bạn không có quyền quản lý video này.',
    1;

    Begin Transaction;

    Update dbo.Videos
    Set
        Title = @Title,
        VideoUrl = @VideoUrl,
        PosterUrl = @PosterUrl,
        DurationSeconds = @DurationSeconds,
        AllowSeek = @AllowSeek,
        AllowSpeed = @AllowSpeed,
        RequiredWatchPercent = @RequiredWatchPercent,
        Status = @Status,
        UpdatedAt = Sysutcdatetime()
    Where (Id = @Id);

    Update dbo.VideoAssets
    Set
        Title = @Title,
        VideoUrl = @VideoUrl,
        PosterUrl = @PosterUrl,
        DurationSeconds = @DurationSeconds,
        Status = @Status,
        UpdatedAt = Sysutcdatetime()
    Where (Id = @AssetId);

    Update dbo.Lessons
    Set
        DurationSeconds = @DurationSeconds,
        UpdatedAt = Sysutcdatetime()
    From dbo.Lessons
    Where (dbo.Lessons.VideoId = @Id)
        And (dbo.Lessons.IsDeleted = 0);

    Insert dbo.AuditLogs (UserId, Action, Module, EntityName, EntityId)
    Values
        (@ActorId, 'UPDATE', 'VIDEO', 'Video', Convert(Nvarchar(100), @Id));

    Commit;

    Select
        @Id;

End
Go
Create Or Alter Procedure dbo.LMS_VideoLibrary_GetList
    @Search Nvarchar(500) = Null,
    @Access Varchar(30) = 'ALL',
    @Source Varchar(30) = 'ALL',
    @Usage Varchar(30) = 'ALL',
    @Status Varchar(30) = 'ALL',
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Select
        dbo.VideoAssets.Id,
        dbo.VideoAssets.Title,
        dbo.VideoAssets.SourceType,
        dbo.VideoAssets.VideoUrl,
        dbo.VideoAssets.PosterUrl,
        dbo.VideoAssets.DurationSeconds,
        dbo.VideoAssets.OriginalFileName,
        dbo.VideoAssets.FileSize,
        dbo.VideoAssets.MimeType,
        dbo.VideoAssets.Status,
        dbo.VideoAssets.CreatedAt,
        dbo.VideoAssets.CreatedBy,
        dbo.Users.FullName CreatedByName,
        dbo.VideoAssets.ShareScope,
        Isnull(useInfo.UsageCount, 0) UsageCount,
        videoInfo.VideoId,
        videoInfo.VideoId FirstVideoId,
        Cast(Iif(dbo.VideoAssets.CreatedBy = @ActorId, 1, 0) As Bit) IsOwner,
        Cast(Case When (@IsAdmin = 1 Or dbo.VideoAssets.CreatedBy = @ActorId) And learningResultInfo.HasLearningResults = 0 Then 1 Else 0 End As Bit) CanEdit,
        Cast(Case When @IsAdmin = 1 Or dbo.VideoAssets.CreatedBy = @ActorId Then 1 Else 0 End As Bit) CanOpenEditor,
        Cast(1 As Bit) CanDuplicate,
        learningResultInfo.HasLearningResults,
        learningResultInfo.AnswerCount,
        Cast(
            Iif(
        @IsAdmin = 1
                Or dbo.VideoAssets.CreatedBy = @ActorId,
                1,
                0
    ) As Bit
    ) CanShare,
        Cast(
            Iif(
                (
        @IsAdmin = 1
                    Or dbo.VideoAssets.CreatedBy = @ActorId
    )
                And Isnull(useInfo.UsageCount, 0) = 0,
                1,
                0
    ) As Bit
    ) CanDelete,
        Case When dbo.VideoAssets.CreatedBy = @ActorId Then 'OWNER' When dbo.VideoAssets.ShareScope = 'SCHOOL' Then 'SCHOOL' When directShare.IsShared = 1 Then 'SHARED' Else 'ADMIN' End AccessType,
        Isnull(shareInfo.ShareCount, 0) SharedTeacherCount
    From dbo.VideoAssets
        Inner Join dbo.Users On dbo.Users.Id = dbo.VideoAssets.CreatedBy
        Outer Apply (
            Select
                Count(*) UsageCount
            From dbo.Videos
                Inner Join dbo.Lessons On dbo.Lessons.VideoId = dbo.Videos.Id And dbo.Lessons.IsDeleted = 0
            Where (dbo.Videos.VideoAssetId = dbo.VideoAssets.Id)
    ) useInfo
        Outer Apply (
            Select
                Min(dbo.Videos.Id) VideoId
            From dbo.Videos
            Where (dbo.Videos.VideoAssetId = dbo.VideoAssets.Id)
    ) videoInfo
        Outer Apply
        (
            Select
                Cast(Case When Exists
                    (
                        Select
                            1
                        From dbo.StudentAnswers
                        Where (dbo.StudentAnswers.VideoId = videoInfo.VideoId)
                    )
                    Or Exists
                    (
                        Select
                            1
                        From dbo.StudentLessonProgress
                            Inner Join dbo.Lessons On dbo.Lessons.Id = dbo.StudentLessonProgress.LessonId
                        Where (dbo.Lessons.VideoId = videoInfo.VideoId)
                            And (dbo.StudentLessonProgress.Score > 0)
                    ) Then 1 Else 0 End As Bit) HasLearningResults,
                (
                    Select
                        Count(*)
                    From dbo.StudentAnswers
                    Where (dbo.StudentAnswers.VideoId = videoInfo.VideoId)
                ) AnswerCount
        ) learningResultInfo
        Outer Apply (
            Select
                Cast(
                    Iif(
                        Exists (
                            Select
                                1
                            From dbo.VideoAssetShares
                            Where (dbo.VideoAssetShares.VideoAssetId = dbo.VideoAssets.Id)
                                And (dbo.VideoAssetShares.TeacherId = @ActorId)
    ),
                        1,
                        0
    ) As Bit
    ) IsShared
    ) directShare
        Outer Apply (
            Select
                Count(*) ShareCount
            From dbo.VideoAssetShares
            Where (dbo.VideoAssetShares.VideoAssetId = dbo.VideoAssets.Id)
    ) shareInfo
    Where (dbo.VideoAssets.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.VideoAssets.CreatedBy = @ActorId Or dbo.VideoAssets.ShareScope = 'SCHOOL' Or directShare.IsShared = 1)
        And (@Access Is Null Or @Access = '' Or @Access = 'ALL' Or (@Access = 'MINE' And dbo.VideoAssets.CreatedBy = @ActorId) Or (@Access = 'SHARED' And dbo.VideoAssets.CreatedBy <> @ActorId And (dbo.VideoAssets.ShareScope = 'SCHOOL' Or directShare.IsShared = 1)) Or (@Access = 'SCHOOL' And dbo.VideoAssets.ShareScope = 'SCHOOL'))
        And (@Status Is Null Or @Status = '' Or @Status = 'ALL' Or dbo.VideoAssets.Status = @Status)
        And (@Usage Is Null Or @Usage = '' Or @Usage = 'ALL' Or (@Usage = 'USED' And Isnull(useInfo.UsageCount, 0) > 0) Or (@Usage = 'UNUSED' And Isnull(useInfo.UsageCount, 0) = 0))
        And (@Source Is Null Or @Source = '' Or @Source = 'ALL' Or dbo.VideoAssets.SourceType = @Source)
        And (@Search Is Null Or @Search = '' Or dbo.VideoAssets.Title Like '%' + @Search + '%' Or dbo.VideoAssets.OriginalFileName Like '%' + @Search + '%' Or dbo.Users.FullName Like '%' + @Search + '%')
    Order By
        dbo.VideoAssets.CreatedAt Desc,
        dbo.VideoAssets.Id Desc;

End
Go
Create Or Alter Procedure dbo.LMS_VideoLibrary_Create
    @Title Nvarchar(500),
    @VideoUrl Nvarchar(1000) = Null,
    @PosterUrl Nvarchar(1000) = Null,
    @DurationSeconds Int,
    @OriginalFileName Nvarchar(500) = Null,
    @FileSize Bigint = Null,
    @MimeType Nvarchar(150) = Null,
    @ActorId Bigint
As
Begin
    Set Nocount On;

    Set Xact_abort On;

    If Nullif(Ltrim(Rtrim(@Title)), '') Is Null
    Or @DurationSeconds <= 0 Throw 50001,
    N'Dữ liệu video thư viện không hợp lệ.',
    1;

    If @VideoUrl Is Not Null
    And (@VideoUrl Not Like '/Media/Video/%' Or @VideoUrl Like '%..%' Or @VideoUrl Like '%\%' Or @VideoUrl Like '%?%' Or @VideoUrl Like '%#%') Throw 50001,
    N'VideoUrl không hợp lệ.',
    1;

    Begin Transaction;

    Insert dbo.VideoAssets (Title, VideoUrl, PosterUrl, DurationSeconds, OriginalFileName, FileSize, MimeType, CreatedBy)
    Values
        (@Title, @VideoUrl, @PosterUrl, @DurationSeconds, @OriginalFileName, @FileSize, @MimeType, @ActorId);

    Declare @AssetId Bigint = Scope_identity();

    Insert dbo.Videos (VideoAssetId, Title, VideoUrl, PosterUrl, DurationSeconds, AllowSeek, AllowSpeed, RequiredWatchPercent, Status)
    Values
        (@AssetId, @Title, @VideoUrl, @PosterUrl, @DurationSeconds, 0, 1, 80, 'ACTIVE');

    Declare @VideoId Bigint = Scope_identity();

    Insert dbo.AuditLogs (UserId, Action, Module, EntityName, EntityId)
    Values
        (@ActorId, 'CREATE', 'VIDEO_LIBRARY', 'Video', Convert(Nvarchar(100), @VideoId));

    Commit;

    Select
        @AssetId;

End
Go
Create Or Alter Procedure dbo.LMS_VideoLibrary_Update
    @Id Bigint,
    @Title Nvarchar(500),
    @VideoUrl Nvarchar(1000),
    @PosterUrl Nvarchar(1000) = Null,
    @DurationSeconds Int,
    @OriginalFileName Nvarchar(500) = Null,
    @FileSize Bigint = Null,
    @MimeType Nvarchar(150) = Null,
    @Status Varchar(30) = 'ACTIVE',
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Set Xact_abort On;

    If Nullif(Ltrim(Rtrim(@Title)), '') Is Null
    Or @DurationSeconds <= 0
    Or @Status Not In ('ACTIVE', 'INACTIVE') Throw 50001,
    N'Dữ liệu video thư viện không hợp lệ.',
    1;

    If @VideoUrl Not Like '/Media/Video/%'
    Or @VideoUrl Like '%..%'
    Or @VideoUrl Like '%\%'
    Or @VideoUrl Like '%?%'
    Or @VideoUrl Like '%#%' Throw 50001,
    N'VideoUrl không hợp lệ.',
    1;

    If Exists (
        Select
            1
        From dbo.VideoAssets
        Where (Id = @Id)
            And (IsDeleted = 0)
    )
    And Not Exists (
        Select
            1
        From dbo.VideoAssets
        Where (Id = @Id)
            And (IsDeleted = 0)
            And (@IsAdmin = 1 Or CreatedBy = @ActorId)
    ) Throw 50003,
    N'Bạn không có quyền sửa video này.',
    1;

    Begin Transaction;

    Update dbo.VideoAssets
    Set
        Title = @Title,
        VideoUrl = @VideoUrl,
        PosterUrl = @PosterUrl,
        DurationSeconds = @DurationSeconds,
        OriginalFileName = Coalesce(@OriginalFileName, OriginalFileName),
        FileSize = Coalesce(@FileSize, FileSize),
        MimeType = Coalesce(@MimeType, MimeType),
        Status = @Status,
        UpdatedAt = Sysutcdatetime()
    Where (Id = @Id)
        And (IsDeleted = 0)
        And (@IsAdmin = 1 Or CreatedBy = @ActorId);

    Declare @Rows Int = @@Rowcount;

    If @Rows > 0
    Begin
        Update dbo.Videos
        Set
            Title = @Title,
            VideoUrl = @VideoUrl,
            PosterUrl = @PosterUrl,
            DurationSeconds = @DurationSeconds,
            Status = @Status,
            UpdatedAt = Sysutcdatetime()
        Where (VideoAssetId = @Id);

        Update dbo.Lessons
        Set
            DurationSeconds = @DurationSeconds,
            UpdatedAt = Sysutcdatetime()
        From dbo.Lessons
            Inner Join dbo.Videos On dbo.Videos.Id = dbo.Lessons.VideoId
        Where (dbo.Videos.VideoAssetId = @Id)
            And (dbo.Lessons.IsDeleted = 0);

        Insert dbo.AuditLogs (UserId, Action, Module, EntityName, EntityId, NewValuesJson)
        Values
            (
            @ActorId,
                'UPDATE',
                'VIDEO_LIBRARY',
                'VideoAsset',
                Convert(Nvarchar(100), @Id),
                (
                    Select
            @Title title,
            @Status status
                    For Json
                        Path,
                        Without_array_wrapper
        )
        );

    End;

    Commit;

    Select
        @Rows;

End
Go
Create Or Alter Procedure dbo.LMS_VideoLibrary_Delete
    @Id Bigint,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    If Exists (
        Select
            1
        From dbo.VideoAssets
        Where (Id = @Id)
            And (IsDeleted = 0)
    )
    And Not Exists (
        Select
            1
        From dbo.VideoAssets
        Where (Id = @Id)
            And (IsDeleted = 0)
            And (@IsAdmin = 1 Or CreatedBy = @ActorId)
    ) Throw 50003,
    N'Chỉ tác giả video mới có quyền xóa.',
    1;

    If Exists (
        Select
            1
        From dbo.Videos
            Inner Join dbo.Lessons On dbo.Lessons.VideoId = dbo.Videos.Id
        Where (dbo.Videos.VideoAssetId = @Id)
            And (dbo.Lessons.IsDeleted = 0)
    ) Throw 50006,
    N'Video đang được sử dụng trong bài học nên không thể xóa.',
    1;

    Update dbo.VideoAssets
    Set
        IsDeleted = 1,
        UpdatedAt = Sysutcdatetime()
    Where (Id = @Id)
        And (IsDeleted = 0)
        And (@IsAdmin = 1 Or CreatedBy = @ActorId);

    Declare @Rows Int = @@Rowcount;

    If @Rows > 0
    Insert dbo.AuditLogs (UserId, Action, Module, EntityName, EntityId)
    Values
        (@ActorId, 'DELETE', 'VIDEO_LIBRARY', 'VideoAsset', Convert(Nvarchar(100), @Id));

    Select
        @Rows;

End
Go
Create Or Alter Procedure dbo.LMS_VideoLibrary_Sharing_Get
    @Id Bigint,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    If Not Exists (
        Select
            1
        From dbo.VideoAssets
        Where (Id = @Id)
            And (IsDeleted = 0)
            And (@IsAdmin = 1 Or CreatedBy = @ActorId)
    ) Throw 50003,
    N'Chỉ tác giả video mới được quản lý chia sẻ.',
    1;

    Select
        Id,
        Title,
        ShareScope,
        CreatedBy
    From dbo.VideoAssets
    Where (Id = @Id)
        And (IsDeleted = 0);

    Select
        dbo.Users.Id,
        dbo.Users.FullName,
        dbo.Users.Email,
        dbo.Users.TeacherCode,
        Cast(Iif(dbo.VideoAssetShares.Id Is Null, 0, 1) As Bit) IsSelected
    From dbo.Users
        Left Join dbo.VideoAssetShares On dbo.VideoAssetShares.VideoAssetId = @Id And dbo.VideoAssetShares.TeacherId = dbo.Users.Id
    Where (dbo.Users.TeacherCode Is Not Null)
        And (dbo.Users.IsDeleted = 0)
        And (dbo.Users.Status = 'ACTIVE')
        And dbo.Users.Id <> (
            Select
                CreatedBy
            From dbo.VideoAssets
            Where (Id = @Id)
    )
    Order By
        dbo.Users.FullName,
        dbo.Users.Id;

End
Go
Create Or Alter Procedure dbo.LMS_VideoLibrary_Sharing_Save
    @Id Bigint,
    @ShareScope Varchar(20),
    @TeacherIdsJson Nvarchar(Max) = N'[]',
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Set Xact_abort On;

    If @ShareScope Not In ('PRIVATE', 'SELECTED', 'SCHOOL') Throw 50001,
    N'Phạm vi chia sẻ không hợp lệ.',
    1;

    If Not Exists (
        Select
            1
        From dbo.VideoAssets
        Where (Id = @Id)
            And (IsDeleted = 0)
            And (@IsAdmin = 1 Or CreatedBy = @ActorId)
    ) Throw 50003,
    N'Chỉ tác giả video mới được quản lý chia sẻ.',
    1;

    Begin Transaction;

    Delete dbo.VideoAssetShares
    Where (VideoAssetId = @Id);

    If @ShareScope = 'SELECTED'
    Begin
        Insert dbo.VideoAssetShares (VideoAssetId, TeacherId, SharedBy)
        Select
            @Id,
            dbo.Users.Id,
            @ActorId
        From dbo.Users
        Where (dbo.Users.TeacherCode Is Not Null)
            And (dbo.Users.IsDeleted = 0)
            And (dbo.Users.Status = 'ACTIVE')
            And dbo.Users.Id <> (
                Select
                    CreatedBy
                From dbo.VideoAssets
                Where (Id = @Id)
        )
            And dbo.Users.Id In (
                Select
                    Try_convert(Bigint, [value])
                From Openjson(Coalesce(@TeacherIdsJson, N'[]'))
                Where (Try_convert(Bigint, [value]) Is Not Null)
        );

        If Not Exists (
            Select
                1
            From dbo.VideoAssetShares
            Where (VideoAssetId = @Id)
        ) Throw 50001,
        N'Hãy chọn ít nhất một giáo viên để chia sẻ.',
        1;

    End;

    Update dbo.VideoAssets
    Set
        ShareScope = @ShareScope,
        UpdatedAt = Sysutcdatetime()
    Where (Id = @Id);

    If @ShareScope In ('SELECTED', 'SCHOOL')
    Begin
        Insert Into dbo.SYS_Notifications
        (
            RecipientUserID,
            ActorUserID,
            NotificationType,
            Title,
            Message,
            ReferenceType,
            ReferenceID,
            ActionUrl
        )
        Select
            TeacherUser.UserID,
            @ActorId,
            'VIDEO_SHARED',
            N'Video được chia sẻ với bạn',
            Concat(ActorUser.FullName, N' đã chia sẻ video “', dbo.SIM_VideoAssets.Title, N'”.'),
            'VIDEO_ASSET',
            dbo.SIM_VideoAssets.VideoAssetID,
            N'/cms/videos'
        From dbo.SIM_VideoAssets
        Cross Join dbo.SYS_Users As TeacherUser
        Inner Join dbo.SYS_Users As ActorUser On ActorUser.UserID = @ActorId
        Where (dbo.SIM_VideoAssets.VideoAssetID = @Id)
            And (TeacherUser.TeacherCode Is Not Null)
            And (TeacherUser.UserID <> @ActorId)
            And (TeacherUser.IsDeleted = 0)
            And (TeacherUser.Status = 'ACTIVE')
            And
            (
                @ShareScope = 'SCHOOL'
                Or Exists
                (
                    Select
                        1
                    From dbo.SIM_VideoAssetShares
                    Where (dbo.SIM_VideoAssetShares.VideoAssetID = @Id)
                        And (dbo.SIM_VideoAssetShares.TeacherUserID = TeacherUser.UserID)
                )
            )
            And Not Exists
            (
                Select
                    1
                From dbo.SYS_Notifications
                Where (dbo.SYS_Notifications.RecipientUserID = TeacherUser.UserID)
                    And (dbo.SYS_Notifications.NotificationType = 'VIDEO_SHARED')
                    And (dbo.SYS_Notifications.ReferenceType = 'VIDEO_ASSET')
                    And (dbo.SYS_Notifications.ReferenceID = @Id)
                    And (dbo.SYS_Notifications.IsRead = 0)
            );
    End;

    Insert dbo.AuditLogs (UserId, Action, Module, EntityName, EntityId, NewValuesJson)
    Values
        (
        @ActorId,
            'SHARE',
            'VIDEO_LIBRARY',
            'VideoAsset',
            Convert(Nvarchar(100), @Id),
            (
                Select
        @ShareScope shareScope,
        @TeacherIdsJson teacherIds
                For Json
                    Path,
                    Without_array_wrapper
    )
    );

    Commit;

    Select
        @Id;

End
Go
Create Or Alter Procedure dbo.LMS_VideoLibrary_Attach
    @LessonId Bigint,
    @VideoAssetId Bigint,
    @AllowSeek Bit,
    @AllowSpeed Bit,
    @RequiredWatchPercent Decimal(5, 2),
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    If @RequiredWatchPercent Not Between 0 And 100  Throw 50001,
    N'Tỷ lệ xem bắt buộc không hợp lệ.',
    1;

    If Not Exists (
        Select
            1
        From dbo.Lessons
            Inner Join dbo.Courses On dbo.Courses.Id = dbo.Lessons.CourseId
        Where (dbo.Lessons.Id = @LessonId)
            And (dbo.Lessons.IsDeleted = 0)
            And (dbo.Lessons.LessonType In ('VIDEO', 'INTERACTIVE_VIDEO'))
            And (@IsAdmin = 1 Or dbo.Courses.TeacherId = @ActorId)
    ) Throw 50003,
    N'Bạn không có quyền quản lý bài học này.',
    1;

    Declare @VideoId Bigint,
        @DurationSeconds Int;

    Select
        @VideoId = dbo.Videos.Id,
        @DurationSeconds = dbo.Videos.DurationSeconds
    From dbo.VideoAssets
        Inner Join dbo.Videos On dbo.Videos.VideoAssetId = dbo.VideoAssets.Id
    Where (dbo.VideoAssets.Id = @VideoAssetId)
        And (dbo.VideoAssets.IsDeleted = 0)
        And (dbo.VideoAssets.Status = 'ACTIVE')
        And (dbo.Videos.Status = 'ACTIVE')
        And (
        @IsAdmin = 1
            Or (dbo.VideoAssets.CreatedBy = @ActorId)
            Or (dbo.VideoAssets.ShareScope = 'SCHOOL')
            Or Exists (
                Select
                    1
                From dbo.VideoAssetShares
                Where (dbo.VideoAssetShares.VideoAssetId = dbo.VideoAssets.Id)
                    And (dbo.VideoAssetShares.TeacherId = @ActorId)
    )
    );

    If @VideoId Is Null Throw 50003,
    N'Video không tồn tại hoặc chưa được tác giả chia sẻ cho bạn.',
    1;

    Update dbo.Lessons
    Set
        VideoId = @VideoId,
        DurationSeconds = @DurationSeconds,
        UpdatedAt = Sysutcdatetime()
    Where (Id = @LessonId);

    Insert dbo.AuditLogs (UserId, Action, Module, EntityName, EntityId)
    Values
        (@ActorId, 'ATTACH', 'VIDEO_LIBRARY', 'Video', Convert(Nvarchar(100), @VideoId));

    Select
        @VideoId;

End
Go
Create Or Alter Procedure dbo.LMS_Video_AttachToLesson
    @LessonId Bigint,
    @VideoId Bigint,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    If Not Exists (
        Select
            1
        From dbo.Lessons
            Inner Join dbo.Courses On dbo.Courses.Id = dbo.Lessons.CourseId
        Where (dbo.Lessons.Id = @LessonId)
            And (dbo.Lessons.IsDeleted = 0)
            And (dbo.Lessons.LessonType In ('VIDEO', 'INTERACTIVE_VIDEO'))
            And (@IsAdmin = 1 Or dbo.Courses.TeacherId = @ActorId)
    ) Throw 50003,
    N'Bạn không có quyền quản lý bài học này.',
    1;

    Declare @DurationSeconds Int;

    Select
        @DurationSeconds = dbo.Videos.DurationSeconds
    From dbo.Videos
        Inner Join dbo.VideoAssets On dbo.VideoAssets.Id = dbo.Videos.VideoAssetId
    Where (dbo.Videos.Id = @VideoId)
        And (dbo.Videos.Status = 'ACTIVE')
        And (dbo.VideoAssets.IsDeleted = 0)
        And (dbo.VideoAssets.Status = 'ACTIVE')
        And (
        @IsAdmin = 1
            Or (dbo.VideoAssets.CreatedBy = @ActorId)
            Or (dbo.VideoAssets.ShareScope = 'SCHOOL')
            Or Exists (
                Select
                    1
                From dbo.VideoAssetShares
                Where (dbo.VideoAssetShares.VideoAssetId = dbo.VideoAssets.Id)
                    And (dbo.VideoAssetShares.TeacherId = @ActorId)
    )
    );

    If @DurationSeconds Is Null Throw 50003,
    N'Video không tồn tại hoặc chưa được tác giả chia sẻ cho bạn.',
    1;

    Update dbo.Lessons
    Set
        VideoId = @VideoId,
        DurationSeconds = @DurationSeconds,
        UpdatedAt = Sysutcdatetime()
    Where (Id = @LessonId);

    Insert dbo.AuditLogs (UserId, Action, Module, EntityName, EntityId, NewValuesJson)
    Values
        (
        @ActorId,
            'ATTACH',
            'VIDEO_LIBRARY',
            'Lesson',
            Convert(Nvarchar(100), @LessonId),
            (
                Select
        @VideoId videoId
                For Json
                    Path,
                    Without_array_wrapper
    )
    );

    Select
        @VideoId;

End
Go
Create Or Alter Procedure dbo.LMS_VideoInteraction_GetByVideo
    @VideoId Bigint,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    If Not Exists (
        Select
            1
        From dbo.Videos
            Inner Join dbo.VideoAssets On dbo.VideoAssets.Id = dbo.Videos.VideoAssetId
        Where (dbo.Videos.Id = @VideoId)
            And (dbo.VideoAssets.IsDeleted = 0)
            And (@IsAdmin = 1 Or dbo.VideoAssets.CreatedBy = @ActorId)
    ) Throw 50003,
    N'Bạn không có quyền quản lý video này.',
    1;

    Select
        dbo.VideoInteractions.*,
        dbo.Questions.QuestionText,
        dbo.Questions.QuestionType,
        dbo.Questions.Description,
        (
            Select
                dbo.QuestionOptions.OptionCode,
                dbo.QuestionOptions.OptionText
            From dbo.QuestionOptions
            Where (dbo.QuestionOptions.QuestionId = dbo.Questions.Id)
                And (dbo.QuestionOptions.IsDeleted = 0)
            Order By
                dbo.QuestionOptions.SortOrder
            For Json
                Path
    ) Options
    From dbo.VideoInteractions
        Inner Join dbo.Questions On dbo.Questions.Id = dbo.VideoInteractions.QuestionId
    Where (dbo.VideoInteractions.VideoId = @VideoId)
        And (dbo.VideoInteractions.IsDeleted = 0)
    Order By
        dbo.VideoInteractions.TimeSeconds,
        dbo.VideoInteractions.SortOrder;

End
Go
Create Or Alter Procedure dbo.LMS_VideoInteraction_PreviewAnswer
    @VideoId Bigint,
    @InteractionId Bigint,
    @QuestionId Bigint,
    @AnswerText Nvarchar(Max),
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Declare @Type Varchar(50),
        @Mode Varchar(30),
        @Score Decimal(8, 2),
        @Correct Nvarchar(Max),
        @IsCorrect Bit;

    Select
        @Type = dbo.Questions.QuestionType,
        @Mode = dbo.Questions.ShortAnswerMode,
        @Score = dbo.VideoInteractions.Score
    From dbo.VideoInteractions
        Inner Join dbo.Videos On dbo.Videos.Id = dbo.VideoInteractions.VideoId
        Inner Join dbo.VideoAssets On dbo.VideoAssets.Id = dbo.Videos.VideoAssetId
        Inner Join dbo.Questions On dbo.Questions.Id = dbo.VideoInteractions.QuestionId
    Where (dbo.VideoInteractions.Id = @InteractionId)
        And (dbo.VideoInteractions.VideoId = @VideoId)
        And (dbo.VideoInteractions.QuestionId = @QuestionId)
        And (dbo.VideoInteractions.IsDeleted = 0)
        And (dbo.VideoInteractions.Status = 'ACTIVE')
        And (dbo.Questions.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.VideoAssets.CreatedBy = @ActorId);

    If @Type Is Null Throw 50003,
    N'Bạn không có quyền xem trước câu hỏi này.',
    1;

    If @Type In ('SINGLE_CHOICE', 'TRUE_FALSE', 'MULTIPLE_CHOICE')
    Begin
        Select
            @Correct = String_agg(Upper(Ltrim(Rtrim(OptionCode))), '|') Within Group (
                Order By
                    Upper(Ltrim(Rtrim(OptionCode)))
        )
        From dbo.QuestionOptions
        Where (QuestionId = @QuestionId)
            And (IsCorrect = 1)
            And (IsDeleted = 0);

        Set @IsCorrect = Iif(Upper(Isnull(@AnswerText, '')) = Isnull(@Correct, ''), 1, 0);

    End Else If @Mode = 'MANUAL_REVIEW'
    Set @IsCorrect = Null;

    Else If @Mode = 'CONTAINS'
    Set @IsCorrect = Iif(
            Exists (
                Select
                    1
                From dbo.QuestionAnswerKeys
                Where (QuestionId = @QuestionId)
                    And ((IsCaseSensitive = 1 And Charindex(AnswerText, @AnswerText collate Latin1_General_100_CS_AS) > 0) Or (IsCaseSensitive = 0 And Charindex(Lower(AnswerText), Lower(@AnswerText)) > 0))
    ),
            1,
            0
    );

    Else
    Set @IsCorrect = Iif(
            Exists (
                Select
                    1
                From dbo.QuestionAnswerKeys
                Where (QuestionId = @QuestionId)
                    And ((IsCaseSensitive = 1 And AnswerText = @AnswerText collate Latin1_General_100_CS_AS) Or (IsCaseSensitive = 0 And Lower(AnswerText) = Lower(@AnswerText)))
    ),
            1,
            0
    );

    Select
        @IsCorrect IsCorrect,
        Cast(Iif(@IsCorrect = 1, @Score, 0) As Decimal(8, 2)) ScoreAwarded,
        Iif(@IsCorrect Is Null, 'PREVIEW_PENDING', 'PREVIEW_AUTO_GRADED') ReviewStatus,
        (
            Select
                Explanation
            From dbo.Questions
            Where (Id = @QuestionId)
    ) Explanation;

End
Go
Create Or Alter Procedure dbo.LMS_VideoInteraction_Create
    @VideoId Bigint,
    @QuestionId Bigint,
    @TimeSeconds Int,
    @EndTimeSeconds Int = Null,
    @InteractionType Varchar(50),
    @Required Bit,
    @PauseVideo Bit,
    @AllowSkip Bit,
    @Score Decimal(8, 2),
    @AttemptLimit Int,
    @SortOrder Int,
    @Status Varchar(30),
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Declare @Duration Int = (
        Select
            dbo.Videos.DurationSeconds
        From dbo.Videos
            Inner Join dbo.VideoAssets On dbo.VideoAssets.Id = dbo.Videos.VideoAssetId
        Where (dbo.Videos.Id = @VideoId)
            And (dbo.VideoAssets.IsDeleted = 0)
            And (@IsAdmin = 1 Or dbo.VideoAssets.CreatedBy = @ActorId)
    );

    If @Duration Is Null Throw 50003,
    N'Bạn không có quyền quản lý video này.',
    1;

    If Not Exists (
        Select
            1
        From dbo.Questions
        Where (Id = @QuestionId)
            And (IsDeleted = 0)
    )
    Or @TimeSeconds < 0
    Or @TimeSeconds > @Duration
    Or @AttemptLimit < 1
    Or @Score < 0 Throw 50001,
    N'Dữ liệu tương tác không hợp lệ.',
    1;

    Insert dbo.VideoInteractions (VideoId, QuestionId, TimeSeconds, EndTimeSeconds, InteractionType, Required, PauseVideo, AllowSkip, Score, AttemptLimit, SortOrder, Status)
    Values
        (@VideoId, @QuestionId, @TimeSeconds, @EndTimeSeconds, @InteractionType, @Required, @PauseVideo, @AllowSkip, @Score, @AttemptLimit, @SortOrder, @Status);

    Declare @Id Bigint = Scope_identity();

    Insert dbo.AuditLogs (UserId, Action, Module, EntityName, EntityId)
    Values
        (@ActorId, 'CREATE', 'VIDEO_INTERACTION', 'VideoInteraction', Convert(Nvarchar(100), @Id));

    Select
        @Id;

End
Go
Create Or Alter Procedure dbo.LMS_VideoInteraction_Update
    @Id Bigint,
    @QuestionId Bigint,
    @TimeSeconds Int,
    @EndTimeSeconds Int = Null,
    @InteractionType Varchar(50),
    @Required Bit,
    @PauseVideo Bit,
    @AllowSkip Bit,
    @Score Decimal(8, 2),
    @AttemptLimit Int,
    @SortOrder Int,
    @Status Varchar(30),
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Declare @Duration Int = (
        Select
            dbo.Videos.DurationSeconds
        From dbo.VideoInteractions
            Inner Join dbo.Videos On dbo.Videos.Id = dbo.VideoInteractions.VideoId
            Inner Join dbo.VideoAssets On dbo.VideoAssets.Id = dbo.Videos.VideoAssetId
        Where (dbo.VideoInteractions.Id = @Id)
            And (dbo.VideoInteractions.IsDeleted = 0)
            And (@IsAdmin = 1 Or dbo.VideoAssets.CreatedBy = @ActorId)
    );

    If @Duration Is Null Throw 50003,
    N'Bạn không có quyền quản lý tương tác này.',
    1;

    If Not Exists (
        Select
            1
        From dbo.Questions
        Where (Id = @QuestionId)
            And (IsDeleted = 0)
    )
    Or @TimeSeconds < 0
    Or @TimeSeconds > @Duration
    Or @AttemptLimit < 1
    Or @Score < 0 Throw 50001,
    N'Dữ liệu tương tác không hợp lệ.',
    1;

    Update dbo.VideoInteractions
    Set
        QuestionId = @QuestionId,
        TimeSeconds = @TimeSeconds,
        EndTimeSeconds = @EndTimeSeconds,
        InteractionType = @InteractionType,
        Required = @Required,
        PauseVideo = @PauseVideo,
        AllowSkip = @AllowSkip,
        Score = @Score,
        AttemptLimit = @AttemptLimit,
        SortOrder = @SortOrder,
        Status = @Status,
        UpdatedAt = Sysutcdatetime()
    Where (Id = @Id);

    Insert dbo.AuditLogs (UserId, Action, Module, EntityName, EntityId)
    Values
        (@ActorId, 'UPDATE', 'VIDEO_INTERACTION', 'VideoInteraction', Convert(Nvarchar(100), @Id));

    Select
        1;

End
Go
Create Or Alter Procedure dbo.LMS_VideoInteraction_Delete
    @Id Bigint,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Update dbo.VideoInteractions
    Set
        IsDeleted = 1,
        UpdatedAt = Sysutcdatetime()
    From dbo.VideoInteractions
        Inner Join dbo.Videos On dbo.Videos.Id = dbo.VideoInteractions.VideoId
        Inner Join dbo.VideoAssets On dbo.VideoAssets.Id = dbo.Videos.VideoAssetId
    Where (dbo.VideoInteractions.Id = @Id)
        And (dbo.VideoInteractions.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.VideoAssets.CreatedBy = @ActorId);

    Declare @Rows Int = @@Rowcount;

    If @Rows > 0
    Insert dbo.AuditLogs (UserId, Action, Module, EntityName, EntityId)
    Values
        (@ActorId, 'DELETE', 'VIDEO_INTERACTION', 'VideoInteraction', Convert(Nvarchar(100), @Id));

    Select
        @Rows;

End
Go
Create Or Alter Procedure dbo.LMS_VideoInteraction_Reorder
    @Id Bigint,
    @SortOrder Int,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Update dbo.VideoInteractions
    Set
        SortOrder = @SortOrder,
        UpdatedAt = Sysutcdatetime()
    From dbo.VideoInteractions
        Inner Join dbo.Videos On dbo.Videos.Id = dbo.VideoInteractions.VideoId
        Inner Join dbo.VideoAssets On dbo.VideoAssets.Id = dbo.Videos.VideoAssetId
    Where (dbo.VideoInteractions.Id = @Id)
        And (dbo.VideoInteractions.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.VideoAssets.CreatedBy = @ActorId);

    If @@Rowcount = 0 Throw 50003,
    N'Không thể sắp xếp tương tác này.',
    1;

End
Go
