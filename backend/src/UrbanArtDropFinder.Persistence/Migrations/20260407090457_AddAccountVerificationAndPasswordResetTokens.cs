using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace UrbanArtDropFinder.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddAccountVerificationAndPasswordResetTokens : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "EmailVerificationTokenExpiresAtUtc",
                table: "UserAccounts",
                type: "datetimeoffset",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "EmailVerificationTokenHash",
                table: "UserAccounts",
                type: "nvarchar(128)",
                maxLength: 128,
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "PasswordResetTokenExpiresAtUtc",
                table: "UserAccounts",
                type: "datetimeoffset",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PasswordResetTokenHash",
                table: "UserAccounts",
                type: "nvarchar(128)",
                maxLength: 128,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "EmailVerificationTokenExpiresAtUtc",
                table: "UserAccounts");

            migrationBuilder.DropColumn(
                name: "EmailVerificationTokenHash",
                table: "UserAccounts");

            migrationBuilder.DropColumn(
                name: "PasswordResetTokenExpiresAtUtc",
                table: "UserAccounts");

            migrationBuilder.DropColumn(
                name: "PasswordResetTokenHash",
                table: "UserAccounts");
        }
    }
}
