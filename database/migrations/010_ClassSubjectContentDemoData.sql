Set Nocount On;
Set Xact_abort On;

/* Dữ liệu mẫu hoàn chỉnh cho luồng năm học -> lớp -> môn -> chương -> bài -> nộp/chấm. */

Declare @ActorID Bigint = Coalesce((Select Top (1) UserID From dbo.SYS_Users Where Username = N'admin' And IsDeleted = 0), 1);
Declare @CategoryID Bigint = (Select Top (1) CourseCategoryID From dbo.SIM_CourseCategories Where Status = 'ACTIVE' Order By SortOrder, CourseCategoryID);

Insert dbo.SIM_Courses
(
    Code,
    Title,
    Slug,
    ShortDescription,
    Description,
    TeacherUserID,
    CourseCategoryID,
    DataGroupID,
    ClassSubjectID,
    Level,
    PassingScore,
    Status,
    PublishedAt,
    CreatedByUserID
)
Select
    Concat(N'MH-', dbo.SIM_Class_Subject.YearID, N'-HK', dbo.SIM_Class_Subject.Semester, N'-', dbo.SIM_Class_Subject.ClassSubjectID),
    Concat(dbo.SIM_Subject.SubjectName, N' · ', dbo.SIM_Class.ClassName, N' · ', dbo.SIM_Year.YearName, N' · Học kỳ ', dbo.SIM_Class_Subject.Semester),
    Lower(Concat(N'mh-', dbo.SIM_Class_Subject.YearID, N'-hk', dbo.SIM_Class_Subject.Semester, N'-', dbo.SIM_Class_Subject.ClassSubjectID)),
    Concat(N'Nội dung học tập môn ', dbo.SIM_Subject.SubjectName, N' dành cho lớp ', dbo.SIM_Class.ClassName, N'.'),
    Concat(N'Không gian học trực tuyến theo phân công môn học lớp năm ', dbo.SIM_Year.YearName, N'.'),
    dbo.SIM_Teacher.UserID,
    @CategoryID,
    dbo.SIM_Class_Subject.DataGroupID,
    dbo.SIM_Class_Subject.ClassSubjectID,
    'BEGINNER',
    50,
    'PUBLISHED',
    Sysutcdatetime(),
    @ActorID
From dbo.SIM_Class_Subject
    Inner Join dbo.SIM_Year On dbo.SIM_Year.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Year.YearID = dbo.SIM_Class_Subject.YearID
    Inner Join dbo.SIM_Class On dbo.SIM_Class.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Class.ClassID = dbo.SIM_Class_Subject.ClassID
    Inner Join dbo.SIM_Subject On dbo.SIM_Subject.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Subject.SubjectID = dbo.SIM_Class_Subject.SubjectID
    Inner Join dbo.SIM_Teacher On dbo.SIM_Teacher.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Teacher.TeacherID = dbo.SIM_Class_Subject.TeacherID And dbo.SIM_Teacher.UserID Is Not Null
Where (dbo.SIM_Class_Subject.ClassSubjectStatus = 1)
    And Not Exists
    (
        Select 1
        From dbo.SIM_Courses
        Where (dbo.SIM_Courses.DataGroupID = dbo.SIM_Class_Subject.DataGroupID)
            And (dbo.SIM_Courses.ClassSubjectID = dbo.SIM_Class_Subject.ClassSubjectID)
            And (dbo.SIM_Courses.IsDeleted = 0)
    );

Insert dbo.LMS_Enrollments
(
    CourseID,
    StudentUserID,
    Status,
    CreatedByUserID
)
Select
    dbo.SIM_Courses.CourseID,
    dbo.SIM_Student.UserID,
    'ENROLLED',
    @ActorID
From dbo.SIM_Courses
    Inner Join dbo.SIM_Class_Subject On dbo.SIM_Class_Subject.DataGroupID = dbo.SIM_Courses.DataGroupID And dbo.SIM_Class_Subject.ClassSubjectID = dbo.SIM_Courses.ClassSubjectID
    Inner Join dbo.SIM_Student On dbo.SIM_Student.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Student.ClassID = dbo.SIM_Class_Subject.ClassID And dbo.SIM_Student.UserID Is Not Null
Where (dbo.SIM_Courses.IsDeleted = 0)
    And (dbo.SIM_Student.IsActived = 1)
    And Not Exists
    (
        Select 1
        From dbo.LMS_Enrollments
        Where (dbo.LMS_Enrollments.CourseID = dbo.SIM_Courses.CourseID)
            And (dbo.LMS_Enrollments.StudentUserID = dbo.SIM_Student.UserID)
    );

Insert dbo.SIM_Chapters
(
    CourseID,
    Title,
    Description,
    SortOrder,
    Status,
    IsDeleted
)
Select
    dbo.SIM_Courses.CourseID,
    N'Chương 1: Khởi động môn học',
    N'Giới thiệu kế hoạch học tập, tài liệu và bài tập mở đầu.',
    1,
    'ACTIVE',
    0
From dbo.SIM_Courses
Where (dbo.SIM_Courses.ClassSubjectID Is Not Null)
    And (dbo.SIM_Courses.IsDeleted = 0)
    And Not Exists
    (
        Select 1
        From dbo.SIM_Chapters
        Where (dbo.SIM_Chapters.CourseID = dbo.SIM_Courses.CourseID)
            And (dbo.SIM_Chapters.IsDeleted = 0)
    );

Insert dbo.SIM_Lessons
(
    CourseID,
    ChapterID,
    Title,
    Description,
    LessonType,
    DurationSeconds,
    SortOrder,
    IsRequired,
    PassingScore,
    ContentHtml,
    Status,
    IsDeleted
)
Select
    dbo.SIM_Chapters.CourseID,
    dbo.SIM_Chapters.ChapterID,
    N'Giới thiệu và mục tiêu học tập',
    N'Đọc mục tiêu, kế hoạch và yêu cầu hoàn thành môn học.',
    'EDITOR',
    300,
    1,
    1,
    0,
    N'<h2>Mục tiêu học tập</h2><p>Sau bài này, học viên nắm được kế hoạch học, cách sử dụng tài liệu và quy tắc hoàn thành bài tập.</p><ul><li>Đọc nội dung theo thứ tự.</li><li>Hoàn thành bài tập đúng hạn.</li><li>Theo dõi phản hồi của giảng viên.</li></ul>',
    'ACTIVE',
    0
From dbo.SIM_Chapters
    Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.SIM_Chapters.CourseID
Where (dbo.SIM_Courses.ClassSubjectID Is Not Null)
    And (dbo.SIM_Chapters.IsDeleted = 0)
    And Not Exists
    (
        Select 1
        From dbo.SIM_Lessons
        Where (dbo.SIM_Lessons.ChapterID = dbo.SIM_Chapters.ChapterID)
            And (dbo.SIM_Lessons.Title = N'Giới thiệu và mục tiêu học tập')
            And (dbo.SIM_Lessons.IsDeleted = 0)
    );

Insert dbo.SIM_Lessons
(
    CourseID,
    ChapterID,
    Title,
    Description,
    LessonType,
    DurationSeconds,
    SortOrder,
    IsRequired,
    PassingScore,
    ContentHtml,
    AssignmentFolderName,
    AssignmentStartAt,
    DueAt,
    AssignmentMaxScore,
    MaxSubmissionAttempts,
    MaxSubmissionFileSizeMB,
    AllowLateSubmission,
    Status,
    IsDeleted
)
Select
    dbo.SIM_Chapters.CourseID,
    dbo.SIM_Chapters.ChapterID,
    N'Bài tập mở đầu',
    N'Tóm tắt kiến thức đầu vào và mục tiêu cá nhân trong môn học.',
    'ASSIGNMENT',
    600,
    2,
    1,
    50,
    N'<h2>Yêu cầu</h2><p>Viết bản tóm tắt từ 300 đến 500 từ hoặc tải file PDF/DOCX. Nội dung cần nêu kiến thức đầu vào, mục tiêu và kế hoạch học tập.</p>',
    N'Bai-tap-mo-dau',
    Dateadd(Day, -7, Sysutcdatetime()),
    Dateadd(Day, 30, Sysutcdatetime()),
    100,
    3,
    50,
    1,
    'ACTIVE',
    0
From dbo.SIM_Chapters
    Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.SIM_Chapters.CourseID
Where (dbo.SIM_Courses.ClassSubjectID Is Not Null)
    And (dbo.SIM_Chapters.IsDeleted = 0)
    And Not Exists
    (
        Select 1
        From dbo.SIM_Lessons
        Where (dbo.SIM_Lessons.ChapterID = dbo.SIM_Chapters.ChapterID)
            And (dbo.SIM_Lessons.Title = N'Bài tập mở đầu')
            And (dbo.SIM_Lessons.IsDeleted = 0)
    );

;With DemoSubmissionSource As
(
    Select
        dbo.SIM_Lessons.LessonID,
        dbo.SIM_Lessons.CourseID,
        dbo.LMS_Enrollments.StudentUserID,
        Row_number() Over (Partition By dbo.SIM_Lessons.CourseID Order By dbo.LMS_Enrollments.StudentUserID) StudentOrder
    From dbo.SIM_Lessons
        Inner Join dbo.LMS_Enrollments On dbo.LMS_Enrollments.CourseID = dbo.SIM_Lessons.CourseID And dbo.LMS_Enrollments.Status <> 'CANCELLED'
    Where (dbo.SIM_Lessons.LessonType = 'ASSIGNMENT')
        And (dbo.SIM_Lessons.Title = N'Bài tập mở đầu')
        And (dbo.SIM_Lessons.IsDeleted = 0)
)
Insert dbo.LMS_AssignmentSubmissions
(
    LessonID,
    CourseID,
    StudentUserID,
    AttemptNumber,
    SubmissionText,
    SubmittedAt,
    SubmissionStatus,
    Score,
    Feedback,
    GradedByUserID,
    GradedAt,
    IsLate
)
Select
    DemoSubmissionSource.LessonID,
    DemoSubmissionSource.CourseID,
    DemoSubmissionSource.StudentUserID,
    1,
    Concat(N'Bài làm mẫu của học viên #', DemoSubmissionSource.StudentUserID, N': mục tiêu học tập và kế hoạch cá nhân đã được trình bày đầy đủ.'),
    Dateadd(Hour, -DemoSubmissionSource.StudentOrder, Sysutcdatetime()),
    Case When DemoSubmissionSource.StudentOrder % 3 = 0 Then 'GRADED' Else 'SUBMITTED' End,
    Case When DemoSubmissionSource.StudentOrder % 3 = 0 Then Convert(Decimal(8, 2), 82 + DemoSubmissionSource.StudentOrder) Else Null End,
    Case When DemoSubmissionSource.StudentOrder % 3 = 0 Then N'Bài làm rõ ràng. Cần bổ sung thêm ví dụ thực tế.' Else Null End,
    Case When DemoSubmissionSource.StudentOrder % 3 = 0 Then @ActorID Else Null End,
    Case When DemoSubmissionSource.StudentOrder % 3 = 0 Then Sysutcdatetime() Else Null End,
    0
From DemoSubmissionSource
Where (DemoSubmissionSource.StudentOrder <= 3)
    And Not Exists
    (
        Select 1
        From dbo.LMS_AssignmentSubmissions
        Where (dbo.LMS_AssignmentSubmissions.LessonID = DemoSubmissionSource.LessonID)
            And (dbo.LMS_AssignmentSubmissions.StudentUserID = DemoSubmissionSource.StudentUserID)
            And (dbo.LMS_AssignmentSubmissions.AttemptNumber = 1)
    );
Go
