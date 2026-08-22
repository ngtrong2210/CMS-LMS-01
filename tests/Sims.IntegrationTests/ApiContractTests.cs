using SimsObject.DTOs;

namespace Sims.IntegrationTests;

public sealed class ApiContractTests
{
    [Fact]
    public void SubmitAnswerRequest_DoesNotAcceptOfficialScore()
    {
        var propertyNames = typeof(SubmitAnswerRequest).GetProperties().Select(x => x.Name).ToArray();
        Assert.DoesNotContain("IsCorrect", propertyNames);
        Assert.DoesNotContain("ScoreAwarded", propertyNames);
        Assert.DoesNotContain("CorrectAnswer", propertyNames);
    }
}
