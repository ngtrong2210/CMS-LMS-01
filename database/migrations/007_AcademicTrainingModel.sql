Set Nocount On;
Set Xact_abort On;

/*
    Mô hình đào tạo dùng chung với dữ liệu quản lý sinh viên:
    năm học -> khoa -> khóa tuyển sinh -> lớp -> môn học lớp.

    SIM_Courses (số nhiều) tiếp tục là không gian học trực tuyến hiện có.
    SIM_Course (số ít) là khóa tuyển sinh K18, K19... theo schema nguồn.
*/

If Object_id(N'dbo.SIM_Year', N'U') Is Null
Begin
    Create Table dbo.SIM_Year
    (
        DataGroupID Int Not Null Constraint DF_SIM_Year_DataGroupID Default (1),
        YearID Int Not Null,
        YearName Nvarchar(50) Not Null,
        StartAt Datetime2 Null,
        FinishAt Datetime2 Null,
        IsActived Bit Not Null Constraint DF_SIM_Year_IsActived Default (1),
        Constraint PK_SIM_Year Primary Key (DataGroupID, YearID)
    );
End;

If Object_id(N'dbo.SIM_Science', N'U') Is Null
Begin
    Create Table dbo.SIM_Science
    (
        DataGroupID Int Not Null Constraint DF_SIM_Science_DataGroupID Default (1),
        ScienceID Nvarchar(50) Not Null,
        ScienceName Nvarchar(500) Not Null,
        ScienceShortName Nvarchar(100) Null,
        IsActived Bit Not Null Constraint DF_SIM_Science_IsActived Default (1),
        Constraint PK_SIM_Science Primary Key (DataGroupID, ScienceID)
    );
End;

If Object_id(N'dbo.SIM_Course', N'U') Is Null
Begin
    Create Table dbo.SIM_Course
    (
        DataGroupID Int Not Null Constraint DF_SIM_Course_DataGroupID Default (1),
        CourseID Nvarchar(50) Not Null,
        CourseName Nvarchar(500) Not Null,
        StartYear Int Not Null,
        FinishYear Int Not Null,
        IsActived Bit Not Null Constraint DF_SIM_Course_IsActived Default (1),
        Constraint PK_SIM_Course Primary Key (DataGroupID, CourseID)
    );
End;

If Object_id(N'dbo.SIM_Subject', N'U') Is Null
Begin
    Create Table dbo.SIM_Subject
    (
        DataGroupID Int Not Null Constraint DF_SIM_Subject_DataGroupID Default (1),
        SubjectID Nvarchar(50) Not Null,
        SubjectName Nvarchar(500) Not Null,
        SubjectShortName Nvarchar(100) Not Null,
        ScienceID Nvarchar(50) Null,
        SubjectGroupID Nvarchar(50) Null,
        TheoryQuantity Int Not Null Constraint DF_SIM_Subject_TheoryQuantity Default (0),
        PracticeQuantity Int Not Null Constraint DF_SIM_Subject_PracticeQuantity Default (0),
        TestQuantity Int Not Null Constraint DF_SIM_Subject_TestQuantity Default (0),
        CreditCount Tinyint Not Null Constraint DF_SIM_Subject_CreditCount Default (0),
        IsActived Bit Not Null Constraint DF_SIM_Subject_IsActived Default (1),
        Constraint PK_SIM_Subject Primary Key (DataGroupID, SubjectID),
        Constraint FK_SIM_Subject_SIM_Science Foreign Key (DataGroupID, ScienceID) References dbo.SIM_Science(DataGroupID, ScienceID)
    );
End;

If Object_id(N'dbo.SIM_Teacher', N'U') Is Null
Begin
    Create Table dbo.SIM_Teacher
    (
        DataGroupID Int Not Null Constraint DF_SIM_Teacher_DataGroupID Default (1),
        TeacherID Nvarchar(50) Not Null,
        UserID Bigint Null,
        TeacherFirstName Nvarchar(100) Not Null,
        TeacherLastName Nvarchar(100) Not Null,
        TeacherShortName Nvarchar(100) Null,
        ScienceID Nvarchar(50) Null,
        SubjectGroupID Nvarchar(50) Null,
        Email Nvarchar(100) Null,
        IsActived Bit Not Null Constraint DF_SIM_Teacher_IsActived Default (1),
        Constraint PK_SIM_Teacher Primary Key (DataGroupID, TeacherID),
        Constraint FK_SIM_Teacher_SYS_Users Foreign Key (UserID) References dbo.SYS_Users(UserID),
        Constraint FK_SIM_Teacher_SIM_Science Foreign Key (DataGroupID, ScienceID) References dbo.SIM_Science(DataGroupID, ScienceID)
    );

    Create Unique Index UX_SIM_Teacher_UserID On dbo.SIM_Teacher(UserID) Where UserID Is Not Null;
End;

If Object_id(N'dbo.SIM_Class', N'U') Is Null
Begin
    Create Table dbo.SIM_Class
    (
        DataGroupID Int Not Null Constraint DF_SIM_Class_DataGroupID Default (1),
        ClassID Nvarchar(50) Not Null,
        ClassName Nvarchar(500) Not Null,
        ClassShortName Nvarchar(100) Null,
        ScienceID Nvarchar(50) Null,
        CourseID Nvarchar(50) Null,
        TrainingLevelID Nvarchar(50) Null,
        TrainingType Nvarchar(50) Null,
        ClassSize Int Not Null Constraint DF_SIM_Class_ClassSize Default (0),
        StartAt Datetime2 Null,
        FinishAt Datetime2 Null,
        ManagerTeacherID Nvarchar(50) Null,
        IsActived Bit Not Null Constraint DF_SIM_Class_IsActived Default (1),
        Description Nvarchar(500) Null,
        Constraint PK_SIM_Class Primary Key (DataGroupID, ClassID),
        Constraint FK_SIM_Class_SIM_Science Foreign Key (DataGroupID, ScienceID) References dbo.SIM_Science(DataGroupID, ScienceID),
        Constraint FK_SIM_Class_SIM_Course Foreign Key (DataGroupID, CourseID) References dbo.SIM_Course(DataGroupID, CourseID),
        Constraint FK_SIM_Class_SIM_Teacher Foreign Key (DataGroupID, ManagerTeacherID) References dbo.SIM_Teacher(DataGroupID, TeacherID)
    );
End;

If Object_id(N'dbo.SIM_Student', N'U') Is Null
Begin
    Create Table dbo.SIM_Student
    (
        DataGroupID Int Not Null Constraint DF_SIM_Student_DataGroupID Default (1),
        StudentID Nvarchar(50) Not Null,
        UserID Bigint Null,
        ClassID Nvarchar(50) Not Null,
        StudentFirstName Nvarchar(100) Not Null,
        StudentLastName Nvarchar(100) Not Null,
        FullName Nvarchar(250) Not Null,
        Gender Bit Null,
        BirthDate Date Null,
        Email Nvarchar(100) Null,
        Mobile Varchar(50) Null,
        Address Nvarchar(1000) Null,
        IsActived Bit Not Null Constraint DF_SIM_Student_IsActived Default (1),
        CreatedDate Datetime2 Not Null Constraint DF_SIM_Student_CreatedDate Default (Sysutcdatetime()),
        UpdatedDate Datetime2 Null,
        Constraint PK_SIM_Student Primary Key (DataGroupID, StudentID),
        Constraint FK_SIM_Student_SYS_Users Foreign Key (UserID) References dbo.SYS_Users(UserID),
        Constraint FK_SIM_Student_SIM_Class Foreign Key (DataGroupID, ClassID) References dbo.SIM_Class(DataGroupID, ClassID)
    );

    Create Unique Index UX_SIM_Student_UserID On dbo.SIM_Student(UserID) Where UserID Is Not Null;
    Create Index IX_SIM_Student_ClassID On dbo.SIM_Student(DataGroupID, ClassID, IsActived);
End;

If Object_id(N'dbo.SIM_Class_Subject', N'U') Is Null
Begin
    Create Table dbo.SIM_Class_Subject
    (
        DataGroupID Int Not Null Constraint DF_SIM_Class_Subject_DataGroupID Default (1),
        ClassSubjectID Bigint Not Null,
        Semester Tinyint Not Null,
        YearID Int Not Null,
        ClassID Nvarchar(50) Not Null,
        SubjectID Nvarchar(50) Not Null,
        TeacherID Nvarchar(50) Null,
        TheoryQuantity Int Not Null Constraint DF_SIM_Class_Subject_TheoryQuantity Default (0),
        PracticeQuantity Int Not Null Constraint DF_SIM_Class_Subject_PracticeQuantity Default (0),
        TestQuantity Int Not Null Constraint DF_SIM_Class_Subject_TestQuantity Default (0),
        CreditCount Tinyint Not Null Constraint DF_SIM_Class_Subject_CreditCount Default (0),
        ClassSubjectStatus Tinyint Not Null Constraint DF_SIM_Class_Subject_Status Default (1),
        OrderIndex Bigint Not Null Constraint DF_SIM_Class_Subject_OrderIndex Default (0),
        IsLocked Bit Not Null Constraint DF_SIM_Class_Subject_IsLocked Default (0),
        CreatedDate Datetime2 Not Null Constraint DF_SIM_Class_Subject_CreatedDate Default (Sysutcdatetime()),
        CreatedUser Nvarchar(50) Not Null Constraint DF_SIM_Class_Subject_CreatedUser Default (N'SYSTEM'),
        UpdatedDate Datetime2 Null,
        UpdatedUser Nvarchar(50) Null,
        MeetingLink Varchar(500) Null,
        MeetingCode Varchar(100) Null,
        Constraint PK_SIM_Class_Subject Primary Key (DataGroupID, ClassSubjectID),
        Constraint UQ_SIM_Class_Subject Unique (DataGroupID, YearID, Semester, ClassID, SubjectID),
        Constraint FK_SIM_Class_Subject_SIM_Year Foreign Key (DataGroupID, YearID) References dbo.SIM_Year(DataGroupID, YearID),
        Constraint FK_SIM_Class_Subject_SIM_Class Foreign Key (DataGroupID, ClassID) References dbo.SIM_Class(DataGroupID, ClassID),
        Constraint FK_SIM_Class_Subject_SIM_Subject Foreign Key (DataGroupID, SubjectID) References dbo.SIM_Subject(DataGroupID, SubjectID),
        Constraint FK_SIM_Class_Subject_SIM_Teacher Foreign Key (DataGroupID, TeacherID) References dbo.SIM_Teacher(DataGroupID, TeacherID)
    );
End;

If Object_id(N'dbo.SIM_Timetable', N'U') Is Null
Begin
    Create Table dbo.SIM_Timetable
    (
        TimetableID Bigint Identity(1, 1) Not Null,
        DataGroupID Int Not Null Constraint DF_SIM_Timetable_DataGroupID Default (1),
        ClassSubjectID Bigint Not Null,
        DayOfWeek Tinyint Not Null,
        StartPeriod Tinyint Null,
        EndPeriod Tinyint Null,
        StartTime Time(0) Null,
        EndTime Time(0) Null,
        RoomName Nvarchar(100) Null,
        EffectiveFrom Date Null,
        EffectiveTo Date Null,
        TimetableStatus Tinyint Not Null Constraint DF_SIM_Timetable_Status Default (1),
        CreatedDate Datetime2 Not Null Constraint DF_SIM_Timetable_CreatedDate Default (Sysutcdatetime()),
        UpdatedDate Datetime2 Null,
        Constraint PK_SIM_Timetable Primary Key (TimetableID),
        Constraint FK_SIM_Timetable_SIM_Class_Subject Foreign Key (DataGroupID, ClassSubjectID) References dbo.SIM_Class_Subject(DataGroupID, ClassSubjectID),
        Constraint CK_SIM_Timetable_DayOfWeek Check (DayOfWeek Between 2 And 8),
        Constraint CK_SIM_Timetable_Period Check (StartPeriod Is Null Or EndPeriod Is Null Or EndPeriod >= StartPeriod),
        Constraint CK_SIM_Timetable_Time Check (StartTime Is Null Or EndTime Is Null Or EndTime > StartTime)
    );

    Create Index IX_SIM_Timetable_ClassSubjectID On dbo.SIM_Timetable(DataGroupID, ClassSubjectID, DayOfWeek, StartTime) Where TimetableStatus = 1;
End;

If Object_id(N'dbo.SYS_PermissionCategory', N'U') Is Null
Begin
    Create Table dbo.SYS_PermissionCategory
    (
        PermissionCategoryID Int Not Null,
        PermissionCategoryName Nvarchar(100) Not Null,
        IsDefault Bit Not Null Constraint DF_SYS_PermissionCategory_IsDefault Default (0),
        IsActived Bit Not Null Constraint DF_SYS_PermissionCategory_IsActived Default (1),
        SortOrder Int Not Null Constraint DF_SYS_PermissionCategory_SortOrder Default (0),
        Constraint PK_SYS_PermissionCategory Primary Key (PermissionCategoryID)
    );
End;

If Object_id(N'dbo.SYS_PermissionGroup', N'U') Is Null
Begin
    Create Table dbo.SYS_PermissionGroup
    (
        PermissionGroupID Nvarchar(50) Not Null,
        PermissionGroupName Nvarchar(100) Not Null,
        PermissionCategoryID Int Not Null,
        SortOrder Int Not Null Constraint DF_SYS_PermissionGroup_SortOrder Default (0),
        IsActived Bit Not Null Constraint DF_SYS_PermissionGroup_IsActived Default (1),
        Constraint PK_SYS_PermissionGroup Primary Key (PermissionGroupID),
        Constraint FK_SYS_PermissionGroup_SYS_PermissionCategory Foreign Key (PermissionCategoryID) References dbo.SYS_PermissionCategory(PermissionCategoryID)
    );
End;

If Col_length(N'dbo.SYS_Users', N'DataGroupID') Is Null
    Alter Table dbo.SYS_Users Add DataGroupID Int Not Null Constraint DF_SYS_Users_DataGroupID Default (1);
If Col_length(N'dbo.SYS_Users', N'StudentID') Is Null
    Alter Table dbo.SYS_Users Add StudentID Nvarchar(50) Null;
If Col_length(N'dbo.SYS_Users', N'TeacherID') Is Null
    Alter Table dbo.SYS_Users Add TeacherID Nvarchar(50) Null;
If Col_length(N'dbo.SYS_Permissions', N'PermissionCategoryID') Is Null
    Alter Table dbo.SYS_Permissions Add PermissionCategoryID Int Null;
If Col_length(N'dbo.SYS_Permissions', N'PermissionGroupID') Is Null
    Alter Table dbo.SYS_Permissions Add PermissionGroupID Nvarchar(50) Null;

If Col_length(N'dbo.SIM_Courses', N'DataGroupID') Is Null
    Alter Table dbo.SIM_Courses Add DataGroupID Int Not Null Constraint DF_SIM_Courses_DataGroupID Default (1);
If Col_length(N'dbo.SIM_Courses', N'ClassSubjectID') Is Null
    Alter Table dbo.SIM_Courses Add ClassSubjectID Bigint Null;

If Not Exists (Select 1 From sys.foreign_keys Where name = N'FK_SIM_Courses_SIM_Class_Subject')
    Alter Table dbo.SIM_Courses Add Constraint FK_SIM_Courses_SIM_Class_Subject Foreign Key (DataGroupID, ClassSubjectID) References dbo.SIM_Class_Subject(DataGroupID, ClassSubjectID);

;With DuplicateOnlineCourse As
(
    Select
        dbo.SIM_Courses.CourseID,
        Row_number() Over
        (
            Partition By dbo.SIM_Courses.DataGroupID, dbo.SIM_Courses.ClassSubjectID
            Order By dbo.SIM_Courses.CourseID
        ) DuplicateOrder
    From dbo.SIM_Courses
    Where (dbo.SIM_Courses.ClassSubjectID Is Not Null)
        And (dbo.SIM_Courses.IsDeleted = 0)
)
Update dbo.SIM_Courses
Set
    ClassSubjectID = Null
From dbo.SIM_Courses
    Inner Join DuplicateOnlineCourse On DuplicateOnlineCourse.CourseID = dbo.SIM_Courses.CourseID
Where (DuplicateOnlineCourse.DuplicateOrder > 1);

If Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.SIM_Courses') And name = N'UX_SIM_Courses_ClassSubjectID')
    Create Unique Index UX_SIM_Courses_ClassSubjectID On dbo.SIM_Courses(DataGroupID, ClassSubjectID) Where ClassSubjectID Is Not Null And IsDeleted = 0;

If Col_length(N'dbo.SIM_Lessons', N'ContentHtml') Is Null
    Alter Table dbo.SIM_Lessons Add ContentHtml Nvarchar(Max) Null;
If Col_length(N'dbo.SIM_Lessons', N'DocumentUrl') Is Null
    Alter Table dbo.SIM_Lessons Add DocumentUrl Nvarchar(1000) Null;
If Col_length(N'dbo.SIM_Lessons', N'AssignmentFolderName') Is Null
    Alter Table dbo.SIM_Lessons Add AssignmentFolderName Nvarchar(250) Null;
If Col_length(N'dbo.SIM_Lessons', N'DueAt') Is Null
    Alter Table dbo.SIM_Lessons Add DueAt Datetime2 Null;
If Col_length(N'dbo.SIM_Lessons', N'MaxSubmissionFileSizeMB') Is Null
    Alter Table dbo.SIM_Lessons Add MaxSubmissionFileSizeMB Int Not Null Constraint DF_SIM_Lessons_MaxSubmissionFileSizeMB Default (50);
If Col_length(N'dbo.SIM_Lessons', N'AllowLateSubmission') Is Null
    Alter Table dbo.SIM_Lessons Add AllowLateSubmission Bit Not Null Constraint DF_SIM_Lessons_AllowLateSubmission Default (0);

Declare @LessonTypeConstraint Sysname;
Select
    @LessonTypeConstraint = sys.check_constraints.name
From sys.check_constraints
Where (sys.check_constraints.parent_object_id = Object_id(N'dbo.SIM_Lessons'))
    And (Object_definition(sys.check_constraints.object_id) Like N'%LessonType%');

If @LessonTypeConstraint Is Not Null
Begin
    Declare @DropLessonTypeConstraint Nvarchar(Max) = N'Alter Table dbo.SIM_Lessons Drop Constraint ' + Quotename(@LessonTypeConstraint) + N';';
    Execute sys.sp_executesql @DropLessonTypeConstraint;
End;

If Not Exists (Select 1 From sys.check_constraints Where name = N'CK_SIM_Lessons_LessonType')
    Alter Table dbo.SIM_Lessons Add Constraint CK_SIM_Lessons_LessonType Check (LessonType In ('VIDEO', 'INTERACTIVE_VIDEO', 'QUIZ', 'DOCUMENT', 'EDITOR', 'ASSIGNMENT'));

If Object_id(N'dbo.SIM_LessonResources', N'U') Is Null
Begin
    Create Table dbo.SIM_LessonResources
    (
        LessonResourceID Bigint Identity(1, 1) Not Null,
        LessonID Bigint Not Null,
        ResourceType Varchar(30) Not Null,
        ResourceName Nvarchar(500) Not Null,
        ResourceUrl Nvarchar(1000) Not Null,
        OriginalFileName Nvarchar(500) Null,
        FileSize Bigint Null,
        MimeType Nvarchar(150) Null,
        SortOrder Int Not Null Constraint DF_SIM_LessonResources_SortOrder Default (1),
        CreatedByUserID Bigint Not Null,
        CreatedAt Datetime2 Not Null Constraint DF_SIM_LessonResources_CreatedAt Default (Sysutcdatetime()),
        IsDeleted Bit Not Null Constraint DF_SIM_LessonResources_IsDeleted Default (0),
        Constraint PK_SIM_LessonResources Primary Key (LessonResourceID),
        Constraint FK_SIM_LessonResources_SIM_Lessons Foreign Key (LessonID) References dbo.SIM_Lessons(LessonID),
        Constraint FK_SIM_LessonResources_SYS_Users Foreign Key (CreatedByUserID) References dbo.SYS_Users(UserID),
        Constraint CK_SIM_LessonResources_ResourceType Check (ResourceType In ('DOCUMENT', 'ATTACHMENT', 'LINK'))
    );

    Create Index IX_SIM_LessonResources_LessonID On dbo.SIM_LessonResources(LessonID, SortOrder) Where IsDeleted = 0;
End;

If Object_id(N'dbo.LMS_AssignmentSubmissions', N'U') Is Null
Begin
    Create Table dbo.LMS_AssignmentSubmissions
    (
        AssignmentSubmissionID Bigint Identity(1, 1) Not Null,
        LessonID Bigint Not Null,
        CourseID Bigint Not Null,
        StudentUserID Bigint Not Null,
        AttemptNumber Int Not Null Constraint DF_LMS_AssignmentSubmissions_AttemptNumber Default (1),
        SubmissionText Nvarchar(Max) Null,
        FileUrl Nvarchar(1000) Null,
        OriginalFileName Nvarchar(500) Null,
        StoredFileName Nvarchar(500) Null,
        FileSize Bigint Null,
        MimeType Nvarchar(150) Null,
        SubmittedAt Datetime2 Not Null Constraint DF_LMS_AssignmentSubmissions_SubmittedAt Default (Sysutcdatetime()),
        SubmissionStatus Varchar(30) Not Null Constraint DF_LMS_AssignmentSubmissions_Status Default ('SUBMITTED'),
        Score Decimal(8, 2) Null,
        Feedback Nvarchar(Max) Null,
        GradedByUserID Bigint Null,
        GradedAt Datetime2 Null,
        IsLate Bit Not Null Constraint DF_LMS_AssignmentSubmissions_IsLate Default (0),
        Constraint PK_LMS_AssignmentSubmissions Primary Key (AssignmentSubmissionID),
        Constraint UQ_LMS_AssignmentSubmissions_Attempt Unique (LessonID, StudentUserID, AttemptNumber),
        Constraint FK_LMS_AssignmentSubmissions_SIM_Lessons Foreign Key (LessonID) References dbo.SIM_Lessons(LessonID),
        Constraint FK_LMS_AssignmentSubmissions_SIM_Courses Foreign Key (CourseID) References dbo.SIM_Courses(CourseID),
        Constraint FK_LMS_AssignmentSubmissions_Student Foreign Key (StudentUserID) References dbo.SYS_Users(UserID),
        Constraint FK_LMS_AssignmentSubmissions_Grader Foreign Key (GradedByUserID) References dbo.SYS_Users(UserID),
        Constraint CK_LMS_AssignmentSubmissions_Status Check (SubmissionStatus In ('DRAFT', 'SUBMITTED', 'GRADED', 'RETURNED'))
    );

    Create Index IX_LMS_AssignmentSubmissions_Student On dbo.LMS_AssignmentSubmissions(StudentUserID, CourseID, LessonID, SubmittedAt Desc);
End;

If Object_id(N'dbo.LMS_StudySessions', N'U') Is Null
Begin
    Create Table dbo.LMS_StudySessions
    (
        StudySessionID Uniqueidentifier Not Null Constraint DF_LMS_StudySessions_StudySessionID Default (Newid()),
        StudentUserID Bigint Not Null,
        ClassSubjectID Bigint Null,
        CourseID Bigint Null,
        ChapterID Bigint Null,
        LessonID Bigint Null,
        StartedAt Datetime2 Not Null Constraint DF_LMS_StudySessions_StartedAt Default (Sysutcdatetime()),
        LastHeartbeatAt Datetime2 Not Null Constraint DF_LMS_StudySessions_LastHeartbeatAt Default (Sysutcdatetime()),
        EndedAt Datetime2 Null,
        ActiveDurationSeconds Int Not Null Constraint DF_LMS_StudySessions_ActiveDurationSeconds Default (0),
        PageUrl Nvarchar(1000) Null,
        ClientSessionKey Nvarchar(100) Null,
        IsCompleted Bit Not Null Constraint DF_LMS_StudySessions_IsCompleted Default (0),
        Constraint PK_LMS_StudySessions Primary Key (StudySessionID),
        Constraint FK_LMS_StudySessions_SYS_Users Foreign Key (StudentUserID) References dbo.SYS_Users(UserID),
        Constraint FK_LMS_StudySessions_SIM_Courses Foreign Key (CourseID) References dbo.SIM_Courses(CourseID),
        Constraint FK_LMS_StudySessions_SIM_Chapters Foreign Key (ChapterID) References dbo.SIM_Chapters(ChapterID),
        Constraint FK_LMS_StudySessions_SIM_Lessons Foreign Key (LessonID) References dbo.SIM_Lessons(LessonID)
    );

    Create Index IX_LMS_StudySessions_Student On dbo.LMS_StudySessions(StudentUserID, StartedAt Desc);
    Create Index IX_LMS_StudySessions_LearningContext On dbo.LMS_StudySessions(CourseID, ChapterID, LessonID, StartedAt Desc);
End;

Execute(N'
Create Or Alter View dbo.Courses
As
Select
    CourseID Id,
    Code,
    Title,
    Slug,
    ThumbnailUrl,
    ShortDescription,
    Description,
    TeacherUserID TeacherId,
    CourseCategoryID CategoryId,
    DataGroupID,
    ClassSubjectID,
    Level,
    PassingScore,
    Status,
    PublishedAt,
    CreatedAt,
    UpdatedAt,
    CreatedByUserID CreatedBy,
    UpdatedByUserID UpdatedBy,
    IsDeleted
From dbo.SIM_Courses;
');

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
    DueAt,
    MaxSubmissionFileSizeMB,
    AllowLateSubmission,
    Status,
    CreatedAt,
    UpdatedAt,
    IsDeleted
From dbo.SIM_Lessons;
');

Declare @Description Table
(
    ObjectName Sysname Not Null,
    ColumnName Sysname Null,
    DescriptionText Nvarchar(1000) Not Null
);

Insert Into @Description(ObjectName, ColumnName, DescriptionText)
Values
    (N'SIM_Year', Null, N'[SIM] Danh mục năm học dùng để mở môn học lớp theo từng học kỳ.'),
    (N'SIM_Year', N'DataGroupID', N'Mã đơn vị hoặc nhóm dữ liệu sở hữu năm học.'),
    (N'SIM_Year', N'YearID', N'Mã năm học, ví dụ 2025 cho năm học 2025-2026.'),
    (N'SIM_Year', N'YearName', N'Tên hiển thị của năm học, ví dụ 2025-2026.'),
    (N'SIM_Year', N'StartAt', N'Ngày bắt đầu năm học.'),
    (N'SIM_Year', N'FinishAt', N'Ngày kết thúc năm học.'),
    (N'SIM_Year', N'IsActived', N'Cho biết năm học còn được sử dụng hay không.'),
    (N'SIM_Science', Null, N'[SIM] Danh mục khoa chuyên môn, ví dụ Khoa Công nghệ thông tin.'),
    (N'SIM_Course', Null, N'[SIM] Danh mục khóa tuyển sinh, ví dụ K18; không phải không gian học trực tuyến.'),
    (N'SIM_Subject', Null, N'[SIM] Danh mục môn học thuộc chương trình đào tạo.'),
    (N'SIM_Teacher', Null, N'[SIM] Hồ sơ nghiệp vụ giảng viên gắn với tài khoản SYS_Users.'),
    (N'SIM_Class', Null, N'[SIM] Lớp hành chính thuộc khoa và khóa tuyển sinh.'),
    (N'SIM_Student', Null, N'[SIM] Hồ sơ cá nhân học viên và lớp hành chính đang theo học.'),
    (N'SIM_Class_Subject', Null, N'[SIM] Môn học được mở cho một lớp trong năm học và học kỳ cụ thể.'),
    (N'SIM_Timetable', Null, N'[SIM] Thời khóa biểu học theo từng môn học lớp và khoảng thời gian hiệu lực.'),
    (N'SYS_PermissionCategory', Null, N'[SYS] Danh mục cấp cao dùng phân loại quyền hệ thống.'),
    (N'SYS_PermissionGroup', Null, N'[SYS] Nhóm quyền nghiệp vụ nằm trong một danh mục quyền.'),
    (N'SIM_LessonResources', Null, N'[SIM] Các file, tài liệu hoặc liên kết đính kèm cho bài học.'),
    (N'LMS_AssignmentSubmissions', Null, N'[LMS] Bài làm học viên nộp cho bài tập, gồm file, nội dung và kết quả chấm.'),
    (N'LMS_StudySessions', Null, N'[LMS] Phiên đo thời gian học viên ở lại môn học, chương hoặc bài học.'),
    (N'SIM_Courses', N'ClassSubjectID', N'Mã môn học lớp được liên kết với không gian học trực tuyến này.'),
    (N'SIM_Courses', N'DataGroupID', N'Mã đơn vị sở hữu không gian học trực tuyến.'),
    (N'SIM_Lessons', N'ContentHtml', N'Nội dung bài học được giảng viên soạn bằng trình biên tập.'),
    (N'SIM_Lessons', N'DocumentUrl', N'Đường dẫn tài liệu chính của bài học trong /Media/File/.'),
    (N'SIM_Lessons', N'AssignmentFolderName', N'Tên thư mục bài tập dùng tổ chức file nộp của học viên.'),
    (N'SIM_Lessons', N'DueAt', N'Hạn cuối nộp bài tập.'),
    (N'SIM_Lessons', N'MaxSubmissionFileSizeMB', N'Dung lượng tối đa tính bằng MB cho mỗi file bài nộp.'),
    (N'SIM_Lessons', N'AllowLateSubmission', N'Cho phép học viên nộp bài sau hạn hay không.'),
    (N'LMS_StudySessions', N'ActiveDurationSeconds', N'Tổng số giây hoạt động hợp lệ, được cộng qua mỗi heartbeat.'),
    (N'LMS_StudySessions', N'LastHeartbeatAt', N'Thời điểm gần nhất trình duyệt xác nhận học viên vẫn đang ở trang học.'),
    (N'LMS_AssignmentSubmissions', N'FileUrl', N'Đường dẫn tương đối tới file học viên nộp trong /Media/File/Assignments/.'),
    (N'LMS_AssignmentSubmissions', N'SubmissionStatus', N'Trạng thái bài nộp: nháp, đã nộp, đã chấm hoặc trả lại.'),
    (N'LMS_AssignmentSubmissions', N'IsLate', N'Cho biết bài được nộp sau hạn cuối hay không.');

Declare @ObjectName Sysname;
Declare @ColumnName Sysname;
Declare @DescriptionText Nvarchar(1000);
Declare description_cursor Cursor Local Fast_forward For
    Select
        ObjectName,
        ColumnName,
        DescriptionText
    From @Description;

Open description_cursor;
Fetch Next From description_cursor Into @ObjectName, @ColumnName, @DescriptionText;
While @@Fetch_status = 0
Begin
    If @ColumnName Is Null
    Begin
        If Exists
        (
            Select 1
            From sys.extended_properties
            Where (class = 1)
                And (major_id = Object_id(N'dbo.' + @ObjectName))
                And (minor_id = 0)
                And (name = N'MS_Description')
        )
            Execute sys.sp_updateextendedproperty @name=N'MS_Description', @value=@DescriptionText,
                @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=@ObjectName;
        Else
            Execute sys.sp_addextendedproperty @name=N'MS_Description', @value=@DescriptionText,
                @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=@ObjectName;
    End;
    Else If Col_length(N'dbo.' + @ObjectName, @ColumnName) Is Not Null
    Begin
        If Exists
        (
            Select 1
            From sys.extended_properties
            Where (class = 1)
                And (major_id = Object_id(N'dbo.' + @ObjectName))
                And (minor_id = Columnproperty(Object_id(N'dbo.' + @ObjectName), @ColumnName, 'ColumnId'))
                And (name = N'MS_Description')
        )
            Execute sys.sp_updateextendedproperty @name=N'MS_Description', @value=@DescriptionText,
                @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=@ObjectName,
                @level2type=N'COLUMN', @level2name=@ColumnName;
        Else
            Execute sys.sp_addextendedproperty @name=N'MS_Description', @value=@DescriptionText,
                @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=@ObjectName,
                @level2type=N'COLUMN', @level2name=@ColumnName;
    End;

    Fetch Next From description_cursor Into @ObjectName, @ColumnName, @DescriptionText;
End;
Close description_cursor;
Deallocate description_cursor;

/* Bổ sung mô tả rõ ràng cho các cột mới còn lại. */
Declare @TableName Sysname;
Declare @MissingColumnName Sysname;
Declare @FallbackDescription Nvarchar(1000);
Declare missing_description_cursor Cursor Local Fast_forward For
    Select
        sys.tables.name,
        sys.columns.name
    From sys.tables
        Inner Join sys.schemas On sys.schemas.schema_id = sys.tables.schema_id
        Inner Join sys.columns On sys.columns.object_id = sys.tables.object_id
        Left Join sys.extended_properties On sys.extended_properties.class = 1
            And sys.extended_properties.major_id = sys.tables.object_id
            And sys.extended_properties.minor_id = sys.columns.column_id
            And sys.extended_properties.name = N'MS_Description'
    Where (sys.schemas.name = N'dbo')
        And (sys.tables.name In (N'SIM_Year', N'SIM_Science', N'SIM_Course', N'SIM_Subject', N'SIM_Teacher', N'SIM_Class', N'SIM_Student', N'SIM_Class_Subject', N'SIM_Timetable', N'SYS_PermissionCategory', N'SYS_PermissionGroup', N'SIM_LessonResources', N'LMS_AssignmentSubmissions', N'LMS_StudySessions'))
        And (sys.extended_properties.value Is Null);

Open missing_description_cursor;
Fetch Next From missing_description_cursor Into @TableName, @MissingColumnName;
While @@Fetch_status = 0
Begin
    Set @FallbackDescription = N'Cột ' + @MissingColumnName + N' của bảng ' + @TableName + N', lưu thông tin phục vụ nghiệp vụ được mô tả ở cấp bảng.';
    Execute sys.sp_addextendedproperty @name=N'MS_Description', @value=@FallbackDescription,
        @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=@TableName,
        @level2type=N'COLUMN', @level2name=@MissingColumnName;
    Fetch Next From missing_description_cursor Into @TableName, @MissingColumnName;
End;
Close missing_description_cursor;
Deallocate missing_description_cursor;
Go

Create Or Alter View dbo.SYS_User
As
Select
    dbo.SYS_Users.UserID,
    dbo.SYS_Users.Username,
    dbo.SYS_Users.PasswordHash Password,
    dbo.SYS_Users.FullName,
    dbo.SYS_Users.Email,
    Convert(Nvarchar(50), Null) Mobile,
    dbo.SYS_Users.AvatarUrl Avatar,
    dbo.SYS_Users.DataGroupID,
    dbo.SYS_Users.StudentID,
    dbo.SYS_Users.TeacherID,
    Convert(Bit, Case When dbo.SYS_Users.Status = 'ACTIVE' Then 1 Else 0 End) IsActived,
    dbo.SYS_Users.CreatedAt CreatedDate,
    dbo.SYS_Users.UpdatedAt UpdatedDate,
    dbo.SYS_Users.IsDeleted
From dbo.SYS_Users;
Go

Create Or Alter View dbo.SYS_Role
As
Select
    dbo.SYS_Roles.RoleID,
    dbo.SYS_Roles.Name RoleName,
    dbo.SYS_Roles.Description,
    Convert(Bit, 0) IsDefault,
    Convert(Bit, Case When dbo.SYS_Roles.Status = 'ACTIVE' Then 1 Else 0 End) IsActived
From dbo.SYS_Roles;
Go

Create Or Alter View dbo.SYS_User_Role
As
Select
    dbo.SYS_Users.Username,
    dbo.SYS_UserRoles.RoleID,
    dbo.SYS_Users.CreatedAt CreatedDate
From dbo.SYS_UserRoles
    Inner Join dbo.SYS_Users On dbo.SYS_Users.UserID = dbo.SYS_UserRoles.UserID;
Go

Create Or Alter View dbo.SYS_Permission
As
Select
    Convert(Nvarchar(50), dbo.SYS_Permissions.PermissionID) PermissionID,
    dbo.SYS_Permissions.Code PermissionCode,
    dbo.SYS_Permissions.Name PermissionName,
    dbo.SYS_Permissions.Description,
    dbo.SYS_Permissions.PermissionCategoryID,
    dbo.SYS_Permissions.PermissionGroupID
From dbo.SYS_Permissions;
Go
