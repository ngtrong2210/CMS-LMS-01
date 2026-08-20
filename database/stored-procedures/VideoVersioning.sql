Set Ansi_nulls On;
Set Quoted_identifier On;
Go

Create Or Alter Procedure dbo.LMS_VideoVersion_GetUsageByVideoAsset
    @Id Bigint,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    If Not Exists
        (
            Select
                1
            From dbo.SIM_VideoAssets
            Where (dbo.SIM_VideoAssets.VideoAssetID = @Id)
                And (dbo.SIM_VideoAssets.IsDeleted = 0)
                And (@IsAdmin = 1 Or dbo.SIM_VideoAssets.CreatedByUserID = @ActorId)
        )
        Throw 50003, N'Bạn không có quyền xem lịch sử sử dụng video này.', 1;

    Select
        dbo.SIM_VideoAssets.VideoAssetID,
        dbo.SIM_Videos.VideoID,
        dbo.SIM_Videos.CurrentVideoVersionID,
        dbo.SIM_VideoVersions.VersionNumber CurrentVersionNumber,
        dbo.SIM_VideoVersions.ChangeSummary,
        Count(dbo.SIM_Lessons.LessonID) UsageCount
    From dbo.SIM_VideoAssets
        Inner Join dbo.SIM_Videos On dbo.SIM_Videos.VideoAssetID = dbo.SIM_VideoAssets.VideoAssetID
        Inner Join dbo.SIM_VideoVersions On dbo.SIM_VideoVersions.VideoVersionID = dbo.SIM_Videos.CurrentVideoVersionID
        Left Join dbo.SIM_Lessons On dbo.SIM_Lessons.VideoID = dbo.SIM_Videos.VideoID
            And dbo.SIM_Lessons.IsDeleted = 0
    Where (dbo.SIM_VideoAssets.VideoAssetID = @Id)
    Group By
        dbo.SIM_VideoAssets.VideoAssetID,
        dbo.SIM_Videos.VideoID,
        dbo.SIM_Videos.CurrentVideoVersionID,
        dbo.SIM_VideoVersions.VersionNumber,
        dbo.SIM_VideoVersions.ChangeSummary;

    Select
        dbo.SIM_Lessons.LessonID,
        dbo.SIM_Lessons.Title LessonTitle,
        dbo.SIM_Courses.CourseID,
        dbo.SIM_Courses.Title CourseTitle,
        dbo.SIM_Chapters.ChapterID,
        dbo.SIM_Chapters.Title ChapterTitle,
        dbo.SIM_Lessons.VideoVersionID,
        dbo.SIM_VideoVersions.VersionNumber,
        dbo.SIM_Courses.Status CourseStatus,
        Cast(Case When dbo.SIM_Lessons.VideoVersionID = dbo.SIM_Videos.CurrentVideoVersionID Then 1 Else 0 End As Bit) IsCurrentVersion,
        Cast(Case When @IsAdmin = 1 Or dbo.SIM_Courses.TeacherUserID = @ActorId Then 1 Else 0 End As Bit) CanMove
    From dbo.SIM_Lessons
        Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.SIM_Lessons.CourseID
        Left Join dbo.SIM_Chapters On dbo.SIM_Chapters.ChapterID = dbo.SIM_Lessons.ChapterID
        Inner Join dbo.SIM_Videos On dbo.SIM_Videos.VideoID = dbo.SIM_Lessons.VideoID
        Inner Join dbo.SIM_VideoVersions On dbo.SIM_VideoVersions.VideoVersionID = dbo.SIM_Lessons.VideoVersionID
    Where (dbo.SIM_Videos.VideoAssetID = @Id)
        And (dbo.SIM_Lessons.IsDeleted = 0)
    Order By
        dbo.SIM_Courses.Title,
        dbo.SIM_Chapters.SortOrder,
        dbo.SIM_Lessons.SortOrder;
End;
Go

Create Or Alter Procedure dbo.LMS_VideoLibrary_UpdateWithLearningPolicy
    @Id Bigint,
    @Title Nvarchar(500),
    @SourceType Varchar(20) = 'LOCAL',
    @VideoUrl Nvarchar(1000),
    @PosterUrl Nvarchar(1000) = Null,
    @DurationSeconds Int,
    @OriginalFileName Nvarchar(500) = Null,
    @FileSize Bigint = Null,
    @MimeType Nvarchar(150) = Null,
    @Status Varchar(30) = 'ACTIVE',
    @LessonIdsJson Nvarchar(Max) = N'[]',
    @ChangeSummary Nvarchar(1000) = Null,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;
    Set Xact_abort On;

    If Nullif(Ltrim(Rtrim(@Title)), '') Is Null
        Or @DurationSeconds <= 0
        Or @SourceType Not In ('LOCAL', 'YOUTUBE')
        Or @Status Not In ('ACTIVE', 'INACTIVE')
        Throw 50001, N'Dữ liệu video thư viện không hợp lệ.', 1;

    If @SourceType = 'LOCAL'
        And (@VideoUrl Not Like '/Media/Video/%'
        Or @VideoUrl Like '%..%'
        Or @VideoUrl Like '%\%'
        Or @VideoUrl Like '%?%'
        Or @VideoUrl Like '%#%')
        Throw 50001, N'VideoUrl không hợp lệ.', 1;

    If @SourceType = 'YOUTUBE'
        And (@VideoUrl Not Like 'https://%youtube.com/%'
            And @VideoUrl Not Like 'https://%youtu.be/%'
            And @VideoUrl Not Like 'https://%youtube-nocookie.com/%')
        Throw 50001, N'Liên kết YouTube không hợp lệ.', 1;

    Declare @VideoID Bigint,
        @CurrentVideoVersionID Bigint;

    Select
        @VideoID = dbo.SIM_Videos.VideoID,
        @CurrentVideoVersionID = dbo.SIM_Videos.CurrentVideoVersionID
    From dbo.SIM_VideoAssets
        Inner Join dbo.SIM_Videos On dbo.SIM_Videos.VideoAssetID = dbo.SIM_VideoAssets.VideoAssetID
    Where (dbo.SIM_VideoAssets.VideoAssetID = @Id)
        And (dbo.SIM_VideoAssets.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.SIM_VideoAssets.CreatedByUserID = @ActorId);

    If @VideoID Is Null
        Throw 50003, N'Bạn không có quyền sửa video này.', 1;

    If Exists
        (
            Select
                1
            From dbo.LMS_StudentAnswers
            Where (dbo.LMS_StudentAnswers.VideoID = @VideoID)
        )
        Or Exists
        (
            Select
                1
            From dbo.LMS_StudentLessonProgress
                Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.LessonID = dbo.LMS_StudentLessonProgress.LessonID
            Where (dbo.SIM_Lessons.VideoID = @VideoID)
                And (dbo.LMS_StudentLessonProgress.Score > 0)
        )
        Throw 50005, N'Video đã có kết quả học tập nên không thể sửa. Hãy nhân bản video để tạo nội dung mới.', 1;

    Begin Transaction;

    Update dbo.SIM_VideoVersions
    Set
        Title = @Title,
        SourceType = @SourceType,
        VideoUrl = @VideoUrl,
        PosterUrl = @PosterUrl,
        DurationSeconds = @DurationSeconds,
        OriginalFileName = Case When @SourceType = 'YOUTUBE' Then Null Else Coalesce(@OriginalFileName, OriginalFileName) End,
        FileSize = Case When @SourceType = 'YOUTUBE' Then Null Else Coalesce(@FileSize, FileSize) End,
        MimeType = Case When @SourceType = 'YOUTUBE' Then Null Else Coalesce(@MimeType, MimeType) End,
        ChangeSummary = Coalesce(Nullif(Ltrim(Rtrim(@ChangeSummary)), ''), N'Cập nhật đồng bộ trước khi phát sinh kết quả học tập.')
    Where (dbo.SIM_VideoVersions.VideoVersionID = @CurrentVideoVersionID);

    Update dbo.SIM_Videos
    Set
        Title = @Title,
        SourceType = @SourceType,
        VideoUrl = @VideoUrl,
        PosterUrl = @PosterUrl,
        DurationSeconds = @DurationSeconds,
        Status = @Status,
        UpdatedAt = Sysutcdatetime()
    Where (dbo.SIM_Videos.VideoID = @VideoID);

    Update dbo.SIM_VideoAssets
    Set
        Title = @Title,
        SourceType = @SourceType,
        VideoUrl = @VideoUrl,
        PosterUrl = @PosterUrl,
        DurationSeconds = @DurationSeconds,
        OriginalFileName = Case When @SourceType = 'YOUTUBE' Then Null Else Coalesce(@OriginalFileName, OriginalFileName) End,
        FileSize = Case When @SourceType = 'YOUTUBE' Then Null Else Coalesce(@FileSize, FileSize) End,
        MimeType = Case When @SourceType = 'YOUTUBE' Then Null Else Coalesce(@MimeType, MimeType) End,
        Status = @Status,
        UpdatedAt = Sysutcdatetime()
    Where (dbo.SIM_VideoAssets.VideoAssetID = @Id);

    Update dbo.SIM_Lessons
    Set
        VideoVersionID = @CurrentVideoVersionID,
        DurationSeconds = @DurationSeconds,
        UpdatedAt = Sysutcdatetime()
    Where (dbo.SIM_Lessons.VideoID = @VideoID)
        And (dbo.SIM_Lessons.IsDeleted = 0);

    Update dbo.LMS_StudentVideoProgress
    Set
        CurrentTimeSeconds = 0,
        MaxWatchedTimeSeconds = 0,
        WatchedSeconds = 0,
        WatchPercent = 0,
        Completed = 0,
        CompletedAt = Null,
        UpdatedAt = Sysutcdatetime()
    Where (dbo.LMS_StudentVideoProgress.VideoID = @VideoID);

    Update dbo.LMS_StudentLessonProgress
    Set
        ProgressPercent = 0,
        Score = 0,
        AttemptCount = 0,
        Completed = 0,
        CompletedAt = Null,
        UpdatedAt = Sysutcdatetime()
    From dbo.LMS_StudentLessonProgress
        Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.LessonID = dbo.LMS_StudentLessonProgress.LessonID
    Where (dbo.SIM_Lessons.VideoID = @VideoID);

    Insert dbo.SYS_AuditLogs
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
        @ActorId,
        'UPDATE_SYNC',
        'VIDEO_LIBRARY',
        'Video',
        Convert(Nvarchar(100), @VideoID),
        (
            Select
                @CurrentVideoVersionID VideoVersionID,
                @DurationSeconds DurationSeconds,
                @Title Title
            For Json Path, Without_array_wrapper
        )
    );

    Commit Transaction;

    Select
        @VideoID;
End;
Go

Create Or Alter Procedure dbo.LMS_Video_UpdateWithLearningPolicy
    @Id Bigint,
    @LessonId Bigint,
    @Title Nvarchar(500),
    @SourceType Varchar(20) = 'LOCAL',
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
        Or @RequiredWatchPercent Not Between 0 And 100
        Throw 50001, N'Dữ liệu video không hợp lệ.', 1;

    Declare @VideoAssetID Bigint,
        @CurrentVideoVersionID Bigint;

    Select
        @VideoAssetID = dbo.SIM_Videos.VideoAssetID,
        @CurrentVideoVersionID = dbo.SIM_Videos.CurrentVideoVersionID
    From dbo.SIM_Videos
        Inner Join dbo.SIM_VideoAssets On dbo.SIM_VideoAssets.VideoAssetID = dbo.SIM_Videos.VideoAssetID
    Where (dbo.SIM_Videos.VideoID = @Id)
        And (dbo.SIM_VideoAssets.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.SIM_VideoAssets.CreatedByUserID = @ActorId);

    If @VideoAssetID Is Null
        Throw 50003, N'Bạn không có quyền quản lý video này.', 1;

    Declare @tblSavedVideo Table
    (
        VideoID Bigint Not Null
    );

    Insert @tblSavedVideo
    (
        VideoID
    )
    Exec dbo.LMS_VideoLibrary_UpdateWithLearningPolicy
        @Id = @VideoAssetID,
        @Title = @Title,
        @SourceType = @SourceType,
        @VideoUrl = @VideoUrl,
        @PosterUrl = @PosterUrl,
        @DurationSeconds = @DurationSeconds,
        @OriginalFileName = Null,
        @FileSize = Null,
        @MimeType = Null,
        @Status = @Status,
        @LessonIdsJson = N'[]',
        @ChangeSummary = N'Cập nhật từ màn hình biên tập video tương tác.',
        @ActorId = @ActorId,
        @IsAdmin = @IsAdmin;

    Update dbo.SIM_VideoVersions
    Set
        AllowSeek = @AllowSeek,
        AllowSpeed = @AllowSpeed,
        RequiredWatchPercent = @RequiredWatchPercent
    Where (dbo.SIM_VideoVersions.VideoVersionID = @CurrentVideoVersionID);

    Update dbo.SIM_Videos
    Set
        AllowSeek = @AllowSeek,
        AllowSpeed = @AllowSpeed,
        RequiredWatchPercent = @RequiredWatchPercent,
        UpdatedAt = Sysutcdatetime()
    Where (dbo.SIM_Videos.VideoID = @Id);

    Select
        @Id;
End;
Go

Create Or Alter Procedure dbo.LMS_VideoLibrary_Duplicate
    @Id Bigint,
    @Title Nvarchar(500) = Null,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;
    Set Xact_abort On;

    Declare @SourceVideoID Bigint,
        @SourceVideoVersionID Bigint,
        @DuplicateTitle Nvarchar(500);

    Select
        @SourceVideoID = dbo.SIM_Videos.VideoID,
        @SourceVideoVersionID = dbo.SIM_Videos.CurrentVideoVersionID,
        @DuplicateTitle = Coalesce(Nullif(Ltrim(Rtrim(@Title)), ''), Concat(dbo.SIM_VideoVersions.Title, N' - Bản sao'))
    From dbo.SIM_VideoAssets
        Inner Join dbo.SIM_Videos On dbo.SIM_Videos.VideoAssetID = dbo.SIM_VideoAssets.VideoAssetID
        Inner Join dbo.SIM_VideoVersions On dbo.SIM_VideoVersions.VideoVersionID = dbo.SIM_Videos.CurrentVideoVersionID
    Where (dbo.SIM_VideoAssets.VideoAssetID = @Id)
        And (dbo.SIM_VideoAssets.IsDeleted = 0)
        And
        (
            @IsAdmin = 1
            Or dbo.SIM_VideoAssets.CreatedByUserID = @ActorId
            Or dbo.SIM_VideoAssets.ShareScope = 'SCHOOL'
            Or Exists
                (
                    Select
                        1
                    From dbo.SIM_VideoAssetShares
                    Where (dbo.SIM_VideoAssetShares.VideoAssetID = @Id)
                        And (dbo.SIM_VideoAssetShares.TeacherUserID = @ActorId)
                )
        );

    If @SourceVideoID Is Null
        Throw 50003, N'Bạn không có quyền nhân bản video này.', 1;

    Begin Transaction;

    Insert dbo.SIM_VideoAssets
    (
        Title,
        SourceType,
        VideoUrl,
        PosterUrl,
        DurationSeconds,
        OriginalFileName,
        FileSize,
        MimeType,
        CreatedByUserID,
        ShareScope,
        Status
    )
    Select
        @DuplicateTitle,
        dbo.SIM_VideoVersions.SourceType,
        dbo.SIM_VideoVersions.VideoUrl,
        dbo.SIM_VideoVersions.PosterUrl,
        dbo.SIM_VideoVersions.DurationSeconds,
        dbo.SIM_VideoVersions.OriginalFileName,
        dbo.SIM_VideoVersions.FileSize,
        dbo.SIM_VideoVersions.MimeType,
        @ActorId,
        'PRIVATE',
        'ACTIVE'
    From dbo.SIM_VideoVersions
    Where (dbo.SIM_VideoVersions.VideoVersionID = @SourceVideoVersionID);

    Declare @NewVideoAssetID Bigint = Scope_identity();

    Insert dbo.SIM_Videos
    (
        VideoAssetID,
        Title,
        SourceType,
        VideoUrl,
        PosterUrl,
        DurationSeconds,
        AllowSeek,
        AllowSpeed,
        RequiredWatchPercent,
        Status
    )
    Select
        @NewVideoAssetID,
        @DuplicateTitle,
        dbo.SIM_VideoVersions.SourceType,
        dbo.SIM_VideoVersions.VideoUrl,
        dbo.SIM_VideoVersions.PosterUrl,
        dbo.SIM_VideoVersions.DurationSeconds,
        dbo.SIM_VideoVersions.AllowSeek,
        dbo.SIM_VideoVersions.AllowSpeed,
        dbo.SIM_VideoVersions.RequiredWatchPercent,
        'ACTIVE'
    From dbo.SIM_VideoVersions
    Where (dbo.SIM_VideoVersions.VideoVersionID = @SourceVideoVersionID);

    Declare @NewVideoID Bigint = Scope_identity();

    Insert dbo.SIM_VideoVersions
    (
        VideoID,
        VersionNumber,
        Title,
        SourceType,
        VideoUrl,
        PosterUrl,
        DurationSeconds,
        AllowSeek,
        AllowSpeed,
        RequiredWatchPercent,
        OriginalFileName,
        FileSize,
        MimeType,
        ChangeSummary,
        VersionStatus,
        CreatedByUserID,
        PublishedByUserID,
        PublishedAt
    )
    Select
        @NewVideoID,
        1,
        @DuplicateTitle,
        dbo.SIM_VideoVersions.SourceType,
        dbo.SIM_VideoVersions.VideoUrl,
        dbo.SIM_VideoVersions.PosterUrl,
        dbo.SIM_VideoVersions.DurationSeconds,
        dbo.SIM_VideoVersions.AllowSeek,
        dbo.SIM_VideoVersions.AllowSpeed,
        dbo.SIM_VideoVersions.RequiredWatchPercent,
        dbo.SIM_VideoVersions.OriginalFileName,
        dbo.SIM_VideoVersions.FileSize,
        dbo.SIM_VideoVersions.MimeType,
        Concat(N'Nhân bản từ video ', @SourceVideoID, N'.'),
        'PUBLISHED',
        @ActorId,
        @ActorId,
        Sysutcdatetime()
    From dbo.SIM_VideoVersions
    Where (dbo.SIM_VideoVersions.VideoVersionID = @SourceVideoVersionID);

    Declare @NewVideoVersionID Bigint = Scope_identity();

    Update dbo.SIM_Videos
    Set
        CurrentVideoVersionID = @NewVideoVersionID
    Where (dbo.SIM_Videos.VideoID = @NewVideoID);

    Insert dbo.LMS_VideoInteractions
    (
        VideoID,
        VideoVersionID,
        QuestionID,
        TimeSeconds,
        EndTimeSeconds,
        InteractionType,
        Required,
        PauseVideo,
        AllowSkip,
        Score,
        AttemptLimit,
        SortOrder,
        Status
    )
    Select
        @NewVideoID,
        @NewVideoVersionID,
        dbo.LMS_VideoInteractions.QuestionID,
        dbo.LMS_VideoInteractions.TimeSeconds,
        dbo.LMS_VideoInteractions.EndTimeSeconds,
        dbo.LMS_VideoInteractions.InteractionType,
        dbo.LMS_VideoInteractions.Required,
        dbo.LMS_VideoInteractions.PauseVideo,
        dbo.LMS_VideoInteractions.AllowSkip,
        dbo.LMS_VideoInteractions.Score,
        dbo.LMS_VideoInteractions.AttemptLimit,
        dbo.LMS_VideoInteractions.SortOrder,
        dbo.LMS_VideoInteractions.Status
    From dbo.LMS_VideoInteractions
    Where (dbo.LMS_VideoInteractions.VideoID = @SourceVideoID)
        And (dbo.LMS_VideoInteractions.VideoVersionID = @SourceVideoVersionID)
        And (dbo.LMS_VideoInteractions.IsDeleted = 0);

    Insert dbo.SYS_AuditLogs
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
        @ActorId,
        'DUPLICATE',
        'VIDEO_LIBRARY',
        'Video',
        Convert(Nvarchar(100), @NewVideoID),
        (
            Select
                @SourceVideoID SourceVideoID,
                @NewVideoAssetID NewVideoAssetID,
                @NewVideoVersionID NewVideoVersionID
            For Json Path, Without_array_wrapper
        )
    );

    Commit Transaction;

    Select
        @NewVideoID;
End;
Go

Declare @tblProcedureDescriptions Table
(
    ProcedureName Sysname Not Null,
    ProcedureDescription Nvarchar(1000) Not Null
);

Insert @tblProcedureDescriptions
(
    ProcedureName,
    ProcedureDescription
)
Values
    (N'LMS_VideoVersion_GetUsageByVideoAsset', N'Trả thông tin phiên bản hiện tại và danh sách bài học đang ghim từng phiên bản của một tài nguyên video.'),
    (N'LMS_VideoLibrary_Create', N'Tạo tài nguyên video, video logic và phiên bản đầu tiên trong cùng transaction.'),
    (N'LMS_VideoLibrary_Update', N'Tạo phiên bản video mới, nhân bộ tương tác và chỉ chuyển các bài học được giáo viên chọn.'),
    (N'LMS_Video_Create', N'Tạo video cùng phiên bản đầu tiên và ghim phiên bản vào bài học được chọn.'),
    (N'LMS_Video_Update', N'Tạo phiên bản mới từ màn hình biên tập khi phạm vi sử dụng cho phép.'),
    (N'LMS_VideoInteraction_Create', N'Tạo mốc tương tác thuộc phiên bản mới nhất của video.');

Declare @ProcedureName Sysname,
    @ProcedureDescription Nvarchar(1000);

Declare procedure_description_cursor Cursor Local Fast_forward For
    Select
        ProcedureName,
        ProcedureDescription
    From @tblProcedureDescriptions;

Open procedure_description_cursor;
Fetch Next From procedure_description_cursor Into @ProcedureName, @ProcedureDescription;

While @@Fetch_status = 0
Begin
    If Exists
        (
            Select
                1
            From sys.extended_properties
            Where (class = 1)
                And (major_id = Object_id(N'dbo.' + @ProcedureName))
                And (minor_id = 0)
                And (name = N'MS_Description')
        )
        Exec sys.sp_updateextendedproperty @name = N'MS_Description', @value = @ProcedureDescription, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'PROCEDURE', @level1name = @ProcedureName;
    Else
        Exec sys.sp_addextendedproperty @name = N'MS_Description', @value = @ProcedureDescription, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'PROCEDURE', @level1name = @ProcedureName;

    Fetch Next From procedure_description_cursor Into @ProcedureName, @ProcedureDescription;
End;

Close procedure_description_cursor;
Deallocate procedure_description_cursor;
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

    If @RequiredWatchPercent Not Between 0 And 100
        Throw 50001, N'Tỷ lệ xem bắt buộc không hợp lệ.', 1;

    If Not Exists
        (
            Select
                1
            From dbo.SIM_Lessons
                Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.SIM_Lessons.CourseID
            Where (dbo.SIM_Lessons.LessonID = @LessonId)
                And (dbo.SIM_Lessons.IsDeleted = 0)
                And (dbo.SIM_Lessons.LessonType In ('VIDEO', 'INTERACTIVE_VIDEO'))
                And (@IsAdmin = 1 Or dbo.SIM_Courses.TeacherUserID = @ActorId)
        )
        Throw 50003, N'Bạn không có quyền quản lý bài học này.', 1;

    Declare @VideoID Bigint,
        @VideoVersionID Bigint,
        @DurationSeconds Int;

    Select
        @VideoID = dbo.SIM_Videos.VideoID,
        @VideoVersionID = dbo.SIM_Videos.CurrentVideoVersionID,
        @DurationSeconds = dbo.SIM_VideoVersions.DurationSeconds
    From dbo.SIM_VideoAssets
        Inner Join dbo.SIM_Videos On dbo.SIM_Videos.VideoAssetID = dbo.SIM_VideoAssets.VideoAssetID
        Inner Join dbo.SIM_VideoVersions On dbo.SIM_VideoVersions.VideoVersionID = dbo.SIM_Videos.CurrentVideoVersionID
    Where (dbo.SIM_VideoAssets.VideoAssetID = @VideoAssetId)
        And (dbo.SIM_VideoAssets.IsDeleted = 0)
        And (dbo.SIM_VideoAssets.Status = 'ACTIVE')
        And (dbo.SIM_Videos.Status = 'ACTIVE')
        And (dbo.SIM_VideoVersions.VersionStatus = 'PUBLISHED')
        And
        (
            @IsAdmin = 1
            Or dbo.SIM_VideoAssets.CreatedByUserID = @ActorId
            Or dbo.SIM_VideoAssets.ShareScope = 'SCHOOL'
            Or Exists
                (
                    Select
                        1
                    From dbo.SIM_VideoAssetShares
                    Where (dbo.SIM_VideoAssetShares.VideoAssetID = dbo.SIM_VideoAssets.VideoAssetID)
                        And (dbo.SIM_VideoAssetShares.TeacherUserID = @ActorId)
                )
        );

    If @VideoID Is Null
        Throw 50003, N'Video không tồn tại hoặc chưa được tác giả chia sẻ cho bạn.', 1;

    Update dbo.SIM_Lessons
    Set
        VideoID = @VideoID,
        VideoVersionID = @VideoVersionID,
        DurationSeconds = @DurationSeconds,
        UpdatedAt = Sysutcdatetime()
    Where (dbo.SIM_Lessons.LessonID = @LessonId);

    Insert dbo.SYS_AuditLogs
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
        @ActorId,
        'ATTACH',
        'VIDEO_LIBRARY',
        'Lesson',
        Convert(Nvarchar(100), @LessonId),
        (
            Select
                @VideoID VideoID,
                @VideoVersionID VideoVersionID
            For Json Path, Without_array_wrapper
        )
    );

    Select
        @VideoID;
End;
Go

Create Or Alter Procedure dbo.LMS_Video_AttachToLesson
    @LessonId Bigint,
    @VideoId Bigint,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    If Not Exists
        (
            Select
                1
            From dbo.SIM_Lessons
                Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.SIM_Lessons.CourseID
            Where (dbo.SIM_Lessons.LessonID = @LessonId)
                And (dbo.SIM_Lessons.IsDeleted = 0)
                And (dbo.SIM_Lessons.LessonType In ('VIDEO', 'INTERACTIVE_VIDEO'))
                And (@IsAdmin = 1 Or dbo.SIM_Courses.TeacherUserID = @ActorId)
        )
        Throw 50003, N'Bạn không có quyền quản lý bài học này.', 1;

    Declare @VideoVersionID Bigint,
        @DurationSeconds Int;

    Select
        @VideoVersionID = dbo.SIM_Videos.CurrentVideoVersionID,
        @DurationSeconds = dbo.SIM_VideoVersions.DurationSeconds
    From dbo.SIM_Videos
        Inner Join dbo.SIM_VideoAssets On dbo.SIM_VideoAssets.VideoAssetID = dbo.SIM_Videos.VideoAssetID
        Inner Join dbo.SIM_VideoVersions On dbo.SIM_VideoVersions.VideoVersionID = dbo.SIM_Videos.CurrentVideoVersionID
    Where (dbo.SIM_Videos.VideoID = @VideoId)
        And (dbo.SIM_Videos.Status = 'ACTIVE')
        And (dbo.SIM_VideoAssets.IsDeleted = 0)
        And (dbo.SIM_VideoAssets.Status = 'ACTIVE')
        And (dbo.SIM_VideoVersions.VersionStatus = 'PUBLISHED')
        And
        (
            @IsAdmin = 1
            Or dbo.SIM_VideoAssets.CreatedByUserID = @ActorId
            Or dbo.SIM_VideoAssets.ShareScope = 'SCHOOL'
            Or Exists
                (
                    Select
                        1
                    From dbo.SIM_VideoAssetShares
                    Where (dbo.SIM_VideoAssetShares.VideoAssetID = dbo.SIM_VideoAssets.VideoAssetID)
                        And (dbo.SIM_VideoAssetShares.TeacherUserID = @ActorId)
                )
        );

    If @VideoVersionID Is Null
        Throw 50003, N'Video không tồn tại hoặc chưa được tác giả chia sẻ cho bạn.', 1;

    Update dbo.SIM_Lessons
    Set
        VideoID = @VideoId,
        VideoVersionID = @VideoVersionID,
        DurationSeconds = @DurationSeconds,
        UpdatedAt = Sysutcdatetime()
    Where (dbo.SIM_Lessons.LessonID = @LessonId);

    Insert dbo.SYS_AuditLogs
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
        @ActorId,
        'ATTACH',
        'VIDEO_LIBRARY',
        'Lesson',
        Convert(Nvarchar(100), @LessonId),
        (
            Select
                @VideoId VideoID,
                @VideoVersionID VideoVersionID
            For Json Path, Without_array_wrapper
        )
    );

    Select
        @VideoId;
End;
Go

Create Or Alter Procedure dbo.LMS_Video_GetById
    @Id Bigint,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    If Exists
        (
            Select
                1
            From dbo.SIM_Videos
            Where (dbo.SIM_Videos.VideoID = @Id)
        )
        And Not Exists
        (
            Select
                1
            From dbo.SIM_Videos
                Inner Join dbo.SIM_VideoAssets On dbo.SIM_VideoAssets.VideoAssetID = dbo.SIM_Videos.VideoAssetID
            Where (dbo.SIM_Videos.VideoID = @Id)
                And (dbo.SIM_VideoAssets.IsDeleted = 0)
                And (@IsAdmin = 1 Or dbo.SIM_VideoAssets.CreatedByUserID = @ActorId)
        )
        Throw 50003, N'Bạn không có quyền quản lý video này.', 1;

    Select
        dbo.SIM_Videos.VideoID Id,
        dbo.SIM_Videos.VideoAssetID VideoAssetId,
        dbo.SIM_Videos.CurrentVideoVersionID CurrentVideoVersionId,
        dbo.SIM_VideoVersions.VersionNumber,
        dbo.SIM_VideoVersions.Title,
        dbo.SIM_VideoVersions.SourceType,
        dbo.SIM_VideoVersions.VideoUrl,
        dbo.SIM_VideoVersions.PosterUrl,
        dbo.SIM_VideoVersions.DurationSeconds,
        dbo.SIM_VideoVersions.AllowSeek,
        dbo.SIM_VideoVersions.AllowSpeed,
        dbo.SIM_VideoVersions.RequiredWatchPercent,
        dbo.SIM_Videos.Status,
        dbo.SIM_VideoAssets.CreatedByUserID CreatedBy,
        dbo.SIM_VideoAssets.ShareScope,
        currentVersionUsage.LessonID LessonId,
        assetUsage.AssetUsageCount,
        currentVersionUsage.CurrentVersionUsageCount,
        learningResultInfo.HasLearningResults,
        learningResultInfo.AnswerCount,
        Cast(Case When (@IsAdmin = 1 Or dbo.SIM_VideoAssets.CreatedByUserID = @ActorId) And learningResultInfo.HasLearningResults = 0 Then 1 Else 0 End As Bit) CanEdit,
        Cast(1 As Bit) CanDuplicate
    From dbo.SIM_Videos
        Inner Join dbo.SIM_VideoAssets On dbo.SIM_VideoAssets.VideoAssetID = dbo.SIM_Videos.VideoAssetID
        Inner Join dbo.SIM_VideoVersions On dbo.SIM_VideoVersions.VideoVersionID = dbo.SIM_Videos.CurrentVideoVersionID
        Outer Apply
        (
            Select
                Count(*) AssetUsageCount
            From dbo.SIM_Lessons
            Where (dbo.SIM_Lessons.VideoID = dbo.SIM_Videos.VideoID)
                And (dbo.SIM_Lessons.IsDeleted = 0)
        ) assetUsage
        Outer Apply
        (
            Select
                Min(dbo.SIM_Lessons.LessonID) LessonID,
                Count(*) CurrentVersionUsageCount
            From dbo.SIM_Lessons
            Where (dbo.SIM_Lessons.VideoID = dbo.SIM_Videos.VideoID)
                And (dbo.SIM_Lessons.VideoVersionID = dbo.SIM_Videos.CurrentVideoVersionID)
                And (dbo.SIM_Lessons.IsDeleted = 0)
        ) currentVersionUsage
        Outer Apply
        (
            Select
                Cast(Case When Exists
                    (
                        Select
                            1
                        From dbo.LMS_StudentAnswers
                        Where (dbo.LMS_StudentAnswers.VideoID = dbo.SIM_Videos.VideoID)
                    )
                    Or Exists
                    (
                        Select
                            1
                        From dbo.LMS_StudentLessonProgress
                            Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.LessonID = dbo.LMS_StudentLessonProgress.LessonID
                        Where (dbo.SIM_Lessons.VideoID = dbo.SIM_Videos.VideoID)
                            And (dbo.LMS_StudentLessonProgress.Score > 0)
                    ) Then 1 Else 0 End As Bit) HasLearningResults,
                (
                    Select
                        Count(*)
                    From dbo.LMS_StudentAnswers
                    Where (dbo.LMS_StudentAnswers.VideoID = dbo.SIM_Videos.VideoID)
                ) AnswerCount
        ) learningResultInfo
    Where (dbo.SIM_Videos.VideoID = @Id)
        And (dbo.SIM_VideoAssets.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.SIM_VideoAssets.CreatedByUserID = @ActorId);
End;
Go

Create Or Alter Procedure dbo.LMS_VideoInteraction_GetByVideo
    @VideoId Bigint,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    If Not Exists
        (
            Select
                1
            From dbo.SIM_Videos
                Inner Join dbo.SIM_VideoAssets On dbo.SIM_VideoAssets.VideoAssetID = dbo.SIM_Videos.VideoAssetID
            Where (dbo.SIM_Videos.VideoID = @VideoId)
                And (dbo.SIM_VideoAssets.IsDeleted = 0)
                And (@IsAdmin = 1 Or dbo.SIM_VideoAssets.CreatedByUserID = @ActorId)
        )
        Throw 50003, N'Bạn không có quyền quản lý tương tác này.', 1;

    Select
        dbo.LMS_VideoInteractions.VideoInteractionID Id,
        dbo.LMS_VideoInteractions.VideoID VideoId,
        dbo.LMS_VideoInteractions.VideoVersionID VideoVersionId,
        dbo.LMS_VideoInteractions.QuestionID QuestionId,
        dbo.LMS_VideoInteractions.TimeSeconds,
        dbo.LMS_VideoInteractions.EndTimeSeconds,
        dbo.LMS_VideoInteractions.InteractionType,
        dbo.LMS_VideoInteractions.Required,
        dbo.LMS_VideoInteractions.PauseVideo,
        dbo.LMS_VideoInteractions.AllowSkip,
        dbo.LMS_VideoInteractions.Score,
        dbo.LMS_VideoInteractions.AttemptLimit,
        dbo.LMS_VideoInteractions.SortOrder,
        dbo.LMS_VideoInteractions.Status,
        dbo.LMS_Questions.QuestionType,
        dbo.LMS_Questions.QuestionText,
        dbo.LMS_Questions.Description,
        dbo.LMS_Questions.Difficulty,
        (
            Select
                dbo.LMS_QuestionOptions.QuestionOptionID Id,
                dbo.LMS_QuestionOptions.OptionCode,
                dbo.LMS_QuestionOptions.OptionText,
                dbo.LMS_QuestionOptions.SortOrder
            From dbo.LMS_QuestionOptions
            Where (dbo.LMS_QuestionOptions.QuestionID = dbo.LMS_Questions.QuestionID)
                And (dbo.LMS_QuestionOptions.IsDeleted = 0)
            Order By
                dbo.LMS_QuestionOptions.SortOrder
            For Json
                Path
        ) Options
    From dbo.LMS_VideoInteractions
        Inner Join dbo.SIM_Videos On dbo.SIM_Videos.VideoID = dbo.LMS_VideoInteractions.VideoID
        Inner Join dbo.LMS_Questions On dbo.LMS_Questions.QuestionID = dbo.LMS_VideoInteractions.QuestionID
    Where (dbo.LMS_VideoInteractions.VideoID = @VideoId)
        And (dbo.LMS_VideoInteractions.VideoVersionID = dbo.SIM_Videos.CurrentVideoVersionID)
        And (dbo.LMS_VideoInteractions.IsDeleted = 0)
    Order By
        dbo.LMS_VideoInteractions.TimeSeconds,
        dbo.LMS_VideoInteractions.SortOrder;
End;
Go

Create Or Alter Procedure dbo.LMS_VideoLibrary_Create
    @Title Nvarchar(500),
    @SourceType Varchar(20) = 'LOCAL',
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
        Or @DurationSeconds <= 0
        Or @SourceType Not In ('LOCAL', 'YOUTUBE')
        Throw 50001, N'Dữ liệu video thư viện không hợp lệ.', 1;

    If @SourceType = 'LOCAL'
        And @VideoUrl Is Not Null
        And (@VideoUrl Not Like '/Media/Video/%' Or @VideoUrl Like '%..%' Or @VideoUrl Like '%\%' Or @VideoUrl Like '%?%' Or @VideoUrl Like '%#%')
        Throw 50001, N'VideoUrl không hợp lệ.', 1;

    If @SourceType = 'YOUTUBE'
        And (@VideoUrl Not Like 'https://%youtube.com/%'
            And @VideoUrl Not Like 'https://%youtu.be/%'
            And @VideoUrl Not Like 'https://%youtube-nocookie.com/%')
        Throw 50001, N'Liên kết YouTube không hợp lệ.', 1;

    Begin Transaction;

    Insert dbo.SIM_VideoAssets
    (
        Title,
        SourceType,
        VideoUrl,
        PosterUrl,
        DurationSeconds,
        OriginalFileName,
        FileSize,
        MimeType,
        CreatedByUserID
    )
    Values
    (
        @Title,
        @SourceType,
        @VideoUrl,
        @PosterUrl,
        @DurationSeconds,
        @OriginalFileName,
        @FileSize,
        @MimeType,
        @ActorId
    );

    Declare @VideoAssetID Bigint = Scope_identity();

    Insert dbo.SIM_Videos
    (
        VideoAssetID,
        Title,
        SourceType,
        VideoUrl,
        PosterUrl,
        DurationSeconds,
        AllowSeek,
        AllowSpeed,
        RequiredWatchPercent,
        Status
    )
    Values
    (
        @VideoAssetID,
        @Title,
        @SourceType,
        @VideoUrl,
        @PosterUrl,
        @DurationSeconds,
        0,
        1,
        80,
        'ACTIVE'
    );

    Declare @VideoID Bigint = Scope_identity();

    Insert dbo.SIM_VideoVersions
    (
        VideoID,
        VersionNumber,
        Title,
        SourceType,
        VideoUrl,
        PosterUrl,
        DurationSeconds,
        AllowSeek,
        AllowSpeed,
        RequiredWatchPercent,
        OriginalFileName,
        FileSize,
        MimeType,
        ChangeSummary,
        VersionStatus,
        CreatedByUserID,
        PublishedByUserID,
        PublishedAt
    )
    Values
    (
        @VideoID,
        1,
        @Title,
        @SourceType,
        @VideoUrl,
        @PosterUrl,
        @DurationSeconds,
        0,
        1,
        80,
        @OriginalFileName,
        @FileSize,
        @MimeType,
        N'Phiên bản đầu tiên.',
        'PUBLISHED',
        @ActorId,
        @ActorId,
        Sysutcdatetime()
    );

    Declare @VideoVersionID Bigint = Scope_identity();

    Update dbo.SIM_Videos
    Set
        CurrentVideoVersionID = @VideoVersionID
    Where (dbo.SIM_Videos.VideoID = @VideoID);

    Insert dbo.SYS_AuditLogs
    (
        UserID,
        Action,
        Module,
        EntityName,
        EntityID
    )
    Values
    (
        @ActorId,
        'CREATE',
        'VIDEO_LIBRARY',
        'VideoAsset',
        Convert(Nvarchar(100), @VideoAssetID)
    );

    Commit Transaction;

    Select
        @VideoAssetID;
End;
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
    @LessonIdsJson Nvarchar(Max) = N'[]',
    @ChangeSummary Nvarchar(1000) = Null,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;
    Set Xact_abort On;

    If Nullif(Ltrim(Rtrim(@Title)), '') Is Null
        Or @DurationSeconds <= 0
        Or @Status Not In ('ACTIVE', 'INACTIVE')
        Throw 50001, N'Dữ liệu video thư viện không hợp lệ.', 1;

    If @VideoUrl Not Like '/Media/Video/%'
        Or @VideoUrl Like '%..%'
        Or @VideoUrl Like '%\%'
        Or @VideoUrl Like '%?%'
        Or @VideoUrl Like '%#%'
        Throw 50001, N'VideoUrl không hợp lệ.', 1;

    If Isjson(@LessonIdsJson) <> 1
        Throw 50001, N'Danh sách bài học được chọn không hợp lệ.', 1;

    Declare @VideoID Bigint,
        @CurrentVideoVersionID Bigint,
        @CurrentVersionNumber Int;

    Select
        @VideoID = dbo.SIM_Videos.VideoID,
        @CurrentVideoVersionID = dbo.SIM_Videos.CurrentVideoVersionID,
        @CurrentVersionNumber = dbo.SIM_VideoVersions.VersionNumber
    From dbo.SIM_VideoAssets
        Inner Join dbo.SIM_Videos On dbo.SIM_Videos.VideoAssetID = dbo.SIM_VideoAssets.VideoAssetID
        Inner Join dbo.SIM_VideoVersions On dbo.SIM_VideoVersions.VideoVersionID = dbo.SIM_Videos.CurrentVideoVersionID
    Where (dbo.SIM_VideoAssets.VideoAssetID = @Id)
        And (dbo.SIM_VideoAssets.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.SIM_VideoAssets.CreatedByUserID = @ActorId);

    If @VideoID Is Null
        Throw 50003, N'Bạn không có quyền sửa video này.', 1;

    Declare @tblSelectedLessons Table
    (
        LessonID Bigint Not Null Primary Key
    );

    Insert @tblSelectedLessons
    (
        LessonID
    )
    Select Distinct
        Convert(Bigint, videoLesson.value)
    From Openjson(@LessonIdsJson) videoLesson
    Where (Try_convert(Bigint, videoLesson.value) Is Not Null);

    If Exists
        (
            Select
                1
            From @tblSelectedLessons SelectedLessons
                Left Join dbo.SIM_Lessons On dbo.SIM_Lessons.LessonID = SelectedLessons.LessonID
                    And dbo.SIM_Lessons.VideoID = @VideoID
                    And dbo.SIM_Lessons.IsDeleted = 0
                Left Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.SIM_Lessons.CourseID
            Where (dbo.SIM_Lessons.LessonID Is Null)
                Or (@IsAdmin = 0 And dbo.SIM_Courses.TeacherUserID <> @ActorId)
        )
        Throw 50003, N'Có bài học không sử dụng video này hoặc bạn không có quyền chuyển phiên bản cho bài học đó.', 1;

    Begin Transaction;

    Insert dbo.SIM_VideoVersions
    (
        VideoID,
        VersionNumber,
        Title,
        VideoUrl,
        PosterUrl,
        DurationSeconds,
        AllowSeek,
        AllowSpeed,
        RequiredWatchPercent,
        OriginalFileName,
        FileSize,
        MimeType,
        ChangeSummary,
        VersionStatus,
        CreatedByUserID,
        PublishedByUserID,
        PublishedAt
    )
    Select
        dbo.SIM_Videos.VideoID,
        @CurrentVersionNumber + 1,
        @Title,
        @VideoUrl,
        @PosterUrl,
        @DurationSeconds,
        dbo.SIM_VideoVersions.AllowSeek,
        dbo.SIM_VideoVersions.AllowSpeed,
        dbo.SIM_VideoVersions.RequiredWatchPercent,
        Coalesce(@OriginalFileName, dbo.SIM_VideoVersions.OriginalFileName),
        Coalesce(@FileSize, dbo.SIM_VideoVersions.FileSize),
        Coalesce(@MimeType, dbo.SIM_VideoVersions.MimeType),
        Coalesce(Nullif(Ltrim(Rtrim(@ChangeSummary)), ''), N'Tạo phiên bản mới từ thư viện video.'),
        'PUBLISHED',
        @ActorId,
        @ActorId,
        Sysutcdatetime()
    From dbo.SIM_Videos
        Inner Join dbo.SIM_VideoVersions On dbo.SIM_VideoVersions.VideoVersionID = @CurrentVideoVersionID
    Where (dbo.SIM_Videos.VideoID = @VideoID);

    Declare @NewVideoVersionID Bigint = Scope_identity();

    Insert dbo.LMS_VideoInteractions
    (
        VideoID,
        VideoVersionID,
        QuestionID,
        TimeSeconds,
        EndTimeSeconds,
        InteractionType,
        Required,
        PauseVideo,
        AllowSkip,
        Score,
        AttemptLimit,
        SortOrder,
        Status,
        CreatedAt,
        UpdatedAt,
        IsDeleted
    )
    Select
        dbo.LMS_VideoInteractions.VideoID,
        @NewVideoVersionID,
        dbo.LMS_VideoInteractions.QuestionID,
        dbo.LMS_VideoInteractions.TimeSeconds,
        dbo.LMS_VideoInteractions.EndTimeSeconds,
        dbo.LMS_VideoInteractions.InteractionType,
        dbo.LMS_VideoInteractions.Required,
        dbo.LMS_VideoInteractions.PauseVideo,
        dbo.LMS_VideoInteractions.AllowSkip,
        dbo.LMS_VideoInteractions.Score,
        dbo.LMS_VideoInteractions.AttemptLimit,
        dbo.LMS_VideoInteractions.SortOrder,
        dbo.LMS_VideoInteractions.Status,
        Sysutcdatetime(),
        Null,
        dbo.LMS_VideoInteractions.IsDeleted
    From dbo.LMS_VideoInteractions
    Where (dbo.LMS_VideoInteractions.VideoID = @VideoID)
        And (dbo.LMS_VideoInteractions.VideoVersionID = @CurrentVideoVersionID);

    Update dbo.SIM_Videos
    Set
        CurrentVideoVersionID = @NewVideoVersionID,
        Title = @Title,
        VideoUrl = @VideoUrl,
        PosterUrl = @PosterUrl,
        DurationSeconds = @DurationSeconds,
        Status = @Status,
        UpdatedAt = Sysutcdatetime()
    Where (dbo.SIM_Videos.VideoID = @VideoID);

    Update dbo.SIM_VideoAssets
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
    Where (dbo.SIM_VideoAssets.VideoAssetID = @Id);

    Update dbo.SIM_Lessons
    Set
        VideoVersionID = @NewVideoVersionID,
        DurationSeconds = @DurationSeconds,
        UpdatedAt = Sysutcdatetime()
    From dbo.SIM_Lessons
        Inner Join @tblSelectedLessons SelectedLessons On SelectedLessons.LessonID = dbo.SIM_Lessons.LessonID;

    Update dbo.LMS_StudentLessonProgress
    Set
        ProgressPercent = 0,
        Score = 0,
        AttemptCount = 0,
        Completed = 0,
        CompletedAt = Null,
        UpdatedAt = Sysutcdatetime()
    From dbo.LMS_StudentLessonProgress
        Inner Join @tblSelectedLessons SelectedLessons On SelectedLessons.LessonID = dbo.LMS_StudentLessonProgress.LessonID;

    Insert dbo.SYS_AuditLogs
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
        @ActorId,
        'CREATE_VERSION',
        'VIDEO_LIBRARY',
        'VideoVersion',
        Convert(Nvarchar(100), @NewVideoVersionID),
        (
            Select
                @VideoID VideoID,
                @CurrentVideoVersionID PreviousVideoVersionID,
                @NewVideoVersionID NewVideoVersionID,
                @CurrentVersionNumber + 1 VersionNumber,
                @LessonIdsJson SelectedLessonIDs
            For Json Path, Without_array_wrapper
        )
    );

    Commit Transaction;

    Select
        @VideoID;
End;
Go

Create Or Alter Procedure dbo.LMS_Video_Create
    @Id Bigint = Null,
    @LessonId Bigint,
    @Title Nvarchar(500),
    @SourceType Varchar(20) = 'LOCAL',
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

    If Nullif(Ltrim(Rtrim(@Title)), '') Is Null
        Or @DurationSeconds <= 0
        Or @SourceType Not In ('LOCAL', 'YOUTUBE')
        Or @RequiredWatchPercent Not Between 0 And 100
        Throw 50001, N'Dữ liệu video không hợp lệ.', 1;

    If @SourceType = 'LOCAL'
        And @VideoUrl Is Not Null
        And (@VideoUrl Not Like '/Media/Video/%' Or @VideoUrl Like '%..%' Or @VideoUrl Like '%\%' Or @VideoUrl Like '%?%' Or @VideoUrl Like '%#%')
        Throw 50001, N'VideoUrl phải là URL tương đối an toàn trong /Media/Video/.', 1;

    If @SourceType = 'YOUTUBE'
        And (@VideoUrl Not Like 'https://%youtube.com/%'
            And @VideoUrl Not Like 'https://%youtu.be/%'
            And @VideoUrl Not Like 'https://%youtube-nocookie.com/%')
        Throw 50001, N'Liên kết YouTube không hợp lệ.', 1;

    If Not Exists
        (
            Select
                1
            From dbo.SIM_Lessons
                Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.SIM_Lessons.CourseID
            Where (dbo.SIM_Lessons.LessonID = @LessonId)
                And (dbo.SIM_Lessons.IsDeleted = 0)
                And (@IsAdmin = 1 Or dbo.SIM_Courses.TeacherUserID = @ActorId)
        )
        Throw 50003, N'Bạn không có quyền quản lý bài học này.', 1;

    Begin Transaction;

    Insert dbo.SIM_VideoAssets
    (
        Title,
        SourceType,
        VideoUrl,
        PosterUrl,
        DurationSeconds,
        CreatedByUserID,
        Status
    )
    Values
    (
        @Title,
        @SourceType,
        @VideoUrl,
        @PosterUrl,
        @DurationSeconds,
        @ActorId,
        @Status
    );

    Declare @VideoAssetID Bigint = Scope_identity();

    Insert dbo.SIM_Videos
    (
        VideoAssetID,
        Title,
        SourceType,
        VideoUrl,
        PosterUrl,
        DurationSeconds,
        AllowSeek,
        AllowSpeed,
        RequiredWatchPercent,
        Status
    )
    Values
    (
        @VideoAssetID,
        @Title,
        @SourceType,
        @VideoUrl,
        @PosterUrl,
        @DurationSeconds,
        @AllowSeek,
        @AllowSpeed,
        @RequiredWatchPercent,
        @Status
    );

    Declare @VideoID Bigint = Scope_identity();

    Insert dbo.SIM_VideoVersions
    (
        VideoID,
        VersionNumber,
        Title,
        SourceType,
        VideoUrl,
        PosterUrl,
        DurationSeconds,
        AllowSeek,
        AllowSpeed,
        RequiredWatchPercent,
        ChangeSummary,
        VersionStatus,
        CreatedByUserID,
        PublishedByUserID,
        PublishedAt
    )
    Values
    (
        @VideoID,
        1,
        @Title,
        @SourceType,
        @VideoUrl,
        @PosterUrl,
        @DurationSeconds,
        @AllowSeek,
        @AllowSpeed,
        @RequiredWatchPercent,
        N'Phiên bản đầu tiên.',
        'PUBLISHED',
        @ActorId,
        @ActorId,
        Sysutcdatetime()
    );

    Declare @VideoVersionID Bigint = Scope_identity();

    Update dbo.SIM_Videos
    Set
        CurrentVideoVersionID = @VideoVersionID
    Where (dbo.SIM_Videos.VideoID = @VideoID);

    Update dbo.SIM_Lessons
    Set
        VideoID = @VideoID,
        VideoVersionID = @VideoVersionID,
        DurationSeconds = @DurationSeconds,
        UpdatedAt = Sysutcdatetime()
    Where (dbo.SIM_Lessons.LessonID = @LessonId);

    Insert dbo.SYS_AuditLogs
    (
        UserID,
        Action,
        Module,
        EntityName,
        EntityID
    )
    Values
    (
        @ActorId,
        'CREATE',
        'VIDEO',
        'VideoVersion',
        Convert(Nvarchar(100), @VideoVersionID)
    );

    Commit Transaction;

    Select
        @VideoID;
End;
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
        Or @RequiredWatchPercent Not Between 0 And 100
        Throw 50001, N'Dữ liệu video không hợp lệ.', 1;

    Declare @VideoAssetID Bigint,
        @CurrentVideoVersionID Bigint,
        @CurrentVersionUsageCount Int;

    Select
        @VideoAssetID = dbo.SIM_Videos.VideoAssetID,
        @CurrentVideoVersionID = dbo.SIM_Videos.CurrentVideoVersionID
    From dbo.SIM_Videos
        Inner Join dbo.SIM_VideoAssets On dbo.SIM_VideoAssets.VideoAssetID = dbo.SIM_Videos.VideoAssetID
    Where (dbo.SIM_Videos.VideoID = @Id)
        And (dbo.SIM_VideoAssets.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.SIM_VideoAssets.CreatedByUserID = @ActorId);

    If @VideoAssetID Is Null
        Throw 50003, N'Bạn không có quyền quản lý video này.', 1;

    Select
        @CurrentVersionUsageCount = Count(*)
    From dbo.SIM_Lessons
    Where (dbo.SIM_Lessons.VideoID = @Id)
        And (dbo.SIM_Lessons.VideoVersionID = @CurrentVideoVersionID)
        And (dbo.SIM_Lessons.IsDeleted = 0);

    If @CurrentVersionUsageCount > 1
        Throw 50005, N'Video đang dùng trong nhiều bài học. Hãy tạo phiên bản mới tại Thư viện video và chọn bài học cần chuyển.', 1;

    Declare @LessonIdsJson Nvarchar(Max) = Case When @CurrentVersionUsageCount = 1 And @LessonId > 0 Then Concat(N'[', @LessonId, N']') Else N'[]' End;

    Exec dbo.LMS_VideoLibrary_Update
        @Id = @VideoAssetID,
        @Title = @Title,
        @VideoUrl = @VideoUrl,
        @PosterUrl = @PosterUrl,
        @DurationSeconds = @DurationSeconds,
        @OriginalFileName = Null,
        @FileSize = Null,
        @MimeType = Null,
        @Status = @Status,
        @LessonIdsJson = @LessonIdsJson,
        @ChangeSummary = N'Tạo phiên bản mới từ màn hình biên tập video tương tác.',
        @ActorId = @ActorId,
        @IsAdmin = @IsAdmin;

    Select
        @CurrentVideoVersionID = dbo.SIM_Videos.CurrentVideoVersionID
    From dbo.SIM_Videos
    Where (dbo.SIM_Videos.VideoID = @Id);

    Update dbo.SIM_VideoVersions
    Set
        AllowSeek = @AllowSeek,
        AllowSpeed = @AllowSpeed,
        RequiredWatchPercent = @RequiredWatchPercent
    Where (dbo.SIM_VideoVersions.VideoVersionID = @CurrentVideoVersionID);

    Update dbo.SIM_Videos
    Set
        AllowSeek = @AllowSeek,
        AllowSpeed = @AllowSpeed,
        RequiredWatchPercent = @RequiredWatchPercent,
        UpdatedAt = Sysutcdatetime()
    Where (dbo.SIM_Videos.VideoID = @Id);
End;
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

    If @TimeSeconds < 0
        Or @Score < 0
        Or @AttemptLimit <= 0
        Or @SortOrder <= 0
        Throw 50001, N'Dữ liệu tương tác không hợp lệ.', 1;

    Declare @VideoVersionID Bigint;

    Select
        @VideoVersionID = dbo.SIM_Videos.CurrentVideoVersionID
    From dbo.SIM_Videos
        Inner Join dbo.SIM_VideoAssets On dbo.SIM_VideoAssets.VideoAssetID = dbo.SIM_Videos.VideoAssetID
    Where (dbo.SIM_Videos.VideoID = @VideoId)
        And (dbo.SIM_VideoAssets.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.SIM_VideoAssets.CreatedByUserID = @ActorId);

    If @VideoVersionID Is Null
        Throw 50003, N'Bạn không có quyền quản lý tương tác này.', 1;

    If Not Exists
        (
            Select
                1
            From dbo.LMS_Questions
            Where (dbo.LMS_Questions.QuestionID = @QuestionId)
                And (dbo.LMS_Questions.IsDeleted = 0)
                And (dbo.LMS_Questions.Status = 'ACTIVE')
        )
        Throw 50002, N'Câu hỏi không tồn tại hoặc không hoạt động.', 1;

    Insert dbo.LMS_VideoInteractions
    (
        VideoID,
        VideoVersionID,
        QuestionID,
        TimeSeconds,
        EndTimeSeconds,
        InteractionType,
        Required,
        PauseVideo,
        AllowSkip,
        Score,
        AttemptLimit,
        SortOrder,
        Status
    )
    Values
    (
        @VideoId,
        @VideoVersionID,
        @QuestionId,
        @TimeSeconds,
        @EndTimeSeconds,
        @InteractionType,
        @Required,
        @PauseVideo,
        @AllowSkip,
        @Score,
        @AttemptLimit,
        @SortOrder,
        @Status
    );

    Declare @VideoInteractionID Bigint = Scope_identity();

    Insert dbo.SYS_AuditLogs
    (
        UserID,
        Action,
        Module,
        EntityName,
        EntityID
    )
    Values
    (
        @ActorId,
        'CREATE',
        'VIDEO_INTERACTION',
        'VideoInteraction',
        Convert(Nvarchar(100), @VideoInteractionID)
    );

    Select
        @VideoInteractionID;
End;
Go

Create Or Alter Procedure dbo.LMS_VideoLibrary_Update
    @Id Bigint,
    @Title Nvarchar(500),
    @SourceType Varchar(20) = 'LOCAL',
    @VideoUrl Nvarchar(1000),
    @PosterUrl Nvarchar(1000) = Null,
    @DurationSeconds Int,
    @OriginalFileName Nvarchar(500) = Null,
    @FileSize Bigint = Null,
    @MimeType Nvarchar(150) = Null,
    @Status Varchar(30) = 'ACTIVE',
    @LessonIdsJson Nvarchar(Max) = N'[]',
    @ChangeSummary Nvarchar(1000) = Null,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Exec dbo.LMS_VideoLibrary_UpdateWithLearningPolicy
        @Id = @Id,
        @Title = @Title,
        @SourceType = @SourceType,
        @VideoUrl = @VideoUrl,
        @PosterUrl = @PosterUrl,
        @DurationSeconds = @DurationSeconds,
        @OriginalFileName = @OriginalFileName,
        @FileSize = @FileSize,
        @MimeType = @MimeType,
        @Status = @Status,
        @LessonIdsJson = @LessonIdsJson,
        @ChangeSummary = @ChangeSummary,
        @ActorId = @ActorId,
        @IsAdmin = @IsAdmin;
End;
Go

Create Or Alter Procedure dbo.LMS_Video_Update
    @Id Bigint,
    @LessonId Bigint,
    @Title Nvarchar(500),
    @SourceType Varchar(20) = 'LOCAL',
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

    Exec dbo.LMS_Video_UpdateWithLearningPolicy
        @Id = @Id,
        @LessonId = @LessonId,
        @Title = @Title,
        @SourceType = @SourceType,
        @VideoUrl = @VideoUrl,
        @PosterUrl = @PosterUrl,
        @DurationSeconds = @DurationSeconds,
        @AllowSeek = @AllowSeek,
        @AllowSpeed = @AllowSpeed,
        @RequiredWatchPercent = @RequiredWatchPercent,
        @Status = @Status,
        @ActorId = @ActorId,
        @IsAdmin = @IsAdmin;
End;
Go

Create Or Alter Procedure dbo.LMS_Video_AssertEditable
    @VideoId Bigint,
    @ActorId Bigint,
    @IsAdmin Bit = 0,
    @VideoVersionId Bigint Output,
    @DurationSeconds Int Output
As
Begin
    Set Nocount On;

    Select
        @VideoVersionId = dbo.SIM_Videos.CurrentVideoVersionID,
        @DurationSeconds = dbo.SIM_VideoVersions.DurationSeconds
    From dbo.SIM_Videos
        Inner Join dbo.SIM_VideoAssets On dbo.SIM_VideoAssets.VideoAssetID = dbo.SIM_Videos.VideoAssetID
        Inner Join dbo.SIM_VideoVersions On dbo.SIM_VideoVersions.VideoVersionID = dbo.SIM_Videos.CurrentVideoVersionID
    Where (dbo.SIM_Videos.VideoID = @VideoId)
        And (dbo.SIM_VideoAssets.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.SIM_VideoAssets.CreatedByUserID = @ActorId);

    If @VideoVersionId Is Null
        Throw 50003, N'Bạn không có quyền quản lý video này.', 1;

    If Exists
        (
            Select
                1
            From dbo.LMS_StudentAnswers
            Where (dbo.LMS_StudentAnswers.VideoID = @VideoId)
        )
        Or Exists
        (
            Select
                1
            From dbo.LMS_StudentLessonProgress
                Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.LessonID = dbo.LMS_StudentLessonProgress.LessonID
            Where (dbo.SIM_Lessons.VideoID = @VideoId)
                And (dbo.LMS_StudentLessonProgress.Score > 0)
        )
        Throw 50005, N'Video đã có kết quả học tập nên không thể sửa. Hãy nhân bản video để tạo nội dung mới.', 1;
End;
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

    Declare @VideoVersionID Bigint,
        @DurationSeconds Int;

    Exec dbo.LMS_Video_AssertEditable
        @VideoId = @VideoId,
        @ActorId = @ActorId,
        @IsAdmin = @IsAdmin,
        @VideoVersionId = @VideoVersionID Output,
        @DurationSeconds = @DurationSeconds Output;

    If Not Exists
        (
            Select
                1
            From dbo.LMS_Questions
            Where (dbo.LMS_Questions.QuestionID = @QuestionId)
                And (dbo.LMS_Questions.IsDeleted = 0)
                And (dbo.LMS_Questions.Status = 'ACTIVE')
        )
        Or @TimeSeconds < 0
        Or @TimeSeconds > @DurationSeconds
        Or @AttemptLimit < 1
        Or @Score < 0
        Throw 50001, N'Dữ liệu tương tác không hợp lệ.', 1;

    Insert dbo.LMS_VideoInteractions
    (
        VideoID,
        VideoVersionID,
        QuestionID,
        TimeSeconds,
        EndTimeSeconds,
        InteractionType,
        Required,
        PauseVideo,
        AllowSkip,
        Score,
        AttemptLimit,
        SortOrder,
        Status
    )
    Values
    (
        @VideoId,
        @VideoVersionID,
        @QuestionId,
        @TimeSeconds,
        @EndTimeSeconds,
        @InteractionType,
        @Required,
        @PauseVideo,
        @AllowSkip,
        @Score,
        @AttemptLimit,
        @SortOrder,
        @Status
    );

    Declare @VideoInteractionID Bigint = Scope_identity();

    Insert dbo.SYS_AuditLogs
    (
        UserID,
        Action,
        Module,
        EntityName,
        EntityID
    )
    Values
    (
        @ActorId,
        'CREATE',
        'VIDEO_INTERACTION',
        'VideoInteraction',
        Convert(Nvarchar(100), @VideoInteractionID)
    );

    Select
        @VideoInteractionID;
End;
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

    Declare @VideoID Bigint,
        @VideoVersionID Bigint,
        @DurationSeconds Int;

    Select
        @VideoID = dbo.LMS_VideoInteractions.VideoID
    From dbo.LMS_VideoInteractions
    Where (dbo.LMS_VideoInteractions.VideoInteractionID = @Id)
        And (dbo.LMS_VideoInteractions.IsDeleted = 0);

    If @VideoID Is Null
        Throw 50002, N'Không tìm thấy tương tác.', 1;

    Exec dbo.LMS_Video_AssertEditable
        @VideoId = @VideoID,
        @ActorId = @ActorId,
        @IsAdmin = @IsAdmin,
        @VideoVersionId = @VideoVersionID Output,
        @DurationSeconds = @DurationSeconds Output;

    If Not Exists
        (
            Select
                1
            From dbo.LMS_Questions
            Where (dbo.LMS_Questions.QuestionID = @QuestionId)
                And (dbo.LMS_Questions.IsDeleted = 0)
        )
        Or @TimeSeconds < 0
        Or @TimeSeconds > @DurationSeconds
        Or @AttemptLimit < 1
        Or @Score < 0
        Throw 50001, N'Dữ liệu tương tác không hợp lệ.', 1;

    Update dbo.LMS_VideoInteractions
    Set
        QuestionID = @QuestionId,
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
    Where (dbo.LMS_VideoInteractions.VideoInteractionID = @Id)
        And (dbo.LMS_VideoInteractions.VideoVersionID = @VideoVersionID)
        And (dbo.LMS_VideoInteractions.IsDeleted = 0);

    If @@Rowcount = 0
        Throw 50002, N'Không tìm thấy tương tác trong phiên bản hiện tại.', 1;

    Insert dbo.SYS_AuditLogs
    (
        UserID,
        Action,
        Module,
        EntityName,
        EntityID
    )
    Values
    (
        @ActorId,
        'UPDATE',
        'VIDEO_INTERACTION',
        'VideoInteraction',
        Convert(Nvarchar(100), @Id)
    );

    Select
        1;
End;
Go

Create Or Alter Procedure dbo.LMS_VideoInteraction_Delete
    @Id Bigint,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Declare @VideoID Bigint,
        @VideoVersionID Bigint,
        @DurationSeconds Int;

    Select
        @VideoID = dbo.LMS_VideoInteractions.VideoID
    From dbo.LMS_VideoInteractions
    Where (dbo.LMS_VideoInteractions.VideoInteractionID = @Id)
        And (dbo.LMS_VideoInteractions.IsDeleted = 0);

    If @VideoID Is Null
        Throw 50002, N'Không tìm thấy tương tác.', 1;

    Exec dbo.LMS_Video_AssertEditable
        @VideoId = @VideoID,
        @ActorId = @ActorId,
        @IsAdmin = @IsAdmin,
        @VideoVersionId = @VideoVersionID Output,
        @DurationSeconds = @DurationSeconds Output;

    Update dbo.LMS_VideoInteractions
    Set
        IsDeleted = 1,
        UpdatedAt = Sysutcdatetime()
    Where (dbo.LMS_VideoInteractions.VideoInteractionID = @Id)
        And (dbo.LMS_VideoInteractions.VideoVersionID = @VideoVersionID)
        And (dbo.LMS_VideoInteractions.IsDeleted = 0);

    Declare @Rows Int = @@Rowcount;

    If @Rows = 0
        Throw 50002, N'Không tìm thấy tương tác trong phiên bản hiện tại.', 1;

    Insert dbo.SYS_AuditLogs
    (
        UserID,
        Action,
        Module,
        EntityName,
        EntityID
    )
    Values
    (
        @ActorId,
        'DELETE',
        'VIDEO_INTERACTION',
        'VideoInteraction',
        Convert(Nvarchar(100), @Id)
    );

    Select
        @Rows;
End;
Go

Create Or Alter Procedure dbo.LMS_VideoInteraction_Reorder
    @Id Bigint,
    @SortOrder Int,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Declare @VideoID Bigint,
        @VideoVersionID Bigint,
        @DurationSeconds Int;

    Select
        @VideoID = dbo.LMS_VideoInteractions.VideoID
    From dbo.LMS_VideoInteractions
    Where (dbo.LMS_VideoInteractions.VideoInteractionID = @Id)
        And (dbo.LMS_VideoInteractions.IsDeleted = 0);

    If @VideoID Is Null
        Throw 50002, N'Không tìm thấy tương tác.', 1;

    Exec dbo.LMS_Video_AssertEditable
        @VideoId = @VideoID,
        @ActorId = @ActorId,
        @IsAdmin = @IsAdmin,
        @VideoVersionId = @VideoVersionID Output,
        @DurationSeconds = @DurationSeconds Output;

    Update dbo.LMS_VideoInteractions
    Set
        SortOrder = @SortOrder,
        UpdatedAt = Sysutcdatetime()
    Where (dbo.LMS_VideoInteractions.VideoInteractionID = @Id)
        And (dbo.LMS_VideoInteractions.VideoVersionID = @VideoVersionID)
        And (dbo.LMS_VideoInteractions.IsDeleted = 0);

    If @@Rowcount = 0
        Throw 50002, N'Không tìm thấy tương tác trong phiên bản hiện tại.', 1;
End;
Go

Declare @tblVideoPolicyDescriptions Table
(
    ProcedureName Sysname Not Null,
    ProcedureDescription Nvarchar(1000) Not Null
);

Insert @tblVideoPolicyDescriptions
(
    ProcedureName,
    ProcedureDescription
)
Values
    (N'LMS_VideoLibrary_UpdateWithLearningPolicy', N'Cập nhật trực tiếp video và đồng bộ tất cả bài học khi chưa phát sinh câu trả lời hoặc điểm; khóa sửa khi đã có kết quả.'),
    (N'LMS_Video_UpdateWithLearningPolicy', N'Cập nhật video từ màn hình biên tập theo chính sách khóa dữ liệu học tập.'),
    (N'LMS_VideoLibrary_Update', N'Điểm vào cập nhật video: đồng bộ toàn bộ bài học khi chưa có kết quả và từ chối sửa khi đã có kết quả.'),
    (N'LMS_Video_Update', N'Cập nhật nội dung, cấu hình phát của video hiện tại và đồng bộ tất cả bài học chưa có kết quả.'),
    (N'LMS_VideoLibrary_Duplicate', N'Nhân bản tài nguyên video, cấu hình và toàn bộ tương tác hiện tại thành video riêng tư độc lập của người thực hiện.'),
    (N'LMS_Video_AssertEditable', N'Kiểm tra quyền tác giả hoặc quản trị và bảo đảm video chưa phát sinh câu trả lời hay điểm trước khi cho phép sửa.'),
    (N'LMS_VideoInteraction_Create', N'Tạo tương tác cho video hiện tại khi video chưa có kết quả học tập.'),
    (N'LMS_VideoInteraction_Update', N'Sửa tương tác của phiên bản hiện tại khi video chưa có kết quả học tập.'),
    (N'LMS_VideoInteraction_Delete', N'Xóa mềm tương tác của phiên bản hiện tại khi video chưa có kết quả học tập.'),
    (N'LMS_VideoInteraction_Reorder', N'Đổi thứ tự tương tác của phiên bản hiện tại khi video chưa có kết quả học tập.');

Declare @VideoPolicyProcedureName Sysname,
    @VideoPolicyProcedureDescription Nvarchar(1000);

Declare video_policy_description_cursor Cursor Local Fast_forward For
    Select
        ProcedureName,
        ProcedureDescription
    From @tblVideoPolicyDescriptions;

Open video_policy_description_cursor;
Fetch Next From video_policy_description_cursor Into @VideoPolicyProcedureName, @VideoPolicyProcedureDescription;

While @@Fetch_status = 0
Begin
    If Exists
        (
            Select
                1
            From sys.extended_properties
            Where (class = 1)
                And (major_id = Object_id(N'dbo.' + @VideoPolicyProcedureName))
                And (minor_id = 0)
                And (name = N'MS_Description')
        )
        Exec sys.sp_updateextendedproperty @name = N'MS_Description', @value = @VideoPolicyProcedureDescription, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'PROCEDURE', @level1name = @VideoPolicyProcedureName;
    Else
        Exec sys.sp_addextendedproperty @name = N'MS_Description', @value = @VideoPolicyProcedureDescription, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'PROCEDURE', @level1name = @VideoPolicyProcedureName;

    Fetch Next From video_policy_description_cursor Into @VideoPolicyProcedureName, @VideoPolicyProcedureDescription;
End;

Close video_policy_description_cursor;
Deallocate video_policy_description_cursor;
Go
