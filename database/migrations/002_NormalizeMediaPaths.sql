SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

UPDATE dbo.SIM_VideoAssets
SET VideoUrl = N'/Media/Video/' + SUBSTRING(VideoUrl, LEN(N'/uploads/videos/') + 1, 4000),
    UpdatedAt = SYSUTCDATETIME()
WHERE VideoUrl LIKE N'/uploads/videos/%';

UPDATE dbo.SIM_Videos
SET VideoUrl = N'/Media/Video/' + SUBSTRING(VideoUrl, LEN(N'/uploads/videos/') + 1, 4000),
    UpdatedAt = SYSUTCDATETIME()
WHERE VideoUrl LIKE N'/uploads/videos/%';

UPDATE dbo.SIM_VideoAssets
SET PosterUrl = CASE
    WHEN PosterUrl LIKE N'/uploads/images/%' THEN N'/Media/Image/' + SUBSTRING(PosterUrl, LEN(N'/uploads/images/') + 1, 4000)
    WHEN PosterUrl LIKE N'/uploads/thumbnails/%' THEN N'/Media/Thumbnail/' + SUBSTRING(PosterUrl, LEN(N'/uploads/thumbnails/') + 1, 4000)
    ELSE PosterUrl END,
    UpdatedAt = SYSUTCDATETIME()
WHERE PosterUrl LIKE N'/uploads/images/%' OR PosterUrl LIKE N'/uploads/thumbnails/%';

UPDATE dbo.SIM_Videos
SET PosterUrl = CASE
    WHEN PosterUrl LIKE N'/uploads/images/%' THEN N'/Media/Image/' + SUBSTRING(PosterUrl, LEN(N'/uploads/images/') + 1, 4000)
    WHEN PosterUrl LIKE N'/uploads/thumbnails/%' THEN N'/Media/Thumbnail/' + SUBSTRING(PosterUrl, LEN(N'/uploads/thumbnails/') + 1, 4000)
    ELSE PosterUrl END,
    UpdatedAt = SYSUTCDATETIME()
WHERE PosterUrl LIKE N'/uploads/images/%' OR PosterUrl LIKE N'/uploads/thumbnails/%';

UPDATE dbo.SIM_Courses
SET ThumbnailUrl = CASE
    WHEN ThumbnailUrl LIKE N'/uploads/images/%' THEN N'/Media/Image/' + SUBSTRING(ThumbnailUrl, LEN(N'/uploads/images/') + 1, 4000)
    WHEN ThumbnailUrl LIKE N'/uploads/thumbnails/%' THEN N'/Media/Thumbnail/' + SUBSTRING(ThumbnailUrl, LEN(N'/uploads/thumbnails/') + 1, 4000)
    ELSE ThumbnailUrl END,
    UpdatedAt = SYSUTCDATETIME()
WHERE ThumbnailUrl LIKE N'/uploads/images/%' OR ThumbnailUrl LIKE N'/uploads/thumbnails/%';

UPDATE dbo.SYS_Users
SET AvatarUrl = N'/Media/Image/' + SUBSTRING(AvatarUrl, LEN(N'/uploads/images/') + 1, 4000),
    UpdatedAt = SYSUTCDATETIME()
WHERE AvatarUrl LIKE N'/uploads/images/%';

COMMIT TRANSACTION;

IF EXISTS(SELECT 1 FROM dbo.SIM_VideoAssets WHERE VideoUrl LIKE N'/uploads/%')
   OR EXISTS(SELECT 1 FROM dbo.SIM_Videos WHERE VideoUrl LIKE N'/uploads/%')
    THROW 51020, N'Vẫn còn URL video dùng cấu trúc /uploads cũ.', 1;
GO
