Create Or Alter Procedure dbo.LMS_Question_GetList
    @Search Nvarchar(500) = Null,
    @Type Varchar(50) = Null,
    @Page Int = 1,
    @PageSize Int = 20
As
Begin
    Set Nocount On;

    Declare @SearchPattern Nvarchar(1010) = N'%' + Replace(Replace(Replace(Isnull(@Search, N''), N'[', N'[[]'), N'%', N'[%]'), N'_', N'[_]') + N'%';

    Select
        dbo.Questions.Id,
        dbo.Questions.QuestionType,
        dbo.Questions.QuestionText,
        dbo.Questions.Difficulty,
        dbo.Questions.DefaultScore,
        dbo.Questions.Status,
        dbo.Users.FullName CreatedBy,
        dbo.Questions.CreatedAt,
        (Select Count(*) From dbo.VideoInteractions Where (dbo.VideoInteractions.QuestionId = dbo.Questions.Id) And (dbo.VideoInteractions.IsDeleted = 0)) UsedCount
    From dbo.Questions
    Inner Join dbo.Users On dbo.Users.Id = dbo.Questions.CreatedBy
    Where (dbo.Questions.IsDeleted = 0)
        And (@Type Is Null Or @Type = '' Or dbo.Questions.QuestionType = @Type)
        And (@Search Is Null Or @Search = '' Or dbo.Questions.QuestionText Like @SearchPattern)
    Order By dbo.Questions.CreatedAt Desc
    Offset (@Page - 1) * @PageSize Rows
    Fetch Next @PageSize Rows Only;

    Select
        Count(*)
    From dbo.Questions
    Where (dbo.Questions.IsDeleted = 0)
        And (@Type Is Null Or @Type = '' Or dbo.Questions.QuestionType = @Type)
        And (@Search Is Null Or @Search = '' Or dbo.Questions.QuestionText Like @SearchPattern);
End
Go

Create Or Alter Procedure dbo.LMS_Question_GetById
    @Id Bigint
As
Begin
    Set Nocount On;

    Select
        Id,
        QuestionType,
        QuestionText,
        Description,
        Explanation,
        Difficulty,
        DefaultScore,
        ShortAnswerMode,
        CreatedBy,
        CreatedAt,
        UpdatedAt,
        Status
    From dbo.Questions
    Where (Id = @Id)
        And (IsDeleted = 0);

    Select
        Id,
        QuestionId,
        OptionCode,
        OptionText,
        IsCorrect,
        SortOrder
    From dbo.QuestionOptions
    Where (QuestionId = @Id)
        And (IsDeleted = 0)
    Order By SortOrder;

    Select
        Id,
        QuestionId,
        AnswerText,
        IsCaseSensitive,
        SortOrder
    From dbo.QuestionAnswerKeys
    Where (QuestionId = @Id)
    Order By SortOrder;
End
Go

Create Or Alter Procedure dbo.LMS_Question_Create
    @Id Bigint = Null,
    @QuestionType Varchar(50),
    @QuestionText Nvarchar(Max),
    @Description Nvarchar(Max) = Null,
    @Explanation Nvarchar(Max) = Null,
    @Difficulty Varchar(30),
    @DefaultScore Decimal(8, 2),
    @ShortAnswerMode Varchar(30) = Null,
    @Status Varchar(30),
    @ActorId Bigint
As
Begin
    Set Nocount On;

    If @QuestionType Not In ('SINGLE_CHOICE', 'MULTIPLE_CHOICE', 'TRUE_FALSE', 'SHORT_ANSWER')
        Or Nullif(Ltrim(Rtrim(@QuestionText)), '') Is Null
        Or @DefaultScore < 0
        Throw 50001, N'Dữ liệu câu hỏi không hợp lệ.', 1;

    Insert dbo.Questions
    (
        QuestionType,
        QuestionText,
        Description,
        Explanation,
        Difficulty,
        DefaultScore,
        ShortAnswerMode,
        CreatedBy,
        Status
    )
    Values
    (
        @QuestionType,
        @QuestionText,
        @Description,
        @Explanation,
        @Difficulty,
        @DefaultScore,
        @ShortAnswerMode,
        @ActorId,
        @Status
    );

    Declare @QuestionId Bigint = Scope_identity();

    Insert dbo.AuditLogs
    (
        UserId,
        Action,
        Module,
        EntityName,
        EntityId
    )
    Values
    (
        @ActorId,
        'CREATE',
        'QUESTION',
        'Question',
        Convert(Nvarchar(100), @QuestionId)
    );

    Select
        @QuestionId;
End
Go

Create Or Alter Procedure dbo.LMS_Question_Update
    @Id Bigint,
    @QuestionType Varchar(50),
    @QuestionText Nvarchar(Max),
    @Description Nvarchar(Max) = Null,
    @Explanation Nvarchar(Max) = Null,
    @Difficulty Varchar(30),
    @DefaultScore Decimal(8, 2),
    @ShortAnswerMode Varchar(30) = Null,
    @Status Varchar(30),
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    If @QuestionType Not In ('SINGLE_CHOICE', 'MULTIPLE_CHOICE', 'TRUE_FALSE', 'SHORT_ANSWER')
        Or Nullif(Ltrim(Rtrim(@QuestionText)), '') Is Null
        Or @DefaultScore < 0
        Throw 50001, N'Dữ liệu câu hỏi không hợp lệ.', 1;

    Update dbo.Questions
    Set QuestionType = @QuestionType,
        QuestionText = @QuestionText,
        Description = @Description,
        Explanation = @Explanation,
        Difficulty = @Difficulty,
        DefaultScore = @DefaultScore,
        ShortAnswerMode = @ShortAnswerMode,
        Status = @Status,
        UpdatedAt = Sysutcdatetime()
    Where (Id = @Id)
        And (IsDeleted = 0)
        And (@IsAdmin = 1 Or CreatedBy = @ActorId);

    If @@Rowcount = 0
        Throw 50003, N'Không tìm thấy câu hỏi hoặc bạn không có quyền sửa.', 1;

    Insert dbo.AuditLogs
    (
        UserId,
        Action,
        Module,
        EntityName,
        EntityId
    )
    Values
    (
        @ActorId,
        'UPDATE',
        'QUESTION',
        'Question',
        Convert(Nvarchar(100), @Id)
    );

    Select
        @Id;
End
Go

Create Or Alter Procedure dbo.LMS_QuestionAnswers_DeleteByQuestion
    @QuestionId Bigint
As
Begin
    Set Nocount On;

    Update dbo.QuestionOptions
    Set IsDeleted = 1
    Where (QuestionId = @QuestionId);

    Delete From dbo.QuestionAnswerKeys
    Where (QuestionId = @QuestionId);
End
Go

Create Or Alter Procedure dbo.LMS_QuestionOption_Create
    @QuestionId Bigint,
    @OptionCode Nvarchar(20),
    @OptionText Nvarchar(2000),
    @IsCorrect Bit,
    @SortOrder Int
As
Begin
    Set Nocount On;

    If Nullif(Ltrim(Rtrim(@OptionCode)), '') Is Null
        Or Nullif(Ltrim(Rtrim(@OptionText)), '') Is Null
        Throw 50001, N'Phương án trả lời không hợp lệ.', 1;

    Set @OptionCode = Upper(Ltrim(Rtrim(@OptionCode)));

    If Exists
    (
        Select
            1
        From dbo.QuestionOptions
        Where (QuestionId = @QuestionId)
            And (OptionCode = @OptionCode)
    )
        Update dbo.QuestionOptions
        Set OptionText = @OptionText,
            IsCorrect = @IsCorrect,
            SortOrder = @SortOrder,
            IsDeleted = 0
        Where (QuestionId = @QuestionId)
            And (OptionCode = @OptionCode);
    Else
        Insert dbo.QuestionOptions
        (
            QuestionId,
            OptionCode,
            OptionText,
            IsCorrect,
            SortOrder,
            IsDeleted
        )
        Values
        (
            @QuestionId,
            @OptionCode,
            @OptionText,
            @IsCorrect,
            @SortOrder,
            0
        );
End
Go

Create Or Alter Procedure dbo.LMS_QuestionAnswerKey_Create
    @QuestionId Bigint,
    @AnswerText Nvarchar(2000),
    @IsCaseSensitive Bit,
    @SortOrder Int
As
Begin
    Set Nocount On;

    If Nullif(Ltrim(Rtrim(@AnswerText)), '') Is Null
        Throw 50001, N'Đáp án mẫu không hợp lệ.', 1;

    Insert dbo.QuestionAnswerKeys
    (
        QuestionId,
        AnswerText,
        IsCaseSensitive,
        SortOrder
    )
    Values
    (
        @QuestionId,
        @AnswerText,
        @IsCaseSensitive,
        @SortOrder
    );
End
Go

Create Or Alter Procedure dbo.LMS_Question_Delete
    @Id Bigint,
    @ActorId Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Update dbo.Questions
    Set IsDeleted = 1,
        UpdatedAt = Sysutcdatetime()
    Where (Id = @Id)
        And (IsDeleted = 0)
        And (@IsAdmin = 1 Or CreatedBy = @ActorId);

    Declare @Rows Int = @@Rowcount;

    If @Rows = 0
        Throw 50003, N'Không tìm thấy câu hỏi hoặc bạn không có quyền xóa.', 1;

    If @Rows > 0
    Begin
        Update dbo.VideoInteractions
        Set IsDeleted = 1,
            UpdatedAt = Sysutcdatetime()
        Where (QuestionId = @Id)
            And (IsDeleted = 0);

        Insert dbo.AuditLogs
        (
            UserId,
            Action,
            Module,
            EntityName,
            EntityId
        )
        Values
        (
            @ActorId,
            'DELETE',
            'QUESTION',
            'Question',
            Convert(Nvarchar(100), @Id)
        );
    End

    Select
        @Rows;
End
Go
