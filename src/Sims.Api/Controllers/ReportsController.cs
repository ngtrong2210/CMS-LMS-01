using SimsObject.Common;
using SimsObject.DTOs;
using SimsObject.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Sims.Api.Controllers;

[ApiController, Route("api/cms"), Authorize(Roles = "ADMIN,TEACHER")]
public sealed class ReportsController(IReportService reports) : ControllerBase
{
    [HttpGet("dashboard")]
    public async Task<ActionResult<ApiResponse<DashboardDto>>> Dashboard(CancellationToken cancellationToken) => Ok(ApiResponse<DashboardDto>.Ok(await reports.GetDashboardAsync(cancellationToken)));
    [HttpGet("reports/{report}")]
    public async Task<ActionResult<ApiResponse<object>>> Report(string report,CancellationToken cancellationToken)=>Ok(ApiResponse<object>.Ok(await reports.GetReportAsync(report,cancellationToken)));
}
