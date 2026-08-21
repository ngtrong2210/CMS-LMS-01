:on error exit

Set Nocount On;
Set Xact_abort On;

Print N'=====================================================';
Print N'LMS/CMS PRODUCTION SYNC 2026-08-21';
Print N'Không xóa dữ liệu, không chạy demo seed, không xử lý Media.';
Print N'=====================================================';
Go

-- =====================================================
-- 1. Tables and required configuration
-- =====================================================
:r .\database\migrations\006_SystemAdministration.sql
:r .\database\migrations\007_AcademicTrainingModel.sql
:r .\database\migrations\009_CompleteClassSubjectLearningFlow.sql
:r .\database\migrations\011_QuizLearningFlow.sql
:r .\database\migrations\012_LessonComments.sql
:r .\database\migrations\013_InteractiveContent.sql

-- =====================================================
-- 2. Columns
-- Các cột được bổ sung idempotent trong các migration ở mục 1.
-- =====================================================

-- =====================================================
-- 3. Constraints
-- Các constraint được kiểm tra tồn tại trước khi tạo trong migration.
-- =====================================================

-- =====================================================
-- 4. Indexes
-- =====================================================
:r .\database\indexes\001_Indexes.sql

-- =====================================================
-- 5. Stored Procedures
-- CREATE OR ALTER đồng bộ toàn bộ contract SQL với backend hiện tại.
-- =====================================================
:r .\database\stored-procedures\Academic.sql
:r .\database\stored-procedures\AcademicCompletion.sql
:r .\database\stored-procedures\Auth.sql
:r .\database\stored-procedures\Content.sql
:r .\database\stored-procedures\Courses.sql
:r .\database\stored-procedures\InteractiveContent.sql
:r .\database\stored-procedures\Notifications.sql
:r .\database\stored-procedures\Progress.sql
:r .\database\stored-procedures\Questions.sql
:r .\database\stored-procedures\Quiz.sql
:r .\database\stored-procedures\Reports.sql
:r .\database\stored-procedures\Search.sql
:r .\database\stored-procedures\Students.sql
:r .\database\stored-procedures\SystemAdministration.sql
:r .\database\stored-procedures\VideoVersioning.sql

-- =====================================================
-- 6. Required configuration data
-- Chỉ cấu hình hệ thống idempotent từ migration 006; không chạy demo seed.
-- =====================================================

Set Nocount On;

If Exists
(
    Select
        1
    From sys.tables
    Where (schema_id = Schema_id(N'dbo'))
        And (name In (N'SIM_Courses', N'SIM_Lessons', N'LMS_Questions', N'LMS_StudentAnswers', N'LMS_AssignmentSubmissions'))
    Group By schema_id
    Having Count(*) = 5
)
    Print N'PRODUCTION_SYNC_SCHEMA_OK';
Else
    Throw 51000, N'Production sync validation failed: required tables are missing.', 1;
Go

Print N'PRODUCTION_SYNC_COMPLETED';
Go
