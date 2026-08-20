Set Nocount On;
Set Xact_abort On;
Go

Declare @LessonID Bigint = 62,
    @CourseID Bigint = 3,
    @StudentUserID Bigint = 3,
    @TeacherUserID Bigint = 4,
    @RootCommentID Bigint,
    @ReplyCommentID Bigint;

If Exists
(
    Select
        1
    From dbo.SIM_Lessons
    Where (dbo.SIM_Lessons.LessonID = @LessonID)
        And (dbo.SIM_Lessons.CourseID = @CourseID)
)
    And Not Exists
    (
        Select
            1
        From dbo.LMS_LessonComments
        Where (dbo.LMS_LessonComments.LessonID = @LessonID)
            And (dbo.LMS_LessonComments.Content = N'[DỮ LIỆU MẪU] Em cần làm rõ định dạng và nội dung bắt buộc của file nộp bài ạ.')
    )
Begin
    Insert Into dbo.LMS_LessonComments
    (
        CourseID,
        LessonID,
        UserID,
        Content,
        CreatedDate
    )
    Values
    (
        @CourseID,
        @LessonID,
        @StudentUserID,
        N'[DỮ LIỆU MẪU] Em cần làm rõ định dạng và nội dung bắt buộc của file nộp bài ạ.',
        Dateadd(Minute, -35, Sysutcdatetime())
    );

    Set @RootCommentID = Scope_identity();

    Insert Into dbo.LMS_LessonComments
    (
        CourseID,
        LessonID,
        UserID,
        ParentCommentID,
        Content,
        CreatedDate
    )
    Values
    (
        @CourseID,
        @LessonID,
        @TeacherUserID,
        @RootCommentID,
        N'Em nộp file PDF, trình bày đủ các mục trong yêu cầu bài tập. Nếu có file thiết kế gốc thì đính kèm thêm nhé.',
        Dateadd(Minute, -28, Sysutcdatetime())
    );

    Set @ReplyCommentID = Scope_identity();

    Insert Into dbo.LMS_LessonComments
    (
        CourseID,
        LessonID,
        UserID,
        ParentCommentID,
        Content,
        CreatedDate
    )
    Values
    (
        @CourseID,
        @LessonID,
        @StudentUserID,
        @ReplyCommentID,
        N'Dạ em đã rõ, em sẽ nộp PDF và kèm file nguồn.',
        Dateadd(Minute, -20, Sysutcdatetime())
    );

    Insert Into dbo.LMS_LessonComments
    (
        CourseID,
        LessonID,
        UserID,
        Content,
        CreatedDate
    )
    Values
    (
        @CourseID,
        @LessonID,
        6,
        N'Thầy cô cho em hỏi bài này có giới hạn số trang không ạ?',
        Dateadd(Minute, -12, Sysutcdatetime())
    );
End;
Go
