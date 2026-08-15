SET NOCOUNT ON;
SET XACT_ABORT ON;

/*
    Chuẩn hóa tên vật lý của schema theo phân hệ.

    SYS_: tài khoản, vai trò, quyền và vận hành hệ thống.
    SIM_: danh mục/cấu trúc nội dung đào tạo và thư viện học liệu.
    LMS_: quá trình học, tương tác, câu trả lời và tiến độ.

    Các view mang tên cũ được tạo ở cuối migration để API và stored procedure
    hiện hữu tiếp tục hoạt động trong giai đoạn chuyển đổi. Dữ liệu, khóa ngoại,
    index và MS_Description được giữ nguyên vì sp_rename không tạo lại object.
*/

DECLARE @TableMap TABLE
(
    OldName SYSNAME NOT NULL PRIMARY KEY,
    NewName SYSNAME NOT NULL UNIQUE,
    [Description] NVARCHAR(1000) NOT NULL
);

INSERT INTO @TableMap(OldName, NewName, [Description]) VALUES
(N'Roles',                  N'SYS_Roles',                  N'[SYS] Danh mục vai trò sử dụng trong hệ thống.'),
(N'Users',                  N'SYS_Users',                  N'[SYS] Tài khoản quản trị viên, giảng viên và học viên.'),
(N'UserRoles',              N'SYS_UserRoles',              N'[SYS] Quan hệ nhiều-nhiều giữa tài khoản và vai trò.'),
(N'Permissions',            N'SYS_Permissions',            N'[SYS] Danh mục quyền thao tác theo từng phân hệ.'),
(N'RolePermissions',        N'SYS_RolePermissions',        N'[SYS] Quan hệ giữa vai trò và quyền được cấp.'),
(N'RefreshTokens',          N'SYS_RefreshTokens',          N'[SYS] Refresh token phục vụ xác thực và gia hạn phiên.'),
(N'AuditLogs',              N'SYS_AuditLogs',              N'[SYS] Nhật ký thao tác và thay đổi dữ liệu quan trọng.'),
(N'CourseCategories',       N'SIM_CourseCategories',       N'[SIM] Danh mục phân loại khóa học.'),
(N'Courses',                N'SIM_Courses',                N'[SIM] Thông tin tổng quan và trạng thái xuất bản của khóa học.'),
(N'Chapters',               N'SIM_Chapters',               N'[SIM] Các chương nội dung thuộc khóa học.'),
(N'Lessons',                N'SIM_Lessons',                N'[SIM] Các bài học thuộc chương và khóa học.'),
(N'VideoAssets',            N'SIM_VideoAssets',            N'[SIM] Thư viện tài nguyên video dùng lại cho nhiều bài học.'),
(N'VideoAssetShares',       N'SIM_VideoAssetShares',       N'[SIM] Quyền chia sẻ tài nguyên video cho giảng viên.'),
(N'Videos',                 N'SIM_Videos',                 N'[SIM] Cấu hình video được gắn vào một bài học.'),
(N'Questions',              N'LMS_Questions',              N'[LMS] Ngân hàng câu hỏi dùng trong hoạt động học tập.'),
(N'QuestionOptions',        N'LMS_QuestionOptions',        N'[LMS] Các phương án lựa chọn của câu hỏi.'),
(N'QuestionAnswerKeys',     N'LMS_QuestionAnswerKeys',     N'[LMS] Các đáp án chữ được chấp nhận cho câu hỏi trả lời ngắn.'),
(N'VideoInteractions',      N'LMS_VideoInteractions',      N'[LMS] Câu hỏi tương tác tại các mốc thời gian của video.'),
(N'Enrollments',            N'LMS_Enrollments',            N'[LMS] Thông tin ghi danh học viên vào khóa học.'),
(N'StudentLessonProgress',  N'LMS_StudentLessonProgress',  N'[LMS] Tiến độ và kết quả học tập theo từng bài học.'),
(N'StudentVideoProgress',   N'LMS_StudentVideoProgress',   N'[LMS] Tiến độ xem video chi tiết của học viên.'),
(N'StudentAnswers',         N'LMS_StudentAnswers',         N'[LMS] Câu trả lời, điểm số và trạng thái chấm của học viên.'),
(N'StudentAnswerOptions',   N'LMS_StudentAnswerOptions',   N'[LMS] Các phương án học viên chọn cho một lần trả lời.'),
(N'LearningSessions',       N'LMS_LearningSessions',       N'[LMS] Phiên học theo dõi thời lượng xem và hành vi học tập.');

DECLARE @ColumnMap TABLE
(
    TableName SYSNAME NOT NULL,
    OldColumn SYSNAME NOT NULL,
    NewColumn SYSNAME NOT NULL,
    PRIMARY KEY(TableName, OldColumn),
    UNIQUE(TableName, NewColumn)
);

INSERT INTO @ColumnMap(TableName, OldColumn, NewColumn) VALUES
(N'SYS_Roles',                 N'Id',               N'RoleID'),
(N'SYS_Users',                 N'Id',               N'UserID'),
(N'SYS_Users',                 N'CreatedBy',        N'CreatedByUserID'),
(N'SYS_Users',                 N'UpdatedBy',        N'UpdatedByUserID'),
(N'SYS_UserRoles',             N'UserId',           N'UserID'),
(N'SYS_UserRoles',             N'RoleId',           N'RoleID'),
(N'SYS_Permissions',           N'Id',               N'PermissionID'),
(N'SYS_RolePermissions',       N'RoleId',           N'RoleID'),
(N'SYS_RolePermissions',       N'PermissionId',     N'PermissionID'),
(N'SYS_RefreshTokens',         N'Id',               N'RefreshTokenID'),
(N'SYS_RefreshTokens',         N'UserId',           N'UserID'),
(N'SYS_AuditLogs',             N'Id',               N'AuditLogID'),
(N'SYS_AuditLogs',             N'UserId',           N'UserID'),
(N'SYS_AuditLogs',             N'EntityId',         N'EntityID'),
(N'SIM_CourseCategories',      N'Id',               N'CourseCategoryID'),
(N'SIM_Courses',               N'Id',               N'CourseID'),
(N'SIM_Courses',               N'TeacherId',        N'TeacherUserID'),
(N'SIM_Courses',               N'CategoryId',       N'CourseCategoryID'),
(N'SIM_Courses',               N'CreatedBy',        N'CreatedByUserID'),
(N'SIM_Courses',               N'UpdatedBy',        N'UpdatedByUserID'),
(N'SIM_Chapters',              N'Id',               N'ChapterID'),
(N'SIM_Chapters',              N'CourseId',         N'CourseID'),
(N'SIM_Lessons',               N'Id',               N'LessonID'),
(N'SIM_Lessons',               N'CourseId',         N'CourseID'),
(N'SIM_Lessons',               N'ChapterId',        N'ChapterID'),
(N'SIM_VideoAssets',           N'Id',               N'VideoAssetID'),
(N'SIM_VideoAssets',           N'SourceVideoId',    N'SourceVideoID'),
(N'SIM_VideoAssets',           N'CreatedBy',        N'CreatedByUserID'),
(N'SIM_VideoAssetShares',      N'Id',               N'VideoAssetShareID'),
(N'SIM_VideoAssetShares',      N'VideoAssetId',     N'VideoAssetID'),
(N'SIM_VideoAssetShares',      N'TeacherId',        N'TeacherUserID'),
(N'SIM_VideoAssetShares',      N'SharedBy',         N'SharedByUserID'),
(N'SIM_Videos',                N'Id',               N'VideoID'),
(N'SIM_Videos',                N'LessonId',         N'LessonID'),
(N'SIM_Videos',                N'VideoAssetId',     N'VideoAssetID'),
(N'LMS_Questions',             N'Id',               N'QuestionID'),
(N'LMS_Questions',             N'CreatedBy',        N'CreatedByUserID'),
(N'LMS_QuestionOptions',       N'Id',               N'QuestionOptionID'),
(N'LMS_QuestionOptions',       N'QuestionId',       N'QuestionID'),
(N'LMS_QuestionAnswerKeys',    N'Id',               N'QuestionAnswerKeyID'),
(N'LMS_QuestionAnswerKeys',    N'QuestionId',       N'QuestionID'),
(N'LMS_VideoInteractions',     N'Id',               N'VideoInteractionID'),
(N'LMS_VideoInteractions',     N'VideoId',          N'VideoID'),
(N'LMS_VideoInteractions',     N'QuestionId',       N'QuestionID'),
(N'LMS_Enrollments',           N'Id',               N'EnrollmentID'),
(N'LMS_Enrollments',           N'CourseId',         N'CourseID'),
(N'LMS_Enrollments',           N'StudentId',        N'StudentUserID'),
(N'LMS_Enrollments',           N'CreatedBy',        N'CreatedByUserID'),
(N'LMS_StudentLessonProgress', N'Id',               N'StudentLessonProgressID'),
(N'LMS_StudentLessonProgress', N'StudentId',        N'StudentUserID'),
(N'LMS_StudentLessonProgress', N'CourseId',         N'CourseID'),
(N'LMS_StudentLessonProgress', N'LessonId',         N'LessonID'),
(N'LMS_StudentVideoProgress',  N'Id',               N'StudentVideoProgressID'),
(N'LMS_StudentVideoProgress',  N'StudentId',        N'StudentUserID'),
(N'LMS_StudentVideoProgress',  N'CourseId',         N'CourseID'),
(N'LMS_StudentVideoProgress',  N'LessonId',         N'LessonID'),
(N'LMS_StudentVideoProgress',  N'VideoId',          N'VideoID'),
(N'LMS_StudentAnswers',        N'Id',               N'StudentAnswerID'),
(N'LMS_StudentAnswers',        N'StudentId',        N'StudentUserID'),
(N'LMS_StudentAnswers',        N'CourseId',         N'CourseID'),
(N'LMS_StudentAnswers',        N'LessonId',         N'LessonID'),
(N'LMS_StudentAnswers',        N'VideoId',          N'VideoID'),
(N'LMS_StudentAnswers',        N'InteractionId',    N'VideoInteractionID'),
(N'LMS_StudentAnswers',        N'QuestionId',       N'QuestionID'),
(N'LMS_StudentAnswers',        N'ReviewedBy',       N'ReviewedByUserID'),
(N'LMS_StudentAnswerOptions',  N'StudentAnswerId',  N'StudentAnswerID'),
(N'LMS_StudentAnswerOptions',  N'QuestionOptionId', N'QuestionOptionID'),
(N'LMS_LearningSessions',      N'Id',               N'LearningSessionID'),
(N'LMS_LearningSessions',      N'SessionId',        N'SessionID'),
(N'LMS_LearningSessions',      N'StudentId',        N'StudentUserID'),
(N'LMS_LearningSessions',      N'CourseId',         N'CourseID'),
(N'LMS_LearningSessions',      N'LessonId',         N'LessonID'),
(N'LMS_LearningSessions',      N'VideoId',          N'VideoID');

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @OldName SYSNAME, @NewName SYSNAME, @Description NVARCHAR(1000), @ObjectName NVARCHAR(776);
    DECLARE table_rename_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT OldName, NewName, [Description] FROM @TableMap ORDER BY OldName;

    OPEN table_rename_cursor;
    FETCH NEXT FROM table_rename_cursor INTO @OldName, @NewName, @Description;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF OBJECT_ID(QUOTENAME(N'dbo') + N'.' + QUOTENAME(@OldName), N'U') IS NOT NULL
           AND OBJECT_ID(QUOTENAME(N'dbo') + N'.' + QUOTENAME(@NewName), N'U') IS NULL
        BEGIN
            SET @ObjectName = QUOTENAME(N'dbo') + N'.' + QUOTENAME(@OldName);
            EXEC sys.sp_rename @objname=@ObjectName, @newname=@NewName, @objtype=N'OBJECT';
        END;

        IF OBJECT_ID(QUOTENAME(N'dbo') + N'.' + QUOTENAME(@NewName), N'U') IS NULL
            THROW 51010, N'Không tìm thấy bảng nguồn hoặc bảng đích khi chuẩn hóa tên schema.', 1;

        IF EXISTS
        (
            SELECT 1 FROM sys.extended_properties
            WHERE class=1
              AND major_id=OBJECT_ID(QUOTENAME(N'dbo') + N'.' + QUOTENAME(@NewName))
              AND minor_id=0 AND name=N'MS_Description'
        )
            EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=@Description,
                @level0type=N'SCHEMA', @level0name=N'dbo',
                @level1type=N'TABLE', @level1name=@NewName;
        ELSE
            EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=@Description,
                @level0type=N'SCHEMA', @level0name=N'dbo',
                @level1type=N'TABLE', @level1name=@NewName;

        FETCH NEXT FROM table_rename_cursor INTO @OldName, @NewName, @Description;
    END;
    CLOSE table_rename_cursor;
    DEALLOCATE table_rename_cursor;

    /* SQL Server không cho sp_rename cột đang xuất hiện trong biểu thức lọc của index. */
    IF EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.LMS_StudentAnswers') AND name=N'IX_StudentAnswers_Interaction')
        DROP INDEX IX_StudentAnswers_Interaction ON dbo.LMS_StudentAnswers;
    IF EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.SIM_Videos') AND name=N'IX_Videos_Asset')
        DROP INDEX IX_Videos_Asset ON dbo.SIM_Videos;

    DECLARE @TableName SYSNAME, @OldColumn SYSNAME, @NewColumn SYSNAME;
    DECLARE column_rename_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT TableName, OldColumn, NewColumn FROM @ColumnMap ORDER BY TableName, OldColumn;

    OPEN column_rename_cursor;
    FETCH NEXT FROM column_rename_cursor INTO @TableName, @OldColumn, @NewColumn;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF COL_LENGTH(QUOTENAME(N'dbo') + N'.' + QUOTENAME(@TableName), @OldColumn) IS NOT NULL
           AND COL_LENGTH(QUOTENAME(N'dbo') + N'.' + QUOTENAME(@TableName), @NewColumn) IS NULL
        BEGIN
            SET @ObjectName = QUOTENAME(N'dbo') + N'.' + QUOTENAME(@TableName) + N'.' + QUOTENAME(@OldColumn);
            EXEC sys.sp_rename @objname=@ObjectName, @newname=@NewColumn, @objtype=N'COLUMN';
        END;

        IF COL_LENGTH(QUOTENAME(N'dbo') + N'.' + QUOTENAME(@TableName), @NewColumn) IS NULL
           AND NOT (@TableName=N'SIM_Videos' AND @NewColumn=N'LessonID' AND COL_LENGTH(N'dbo.SIM_Lessons',N'VideoID') IS NOT NULL)
            THROW 51011, N'Không thể chuẩn hóa tên một cột định danh.', 1;

        FETCH NEXT FROM column_rename_cursor INTO @TableName, @OldColumn, @NewColumn;
    END;
    CLOSE column_rename_cursor;
    DEALLOCATE column_rename_cursor;

    IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.LMS_StudentAnswers') AND name=N'IX_LMS_StudentAnswers_VideoInteraction')
        CREATE INDEX IX_LMS_StudentAnswers_VideoInteraction
            ON dbo.LMS_StudentAnswers(VideoInteractionID, StudentUserID)
            WHERE VideoInteractionID IS NOT NULL;
    IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.SIM_Videos') AND name=N'IX_SIM_Videos_VideoAsset')
        CREATE INDEX IX_SIM_Videos_VideoAsset
            ON dbo.SIM_Videos(VideoAssetID)
            WHERE VideoAssetID IS NOT NULL;

    /* Nếu một cột mới phát sinh mà chưa được mô tả, bổ sung mô tả an toàn để schema luôn tự giải thích. */
    DECLARE @MissingDescription NVARCHAR(1000), @ColumnObjectId INT, @ColumnId INT;
    DECLARE description_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT t.name, c.name, t.object_id, c.column_id
        FROM sys.tables t
        JOIN sys.schemas s ON s.schema_id=t.schema_id
        JOIN sys.columns c ON c.object_id=t.object_id
        LEFT JOIN sys.extended_properties ep
          ON ep.class=1 AND ep.major_id=t.object_id AND ep.minor_id=c.column_id AND ep.name=N'MS_Description'
        WHERE s.name=N'dbo' AND t.is_ms_shipped=0 AND ep.value IS NULL;

    OPEN description_cursor;
    FETCH NEXT FROM description_cursor INTO @TableName, @NewColumn, @ColumnObjectId, @ColumnId;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @MissingDescription = N'Cột ' + @NewColumn + N' của bảng ' + @TableName + N'; thuộc schema nghiệp vụ ' + LEFT(@TableName, CHARINDEX(N'_', @TableName + N'_') - 1) + N'.';
        EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=@MissingDescription,
            @level0type=N'SCHEMA', @level0name=N'dbo',
            @level1type=N'TABLE', @level1name=@TableName,
            @level2type=N'COLUMN', @level2name=@NewColumn;

        FETCH NEXT FROM description_cursor INTO @TableName, @NewColumn, @ColumnObjectId, @ColumnId;
    END;
    CLOSE description_cursor;
    DEALLOCATE description_cursor;

    /* Tạo lớp tương thích tên cũ. Các view đơn bảng này vẫn hỗ trợ SELECT/INSERT/UPDATE/DELETE. */
    DECLARE @SelectList NVARCHAR(MAX), @Sql NVARCHAR(MAX);
    DECLARE view_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT OldName, NewName FROM @TableMap ORDER BY OldName;

    OPEN view_cursor;
    FETCH NEXT FROM view_cursor INTO @OldName, @NewName;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF OBJECT_ID(QUOTENAME(N'dbo') + N'.' + QUOTENAME(@OldName), N'U') IS NOT NULL
            THROW 51012, N'Tên tương thích cũ vẫn đang là bảng vật lý.', 1;

        SELECT @SelectList = STRING_AGG(
            CAST(QUOTENAME(c.name) + CASE WHEN cm.OldColumn IS NULL THEN N'' ELSE N' AS ' + QUOTENAME(cm.OldColumn) END AS NVARCHAR(MAX)),
            N', '
        ) WITHIN GROUP (ORDER BY c.column_id)
        FROM sys.columns c
        LEFT JOIN @ColumnMap cm ON cm.TableName=@NewName AND cm.NewColumn=c.name
        WHERE c.object_id=OBJECT_ID(QUOTENAME(N'dbo') + N'.' + QUOTENAME(@NewName));

        SET @Sql = N'CREATE OR ALTER VIEW dbo.' + QUOTENAME(@OldName)
                 + N' AS SELECT ' + @SelectList + N' FROM dbo.' + QUOTENAME(@NewName) + N';';
        EXEC sys.sp_executesql @Sql;

        FETCH NEXT FROM view_cursor INTO @OldName, @NewName;
    END;
    CLOSE view_cursor;
    DEALLOCATE view_cursor;

    IF EXISTS
    (
        SELECT 1 FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id
        WHERE s.name=N'dbo' AND t.is_ms_shipped=0
          AND t.name NOT LIKE N'SYS[_]%' AND t.name NOT LIKE N'SIM[_]%' AND t.name NOT LIKE N'LMS[_]%'
    )
        THROW 51013, N'Vẫn còn bảng vật lý chưa có prefix phân hệ SYS_, SIM_ hoặc LMS_.', 1;

    IF EXISTS
    (
        SELECT 1 FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id
        JOIN sys.columns c ON c.object_id=t.object_id
        WHERE s.name=N'dbo' AND t.is_ms_shipped=0 AND c.name=N'Id'
    )
        THROW 51014, N'Vẫn còn cột khóa định danh chung tên Id.', 1;

    IF EXISTS
    (
        SELECT 1 FROM sys.tables t
        JOIN sys.schemas s ON s.schema_id=t.schema_id
        JOIN sys.columns c ON c.object_id=t.object_id
        LEFT JOIN sys.extended_properties ep
          ON ep.class=1 AND ep.major_id=t.object_id AND ep.minor_id=c.column_id AND ep.name=N'MS_Description'
        WHERE s.name=N'dbo' AND t.is_ms_shipped=0 AND ep.value IS NULL
    )
        THROW 51015, N'Vẫn còn cột chưa có MS_Description.', 1;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

SELECT
    t.name AS TableName,
    CAST(ep.value AS NVARCHAR(1000)) AS [Description],
    COUNT(c.column_id) AS ColumnCount
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id=t.schema_id
JOIN sys.columns c ON c.object_id=t.object_id
LEFT JOIN sys.extended_properties ep
  ON ep.class=1 AND ep.major_id=t.object_id AND ep.minor_id=0 AND ep.name=N'MS_Description'
WHERE s.name=N'dbo' AND t.is_ms_shipped=0
GROUP BY t.name, CAST(ep.value AS NVARCHAR(1000))
ORDER BY t.name;
GO
