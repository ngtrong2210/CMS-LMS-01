SET NOCOUNT ON;

/*
 Nhân bản metadata của video mẫu cho từng giáo viên để kiểm thử quyền sở hữu.
 Không sao chép file vật lý: các bản ghi mới dùng lại VideoUrl/PosterUrl hiện có.
 Mỗi giáo viên nhận 5 tài nguyên riêng tư và có thể tự chia sẻ từ giao diện.
*/
DECLARE @Sources TABLE(
 SourceId BIGINT PRIMARY KEY,
 SourceOrder INT NOT NULL,
 Title NVARCHAR(500) NOT NULL,
 VideoUrl NVARCHAR(1000) NULL,
 PosterUrl NVARCHAR(1000) NULL,
 DurationSeconds INT NOT NULL,
 OriginalFileName NVARCHAR(500) NULL,
 FileSize BIGINT NULL,
 MimeType NVARCHAR(150) NULL
);

INSERT @Sources(SourceId,SourceOrder,Title,VideoUrl,PosterUrl,DurationSeconds,OriginalFileName,FileSize,MimeType)
SELECT Id,SourceOrder,Title,VideoUrl,PosterUrl,DurationSeconds,OriginalFileName,FileSize,MimeType
FROM (
 SELECT a.Id,a.Title,a.VideoUrl,a.PosterUrl,a.DurationSeconds,a.OriginalFileName,a.FileSize,a.MimeType,
        ROW_NUMBER() OVER(ORDER BY CASE WHEN a.OriginalFileName IS NOT NULL THEN 0 ELSE 1 END,a.Id) SourceOrder
 FROM dbo.VideoAssets a
 WHERE a.IsDeleted=0 AND a.Status='ACTIVE' AND a.VideoUrl IS NOT NULL
   AND a.Title NOT LIKE N'%[[]Bản GV:%'
) ranked
WHERE SourceOrder<=5;

INSERT dbo.VideoAssets(
 Title,VideoUrl,PosterUrl,DurationSeconds,OriginalFileName,FileSize,MimeType,
 SourceVideoId,CreatedBy,ShareScope,Status
)
SELECT LEFT(CONCAT(s.Title,N' [Bản GV: ',u.TeacherCode,N']'),500),
       s.VideoUrl,s.PosterUrl,s.DurationSeconds,s.OriginalFileName,s.FileSize,s.MimeType,
       NULL,u.Id,'PRIVATE','ACTIVE'
FROM dbo.Users u
CROSS JOIN @Sources s
WHERE u.TeacherCode IS NOT NULL AND u.IsDeleted=0 AND u.Status='ACTIVE'
  AND NOT EXISTS(
   SELECT 1 FROM dbo.VideoAssets existing
   WHERE existing.CreatedBy=u.Id
     AND existing.Title=LEFT(CONCAT(s.Title,N' [Bản GV: ',u.TeacherCode,N']'),500)
     AND existing.IsDeleted=0
  );
GO
