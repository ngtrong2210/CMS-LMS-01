SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;

BEGIN TRANSACTION;

DECLARE @AdminId BIGINT=(SELECT Id FROM dbo.Users WHERE Username='admin');
IF @AdminId IS NULL THROW 51000, N'Không tìm thấy tài khoản admin để tạo dữ liệu video mẫu.', 1;

DECLARE @DemoFiles TABLE(
    FileOrder INT PRIMARY KEY,
    FileName NVARCHAR(500) NOT NULL,
    VideoUrl NVARCHAR(1000) NOT NULL,
    Title NVARCHAR(500) NOT NULL
);

INSERT @DemoFiles(FileOrder,FileName,VideoUrl,Title) VALUES
(1,N'z3.mp4', N'/Media/Video/demo/z3.mp4', N'Video mẫu 03'),
(2,N'z5.mp4', N'/Media/Video/demo/z5.mp4', N'Video mẫu 05'),
(3,N'z6.mp4', N'/Media/Video/demo/z6.mp4', N'Video mẫu 06'),
(4,N'z7.mp4', N'/Media/Video/demo/z7.mp4', N'Video mẫu 07'),
(5,N'z22.mp4',N'/Media/Video/demo/z22.mp4',N'Video mẫu 22');

/* Keep five reusable entries in the video library. */
INSERT dbo.VideoAssets(Title,VideoUrl,DurationSeconds,OriginalFileName,FileSize,MimeType,CreatedBy,Status)
SELECT f.Title,f.VideoUrl,180,f.FileName,3130713,N'video/mp4',@AdminId,'ACTIVE'
FROM @DemoFiles f
WHERE NOT EXISTS(
    SELECT 1 FROM dbo.VideoAssets a
    WHERE a.VideoUrl=f.VideoUrl AND a.IsDeleted=0
);

/* Assign the attached files round-robin only to videos that do not have a local file. */
DECLARE @AssignedVideos TABLE(VideoId BIGINT PRIMARY KEY,FileOrder INT NOT NULL);
;WITH MissingVideos AS (
    SELECT v.Id,ROW_NUMBER() OVER(ORDER BY v.Id) AS RowNumber
    FROM dbo.Videos v
    WHERE v.VideoUrl IS NULL OR LTRIM(RTRIM(v.VideoUrl))=''
)
INSERT @AssignedVideos(VideoId,FileOrder)
SELECT Id,((RowNumber-1)%5)+1 FROM MissingVideos;

UPDATE v
SET VideoUrl=f.VideoUrl,
    DurationSeconds=180,
    UpdatedAt=SYSUTCDATETIME()
FROM dbo.Videos v
JOIN @AssignedVideos av ON av.VideoId=v.Id
JOIN @DemoFiles f ON f.FileOrder=av.FileOrder;

UPDATE l
SET DurationSeconds=v.DurationSeconds,
    UpdatedAt=SYSUTCDATETIME()
FROM dbo.Lessons l
JOIN dbo.Videos v ON v.LessonId=l.Id
JOIN @AssignedVideos av ON av.VideoId=v.Id;

/* Preserve current video-to-library relations and fill their missing file metadata. */
UPDATE a
SET VideoUrl=f.VideoUrl,
    DurationSeconds=180,
    OriginalFileName=f.FileName,
    FileSize=3130713,
    MimeType=N'video/mp4',
    UpdatedAt=SYSUTCDATETIME(),
    Status='ACTIVE',
    IsDeleted=0
FROM dbo.VideoAssets a
JOIN dbo.Videos v ON v.VideoAssetId=a.Id
JOIN @DemoFiles f ON f.VideoUrl=v.VideoUrl
WHERE EXISTS(SELECT 1 FROM @AssignedVideos av WHERE av.VideoId=v.Id);

/* Also repair source-linked library rows left empty by older seed versions. */
UPDATE a
SET VideoUrl=v.VideoUrl,
    DurationSeconds=v.DurationSeconds,
    OriginalFileName=f.FileName,
    FileSize=3130713,
    MimeType=N'video/mp4',
    UpdatedAt=SYSUTCDATETIME(),
    Status='ACTIVE',
    IsDeleted=0
FROM dbo.VideoAssets a
JOIN dbo.Videos v ON v.Id=a.SourceVideoId
JOIN @DemoFiles f ON f.VideoUrl=v.VideoUrl
WHERE a.VideoUrl IS NULL OR LTRIM(RTRIM(a.VideoUrl))='';

/* A video without a prior library relation uses the matching reusable asset. */
UPDATE v
SET VideoAssetId=a.Id,
    UpdatedAt=SYSUTCDATETIME()
FROM dbo.Videos v
JOIN dbo.VideoAssets a ON a.VideoUrl=v.VideoUrl AND a.IsDeleted=0
WHERE v.VideoAssetId IS NULL;

/* Every video has at least five active interactions at useful points in playback. */
DECLARE @Slots TABLE(SlotOrder INT PRIMARY KEY,PercentOfVideo INT NOT NULL);
INSERT @Slots VALUES(1,12),(2,30),(3,48),(4,66),(5,84);

;WITH ActiveCounts AS (
    SELECT v.Id AS VideoId,COUNT(vi.Id) AS ActiveCount
    FROM dbo.Videos v
    LEFT JOIN dbo.VideoInteractions vi ON vi.VideoId=v.Id AND vi.IsDeleted=0
    GROUP BY v.Id
), CandidateSlots AS (
    SELECT v.Id AS VideoId,
           s.SlotOrder,
           CAST(ROUND(v.DurationSeconds*s.PercentOfVideo/100.0,0) AS INT) AS TimeSeconds,
           ac.ActiveCount,
           ROW_NUMBER() OVER(PARTITION BY v.Id ORDER BY s.SlotOrder) AS SlotRank
    FROM dbo.Videos v
    JOIN ActiveCounts ac ON ac.VideoId=v.Id
    CROSS JOIN @Slots s
    WHERE NOT EXISTS(
        SELECT 1
        FROM dbo.VideoInteractions vi
        WHERE vi.VideoId=v.Id
          AND vi.IsDeleted=0
          AND vi.TimeSeconds=CAST(ROUND(v.DurationSeconds*s.PercentOfVideo/100.0,0) AS INT)
    )
), NumberedQuestions AS (
    SELECT q.Id,
           ROW_NUMBER() OVER(ORDER BY
               CASE q.QuestionType
                   WHEN 'SINGLE_CHOICE' THEN 1
                   WHEN 'TRUE_FALSE' THEN 2
                   WHEN 'SHORT_ANSWER' THEN 3
                   ELSE 4
               END,
               q.Id) AS QuestionNumber,
           COUNT(*) OVER() AS QuestionCount
    FROM dbo.Questions q
    WHERE q.IsDeleted=0 AND q.Status='ACTIVE'
), InsertRows AS (
    SELECT cs.VideoId,cs.SlotOrder,cs.TimeSeconds,cs.SlotRank,q.Id AS QuestionId
    FROM CandidateSlots cs
    JOIN NumberedQuestions q
      ON q.QuestionNumber=((cs.VideoId+cs.SlotOrder-2)%q.QuestionCount)+1
    WHERE cs.SlotRank<=CASE WHEN cs.ActiveCount<5 THEN 5-cs.ActiveCount ELSE 0 END
)
INSERT dbo.VideoInteractions(
    VideoId,QuestionId,TimeSeconds,InteractionType,Required,PauseVideo,
    AllowSkip,Score,AttemptLimit,SortOrder,Status
)
SELECT r.VideoId,r.QuestionId,r.TimeSeconds,'QUESTION',1,1,0,10,2,
       ISNULL((SELECT MAX(existing.SortOrder) FROM dbo.VideoInteractions existing WHERE existing.VideoId=r.VideoId),0)+r.SlotRank,
       'ACTIVE'
FROM InsertRows r;

COMMIT TRANSACTION;
GO
