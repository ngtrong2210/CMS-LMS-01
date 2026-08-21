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
            await context.Response.WriteAsJsonAsync(ApiResponse<object>.Fail(GetPublicBusinessMessage(exception.Number)));
        }
        catch (Exception exception)
        {
            logger.LogError(exception, "Unhandled request error. TraceId: {TraceId}", context.TraceIdentifier);
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;
            context.Response.ContentType = "application/json";
            await context.Response.WriteAsJsonAsync(ApiResponse<object>.Fail("Đã xảy ra lỗi hệ thống.", context.TraceIdentifier));
        }
    }

    private static string GetPublicBusinessMessage(int errorNumber) => errorNumber switch
    {
        50001 => "Dữ liệu yêu cầu không hợp lệ.",
        50002 => "Không tìm thấy dữ liệu yêu cầu.",
        50003 => "Bạn không có quyền thực hiện thao tác này.",
        50004 => "Không thể thực hiện thao tác ở trạng thái hiện tại.",
        50005 => "Dữ liệu đã phát sinh kết quả và không thể thay đổi trực tiếp.",
        50006 => "Thao tác xung đột với dữ liệu hiện tại.",
        50007 => "Dữ liệu vượt quá giới hạn cho phép.",
        50008 => "Chức năng hiện không khả dụng.",
        50009 => "Loại dữ liệu không được hỗ trợ.",
        _ => "Không thể xử lý yêu cầu."
    };
}
