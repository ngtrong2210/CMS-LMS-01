using SimsObject.Common;

namespace Sims.UnitTests;

public sealed class ApiResponseTests
{
    [Fact]
    public void Ok_CreatesSuccessfulResponse()
    {
        var result = ApiResponse<int>.Ok(42);
        Assert.True(result.Success);
        Assert.Equal(42, result.Data);
        Assert.Empty(result.Errors);
    }

    [Fact]
    public void PagedResult_CalculatesTotalPages()
    {
        var result = new PagedResult<int>([1, 2], 1, 2, 5);
        Assert.Equal(3, result.TotalPages);
    }
}
