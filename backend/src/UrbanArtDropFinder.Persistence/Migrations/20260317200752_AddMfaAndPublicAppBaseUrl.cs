using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace UrbanArtDropFinder.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddMfaAndPublicAppBaseUrl : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsMfaEnabled",
                table: "UserAccounts",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "MfaSecretKey",
                table: "UserAccounts",
                type: "nvarchar(128)",
                maxLength: 128,
                nullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "SmtpHost",
                table: "AppConfigurations",
                type: "nvarchar(512)",
                maxLength: 512,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PublicAppBaseUrl",
                table: "AppConfigurations",
                type: "nvarchar(512)",
                maxLength: 512,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsMfaEnabled",
                table: "UserAccounts");

            migrationBuilder.DropColumn(
                name: "MfaSecretKey",
                table: "UserAccounts");

            migrationBuilder.DropColumn(
                name: "PublicAppBaseUrl",
                table: "AppConfigurations");

            migrationBuilder.AlterColumn<string>(
                name: "SmtpHost",
                table: "AppConfigurations",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(512)",
                oldMaxLength: 512,
                oldNullable: true);
        }
    }
}
