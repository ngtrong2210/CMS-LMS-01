/* Backfill reusable library records after every demo seed has created its videos. */
INSERT dbo.VideoAssets(Title,VideoUrl,PosterUrl,DurationSeconds,SourceVideoId,CreatedBy,Status)
SELECT v.Title,v.VideoUrl,v.PosterUrl,v.DurationSeconds,v.Id,COALESCE(c.CreatedBy,c.TeacherId),'ACTIVE'
FROM dbo.Videos v JOIN dbo.Lessons l ON l.Id=v.LessonId JOIN dbo.Courses c ON c.Id=l.CourseId
WHERE v.VideoAssetId IS NULL AND NOT EXISTS(SELECT 1 FROM dbo.VideoAssets a WHERE a.SourceVideoId=v.Id);

UPDATE v SET VideoAssetId=a.Id
FROM dbo.Videos v JOIN dbo.VideoAssets a ON a.SourceVideoId=v.Id
WHERE v.VideoAssetId IS NULL;
