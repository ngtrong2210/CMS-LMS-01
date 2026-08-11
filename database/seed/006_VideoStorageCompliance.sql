/* Video binaries are project-local. Remove legacy absolute/external VideoUrl values. */
UPDATE dbo.Videos
SET VideoUrl = NULL, UpdatedAt = SYSUTCDATETIME()
WHERE VideoUrl IS NOT NULL
  AND VideoUrl NOT LIKE '/uploads/videos/%';
