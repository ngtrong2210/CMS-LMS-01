IF COL_LENGTH(N'dbo.SIM_Lessons', N'VideoID') IS NULL
    EXEC(N'ALTER TABLE dbo.SIM_Lessons ADD VideoID BIGINT NULL;');
GO

SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;

    IF COL_LENGTH(N'dbo.SIM_Videos', N'LessonID') IS NOT NULL
    BEGIN
        IF OBJECT_ID(N'dbo.Lessons', N'V') IS NOT NULL DROP VIEW dbo.Lessons;
        IF OBJECT_ID(N'dbo.Videos', N'V') IS NOT NULL DROP VIEW dbo.Videos;

        /* Mỗi tài nguyên thư viện chỉ có một video tương tác chuẩn. */
        CREATE TABLE #VideoMap(OldVideoID BIGINT NOT NULL PRIMARY KEY, CanonicalVideoID BIGINT NOT NULL);
        INSERT #VideoMap(OldVideoID,CanonicalVideoID)
        SELECT v.VideoID,MIN(v.VideoID) OVER(PARTITION BY COALESCE(v.VideoAssetID,-v.VideoID))
        FROM dbo.SIM_Videos v;

        EXEC(N'UPDATE l SET VideoID=m.CanonicalVideoID
          FROM dbo.SIM_Lessons l
          JOIN dbo.SIM_Videos v ON v.LessonID=l.LessonID
          JOIN #VideoMap m ON m.OldVideoID=v.VideoID;');

        UPDATE vi SET VideoID=m.CanonicalVideoID
        FROM dbo.LMS_VideoInteractions vi JOIN #VideoMap m ON m.OldVideoID=vi.VideoID
        WHERE vi.VideoID<>m.CanonicalVideoID;
        UPDATE p SET VideoID=m.CanonicalVideoID
        FROM dbo.LMS_StudentVideoProgress p JOIN #VideoMap m ON m.OldVideoID=p.VideoID
        WHERE p.VideoID<>m.CanonicalVideoID;
        UPDATE a SET VideoID=m.CanonicalVideoID
        FROM dbo.LMS_StudentAnswers a JOIN #VideoMap m ON m.OldVideoID=a.VideoID
        WHERE a.VideoID<>m.CanonicalVideoID;
        UPDATE s SET VideoID=m.CanonicalVideoID
        FROM dbo.LMS_LearningSessions s JOIN #VideoMap m ON m.OldVideoID=s.VideoID
        WHERE s.VideoID<>m.CanonicalVideoID;
        UPDATE a SET SourceVideoID=m.CanonicalVideoID
        FROM dbo.SIM_VideoAssets a JOIN #VideoMap m ON m.OldVideoID=a.SourceVideoID
        WHERE a.SourceVideoID<>m.CanonicalVideoID;

        DELETE v FROM dbo.SIM_Videos v JOIN #VideoMap m ON m.OldVideoID=v.VideoID
        WHERE m.OldVideoID<>m.CanonicalVideoID;

        DECLARE @ConstraintName SYSNAME, @Sql NVARCHAR(MAX);
        DECLARE fk_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT fk.name
            FROM sys.foreign_keys fk
            JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
            JOIN sys.columns c ON c.object_id=fkc.parent_object_id AND c.column_id=fkc.parent_column_id
            WHERE fk.parent_object_id=OBJECT_ID(N'dbo.SIM_Videos') AND c.name=N'LessonID';
        OPEN fk_cursor;
        FETCH NEXT FROM fk_cursor INTO @ConstraintName;
        WHILE @@FETCH_STATUS=0
        BEGIN
            SET @Sql=N'ALTER TABLE dbo.SIM_Videos DROP CONSTRAINT '+QUOTENAME(@ConstraintName)+N';';
            EXEC sys.sp_executesql @Sql;
            FETCH NEXT FROM fk_cursor INTO @ConstraintName;
        END
        CLOSE fk_cursor;
        DEALLOCATE fk_cursor;

        DECLARE uq_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT i.name
            FROM sys.indexes i
            JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id
            JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
            WHERE i.object_id=OBJECT_ID(N'dbo.SIM_Videos') AND c.name=N'LessonID'
              AND (i.is_unique_constraint=1 OR i.is_unique=1);
        OPEN uq_cursor;
        FETCH NEXT FROM uq_cursor INTO @ConstraintName;
        WHILE @@FETCH_STATUS=0
        BEGIN
            IF EXISTS(SELECT 1 FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID(N'dbo.SIM_Videos') AND name=@ConstraintName)
                SET @Sql=N'ALTER TABLE dbo.SIM_Videos DROP CONSTRAINT '+QUOTENAME(@ConstraintName)+N';';
            ELSE
                SET @Sql=N'DROP INDEX '+QUOTENAME(@ConstraintName)+N' ON dbo.SIM_Videos;';
            EXEC sys.sp_executesql @Sql;
            FETCH NEXT FROM uq_cursor INTO @ConstraintName;
        END
        CLOSE uq_cursor;
        DEALLOCATE uq_cursor;

        ALTER TABLE dbo.SIM_Videos DROP COLUMN LessonID;
    END

    /* Tài nguyên cũ chưa có bản ghi video được nâng thành video độc lập để có thể soạn tương tác. */
    INSERT dbo.SIM_Videos(VideoAssetID,Title,VideoUrl,PosterUrl,DurationSeconds,AllowSeek,AllowSpeed,RequiredWatchPercent,Status,CreatedAt,UpdatedAt)
    SELECT a.VideoAssetID,a.Title,a.VideoUrl,a.PosterUrl,a.DurationSeconds,0,1,80,a.Status,a.CreatedAt,a.UpdatedAt
    FROM dbo.SIM_VideoAssets a
    WHERE a.IsDeleted=0 AND NOT EXISTS(SELECT 1 FROM dbo.SIM_Videos v WHERE v.VideoAssetID=a.VideoAssetID);

    IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE parent_object_id=OBJECT_ID(N'dbo.SIM_Lessons') AND name=N'FK_SIM_Lessons_Video')
        ALTER TABLE dbo.SIM_Lessons ADD CONSTRAINT FK_SIM_Lessons_Video FOREIGN KEY(VideoID) REFERENCES dbo.SIM_Videos(VideoID);
    IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.SIM_Lessons') AND name=N'IX_SIM_Lessons_VideoID')
        CREATE INDEX IX_SIM_Lessons_VideoID ON dbo.SIM_Lessons(VideoID) WHERE VideoID IS NOT NULL;
    IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.SIM_Videos') AND name=N'UX_SIM_Videos_VideoAssetID')
        CREATE UNIQUE INDEX UX_SIM_Videos_VideoAssetID ON dbo.SIM_Videos(VideoAssetID) WHERE VideoAssetID IS NOT NULL;

    /* Tiến độ cùng một video phải tách riêng theo từng bài học. */
    DECLARE @ProgressConstraint SYSNAME, @ProgressSql NVARCHAR(MAX);
    SELECT TOP(1) @ProgressConstraint=kc.name
    FROM sys.key_constraints kc
    JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id AND ic.index_id=kc.unique_index_id
    JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
    WHERE kc.parent_object_id=OBJECT_ID(N'dbo.LMS_StudentVideoProgress') AND kc.type=N'UQ'
    GROUP BY kc.name
    HAVING COUNT(*)=2 AND SUM(IIF(c.name IN(N'StudentUserID',N'VideoID'),1,0))=2;
    IF @ProgressConstraint IS NOT NULL
    BEGIN
        SET @ProgressSql=N'ALTER TABLE dbo.LMS_StudentVideoProgress DROP CONSTRAINT '+QUOTENAME(@ProgressConstraint)+N';';
        EXEC sys.sp_executesql @ProgressSql;
    END
    IF NOT EXISTS(SELECT 1 FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID(N'dbo.LMS_StudentVideoProgress') AND name=N'UQ_LMS_StudentVideoProgress_LessonVideo')
        ALTER TABLE dbo.LMS_StudentVideoProgress ADD CONSTRAINT UQ_LMS_StudentVideoProgress_LessonVideo UNIQUE(StudentUserID,LessonID,VideoID);

    IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=OBJECT_ID(N'dbo.SIM_Lessons') AND minor_id=COLUMNPROPERTY(OBJECT_ID(N'dbo.SIM_Lessons'),N'VideoID','ColumnId') AND name=N'MS_Description')
        EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'ID video tương tác độc lập được bài học tham chiếu; nhiều bài học có thể dùng chung một video.',@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'TABLE',@level1name=N'SIM_Lessons',@level2type=N'COLUMN',@level2name=N'VideoID';
    ELSE
        EXEC sys.sp_updateextendedproperty @name=N'MS_Description',@value=N'ID video tương tác độc lập được bài học tham chiếu; nhiều bài học có thể dùng chung một video.',@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'TABLE',@level1name=N'SIM_Lessons',@level2type=N'COLUMN',@level2name=N'VideoID';

    EXEC sys.sp_updateextendedproperty @name=N'MS_Description',@value=N'[SIM] Video tương tác độc lập đã soạn sẵn, có thể được nhiều bài học tham chiếu mà không nhân bản.',@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'TABLE',@level1name=N'SIM_Videos';

    EXEC(N'CREATE OR ALTER VIEW dbo.Lessons AS SELECT LessonID AS Id,CourseID AS CourseId,ChapterID AS ChapterId,VideoID AS VideoId,Title,Description,LessonType,DurationSeconds,SortOrder,IsRequired,PassingScore,Status,CreatedAt,UpdatedAt,IsDeleted FROM dbo.SIM_Lessons;');
    EXEC(N'CREATE OR ALTER VIEW dbo.Videos AS SELECT VideoID AS Id,VideoAssetID AS VideoAssetId,Title,VideoUrl,PosterUrl,DurationSeconds,AllowSeek,AllowSpeed,RequiredWatchPercent,Status,CreatedAt,UpdatedAt FROM dbo.SIM_Videos;');

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
