using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace UrbanArtDropFinder.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPendingRoleApplications : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "PendingRoleApplication",
                table: "UserAccounts",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "PendingRoleApplicationRequestedAtUtc",
                table: "UserAccounts",
                type: "datetimeoffset",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PendingRoleApplication",
                table: "UserAccounts");

            migrationBuilder.DropColumn(
                name: "PendingRoleApplicationRequestedAtUtc",
                table: "UserAccounts");
        }
    }
}
