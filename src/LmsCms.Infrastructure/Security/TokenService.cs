using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using LmsCms.Application.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace LmsCms.Infrastructure.Security;

public sealed class TokenService(IConfiguration configuration) : ITokenService
{
    public (string Token, DateTime ExpiresAt) CreateAccessToken(long userId, string username, string role)
    {
        var section = configuration.GetSection("Jwt");
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(section["Key"] ?? throw new InvalidOperationException("JWT key is missing.")));
        var expires = DateTime.UtcNow.AddMinutes(int.TryParse(section["AccessTokenMinutes"], out var minutes) ? minutes : 60);
        var claims = new[] { new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()), new Claim("userId", userId.ToString()), new Claim("username", username), new Claim(ClaimTypes.Role, role), new Claim("roles", role) };
        var token = new JwtSecurityToken(section["Issuer"], section["Audience"], claims, expires: expires, signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256));
        return (new JwtSecurityTokenHandler().WriteToken(token), expires);
    }
    public string CreateRefreshToken() => Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
}
