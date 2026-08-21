Set Nocount On;
Set Xact_abort On;

/*
    Dữ liệu mẫu đầy đủ cho một môn học:
    WEB101 -> 5 chương -> mỗi chương có đủ 7 loại bài học hệ thống hỗ trợ.
    Script có thể chạy nhiều lần mà không tạo dữ liệu trùng.
*/

Declare @CourseID Bigint;
Declare @TeacherUserID Bigint;
Declare @ActorUserID Bigint = Coalesce
(
    (Select Top (1) UserID From dbo.SYS_Users Where (Username = N'admin') And (IsDeleted = 0)),
    1
);

Select Top (1)
    @CourseID = dbo.SIM_Courses.CourseID,
    @TeacherUserID = dbo.SIM_Courses.TeacherUserID
From dbo.SIM_Courses
Inner Join dbo.SIM_Class_Subject On dbo.SIM_Class_Subject.DataGroupID = dbo.SIM_Courses.DataGroupID And dbo.SIM_Class_Subject.ClassSubjectID = dbo.SIM_Courses.ClassSubjectID
Where (dbo.SIM_Class_Subject.SubjectID = N'WEB101')
    And (dbo.SIM_Class_Subject.ClassSubjectStatus = 1)
    And (dbo.SIM_Courses.IsDeleted = 0)
Order By
    dbo.SIM_Courses.CourseID;

If @CourseID Is Null
    Throw 50000, N'Không tìm thấy không gian học trực tuyến của môn WEB101.', 1;

Set @TeacherUserID = Coalesce(@TeacherUserID, @ActorUserID);

Update dbo.SIM_Courses
Set
    Status = 'PUBLISHED',
    PublishedAt = Coalesce(PublishedAt, Sysutcdatetime()),
    ShortDescription = N'Môn học mẫu đầy đủ gồm 5 chương và toàn bộ loại bài học.',
    Description = N'Dữ liệu kiểm thử hoàn chỉnh cho bài soạn thảo, tài liệu, video, video tương tác, quiz, bài tập nộp bài và bài đọc tương tác.'
Where (dbo.SIM_Courses.CourseID = @CourseID);

Declare @ChapterDefinition Table
(
    ChapterNumber Int Not Null,
    ChapterTitle Nvarchar(500) Not Null,
    ChapterDescription Nvarchar(1000) Not Null
);

Insert Into @ChapterDefinition
(
    ChapterNumber,
    ChapterTitle,
    ChapterDescription
)
Values
    (1, N'Chương 1: Nền tảng ứng dụng Web', N'Tổng quan kiến trúc Web, HTTP và quy trình phát triển ứng dụng.'),
    (2, N'Chương 2: HTML5 và cấu trúc nội dung', N'Xây dựng cấu trúc trang có ngữ nghĩa, dễ truy cập và dễ bảo trì.'),
    (3, N'Chương 3: CSS và thiết kế responsive', N'Tổ chức giao diện, bố cục linh hoạt và hiển thị tốt trên nhiều thiết bị.'),
    (4, N'Chương 4: JavaScript và DOM', N'Xử lý dữ liệu, sự kiện và tương tác động trên trình duyệt.'),
    (5, N'Chương 5: Vue.js và dự án tổng kết', N'Xây dựng ứng dụng Vue.js hoàn chỉnh và tổng kết kiến thức môn học.');

Insert Into dbo.SIM_Chapters
(
    CourseID,
    Title,
    Description,
    SortOrder,
    Status,
    IsDeleted
)
Select
    @CourseID,
    ChapterDefinition.ChapterTitle,
    ChapterDefinition.ChapterDescription,
    ChapterDefinition.ChapterNumber,
    'ACTIVE',
    0
From @ChapterDefinition ChapterDefinition
Where Not Exists
(
    Select
        1
    From dbo.SIM_Chapters
    Where (dbo.SIM_Chapters.CourseID = @CourseID)
        And (dbo.SIM_Chapters.Title = ChapterDefinition.ChapterTitle)
        And (dbo.SIM_Chapters.IsDeleted = 0)
);

Declare @LessonTypeDefinition Table
(
    LessonOrder Int Not Null,
    LessonType Varchar(50) Not Null,
    LessonName Nvarchar(200) Not Null,
    DurationSeconds Int Not Null,
    PassingScore Decimal(5, 2) Not Null
);

Insert Into @LessonTypeDefinition
(
    LessonOrder,
    LessonType,
    LessonName,
    DurationSeconds,
    PassingScore
)
Values
    (1, 'EDITOR', N'Bài đọc lý thuyết', 600, 0),
    (2, 'DOCUMENT', N'Tài liệu PDF tham khảo', 900, 0),
    (3, 'VIDEO', N'Video bài giảng', 180, 0),
    (4, 'INTERACTIVE_VIDEO', N'Video tương tác', 180, 70),
    (5, 'QUIZ', N'Bài kiểm tra cuối chương', 900, 70),
    (6, 'ASSIGNMENT', N'Bài tập thực hành', 1800, 50),
    (7, 'INTERACTIVE_CONTENT', N'Bài đọc tương tác', 1200, 70);

Insert Into dbo.SIM_Lessons
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
    DocumentUrl,
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
    @CourseID,
    dbo.SIM_Chapters.ChapterID,
    Concat(N'Bài ', ChapterDefinition.ChapterNumber, N'.', LessonTypeDefinition.LessonOrder, N': ', LessonTypeDefinition.LessonName),
    Concat(LessonTypeDefinition.LessonName, N' của ', Lower(ChapterDefinition.ChapterTitle), N'.'),
    LessonTypeDefinition.LessonType,
    LessonTypeDefinition.DurationSeconds,
    LessonTypeDefinition.LessonOrder,
    1,
    LessonTypeDefinition.PassingScore,
    Case
        When LessonTypeDefinition.LessonType = 'EDITOR' Then Concat(N'<h2>', ChapterDefinition.ChapterTitle, N'</h2><p>Bài học trình bày kiến thức trọng tâm, ví dụ minh họa và các lưu ý thực hành.</p><h3>Mục tiêu</h3><ul><li>Hiểu khái niệm cốt lõi của chương.</li><li>Áp dụng kiến thức vào ví dụ thực tế.</li><li>Chuẩn bị cho bài kiểm tra và bài tập cuối chương.</li></ul>')
        When LessonTypeDefinition.LessonType = 'ASSIGNMENT' Then Concat(N'<h2>Yêu cầu bài tập chương ', ChapterDefinition.ChapterNumber, N'</h2><p>Hoàn thành sản phẩm thực hành, mô tả các bước thực hiện và nộp file PDF hoặc DOCX. Học viên cũng có thể soạn nội dung trực tiếp trên hệ thống.</p><ul><li>Nêu rõ mục tiêu.</li><li>Đính kèm minh chứng kết quả.</li><li>Tự đánh giá và đề xuất cải tiến.</li></ul>')
        When LessonTypeDefinition.LessonType = 'INTERACTIVE_CONTENT' Then Concat(N'<h2>Bài đọc tương tác chương ', ChapterDefinition.ChapterNumber, N'</h2><p>Đọc nội dung theo thứ tự và trả lời các câu hỏi bên dưới để hoàn thành bài.</p><h3>Kiến thức trọng tâm</h3><p>', ChapterDefinition.ChapterDescription, N'</p><blockquote>Hãy đọc hết nội dung trước khi gửi câu trả lời.</blockquote>')
        Else Null
    End,
    Case
        When LessonTypeDefinition.LessonType = 'DOCUMENT' And ChapterDefinition.ChapterNumber In (1, 4) Then N'/Media/File/Lessons/Demo/51T.XD1_MC_QP_102251_KeHoach.pdf'
        When LessonTypeDefinition.LessonType = 'DOCUMENT' And ChapterDefinition.ChapterNumber In (2, 5) Then N'/Media/File/Lessons/Demo/mau_hk.pdf'
        When LessonTypeDefinition.LessonType = 'DOCUMENT' Then N'/Media/File/Lessons/Demo/STGV.pdf'
        Else Null
    End,
    Case When LessonTypeDefinition.LessonType = 'ASSIGNMENT' Then Concat(N'WEB101-Chuong-', ChapterDefinition.ChapterNumber) Else Null End,
    Case When LessonTypeDefinition.LessonType = 'ASSIGNMENT' Then Dateadd(Day, -7, Sysutcdatetime()) Else Null End,
    Case When LessonTypeDefinition.LessonType = 'ASSIGNMENT' Then Dateadd(Day, 30 + (ChapterDefinition.ChapterNumber * 7), Sysutcdatetime()) Else Null End,
    100,
    3,
    50,
    1,
    'ACTIVE',
    0
From @ChapterDefinition ChapterDefinition
Inner Join dbo.SIM_Chapters On dbo.SIM_Chapters.CourseID = @CourseID And dbo.SIM_Chapters.Title = ChapterDefinition.ChapterTitle And dbo.SIM_Chapters.IsDeleted = 0
Cross Join @LessonTypeDefinition LessonTypeDefinition
Where Not Exists
(
    Select
        1
    From dbo.SIM_Lessons
    Where (dbo.SIM_Lessons.ChapterID = dbo.SIM_Chapters.ChapterID)
        And (dbo.SIM_Lessons.Title = Concat(N'Bài ', ChapterDefinition.ChapterNumber, N'.', LessonTypeDefinition.LessonOrder, N': ', LessonTypeDefinition.LessonName))
        And (dbo.SIM_Lessons.IsDeleted = 0)
);

Insert Into dbo.SIM_LessonResources
(
    LessonID,
    ResourceType,
    ResourceName,
    ResourceUrl,
    OriginalFileName,
    MimeType,
    SortOrder,
    CreatedByUserID,
    IsDeleted
)
Select
    dbo.SIM_Lessons.LessonID,
    'DOCUMENT',
    Concat(N'Tài liệu chương ', ChapterDefinition.ChapterNumber),
    dbo.SIM_Lessons.DocumentUrl,
    Case
        When dbo.SIM_Lessons.DocumentUrl Like N'%51T.XD1%' Then N'51T.XD1_MC_QP_102251_KeHoach.pdf'
        When dbo.SIM_Lessons.DocumentUrl Like N'%mau_hk%' Then N'mau_hk.pdf'
        Else N'STGV.pdf'
    End,
    N'application/pdf',
    1,
    @TeacherUserID,
    0
From @ChapterDefinition ChapterDefinition
Inner Join dbo.SIM_Chapters On dbo.SIM_Chapters.CourseID = @CourseID And dbo.SIM_Chapters.Title = ChapterDefinition.ChapterTitle And dbo.SIM_Chapters.IsDeleted = 0
Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.ChapterID = dbo.SIM_Chapters.ChapterID And dbo.SIM_Lessons.LessonType = 'DOCUMENT' And dbo.SIM_Lessons.IsDeleted = 0
Where Not Exists
(
    Select
        1
    From dbo.SIM_LessonResources
    Where (dbo.SIM_LessonResources.LessonID = dbo.SIM_Lessons.LessonID)
        And (dbo.SIM_LessonResources.ResourceUrl = dbo.SIM_Lessons.DocumentUrl)
        And (dbo.SIM_LessonResources.IsDeleted = 0)
);

Declare @VideoDefinition Table
(
    ChapterNumber Int Not Null,
    VideoTitle Nvarchar(500) Not Null,
    VideoUrl Nvarchar(1000) Not Null,
    OriginalFileName Nvarchar(500) Not Null
);

Insert Into @VideoDefinition
(
    ChapterNumber,
    VideoTitle,
    VideoUrl,
    OriginalFileName
)
Values
    (1, N'WEB101 - Video chương 1', N'/Media/Video/demo/z3.mp4', N'z3.mp4'),
    (2, N'WEB101 - Video chương 2', N'/Media/Video/demo/z5.mp4', N'z5.mp4'),
    (3, N'WEB101 - Video chương 3', N'/Media/Video/demo/z6.mp4', N'z6.mp4'),
    (4, N'WEB101 - Video chương 4', N'/Media/Video/demo/z7.mp4', N'z7.mp4'),
    (5, N'WEB101 - Video chương 5', N'/Media/Video/demo/z22.mp4', N'z22.mp4');

Insert Into dbo.SIM_VideoAssets
(
    Title,
    SourceType,
    VideoUrl,
    DurationSeconds,
    OriginalFileName,
    MimeType,
    CreatedByUserID,
    ShareScope,
    Status,
    IsDeleted
)
Select
    VideoDefinition.VideoTitle,
    'LOCAL',
    VideoDefinition.VideoUrl,
    180,
    VideoDefinition.OriginalFileName,
    N'video/mp4',
    @TeacherUserID,
    'SCHOOL',
    'ACTIVE',
    0
From @VideoDefinition VideoDefinition
Where Not Exists
(
    Select
        1
    From dbo.SIM_VideoAssets
    Where (dbo.SIM_VideoAssets.Title = VideoDefinition.VideoTitle)
        And (dbo.SIM_VideoAssets.IsDeleted = 0)
);

Insert Into dbo.SIM_Videos
(
    VideoAssetID,
    Title,
    SourceType,
    VideoUrl,
    DurationSeconds,
    AllowSeek,
    AllowSpeed,
    RequiredWatchPercent,
    Status
)
Select
    dbo.SIM_VideoAssets.VideoAssetID,
    dbo.SIM_VideoAssets.Title,
    dbo.SIM_VideoAssets.SourceType,
    dbo.SIM_VideoAssets.VideoUrl,
    dbo.SIM_VideoAssets.DurationSeconds,
    1,
    1,
    80,
    'ACTIVE'
From dbo.SIM_VideoAssets
Inner Join @VideoDefinition VideoDefinition On VideoDefinition.VideoTitle = dbo.SIM_VideoAssets.Title
Where (dbo.SIM_VideoAssets.IsDeleted = 0)
    And Not Exists
    (
        Select
            1
        From dbo.SIM_Videos
        Where (dbo.SIM_Videos.VideoAssetID = dbo.SIM_VideoAssets.VideoAssetID)
    );

Insert Into dbo.SIM_VideoVersions
(
    VideoID,
    VersionNumber,
    Title,
    SourceType,
    VideoUrl,
    DurationSeconds,
    AllowSeek,
    AllowSpeed,
    RequiredWatchPercent,
    OriginalFileName,
    MimeType,
    ChangeSummary,
    VersionStatus,
    CreatedByUserID,
    PublishedByUserID,
    PublishedAt
)
Select
    dbo.SIM_Videos.VideoID,
    1,
    dbo.SIM_Videos.Title,
    dbo.SIM_Videos.SourceType,
    dbo.SIM_Videos.VideoUrl,
    dbo.SIM_Videos.DurationSeconds,
    dbo.SIM_Videos.AllowSeek,
    dbo.SIM_Videos.AllowSpeed,
    dbo.SIM_Videos.RequiredWatchPercent,
    VideoDefinition.OriginalFileName,
    N'video/mp4',
    N'Phiên bản video mẫu cho môn WEB101.',
    'PUBLISHED',
    @TeacherUserID,
    @TeacherUserID,
    Sysutcdatetime()
From dbo.SIM_Videos
Inner Join dbo.SIM_VideoAssets On dbo.SIM_VideoAssets.VideoAssetID = dbo.SIM_Videos.VideoAssetID
Inner Join @VideoDefinition VideoDefinition On VideoDefinition.VideoTitle = dbo.SIM_VideoAssets.Title
Where Not Exists
(
    Select
        1
    From dbo.SIM_VideoVersions
    Where (dbo.SIM_VideoVersions.VideoID = dbo.SIM_Videos.VideoID)
        And (dbo.SIM_VideoVersions.VersionNumber = 1)
);

Update dbo.SIM_Videos
Set
    CurrentVideoVersionID = dbo.SIM_VideoVersions.VideoVersionID
From dbo.SIM_Videos
Inner Join dbo.SIM_VideoAssets On dbo.SIM_VideoAssets.VideoAssetID = dbo.SIM_Videos.VideoAssetID
Inner Join @VideoDefinition VideoDefinition On VideoDefinition.VideoTitle = dbo.SIM_VideoAssets.Title
Inner Join dbo.SIM_VideoVersions On dbo.SIM_VideoVersions.VideoID = dbo.SIM_Videos.VideoID And dbo.SIM_VideoVersions.VersionNumber = 1
Where (dbo.SIM_Videos.CurrentVideoVersionID Is Null);

Update dbo.SIM_Lessons
Set
    VideoID = dbo.SIM_Videos.VideoID,
    VideoVersionID = dbo.SIM_VideoVersions.VideoVersionID
From dbo.SIM_Lessons
Inner Join dbo.SIM_Chapters On dbo.SIM_Chapters.ChapterID = dbo.SIM_Lessons.ChapterID
Inner Join @ChapterDefinition ChapterDefinition On ChapterDefinition.ChapterTitle = dbo.SIM_Chapters.Title
Inner Join @VideoDefinition VideoDefinition On VideoDefinition.ChapterNumber = ChapterDefinition.ChapterNumber
Inner Join dbo.SIM_VideoAssets On dbo.SIM_VideoAssets.Title = VideoDefinition.VideoTitle And dbo.SIM_VideoAssets.IsDeleted = 0
Inner Join dbo.SIM_Videos On dbo.SIM_Videos.VideoAssetID = dbo.SIM_VideoAssets.VideoAssetID
Inner Join dbo.SIM_VideoVersions On dbo.SIM_VideoVersions.VideoID = dbo.SIM_Videos.VideoID And dbo.SIM_VideoVersions.VersionNumber = 1
Where (dbo.SIM_Lessons.CourseID = @CourseID)
    And (dbo.SIM_Lessons.LessonType In ('VIDEO', 'INTERACTIVE_VIDEO'))
    And (dbo.SIM_Lessons.IsDeleted = 0);

Declare @QuestionDefinition Table
(
    ChapterNumber Int Not Null,
    QuestionOrder Int Not Null,
    QuestionCode Nvarchar(100) Not Null,
    QuestionType Varchar(50) Not Null,
    QuestionText Nvarchar(2000) Not Null,
    Explanation Nvarchar(2000) Not Null
);

Insert Into @QuestionDefinition
(
    ChapterNumber,
    QuestionOrder,
    QuestionCode,
    QuestionType,
    QuestionText,
    Explanation
)
Select
    ChapterDefinition.ChapterNumber,
    QuestionTypeDefinition.QuestionOrder,
    Concat(N'FULL-WEB101-C', Right(N'00' + Convert(Nvarchar(10), ChapterDefinition.ChapterNumber), 2), N'-', QuestionTypeDefinition.QuestionType),
    QuestionTypeDefinition.QuestionType,
    Case
        When QuestionTypeDefinition.QuestionType = 'SINGLE_CHOICE' Then Concat(N'Chương ', ChapterDefinition.ChapterNumber, N': nội dung nào là trọng tâm chính của chương?')
        When QuestionTypeDefinition.QuestionType = 'MULTIPLE_CHOICE' Then Concat(N'Chương ', ChapterDefinition.ChapterNumber, N': chọn các hoạt động học tập phù hợp.')
        When QuestionTypeDefinition.QuestionType = 'TRUE_FALSE' Then Concat(N'Chương ', ChapterDefinition.ChapterNumber, N': học viên cần hoàn thành bài đọc và bài thực hành để củng cố kiến thức.')
        Else Concat(N'Nhập từ khóa xác nhận hoàn thành chương ', ChapterDefinition.ChapterNumber, N'.')
    End,
    Concat(N'Giải thích mẫu cho câu hỏi chương ', ChapterDefinition.ChapterNumber, N'.')
From @ChapterDefinition ChapterDefinition
Cross Apply
(
    Values
        (1, 'SINGLE_CHOICE'),
        (2, 'MULTIPLE_CHOICE'),
        (3, 'TRUE_FALSE'),
        (4, 'SHORT_ANSWER')
) QuestionTypeDefinition(QuestionOrder, QuestionType);

Insert Into dbo.LMS_Questions
(
    QuestionType,
    QuestionText,
    Description,
    Explanation,
    Difficulty,
    DefaultScore,
    ShortAnswerMode,
    CreatedByUserID,
    Status,
    IsDeleted
)
Select
    QuestionDefinition.QuestionType,
    QuestionDefinition.QuestionText,
    QuestionDefinition.QuestionCode,
    QuestionDefinition.Explanation,
    Case When QuestionDefinition.ChapterNumber <= 2 Then 'EASY' When QuestionDefinition.ChapterNumber <= 4 Then 'MEDIUM' Else 'HARD' End,
    10,
    Case When QuestionDefinition.QuestionType = 'SHORT_ANSWER' Then 'EXACT_MATCH' Else Null End,
    @TeacherUserID,
    'ACTIVE',
    0
From @QuestionDefinition QuestionDefinition
Where Not Exists
(
    Select
        1
    From dbo.LMS_Questions
    Where (dbo.LMS_Questions.Description = QuestionDefinition.QuestionCode)
        And (dbo.LMS_Questions.IsDeleted = 0)
);

Insert Into dbo.LMS_QuestionOptions
(
    QuestionID,
    OptionCode,
    OptionText,
    IsCorrect,
    SortOrder,
    IsDeleted
)
Select
    dbo.LMS_Questions.QuestionID,
    QuestionOptionDefinition.OptionCode,
    QuestionOptionDefinition.OptionText,
    QuestionOptionDefinition.IsCorrect,
    QuestionOptionDefinition.SortOrder,
    0
From @QuestionDefinition QuestionDefinition
Inner Join dbo.LMS_Questions On dbo.LMS_Questions.Description = QuestionDefinition.QuestionCode And dbo.LMS_Questions.IsDeleted = 0
Cross Apply
(
    Select
        'A' OptionCode,
        Concat(N'Kiến thức trọng tâm chương ', QuestionDefinition.ChapterNumber) OptionText,
        Convert(Bit, 1) IsCorrect,
        1 SortOrder
    Where (QuestionDefinition.QuestionType = 'SINGLE_CHOICE')
    Union All
    Select 'B', N'Nội dung không liên quan', Convert(Bit, 0), 2 Where (QuestionDefinition.QuestionType = 'SINGLE_CHOICE')
    Union All
    Select 'C', N'Bỏ qua toàn bộ hoạt động học', Convert(Bit, 0), 3 Where (QuestionDefinition.QuestionType = 'SINGLE_CHOICE')
    Union All
    Select 'A', N'Đọc nội dung bài học', Convert(Bit, 1), 1 Where (QuestionDefinition.QuestionType = 'MULTIPLE_CHOICE')
    Union All
    Select 'B', N'Xem video và thực hành', Convert(Bit, 1), 2 Where (QuestionDefinition.QuestionType = 'MULTIPLE_CHOICE')
    Union All
    Select 'C', N'Không cần làm bài tập', Convert(Bit, 0), 3 Where (QuestionDefinition.QuestionType = 'MULTIPLE_CHOICE')
    Union All
    Select 'D', N'Trao đổi và tự đánh giá', Convert(Bit, 1), 4 Where (QuestionDefinition.QuestionType = 'MULTIPLE_CHOICE')
    Union All
    Select 'A', N'Đúng', Convert(Bit, 1), 1 Where (QuestionDefinition.QuestionType = 'TRUE_FALSE')
    Union All
    Select 'B', N'Sai', Convert(Bit, 0), 2 Where (QuestionDefinition.QuestionType = 'TRUE_FALSE')
) QuestionOptionDefinition
Where Not Exists
(
    Select
        1
    From dbo.LMS_QuestionOptions
    Where (dbo.LMS_QuestionOptions.QuestionID = dbo.LMS_Questions.QuestionID)
        And (dbo.LMS_QuestionOptions.OptionCode = QuestionOptionDefinition.OptionCode)
);

Insert Into dbo.LMS_QuestionAnswerKeys
(
    QuestionID,
    AnswerText,
    IsCaseSensitive,
    SortOrder
)
Select
    dbo.LMS_Questions.QuestionID,
    Concat(N'CHUONG ', QuestionDefinition.ChapterNumber),
    0,
    1
From @QuestionDefinition QuestionDefinition
Inner Join dbo.LMS_Questions On dbo.LMS_Questions.Description = QuestionDefinition.QuestionCode And dbo.LMS_Questions.IsDeleted = 0
Where (QuestionDefinition.QuestionType = 'SHORT_ANSWER')
    And Not Exists
    (
        Select
            1
        From dbo.LMS_QuestionAnswerKeys
        Where (dbo.LMS_QuestionAnswerKeys.QuestionID = dbo.LMS_Questions.QuestionID)
    );

Insert Into dbo.LMS_Quizzes
(
    LessonID,
    Title,
    Description,
    PassingScore,
    TimeLimitMinutes,
    MaxAttempts,
    ShuffleQuestions,
    Status,
    CreatedByUserID
)
Select
    dbo.SIM_Lessons.LessonID,
    dbo.SIM_Lessons.Title,
    Concat(N'Bài kiểm tra gồm đủ 4 dạng câu hỏi của chương ', ChapterDefinition.ChapterNumber, N'.'),
    70,
    15,
    3,
    0,
    'ACTIVE',
    @TeacherUserID
From @ChapterDefinition ChapterDefinition
Inner Join dbo.SIM_Chapters On dbo.SIM_Chapters.CourseID = @CourseID And dbo.SIM_Chapters.Title = ChapterDefinition.ChapterTitle And dbo.SIM_Chapters.IsDeleted = 0
Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.ChapterID = dbo.SIM_Chapters.ChapterID And dbo.SIM_Lessons.LessonType = 'QUIZ' And dbo.SIM_Lessons.IsDeleted = 0
Where Not Exists
(
    Select
        1
    From dbo.LMS_Quizzes
    Where (dbo.LMS_Quizzes.LessonID = dbo.SIM_Lessons.LessonID)
);

Insert Into dbo.LMS_QuizQuestions
(
    QuizID,
    QuestionID,
    Score,
    SortOrder,
    IsRequired
)
Select
    dbo.LMS_Quizzes.QuizID,
    dbo.LMS_Questions.QuestionID,
    10,
    QuestionDefinition.QuestionOrder,
    1
From @ChapterDefinition ChapterDefinition
Inner Join dbo.SIM_Chapters On dbo.SIM_Chapters.CourseID = @CourseID And dbo.SIM_Chapters.Title = ChapterDefinition.ChapterTitle And dbo.SIM_Chapters.IsDeleted = 0
Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.ChapterID = dbo.SIM_Chapters.ChapterID And dbo.SIM_Lessons.LessonType = 'QUIZ' And dbo.SIM_Lessons.IsDeleted = 0
Inner Join dbo.LMS_Quizzes On dbo.LMS_Quizzes.LessonID = dbo.SIM_Lessons.LessonID
Inner Join @QuestionDefinition QuestionDefinition On QuestionDefinition.ChapterNumber = ChapterDefinition.ChapterNumber
Inner Join dbo.LMS_Questions On dbo.LMS_Questions.Description = QuestionDefinition.QuestionCode And dbo.LMS_Questions.IsDeleted = 0
Where Not Exists
(
    Select
        1
    From dbo.LMS_QuizQuestions
    Where (dbo.LMS_QuizQuestions.QuizID = dbo.LMS_Quizzes.QuizID)
        And (dbo.LMS_QuizQuestions.QuestionID = dbo.LMS_Questions.QuestionID)
);

Insert Into dbo.LMS_InteractiveContents
(
    LessonID,
    CompletionRule,
    RequireReading,
    PassingScore,
    ShowResultImmediately,
    ShowScore,
    CreatedByUserID
)
Select
    dbo.SIM_Lessons.LessonID,
    'REQUIRED_QUESTIONS',
    1,
    70,
    1,
    1,
    @TeacherUserID
From @ChapterDefinition ChapterDefinition
Inner Join dbo.SIM_Chapters On dbo.SIM_Chapters.CourseID = @CourseID And dbo.SIM_Chapters.Title = ChapterDefinition.ChapterTitle And dbo.SIM_Chapters.IsDeleted = 0
Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.ChapterID = dbo.SIM_Chapters.ChapterID And dbo.SIM_Lessons.LessonType = 'INTERACTIVE_CONTENT' And dbo.SIM_Lessons.IsDeleted = 0
Where Not Exists
(
    Select
        1
    From dbo.LMS_InteractiveContents
    Where (dbo.LMS_InteractiveContents.LessonID = dbo.SIM_Lessons.LessonID)
);

Insert Into dbo.LMS_ContentInteractions
(
    InteractiveContentID,
    QuestionID,
    ContentAnchor,
    Required,
    AllowRetry,
    Score,
    AttemptLimit,
    SortOrder,
    Status,
    CreatedByUserID,
    IsDeleted
)
Select
    dbo.LMS_InteractiveContents.InteractiveContentID,
    dbo.LMS_Questions.QuestionID,
    Concat(N'chapter-', ChapterDefinition.ChapterNumber, N'-question-', QuestionDefinition.QuestionOrder),
    1,
    1,
    10,
    3,
    QuestionDefinition.QuestionOrder,
    'ACTIVE',
    @TeacherUserID,
    0
From @ChapterDefinition ChapterDefinition
Inner Join dbo.SIM_Chapters On dbo.SIM_Chapters.CourseID = @CourseID And dbo.SIM_Chapters.Title = ChapterDefinition.ChapterTitle And dbo.SIM_Chapters.IsDeleted = 0
Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.ChapterID = dbo.SIM_Chapters.ChapterID And dbo.SIM_Lessons.LessonType = 'INTERACTIVE_CONTENT' And dbo.SIM_Lessons.IsDeleted = 0
Inner Join dbo.LMS_InteractiveContents On dbo.LMS_InteractiveContents.LessonID = dbo.SIM_Lessons.LessonID
Inner Join @QuestionDefinition QuestionDefinition On QuestionDefinition.ChapterNumber = ChapterDefinition.ChapterNumber
Inner Join dbo.LMS_Questions On dbo.LMS_Questions.Description = QuestionDefinition.QuestionCode And dbo.LMS_Questions.IsDeleted = 0
Where Not Exists
(
    Select
        1
    From dbo.LMS_ContentInteractions
    Where (dbo.LMS_ContentInteractions.InteractiveContentID = dbo.LMS_InteractiveContents.InteractiveContentID)
        And (dbo.LMS_ContentInteractions.QuestionID = dbo.LMS_Questions.QuestionID)
        And (dbo.LMS_ContentInteractions.IsDeleted = 0)
);

Insert Into dbo.LMS_VideoInteractions
(
    VideoID,
    VideoVersionID,
    QuestionID,
    TimeSeconds,
    InteractionType,
    Required,
    PauseVideo,
    AllowSkip,
    Score,
    AttemptLimit,
    SortOrder,
    Status,
    IsDeleted
)
Select
    dbo.SIM_Lessons.VideoID,
    dbo.SIM_Lessons.VideoVersionID,
    dbo.LMS_Questions.QuestionID,
    QuestionDefinition.QuestionOrder * 30,
    QuestionDefinition.QuestionType,
    1,
    1,
    0,
    10,
    3,
    QuestionDefinition.QuestionOrder,
    'ACTIVE',
    0
From @ChapterDefinition ChapterDefinition
Inner Join dbo.SIM_Chapters On dbo.SIM_Chapters.CourseID = @CourseID And dbo.SIM_Chapters.Title = ChapterDefinition.ChapterTitle And dbo.SIM_Chapters.IsDeleted = 0
Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.ChapterID = dbo.SIM_Chapters.ChapterID And dbo.SIM_Lessons.LessonType = 'INTERACTIVE_VIDEO' And dbo.SIM_Lessons.IsDeleted = 0
Inner Join @QuestionDefinition QuestionDefinition On QuestionDefinition.ChapterNumber = ChapterDefinition.ChapterNumber
Inner Join dbo.LMS_Questions On dbo.LMS_Questions.Description = QuestionDefinition.QuestionCode And dbo.LMS_Questions.IsDeleted = 0
Where (dbo.SIM_Lessons.VideoID Is Not Null)
    And (dbo.SIM_Lessons.VideoVersionID Is Not Null)
    And Not Exists
    (
        Select
            1
        From dbo.LMS_VideoInteractions
        Where (dbo.LMS_VideoInteractions.VideoID = dbo.SIM_Lessons.VideoID)
            And (dbo.LMS_VideoInteractions.VideoVersionID = dbo.SIM_Lessons.VideoVersionID)
            And (dbo.LMS_VideoInteractions.QuestionID = dbo.LMS_Questions.QuestionID)
            And (dbo.LMS_VideoInteractions.IsDeleted = 0)
    );

Go
