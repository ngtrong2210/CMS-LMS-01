using System.Security.Claims;
using LmsCms.Application.Common;
using LmsCms.Application.DTOs;
using LmsCms.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LmsCms.Api.Controllers;

[ApiController, Route("api")]
public sealed class QuizController(IQuizService quizzes) : ControllerBase
{
    private long UserId => long.Parse(User.FindFirstValue("userId")!);
    private bool IsAdmin => User.IsInRole("ADMIN");

    [Authorize(Roles = "ADMIN,TEACHER")]
    [HttpGet("lessons/{lessonId:long}/quiz")]
    public async Task<ActionResult<ApiResponse<object>>> GetForTeacher(long lessonId, CancellationToken cancellationToken) =>
        Ok(ApiResponse<object>.Ok(await quizzes.GetForTeacherAsync(lessonId, UserId, IsAdmin, cancellationToken)));

    [Authorize(Roles = "ADMIN,TEACHER")]
    [HttpPut("lessons/{lessonId:long}/quiz")]
    public async Task<ActionResult<ApiResponse<object>>> Save(long lessonId, QuizSaveRequest request, CancellationToken cancellationToken) =>
        Ok(ApiResponse<object>.Ok(await quizzes.SaveAsync(lessonId, request, UserId, IsAdmin, cancellationToken), "Đã lưu cấu hình bài kiểm tra."));

    [Authorize(Roles = "STUDENT")]
    [HttpGet("lms/lessons/{lessonId:long}/quiz")]
    public async Task<ActionResult<ApiResponse<object>>> GetForStudent(long lessonId, CancellationToken cancellationToken) =>
        Ok(ApiResponse<object>.Ok(await quizzes.GetForStudentAsync(lessonId, UserId, cancellationToken)));

    [Authorize(Roles = "STUDENT")]
    [HttpPost("lms/lessons/{lessonId:long}/quiz-attempts")]
    public async Task<ActionResult<ApiResponse<object>>> StartAttempt(long lessonId, CancellationToken cancellationToken) =>
        Ok(ApiResponse<object>.Ok(await quizzes.StartAttemptAsync(lessonId, UserId, cancellationToken)));

    [Authorize(Roles = "STUDENT")]
    [HttpPost("lms/quiz-attempts/{quizAttemptId:long}/submit")]
    public async Task<ActionResult<ApiResponse<object>>> SubmitAttempt(long quizAttemptId, QuizSubmitRequest request, CancellationToken cancellationToken) =>
        Ok(ApiResponse<object>.Ok(await quizzes.SubmitAttemptAsync(quizAttemptId, UserId, request, cancellationToken), "Đã nộp bài kiểm tra."));
}
