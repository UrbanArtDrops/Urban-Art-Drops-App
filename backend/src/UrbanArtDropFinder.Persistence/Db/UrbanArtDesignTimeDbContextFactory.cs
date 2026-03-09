using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace UrbanArtDropFinder.Persistence.Db;

public sealed class UrbanArtDesignTimeDbContextFactory : IDesignTimeDbContextFactory<UrbanArtDbContext>
{
    public UrbanArtDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<UrbanArtDbContext>();
        optionsBuilder.UseSqlServer(
            "Server=(localdb)\\mssqllocaldb;Database=UrbanArtDropFinder.DesignTime;Trusted_Connection=True;TrustServerCertificate=True;");
        return new UrbanArtDbContext(optionsBuilder.Options);
    }
}
