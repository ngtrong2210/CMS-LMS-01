# Development

Yêu cầu: .NET SDK hỗ trợ target .NET 8, Node.js 20+, SQL Server 2022 Express và npm.

Kiểm tra trước khi bàn giao:

```powershell
dotnet build LmsCms.sln
dotnet test LmsCms.sln --no-build
cd frontend
npm run build
```

Không commit connection string có mật khẩu. Dùng environment variables, .NET User Secrets hoặc `appsettings.Local.json` (đã được ignore).
