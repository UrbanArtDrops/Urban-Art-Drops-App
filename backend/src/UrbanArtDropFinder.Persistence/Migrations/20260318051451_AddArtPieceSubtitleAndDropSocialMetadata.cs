using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace UrbanArtDropFinder.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddArtPieceSubtitleAndDropSocialMetadata : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "DropMakerComment",
                table: "Drops",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Subtitle",
                table: "ArtPieces",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateTable(
                name: "DropSocialChannelSelections",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DropId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Channel = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DropSocialChannelSelections", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DropSocialChannelSelections_Drops_DropId",
                        column: x => x.DropId,
                        principalTable: "Drops",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_DropSocialChannelSelections_DropId_Channel",
                table: "DropSocialChannelSelections",
                columns: new[] { "DropId", "Channel" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DropSocialChannelSelections");

            migrationBuilder.DropColumn(
                name: "DropMakerComment",
                table: "Drops");

            migrationBuilder.DropColumn(
                name: "Subtitle",
                table: "ArtPieces");
        }
    }
}
