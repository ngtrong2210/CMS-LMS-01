using LmsCms.Application.Common;
using LmsCms.Application.DTOs;
using LmsCms.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LmsCms.Api.Controllers;

[ApiController, Route("api/cms"), Authorize(Roles = "ADMIN,TEACHER")]
public sealed class ReportsController(IReportService reports) : ControllerBase
{
    [HttpGet("dashboard")]
    public async Task<ActionResult<ApiResponse<DashboardDto>>> Dashboard(CancellationToken cancellationToken) => Ok(ApiResponse<DashboardDto>.Ok(await reports.GetDashboardAsync(cancellationToken)));
}
