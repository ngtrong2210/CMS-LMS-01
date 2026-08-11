using LmsCms.Application.Common;
using Microsoft.Data.SqlClient;

namespace LmsCms.Api.Middleware;

public sealed class GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try { await next(context); }
        catch (UnauthorizedAccessException exception)
        {
            context.Response.StatusCode = StatusCodes.Status403Forbidden;
            context.Response.ContentType = "application/json";
            await context.Response.WriteAsJsonAsync(ApiResponse<object>.Fail(exception.Message));
        }
        catch (ArgumentException exception)
        {
            context.Response.StatusCode = StatusCodes.Status400BadRequest;
            context.Response.ContentType = "application/json";
            await context.Response.WriteAsJsonAsync(ApiResponse<object>.Fail(exception.Message));
        }
        catch (SqlException exception) when (exception.Number is >= 50001 and <= 50009)
        {
            var status = exception.Number switch
            {
                50003 => StatusCodes.Status403Forbidden,
                50004 or 50006 => StatusCodes.Status409Conflict,
                _ => StatusCodes.Status400BadRequest
            };
            logger.LogWarning("Business rule rejected request. Code: {Code}, TraceId: {TraceId}", exception.Number, context.TraceIdentifier);
            context.Response.StatusCode = status;
            context.Response.ContentType = "application/json";
            await context.Response.WriteAsJsonAsync(ApiResponse<object>.Fail(exception.Message));
        }
        catch (Exception exception)
        {
            logger.LogError(exception, "Unhandled request error. TraceId: {TraceId}", context.TraceIdentifier);
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;
            context.Response.ContentType = "application/json";
            await context.Response.WriteAsJsonAsync(ApiResponse<object>.Fail("Đã xảy ra lỗi hệ thống.", context.TraceIdentifier));
        }
    }
}
