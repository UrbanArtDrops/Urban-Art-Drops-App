using UrbanArtDropFinder.Domain.Comments;

namespace UrbanArtDropFinder.Domain.Tests;

public sealed class CommentDomainRulesTests
{
    [Fact]
    public void Hide_ClearsReportStateAndMarksCommentHidden()
    {
        var comment = new DropComment
        {
            DropId = Guid.NewGuid(),
            Content = "Please moderate this comment."
        };

        comment.Report("Offensive", DateTimeOffset.UtcNow.AddMinutes(-5));
        comment.Hide(DateTimeOffset.UtcNow);

        Assert.True(comment.IsHidden);
        Assert.False(comment.IsReported);
        Assert.Null(comment.ReportReason);
    }

    [Fact]
    public void DismissReport_ClearsReportMetadata()
    {
        var comment = new DropComment
        {
            DropId = Guid.NewGuid(),
            Content = "Please moderate this comment."
        };

        comment.Report("Spam", DateTimeOffset.UtcNow);
        comment.DismissReport();

        Assert.False(comment.IsReported);
        Assert.Null(comment.ReportReason);
        Assert.Null(comment.ReportedAtUtc);
    }
}
