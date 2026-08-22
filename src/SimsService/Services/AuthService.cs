using System.Security.Cryptography;
using System.Text;
using Dapper;
using SimsObject.DTOs;
using SimsObject.Interfaces;
using SimsObject;
using SimsData.Data;

namespace SimsService.Services;

public sealed class AuthService(ISqlConnectionFactory connections, ITokenService tokens) : IAuthService
{
    public async Task<AuthResponse?> LoginAsync(LoginRequest request, string? ipAddress, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        var user = await connection.QuerySingleOrDefaultAsync<User>(new CommandDefinition("dbo.LMS_Auth_GetUserByUsername", new { request.Username }, commandType: System.Data.CommandType.StoredProcedure, cancellationToken: cancellationToken));
        if (user is null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash)) return null;
        var permissions = (await connection.QueryAsync<string>(new CommandDefinition("dbo.LMS_Auth_GetUserPermissions", new { UserId = user.Id }, commandType: System.Data.CommandType.StoredProcedure, cancellationToken: cancellationToken))).ToArray();
        var access = tokens.CreateAccessToken(user.Id, user.Username, user.Role);
        var refresh = tokens.CreateRefreshToken();
        var hash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(refresh)));
        await connection.ExecuteAsync(new CommandDefinition("dbo.LMS_RefreshToken_Create", new { UserId = user.Id, TokenHash = hash, ExpiresAt = DateTime.UtcNow.AddDays(14), CreatedIp = ipAddress }, commandType: System.Data.CommandType.StoredProcedure, cancellationToken: cancellationToken));
        await connection.ExecuteAsync(new CommandDefinition("dbo.LMS_Auth_UpdateLastLogin", new { UserId = user.Id }, commandType: System.Data.CommandType.StoredProcedure, cancellationToken: cancellationToken));
        return new AuthResponse(access.Token, refresh, access.ExpiresAt, new UserDto(user.Id, user.Username, user.FullName, user.Email, user.Role, permissions));
    }

    public async Task<UserDto?> GetCurrentUserAsync(long userId, CancellationToken cancellationToken = default)
    {
        using var connection = connections.CreateConnection();
        var user = await connection.QuerySingleOrDefaultAsync<User>(new CommandDefinition("dbo.LMS_Auth_GetUserById", new { UserId = userId }, commandType: System.Data.CommandType.StoredProcedure, cancellationToken: cancellationToken));
        if (user is null) return null;
        var permissions = (await connection.QueryAsync<string>(new CommandDefinition("dbo.LMS_Auth_GetUserPermissions", new { UserId = user.Id }, commandType: System.Data.CommandType.StoredProcedure, cancellationToken: cancellationToken))).ToArray();
        return new UserDto(user.Id, user.Username, user.FullName, user.Email, user.Role, permissions);
    }
}
