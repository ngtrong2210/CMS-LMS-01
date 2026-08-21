Set Nocount On;
Set Xact_abort On;
Set Quoted_identifier On;

If Object_id(N'dbo.LMS_InteractiveContents', N'U') Is Null
Begin
    Create Table dbo.LMS_InteractiveContents
    (
        InteractiveContentID Bigint Identity(1, 1) Not Null Constraint PK_LMS_InteractiveContents Primary Key,
        LessonID Bigint Not Null,
        CompletionRule Varchar(30) Not Null Constraint DF_LMS_InteractiveContents_CompletionRule Default ('REQUIRED_QUESTIONS'),
        RequireReading Bit Not Null Constraint DF_LMS_InteractiveContents_RequireReading Default (1),
        PassingScore Decimal(5, 2) Not Null Constraint DF_LMS_InteractiveContents_PassingScore Default (70),
        ShowResultImmediately Bit Not Null Constraint DF_LMS_InteractiveContents_ShowResultImmediately Default (1),
        ShowScore Bit Not Null Constraint DF_LMS_InteractiveContents_ShowScore Default (1),
        CreatedByUserID Bigint Not Null,
        CreatedAt Datetime2 Not Null Constraint DF_LMS_InteractiveContents_CreatedAt Default (Sysutcdatetime()),
        UpdatedByUserID Bigint Null,
        UpdatedAt Datetime2 Null,
        Constraint UQ_LMS_InteractiveContents_LessonID Unique (LessonID),
        Constraint FK_LMS_InteractiveContents_Lesson Foreign Key (LessonID) References dbo.SIM_Lessons(LessonID),
        Constraint FK_LMS_InteractiveContents_CreatedBy Foreign Key (CreatedByUserID) References dbo.SYS_Users(UserID),
        Constraint FK_LMS_InteractiveContents_UpdatedBy Foreign Key (UpdatedByUserID) References dbo.SYS_Users(UserID),
        Constraint CK_LMS_InteractiveContents_CompletionRule Check (CompletionRule In ('REQUIRED_QUESTIONS', 'ALL_QUESTIONS', 'PASSING_SCORE')),
        Constraint CK_LMS_InteractiveContents_PassingScore Check (PassingScore Between 0 And 100)
    );
End;
Go

If Object_id(N'dbo.LMS_ContentInteractions', N'U') Is Null
Begin
    Create Table dbo.LMS_ContentInteractions
    (
        ContentInteractionID Bigint Identity(1, 1) Not Null Constraint PK_LMS_ContentInteractions Primary Key,
        InteractiveContentID Bigint Not Null,
        QuestionID Bigint Not Null,
        ContentAnchor Nvarchar(100) Null,
        Required Bit Not Null Constraint DF_LMS_ContentInteractions_Required Default (1),
        AllowRetry Bit Not Null Constraint DF_LMS_ContentInteractions_AllowRetry Default (1),
        Score Decimal(8, 2) Not Null Constraint DF_LMS_ContentInteractions_Score Default (10),
        AttemptLimit Int Not Null Constraint DF_LMS_ContentInteractions_AttemptLimit Default (2),
        SortOrder Int Not Null,
        Status Varchar(30) Not Null Constraint DF_LMS_ContentInteractions_Status Default ('ACTIVE'),
        CreatedByUserID Bigint Not Null,
        CreatedAt Datetime2 Not Null Constraint DF_LMS_ContentInteractions_CreatedAt Default (Sysutcdatetime()),
        UpdatedByUserID Bigint Null,
        UpdatedAt Datetime2 Null,
        IsDeleted Bit Not Null Constraint DF_LMS_ContentInteractions_IsDeleted Default (0),
        Constraint FK_LMS_ContentInteractions_Content Foreign Key (InteractiveContentID) References dbo.LMS_InteractiveContents(InteractiveContentID),
        Constraint FK_LMS_ContentInteractions_Question Foreign Key (QuestionID) References dbo.LMS_Questions(QuestionID),
        Constraint FK_LMS_ContentInteractions_CreatedBy Foreign Key (CreatedByUserID) References dbo.SYS_Users(UserID),
        Constraint FK_LMS_ContentInteractions_UpdatedBy Foreign Key (UpdatedByUserID) References dbo.SYS_Users(UserID),
        Constraint CK_LMS_ContentInteractions_Score Check (Score Between 0 And 10000),
        Constraint CK_LMS_ContentInteractions_AttemptLimit Check (AttemptLimit Between 1 And 100),
        Constraint CK_LMS_ContentInteractions_SortOrder Check (SortOrder > 0),
        Constraint CK_LMS_ContentInteractions_Status Check (Status In ('ACTIVE', 'INACTIVE'))
    );

    Create Unique Index UX_LMS_ContentInteractions_Content_Question
        On dbo.LMS_ContentInteractions(InteractiveContentID, QuestionID)
        Where IsDeleted = 0;

    Create Index IX_LMS_ContentInteractions_Content_Order
        On dbo.LMS_ContentInteractions(InteractiveContentID, Status, IsDeleted, SortOrder);
End;
Go

If Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.LMS_ContentInteractions') And name = N'UX_LMS_ContentInteractions_Content_Question')
    Create Unique Index UX_LMS_ContentInteractions_Content_Question On dbo.LMS_ContentInteractions(InteractiveContentID, QuestionID) Where IsDeleted = 0;
Go

If Not Exists (Select 1 From sys.indexes Where object_id = Object_id(N'dbo.LMS_ContentInteractions') And name = N'IX_LMS_ContentInteractions_Content_Order')
    Create Index IX_LMS_ContentInteractions_Content_Order On dbo.LMS_ContentInteractions(InteractiveContentID, Status, IsDeleted, SortOrder);
Go

If Col_length(N'dbo.LMS_StudentAnswers', N'ContentInteractionID') Is Null
Begin
    Alter Table dbo.LMS_StudentAnswers Add ContentInteractionID Bigint Null;
    Alter Table dbo.LMS_StudentAnswers Add Constraint FK_LMS_StudentAnswers_ContentInteraction Foreign Key (ContentInteractionID) References dbo.LMS_ContentInteractions(ContentInteractionID);
    Create Index IX_LMS_StudentAnswers_ContentInteraction On dbo.LMS_StudentAnswers(StudentUserID, LessonId, ContentInteractionID, AttemptNumber Desc);
End;
Go

If Col_length(N'dbo.LMS_StudentLessonProgress', N'ReadingProgressPercent') Is Null
    Alter Table dbo.LMS_StudentLessonProgress Add ReadingProgressPercent Decimal(5, 2) Not Null Constraint DF_LMS_StudentLessonProgress_ReadingProgress Default (0);
Go

If Col_length(N'dbo.LMS_StudentLessonProgress', N'LastScrollPercent') Is Null
    Alter Table dbo.LMS_StudentLessonProgress Add LastScrollPercent Decimal(5, 2) Not Null Constraint DF_LMS_StudentLessonProgress_LastScroll Default (0);
Go

Declare @LessonTypeConstraint Sysname;
Select
    @LessonTypeConstraint = CheckConstraint.name
From sys.check_constraints As CheckConstraint
Inner Join sys.columns As TableColumn On TableColumn.object_id = CheckConstraint.parent_object_id
Where (CheckConstraint.parent_object_id = Object_id(N'dbo.SIM_Lessons'))
    And (TableColumn.name = N'LessonType')
    And (CheckConstraint.definition Like N'%LessonType%');

If @LessonTypeConstraint Is Not Null
Begin
    Declare @DropLessonTypeConstraintSql Nvarchar(Max) = N'Alter Table dbo.SIM_Lessons Drop Constraint ' + Quotename(@LessonTypeConstraint) + N';';
    Exec sys.sp_executesql @DropLessonTypeConstraintSql;
End;

Alter Table dbo.SIM_Lessons With Check Add Constraint CK_SIM_Lessons_LessonType Check
(
    LessonType In ('VIDEO', 'INTERACTIVE_VIDEO', 'QUIZ', 'DOCUMENT', 'EDITOR', 'ASSIGNMENT', 'INTERACTIVE_CONTENT')
);
Go

Declare @Descriptions Table
(
    TableName Sysname,
    ColumnName Sysname Null,
    DescriptionText Nvarchar(1000)
);

Insert Into @Descriptions(TableName, ColumnName, DescriptionText)
Values
    (N'LMS_InteractiveContents', Null, N'Cấu hình bài học đọc hiểu có câu hỏi tương tác.'),
    (N'LMS_InteractiveContents', N'InteractiveContentID', N'Khóa chính của cấu hình bài học tương tác.'),
    (N'LMS_InteractiveContents', N'LessonID', N'Bài học loại INTERACTIVE_CONTENT được cấu hình.'),
    (N'LMS_InteractiveContents', N'CompletionRule', N'Quy tắc hoàn thành: câu bắt buộc, toàn bộ câu hỏi hoặc đạt điểm.'),
    (N'LMS_InteractiveContents', N'RequireReading', N'Yêu cầu học viên đọc hết nội dung trước khi hoàn thành.'),
    (N'LMS_InteractiveContents', N'PassingScore', N'Phần trăm điểm tối thiểu khi dùng quy tắc PASSING_SCORE.'),
    (N'LMS_InteractiveContents', N'ShowResultImmediately', N'Cho phép trả kết quả đúng sai và giải thích ngay sau khi trả lời.'),
    (N'LMS_InteractiveContents', N'ShowScore', N'Cho phép học viên xem điểm của bài.'),
    (N'LMS_InteractiveContents', N'CreatedByUserID', N'Người dùng đã tạo cấu hình bài học tương tác.'),
    (N'LMS_InteractiveContents', N'CreatedAt', N'Thời điểm tạo cấu hình theo UTC.'),
    (N'LMS_InteractiveContents', N'UpdatedByUserID', N'Người dùng cập nhật cấu hình gần nhất.'),
    (N'LMS_InteractiveContents', N'UpdatedAt', N'Thời điểm cập nhật cấu hình gần nhất theo UTC.'),
    (N'LMS_ContentInteractions', Null, N'Liên kết câu hỏi dùng chung với một bài học tương tác.'),
    (N'LMS_ContentInteractions', N'ContentInteractionID', N'Khóa chính của câu hỏi trong bài học tương tác.'),
    (N'LMS_ContentInteractions', N'InteractiveContentID', N'Cấu hình bài học tương tác sở hữu câu hỏi.'),
    (N'LMS_ContentInteractions', N'QuestionID', N'Câu hỏi dùng lại từ ngân hàng LMS_Questions.'),
    (N'LMS_ContentInteractions', N'ContentAnchor', N'Điểm neo tùy chọn để liên hệ câu hỏi với một phần nội dung.'),
    (N'LMS_ContentInteractions', N'Required', N'Đánh dấu câu hỏi bắt buộc.'),
    (N'LMS_ContentInteractions', N'AllowRetry', N'Cho phép học viên thử lại khi chưa đạt.'),
    (N'LMS_ContentInteractions', N'Score', N'Điểm tối đa của câu hỏi trong bài.'),
    (N'LMS_ContentInteractions', N'AttemptLimit', N'Số lần trả lời tối đa.'),
    (N'LMS_ContentInteractions', N'SortOrder', N'Thứ tự hiển thị câu hỏi.'),
    (N'LMS_ContentInteractions', N'Status', N'Trạng thái sử dụng của câu hỏi trong bài học.'),
    (N'LMS_ContentInteractions', N'CreatedByUserID', N'Người dùng đã gắn câu hỏi vào bài học.'),
    (N'LMS_ContentInteractions', N'CreatedAt', N'Thời điểm gắn câu hỏi theo UTC.'),
    (N'LMS_ContentInteractions', N'UpdatedByUserID', N'Người dùng cập nhật liên kết câu hỏi gần nhất.'),
    (N'LMS_ContentInteractions', N'UpdatedAt', N'Thời điểm cập nhật liên kết câu hỏi gần nhất theo UTC.'),
    (N'LMS_ContentInteractions', N'IsDeleted', N'Cờ xóa mềm của câu hỏi trong bài học.'),
    (N'LMS_StudentAnswers', N'ContentInteractionID', N'Câu hỏi bài đọc tương tác tương ứng; rỗng đối với video hoặc quiz.'),
    (N'LMS_StudentLessonProgress', N'ReadingProgressPercent', N'Phần trăm nội dung học viên đã đọc.'),
    (N'LMS_StudentLessonProgress', N'LastScrollPercent', N'Vị trí cuộn gần nhất để khôi phục khi học tiếp.');

Declare @TableName Sysname;
Declare @ColumnName Sysname;
Declare @DescriptionText Nvarchar(1000);

Declare DescriptionCursor Cursor Local Fast_forward For
Select
    TableName,
    ColumnName,
    DescriptionText
From @Descriptions;

Open DescriptionCursor;
Fetch Next From DescriptionCursor Into @TableName, @ColumnName, @DescriptionText;

While @@Fetch_status = 0
Begin
    If @ColumnName Is Null
    Begin
        If Exists (Select 1 From sys.extended_properties Where major_id = Object_id(N'dbo.' + @TableName) And minor_id = 0 And name = N'MS_Description')
            Exec sys.sp_updateextendedproperty @name = N'MS_Description', @value = @DescriptionText, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = @TableName;
        Else
            Exec sys.sp_addextendedproperty @name = N'MS_Description', @value = @DescriptionText, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = @TableName;
    End
    Else
    Begin
        If Exists (Select 1 From sys.extended_properties Where major_id = Object_id(N'dbo.' + @TableName) And minor_id = Columnproperty(Object_id(N'dbo.' + @TableName), @ColumnName, 'ColumnId') And name = N'MS_Description')
            Exec sys.sp_updateextendedproperty @name = N'MS_Description', @value = @DescriptionText, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = @TableName, @level2type = N'COLUMN', @level2name = @ColumnName;
        Else
            Exec sys.sp_addextendedproperty @name = N'MS_Description', @value = @DescriptionText, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = @TableName, @level2type = N'COLUMN', @level2name = @ColumnName;
    End;

    Fetch Next From DescriptionCursor Into @TableName, @ColumnName, @DescriptionText;
End;

Close DescriptionCursor;
Deallocate DescriptionCursor;
Go
