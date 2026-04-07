using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace UrbanArtDropFinder.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddMailSocialAndDropExecutionState : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "PlacementConfirmed",
                table: "Drops",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "PlacementConfirmedAtUtc",
                table: "Drops",
                type: "datetimeoffset",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "ProductionPrinted",
                table: "Drops",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "ProductionPrintedAtUtc",
                table: "Drops",
                type: "datetimeoffset",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SmtpPasswordSecretName",
                table: "AppConfigurations",
                type: "nvarchar(512)",
                maxLength: 512,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "DropSocialPublishStatuses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DropId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Channel = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false),
                    Status = table.Column<string>(type: "nvarchar(32)", maxLength: 32, nullable: false),
                    Message = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: false),
                    ExternalPostId = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: true),
                    LastAttemptAtUtc = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    PublishedAtUtc = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DropSocialPublishStatuses", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DropSocialPublishStatuses_Drops_DropId",
                        column: x => x.DropId,
                        principalTable: "Drops",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_DropSocialPublishStatuses_DropId_Channel",
                table: "DropSocialPublishStatuses",
                columns: new[] { "DropId", "Channel" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DropSocialPublishStatuses");

            migrationBuilder.DropColumn(
                name: "PlacementConfirmed",
                table: "Drops");

            migrationBuilder.DropColumn(
                name: "PlacementConfirmedAtUtc",
                table: "Drops");

            migrationBuilder.DropColumn(
                name: "ProductionPrinted",
                table: "Drops");

            migrationBuilder.DropColumn(
                name: "ProductionPrintedAtUtc",
                table: "Drops");

            migrationBuilder.DropColumn(
                name: "SmtpPasswordSecretName",
                table: "AppConfigurations");
        }
    }
}
