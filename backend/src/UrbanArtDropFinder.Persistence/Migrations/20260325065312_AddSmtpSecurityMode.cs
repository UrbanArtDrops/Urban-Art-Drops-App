using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace UrbanArtDropFinder.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddSmtpSecurityMode : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "SmtpSecurityMode",
                table: "AppConfigurations",
                type: "int",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "SmtpSecurityMode",
                table: "AppConfigurations");
        }
    }
}
