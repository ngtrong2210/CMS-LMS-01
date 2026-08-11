SET NOCOUNT ON;

DECLARE @TableDescriptions TABLE(
    SchemaName SYSNAME NOT NULL,
    TableName SYSNAME NOT NULL,
    [Description] NVARCHAR(1000) NOT NULL
);

INSERT INTO @TableDescriptions(SchemaName, TableName, [Description]) VALUES
(N'dbo',N'Roles',N'Danh mục vai trò sử dụng trong hệ thống.'),
(N'dbo',N'Users',N'Tài khoản người dùng gồm quản trị viên, giảng viên và học viên.'),
(N'dbo',N'UserRoles',N'Bảng liên kết nhiều-nhiều giữa người dùng và vai trò.'),
(N'dbo',N'Permissions',N'Danh mục quyền thao tác theo từng phân hệ.'),
(N'dbo',N'RolePermissions',N'Bảng liên kết quyền được cấp cho từng vai trò.'),
(N'dbo',N'RefreshTokens',N'Thông tin refresh token phục vụ xác thực và gia hạn phiên đăng nhập.'),
(N'dbo',N'AuditLogs',N'Nhật ký các thao tác và thay đổi dữ liệu quan trọng.'),
(N'dbo',N'CourseCategories',N'Danh mục phân loại khóa học.'),
(N'dbo',N'Courses',N'Thông tin tổng quan và trạng thái xuất bản của khóa học.'),
(N'dbo',N'Chapters',N'Các chương nội dung thuộc khóa học.'),
(N'dbo',N'Lessons',N'Các bài học thuộc chương và khóa học.'),
(N'dbo',N'Videos',N'Cấu hình video gắn với bài học.'),
(N'dbo',N'VideoAssets',N'Thư viện tệp video dùng lại cho nhiều bài học và khóa học.'),
(N'dbo',N'Questions',N'Ngân hàng câu hỏi dùng cho video tương tác và bài kiểm tra.'),
(N'dbo',N'QuestionOptions',N'Các phương án lựa chọn của câu hỏi.'),
(N'dbo',N'QuestionAnswerKeys',N'Danh sách đáp án chữ được chấp nhận cho câu hỏi trả lời ngắn.'),
(N'dbo',N'VideoInteractions',N'Cấu hình câu hỏi tương tác tại các mốc thời gian của video.'),
(N'dbo',N'Enrollments',N'Thông tin ghi danh học viên vào khóa học.'),
(N'dbo',N'StudentLessonProgress',N'Tiến độ và kết quả học tập theo từng bài học.'),
(N'dbo',N'StudentVideoProgress',N'Tiến độ xem video chi tiết của từng học viên.'),
(N'dbo',N'StudentAnswers',N'Câu trả lời, điểm số và trạng thái chấm của học viên.'),
(N'dbo',N'StudentAnswerOptions',N'Các phương án học viên đã chọn cho một lần trả lời.'),
(N'dbo',N'LearningSessions',N'Phiên học dùng để theo dõi thời lượng xem và hành vi trong bài học.');

DECLARE @ColumnDescriptions TABLE(
    SchemaName SYSNAME NOT NULL,
    TableName SYSNAME NOT NULL,
    ColumnName SYSNAME NOT NULL,
    [Description] NVARCHAR(1000) NOT NULL,
    PRIMARY KEY(SchemaName, TableName, ColumnName)
);

INSERT INTO @ColumnDescriptions VALUES
-- Roles
(N'dbo',N'Roles',N'Id',N'Khóa chính tự tăng của vai trò.'),
(N'dbo',N'Roles',N'Code',N'Mã kỹ thuật duy nhất của vai trò, ví dụ ADMIN, TEACHER, STUDENT.'),
(N'dbo',N'Roles',N'Name',N'Tên hiển thị của vai trò.'),
(N'dbo',N'Roles',N'Description',N'Mô tả phạm vi và mục đích của vai trò.'),
(N'dbo',N'Roles',N'Status',N'Trạng thái sử dụng của vai trò.'),
-- Users
(N'dbo',N'Users',N'Id',N'Khóa chính tự tăng của người dùng.'),
(N'dbo',N'Users',N'Username',N'Tên đăng nhập duy nhất của người dùng.'),
(N'dbo',N'Users',N'PasswordHash',N'Chuỗi mật khẩu đã băm; không lưu mật khẩu dạng rõ.'),
(N'dbo',N'Users',N'FullName',N'Họ và tên đầy đủ của người dùng.'),
(N'dbo',N'Users',N'Email',N'Địa chỉ email duy nhất của người dùng.'),
(N'dbo',N'Users',N'StudentCode',N'Mã học viên; chỉ có giá trị với tài khoản học viên.'),
(N'dbo',N'Users',N'TeacherCode',N'Mã giảng viên; chỉ có giá trị với tài khoản giảng viên.'),
(N'dbo',N'Users',N'AvatarUrl',N'Đường dẫn ảnh đại diện của người dùng.'),
(N'dbo',N'Users',N'Status',N'Trạng thái tài khoản: ACTIVE, INACTIVE hoặc LOCKED.'),
(N'dbo',N'Users',N'LastLoginAt',N'Thời điểm đăng nhập thành công gần nhất theo UTC.'),
(N'dbo',N'Users',N'CreatedAt',N'Thời điểm tạo tài khoản theo UTC.'),
(N'dbo',N'Users',N'UpdatedAt',N'Thời điểm cập nhật tài khoản gần nhất theo UTC.'),
(N'dbo',N'Users',N'CreatedBy',N'ID người dùng đã tạo tài khoản này.'),
(N'dbo',N'Users',N'UpdatedBy',N'ID người dùng cập nhật tài khoản gần nhất.'),
(N'dbo',N'Users',N'IsDeleted',N'Cờ xóa mềm: 1 là đã xóa, 0 là đang sử dụng.'),
-- UserRoles
(N'dbo',N'UserRoles',N'UserId',N'ID người dùng được gán vai trò.'),
(N'dbo',N'UserRoles',N'RoleId',N'ID vai trò được gán cho người dùng.'),
-- Permissions
(N'dbo',N'Permissions',N'Id',N'Khóa chính tự tăng của quyền.'),
(N'dbo',N'Permissions',N'Code',N'Mã kỹ thuật duy nhất của quyền.'),
(N'dbo',N'Permissions',N'Name',N'Tên hiển thị của quyền.'),
(N'dbo',N'Permissions',N'Module',N'Tên phân hệ chức năng sở hữu quyền.'),
(N'dbo',N'Permissions',N'Description',N'Mô tả thao tác mà quyền cho phép thực hiện.'),
-- RolePermissions
(N'dbo',N'RolePermissions',N'RoleId',N'ID vai trò được cấp quyền.'),
(N'dbo',N'RolePermissions',N'PermissionId',N'ID quyền được cấp cho vai trò.'),
-- RefreshTokens
(N'dbo',N'RefreshTokens',N'Id',N'Khóa chính tự tăng của refresh token.'),
(N'dbo',N'RefreshTokens',N'UserId',N'ID người dùng sở hữu refresh token.'),
(N'dbo',N'RefreshTokens',N'TokenHash',N'Giá trị refresh token đã được băm.'),
(N'dbo',N'RefreshTokens',N'ExpiresAt',N'Thời điểm refresh token hết hạn theo UTC.'),
(N'dbo',N'RefreshTokens',N'CreatedAt',N'Thời điểm phát hành refresh token theo UTC.'),
(N'dbo',N'RefreshTokens',N'RevokedAt',N'Thời điểm refresh token bị thu hồi theo UTC.'),
(N'dbo',N'RefreshTokens',N'CreatedIp',N'Địa chỉ IP yêu cầu phát hành refresh token.'),
(N'dbo',N'RefreshTokens',N'RevokedIp',N'Địa chỉ IP thực hiện thu hồi refresh token.'),
(N'dbo',N'RefreshTokens',N'IsRevoked',N'Cờ cho biết refresh token đã bị thu hồi hay chưa.'),
-- AuditLogs
(N'dbo',N'AuditLogs',N'Id',N'Khóa chính tự tăng của bản ghi nhật ký.'),
(N'dbo',N'AuditLogs',N'UserId',N'ID người dùng thực hiện thao tác; có thể rỗng với tác vụ hệ thống.'),
(N'dbo',N'AuditLogs',N'Action',N'Tên hành động được ghi nhận.'),
(N'dbo',N'AuditLogs',N'Module',N'Phân hệ phát sinh hành động.'),
(N'dbo',N'AuditLogs',N'EntityName',N'Tên loại dữ liệu bị tác động.'),
(N'dbo',N'AuditLogs',N'EntityId',N'Khóa định danh của bản ghi bị tác động.'),
(N'dbo',N'AuditLogs',N'OldValuesJson',N'Dữ liệu trước thay đổi ở định dạng JSON.'),
(N'dbo',N'AuditLogs',N'NewValuesJson',N'Dữ liệu sau thay đổi ở định dạng JSON.'),
(N'dbo',N'AuditLogs',N'IpAddress',N'Địa chỉ IP của thiết bị thực hiện thao tác.'),
(N'dbo',N'AuditLogs',N'UserAgent',N'Thông tin trình duyệt hoặc ứng dụng khách.'),
(N'dbo',N'AuditLogs',N'CreatedAt',N'Thời điểm ghi nhận hành động theo UTC.'),
-- CourseCategories
(N'dbo',N'CourseCategories',N'Id',N'Khóa chính tự tăng của danh mục khóa học.'),
(N'dbo',N'CourseCategories',N'Code',N'Mã duy nhất của danh mục khóa học.'),
(N'dbo',N'CourseCategories',N'Name',N'Tên hiển thị của danh mục khóa học.'),
(N'dbo',N'CourseCategories',N'Description',N'Mô tả nội dung của danh mục khóa học.'),
(N'dbo',N'CourseCategories',N'SortOrder',N'Thứ tự hiển thị của danh mục, số nhỏ hiển thị trước.'),
(N'dbo',N'CourseCategories',N'Status',N'Trạng thái sử dụng của danh mục khóa học.'),
-- Courses
(N'dbo',N'Courses',N'Id',N'Khóa chính tự tăng của khóa học.'),
(N'dbo',N'Courses',N'Code',N'Mã nghiệp vụ duy nhất của khóa học.'),
(N'dbo',N'Courses',N'Title',N'Tên hiển thị của khóa học.'),
(N'dbo',N'Courses',N'Slug',N'Chuỗi định danh thân thiện dùng trong đường dẫn URL.'),
(N'dbo',N'Courses',N'ThumbnailUrl',N'Đường dẫn ảnh đại diện của khóa học.'),
(N'dbo',N'Courses',N'ShortDescription',N'Mô tả ngắn dùng tại danh sách và thẻ khóa học.'),
(N'dbo',N'Courses',N'Description',N'Nội dung giới thiệu chi tiết của khóa học.'),
(N'dbo',N'Courses',N'TeacherId',N'ID giảng viên phụ trách khóa học.'),
(N'dbo',N'Courses',N'CategoryId',N'ID danh mục của khóa học; có thể chưa phân loại.'),
(N'dbo',N'Courses',N'Level',N'Cấp độ kiến thức của khóa học.'),
(N'dbo',N'Courses',N'PassingScore',N'Điểm tối thiểu theo thang 100 để đạt khóa học.'),
(N'dbo',N'Courses',N'Status',N'Trạng thái khóa học: DRAFT, PUBLISHED hoặc ARCHIVED.'),
(N'dbo',N'Courses',N'PublishedAt',N'Thời điểm khóa học được xuất bản theo UTC.'),
(N'dbo',N'Courses',N'CreatedAt',N'Thời điểm tạo khóa học theo UTC.'),
(N'dbo',N'Courses',N'UpdatedAt',N'Thời điểm cập nhật khóa học gần nhất theo UTC.'),
(N'dbo',N'Courses',N'CreatedBy',N'ID người dùng tạo khóa học.'),
(N'dbo',N'Courses',N'UpdatedBy',N'ID người dùng cập nhật khóa học gần nhất.'),
(N'dbo',N'Courses',N'IsDeleted',N'Cờ xóa mềm của khóa học.'),
-- Chapters
(N'dbo',N'Chapters',N'Id',N'Khóa chính tự tăng của chương.'),
(N'dbo',N'Chapters',N'CourseId',N'ID khóa học chứa chương.'),
(N'dbo',N'Chapters',N'Title',N'Tên hiển thị của chương.'),
(N'dbo',N'Chapters',N'Description',N'Mô tả nội dung của chương.'),
(N'dbo',N'Chapters',N'SortOrder',N'Thứ tự hiển thị của chương trong khóa học.'),
(N'dbo',N'Chapters',N'Status',N'Trạng thái sử dụng của chương.'),
(N'dbo',N'Chapters',N'CreatedAt',N'Thời điểm tạo chương theo UTC.'),
(N'dbo',N'Chapters',N'UpdatedAt',N'Thời điểm cập nhật chương gần nhất theo UTC.'),
(N'dbo',N'Chapters',N'IsDeleted',N'Cờ xóa mềm của chương.'),
-- Lessons
(N'dbo',N'Lessons',N'Id',N'Khóa chính tự tăng của bài học.'),
(N'dbo',N'Lessons',N'CourseId',N'ID khóa học chứa bài học.'),
(N'dbo',N'Lessons',N'ChapterId',N'ID chương chứa bài học.'),
(N'dbo',N'Lessons',N'Title',N'Tên hiển thị của bài học.'),
(N'dbo',N'Lessons',N'Description',N'Mô tả nội dung của bài học.'),
(N'dbo',N'Lessons',N'LessonType',N'Loại bài học: VIDEO, INTERACTIVE_VIDEO, QUIZ hoặc DOCUMENT.'),
(N'dbo',N'Lessons',N'DurationSeconds',N'Thời lượng dự kiến của bài học tính bằng giây.'),
(N'dbo',N'Lessons',N'SortOrder',N'Thứ tự hiển thị của bài học trong chương.'),
(N'dbo',N'Lessons',N'IsRequired',N'Cờ cho biết bài học có bắt buộc hoàn thành hay không.'),
(N'dbo',N'Lessons',N'PassingScore',N'Điểm tối thiểu để đạt bài học; rỗng nếu không áp dụng.'),
(N'dbo',N'Lessons',N'Status',N'Trạng thái sử dụng của bài học.'),
(N'dbo',N'Lessons',N'CreatedAt',N'Thời điểm tạo bài học theo UTC.'),
(N'dbo',N'Lessons',N'UpdatedAt',N'Thời điểm cập nhật bài học gần nhất theo UTC.'),
(N'dbo',N'Lessons',N'IsDeleted',N'Cờ xóa mềm của bài học.'),
-- Videos
(N'dbo',N'Videos',N'Id',N'Khóa chính tự tăng của cấu hình video bài học.'),
(N'dbo',N'Videos',N'LessonId',N'ID bài học đang sử dụng video.'),
(N'dbo',N'Videos',N'Title',N'Tên hiển thị của video trong bài học.'),
(N'dbo',N'Videos',N'VideoUrl',N'Đường dẫn phát video; giữ để tương thích dữ liệu cũ.'),
(N'dbo',N'Videos',N'PosterUrl',N'Đường dẫn ảnh đại diện của video.'),
(N'dbo',N'Videos',N'DurationSeconds',N'Thời lượng video tính bằng giây.'),
(N'dbo',N'Videos',N'AllowSeek',N'Cờ cho phép học viên tua đến vị trí chưa xem.'),
(N'dbo',N'Videos',N'AllowSpeed',N'Cờ cho phép học viên thay đổi tốc độ phát.'),
(N'dbo',N'Videos',N'RequiredWatchPercent',N'Tỷ lệ phần trăm video phải xem để được tính hoàn thành.'),
(N'dbo',N'Videos',N'Status',N'Trạng thái sử dụng của video.'),
(N'dbo',N'Videos',N'CreatedAt',N'Thời điểm tạo cấu hình video theo UTC.'),
(N'dbo',N'Videos',N'UpdatedAt',N'Thời điểm cập nhật cấu hình video gần nhất theo UTC.'),
(N'dbo',N'Videos',N'VideoAssetId',N'ID tệp trong thư viện video được bài học sử dụng.'),
-- VideoAssets
(N'dbo',N'VideoAssets',N'Id',N'Khóa chính tự tăng của tài nguyên video.'),
(N'dbo',N'VideoAssets',N'Title',N'Tên hiển thị của tài nguyên video.'),
(N'dbo',N'VideoAssets',N'VideoUrl',N'Đường dẫn tệp video trong vùng lưu trữ dự án.'),
(N'dbo',N'VideoAssets',N'PosterUrl',N'Đường dẫn ảnh đại diện của tài nguyên video.'),
(N'dbo',N'VideoAssets',N'DurationSeconds',N'Thời lượng tài nguyên video tính bằng giây.'),
(N'dbo',N'VideoAssets',N'OriginalFileName',N'Tên gốc của tệp khi được tải lên.'),
(N'dbo',N'VideoAssets',N'FileSize',N'Kích thước tệp video tính bằng byte.'),
(N'dbo',N'VideoAssets',N'MimeType',N'Kiểu nội dung MIME của tệp video.'),
(N'dbo',N'VideoAssets',N'SourceVideoId',N'ID video nguồn dùng khi chuyển đổi dữ liệu cũ sang thư viện.'),
(N'dbo',N'VideoAssets',N'CreatedBy',N'ID người dùng tải lên hoặc tạo tài nguyên video.'),
(N'dbo',N'VideoAssets',N'CreatedAt',N'Thời điểm tạo tài nguyên video theo UTC.'),
(N'dbo',N'VideoAssets',N'UpdatedAt',N'Thời điểm cập nhật tài nguyên video gần nhất theo UTC.'),
(N'dbo',N'VideoAssets',N'Status',N'Trạng thái sử dụng của tài nguyên video.'),
(N'dbo',N'VideoAssets',N'IsDeleted',N'Cờ xóa mềm của tài nguyên video.'),
-- Questions
(N'dbo',N'Questions',N'Id',N'Khóa chính tự tăng của câu hỏi.'),
(N'dbo',N'Questions',N'QuestionType',N'Loại câu hỏi: một lựa chọn, nhiều lựa chọn, đúng/sai hoặc trả lời ngắn.'),
(N'dbo',N'Questions',N'QuestionText',N'Nội dung chính của câu hỏi.'),
(N'dbo',N'Questions',N'Description',N'Thông tin bổ sung hoặc ngữ cảnh của câu hỏi.'),
(N'dbo',N'Questions',N'Explanation',N'Lời giải thích đáp án hiển thị sau khi trả lời.'),
(N'dbo',N'Questions',N'Difficulty',N'Mức độ khó của câu hỏi.'),
(N'dbo',N'Questions',N'DefaultScore',N'Điểm mặc định khi sử dụng câu hỏi.'),
(N'dbo',N'Questions',N'ShortAnswerMode',N'Quy tắc so khớp đáp án cho câu hỏi trả lời ngắn.'),
(N'dbo',N'Questions',N'CreatedBy',N'ID người dùng tạo câu hỏi.'),
(N'dbo',N'Questions',N'CreatedAt',N'Thời điểm tạo câu hỏi theo UTC.'),
(N'dbo',N'Questions',N'UpdatedAt',N'Thời điểm cập nhật câu hỏi gần nhất theo UTC.'),
(N'dbo',N'Questions',N'Status',N'Trạng thái sử dụng của câu hỏi.'),
(N'dbo',N'Questions',N'IsDeleted',N'Cờ xóa mềm của câu hỏi.'),
-- QuestionOptions
(N'dbo',N'QuestionOptions',N'Id',N'Khóa chính tự tăng của phương án trả lời.'),
(N'dbo',N'QuestionOptions',N'QuestionId',N'ID câu hỏi sở hữu phương án.'),
(N'dbo',N'QuestionOptions',N'OptionCode',N'Mã phương án trong phạm vi câu hỏi, ví dụ A, B, C, D.'),
(N'dbo',N'QuestionOptions',N'OptionText',N'Nội dung hiển thị của phương án.'),
(N'dbo',N'QuestionOptions',N'IsCorrect',N'Cờ cho biết phương án là đáp án đúng.'),
(N'dbo',N'QuestionOptions',N'SortOrder',N'Thứ tự hiển thị của phương án.'),
(N'dbo',N'QuestionOptions',N'IsDeleted',N'Cờ xóa mềm của phương án.'),
-- QuestionAnswerKeys
(N'dbo',N'QuestionAnswerKeys',N'Id',N'Khóa chính tự tăng của đáp án chữ.'),
(N'dbo',N'QuestionAnswerKeys',N'QuestionId',N'ID câu hỏi trả lời ngắn.'),
(N'dbo',N'QuestionAnswerKeys',N'AnswerText',N'Nội dung đáp án được chấp nhận.'),
(N'dbo',N'QuestionAnswerKeys',N'IsCaseSensitive',N'Cờ cho biết việc so khớp có phân biệt chữ hoa, chữ thường.'),
(N'dbo',N'QuestionAnswerKeys',N'SortOrder',N'Thứ tự ưu tiên của đáp án được chấp nhận.'),
-- VideoInteractions
(N'dbo',N'VideoInteractions',N'Id',N'Khóa chính tự tăng của tương tác video.'),
(N'dbo',N'VideoInteractions',N'VideoId',N'ID video chứa mốc tương tác.'),
(N'dbo',N'VideoInteractions',N'QuestionId',N'ID câu hỏi được hiển thị tại mốc tương tác.'),
(N'dbo',N'VideoInteractions',N'TimeSeconds',N'Thời điểm bắt đầu tương tác tính từ đầu video, đơn vị giây.'),
(N'dbo',N'VideoInteractions',N'EndTimeSeconds',N'Thời điểm kết thúc vùng tương tác tính bằng giây; có thể rỗng.'),
(N'dbo',N'VideoInteractions',N'InteractionType',N'Loại tương tác được kích hoạt trong video.'),
(N'dbo',N'VideoInteractions',N'Required',N'Cờ bắt buộc học viên phải trả lời tương tác.'),
(N'dbo',N'VideoInteractions',N'PauseVideo',N'Cờ tự động tạm dừng video khi tương tác xuất hiện.'),
(N'dbo',N'VideoInteractions',N'AllowSkip',N'Cờ cho phép học viên bỏ qua tương tác.'),
(N'dbo',N'VideoInteractions',N'Score',N'Điểm tối đa của tương tác.'),
(N'dbo',N'VideoInteractions',N'AttemptLimit',N'Số lần tối đa được phép trả lời tương tác.'),
(N'dbo',N'VideoInteractions',N'SortOrder',N'Thứ tự xử lý khi nhiều tương tác cùng thời điểm.'),
(N'dbo',N'VideoInteractions',N'Status',N'Trạng thái sử dụng của tương tác.'),
(N'dbo',N'VideoInteractions',N'CreatedAt',N'Thời điểm tạo tương tác theo UTC.'),
(N'dbo',N'VideoInteractions',N'UpdatedAt',N'Thời điểm cập nhật tương tác gần nhất theo UTC.'),
(N'dbo',N'VideoInteractions',N'IsDeleted',N'Cờ xóa mềm của tương tác.'),
-- Enrollments
(N'dbo',N'Enrollments',N'Id',N'Khóa chính tự tăng của lượt ghi danh.'),
(N'dbo',N'Enrollments',N'CourseId',N'ID khóa học được ghi danh.'),
(N'dbo',N'Enrollments',N'StudentId',N'ID học viên được ghi danh.'),
(N'dbo',N'Enrollments',N'EnrolledAt',N'Thời điểm ghi danh học viên theo UTC.'),
(N'dbo',N'Enrollments',N'StartedAt',N'Thời điểm học viên bắt đầu học theo UTC.'),
(N'dbo',N'Enrollments',N'CompletedAt',N'Thời điểm học viên hoàn thành khóa học theo UTC.'),
(N'dbo',N'Enrollments',N'Status',N'Trạng thái ghi danh: ENROLLED, IN_PROGRESS, COMPLETED hoặc CANCELLED.'),
(N'dbo',N'Enrollments',N'ProgressPercent',N'Tỷ lệ phần trăm hoàn thành khóa học.'),
(N'dbo',N'Enrollments',N'FinalScore',N'Điểm tổng kết cuối cùng của khóa học.'),
(N'dbo',N'Enrollments',N'LastAccessAt',N'Thời điểm học viên truy cập khóa học gần nhất theo UTC.'),
(N'dbo',N'Enrollments',N'CreatedBy',N'ID người dùng thực hiện ghi danh.'),
-- StudentLessonProgress
(N'dbo',N'StudentLessonProgress',N'Id',N'Khóa chính tự tăng của tiến độ bài học.'),
(N'dbo',N'StudentLessonProgress',N'StudentId',N'ID học viên có tiến độ học.'),
(N'dbo',N'StudentLessonProgress',N'CourseId',N'ID khóa học chứa bài học.'),
(N'dbo',N'StudentLessonProgress',N'LessonId',N'ID bài học được theo dõi.'),
(N'dbo',N'StudentLessonProgress',N'ProgressPercent',N'Tỷ lệ phần trăm hoàn thành bài học.'),
(N'dbo',N'StudentLessonProgress',N'Score',N'Điểm cao nhất hoặc hiện tại của bài học.'),
(N'dbo',N'StudentLessonProgress',N'AttemptCount',N'Tổng số lần học viên thực hiện bài học.'),
(N'dbo',N'StudentLessonProgress',N'Completed',N'Cờ cho biết bài học đã hoàn thành.'),
(N'dbo',N'StudentLessonProgress',N'CompletedAt',N'Thời điểm hoàn thành bài học theo UTC.'),
(N'dbo',N'StudentLessonProgress',N'LastAccessAt',N'Thời điểm truy cập bài học gần nhất theo UTC.'),
(N'dbo',N'StudentLessonProgress',N'CreatedAt',N'Thời điểm tạo bản ghi tiến độ theo UTC.'),
(N'dbo',N'StudentLessonProgress',N'UpdatedAt',N'Thời điểm cập nhật tiến độ gần nhất theo UTC.'),
-- StudentVideoProgress
(N'dbo',N'StudentVideoProgress',N'Id',N'Khóa chính tự tăng của tiến độ video.'),
(N'dbo',N'StudentVideoProgress',N'StudentId',N'ID học viên xem video.'),
(N'dbo',N'StudentVideoProgress',N'CourseId',N'ID khóa học chứa video.'),
(N'dbo',N'StudentVideoProgress',N'LessonId',N'ID bài học chứa video.'),
(N'dbo',N'StudentVideoProgress',N'VideoId',N'ID video được theo dõi.'),
(N'dbo',N'StudentVideoProgress',N'CurrentTimeSeconds',N'Vị trí phát hiện tại của học viên, đơn vị giây.'),
(N'dbo',N'StudentVideoProgress',N'MaxWatchedTimeSeconds',N'Vị trí xa nhất học viên đã xem hợp lệ, đơn vị giây.'),
(N'dbo',N'StudentVideoProgress',N'WatchedSeconds',N'Tổng thời lượng xem hợp lệ, đơn vị giây.'),
(N'dbo',N'StudentVideoProgress',N'WatchPercent',N'Tỷ lệ phần trăm video đã xem hợp lệ.'),
(N'dbo',N'StudentVideoProgress',N'Completed',N'Cờ cho biết video đã đạt điều kiện hoàn thành.'),
(N'dbo',N'StudentVideoProgress',N'StartedAt',N'Thời điểm bắt đầu xem video theo UTC.'),
(N'dbo',N'StudentVideoProgress',N'CompletedAt',N'Thời điểm hoàn thành video theo UTC.'),
(N'dbo',N'StudentVideoProgress',N'LastAccessAt',N'Thời điểm truy cập video gần nhất theo UTC.'),
(N'dbo',N'StudentVideoProgress',N'CreatedAt',N'Thời điểm tạo bản ghi tiến độ video theo UTC.'),
(N'dbo',N'StudentVideoProgress',N'UpdatedAt',N'Thời điểm cập nhật tiến độ video gần nhất theo UTC.'),
(N'dbo',N'StudentVideoProgress',N'RowVersion',N'Phiên bản hàng tự động dùng kiểm soát cập nhật đồng thời.'),
-- StudentAnswers
(N'dbo',N'StudentAnswers',N'Id',N'Khóa chính tự tăng của lần trả lời.'),
(N'dbo',N'StudentAnswers',N'StudentId',N'ID học viên thực hiện câu trả lời.'),
(N'dbo',N'StudentAnswers',N'CourseId',N'ID khóa học phát sinh câu trả lời.'),
(N'dbo',N'StudentAnswers',N'LessonId',N'ID bài học phát sinh câu trả lời.'),
(N'dbo',N'StudentAnswers',N'VideoId',N'ID video phát sinh câu trả lời; rỗng nếu không từ video.'),
(N'dbo',N'StudentAnswers',N'InteractionId',N'ID tương tác video phát sinh câu trả lời.'),
(N'dbo',N'StudentAnswers',N'QuestionId',N'ID câu hỏi được trả lời.'),
(N'dbo',N'StudentAnswers',N'AttemptNumber',N'Số thứ tự lần thử của học viên với câu hỏi.'),
(N'dbo',N'StudentAnswers',N'AnswerText',N'Nội dung trả lời dạng chữ của học viên.'),
(N'dbo',N'StudentAnswers',N'IsCorrect',N'Kết quả đúng/sai; rỗng khi chưa chấm.'),
(N'dbo',N'StudentAnswers',N'ScoreAwarded',N'Số điểm được trao cho lần trả lời.'),
(N'dbo',N'StudentAnswers',N'ReviewStatus',N'Trạng thái chấm hoặc duyệt câu trả lời.'),
(N'dbo',N'StudentAnswers',N'AnsweredAt',N'Thời điểm học viên trả lời theo UTC.'),
(N'dbo',N'StudentAnswers',N'TimeInVideoSeconds',N'Vị trí video khi học viên trả lời, đơn vị giây.'),
(N'dbo',N'StudentAnswers',N'TimeSpentSeconds',N'Thời gian học viên dùng để trả lời, đơn vị giây.'),
(N'dbo',N'StudentAnswers',N'ReviewedBy',N'ID người dùng chấm hoặc duyệt câu trả lời.'),
(N'dbo',N'StudentAnswers',N'ReviewedAt',N'Thời điểm chấm hoặc duyệt câu trả lời theo UTC.'),
(N'dbo',N'StudentAnswers',N'ReviewerComment',N'Nhận xét của người chấm dành cho học viên.'),
-- StudentAnswerOptions
(N'dbo',N'StudentAnswerOptions',N'StudentAnswerId',N'ID lần trả lời của học viên.'),
(N'dbo',N'StudentAnswerOptions',N'QuestionOptionId',N'ID phương án học viên đã chọn.'),
-- LearningSessions
(N'dbo',N'LearningSessions',N'Id',N'Khóa chính tự tăng của phiên học.'),
(N'dbo',N'LearningSessions',N'SessionId',N'Mã UUID duy nhất dùng nhận diện phiên học.'),
(N'dbo',N'LearningSessions',N'StudentId',N'ID học viên tham gia phiên học.'),
(N'dbo',N'LearningSessions',N'CourseId',N'ID khóa học của phiên học.'),
(N'dbo',N'LearningSessions',N'LessonId',N'ID bài học của phiên học.'),
(N'dbo',N'LearningSessions',N'VideoId',N'ID video đang học; có thể rỗng với bài học không phải video.'),
(N'dbo',N'LearningSessions',N'StartedAt',N'Thời điểm bắt đầu phiên học theo UTC.'),
(N'dbo',N'LearningSessions',N'EndedAt',N'Thời điểm kết thúc phiên học theo UTC.'),
(N'dbo',N'LearningSessions',N'WatchDurationSeconds',N'Tổng thời lượng xem trong phiên, đơn vị giây.'),
(N'dbo',N'LearningSessions',N'LastPositionSeconds',N'Vị trí phát cuối cùng trong phiên, đơn vị giây.'),
(N'dbo',N'LearningSessions',N'MaxPositionSeconds',N'Vị trí xa nhất đã xem trong phiên, đơn vị giây.'),
(N'dbo',N'LearningSessions',N'SeekCount',N'Số lần tua video trong phiên.'),
(N'dbo',N'LearningSessions',N'PauseCount',N'Số lần tạm dừng video trong phiên.'),
(N'dbo',N'LearningSessions',N'InteractionCount',N'Số tương tác đã kích hoạt trong phiên.'),
(N'dbo',N'LearningSessions',N'Completed',N'Cờ cho biết phiên đã hoàn thành nội dung học.');

DECLARE @SchemaName SYSNAME, @TableName SYSNAME, @ColumnName SYSNAME, @Description NVARCHAR(1000);

DECLARE table_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT SchemaName, TableName, [Description] FROM @TableDescriptions;
OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @SchemaName, @TableName, @Description;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF OBJECT_ID(QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName), N'U') IS NOT NULL
    BEGIN
        IF EXISTS(
            SELECT 1 FROM sys.extended_properties
            WHERE class = 1
              AND major_id = OBJECT_ID(QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName))
              AND minor_id = 0
              AND name = N'MS_Description'
        )
            EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=@Description,
                @level0type=N'SCHEMA', @level0name=@SchemaName,
                @level1type=N'TABLE', @level1name=@TableName;
        ELSE
            EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=@Description,
                @level0type=N'SCHEMA', @level0name=@SchemaName,
                @level1type=N'TABLE', @level1name=@TableName;
    END;
    FETCH NEXT FROM table_cursor INTO @SchemaName, @TableName, @Description;
END;
CLOSE table_cursor;
DEALLOCATE table_cursor;

DECLARE column_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT SchemaName, TableName, ColumnName, [Description] FROM @ColumnDescriptions;
OPEN column_cursor;
FETCH NEXT FROM column_cursor INTO @SchemaName, @TableName, @ColumnName, @Description;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF COL_LENGTH(QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName), @ColumnName) IS NOT NULL
    BEGIN
        IF EXISTS(
            SELECT 1 FROM sys.extended_properties
            WHERE class = 1
              AND major_id = OBJECT_ID(QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName))
              AND minor_id = COLUMNPROPERTY(OBJECT_ID(QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName)), @ColumnName, 'ColumnId')
              AND name = N'MS_Description'
        )
            EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=@Description,
                @level0type=N'SCHEMA', @level0name=@SchemaName,
                @level1type=N'TABLE', @level1name=@TableName,
                @level2type=N'COLUMN', @level2name=@ColumnName;
        ELSE
            EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=@Description,
                @level0type=N'SCHEMA', @level0name=@SchemaName,
                @level1type=N'TABLE', @level1name=@TableName,
                @level2type=N'COLUMN', @level2name=@ColumnName;
    END;
    FETCH NEXT FROM column_cursor INTO @SchemaName, @TableName, @ColumnName, @Description;
END;
CLOSE column_cursor;
DEALLOCATE column_cursor;

IF EXISTS(
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id=t.schema_id
    JOIN sys.columns c ON c.object_id=t.object_id
    LEFT JOIN sys.extended_properties ep
      ON ep.class=1 AND ep.major_id=t.object_id AND ep.minor_id=c.column_id AND ep.name=N'MS_Description'
    WHERE s.name=N'dbo' AND t.is_ms_shipped=0 AND ep.value IS NULL
)
    THROW 51000, N'Vẫn còn cột trong schema dbo chưa có MS_Description.', 1;

SELECT
    COUNT(DISTINCT t.object_id) AS DescribedTableCount,
    COUNT(*) AS DescribedColumnCount
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id=t.schema_id
JOIN sys.columns c ON c.object_id=t.object_id
JOIN sys.extended_properties ep
  ON ep.class=1 AND ep.major_id=t.object_id AND ep.minor_id=c.column_id AND ep.name=N'MS_Description'
WHERE s.name=N'dbo' AND t.is_ms_shipped=0;
GO
