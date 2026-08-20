Set Nocount On;
Set Xact_abort On;

/*
    Hoàn thiện luồng môn học lớp theo năm học:
    - SIM_Courses chỉ còn là không gian nội dung của SIM_Class_Subject.
    - Bài tập hỗ trợ thời gian mở, điểm tối đa và giới hạn số lần nộp.
    - Phiên học được tổng hợp an toàn vào tiến độ và không nhân đôi giữa nhiều tab.
*/

If Col_length(N'dbo.SIM_Lessons', N'AssignmentStartAt') Is Null
    Alter Table dbo.SIM_Lessons Add AssignmentStartAt Datetime2 Null;

If Col_length(N'dbo.SIM_Lessons', N'AssignmentMaxScore') Is Null
    Alter Table dbo.SIM_Lessons Add AssignmentMaxScore Decimal(8, 2) Not Null Constraint DF_SIM_Lessons_AssignmentMaxScore Default (100);

If Col_length(N'dbo.SIM_Lessons', N'MaxSubmissionAttempts') Is Null
    Alter Table dbo.SIM_Lessons Add MaxSubmissionAttempts Int Not Null Constraint DF_SIM_Lessons_MaxSubmissionAttempts Default (3);

If Col_length(N'dbo.LMS_StudentLessonProgress', N'ActiveStudySeconds') Is Null
    Alter Table dbo.LMS_StudentLessonProgress Add ActiveStudySeconds Int Not Null Constraint DF_LMS_StudentLessonProgress_ActiveStudySeconds Default (0);

If Col_length(N'dbo.LMS_StudySessions', N'IsAggregated') Is Null
    Alter Table dbo.LMS_StudySessions Add IsAggregated Bit Not Null Constraint DF_LMS_StudySessions_IsAggregated Default (0);

-- Tách batch để SQL Server biên dịch các câu lệnh phía dưới sau khi nhận diện cột mới.
Go

Execute(N'
Create Or Alter View dbo.Lessons
As
Select
    LessonID Id,
    CourseID CourseId,
    ChapterID ChapterId,
    VideoID VideoId,
    VideoVersionID VideoVersionId,
    Title,
    Description,
    LessonType,
    DurationSeconds,
    SortOrder,
    IsRequired,
    PassingScore,
    ContentHtml,
    DocumentUrl,
    AssignmentFolderName,
    AssignmentStartAt,
    DueAt,
    AssignmentMaxScore,
    MaxSubmissionAttempts,
    MaxSubmissionFileSizeMB,
    AllowLateSubmission,
    Status,
    CreatedAt,
    UpdatedAt,
    IsDeleted
From dbo.SIM_Lessons;
');

If Object_id(N'dbo.LMS_AssignmentSubmissionFiles', N'U') Is Null
Begin
    Create Table dbo.LMS_AssignmentSubmissionFiles
    (
        AssignmentSubmissionFileID Bigint Identity(1, 1) Not Null,
        AssignmentSubmissionID Bigint Not Null,
        OriginalFileName Nvarchar(500) Not Null,
        StoredFileName Nvarchar(500) Not Null,
        FileUrl Nvarchar(1000) Not Null,
        FileSize Bigint Not Null,
        MimeType Nvarchar(150) Not Null,
        CreatedAt Datetime2 Not Null Constraint DF_LMS_AssignmentSubmissionFiles_CreatedAt Default (Sysutcdatetime()),
        Constraint PK_LMS_AssignmentSubmissionFiles Primary Key (AssignmentSubmissionFileID),
        Constraint FK_LMS_AssignmentSubmissionFiles_Submission Foreign Key (AssignmentSubmissionID) References dbo.LMS_AssignmentSubmissions(AssignmentSubmissionID)
    );

    Create Index IX_LMS_AssignmentSubmissionFiles_SubmissionID On dbo.LMS_AssignmentSubmissionFiles(AssignmentSubmissionID, CreatedAt);
End;

Insert dbo.LMS_AssignmentSubmissionFiles
(
    AssignmentSubmissionID,
    OriginalFileName,
    StoredFileName,
    FileUrl,
    FileSize,
    MimeType,
    CreatedAt
)
Select
    dbo.LMS_AssignmentSubmissions.AssignmentSubmissionID,
    dbo.LMS_AssignmentSubmissions.OriginalFileName,
    dbo.LMS_AssignmentSubmissions.StoredFileName,
    dbo.LMS_AssignmentSubmissions.FileUrl,
    Coalesce(dbo.LMS_AssignmentSubmissions.FileSize, 0),
    Coalesce(dbo.LMS_AssignmentSubmissions.MimeType, N'application/octet-stream'),
    dbo.LMS_AssignmentSubmissions.SubmittedAt
From dbo.LMS_AssignmentSubmissions
Where (dbo.LMS_AssignmentSubmissions.FileUrl Is Not Null)
    And Not Exists
    (
        Select 1
        From dbo.LMS_AssignmentSubmissionFiles
        Where (dbo.LMS_AssignmentSubmissionFiles.AssignmentSubmissionID = dbo.LMS_AssignmentSubmissions.AssignmentSubmissionID)
            And (dbo.LMS_AssignmentSubmissionFiles.FileUrl = dbo.LMS_AssignmentSubmissions.FileUrl)
    );

If Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.LMS_AssignmentSubmissions') And name = N'IX_LMS_AssignmentSubmissions_TeacherQueue')
    Create Index IX_LMS_AssignmentSubmissions_TeacherQueue On dbo.LMS_AssignmentSubmissions(CourseID, LessonID, SubmissionStatus, SubmittedAt Desc) Include (StudentUserID, Score, IsLate);

If Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.LMS_StudySessions') And name = N'IX_LMS_StudySessions_ActiveLesson')
    Create Index IX_LMS_StudySessions_ActiveLesson On dbo.LMS_StudySessions(StudentUserID, LessonID, LastHeartbeatAt Desc) Include (EndedAt, ActiveDurationSeconds, IsAggregated);

Declare @Descriptions Table
(
    TableName Sysname,
    ColumnName Sysname,
    DescriptionValue Nvarchar(1000)
);

Insert @Descriptions(TableName, ColumnName, DescriptionValue)
Values
    (N'SIM_Lessons', N'AssignmentStartAt', N'Thời điểm học viên bắt đầu được nộp bài tập.'),
    (N'SIM_Lessons', N'AssignmentMaxScore', N'Điểm tối đa giáo viên có thể chấm cho bài tập.'),
    (N'SIM_Lessons', N'MaxSubmissionAttempts', N'Số lần nộp tối đa được phép cho bài tập.'),
    (N'LMS_StudentLessonProgress', N'ActiveStudySeconds', N'Tổng số giây học hợp lệ được backend tổng hợp từ các phiên heartbeat.'),
    (N'LMS_StudySessions', N'IsAggregated', N'Cờ cho biết thời lượng phiên đã được cộng vào tiến độ bài học.'),
    (N'LMS_AssignmentSubmissionFiles', N'AssignmentSubmissionFileID', N'Khóa chính của file thuộc một lần nộp bài.'),
    (N'LMS_AssignmentSubmissionFiles', N'AssignmentSubmissionID', N'ID lần nộp bài sở hữu file.'),
    (N'LMS_AssignmentSubmissionFiles', N'OriginalFileName', N'Tên file gốc do học viên tải lên.'),
    (N'LMS_AssignmentSubmissionFiles', N'StoredFileName', N'Tên file GUID được lưu vật lý.'),
    (N'LMS_AssignmentSubmissionFiles', N'FileUrl', N'Đường dẫn tương đối an toàn trong thư mục Media/File.'),
    (N'LMS_AssignmentSubmissionFiles', N'FileSize', N'Kích thước file tính theo byte.'),
    (N'LMS_AssignmentSubmissionFiles', N'MimeType', N'Kiểu nội dung MIME đã được máy chủ kiểm tra.'),
    (N'LMS_AssignmentSubmissionFiles', N'CreatedAt', N'Thời điểm metadata file được tạo theo UTC.');

Declare @TableName Sysname;
Declare @ColumnName Sysname;
Declare @DescriptionValue Nvarchar(1000);

Declare DescriptionCursor Cursor Local Fast_forward For
    Select TableName, ColumnName, DescriptionValue From @Descriptions;

Open DescriptionCursor;
Fetch Next From DescriptionCursor Into @TableName, @ColumnName, @DescriptionValue;

While @@Fetch_status = 0
Begin
    If Exists
    (
        Select 1
        From sys.extended_properties
        Where (class = 1)
            And (major_id = Object_id(N'dbo.' + @TableName))
            And (minor_id = Columnproperty(Object_id(N'dbo.' + @TableName), @ColumnName, 'ColumnId'))
            And (name = N'MS_Description')
    )
        Execute sys.sp_updateextendedproperty
            @name = N'MS_Description', @value = @DescriptionValue,
            @level0type = N'SCHEMA', @level0name = N'dbo',
            @level1type = N'TABLE', @level1name = @TableName,
            @level2type = N'COLUMN', @level2name = @ColumnName;
    Else
        Execute sys.sp_addextendedproperty
            @name = N'MS_Description', @value = @DescriptionValue,
            @level0type = N'SCHEMA', @level0name = N'dbo',
            @level1type = N'TABLE', @level1name = @TableName,
            @level2type = N'COLUMN', @level2name = @ColumnName;

    Fetch Next From DescriptionCursor Into @TableName, @ColumnName, @DescriptionValue;
End;

Close DescriptionCursor;
Deallocate DescriptionCursor;

If Not Exists
(
    Select 1
    From sys.extended_properties
    Where (class = 1)
        And (major_id = Object_id(N'dbo.LMS_AssignmentSubmissionFiles'))
        And (minor_id = 0)
        And (name = N'MS_Description')
)
    Execute sys.sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'[LMS] Danh sách file đính kèm của từng lần nộp bài, tách khỏi metadata bài nộp.',
        @level0type = N'SCHEMA', @level0name = N'dbo',
        @level1type = N'TABLE', @level1name = N'LMS_AssignmentSubmissionFiles';
Go
