namespace LmsCms.Application.Common;

public static class InputGuard
{
    public static string? OptionalText(string? value, int maximumLength, string fieldName)
    {
        if (string.IsNullOrWhiteSpace(value)) return null;
        var normalized = value.Trim();
        if (normalized.Length > maximumLength)
            throw new ArgumentException($"{fieldName} không được vượt quá {maximumLength} ký tự.");
        return normalized;
    }

    public static string? OptionalChoice(string? value, string fieldName, params string[] allowedValues)
    {
        if (string.IsNullOrWhiteSpace(value)) return null;
        var normalized = value.Trim().ToUpperInvariant();
        if (!allowedValues.Contains(normalized, StringComparer.Ordinal))
            throw new ArgumentException($"{fieldName} không hợp lệ.");
        return normalized;
    }

    public static string? BoundedText(string? value, int maximumLength, string fieldName)
    {
        if (value is null) return null;
        if (value.Length > maximumLength)
            throw new ArgumentException($"{fieldName} không được vượt quá {maximumLength} ký tự.");
        return value;
    }

    public static long[] PositiveDistinctIds(IEnumerable<long> values, string fieldName)
    {
        var ids = values.Distinct().ToArray();
        if (ids.Any(id => id <= 0))
            throw new ArgumentException($"{fieldName} chỉ được chứa mã định danh lớn hơn 0.");
        return ids;
    }

    public static string[] TextItems(IEnumerable<string> values, int maximumItems, int maximumItemLength, string fieldName)
    {
        var items = values.ToArray();
        if (items.Length > maximumItems || items.Any(value => value?.Length > maximumItemLength))
            throw new ArgumentException($"{fieldName} vượt quá giới hạn cho phép.");
        return items;
    }
}
