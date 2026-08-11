/* Keep demo completion thresholds achievable and derived from required interactions. */
UPDATE l SET PassingScore=ISNULL(scores.RequiredScore,0)
FROM dbo.Lessons l
OUTER APPLY(
  SELECT SUM(vi.Score) RequiredScore FROM dbo.Videos v JOIN dbo.VideoInteractions vi ON vi.VideoId=v.Id
  WHERE v.LessonId=l.Id AND vi.Required=1 AND vi.IsDeleted=0 AND vi.Status='ACTIVE'
) scores
WHERE l.LessonType IN('VIDEO','INTERACTIVE_VIDEO') AND l.IsDeleted=0;
GO
