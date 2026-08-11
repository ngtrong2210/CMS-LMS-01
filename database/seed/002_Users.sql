IF NOT EXISTS(SELECT 1 FROM dbo.Users WHERE Username='admin') INSERT dbo.Users(Username,PasswordHash,FullName,Email,Status,CreatedBy) VALUES('admin','INITIALIZE_REQUIRED',N'Quản trị hệ thống','admin@learnhub.vn','ACTIVE',NULL);
IF NOT EXISTS(SELECT 1 FROM dbo.Users WHERE Username='teacher') INSERT dbo.Users(Username,PasswordHash,FullName,Email,TeacherCode,Status,CreatedBy) VALUES('teacher','INITIALIZE_REQUIRED',N'Nguyễn Văn Giảng','teacher@learnhub.vn','GV0001','ACTIVE',NULL);
IF NOT EXISTS(SELECT 1 FROM dbo.Users WHERE Username='student') INSERT dbo.Users(Username,PasswordHash,FullName,Email,StudentCode,Status,CreatedBy) VALUES('student','INITIALIZE_REQUIRED',N'Nguyễn Văn Học','student@learnhub.vn','HV0001','ACTIVE',NULL);
INSERT dbo.UserRoles(UserId,RoleId) SELECT u.Id,r.Id FROM dbo.Users u JOIN dbo.Roles r ON r.Code=UPPER(u.Username) WHERE u.Username IN('admin','teacher','student') AND NOT EXISTS(SELECT 1 FROM dbo.UserRoles ur WHERE ur.UserId=u.Id AND ur.RoleId=r.Id);
GO
