Set Ansi_nulls On;
Set Quoted_identifier On;
Set Xact_abort On;
Go

If Object_id(N'dbo.LMS_LessonComments', N'U') Is Null
Begin
    Create Table dbo.LMS_LessonComments
    (
        LessonCommentID Bigint Identity(1, 1) Not Null,
        CourseID Bigint Not Null,
        LessonID Bigint Not Null,
        UserID Bigint Not Null,
        ParentCommentID Bigint Null,
        Content Nvarchar(Max) Not Null,
        IsEdited Bit Not Null Constraint DF_LMS_LessonComments_IsEdited Default (0),
        CreatedDate Datetime2(0) Not Null Constraint DF_LMS_LessonComments_CreatedDate Default (Sysutcdatetime()),
        UpdatedDate Datetime2(0) Null,
        IsDeleted Bit Not Null Constraint DF_LMS_LessonComments_IsDeleted Default (0),
        DeletedDate Datetime2(0) Null,
        DeletedUserID Bigint Null,
        Constraint PK_LMS_LessonComments Primary Key Clustered (LessonCommentID),
        Constraint FK_LMS_LessonComments_SIM_Courses Foreign Key (CourseID) References dbo.SIM_Courses(CourseID),
        Constraint FK_LMS_LessonComments_SIM_Lessons Foreign Key (LessonID) References dbo.SIM_Lessons(LessonID),
        Constraint FK_LMS_LessonComments_SYS_Users Foreign Key (UserID) References dbo.SYS_Users(UserID),
        Constraint FK_LMS_LessonComments_Parent Foreign Key (ParentCommentID) References dbo.LMS_LessonComments(LessonCommentID),
        Constraint FK_LMS_LessonComments_DeletedUser Foreign Key (DeletedUserID) References dbo.SYS_Users(UserID),
        Constraint CK_LMS_LessonComments_Content Check (Len(Ltrim(Rtrim(Content))) Between 1 And 5000)
    );
End;
Go

If Not Exists
(
    Select
        1
    From sys.indexes
    Where (object_id = Object_id(N'dbo.LMS_LessonComments'))
        And (name = N'IX_LMS_LessonComments_Lesson_CreatedDate')
)
    Create Index IX_LMS_LessonComments_Lesson_CreatedDate On dbo.LMS_LessonComments(LessonID, IsDeleted, CreatedDate Desc) Include (ParentCommentID, UserID, CourseID);
Go

If Not Exists
(
    Select
        1
    From sys.indexes
    Where (object_id = Object_id(N'dbo.LMS_LessonComments'))
        And (name = N'IX_LMS_LessonComments_ParentCommentID')
)
    Create Index IX_LMS_LessonComments_ParentCommentID On dbo.LMS_LessonComments(ParentCommentID, CreatedDate) Include (LessonID, UserID, IsDeleted);
Go

If Not Exists
(
    Select
        1
    From sys.indexes
    Where (object_id = Object_id(N'dbo.LMS_LessonComments'))
        And (name = N'IX_LMS_LessonComments_UserID')
)
    Create Index IX_LMS_LessonComments_UserID On dbo.LMS_LessonComments(UserID, CreatedDate Desc) Include (LessonID, IsDeleted);
Go

Declare @TableDescription Nvarchar(1000) = N'[LMS] Lưu thảo luận của bài học và các câu trả lời lồng nhau bằng quan hệ tự tham chiếu.';

If Exists
(
    Select
        1
    From sys.extended_properties
    Where (class = 1)
        And (major_id = Object_id(N'dbo.LMS_LessonComments'))
        And (minor_id = 0)
        And (name = N'MS_Description')
)
    Exec sys.sp_updateextendedproperty @name = N'MS_Description', @value = @TableDescription, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'LMS_LessonComments';
Else
    Exec sys.sp_addextendedproperty @name = N'MS_Description', @value = @TableDescription, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'LMS_LessonComments';
Go

Declare @ColumnDescriptions Table
(
    ColumnName Sysname Not Null,
    ColumnDescription Nvarchar(1000) Not Null
);

Insert Into @ColumnDescriptions
(
    ColumnName,
    ColumnDescription
)
Values
    (N'LessonCommentID', N'Khóa chính tự tăng của bình luận bài học.'),
    (N'CourseID', N'Khóa học chứa bài học được bình luận.'),
    (N'LessonID', N'Bài học chứa luồng thảo luận.'),
    (N'UserID', N'Tài khoản tạo bình luận hoặc câu trả lời.'),
    (N'ParentCommentID', N'Bình luận cha; rỗng nghĩa là bình luận gốc.'),
    (N'Content', N'Nội dung bình luận dạng văn bản thuần, tối đa 5000 ký tự.'),
    (N'IsEdited', N'Đánh dấu nội dung đã được tác giả chỉnh sửa.'),
    (N'CreatedDate', N'Thời điểm UTC tạo bình luận.'),
    (N'UpdatedDate', N'Thời điểm UTC cập nhật nội dung gần nhất.'),
    (N'IsDeleted', N'Đánh dấu xóa mềm để giữ nguyên chuỗi trả lời.'),
    (N'DeletedDate', N'Thời điểm UTC xóa mềm bình luận.'),
    (N'DeletedUserID', N'Tài khoản thực hiện xóa mềm bình luận.');

Declare @ColumnName Sysname,
    @ColumnDescription Nvarchar(1000);

Declare LessonCommentDescriptionCursor Cursor Local Fast_forward For
    Select
        ColumnName,
        ColumnDescription
    From @ColumnDescriptions;

Open LessonCommentDescriptionCursor;
Fetch Next From LessonCommentDescriptionCursor Into @ColumnName, @ColumnDescription;

While @@Fetch_status = 0
Begin
    If Exists
    (
        Select
            1
        From sys.extended_properties
        Inner Join sys.columns On sys.columns.object_id = sys.extended_properties.major_id And sys.columns.column_id = sys.extended_properties.minor_id
        Where (sys.extended_properties.class = 1)
            And (sys.extended_properties.major_id = Object_id(N'dbo.LMS_LessonComments'))
            And (sys.extended_properties.name = N'MS_Description')
            And (sys.columns.name = @ColumnName)
    )
        Exec sys.sp_updateextendedproperty @name = N'MS_Description', @value = @ColumnDescription, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'LMS_LessonComments', @level2type = N'COLUMN', @level2name = @ColumnName;
    Else
        Exec sys.sp_addextendedproperty @name = N'MS_Description', @value = @ColumnDescription, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'LMS_LessonComments', @level2type = N'COLUMN', @level2name = @ColumnName;

    Fetch Next From LessonCommentDescriptionCursor Into @ColumnName, @ColumnDescription;
End;

Close LessonCommentDescriptionCursor;
Deallocate LessonCommentDescriptionCursor;
Go

Create Or Alter Procedure dbo.LMS_LessonComment_GetByLesson
    @LessonID Bigint,
    @ActorUserID Bigint,
    @IsAdmin Bit = 0,
    @IsTeacher Bit = 0,
    @Page Int = 1,
    @PageSize Int = 20
As
Begin
    Set Nocount On;

    Set @Page = Case When @Page < 1 Then 1 Else @Page End;
    Set @PageSize = Case When @PageSize < 1 Then 20 When @PageSize > 50 Then 50 Else @PageSize End;

    Declare @CourseID Bigint;

    Select
        @CourseID = dbo.SIM_Lessons.CourseID
    From dbo.SIM_Lessons
    Where (dbo.SIM_Lessons.LessonID = @LessonID)
        And (dbo.SIM_Lessons.IsDeleted = 0);

    If @CourseID Is Null
        Throw 50001, N'Không tìm thấy bài học.', 1;

    If @IsAdmin = 0
        And Not Exists
        (
            Select
                1
            From dbo.LMS_Enrollments
            Where (dbo.LMS_Enrollments.CourseID = @CourseID)
                And (dbo.LMS_Enrollments.StudentUserID = @ActorUserID)
                And (dbo.LMS_Enrollments.Status <> 'CANCELLED')
        )
        And Not Exists
        (
            Select
                1
            From dbo.SIM_Courses
            Left Join dbo.SIM_Class_Subject On dbo.SIM_Class_Subject.DataGroupID = dbo.SIM_Courses.DataGroupID And dbo.SIM_Class_Subject.ClassSubjectID = dbo.SIM_Courses.ClassSubjectID
            Left Join dbo.SIM_Teacher On dbo.SIM_Teacher.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Teacher.TeacherID = dbo.SIM_Class_Subject.TeacherID
            Where (dbo.SIM_Courses.CourseID = @CourseID)
                And (@IsTeacher = 1)
                And ((dbo.SIM_Courses.TeacherUserID = @ActorUserID) Or (dbo.SIM_Courses.CreatedByUserID = @ActorUserID) Or (dbo.SIM_Teacher.UserID = @ActorUserID))
        )
        Throw 50003, N'Bạn không có quyền xem thảo luận của bài học này.', 1;

    Create Table #tblRootComment
    (
        LessonCommentID Bigint Not Null Primary Key
    );

    Insert Into #tblRootComment
    (
        LessonCommentID
    )
    Select
        dbo.LMS_LessonComments.LessonCommentID
    From dbo.LMS_LessonComments
    Where (dbo.LMS_LessonComments.LessonID = @LessonID)
        And (dbo.LMS_LessonComments.ParentCommentID Is Null)
    Order By
        dbo.LMS_LessonComments.CreatedDate Desc,
        dbo.LMS_LessonComments.LessonCommentID Desc
    Offset (@Page - 1) * @PageSize Rows Fetch Next @PageSize Rows Only;

    Select
        Count(Case When dbo.LMS_LessonComments.ParentCommentID Is Null Then 1 End) RootCommentCount,
        Count(*) TotalCommentCount
    From dbo.LMS_LessonComments
    Where (dbo.LMS_LessonComments.LessonID = @LessonID);

    ;With LessonCommentTree As
    (
        Select
            dbo.LMS_LessonComments.LessonCommentID,
            dbo.LMS_LessonComments.ParentCommentID,
            0 CommentLevel
        From dbo.LMS_LessonComments
        Inner Join #tblRootComment On #tblRootComment.LessonCommentID = dbo.LMS_LessonComments.LessonCommentID

        Union All

        Select
            ChildComment.LessonCommentID,
            ChildComment.ParentCommentID,
            LessonCommentTree.CommentLevel + 1
        From dbo.LMS_LessonComments As ChildComment
        Inner Join LessonCommentTree On LessonCommentTree.LessonCommentID = ChildComment.ParentCommentID
        Where (LessonCommentTree.CommentLevel < 20)
    )
    Select
        dbo.LMS_LessonComments.LessonCommentID Id,
        dbo.LMS_LessonComments.CourseID,
        dbo.LMS_LessonComments.LessonID,
        dbo.LMS_LessonComments.UserID,
        dbo.LMS_LessonComments.ParentCommentID,
        Case When dbo.LMS_LessonComments.IsDeleted = 1 Then N'Bình luận đã được xóa.' Else dbo.LMS_LessonComments.Content End Content,
        dbo.LMS_LessonComments.IsEdited,
        dbo.LMS_LessonComments.IsDeleted,
        dbo.LMS_LessonComments.CreatedDate,
        dbo.LMS_LessonComments.UpdatedDate,
        dbo.SYS_Users.FullName UserFullName,
        dbo.SYS_Users.AvatarUrl UserAvatarUrl,
        Coalesce(UserRole.RoleCode, 'STUDENT') UserRole,
        Cast(Case When dbo.LMS_LessonComments.UserID = @ActorUserID And dbo.LMS_LessonComments.IsDeleted = 0 Then 1 Else 0 End As Bit) CanEdit,
        Cast(Case When dbo.LMS_LessonComments.IsDeleted = 0 And (dbo.LMS_LessonComments.UserID = @ActorUserID Or @IsAdmin = 1 Or @IsTeacher = 1) Then 1 Else 0 End As Bit) CanDelete,
        LessonCommentTree.CommentLevel
    From LessonCommentTree
    Inner Join dbo.LMS_LessonComments On dbo.LMS_LessonComments.LessonCommentID = LessonCommentTree.LessonCommentID
    Inner Join dbo.SYS_Users On dbo.SYS_Users.UserID = dbo.LMS_LessonComments.UserID
    Outer Apply
    (
        Select Top (1)
            dbo.SYS_Roles.Code RoleCode
        From dbo.SYS_UserRoles
        Inner Join dbo.SYS_Roles On dbo.SYS_Roles.RoleID = dbo.SYS_UserRoles.RoleID
        Where (dbo.SYS_UserRoles.UserID = dbo.LMS_LessonComments.UserID)
        Order By
            Case dbo.SYS_Roles.Code When 'ADMIN' Then 1 When 'TEACHER' Then 2 Else 3 End
    ) As UserRole
    Order By
        Case When dbo.LMS_LessonComments.ParentCommentID Is Null Then dbo.LMS_LessonComments.CreatedDate End Desc,
        dbo.LMS_LessonComments.CreatedDate,
        dbo.LMS_LessonComments.LessonCommentID;
End;
Go

Create Or Alter Procedure dbo.LMS_LessonComment_Insert
    @LessonID Bigint,
    @ActorUserID Bigint,
    @IsAdmin Bit = 0,
    @IsTeacher Bit = 0,
    @Content Nvarchar(Max),
    @ParentCommentID Bigint = Null
As
Begin
    Set Nocount On;
    Set Xact_abort On;

    Set @Content = Ltrim(Rtrim(@Content));

    If Len(@Content) Not Between 1 And 5000
        Throw 50001, N'Nội dung bình luận phải có từ 1 đến 5000 ký tự.', 1;

    Declare @CourseID Bigint;

    Select
        @CourseID = dbo.SIM_Lessons.CourseID
    From dbo.SIM_Lessons
    Where (dbo.SIM_Lessons.LessonID = @LessonID)
        And (dbo.SIM_Lessons.IsDeleted = 0);

    If @CourseID Is Null
        Throw 50001, N'Không tìm thấy bài học.', 1;

    If @IsAdmin = 0
        And Not Exists
        (
            Select
                1
            From dbo.LMS_Enrollments
            Where (dbo.LMS_Enrollments.CourseID = @CourseID)
                And (dbo.LMS_Enrollments.StudentUserID = @ActorUserID)
                And (dbo.LMS_Enrollments.Status <> 'CANCELLED')
        )
        And Not Exists
        (
            Select
                1
            From dbo.SIM_Courses
            Left Join dbo.SIM_Class_Subject On dbo.SIM_Class_Subject.DataGroupID = dbo.SIM_Courses.DataGroupID And dbo.SIM_Class_Subject.ClassSubjectID = dbo.SIM_Courses.ClassSubjectID
            Left Join dbo.SIM_Teacher On dbo.SIM_Teacher.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Teacher.TeacherID = dbo.SIM_Class_Subject.TeacherID
            Where (dbo.SIM_Courses.CourseID = @CourseID)
                And (@IsTeacher = 1)
                And ((dbo.SIM_Courses.TeacherUserID = @ActorUserID) Or (dbo.SIM_Courses.CreatedByUserID = @ActorUserID) Or (dbo.SIM_Teacher.UserID = @ActorUserID))
        )
        Throw 50003, N'Bạn không có quyền bình luận trong bài học này.', 1;

    If @ParentCommentID Is Not Null
        And Not Exists
        (
            Select
                1
            From dbo.LMS_LessonComments
            Where (dbo.LMS_LessonComments.LessonCommentID = @ParentCommentID)
                And (dbo.LMS_LessonComments.LessonID = @LessonID)
                And (dbo.LMS_LessonComments.IsDeleted = 0)
        )
        Throw 50001, N'Bình luận cha không hợp lệ hoặc thuộc bài học khác.', 1;

    Insert Into dbo.LMS_LessonComments
    (
        CourseID,
        LessonID,
        UserID,
        ParentCommentID,
        Content
    )
    Values
    (
        @CourseID,
        @LessonID,
        @ActorUserID,
        @ParentCommentID,
        @Content
    );

    Declare @LessonCommentID Bigint = Scope_identity();
    Declare @ParentUserID Bigint = (Select UserID From dbo.LMS_LessonComments Where LessonCommentID = @ParentCommentID);

    If @ParentUserID Is Not Null And @ParentUserID <> @ActorUserID
        Insert Into dbo.SYS_Notifications
        (
            RecipientUserID,
            ActorUserID,
            NotificationType,
            Title,
            Message,
            ReferenceType,
            ReferenceID,
            ActionUrl
        )
        Select
            @ParentUserID,
            @ActorUserID,
            'LESSON_COMMENT_REPLY',
            N'Có trả lời mới trong bài học',
            Concat(dbo.SYS_Users.FullName, N' đã trả lời bình luận của bạn.'),
            'LESSON_COMMENT',
            @LessonCommentID,
            Concat(N'/lms/courses/', @CourseID, N'/lessons/', @LessonID)
        From dbo.SYS_Users
        Where (dbo.SYS_Users.UserID = @ActorUserID);

    If @ParentCommentID Is Null
        Insert Into dbo.SYS_Notifications
        (
            RecipientUserID,
            ActorUserID,
            NotificationType,
            Title,
            Message,
            ReferenceType,
            ReferenceID,
            ActionUrl
        )
        Select Distinct
            TeacherUser.UserID,
            @ActorUserID,
            'LESSON_COMMENT',
            N'Bài học có thảo luận mới',
            Concat(ActorUser.FullName, N' đã bình luận trong bài “', dbo.SIM_Lessons.Title, N'”.'),
            'LESSON_COMMENT',
            @LessonCommentID,
            Concat(N'/lms/courses/', @CourseID, N'/lessons/', @LessonID)
        From dbo.SIM_Courses
        Inner Join dbo.SIM_Lessons On dbo.SIM_Lessons.CourseID = dbo.SIM_Courses.CourseID And dbo.SIM_Lessons.LessonID = @LessonID
        Inner Join dbo.SYS_Users As ActorUser On ActorUser.UserID = @ActorUserID
        Cross Apply
        (
            Select
                dbo.SIM_Courses.TeacherUserID UserID

            Union

            Select
                dbo.SIM_Teacher.UserID
            From dbo.SIM_Class_Subject
            Inner Join dbo.SIM_Teacher On dbo.SIM_Teacher.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Teacher.TeacherID = dbo.SIM_Class_Subject.TeacherID
            Where (dbo.SIM_Class_Subject.DataGroupID = dbo.SIM_Courses.DataGroupID)
                And (dbo.SIM_Class_Subject.ClassSubjectID = dbo.SIM_Courses.ClassSubjectID)
        ) As TeacherUser
        Where (dbo.SIM_Courses.CourseID = @CourseID)
            And (TeacherUser.UserID Is Not Null)
            And (TeacherUser.UserID <> @ActorUserID);

    Select
        @LessonCommentID LessonCommentID;
End;
Go

Create Or Alter Procedure dbo.LMS_LessonComment_Update
    @LessonCommentID Bigint,
    @ActorUserID Bigint,
    @Content Nvarchar(Max)
As
Begin
    Set Nocount On;

    Set @Content = Ltrim(Rtrim(@Content));

    If Len(@Content) Not Between 1 And 5000
        Throw 50001, N'Nội dung bình luận phải có từ 1 đến 5000 ký tự.', 1;

    If Not Exists
    (
        Select
            1
        From dbo.LMS_LessonComments
        Where (dbo.LMS_LessonComments.LessonCommentID = @LessonCommentID)
            And (dbo.LMS_LessonComments.UserID = @ActorUserID)
            And (dbo.LMS_LessonComments.IsDeleted = 0)
    )
        Throw 50003, N'Bạn chỉ có thể sửa bình luận của chính mình.', 1;

    Update dbo.LMS_LessonComments
    Set
        Content = @Content,
        IsEdited = 1,
        UpdatedDate = Sysutcdatetime()
    Where (dbo.LMS_LessonComments.LessonCommentID = @LessonCommentID);

    Select
        @LessonCommentID LessonCommentID;
End;
Go

Create Or Alter Procedure dbo.LMS_LessonComment_Delete
    @LessonCommentID Bigint,
    @ActorUserID Bigint,
    @IsAdmin Bit = 0,
    @IsTeacher Bit = 0
As
Begin
    Set Nocount On;

    Declare @CourseID Bigint,
        @OwnerUserID Bigint;

    Select
        @CourseID = dbo.LMS_LessonComments.CourseID,
        @OwnerUserID = dbo.LMS_LessonComments.UserID
    From dbo.LMS_LessonComments
    Where (dbo.LMS_LessonComments.LessonCommentID = @LessonCommentID)
        And (dbo.LMS_LessonComments.IsDeleted = 0);

    If @CourseID Is Null
        Throw 50001, N'Không tìm thấy bình luận.', 1;

    If @OwnerUserID <> @ActorUserID
        And @IsAdmin = 0
        And Not Exists
        (
            Select
                1
            From dbo.SIM_Courses
            Left Join dbo.SIM_Class_Subject On dbo.SIM_Class_Subject.DataGroupID = dbo.SIM_Courses.DataGroupID And dbo.SIM_Class_Subject.ClassSubjectID = dbo.SIM_Courses.ClassSubjectID
            Left Join dbo.SIM_Teacher On dbo.SIM_Teacher.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Teacher.TeacherID = dbo.SIM_Class_Subject.TeacherID
            Where (dbo.SIM_Courses.CourseID = @CourseID)
                And (@IsTeacher = 1)
                And ((dbo.SIM_Courses.TeacherUserID = @ActorUserID) Or (dbo.SIM_Courses.CreatedByUserID = @ActorUserID) Or (dbo.SIM_Teacher.UserID = @ActorUserID))
        )
        Throw 50003, N'Bạn không có quyền xóa bình luận này.', 1;

    Update dbo.LMS_LessonComments
    Set
        IsDeleted = 1,
        DeletedDate = Sysutcdatetime(),
        DeletedUserID = @ActorUserID
    Where (dbo.LMS_LessonComments.LessonCommentID = @LessonCommentID);

    Select
        @LessonCommentID LessonCommentID;
End;
Go
