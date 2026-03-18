using Microsoft.EntityFrameworkCore;
using UrbanArtDropFinder.Domain.Art;
using UrbanArtDropFinder.Domain.Comments;
using UrbanArtDropFinder.Domain.Configuration;
using UrbanArtDropFinder.Domain.Drops;
using UrbanArtDropFinder.Domain.Users;

namespace UrbanArtDropFinder.Persistence.Db;

public sealed class UrbanArtDbContext : DbContext
{
    public UrbanArtDbContext(DbContextOptions<UrbanArtDbContext> options)
        : base(options)
    {
    }

    public DbSet<UserAccount> UserAccounts => Set<UserAccount>();
    public DbSet<UserNotification> UserNotifications => Set<UserNotification>();
    public DbSet<UserProfileImage> UserProfileImages => Set<UserProfileImage>();
    public DbSet<UserProviderLink> UserProviderLinks => Set<UserProviderLink>();
    public DbSet<ArtPiece> ArtPieces => Set<ArtPiece>();
    public DbSet<ArtPieceAssetFile> ArtPieceAssetFiles => Set<ArtPieceAssetFile>();
    public DbSet<ArtPiecePhoto> ArtPiecePhotos => Set<ArtPiecePhoto>();
    public DbSet<Drop> Drops => Set<Drop>();
    public DbSet<DropItem> DropItems => Set<DropItem>();
    public DbSet<DropLocationPhoto> DropLocationPhotos => Set<DropLocationPhoto>();
    public DbSet<DropSocialChannelSelection> DropSocialChannelSelections => Set<DropSocialChannelSelection>();
    public DbSet<DropComment> DropComments => Set<DropComment>();
    public DbSet<AppConfiguration> AppConfigurations => Set<AppConfiguration>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<UserAccount>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Email).IsRequired();
            entity.Property(x => x.UserName).IsRequired();
            entity.Property(x => x.MfaSecretKey).HasMaxLength(128);
            entity.HasIndex(x => x.Email).IsUnique();
            entity.HasIndex(x => x.UserName).IsUnique();
        });

        modelBuilder.Entity<UserNotification>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Title).IsRequired().HasMaxLength(200);
            entity.Property(x => x.Message).IsRequired().HasMaxLength(2000);
            entity.Property(x => x.Category).IsRequired().HasMaxLength(64);
            entity.Property(x => x.RelatedEntityType).HasMaxLength(64);
            entity.HasIndex(x => new { x.UserAccountId, x.CreatedAtUtc });
        });

        modelBuilder.Entity<UserProfileImage>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.BinaryData).IsRequired();
            entity.Property(x => x.ContentType).IsRequired().HasMaxLength(255);
            entity.HasIndex(x => x.UserAccountId).IsUnique();
        });

        modelBuilder.Entity<UserProviderLink>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Provider).IsRequired();
            entity.Property(x => x.ProviderSubject).IsRequired();
            entity.HasIndex(x => new { x.Provider, x.ProviderSubject }).IsUnique();
        });

        modelBuilder.Entity<ArtPiece>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Title).HasMaxLength(200).IsRequired();
            entity.Property(x => x.Subtitle).HasMaxLength(200).IsRequired();
            entity.Property(x => x.Description).HasMaxLength(3000).IsRequired();
            entity.Property(x => x.ReportReason).HasMaxLength(1000);
            entity.HasMany(x => x.Photos).WithOne().HasForeignKey(x => x.ArtPieceId);
            entity.HasOne(x => x.AssetFile).WithOne().HasForeignKey<ArtPieceAssetFile>(x => x.ArtPieceId);
        });

        modelBuilder.Entity<ArtPieceAssetFile>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.BinaryData).IsRequired();
            entity.Property(x => x.ContentType).IsRequired().HasMaxLength(255);
            entity.Property(x => x.FileName).IsRequired().HasMaxLength(255);
            entity.HasIndex(x => x.ArtPieceId).IsUnique();
        });

        modelBuilder.Entity<ArtPiecePhoto>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.BinaryData).IsRequired();
            entity.Property(x => x.ContentType).IsRequired().HasMaxLength(255);
        });

        modelBuilder.Entity<Drop>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.DropMakerComment).HasMaxLength(1000);
            entity.HasMany(x => x.Items).WithOne().HasForeignKey(x => x.DropId);
            entity.HasMany(x => x.LocationPhotos).WithOne().HasForeignKey(x => x.DropId);
            entity.HasMany(x => x.SocialChannels).WithOne().HasForeignKey(x => x.DropId);
        });

        modelBuilder.Entity<DropItem>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.QrToken).IsRequired().HasMaxLength(512);
            entity.HasIndex(x => x.QrToken).IsUnique();
        });

        modelBuilder.Entity<DropLocationPhoto>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.BinaryData).IsRequired();
            entity.Property(x => x.ContentType).IsRequired().HasMaxLength(255);
        });

        modelBuilder.Entity<DropSocialChannelSelection>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Channel).IsRequired().HasMaxLength(64);
            entity.HasIndex(x => new { x.DropId, x.Channel }).IsUnique();
        });

        modelBuilder.Entity<DropComment>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Content).IsRequired().HasMaxLength(2000);
            entity.Property(x => x.ReportReason).HasMaxLength(1000);
            entity.HasIndex(x => x.DropId);
        });

        modelBuilder.Entity<AppConfiguration>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.PublicAppBaseUrl).HasMaxLength(512);
            entity.Property(x => x.SmtpHost).HasMaxLength(512);
        });

        base.OnModelCreating(modelBuilder);
    }
}
