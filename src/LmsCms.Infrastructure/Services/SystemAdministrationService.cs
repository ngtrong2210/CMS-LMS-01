using System.Data;
using System.Text.Json;
using Dapper;
using LmsCms.Application.Common;
using LmsCms.Application.DTOs;
using LmsCms.Application.Interfaces;
using LmsCms.Infrastructure.Data;

namespace LmsCms.Infrastructure.Services;

public sealed class SystemAdministrationService(ISqlConnectionFactory connections) : ISystemAdministrationService
{
    public async Task<PagedResult<object>> GetUsersAsync(
        string? search,
        string? roleCode,
        string? status,
        int page,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        using var database = connections.CreateConnection();
        using var result = await database.QueryMultipleAsync(new CommandDefinition(
            "dbo.SYS_User_GetList",
            new { Search = Normalize(search), RoleCode = Normalize(roleCode), Status = Normalize(status), Page = page, PageSize = pageSize },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));
        var users = (await result.ReadAsync<SystemUserListItemDto>()).Cast<object>().ToArray();
        var total = await result.ReadSingleAsync<int>();
        return new PagedResult<object>(users, page, pageSize, total);
    }

    public async Task<object?> GetUserAsync(long userId, CancellationToken cancellationToken = default)
    {
        using var database = connections.CreateConnection();
        using var result = await database.QueryMultipleAsync(new CommandDefinition(
            "dbo.SYS_User_GetByID",
            new { UserID = userId },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));
        var user = await result.ReadSingleOrDefaultAsync<SystemUserDetailDto>();
        if (user is null) return null;
        var roleCodes = (await result.ReadAsync<string>()).ToArray();
        return new { User = user, RoleCodes = roleCodes };
    }

    public async Task<long> CreateUserAsync(UserSaveRequest request, long actorUserId, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 6)
            throw new ArgumentException("Mật khẩu tài khoản mới phải có ít nhất 6 ký tự.");

        using var database = connections.CreateConnection();
        return await database.QuerySingleAsync<long>(new CommandDefinition(
            "dbo.SYS_User_Create",
            CreateUserParameters(request, BCrypt.Net.BCrypt.HashPassword(request.Password, workFactor: 11), actorUserId),
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken));
    }

    public async Task<bool> UpdateUserAsync(long userId, UserSaveRequest request, long actorUserId, CancellationToken cancellationToken = default)
    {
        var passwordHash = string.IsNullOrWhiteSpace(request.Password)
            ? null
            : BCrypt.Net.BCrypt.HashPassword(request.Password, workFactor: 11);
        using var database = connections.CreateConnection();
        return await database.ExecuteScalarAsync<int>(new CommandDefinition(
            "dbo.SYS_User_Update",
            new
            {
                UserID = userId,
                request.FullName,
                request.Email,
                request.StudentCode,
                request.TeacherCode,
                request.AvatarUrl,
                request.Status,
                PasswordHash = passwordHash,
                RoleCodesJson = JsonSerializer.Serialize(request.RoleCodes.Distinct(StringComparer.OrdinalIgnoreCase)),
                ActorUserID = actorUserId
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken)) > 0;
    }

    public async Task<bool> SetUserStatusAsync(long userId, string status, long actorUserId, CancellationToken cancellationToken = default)
    {
        using var database = connections.CreateConnection();
        return await database.ExecuteScalarAsync<int>(new CommandDefinition(
            "dbo.SYS_User_SetStatus",
            new { UserID = userId, Status = status, ActorUserID = actorUserId },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken)) > 0;
    }

    public async Task<IReadOnlyCollection<object>> GetRolesAsync(CancellationToken cancellationToken = default)
    {
        using var database = connections.CreateConnection();
        return (await database.QueryAsync<SystemRoleDto>(new CommandDefinition(
            "dbo.SYS_Role_GetList",
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken))).Cast<object>().ToArray();
    }

    public async Task<IReadOnlyCollection<object>> GetRolePermissionsAsync(long roleId, CancellationToken cancellationToken = default)
    {
        using var database = connections.CreateConnection();
        return (await database.QueryAsync<SystemPermissionDto>(new CommandDefinition(
            "dbo.SYS_Role_GetPermissions",
            new { RoleID = roleId },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken))).Cast<object>().ToArray();
    }

    public async Task<bool> SaveRolePermissionsAsync(
        long roleId,
        RolePermissionsSaveRequest request,
        long actorUserId,
        CancellationToken cancellationToken = default)
    {
        using var database = connections.CreateConnection();
        return await database.ExecuteScalarAsync<int>(new CommandDefinition(
            "dbo.SYS_Role_SavePermissions",
            new
            {
                RoleID = roleId,
                PermissionCodesJson = JsonSerializer.Serialize(request.PermissionCodes.Distinct(StringComparer.OrdinalIgnoreCase)),
                ActorUserID = actorUserId
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken)) > 0;
    }

    public async Task<IReadOnlyCollection<object>> GetSettingsAsync(CancellationToken cancellationToken = default)
    {
        using var database = connections.CreateConnection();
        return (await database.QueryAsync<SystemSettingDto>(new CommandDefinition(
            "dbo.SYS_SystemSetting_GetList",
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken))).Cast<object>().ToArray();
    }

    public async Task<int> SaveSettingsAsync(
        SystemSettingsSaveRequest request,
        long actorUserId,
        CancellationToken cancellationToken = default)
    {
        using var database = connections.CreateConnection();
        database.Open();
        using var transaction = database.BeginTransaction();
        var updated = 0;
        foreach (var item in request.Items)
        {
            updated += await database.ExecuteScalarAsync<int>(new CommandDefinition(
                "dbo.SYS_SystemSetting_Update",
                new { item.SettingKey, item.SettingValue, ActorUserID = actorUserId },
                transaction,
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken));
        }
        transaction.Commit();
        return updated;
    }

    private static object CreateUserParameters(UserSaveRequest request, string passwordHash, long actorUserId) => new
    {
        request.Username,
        PasswordHash = passwordHash,
        request.FullName,
        request.Email,
        request.StudentCode,
        request.TeacherCode,
        request.AvatarUrl,
        request.Status,
        RoleCodesJson = JsonSerializer.Serialize(request.RoleCodes.Distinct(StringComparer.OrdinalIgnoreCase)),
        ActorUserID = actorUserId
    };

    private static string? Normalize(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
