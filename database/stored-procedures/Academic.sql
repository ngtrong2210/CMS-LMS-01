Create Or Alter Procedure dbo.LMS_Academic_GetCatalog
    @ActorID Bigint,
    @IsAdmin Bit = 0
As
Begin
    Set Nocount On;

    Select
        (Select Count(*) From dbo.SIM_Year Where IsActived = 1) YearCount,
        (Select Count(*) From dbo.SIM_Science Where IsActived = 1) ScienceCount,
        (Select Count(*) From dbo.SIM_Course Where IsActived = 1) CohortCount,
        (Select Count(*) From dbo.SIM_Class Where IsActived = 1) ClassCount,
        (Select Count(*) From dbo.SIM_Subject Where IsActived = 1) SubjectCount,
        (Select Count(*) From dbo.SIM_Student Where IsActived = 1) StudentCount,
        (Select Count(*) From dbo.SIM_Class_Subject Where ClassSubjectStatus = 1) ClassSubjectCount,
        (Select Count(*) From dbo.SIM_Timetable Where TimetableStatus = 1) TimetableCount;

    Select
        dbo.SIM_Year.DataGroupID,
        dbo.SIM_Year.YearID,
        dbo.SIM_Year.YearName,
        dbo.SIM_Year.StartAt,
        dbo.SIM_Year.FinishAt,
        dbo.SIM_Year.IsActived
    From dbo.SIM_Year
    Order By dbo.SIM_Year.YearID Desc;

    Select
        dbo.SIM_Science.DataGroupID,
        dbo.SIM_Science.ScienceID,
        dbo.SIM_Science.ScienceName,
        dbo.SIM_Science.ScienceShortName,
        dbo.SIM_Science.IsActived
    From dbo.SIM_Science
    Order By dbo.SIM_Science.ScienceName;

    Select
        dbo.SIM_Course.DataGroupID,
        dbo.SIM_Course.CourseID,
        dbo.SIM_Course.CourseName,
        dbo.SIM_Course.StartYear,
        dbo.SIM_Course.FinishYear,
        dbo.SIM_Course.IsActived
    From dbo.SIM_Course
    Order By dbo.SIM_Course.StartYear Desc,
        dbo.SIM_Course.CourseName;

    Select
        dbo.SIM_Class.DataGroupID,
        dbo.SIM_Class.ClassID,
        dbo.SIM_Class.ClassName,
        dbo.SIM_Class.ClassShortName,
        dbo.SIM_Class.ScienceID,
        dbo.SIM_Science.ScienceName,
        dbo.SIM_Class.CourseID,
        dbo.SIM_Course.CourseName,
        dbo.SIM_Class.ClassSize,
        dbo.SIM_Class.ManagerTeacherID,
        Concat(dbo.SIM_Teacher.TeacherFirstName, N' ', dbo.SIM_Teacher.TeacherLastName) ManagerTeacherName,
        (Select Count(*) From dbo.SIM_Student Where dbo.SIM_Student.DataGroupID = dbo.SIM_Class.DataGroupID And dbo.SIM_Student.ClassID = dbo.SIM_Class.ClassID And dbo.SIM_Student.IsActived = 1) StudentCount,
        dbo.SIM_Class.IsActived
    From dbo.SIM_Class
        Left Join dbo.SIM_Science On dbo.SIM_Science.DataGroupID = dbo.SIM_Class.DataGroupID And dbo.SIM_Science.ScienceID = dbo.SIM_Class.ScienceID
        Left Join dbo.SIM_Course On dbo.SIM_Course.DataGroupID = dbo.SIM_Class.DataGroupID And dbo.SIM_Course.CourseID = dbo.SIM_Class.CourseID
        Left Join dbo.SIM_Teacher On dbo.SIM_Teacher.DataGroupID = dbo.SIM_Class.DataGroupID And dbo.SIM_Teacher.TeacherID = dbo.SIM_Class.ManagerTeacherID
    Order By dbo.SIM_Class.ClassName;

    Select
        dbo.SIM_Subject.DataGroupID,
        dbo.SIM_Subject.SubjectID,
        dbo.SIM_Subject.SubjectName,
        dbo.SIM_Subject.SubjectShortName,
        dbo.SIM_Subject.ScienceID,
        dbo.SIM_Science.ScienceName,
        dbo.SIM_Subject.TheoryQuantity,
        dbo.SIM_Subject.PracticeQuantity,
        dbo.SIM_Subject.TestQuantity,
        dbo.SIM_Subject.CreditCount,
        dbo.SIM_Subject.IsActived
    From dbo.SIM_Subject
        Left Join dbo.SIM_Science On dbo.SIM_Science.DataGroupID = dbo.SIM_Subject.DataGroupID And dbo.SIM_Science.ScienceID = dbo.SIM_Subject.ScienceID
    Order By dbo.SIM_Subject.SubjectName;

    Select
        dbo.SIM_Teacher.DataGroupID,
        dbo.SIM_Teacher.TeacherID,
        dbo.SIM_Teacher.UserID,
        Ltrim(Rtrim(Concat(dbo.SIM_Teacher.TeacherFirstName, N' ', dbo.SIM_Teacher.TeacherLastName))) TeacherName,
        dbo.SIM_Teacher.ScienceID,
        dbo.SIM_Teacher.Email,
        dbo.SIM_Teacher.IsActived
    From dbo.SIM_Teacher
    Where (@IsAdmin = 1 Or dbo.SIM_Teacher.UserID = @ActorID)
    Order By TeacherName;

    Select
        dbo.SIM_Student.DataGroupID,
        dbo.SIM_Student.StudentID,
        dbo.SIM_Student.UserID,
        dbo.SIM_Student.FullName,
        dbo.SIM_Student.ClassID,
        dbo.SIM_Class.ClassName,
        dbo.SIM_Student.Email,
        dbo.SIM_Student.Mobile,
        dbo.SIM_Student.IsActived
    From dbo.SIM_Student
        Inner Join dbo.SIM_Class On dbo.SIM_Class.DataGroupID = dbo.SIM_Student.DataGroupID And dbo.SIM_Class.ClassID = dbo.SIM_Student.ClassID
    Order By dbo.SIM_Class.ClassName,
        dbo.SIM_Student.FullName;

    Select
        dbo.SIM_Class_Subject.DataGroupID,
        dbo.SIM_Class_Subject.ClassSubjectID,
        dbo.SIM_Class_Subject.YearID,
        dbo.SIM_Year.YearName,
        dbo.SIM_Class_Subject.Semester,
        dbo.SIM_Class_Subject.ClassID,
        dbo.SIM_Class.ClassName,
        dbo.SIM_Class_Subject.SubjectID,
        dbo.SIM_Subject.SubjectName,
        dbo.SIM_Class_Subject.TeacherID,
        Ltrim(Rtrim(Concat(dbo.SIM_Teacher.TeacherFirstName, N' ', dbo.SIM_Teacher.TeacherLastName))) TeacherName,
        dbo.SIM_Class_Subject.CreditCount,
        dbo.SIM_Class_Subject.TheoryQuantity,
        dbo.SIM_Class_Subject.PracticeQuantity,
        dbo.SIM_Class_Subject.ClassSubjectStatus,
        dbo.SIM_Courses.CourseID OnlineCourseID,
        dbo.SIM_Courses.Title OnlineCourseTitle,
        dbo.SIM_Courses.Status OnlineCourseStatus,
        (Select Count(*) From dbo.SIM_Chapters Where dbo.SIM_Chapters.CourseID = dbo.SIM_Courses.CourseID And dbo.SIM_Chapters.IsDeleted = 0) ChapterCount,
        (Select Count(*) From dbo.SIM_Lessons Where dbo.SIM_Lessons.CourseID = dbo.SIM_Courses.CourseID And dbo.SIM_Lessons.IsDeleted = 0) LessonCount,
        (Select Count(*) From dbo.SIM_Student Where dbo.SIM_Student.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Student.ClassID = dbo.SIM_Class_Subject.ClassID And dbo.SIM_Student.IsActived = 1) StudentCount
    From dbo.SIM_Class_Subject
        Inner Join dbo.SIM_Year On dbo.SIM_Year.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Year.YearID = dbo.SIM_Class_Subject.YearID
        Inner Join dbo.SIM_Class On dbo.SIM_Class.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Class.ClassID = dbo.SIM_Class_Subject.ClassID
        Inner Join dbo.SIM_Subject On dbo.SIM_Subject.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Subject.SubjectID = dbo.SIM_Class_Subject.SubjectID
        Left Join dbo.SIM_Teacher On dbo.SIM_Teacher.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Teacher.TeacherID = dbo.SIM_Class_Subject.TeacherID
        Left Join dbo.SIM_Courses On dbo.SIM_Courses.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Courses.ClassSubjectID = dbo.SIM_Class_Subject.ClassSubjectID And dbo.SIM_Courses.IsDeleted = 0
    Where (@IsAdmin = 1 Or dbo.SIM_Teacher.UserID = @ActorID)
    Order By dbo.SIM_Class_Subject.YearID Desc,
        dbo.SIM_Class_Subject.Semester,
        dbo.SIM_Class.ClassName,
        dbo.SIM_Subject.SubjectName;

    Select
        dbo.SIM_Timetable.TimetableID,
        dbo.SIM_Timetable.DataGroupID,
        dbo.SIM_Timetable.ClassSubjectID,
        dbo.SIM_Class_Subject.YearID,
        dbo.SIM_Year.YearName,
        dbo.SIM_Class_Subject.Semester,
        dbo.SIM_Class_Subject.ClassID,
        dbo.SIM_Class.ClassName,
        dbo.SIM_Class_Subject.SubjectID,
        dbo.SIM_Subject.SubjectName,
        dbo.SIM_Timetable.DayOfWeek,
        dbo.SIM_Timetable.StartPeriod,
        dbo.SIM_Timetable.EndPeriod,
        dbo.SIM_Timetable.StartTime,
        dbo.SIM_Timetable.EndTime,
        dbo.SIM_Timetable.RoomName,
        dbo.SIM_Timetable.EffectiveFrom,
        dbo.SIM_Timetable.EffectiveTo,
        dbo.SIM_Timetable.TimetableStatus
    From dbo.SIM_Timetable
        Inner Join dbo.SIM_Class_Subject On dbo.SIM_Class_Subject.DataGroupID = dbo.SIM_Timetable.DataGroupID And dbo.SIM_Class_Subject.ClassSubjectID = dbo.SIM_Timetable.ClassSubjectID
        Inner Join dbo.SIM_Year On dbo.SIM_Year.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Year.YearID = dbo.SIM_Class_Subject.YearID
        Inner Join dbo.SIM_Class On dbo.SIM_Class.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Class.ClassID = dbo.SIM_Class_Subject.ClassID
        Inner Join dbo.SIM_Subject On dbo.SIM_Subject.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Subject.SubjectID = dbo.SIM_Class_Subject.SubjectID
        Left Join dbo.SIM_Teacher On dbo.SIM_Teacher.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Teacher.TeacherID = dbo.SIM_Class_Subject.TeacherID
    Where (dbo.SIM_Timetable.TimetableStatus = 1)
        And (@IsAdmin = 1 Or dbo.SIM_Teacher.UserID = @ActorID)
    Order By dbo.SIM_Timetable.DayOfWeek,
        dbo.SIM_Timetable.StartTime,
        dbo.SIM_Class.ClassName;
End
Go

Create Or Alter Procedure dbo.LMS_Academic_Save
    @EntityType Varchar(30),
    @DataGroupID Int = 1,
    @Code Nvarchar(50) = Null,
    @Name Nvarchar(500) = Null,
    @ShortName Nvarchar(100) = Null,
    @ParentCode Nvarchar(50) = Null,
    @StartYear Int = Null,
    @FinishYear Int = Null,
    @StartAt Datetime2 = Null,
    @FinishAt Datetime2 = Null,
    @YearID Int = Null,
    @Semester Tinyint = Null,
    @ClassSubjectID Bigint = Null,
    @ClassID Nvarchar(50) = Null,
    @SubjectID Nvarchar(50) = Null,
    @TeacherID Nvarchar(50) = Null,
    @ClassSize Int = 0,
    @CreditCount Tinyint = 0,
    @TheoryQuantity Int = 0,
    @PracticeQuantity Int = 0,
    @TimetableID Bigint = Null,
    @DayOfWeek Tinyint = Null,
    @StartPeriod Tinyint = Null,
    @EndPeriod Tinyint = Null,
    @StartTime Time(0) = Null,
    @EndTime Time(0) = Null,
    @RoomName Nvarchar(100) = Null,
    @EffectiveFrom Date = Null,
    @EffectiveTo Date = Null,
    @ActorID Bigint
As
Begin
    Set Nocount On;
    Set Xact_abort On;

    Set @EntityType = Upper(Ltrim(Rtrim(@EntityType)));
    Set @Code = Nullif(Ltrim(Rtrim(@Code)), N'');
    Set @Name = Nullif(Ltrim(Rtrim(@Name)), N'');

    If @EntityType Not In ('YEAR', 'SCIENCE', 'COHORT', 'SUBJECT', 'CLASS', 'CLASS_SUBJECT', 'TIMETABLE')
        Throw 50001, N'Loại danh mục đào tạo không hợp lệ.', 1;

    If @EntityType Not In ('CLASS_SUBJECT', 'TIMETABLE') And (@Code Is Null Or @Name Is Null)
        Throw 50001, N'Mã và tên danh mục không được để trống.', 1;

    Begin Transaction;

    If @EntityType = 'YEAR'
    Begin
        Set @YearID = Coalesce(@YearID, Try_convert(Int, @Code));
        If @YearID Is Null Throw 50001, N'Mã năm học phải là số.', 1;

        If Exists (Select 1 From dbo.SIM_Year Where DataGroupID = @DataGroupID And YearID = @YearID)
            Update dbo.SIM_Year
            Set
                YearName = @Name,
                StartAt = @StartAt,
                FinishAt = @FinishAt,
                IsActived = 1
            Where (DataGroupID = @DataGroupID)
                And (YearID = @YearID);
        Else
            Insert dbo.SIM_Year
            (
                DataGroupID,
                YearID,
                YearName,
                StartAt,
                FinishAt,
                IsActived
            )
            Values
                (@DataGroupID, @YearID, @Name, @StartAt, @FinishAt, 1);

        Select @EntityType EntityType, Convert(Nvarchar(100), @YearID) EntityID;
    End;
    Else If @EntityType = 'SCIENCE'
    Begin
        If Exists (Select 1 From dbo.SIM_Science Where DataGroupID = @DataGroupID And ScienceID = @Code)
            Update dbo.SIM_Science
            Set
                ScienceName = @Name,
                ScienceShortName = @ShortName,
                IsActived = 1
            Where (DataGroupID = @DataGroupID)
                And (ScienceID = @Code);
        Else
            Insert dbo.SIM_Science
            (
                DataGroupID,
                ScienceID,
                ScienceName,
                ScienceShortName,
                IsActived
            )
            Values
                (@DataGroupID, @Code, @Name, @ShortName, 1);

        Select @EntityType EntityType, @Code EntityID;
    End;
    Else If @EntityType = 'COHORT'
    Begin
        If @StartYear Is Null Or @FinishYear Is Null Or @FinishYear < @StartYear
            Throw 50001, N'Khoảng năm của khóa tuyển sinh không hợp lệ.', 1;

        If Exists (Select 1 From dbo.SIM_Course Where DataGroupID = @DataGroupID And CourseID = @Code)
            Update dbo.SIM_Course
            Set
                CourseName = @Name,
                StartYear = @StartYear,
                FinishYear = @FinishYear,
                IsActived = 1
            Where (DataGroupID = @DataGroupID)
                And (CourseID = @Code);
        Else
            Insert dbo.SIM_Course
            (
                DataGroupID,
                CourseID,
                CourseName,
                StartYear,
                FinishYear,
                IsActived
            )
            Values
                (@DataGroupID, @Code, @Name, @StartYear, @FinishYear, 1);

        Select @EntityType EntityType, @Code EntityID;
    End;
    Else If @EntityType = 'SUBJECT'
    Begin
        If @ParentCode Is Not Null And Not Exists (Select 1 From dbo.SIM_Science Where DataGroupID = @DataGroupID And ScienceID = @ParentCode)
            Throw 50002, N'Khoa của môn học không tồn tại.', 1;

        If Exists (Select 1 From dbo.SIM_Subject Where DataGroupID = @DataGroupID And SubjectID = @Code)
            Update dbo.SIM_Subject
            Set
                SubjectName = @Name,
                SubjectShortName = Coalesce(@ShortName, @Name),
                ScienceID = @ParentCode,
                TheoryQuantity = @TheoryQuantity,
                PracticeQuantity = @PracticeQuantity,
                CreditCount = @CreditCount,
                IsActived = 1
            Where (DataGroupID = @DataGroupID)
                And (SubjectID = @Code);
        Else
            Insert dbo.SIM_Subject
            (
                DataGroupID,
                SubjectID,
                SubjectName,
                SubjectShortName,
                ScienceID,
                TheoryQuantity,
                PracticeQuantity,
                TestQuantity,
                CreditCount,
                IsActived
            )
            Values
                (@DataGroupID, @Code, @Name, Coalesce(@ShortName, @Name), @ParentCode, @TheoryQuantity, @PracticeQuantity, 0, @CreditCount, 1);

        Select @EntityType EntityType, @Code EntityID;
    End;
    Else If @EntityType = 'CLASS'
    Begin
        If @ParentCode Is Null Or Not Exists (Select 1 From dbo.SIM_Science Where DataGroupID = @DataGroupID And ScienceID = @ParentCode)
            Throw 50002, N'Khoa của lớp không tồn tại.', 1;
        If @SubjectID Is Null Or Not Exists (Select 1 From dbo.SIM_Course Where DataGroupID = @DataGroupID And CourseID = @SubjectID)
            Throw 50002, N'Khóa tuyển sinh của lớp không tồn tại.', 1;

        If Exists (Select 1 From dbo.SIM_Class Where DataGroupID = @DataGroupID And ClassID = @Code)
            Update dbo.SIM_Class
            Set
                ClassName = @Name,
                ClassShortName = @ShortName,
                ScienceID = @ParentCode,
                CourseID = @SubjectID,
                ClassSize = @ClassSize,
                ManagerTeacherID = @TeacherID,
                IsActived = 1
            Where (DataGroupID = @DataGroupID)
                And (ClassID = @Code);
        Else
            Insert dbo.SIM_Class
            (
                DataGroupID,
                ClassID,
                ClassName,
                ClassShortName,
                ScienceID,
                CourseID,
                ClassSize,
                ManagerTeacherID,
                IsActived
            )
            Values
                (@DataGroupID, @Code, @Name, @ShortName, @ParentCode, @SubjectID, @ClassSize, @TeacherID, 1);

        Select @EntityType EntityType, @Code EntityID;
    End;
    Else If @EntityType = 'CLASS_SUBJECT'
    Begin
        If @YearID Is Null Or @Semester Is Null Or @ClassID Is Null Or @SubjectID Is Null
            Throw 50001, N'Năm học, học kỳ, lớp và môn học không được để trống.', 1;

        If Not Exists (Select 1 From dbo.SIM_Year Where DataGroupID = @DataGroupID And YearID = @YearID)
            Or Not Exists (Select 1 From dbo.SIM_Class Where DataGroupID = @DataGroupID And ClassID = @ClassID)
            Or Not Exists (Select 1 From dbo.SIM_Subject Where DataGroupID = @DataGroupID And SubjectID = @SubjectID)
            Throw 50002, N'Năm học, lớp hoặc môn học không tồn tại.', 1;

        If @ClassSubjectID Is Null
            Select @ClassSubjectID = Coalesce(Max(ClassSubjectID), Convert(Bigint, @YearID) * 1000) + 1 From dbo.SIM_Class_Subject With (Updlock, Holdlock) Where DataGroupID = @DataGroupID;

        If Exists (Select 1 From dbo.SIM_Class_Subject Where DataGroupID = @DataGroupID And ClassSubjectID = @ClassSubjectID)
            Update dbo.SIM_Class_Subject
            Set
                Semester = @Semester,
                YearID = @YearID,
                ClassID = @ClassID,
                SubjectID = @SubjectID,
                TeacherID = @TeacherID,
                TheoryQuantity = @TheoryQuantity,
                PracticeQuantity = @PracticeQuantity,
                CreditCount = @CreditCount,
                ClassSubjectStatus = 1,
                UpdatedDate = Sysutcdatetime(),
                UpdatedUser = Convert(Nvarchar(50), @ActorID)
            Where (DataGroupID = @DataGroupID)
                And (ClassSubjectID = @ClassSubjectID);
        Else
            Insert dbo.SIM_Class_Subject
            (
                DataGroupID,
                ClassSubjectID,
                Semester,
                YearID,
                ClassID,
                SubjectID,
                TeacherID,
                TheoryQuantity,
                PracticeQuantity,
                TestQuantity,
                CreditCount,
                ClassSubjectStatus,
                OrderIndex,
                IsLocked,
                CreatedDate,
                CreatedUser
            )
            Values
                (@DataGroupID, @ClassSubjectID, @Semester, @YearID, @ClassID, @SubjectID, @TeacherID, @TheoryQuantity, @PracticeQuantity, 0, @CreditCount, 1, @ClassSubjectID, 0, Sysutcdatetime(), Convert(Nvarchar(50), @ActorID));

        Select @EntityType EntityType, Convert(Nvarchar(100), @ClassSubjectID) EntityID;
    End;
    Else
    Begin
        If @ClassSubjectID Is Null Or @DayOfWeek Is Null Or @DayOfWeek Not Between 2 And 8
            Throw 50001, N'Môn học lớp và thứ học không hợp lệ.', 1;
        If @StartTime Is Not Null And @EndTime Is Not Null And @EndTime <= @StartTime
            Throw 50001, N'Giờ kết thúc phải sau giờ bắt đầu.', 1;
        If @StartPeriod Is Not Null And @EndPeriod Is Not Null And @EndPeriod < @StartPeriod
            Throw 50001, N'Tiết kết thúc phải lớn hơn hoặc bằng tiết bắt đầu.', 1;
        If Not Exists (Select 1 From dbo.SIM_Class_Subject Where DataGroupID = @DataGroupID And ClassSubjectID = @ClassSubjectID And ClassSubjectStatus = 1)
            Throw 50002, N'Môn học lớp không tồn tại.', 1;

        If @TimetableID Is Null
        Begin
            Insert dbo.SIM_Timetable
            (
                DataGroupID,
                ClassSubjectID,
                DayOfWeek,
                StartPeriod,
                EndPeriod,
                StartTime,
                EndTime,
                RoomName,
                EffectiveFrom,
                EffectiveTo,
                TimetableStatus
            )
            Values
                (@DataGroupID, @ClassSubjectID, @DayOfWeek, @StartPeriod, @EndPeriod, @StartTime, @EndTime, @RoomName, @EffectiveFrom, @EffectiveTo, 1);

            Set @TimetableID = Scope_identity();
        End;
        Else
        Begin
            Update dbo.SIM_Timetable
            Set
                ClassSubjectID = @ClassSubjectID,
                DayOfWeek = @DayOfWeek,
                StartPeriod = @StartPeriod,
                EndPeriod = @EndPeriod,
                StartTime = @StartTime,
                EndTime = @EndTime,
                RoomName = @RoomName,
                EffectiveFrom = @EffectiveFrom,
                EffectiveTo = @EffectiveTo,
                TimetableStatus = 1,
                UpdatedDate = Sysutcdatetime()
            Where (dbo.SIM_Timetable.TimetableID = @TimetableID)
                And (dbo.SIM_Timetable.DataGroupID = @DataGroupID);

            If @@Rowcount = 0 Throw 50002, N'Thời khóa biểu không tồn tại.', 1;
        End;

        Select @EntityType EntityType, Convert(Nvarchar(100), @TimetableID) EntityID;
    End;

    Commit;
End
Go

Create Or Alter Procedure dbo.LMS_Academic_Student_AssignClass
    @DataGroupID Int,
    @ClassID Nvarchar(50),
    @StudentUserIDsJson Nvarchar(Max),
    @ActorID Bigint
As
Begin
    Set Nocount On;
    Set Xact_abort On;

    If Not Exists (Select 1 From dbo.SIM_Class Where DataGroupID = @DataGroupID And ClassID = @ClassID And IsActived = 1)
        Throw 50002, N'Lớp học không tồn tại hoặc đã ngừng hoạt động.', 1;

    Create Table #tblStudentUser
    (
        StudentUserID Bigint Not Null Primary Key
    );

    Insert #tblStudentUser
    (
        StudentUserID
    )
    Select Distinct
        Parsed.StudentUserID
    From Openjson(@StudentUserIDsJson) With (StudentUserID Bigint '$') Parsed
        Inner Join dbo.SYS_Users On dbo.SYS_Users.UserID = Parsed.StudentUserID
    Where (dbo.SYS_Users.StudentCode Is Not Null)
        And (dbo.SYS_Users.IsDeleted = 0);

    If Not Exists (Select 1 From #tblStudentUser)
        Throw 50001, N'Chưa chọn học viên hợp lệ.', 1;

    Begin Transaction;

    Update dbo.SIM_Student
    Set
        ClassID = @ClassID,
        UpdatedDate = Sysutcdatetime()
    From dbo.SIM_Student
        Inner Join #tblStudentUser On #tblStudentUser.StudentUserID = dbo.SIM_Student.UserID
    Where (dbo.SIM_Student.DataGroupID = @DataGroupID);

    Update dbo.LMS_Enrollments
    Set
        Status = 'ENROLLED',
        ProgressPercent = 0,
        FinalScore = Null,
        EnrolledAt = Sysutcdatetime(),
        CreatedByUserID = @ActorID
    From dbo.LMS_Enrollments
        Inner Join #tblStudentUser On #tblStudentUser.StudentUserID = dbo.LMS_Enrollments.StudentUserID
        Inner Join dbo.SIM_Courses On dbo.SIM_Courses.CourseID = dbo.LMS_Enrollments.CourseID
        Inner Join dbo.SIM_Class_Subject On dbo.SIM_Class_Subject.DataGroupID = dbo.SIM_Courses.DataGroupID And dbo.SIM_Class_Subject.ClassSubjectID = dbo.SIM_Courses.ClassSubjectID
    Where (dbo.SIM_Class_Subject.DataGroupID = @DataGroupID)
        And (dbo.SIM_Class_Subject.ClassID = @ClassID)
        And (dbo.LMS_Enrollments.Status = 'CANCELLED');

    Insert dbo.LMS_Enrollments
    (
        CourseID,
        StudentUserID,
        Status,
        ProgressPercent,
        CreatedByUserID
    )
    Select
        dbo.SIM_Courses.CourseID,
        #tblStudentUser.StudentUserID,
        'ENROLLED',
        0,
        @ActorID
    From #tblStudentUser
        Cross Join dbo.SIM_Class_Subject
        Inner Join dbo.SIM_Courses On dbo.SIM_Courses.DataGroupID = dbo.SIM_Class_Subject.DataGroupID And dbo.SIM_Courses.ClassSubjectID = dbo.SIM_Class_Subject.ClassSubjectID And dbo.SIM_Courses.IsDeleted = 0
    Where (dbo.SIM_Class_Subject.DataGroupID = @DataGroupID)
        And (dbo.SIM_Class_Subject.ClassID = @ClassID)
        And Not Exists
        (
            Select 1
            From dbo.LMS_Enrollments
            Where (dbo.LMS_Enrollments.CourseID = dbo.SIM_Courses.CourseID)
                And (dbo.LMS_Enrollments.StudentUserID = #tblStudentUser.StudentUserID)
        );

    Declare @StudentCount Int = (Select Count(*) From #tblStudentUser);
    Declare @EnrollmentCount Int = @@Rowcount;

    Commit;

    Select
        @StudentCount StudentCount,
        @EnrollmentCount NewEnrollmentCount;
End
Go

Create Or Alter Procedure dbo.LMS_StudySession_Start
    @StudentUserID Bigint,
    @CourseID Bigint = Null,
    @ChapterID Bigint = Null,
    @LessonID Bigint = Null,
    @PageUrl Nvarchar(1000) = Null,
    @ClientSessionKey Nvarchar(100) = Null
As
Begin
    Set Nocount On;

    If @LessonID Is Not Null
        Select
            @ChapterID = dbo.SIM_Lessons.ChapterID,
            @CourseID = dbo.SIM_Lessons.CourseID
        From dbo.SIM_Lessons
        Where (dbo.SIM_Lessons.LessonID = @LessonID)
            And (dbo.SIM_Lessons.IsDeleted = 0);
    Else If @ChapterID Is Not Null
        Select @CourseID = dbo.SIM_Chapters.CourseID From dbo.SIM_Chapters Where dbo.SIM_Chapters.ChapterID = @ChapterID And dbo.SIM_Chapters.IsDeleted = 0;

    If @CourseID Is Null Or Not Exists
    (
        Select 1
        From dbo.LMS_Enrollments
        Where (dbo.LMS_Enrollments.StudentUserID = @StudentUserID)
            And (dbo.LMS_Enrollments.CourseID = @CourseID)
            And (dbo.LMS_Enrollments.Status <> 'CANCELLED')
    )
        Throw 50003, N'Học viên chưa được ghi danh vào môn học này.', 1;

    Declare @StudySessionID Uniqueidentifier = Newid();
    Declare @ClassSubjectID Bigint = (Select ClassSubjectID From dbo.SIM_Courses Where CourseID = @CourseID);

    Insert dbo.LMS_StudySessions
    (
        StudySessionID,
        StudentUserID,
        ClassSubjectID,
        CourseID,
        ChapterID,
        LessonID,
        PageUrl,
        ClientSessionKey
    )
    Values
        (@StudySessionID, @StudentUserID, @ClassSubjectID, @CourseID, @ChapterID, @LessonID, @PageUrl, @ClientSessionKey);

    Select
        @StudySessionID StudySessionID,
        Sysutcdatetime() StartedAt;
End
Go

Create Or Alter Procedure dbo.LMS_StudySession_Heartbeat
    @StudySessionID Uniqueidentifier,
    @StudentUserID Bigint
As
Begin
    Set Nocount On;

    Update dbo.LMS_StudySessions
    Set
        ActiveDurationSeconds = ActiveDurationSeconds + Case When Datediff(Second, LastHeartbeatAt, Sysutcdatetime()) Between 1 And 60 Then Datediff(Second, LastHeartbeatAt, Sysutcdatetime()) Else 0 End,
        LastHeartbeatAt = Sysutcdatetime()
    Where (StudySessionID = @StudySessionID)
        And (StudentUserID = @StudentUserID)
        And (EndedAt Is Null);

    Select
        ActiveDurationSeconds,
        LastHeartbeatAt
    From dbo.LMS_StudySessions
    Where (StudySessionID = @StudySessionID)
        And (StudentUserID = @StudentUserID);
End
Go

Create Or Alter Procedure dbo.LMS_StudySession_End
    @StudySessionID Uniqueidentifier,
    @StudentUserID Bigint,
    @IsCompleted Bit = 0
As
Begin
    Set Nocount On;

    Update dbo.LMS_StudySessions
    Set
        ActiveDurationSeconds = ActiveDurationSeconds + Case When Datediff(Second, LastHeartbeatAt, Sysutcdatetime()) Between 1 And 60 Then Datediff(Second, LastHeartbeatAt, Sysutcdatetime()) Else 0 End,
        LastHeartbeatAt = Sysutcdatetime(),
        EndedAt = Sysutcdatetime(),
        IsCompleted = @IsCompleted
    Where (StudySessionID = @StudySessionID)
        And (StudentUserID = @StudentUserID)
        And (EndedAt Is Null);

    Select
        ActiveDurationSeconds,
        EndedAt,
        IsCompleted
    From dbo.LMS_StudySessions
    Where (StudySessionID = @StudySessionID)
        And (StudentUserID = @StudentUserID);
End
Go

Create Or Alter Procedure dbo.LMS_AssignmentSubmission_GetByLesson
    @LessonID Bigint,
    @StudentUserID Bigint
As
Begin
    Set Nocount On;

    Select
        dbo.LMS_AssignmentSubmissions.AssignmentSubmissionID,
        dbo.LMS_AssignmentSubmissions.LessonID,
        dbo.LMS_AssignmentSubmissions.CourseID,
        dbo.LMS_AssignmentSubmissions.AttemptNumber,
        dbo.LMS_AssignmentSubmissions.SubmissionText,
        dbo.LMS_AssignmentSubmissions.FileUrl,
        dbo.LMS_AssignmentSubmissions.OriginalFileName,
        dbo.LMS_AssignmentSubmissions.FileSize,
        dbo.LMS_AssignmentSubmissions.MimeType,
        dbo.LMS_AssignmentSubmissions.SubmittedAt,
        dbo.LMS_AssignmentSubmissions.SubmissionStatus,
        dbo.LMS_AssignmentSubmissions.Score,
        dbo.LMS_AssignmentSubmissions.Feedback,
        dbo.LMS_AssignmentSubmissions.IsLate
    From dbo.LMS_AssignmentSubmissions
    Where (dbo.LMS_AssignmentSubmissions.LessonID = @LessonID)
        And (dbo.LMS_AssignmentSubmissions.StudentUserID = @StudentUserID)
    Order By dbo.LMS_AssignmentSubmissions.AttemptNumber Desc;
End
Go

Create Or Alter Procedure dbo.LMS_AssignmentSubmission_Create
    @LessonID Bigint,
    @StudentUserID Bigint,
    @SubmissionText Nvarchar(Max) = Null,
    @FileUrl Nvarchar(1000) = Null,
    @OriginalFileName Nvarchar(500) = Null,
    @StoredFileName Nvarchar(500) = Null,
    @FileSize Bigint = Null,
    @MimeType Nvarchar(150) = Null
As
Begin
    Set Nocount On;
    Set Xact_abort On;

    Declare @CourseID Bigint;
    Declare @DueAt Datetime2;
    Declare @AllowLateSubmission Bit;

    Select
        @CourseID = dbo.SIM_Lessons.CourseID,
        @DueAt = dbo.SIM_Lessons.DueAt,
        @AllowLateSubmission = dbo.SIM_Lessons.AllowLateSubmission
    From dbo.SIM_Lessons
    Where (dbo.SIM_Lessons.LessonID = @LessonID)
        And (dbo.SIM_Lessons.LessonType = 'ASSIGNMENT')
        And (dbo.SIM_Lessons.IsDeleted = 0);

    If @CourseID Is Null Throw 50002, N'Bài tập không tồn tại.', 1;
    If Not Exists (Select 1 From dbo.LMS_Enrollments Where CourseID = @CourseID And StudentUserID = @StudentUserID And Status <> 'CANCELLED')
        Throw 50003, N'Học viên chưa được ghi danh vào môn học.', 1;
    If @DueAt Is Not Null And Sysutcdatetime() > @DueAt And @AllowLateSubmission = 0
        Throw 50006, N'Bài tập đã hết hạn nộp.', 1;
    If Nullif(Ltrim(Rtrim(@SubmissionText)), N'') Is Null And @FileUrl Is Null
        Throw 50001, N'Cần nhập nội dung hoặc chọn file để nộp bài.', 1;

    Declare @AttemptNumber Int = Coalesce((Select Max(AttemptNumber) From dbo.LMS_AssignmentSubmissions With (Updlock, Holdlock) Where LessonID = @LessonID And StudentUserID = @StudentUserID), 0) + 1;

    Insert dbo.LMS_AssignmentSubmissions
    (
        LessonID,
        CourseID,
        StudentUserID,
        AttemptNumber,
        SubmissionText,
        FileUrl,
        OriginalFileName,
        StoredFileName,
        FileSize,
        MimeType,
        SubmissionStatus,
        IsLate
    )
    Values
        (@LessonID, @CourseID, @StudentUserID, @AttemptNumber, @SubmissionText, @FileUrl, @OriginalFileName, @StoredFileName, @FileSize, @MimeType, 'SUBMITTED', Iif(@DueAt Is Not Null And Sysutcdatetime() > @DueAt, 1, 0));

    Declare @AssignmentSubmissionID Bigint = Scope_identity();

    Select
        @AssignmentSubmissionID AssignmentSubmissionID,
        @AttemptNumber AttemptNumber,
        'SUBMITTED' SubmissionStatus;
End
Go
