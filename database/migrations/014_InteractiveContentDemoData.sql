Set Nocount On;
Set Xact_abort On;
Set Quoted_identifier On;

Declare @CourseID Bigint =
(
    Select Top (1)
        dbo.SIM_Courses.CourseID
    From dbo.SIM_Courses
    Inner Join dbo.SIM_Chapters On dbo.SIM_Chapters.CourseId = dbo.SIM_Courses.CourseID
    Inner Join dbo.LMS_Enrollments On dbo.LMS_Enrollments.CourseId = dbo.SIM_Courses.CourseID
    Where (dbo.SIM_Courses.Status = 'PUBLISHED')
        And (dbo.SIM_Courses.IsDeleted = 0)
    Order By
        Case When dbo.SIM_Courses.CourseID = 3 Then 0 Else 1 End,
        dbo.SIM_Courses.CourseID
);
Declare @ChapterID Bigint =
(
    Select Top (1)
        dbo.SIM_Chapters.ChapterID
    From dbo.SIM_Chapters
    Where (dbo.SIM_Chapters.CourseId = @CourseID)
        And (dbo.SIM_Chapters.IsDeleted = 0)
    Order By
        dbo.SIM_Chapters.SortOrder
);
Declare @TeacherUserID Bigint = (Select TeacherUserID From dbo.SIM_Courses Where CourseID = @CourseID);
Declare @LessonID Bigint;

Select
    @LessonID = LessonID
From dbo.SIM_Lessons
Where (CourseId = @CourseID)
    And (Title = N'Đọc hiểu: An toàn dữ liệu trong ứng dụng web')
    And (IsDeleted = 0);

If @LessonID Is Null And @CourseID Is Not Null And @ChapterID Is Not Null
Begin
    Insert Into dbo.SIM_Lessons
    (
        CourseId,
        ChapterId,
        Title,
        Description,
        LessonType,
        DurationSeconds,
        SortOrder,
        IsRequired,
        PassingScore,
        Status,
        ContentHtml
    )
    Select
        @CourseID,
        @ChapterID,
        N'Đọc hiểu: An toàn dữ liệu trong ứng dụng web',
        N'Bài đọc tương tác mẫu giúp kiểm tra việc lưu câu trả lời, thử lại, tiến độ đọc và điểm.',
        'INTERACTIVE_CONTENT',
        900,
        Coalesce(Max(SortOrder), 0) + 1,
        1,
        70,
        'ACTIVE',
        N'<h2>An toàn dữ liệu bắt đầu từ đâu?</h2><p>Một ứng dụng web an toàn không gửi đáp án đúng, khóa bí mật hoặc dữ liệu nhạy cảm xuống trình duyệt. Giao diện chỉ gửi lựa chọn của người học đến máy chủ và nhận lại kết quả đã được kiểm tra.</p><h3>Nguyên tắc tối thiểu</h3><ul><li>Xác thực người dùng trước khi truy cập dữ liệu.</li><li>Phân quyền ở API và cơ sở dữ liệu.</li><li>Không tin dữ liệu do trình duyệt gửi lên.</li><li>Lưu lịch sử thao tác quan trọng để có thể kiểm tra.</li></ul><h3>Chấm câu hỏi an toàn</h3><p>Đáp án đúng được giữ trong SQL Server. Khi học viên trả lời, stored procedure so sánh dữ liệu trong transaction, ghi attempt và trả về kết quả phù hợp với cấu hình của giảng viên.</p><blockquote>Hãy đọc hết nội dung và hoàn thành các câu hỏi bên dưới.</blockquote>'
    From dbo.SIM_Lessons
    Where (CourseId = @CourseID)
        And (ChapterId = @ChapterID);

    Set @LessonID = Scope_identity();
End;

If @LessonID Is Not Null
Begin
    If Not Exists (Select 1 From dbo.LMS_InteractiveContents Where LessonID = @LessonID)
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
        Values (@LessonID, 'REQUIRED_QUESTIONS', 1, 70, 1, 1, @TeacherUserID);

    Declare @InteractiveContentID Bigint = (Select InteractiveContentID From dbo.LMS_InteractiveContents Where LessonID = @LessonID);
    Declare @Questions Table
    (
        QuestionCode Varchar(30),
        QuestionType Varchar(50),
        QuestionText Nvarchar(Max),
        Explanation Nvarchar(Max),
        Score Decimal(8, 2),
        SortOrder Int
    );

    Insert Into @Questions(QuestionCode, QuestionType, QuestionText, Explanation, Score, SortOrder)
    Values
        ('SAFE_SINGLE', 'SINGLE_CHOICE', N'Nơi phù hợp nhất để kiểm tra đáp án đúng là đâu?', N'Đáp án đúng cần được giữ và so sánh ở máy chủ hoặc cơ sở dữ liệu.', 10, 1),
        ('SAFE_MULTI', 'MULTIPLE_CHOICE', N'Những biện pháp nào giúp bảo vệ dữ liệu?', N'Cần kết hợp xác thực, phân quyền và kiểm tra dữ liệu đầu vào.', 20, 2),
        ('SAFE_TRUE', 'TRUE_FALSE', N'Trình duyệt của học viên nên nhận toàn bộ đáp án đúng để tự chấm.', N'Nếu gửi đáp án đúng xuống trình duyệt, người dùng có thể xem bằng công cụ phát triển.', 10, 3),
        ('SAFE_SHORT', 'SHORT_ANSWER', N'Tên cơ chế dùng để xác định người dùng được phép làm gì là gì?', N'Phân quyền quyết định các thao tác mà người dùng đã xác thực được phép thực hiện.', 20, 4),
        ('SAFE_ATTEMPT', 'SINGLE_CHOICE', N'Mỗi lần trả lời nên được lưu để phục vụ mục đích nào?', N'Lịch sử attempt giúp khôi phục tiến độ và phục vụ báo cáo.', 10, 5);

    Declare @QuestionCode Varchar(30);
    Declare @QuestionType Varchar(50);
    Declare @QuestionText Nvarchar(Max);
    Declare @Explanation Nvarchar(Max);
    Declare @Score Decimal(8, 2);
    Declare @SortOrder Int;
    Declare @QuestionID Bigint;

    Declare QuestionCursor Cursor Local Fast_forward For
    Select
        QuestionCode,
        QuestionType,
        QuestionText,
        Explanation,
        Score,
        SortOrder
    From @Questions
    Order By
        SortOrder;

    Open QuestionCursor;
    Fetch Next From QuestionCursor Into @QuestionCode, @QuestionType, @QuestionText, @Explanation, @Score, @SortOrder;

    While @@Fetch_status = 0
    Begin
        Select
            @QuestionID = QuestionID
        From dbo.LMS_Questions
        Where (QuestionText = @QuestionText)
            And (IsDeleted = 0);

        If @QuestionID Is Null
        Begin
            Insert Into dbo.LMS_Questions
            (
                QuestionType,
                QuestionText,
                Explanation,
                Difficulty,
                DefaultScore,
                ShortAnswerMode,
                CreatedByUserID,
                Status
            )
            Values
            (
                @QuestionType,
                @QuestionText,
                @Explanation,
                'MEDIUM',
                @Score,
                Case When @QuestionType = 'SHORT_ANSWER' Then 'EXACT_MATCH' Else Null End,
                @TeacherUserID,
                'ACTIVE'
            );
            Set @QuestionID = Scope_identity();

            If @QuestionCode = 'SAFE_SINGLE'
                Insert Into dbo.LMS_QuestionOptions(QuestionId, OptionCode, OptionText, IsCorrect, SortOrder)
                Values (@QuestionID, 'A', N'Trong CSS', 0, 1), (@QuestionID, 'B', N'Tại API hoặc SQL Server', 1, 2), (@QuestionID, 'C', N'Trong localStorage', 0, 3);
            Else If @QuestionCode = 'SAFE_MULTI'
                Insert Into dbo.LMS_QuestionOptions(QuestionId, OptionCode, OptionText, IsCorrect, SortOrder)
                Values (@QuestionID, 'A', N'Xác thực', 1, 1), (@QuestionID, 'B', N'Phân quyền', 1, 2), (@QuestionID, 'C', N'Tin mọi dữ liệu từ trình duyệt', 0, 3), (@QuestionID, 'D', N'Kiểm tra dữ liệu đầu vào', 1, 4);
            Else If @QuestionCode = 'SAFE_TRUE'
                Insert Into dbo.LMS_QuestionOptions(QuestionId, OptionCode, OptionText, IsCorrect, SortOrder)
                Values (@QuestionID, 'A', N'Đúng', 0, 1), (@QuestionID, 'B', N'Sai', 1, 2);
            Else If @QuestionCode = 'SAFE_ATTEMPT'
                Insert Into dbo.LMS_QuestionOptions(QuestionId, OptionCode, OptionText, IsCorrect, SortOrder)
                Values (@QuestionID, 'A', N'Trang trí giao diện', 0, 1), (@QuestionID, 'B', N'Khôi phục tiến độ và báo cáo', 1, 2), (@QuestionID, 'C', N'Tăng dung lượng video', 0, 3);
            Else If @QuestionCode = 'SAFE_SHORT'
                Insert Into dbo.LMS_QuestionAnswerKeys(QuestionId, AnswerText, IsCaseSensitive, SortOrder)
                Values (@QuestionID, N'PHÂN QUYỀN', 0, 1), (@QuestionID, N'PHAN QUYEN', 0, 2);
        End;

        If Not Exists
        (
            Select
                1
            From dbo.LMS_ContentInteractions
            Where (InteractiveContentID = @InteractiveContentID)
                And (QuestionID = @QuestionID)
                And (IsDeleted = 0)
        )
            Insert Into dbo.LMS_ContentInteractions
            (
                InteractiveContentID,
                QuestionID,
                Required,
                AllowRetry,
                Score,
                AttemptLimit,
                SortOrder,
                Status,
                CreatedByUserID
            )
            Values (@InteractiveContentID, @QuestionID, Case When @SortOrder <= 4 Then 1 Else 0 End, 1, @Score, 2, @SortOrder, 'ACTIVE', @TeacherUserID);

        Set @QuestionID = Null;
        Fetch Next From QuestionCursor Into @QuestionCode, @QuestionType, @QuestionText, @Explanation, @Score, @SortOrder;
    End;

    Close QuestionCursor;
    Deallocate QuestionCursor;
End;
Go
