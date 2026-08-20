Set Nocount On;
Set Xact_abort On;

If Object_id(N'dbo.LMS_Quizzes', N'U') Is Null
Begin
    Create Table dbo.LMS_Quizzes
    (
        QuizID Bigint Identity(1, 1) Not Null,
        LessonID Bigint Not Null,
        Title Nvarchar(500) Not Null,
        Description Nvarchar(2000) Null,
        PassingScore Decimal(5, 2) Not Null Constraint DF_LMS_Quizzes_PassingScore Default (50),
        TimeLimitMinutes Int Null,
        MaxAttempts Int Not Null Constraint DF_LMS_Quizzes_MaxAttempts Default (1),
        ShuffleQuestions Bit Not Null Constraint DF_LMS_Quizzes_ShuffleQuestions Default (0),
        Status Varchar(30) Not Null Constraint DF_LMS_Quizzes_Status Default ('ACTIVE'),
        CreatedByUserID Bigint Not Null,
        CreatedAt Datetime2 Not Null Constraint DF_LMS_Quizzes_CreatedAt Default (Sysutcdatetime()),
        UpdatedAt Datetime2 Null,
        Constraint PK_LMS_Quizzes Primary Key (QuizID),
        Constraint UQ_LMS_Quizzes_LessonID Unique (LessonID),
        Constraint FK_LMS_Quizzes_Lesson Foreign Key (LessonID) References dbo.SIM_Lessons(LessonID),
        Constraint FK_LMS_Quizzes_CreatedBy Foreign Key (CreatedByUserID) References dbo.SYS_Users(UserID),
        Constraint CK_LMS_Quizzes_PassingScore Check (PassingScore Between 0 And 100),
        Constraint CK_LMS_Quizzes_MaxAttempts Check (MaxAttempts Between 1 And 20),
        Constraint CK_LMS_Quizzes_Status Check (Status In ('ACTIVE', 'INACTIVE'))
    );
End;

If Object_id(N'dbo.LMS_QuizQuestions', N'U') Is Null
Begin
    Create Table dbo.LMS_QuizQuestions
    (
        QuizQuestionID Bigint Identity(1, 1) Not Null,
        QuizID Bigint Not Null,
        QuestionID Bigint Not Null,
        Score Decimal(8, 2) Not Null,
        SortOrder Int Not Null,
        IsRequired Bit Not Null Constraint DF_LMS_QuizQuestions_IsRequired Default (1),
        Constraint PK_LMS_QuizQuestions Primary Key (QuizQuestionID),
        Constraint UQ_LMS_QuizQuestions_QuizQuestion Unique (QuizID, QuestionID),
        Constraint FK_LMS_QuizQuestions_Quiz Foreign Key (QuizID) References dbo.LMS_Quizzes(QuizID),
        Constraint FK_LMS_QuizQuestions_Question Foreign Key (QuestionID) References dbo.LMS_Questions(QuestionID),
        Constraint CK_LMS_QuizQuestions_Score Check (Score > 0),
        Constraint CK_LMS_QuizQuestions_SortOrder Check (SortOrder > 0)
    );

    Create Index IX_LMS_QuizQuestions_QuizID On dbo.LMS_QuizQuestions(QuizID, SortOrder);
End;

If Object_id(N'dbo.LMS_QuizAttempts', N'U') Is Null
Begin
    Create Table dbo.LMS_QuizAttempts
    (
        QuizAttemptID Bigint Identity(1, 1) Not Null,
        QuizID Bigint Not Null,
        StudentUserID Bigint Not Null,
        AttemptNumber Int Not Null,
        StartedAt Datetime2 Not Null Constraint DF_LMS_QuizAttempts_StartedAt Default (Sysutcdatetime()),
        SubmittedAt Datetime2 Null,
        Score Decimal(8, 2) Null,
        MaxScore Decimal(8, 2) Null,
        ScorePercent Decimal(5, 2) Null,
        Passed Bit Null,
        AttemptStatus Varchar(30) Not Null Constraint DF_LMS_QuizAttempts_Status Default ('IN_PROGRESS'),
        Constraint PK_LMS_QuizAttempts Primary Key (QuizAttemptID),
        Constraint UQ_LMS_QuizAttempts_QuizStudentAttempt Unique (QuizID, StudentUserID, AttemptNumber),
        Constraint FK_LMS_QuizAttempts_Quiz Foreign Key (QuizID) References dbo.LMS_Quizzes(QuizID),
        Constraint FK_LMS_QuizAttempts_Student Foreign Key (StudentUserID) References dbo.SYS_Users(UserID),
        Constraint CK_LMS_QuizAttempts_Status Check (AttemptStatus In ('IN_PROGRESS', 'SUBMITTED'))
    );

    Create Index IX_LMS_QuizAttempts_StudentQuiz On dbo.LMS_QuizAttempts(StudentUserID, QuizID, AttemptNumber Desc);
End;

If Object_id(N'dbo.LMS_QuizAttemptAnswers', N'U') Is Null
Begin
    Create Table dbo.LMS_QuizAttemptAnswers
    (
        QuizAttemptAnswerID Bigint Identity(1, 1) Not Null,
        QuizAttemptID Bigint Not Null,
        QuestionID Bigint Not Null,
        AnswerText Nvarchar(Max) Null,
        IsCorrect Bit Null,
        ScoreAwarded Decimal(8, 2) Not Null Constraint DF_LMS_QuizAttemptAnswers_Score Default (0),
        AnsweredAt Datetime2 Not Null Constraint DF_LMS_QuizAttemptAnswers_AnsweredAt Default (Sysutcdatetime()),
        Constraint PK_LMS_QuizAttemptAnswers Primary Key (QuizAttemptAnswerID),
        Constraint UQ_LMS_QuizAttemptAnswers_AttemptQuestion Unique (QuizAttemptID, QuestionID),
        Constraint FK_LMS_QuizAttemptAnswers_Attempt Foreign Key (QuizAttemptID) References dbo.LMS_QuizAttempts(QuizAttemptID),
        Constraint FK_LMS_QuizAttemptAnswers_Question Foreign Key (QuestionID) References dbo.LMS_Questions(QuestionID)
    );
End;

Declare @ActorID Bigint = Coalesce((Select Top (1) UserID From dbo.SYS_Users Where Username = N'admin' And IsDeleted = 0), 1);

Insert dbo.LMS_Quizzes
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
    Coalesce(dbo.SIM_Lessons.Description, N'Bài kiểm tra kiến thức của bài học.'),
    Coalesce(dbo.SIM_Lessons.PassingScore, 50),
    30,
    2,
    0,
    'ACTIVE',
    @ActorID
From dbo.SIM_Lessons
Where (dbo.SIM_Lessons.LessonType = 'QUIZ')
    And (dbo.SIM_Lessons.IsDeleted = 0)
    And Not Exists
    (
        Select 1
        From dbo.LMS_Quizzes
        Where (dbo.LMS_Quizzes.LessonID = dbo.SIM_Lessons.LessonID)
    );

Insert dbo.LMS_QuizQuestions
(
    QuizID,
    QuestionID,
    Score,
    SortOrder,
    IsRequired
)
Select
    QuizSource.QuizID,
    QuestionSource.QuestionID,
    Coalesce(QuestionSource.DefaultScore, 10),
    QuestionSource.SortOrder,
    1
From
(
    Select
        dbo.LMS_Quizzes.QuizID
    From dbo.LMS_Quizzes
        Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.LessonID = dbo.LMS_Quizzes.LessonID
    Where (dbo.SIM_Lessons.LessonType = 'QUIZ')
) QuizSource
Cross Apply
(
    Select Top (5)
        dbo.LMS_Questions.QuestionID,
        dbo.LMS_Questions.DefaultScore,
        Row_number() Over (Order By dbo.LMS_Questions.QuestionID) SortOrder
    From dbo.LMS_Questions
    Where (dbo.LMS_Questions.Status = 'ACTIVE')
        And (dbo.LMS_Questions.IsDeleted = 0)
    Order By dbo.LMS_Questions.QuestionID
) QuestionSource
Where Not Exists
(
    Select 1
    From dbo.LMS_QuizQuestions
    Where (dbo.LMS_QuizQuestions.QuizID = QuizSource.QuizID)
        And (dbo.LMS_QuizQuestions.QuestionID = QuestionSource.QuestionID)
);

Declare @Descriptions Table
(
    TableName Sysname,
    ColumnName Sysname Null,
    DescriptionValue Nvarchar(1000)
);

Insert @Descriptions(TableName, ColumnName, DescriptionValue)
Values
    (N'LMS_Quizzes', Null, N'[LMS] Cấu hình bài kiểm tra gắn một-một với bài học loại QUIZ.'),
    (N'LMS_Quizzes', N'QuizID', N'Khóa chính bài kiểm tra.'),
    (N'LMS_Quizzes', N'LessonID', N'Bài học loại QUIZ sở hữu bài kiểm tra.'),
    (N'LMS_Quizzes', N'Title', N'Tên bài kiểm tra hiển thị cho giáo viên và học viên.'),
    (N'LMS_Quizzes', N'Description', N'Mô tả hoặc hướng dẫn làm bài kiểm tra.'),
    (N'LMS_Quizzes', N'PassingScore', N'Phần trăm điểm tối thiểu để đạt.'),
    (N'LMS_Quizzes', N'TimeLimitMinutes', N'Thời gian làm bài tối đa; rỗng nghĩa là không giới hạn.'),
    (N'LMS_Quizzes', N'MaxAttempts', N'Số lượt làm tối đa của mỗi học viên.'),
    (N'LMS_Quizzes', N'ShuffleQuestions', N'Cờ đảo thứ tự câu hỏi khi tải đề.'),
    (N'LMS_Quizzes', N'Status', N'Trạng thái hoạt động của bài kiểm tra.'),
    (N'LMS_Quizzes', N'CreatedByUserID', N'Tài khoản tạo cấu hình bài kiểm tra.'),
    (N'LMS_Quizzes', N'CreatedAt', N'Thời điểm tạo theo UTC.'),
    (N'LMS_Quizzes', N'UpdatedAt', N'Thời điểm cập nhật gần nhất theo UTC.'),
    (N'LMS_QuizQuestions', Null, N'[LMS] Danh sách câu hỏi và số điểm trong một bài kiểm tra.'),
    (N'LMS_QuizQuestions', N'QuizQuestionID', N'Khóa chính dòng câu hỏi của bài kiểm tra.'),
    (N'LMS_QuizQuestions', N'QuizID', N'Bài kiểm tra sở hữu câu hỏi.'),
    (N'LMS_QuizQuestions', N'QuestionID', N'Câu hỏi tham chiếu từ ngân hàng câu hỏi.'),
    (N'LMS_QuizQuestions', N'Score', N'Điểm tối đa của câu hỏi trong bài kiểm tra.'),
    (N'LMS_QuizQuestions', N'SortOrder', N'Thứ tự câu hỏi khi không bật đảo câu.'),
    (N'LMS_QuizQuestions', N'IsRequired', N'Cờ câu hỏi bắt buộc trả lời.'),
    (N'LMS_QuizAttempts', Null, N'[LMS] Mỗi lượt học viên bắt đầu và nộp bài kiểm tra.'),
    (N'LMS_QuizAttempts', N'QuizAttemptID', N'Khóa chính lượt làm bài kiểm tra.'),
    (N'LMS_QuizAttempts', N'QuizID', N'Bài kiểm tra được thực hiện.'),
    (N'LMS_QuizAttempts', N'StudentUserID', N'Tài khoản học viên thực hiện lượt làm.'),
    (N'LMS_QuizAttempts', N'AttemptNumber', N'Số thứ tự lượt làm của học viên.'),
    (N'LMS_QuizAttempts', N'StartedAt', N'Thời điểm bắt đầu lượt làm theo UTC.'),
    (N'LMS_QuizAttempts', N'SubmittedAt', N'Thời điểm nộp lượt làm theo UTC.'),
    (N'LMS_QuizAttempts', N'Score', N'Tổng điểm học viên đạt trong lượt làm.'),
    (N'LMS_QuizAttempts', N'MaxScore', N'Tổng điểm tối đa của đề tại lúc nộp.'),
    (N'LMS_QuizAttempts', N'ScorePercent', N'Phần trăm điểm sau khi backend chấm.'),
    (N'LMS_QuizAttempts', N'Passed', N'Kết quả đạt hoặc chưa đạt theo điểm chuẩn.'),
    (N'LMS_QuizAttempts', N'AttemptStatus', N'Trạng thái đang làm hoặc đã nộp.'),
    (N'LMS_QuizAttemptAnswers', Null, N'[LMS] Câu trả lời và điểm backend chấm cho từng câu trong một lượt quiz.'),
    (N'LMS_QuizAttemptAnswers', N'QuizAttemptAnswerID', N'Khóa chính câu trả lời trong lượt quiz.'),
    (N'LMS_QuizAttemptAnswers', N'QuizAttemptID', N'Lượt quiz sở hữu câu trả lời.'),
    (N'LMS_QuizAttemptAnswers', N'QuestionID', N'Câu hỏi được trả lời.'),
    (N'LMS_QuizAttemptAnswers', N'AnswerText', N'Nội dung hoặc mã phương án học viên đã chọn; không chứa đáp án đúng.'),
    (N'LMS_QuizAttemptAnswers', N'IsCorrect', N'Kết quả đúng sai do backend xác định.'),
    (N'LMS_QuizAttemptAnswers', N'ScoreAwarded', N'Điểm backend trao cho câu trả lời.'),
    (N'LMS_QuizAttemptAnswers', N'AnsweredAt', N'Thời điểm backend ghi nhận câu trả lời theo UTC.');

Declare @TableName Sysname;
Declare @ColumnName Sysname;
Declare @DescriptionValue Nvarchar(1000);

Declare DescriptionCursor Cursor Local Fast_forward For
    Select TableName, ColumnName, DescriptionValue From @Descriptions;

Open DescriptionCursor;
Fetch Next From DescriptionCursor Into @TableName, @ColumnName, @DescriptionValue;

While @@Fetch_status = 0
Begin
    If @ColumnName Is Null And Not Exists (Select 1 From sys.extended_properties Where class = 1 And major_id = Object_id(N'dbo.' + @TableName) And minor_id = 0 And name = N'MS_Description')
        Execute sys.sp_addextendedproperty @name = N'MS_Description', @value = @DescriptionValue, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = @TableName;
    Else If @ColumnName Is Not Null And Not Exists (Select 1 From sys.extended_properties Where class = 1 And major_id = Object_id(N'dbo.' + @TableName) And minor_id = Columnproperty(Object_id(N'dbo.' + @TableName), @ColumnName, 'ColumnId') And name = N'MS_Description')
        Execute sys.sp_addextendedproperty @name = N'MS_Description', @value = @DescriptionValue, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = @TableName, @level2type = N'COLUMN', @level2name = @ColumnName;

    Fetch Next From DescriptionCursor Into @TableName, @ColumnName, @DescriptionValue;
End;

Close DescriptionCursor;
Deallocate DescriptionCursor;
Go
