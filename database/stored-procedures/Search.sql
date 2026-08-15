Create Or Alter Procedure dbo.LMS_GlobalSearch
    @Search Nvarchar(250),
    @ActorId Bigint,
    @IsAdmin Bit = 0,
    @Limit Int = 60
As
Begin
    Set Nocount On;

    Declare @Term Nvarchar(250) = Ltrim(Rtrim(Isnull(@Search, N'')));

    If Len(@Term) < 2
    Begin
        Select
            Top (0) Cast(Null As Varchar(30)) ResultType,
            Cast(Null As Bigint) EntityId,
            Cast(Null As Bigint) ParentId,
            Cast(Null As Nvarchar(500)) Title,
            Cast(Null As Nvarchar(1000)) Subtitle,
            Cast(Null As Nvarchar(1000)) Description,
            Cast(Null As Varchar(30)) Status,
            Cast(Null As Nvarchar(1000)) TargetUrl,
            Cast(Null As Varchar(100)) Icon,
            Cast(Null As Datetime2) UpdatedAt,
            Cast(Null As Int) Relevance;

        Return;

    End;

    Set @Limit = Iif(@Limit Between 1 And 100, @Limit, 60);

    Declare @Pattern Nvarchar(520) = N'%' + Replace(Replace(Replace(@Term, N'[', N'[[]'), N'%', N'[%]'), N'_', N'[_]') + N'%';

    Declare @StartsWith Nvarchar(510) = Replace(Replace(Replace(@Term, N'[', N'[[]'), N'%', N'[%]'), N'_', N'[_]') + N'%';

    Declare @Results
    Table (ResultType Varchar(30) Not Null, EntityId Bigint Not Null, ParentId Bigint Null, Title Nvarchar(500) Not Null, Subtitle Nvarchar(1000) Null, Description Nvarchar(1000) Null, Status Varchar(30) Null, TargetUrl Nvarchar(1000) Not Null, Icon Varchar(100) Not Null, UpdatedAt Datetime2 Null, Relevance Int Not Null);

    Insert @Results (ResultType, EntityId, ParentId, Title, Subtitle, Description, Status, TargetUrl, Icon, UpdatedAt, Relevance)
    Select
        'COURSE',
        dbo.Courses.Id,
        Null,
        dbo.Courses.Title,
        Concat(dbo.Courses.Code, N' · ', Isnull(dbo.CourseCategories.Name, N'Chưa phân loại'), N' · ', dbo.Users.FullName),
        Left(Coalesce(dbo.Courses.ShortDescription, dbo.Courses.Description, N''), 1000),
        dbo.Courses.Status,
        Concat(N'/cms/courses/', dbo.Courses.Id, N'/content'),
        'bi-journal-bookmark',
        Coalesce(dbo.Courses.UpdatedAt, dbo.Courses.CreatedAt),
        Case When dbo.Courses.Code = @Term Then 120 When dbo.Courses.Title = @Term Then 115 When dbo.Courses.Code Like @StartsWith Then 100 When dbo.Courses.Title Like @StartsWith Then 90 Else 60 End
    From dbo.Courses
        Inner Join dbo.Users On dbo.Users.Id = dbo.Courses.TeacherId
        Left Join dbo.CourseCategories On dbo.CourseCategories.Id = dbo.Courses.CategoryId
    Where (dbo.Courses.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.Courses.TeacherId = @ActorId)
        And (dbo.Courses.Code Like @Pattern Or dbo.Courses.Title Like @Pattern Or dbo.Courses.ShortDescription Like @Pattern Or dbo.Courses.Description Like @Pattern Or dbo.CourseCategories.Name Like @Pattern Or dbo.Users.FullName Like @Pattern);

    Insert @Results (ResultType, EntityId, ParentId, Title, Subtitle, Description, Status, TargetUrl, Icon, UpdatedAt, Relevance)
    Select
        'LESSON',
        dbo.Lessons.Id,
        dbo.Lessons.CourseId,
        dbo.Lessons.Title,
        Concat(dbo.Courses.Code, N' · ', dbo.Courses.Title, N' · ', dbo.Chapters.Title),
        Left(Isnull(dbo.Lessons.Description, N''), 1000),
        dbo.Lessons.Status,
        Concat(N'/cms/courses/', dbo.Lessons.CourseId, N'/content'),
        'bi-play-btn',
        Coalesce(dbo.Lessons.UpdatedAt, dbo.Lessons.CreatedAt),
        Case When dbo.Lessons.Title = @Term Then 110 When dbo.Lessons.Title Like @StartsWith Then 85 Else 55 End
    From dbo.Lessons
        Inner Join dbo.Courses On dbo.Courses.Id = dbo.Lessons.CourseId And dbo.Courses.IsDeleted = 0
        Inner Join dbo.Chapters On dbo.Chapters.Id = dbo.Lessons.ChapterId And dbo.Chapters.IsDeleted = 0
    Where (dbo.Lessons.IsDeleted = 0)
        And (@IsAdmin = 1 Or dbo.Courses.TeacherId = @ActorId)
        And (dbo.Lessons.Title Like @Pattern Or dbo.Lessons.Description Like @Pattern Or dbo.Courses.Code Like @Pattern Or dbo.Courses.Title Like @Pattern Or dbo.Chapters.Title Like @Pattern);

    Insert @Results (ResultType, EntityId, ParentId, Title, Subtitle, Description, Status, TargetUrl, Icon, UpdatedAt, Relevance)
    Select
        'VIDEO',
        dbo.VideoAssets.Id,
        ownedUse.FirstVideoId,
        dbo.VideoAssets.Title,
        Concat(Coalesce(Nullif(dbo.VideoAssets.OriginalFileName, N''), N'Tệp video'), N' · ', dbo.VideoAssets.DurationSeconds, N' giây · Đang dùng ', usageInfo.UsageCount, N' bài học'),
        N'Video trong thư viện dùng chung cho nhiều bài học và khóa học.',
        dbo.VideoAssets.Status,
        Case When ownedUse.FirstVideoId Is Null Then N'/cms/videos' Else Concat(N'/cms/videos/', ownedUse.FirstVideoId, N'/editor') End,
        'bi-collection-play',
        Coalesce(dbo.VideoAssets.UpdatedAt, dbo.VideoAssets.CreatedAt),
        Case When dbo.VideoAssets.Title = @Term Then 110 When dbo.VideoAssets.Title Like @StartsWith Then 85 When dbo.VideoAssets.OriginalFileName Like @StartsWith Then 80 Else 55 End
    From dbo.VideoAssets
        Outer Apply (
            Select
                Count(*) UsageCount
            From dbo.Videos
                Inner Join dbo.Lessons On dbo.Lessons.VideoId = dbo.Videos.Id And dbo.Lessons.IsDeleted = 0
            Where (dbo.Videos.VideoAssetId = dbo.VideoAssets.Id)
    ) usageInfo
        Outer Apply (
            Select
                Min(dbo.Videos.Id) FirstVideoId
            From dbo.Videos
            Where (dbo.Videos.VideoAssetId = dbo.VideoAssets.Id)
    ) ownedUse
    Where (dbo.VideoAssets.IsDeleted = 0)
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
    )
        And (dbo.VideoAssets.Title Like @Pattern Or dbo.VideoAssets.OriginalFileName Like @Pattern Or dbo.VideoAssets.VideoUrl Like @Pattern);

    Insert @Results (ResultType, EntityId, ParentId, Title, Subtitle, Description, Status, TargetUrl, Icon, UpdatedAt, Relevance)
    Select
        'QUESTION',
        dbo.Questions.Id,
        Null,
        Left(dbo.Questions.QuestionText, 500),
        Concat(dbo.Questions.QuestionType, N' · ', dbo.Questions.Difficulty, N' · ', dbo.Questions.DefaultScore, N' điểm'),
        Left(Coalesce(dbo.Questions.Description, dbo.Questions.Explanation, N''), 1000),
        dbo.Questions.Status,
        Concat(N'/cms/questions?edit=', dbo.Questions.Id),
        'bi-patch-question',
        Coalesce(dbo.Questions.UpdatedAt, dbo.Questions.CreatedAt),
        Case When dbo.Questions.QuestionText = @Term Then 110 When dbo.Questions.QuestionText Like @StartsWith Then 85 Else 55 End
    From dbo.Questions
    Where (dbo.Questions.IsDeleted = 0)
        And (dbo.Questions.QuestionText Like @Pattern Or dbo.Questions.Description Like @Pattern Or dbo.Questions.Explanation Like @Pattern Or dbo.Questions.QuestionType Like @Pattern Or dbo.Questions.Difficulty Like @Pattern);

    Insert @Results (ResultType, EntityId, ParentId, Title, Subtitle, Description, Status, TargetUrl, Icon, UpdatedAt, Relevance)
    Select
        'STUDENT',
        dbo.Users.Id,
        Null,
        dbo.Users.FullName,
        Concat(Coalesce(Nullif(dbo.Users.StudentCode, N''), dbo.Users.Username), N' · ', dbo.Users.Email),
        Concat(
            N'Đang tham gia ',
            (
                Select
                    Count(*)
                From dbo.Enrollments
                Where (dbo.Enrollments.StudentId = dbo.Users.Id)
                    And (dbo.Enrollments.Status <> 'CANCELLED')
    ),
            N' khóa học.'
    ),
        dbo.Users.Status,
        Concat(N'/cms/enrollments?studentId=', dbo.Users.Id),
        'bi-people',
        Coalesce(dbo.Users.UpdatedAt, dbo.Users.CreatedAt),
        Case When dbo.Users.StudentCode = @Term Or dbo.Users.Username = @Term Then 120 When dbo.Users.FullName = @Term Then 110 When dbo.Users.StudentCode Like @StartsWith Or dbo.Users.Username Like @StartsWith Then 95 When dbo.Users.FullName Like @StartsWith Then 85 Else 55 End
    From dbo.Users
    Where (dbo.Users.IsDeleted = 0)
        And (dbo.Users.StudentCode Is Not Null)
        And (dbo.Users.FullName Like @Pattern Or dbo.Users.StudentCode Like @Pattern Or dbo.Users.Username Like @Pattern Or dbo.Users.Email Like @Pattern);

    Select
        Top (@Limit) ResultType,
        EntityId,
        ParentId,
        Title,
        Subtitle,
        Description,
        Status,
        TargetUrl,
        Icon,
        UpdatedAt,
        Relevance
    From @Results
    Order By
        Relevance Desc,
        UpdatedAt Desc,
        ResultType,
        Title;

End
Go
