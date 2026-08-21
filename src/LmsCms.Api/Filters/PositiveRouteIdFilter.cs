using LmsCms.Application.Common;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace LmsCms.Api.Filters;

/// <summary>
/// Rejects numeric route identifiers that are zero or negative before they reach
/// the service/data-access layer. The route constraints already reject values
/// that are not valid Int64 values.
/// </summary>
public sealed class PositiveRouteIdFilter : IActionFilter
{
    public void OnActionExecuting(ActionExecutingContext context)
    {
        foreach (var routeValue in context.RouteData.Values)
        {
            if (!routeValue.Key.EndsWith("Id", StringComparison.OrdinalIgnoreCase)
                && !routeValue.Key.Equals("id", StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            if (long.TryParse(routeValue.Value?.ToString(), out var id) && id <= 0)
            {
                context.Result = new BadRequestObjectResult(
                    ApiResponse<object>.Fail("Mã định danh phải lớn hơn 0."));
                return;
            }
        }
    }

    public void OnActionExecuted(ActionExecutedContext context)
    {
    }
}
