Set Ansi_nulls On;
Set Quoted_identifier On;
Go

If Col_length(N'dbo.SIM_VideoAssets', N'SourceType') Is Null
Begin
    Alter Table dbo.SIM_VideoAssets
        Add SourceType Varchar(20) Not Null Constraint DF_SIM_VideoAssets_SourceType Default 'LOCAL';
End;

If Col_length(N'dbo.SIM_Videos', N'SourceType') Is Null
Begin
    Alter Table dbo.SIM_Videos
        Add SourceType Varchar(20) Not Null Constraint DF_SIM_Videos_SourceType Default 'LOCAL';
End;

If Col_length(N'dbo.SIM_VideoVersions', N'SourceType') Is Null
Begin
    Alter Table dbo.SIM_VideoVersions
        Add SourceType Varchar(20) Not Null Constraint DF_SIM_VideoVersions_SourceType Default 'LOCAL';
End;
Go

If Not Exists
    (
        Select
            1
        From sys.check_constraints
        Where (sys.check_constraints.parent_object_id = Object_id(N'dbo.SIM_VideoAssets'))
            And (sys.check_constraints.name = N'CK_SIM_VideoAssets_SourceType')
    )
    Alter Table dbo.SIM_VideoAssets
        Add Constraint CK_SIM_VideoAssets_SourceType Check (SourceType In ('LOCAL', 'YOUTUBE'));

If Not Exists
    (
        Select
            1
        From sys.check_constraints
        Where (sys.check_constraints.parent_object_id = Object_id(N'dbo.SIM_Videos'))
            And (sys.check_constraints.name = N'CK_SIM_Videos_SourceType')
    )
    Alter Table dbo.SIM_Videos
        Add Constraint CK_SIM_Videos_SourceType Check (SourceType In ('LOCAL', 'YOUTUBE'));

If Not Exists
    (
        Select
            1
        From sys.check_constraints
        Where (sys.check_constraints.parent_object_id = Object_id(N'dbo.SIM_VideoVersions'))
            And (sys.check_constraints.name = N'CK_SIM_VideoVersions_SourceType')
    )
    Alter Table dbo.SIM_VideoVersions
        Add Constraint CK_SIM_VideoVersions_SourceType Check (SourceType In ('LOCAL', 'YOUTUBE'));

Declare @tblSourceTypeDescriptions Table
(
    TableName Sysname Not Null,
    DescriptionValue Nvarchar(1000) Not Null
);

Insert @tblSourceTypeDescriptions
(
    TableName,
    DescriptionValue
)
Values
    (N'SIM_VideoAssets', N'Loại nguồn video trong thư viện: LOCAL là file tải lên Media, YOUTUBE là liên kết YouTube.'),
    (N'SIM_Videos', N'Loại nguồn phát hiện tại của video tương tác: LOCAL hoặc YOUTUBE.'),
    (N'SIM_VideoVersions', N'Loại nguồn được chụp tại phiên bản video: LOCAL hoặc YOUTUBE.');

Declare @DescriptionTableName Sysname,
    @DescriptionValue Nvarchar(1000);

Declare source_type_description_cursor Cursor Local Fast_forward For
Select
    sourceTypeDescription.TableName,
    sourceTypeDescription.DescriptionValue
From @tblSourceTypeDescriptions sourceTypeDescription;

Open source_type_description_cursor;
Fetch Next From source_type_description_cursor Into @DescriptionTableName, @DescriptionValue;

While @@Fetch_status = 0
Begin
    If Exists
        (
            Select
                1
            From sys.extended_properties
            Where (sys.extended_properties.class = 1)
                And (sys.extended_properties.major_id = Object_id(N'dbo.' + @DescriptionTableName))
                And (sys.extended_properties.minor_id = Columnproperty(Object_id(N'dbo.' + @DescriptionTableName), N'SourceType', 'ColumnId'))
                And (sys.extended_properties.name = N'MS_Description')
        )
        Exec sys.sp_updateextendedproperty @name = N'MS_Description', @value = @DescriptionValue, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = @DescriptionTableName, @level2type = N'COLUMN', @level2name = N'SourceType';
    Else
        Exec sys.sp_addextendedproperty @name = N'MS_Description', @value = @DescriptionValue, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = @DescriptionTableName, @level2type = N'COLUMN', @level2name = N'SourceType';

    Fetch Next From source_type_description_cursor Into @DescriptionTableName, @DescriptionValue;
End;

Close source_type_description_cursor;
Deallocate source_type_description_cursor;
Go

Create Or Alter View dbo.VideoAssets
As
Select
    dbo.SIM_VideoAssets.VideoAssetID Id,
    dbo.SIM_VideoAssets.Title,
    dbo.SIM_VideoAssets.SourceType,
    dbo.SIM_VideoAssets.VideoUrl,
    dbo.SIM_VideoAssets.PosterUrl,
    dbo.SIM_VideoAssets.DurationSeconds,
    dbo.SIM_VideoAssets.OriginalFileName,
    dbo.SIM_VideoAssets.FileSize,
    dbo.SIM_VideoAssets.MimeType,
    dbo.SIM_VideoAssets.SourceVideoID SourceVideoId,
    dbo.SIM_VideoAssets.CreatedByUserID CreatedBy,
    dbo.SIM_VideoAssets.ShareScope,
    dbo.SIM_VideoAssets.CreatedAt,
    dbo.SIM_VideoAssets.UpdatedAt,
    dbo.SIM_VideoAssets.Status,
    dbo.SIM_VideoAssets.IsDeleted
From dbo.SIM_VideoAssets;
Go

Create Or Alter View dbo.VideoVersions
As
Select
    dbo.SIM_VideoVersions.VideoVersionID Id,
    dbo.SIM_VideoVersions.VideoID VideoId,
    dbo.SIM_VideoVersions.VersionNumber,
    dbo.SIM_VideoVersions.Title,
    dbo.SIM_VideoVersions.SourceType,
    dbo.SIM_VideoVersions.VideoUrl,
    dbo.SIM_VideoVersions.PosterUrl,
    dbo.SIM_VideoVersions.DurationSeconds,
    dbo.SIM_VideoVersions.AllowSeek,
    dbo.SIM_VideoVersions.AllowSpeed,
    dbo.SIM_VideoVersions.RequiredWatchPercent,
    dbo.SIM_VideoVersions.OriginalFileName,
    dbo.SIM_VideoVersions.FileSize,
    dbo.SIM_VideoVersions.MimeType,
    dbo.SIM_VideoVersions.ChangeSummary,
    dbo.SIM_VideoVersions.VersionStatus,
    dbo.SIM_VideoVersions.CreatedByUserID CreatedBy,
    dbo.SIM_VideoVersions.CreatedAt,
    dbo.SIM_VideoVersions.PublishedByUserID PublishedBy,
    dbo.SIM_VideoVersions.PublishedAt,
    dbo.SIM_VideoVersions.RowVersion
From dbo.SIM_VideoVersions;
Go

Create Or Alter View dbo.Videos
As
Select
    dbo.SIM_Videos.VideoID Id,
    dbo.SIM_Videos.VideoAssetID VideoAssetId,
    dbo.SIM_Videos.CurrentVideoVersionID CurrentVideoVersionId,
    dbo.SIM_Videos.Title,
    dbo.SIM_Videos.SourceType,
    dbo.SIM_Videos.VideoUrl,
    dbo.SIM_Videos.PosterUrl,
    dbo.SIM_Videos.DurationSeconds,
    dbo.SIM_Videos.AllowSeek,
    dbo.SIM_Videos.AllowSpeed,
    dbo.SIM_Videos.RequiredWatchPercent,
    dbo.SIM_Videos.Status,
    dbo.SIM_Videos.CreatedAt,
    dbo.SIM_Videos.UpdatedAt
From dbo.SIM_Videos;
Go
