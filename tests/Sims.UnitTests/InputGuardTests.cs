using SimsObject.Common;

namespace Sims.UnitTests;

public sealed class InputGuardTests
{
    [Theory]
    [InlineData("O'Brien")]
    [InlineData("' OR '1'='1")]
    [InlineData("'; SELECT 1; --")]
    public void OptionalText_PreservesSqlSpecialCharacters(string value)
    {
        Assert.Equal(value, InputGuard.OptionalText(value, 250, "Kiểm thử"));
    }

    [Fact]
    public void BoundedText_PreservesLeadingAndTrailingWhitespace()
    {
        const string value = "  Hôm nay em học phần 'JOIN' trong SQL.  ";

        Assert.Equal(value, InputGuard.BoundedText(value, 250, "Nội dung bài làm"));
    }

    [Fact]
    public void OptionalChoice_RejectsValuesOutsideWhitelist()
    {
        Assert.Throws<ArgumentException>(() =>
            InputGuard.OptionalChoice("CreatedAt; Drop Table", "Sắp xếp", "CREATEDAT", "TITLE"));
    }

    [Fact]
    public void PositiveDistinctIds_RejectsNonPositiveIds()
    {
        Assert.Throws<ArgumentException>(() => InputGuard.PositiveDistinctIds([1, 0, -1], "Danh sách ID"));
    }
}
