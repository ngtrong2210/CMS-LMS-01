Set Nocount On;

If Object_id(N'dbo.SYS_Users', N'U') Is Not Null
    And Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.SYS_Users') And name = N'UX_Users_StudentCode')
    Create Unique Index UX_Users_StudentCode On dbo.SYS_Users(StudentCode) Where StudentCode Is Not Null And IsDeleted = 0;

If Object_id(N'dbo.SYS_Users', N'U') Is Not Null
    And Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.SYS_Users') And name = N'UX_Users_TeacherCode')
    Create Unique Index UX_Users_TeacherCode On dbo.SYS_Users(TeacherCode) Where TeacherCode Is Not Null And IsDeleted = 0;

If Object_id(N'dbo.SIM_Courses', N'U') Is Not Null
    And Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.SIM_Courses') And name = N'IX_Courses_Status')
    Create Index IX_Courses_Status On dbo.SIM_Courses(Status, IsDeleted);

If Object_id(N'dbo.SIM_Courses', N'U') Is Not Null
    And Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.SIM_Courses') And name = N'IX_Courses_Teacher')
    Create Index IX_Courses_Teacher On dbo.SIM_Courses(TeacherUserID);

If Object_id(N'dbo.SIM_Chapters', N'U') Is Not Null
    And Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.SIM_Chapters') And name = N'IX_Chapters_Course_Sort')
    Create Index IX_Chapters_Course_Sort On dbo.SIM_Chapters(CourseId, SortOrder);

If Object_id(N'dbo.SIM_Lessons', N'U') Is Not Null
    And Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.SIM_Lessons') And name = N'IX_Lessons_Chapter_Sort')
    Create Index IX_Lessons_Chapter_Sort On dbo.SIM_Lessons(ChapterId, SortOrder);

If Object_id(N'dbo.SIM_Lessons', N'U') Is Not Null
    And Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.SIM_Lessons') And name = N'IX_Lessons_Course')
    Create Index IX_Lessons_Course On dbo.SIM_Lessons(CourseId, IsDeleted, IsRequired);

If Object_id(N'dbo.LMS_VideoInteractions', N'U') Is Not Null
    And Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.LMS_VideoInteractions') And name = N'IX_Interactions_Video_Time')
    Create Index IX_Interactions_Video_Time On dbo.LMS_VideoInteractions(VideoId, TimeSeconds);

If Object_id(N'dbo.SIM_VideoAssets', N'U') Is Not Null
    And Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.SIM_VideoAssets') And name = N'IX_VideoAssets_Search')
    Create Index IX_VideoAssets_Search On dbo.SIM_VideoAssets(Status, IsDeleted, CreatedAt Desc) Include(Title, DurationSeconds, VideoUrl);

If Object_id(N'dbo.SIM_VideoAssets', N'U') Is Not Null
    And Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.SIM_VideoAssets') And name = N'IX_VideoAssets_OwnerScope')
    Create Index IX_VideoAssets_OwnerScope On dbo.SIM_VideoAssets(CreatedByUserID, ShareScope, Status, IsDeleted);

If Object_id(N'dbo.SIM_VideoAssetShares', N'U') Is Not Null
    And Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.SIM_VideoAssetShares') And name = N'IX_VideoAssetShares_Teacher')
    Create Index IX_VideoAssetShares_Teacher On dbo.SIM_VideoAssetShares(TeacherUserID, VideoAssetId);

If Object_id(N'dbo.SIM_Videos', N'U') Is Not Null
    And Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.SIM_Videos') And name = N'IX_Videos_Asset')
    Create Index IX_Videos_Asset On dbo.SIM_Videos(VideoAssetId) Where VideoAssetId Is Not Null;

If Object_id(N'dbo.LMS_Enrollments', N'U') Is Not Null
    And Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.LMS_Enrollments') And name = N'IX_Enrollments_Student')
    Create Index IX_Enrollments_Student On dbo.LMS_Enrollments(StudentUserID, Status);

If Object_id(N'dbo.LMS_Enrollments', N'U') Is Not Null
    And Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.LMS_Enrollments') And name = N'IX_Enrollments_Student_Course')
    Create Index IX_Enrollments_Student_Course On dbo.LMS_Enrollments(StudentUserID, CourseId) Include(Status, ProgressPercent, FinalScore);

If Object_id(N'dbo.LMS_StudentAnswers', N'U') Is Not Null
    And Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.LMS_StudentAnswers') And name = N'IX_StudentAnswers_Question')
    Create Index IX_StudentAnswers_Question On dbo.LMS_StudentAnswers(QuestionId, StudentUserID);

If Object_id(N'dbo.LMS_StudentAnswers', N'U') Is Not Null
    And Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.LMS_StudentAnswers') And name = N'IX_StudentAnswers_Student')
    Create Index IX_StudentAnswers_Student On dbo.LMS_StudentAnswers(StudentUserID, LessonId, AnsweredAt Desc);

If Object_id(N'dbo.LMS_StudentAnswers', N'U') Is Not Null
    And Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.LMS_StudentAnswers') And name = N'IX_StudentAnswers_Interaction')
    Create Index IX_StudentAnswers_Interaction On dbo.LMS_StudentAnswers(VideoInteractionID, StudentUserID) Where VideoInteractionID Is Not Null;

If Object_id(N'dbo.LMS_LearningSessions', N'U') Is Not Null
    And Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.LMS_LearningSessions') And name = N'IX_LearningSessions_Student')
    Create Index IX_LearningSessions_Student On dbo.LMS_LearningSessions(StudentUserID, StartedAt Desc);
Go
