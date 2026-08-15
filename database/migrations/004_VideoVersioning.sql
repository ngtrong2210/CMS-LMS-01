Set Nocount On;
Set Xact_abort On;
Set Ansi_nulls On;
Set Quoted_identifier On;

/*
    Tạo trước bảng/cột ở một batch riêng để SQL Server biên dịch được các câu lệnh
    tham chiếu VideoVersionID trong batch migration chính ngay ở lần chạy đầu tiên.
*/
If Object_id(N'dbo.SIM_VideoVersions', N'U') Is Null
Begin
    Create Table dbo.SIM_VideoVersions
    (
        VideoVersionID Bigint Identity(1, 1) Not Null,
        VideoID Bigint Not Null,
        VersionNumber Int Not Null,
        Title Nvarchar(500) Not Null,
        VideoUrl Nvarchar(1000) Null,
        PosterUrl Nvarchar(1000) Null,
        DurationSeconds Int Not Null,
        AllowSeek Bit Not Null Constraint DF_SIM_VideoVersions_AllowSeek Default 0,
        AllowSpeed Bit Not Null Constraint DF_SIM_VideoVersions_AllowSpeed Default 1,
        RequiredWatchPercent Decimal(5, 2) Not Null Constraint DF_SIM_VideoVersions_RequiredWatchPercent Default 80,
        OriginalFileName Nvarchar(500) Null,
        FileSize Bigint Null,
        MimeType Nvarchar(150) Null,
        ChangeSummary Nvarchar(1000) Null,
        VersionStatus Varchar(30) Not Null Constraint DF_SIM_VideoVersions_VersionStatus Default 'PUBLISHED',
        CreatedByUserID Bigint Not Null,
        CreatedAt Datetime2 Not Null Constraint DF_SIM_VideoVersions_CreatedAt Default Sysutcdatetime(),
        PublishedByUserID Bigint Null,
        PublishedAt Datetime2 Null,
        RowVersion Rowversion Not Null,
        Constraint PK_SIM_VideoVersions Primary Key (VideoVersionID),
        Constraint UQ_SIM_VideoVersions_Video_Version Unique (VideoID, VersionNumber),
        Constraint CK_SIM_VideoVersions_VersionNumber Check (VersionNumber > 0),
        Constraint CK_SIM_VideoVersions_Duration Check (DurationSeconds > 0),
        Constraint CK_SIM_VideoVersions_WatchPercent Check (RequiredWatchPercent Between 0 And 100),
        Constraint CK_SIM_VideoVersions_Status Check (VersionStatus In ('DRAFT', 'PUBLISHED', 'ARCHIVED')),
        Constraint FK_SIM_VideoVersions_Video Foreign Key (VideoID) References dbo.SIM_Videos(VideoID),
        Constraint FK_SIM_VideoVersions_CreatedByUser Foreign Key (CreatedByUserID) References dbo.SYS_Users(UserID),
        Constraint FK_SIM_VideoVersions_PublishedByUser Foreign Key (PublishedByUserID) References dbo.SYS_Users(UserID)
    );
End;

If Col_length(N'dbo.SIM_Videos', N'CurrentVideoVersionID') Is Null
    Alter Table dbo.SIM_Videos Add CurrentVideoVersionID Bigint Null;

If Col_length(N'dbo.SIM_Lessons', N'VideoVersionID') Is Null
    Alter Table dbo.SIM_Lessons Add VideoVersionID Bigint Null;

If Col_length(N'dbo.LMS_VideoInteractions', N'VideoVersionID') Is Null
    Alter Table dbo.LMS_VideoInteractions Add VideoVersionID Bigint Null;

If Col_length(N'dbo.LMS_StudentVideoProgress', N'VideoVersionID') Is Null
    Alter Table dbo.LMS_StudentVideoProgress Add VideoVersionID Bigint Null;

If Col_length(N'dbo.LMS_StudentAnswers', N'VideoVersionID') Is Null
    Alter Table dbo.LMS_StudentAnswers Add VideoVersionID Bigint Null;

If Col_length(N'dbo.LMS_LearningSessions', N'VideoVersionID') Is Null
    Alter Table dbo.LMS_LearningSessions Add VideoVersionID Bigint Null;
Go

Set Nocount On;
Set Xact_abort On;
Set Ansi_nulls On;
Set Quoted_identifier On;

Begin Try
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
        CreatedAt,
        PublishedByUserID,
        PublishedAt
    )
    Select
        dbo.SIM_Videos.VideoID,
        1,
        dbo.SIM_Videos.Title,
        dbo.SIM_Videos.VideoUrl,
        dbo.SIM_Videos.PosterUrl,
        dbo.SIM_Videos.DurationSeconds,
        dbo.SIM_Videos.AllowSeek,
        dbo.SIM_Videos.AllowSpeed,
        dbo.SIM_Videos.RequiredWatchPercent,
        dbo.SIM_VideoAssets.OriginalFileName,
        dbo.SIM_VideoAssets.FileSize,
        dbo.SIM_VideoAssets.MimeType,
        N'Phiên bản đầu tiên được tạo khi nâng cấp hệ thống.',
        'PUBLISHED',
        dbo.SIM_VideoAssets.CreatedByUserID,
        Coalesce(dbo.SIM_Videos.CreatedAt, Sysutcdatetime()),
        dbo.SIM_VideoAssets.CreatedByUserID,
        Coalesce(dbo.SIM_Videos.UpdatedAt, dbo.SIM_Videos.CreatedAt, Sysutcdatetime())
    From dbo.SIM_Videos
        Inner Join dbo.SIM_VideoAssets On dbo.SIM_VideoAssets.VideoAssetID = dbo.SIM_Videos.VideoAssetID
    Where Not Exists
        (
            Select
                1
            From dbo.SIM_VideoVersions
            Where (dbo.SIM_VideoVersions.VideoID = dbo.SIM_Videos.VideoID)
        );

    Update dbo.SIM_Videos
    Set
        CurrentVideoVersionID = currentVersion.VideoVersionID
    From dbo.SIM_Videos
        Inner Join dbo.SIM_VideoVersions currentVersion On currentVersion.VideoID = dbo.SIM_Videos.VideoID
            And currentVersion.VersionNumber =
            (
                Select
                    Max(latestVersion.VersionNumber)
                From dbo.SIM_VideoVersions latestVersion
                Where (latestVersion.VideoID = dbo.SIM_Videos.VideoID)
            )
    Where (dbo.SIM_Videos.CurrentVideoVersionID Is Null);

    Update dbo.SIM_Lessons
    Set
        VideoVersionID = dbo.SIM_Videos.CurrentVideoVersionID
    From dbo.SIM_Lessons
        Inner Join dbo.SIM_Videos On dbo.SIM_Videos.VideoID = dbo.SIM_Lessons.VideoID
    Where (dbo.SIM_Lessons.VideoVersionID Is Null);

    Update dbo.LMS_VideoInteractions
    Set
        VideoVersionID = dbo.SIM_Videos.CurrentVideoVersionID
    From dbo.LMS_VideoInteractions
        Inner Join dbo.SIM_Videos On dbo.SIM_Videos.VideoID = dbo.LMS_VideoInteractions.VideoID
    Where (dbo.LMS_VideoInteractions.VideoVersionID Is Null);

    Update dbo.LMS_StudentVideoProgress
    Set
        VideoVersionID = Coalesce(dbo.SIM_Lessons.VideoVersionID, dbo.SIM_Videos.CurrentVideoVersionID)
    From dbo.LMS_StudentVideoProgress
        Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.LessonID = dbo.LMS_StudentVideoProgress.LessonID
        Inner Join dbo.SIM_Videos On dbo.SIM_Videos.VideoID = dbo.LMS_StudentVideoProgress.VideoID
    Where (dbo.LMS_StudentVideoProgress.VideoVersionID Is Null);

    Update dbo.LMS_StudentAnswers
    Set
        VideoVersionID = Coalesce(dbo.SIM_Lessons.VideoVersionID, dbo.SIM_Videos.CurrentVideoVersionID)
    From dbo.LMS_StudentAnswers
        Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.LessonID = dbo.LMS_StudentAnswers.LessonID
        Inner Join dbo.SIM_Videos On dbo.SIM_Videos.VideoID = dbo.LMS_StudentAnswers.VideoID
    Where (dbo.LMS_StudentAnswers.VideoVersionID Is Null)
        And (dbo.LMS_StudentAnswers.VideoID Is Not Null);

    Update dbo.LMS_LearningSessions
    Set
        VideoVersionID = Coalesce(dbo.SIM_Lessons.VideoVersionID, dbo.SIM_Videos.CurrentVideoVersionID)
    From dbo.LMS_LearningSessions
        Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.LessonID = dbo.LMS_LearningSessions.LessonID
        Inner Join dbo.SIM_Videos On dbo.SIM_Videos.VideoID = dbo.LMS_LearningSessions.VideoID
    Where (dbo.LMS_LearningSessions.VideoVersionID Is Null)
        And (dbo.LMS_LearningSessions.VideoID Is Not Null);

    If Not Exists
        (
            Select
                1
            From sys.foreign_keys
            Where (name = N'FK_SIM_Videos_CurrentVideoVersion')
        )
        Alter Table dbo.SIM_Videos Add Constraint FK_SIM_Videos_CurrentVideoVersion Foreign Key (CurrentVideoVersionID) References dbo.SIM_VideoVersions(VideoVersionID);

    If Not Exists
        (
            Select
                1
            From sys.foreign_keys
            Where (name = N'FK_SIM_Lessons_VideoVersion')
        )
        Alter Table dbo.SIM_Lessons Add Constraint FK_SIM_Lessons_VideoVersion Foreign Key (VideoVersionID) References dbo.SIM_VideoVersions(VideoVersionID);

    If Not Exists
        (
            Select
                1
            From sys.foreign_keys
            Where (name = N'FK_LMS_VideoInteractions_VideoVersion')
        )
        Alter Table dbo.LMS_VideoInteractions Add Constraint FK_LMS_VideoInteractions_VideoVersion Foreign Key (VideoVersionID) References dbo.SIM_VideoVersions(VideoVersionID);

    If Not Exists
        (
            Select
                1
            From sys.foreign_keys
            Where (name = N'FK_LMS_StudentVideoProgress_VideoVersion')
        )
        Alter Table dbo.LMS_StudentVideoProgress Add Constraint FK_LMS_StudentVideoProgress_VideoVersion Foreign Key (VideoVersionID) References dbo.SIM_VideoVersions(VideoVersionID);

    If Not Exists
        (
            Select
                1
            From sys.foreign_keys
            Where (name = N'FK_LMS_StudentAnswers_VideoVersion')
        )
        Alter Table dbo.LMS_StudentAnswers Add Constraint FK_LMS_StudentAnswers_VideoVersion Foreign Key (VideoVersionID) References dbo.SIM_VideoVersions(VideoVersionID);

    If Not Exists
        (
            Select
                1
            From sys.foreign_keys
            Where (name = N'FK_LMS_LearningSessions_VideoVersion')
        )
        Alter Table dbo.LMS_LearningSessions Add Constraint FK_LMS_LearningSessions_VideoVersion Foreign Key (VideoVersionID) References dbo.SIM_VideoVersions(VideoVersionID);

    Declare @ProgressConstraintName Sysname;

    Select
        @ProgressConstraintName = sys.key_constraints.name
    From sys.key_constraints
        Inner Join sys.index_columns On sys.index_columns.object_id = sys.key_constraints.parent_object_id
            And sys.index_columns.index_id = sys.key_constraints.unique_index_id
        Inner Join sys.columns On sys.columns.object_id = sys.index_columns.object_id
            And sys.columns.column_id = sys.index_columns.column_id
    Where (sys.key_constraints.parent_object_id = Object_id(N'dbo.LMS_StudentVideoProgress'))
        And (sys.key_constraints.type = 'UQ')
    Group By
        sys.key_constraints.name
    Having (Count(*) = 3)
        And (Sum(Case When sys.columns.name In (N'StudentUserID', N'LessonID', N'VideoID') Then 1 Else 0 End) = 3);

    If @ProgressConstraintName Is Not Null
    Begin
        Declare @DropProgressConstraintSql Nvarchar(Max) = N'Alter Table dbo.LMS_StudentVideoProgress Drop Constraint ' + Quotename(@ProgressConstraintName) + N';';
        Exec sys.sp_executesql @DropProgressConstraintSql;
    End;

    If Not Exists
        (
            Select
                1
            From sys.key_constraints
            Where (parent_object_id = Object_id(N'dbo.LMS_StudentVideoProgress'))
                And (name = N'UQ_LMS_StudentVideoProgress_LessonVideoVersion')
        )
        Alter Table dbo.LMS_StudentVideoProgress Add Constraint UQ_LMS_StudentVideoProgress_LessonVideoVersion Unique (StudentUserID, LessonID, VideoID, VideoVersionID);

    If Not Exists
        (
            Select
                1
            From sys.indexes
            Where (object_id = Object_id(N'dbo.SIM_Lessons'))
                And (name = N'IX_SIM_Lessons_VideoVersionID')
        )
        Create Index IX_SIM_Lessons_VideoVersionID On dbo.SIM_Lessons(VideoVersionID) Where VideoVersionID Is Not Null;

    If Not Exists
        (
            Select
                1
            From sys.indexes
            Where (object_id = Object_id(N'dbo.LMS_VideoInteractions'))
                And (name = N'IX_LMS_VideoInteractions_VideoVersion_Time')
        )
        Create Index IX_LMS_VideoInteractions_VideoVersion_Time On dbo.LMS_VideoInteractions(VideoVersionID, TimeSeconds) Include (VideoID, QuestionID, Status, IsDeleted);

    If Exists
        (
            Select
                1
            From sys.extended_properties
            Where (class = 1)
                And (major_id = Object_id(N'dbo.SIM_VideoVersions'))
                And (minor_id = 0)
                And (name = N'MS_Description')
        )
        Exec sys.sp_updateextendedproperty @name = N'MS_Description', @value = N'[SIM] Lịch sử phiên bản bất biến của video; bài học ghim một phiên bản cụ thể để tránh thay đổi nội dung ngoài ý muốn.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'SIM_VideoVersions';
    Else
        Exec sys.sp_addextendedproperty @name = N'MS_Description', @value = N'[SIM] Lịch sử phiên bản bất biến của video; bài học ghim một phiên bản cụ thể để tránh thay đổi nội dung ngoài ý muốn.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'SIM_VideoVersions';

    Declare @tblColumnDescriptions Table
    (
        TableName Sysname Not Null,
        ColumnName Sysname Not Null,
        ColumnDescription Nvarchar(1000) Not Null
    );

    Insert @tblColumnDescriptions
    (
        TableName,
        ColumnName,
        ColumnDescription
    )
    Values
        (N'SIM_VideoVersions', N'VideoVersionID', N'Khóa chính tự tăng của phiên bản video.'),
        (N'SIM_VideoVersions', N'VideoID', N'ID video gốc sở hữu phiên bản.'),
        (N'SIM_VideoVersions', N'VersionNumber', N'Số phiên bản tăng dần trong phạm vi một video.'),
        (N'SIM_VideoVersions', N'Title', N'Tên video được chụp tại thời điểm tạo phiên bản.'),
        (N'SIM_VideoVersions', N'VideoUrl', N'Đường dẫn file video tương đối trong project của phiên bản.'),
        (N'SIM_VideoVersions', N'PosterUrl', N'Đường dẫn ảnh đại diện của phiên bản video.'),
        (N'SIM_VideoVersions', N'DurationSeconds', N'Thời lượng của file thuộc phiên bản, tính bằng giây.'),
        (N'SIM_VideoVersions', N'AllowSeek', N'Cho phép học viên tua video trong phiên bản.'),
        (N'SIM_VideoVersions', N'AllowSpeed', N'Cho phép học viên thay đổi tốc độ phát.'),
        (N'SIM_VideoVersions', N'RequiredWatchPercent', N'Tỷ lệ xem tối thiểu để hoàn thành phiên bản video.'),
        (N'SIM_VideoVersions', N'OriginalFileName', N'Tên gốc của file video khi được tải lên.'),
        (N'SIM_VideoVersions', N'FileSize', N'Kích thước file của phiên bản video, tính bằng byte.'),
        (N'SIM_VideoVersions', N'MimeType', N'Kiểu MIME của file video thuộc phiên bản.'),
        (N'SIM_VideoVersions', N'ChangeSummary', N'Nội dung mô tả lý do tạo phiên bản mới.'),
        (N'SIM_VideoVersions', N'VersionStatus', N'Trạng thái phiên bản: DRAFT, PUBLISHED hoặc ARCHIVED.'),
        (N'SIM_VideoVersions', N'CreatedByUserID', N'ID người dùng tạo phiên bản.'),
        (N'SIM_VideoVersions', N'CreatedAt', N'Thời điểm tạo phiên bản theo UTC.'),
        (N'SIM_VideoVersions', N'PublishedByUserID', N'ID người dùng xuất bản phiên bản.'),
        (N'SIM_VideoVersions', N'PublishedAt', N'Thời điểm xuất bản phiên bản theo UTC.'),
        (N'SIM_VideoVersions', N'RowVersion', N'Dấu phiên bản hàng do SQL Server quản lý để kiểm soát đồng thời.'),
        (N'SIM_Videos', N'CurrentVideoVersionID', N'ID phiên bản mới nhất dùng cho lần gắn video tiếp theo và màn hình biên tập.'),
        (N'SIM_Lessons', N'VideoVersionID', N'ID phiên bản video được bài học ghim; thay phiên bản khác không ảnh hưởng bài học này.'),
        (N'LMS_VideoInteractions', N'VideoVersionID', N'ID phiên bản video chứa mốc tương tác.'),
        (N'LMS_StudentVideoProgress', N'VideoVersionID', N'ID phiên bản video mà học viên đã xem và phát sinh tiến độ.'),
        (N'LMS_StudentAnswers', N'VideoVersionID', N'ID phiên bản video tại thời điểm học viên trả lời.'),
        (N'LMS_LearningSessions', N'VideoVersionID', N'ID phiên bản video được sử dụng trong phiên học.');

    Declare @DescriptionTableName Sysname,
        @DescriptionColumnName Sysname,
        @DescriptionValue Nvarchar(1000);

    Declare description_cursor Cursor Local Fast_forward For
        Select
            TableName,
            ColumnName,
            ColumnDescription
        From @tblColumnDescriptions;

    Open description_cursor;

    Fetch Next From description_cursor Into @DescriptionTableName, @DescriptionColumnName, @DescriptionValue;

    While @@Fetch_status = 0
    Begin
        If Exists
            (
                Select
                    1
                From sys.extended_properties
                Where (class = 1)
                    And (major_id = Object_id(N'dbo.' + @DescriptionTableName))
                    And (minor_id = Columnproperty(Object_id(N'dbo.' + @DescriptionTableName), @DescriptionColumnName, 'ColumnId'))
                    And (name = N'MS_Description')
            )
            Exec sys.sp_updateextendedproperty @name = N'MS_Description', @value = @DescriptionValue, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = @DescriptionTableName, @level2type = N'COLUMN', @level2name = @DescriptionColumnName;
        Else
            Exec sys.sp_addextendedproperty @name = N'MS_Description', @value = @DescriptionValue, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = @DescriptionTableName, @level2type = N'COLUMN', @level2name = @DescriptionColumnName;

        Fetch Next From description_cursor Into @DescriptionTableName, @DescriptionColumnName, @DescriptionValue;
    End;

    Close description_cursor;
    Deallocate description_cursor;

    Exec(N'Create Or Alter View dbo.VideoVersions As
        Select
            VideoVersionID As Id,
            VideoID As VideoId,
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
            CreatedByUserID As CreatedBy,
            CreatedAt,
            PublishedByUserID As PublishedBy,
            PublishedAt,
            RowVersion
        From dbo.SIM_VideoVersions;');

    Exec(N'Create Or Alter View dbo.Lessons As
        Select
            LessonID As Id,
            CourseID As CourseId,
            ChapterID As ChapterId,
            VideoID As VideoId,
            VideoVersionID As VideoVersionId,
            Title,
            Description,
            LessonType,
            DurationSeconds,
            SortOrder,
            IsRequired,
            PassingScore,
            Status,
            CreatedAt,
            UpdatedAt,
            IsDeleted
        From dbo.SIM_Lessons;');

    Exec(N'Create Or Alter View dbo.Videos As
        Select
            VideoID As Id,
            VideoAssetID As VideoAssetId,
            CurrentVideoVersionID As CurrentVideoVersionId,
            Title,
            VideoUrl,
            PosterUrl,
            DurationSeconds,
            AllowSeek,
            AllowSpeed,
            RequiredWatchPercent,
            Status,
            CreatedAt,
            UpdatedAt
        From dbo.SIM_Videos;');

    Exec(N'Create Or Alter View dbo.VideoInteractions As
        Select
            VideoInteractionID As Id,
            VideoID As VideoId,
            VideoVersionID As VideoVersionId,
            QuestionID As QuestionId,
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
        From dbo.LMS_VideoInteractions;');

    Exec(N'Create Or Alter View dbo.StudentVideoProgress As
        Select
            StudentVideoProgressID As Id,
            StudentUserID As StudentId,
            CourseID As CourseId,
            LessonID As LessonId,
            VideoID As VideoId,
            VideoVersionID As VideoVersionId,
            CurrentTimeSeconds,
            MaxWatchedTimeSeconds,
            WatchedSeconds,
            WatchPercent,
            Completed,
            StartedAt,
            CompletedAt,
            LastAccessAt,
            CreatedAt,
            UpdatedAt,
            RowVersion
        From dbo.LMS_StudentVideoProgress;');

    Exec(N'Create Or Alter View dbo.StudentAnswers As
        Select
            StudentAnswerID As Id,
            StudentUserID As StudentId,
            CourseID As CourseId,
            LessonID As LessonId,
            VideoID As VideoId,
            VideoVersionID As VideoVersionId,
            VideoInteractionID As InteractionId,
            QuestionID As QuestionId,
            AttemptNumber,
            AnswerText,
            IsCorrect,
            ScoreAwarded,
            ReviewStatus,
            AnsweredAt,
            TimeInVideoSeconds,
            TimeSpentSeconds,
            ReviewedByUserID As ReviewedBy,
            ReviewedAt,
            ReviewerComment
        From dbo.LMS_StudentAnswers;');

    Exec(N'Create Or Alter View dbo.LearningSessions As
        Select
            LearningSessionID As Id,
            SessionID As SessionId,
            StudentUserID As StudentId,
            CourseID As CourseId,
            LessonID As LessonId,
            VideoID As VideoId,
            VideoVersionID As VideoVersionId,
            StartedAt,
            EndedAt,
            WatchDurationSeconds,
            LastPositionSeconds,
            MaxPositionSeconds,
            SeekCount,
            PauseCount,
            InteractionCount,
            Completed
        From dbo.LMS_LearningSessions;');

    Commit Transaction;
End Try
Begin Catch
    If Xact_state() <> 0 Rollback Transaction;
    Throw;
End Catch;
Go
