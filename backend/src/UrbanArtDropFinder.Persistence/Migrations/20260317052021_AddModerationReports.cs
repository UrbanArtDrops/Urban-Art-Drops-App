using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace UrbanArtDropFinder.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddModerationReports : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ReportReason",
                table: "DropComments",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "ReportedAtUtc",
                table: "DropComments",
                type: "datetimeoffset",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsReported",
                table: "ArtPieces",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "ReportReason",
                table: "ArtPieces",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "ReportedAtUtc",
                table: "ArtPieces",
                type: "datetimeoffset",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ReportReason",
                table: "DropComments");

            migrationBuilder.DropColumn(
                name: "ReportedAtUtc",
                table: "DropComments");

            migrationBuilder.DropColumn(
                name: "IsReported",
                table: "ArtPieces");

            migrationBuilder.DropColumn(
                name: "ReportReason",
                table: "ArtPieces");

            migrationBuilder.DropColumn(
                name: "ReportedAtUtc",
                table: "ArtPieces");
        }
    }
}
