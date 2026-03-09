# AGENTS.md

## Project purpose
Urban Art Drop Finder is an artistic and technical platform that reconnects digital creation with the physical world. Projects are designed digitally, produced via 3D printing, and disseminated in public space as discoverable drops. The system supports the creation, production, management, publication, discovery, and administration of these drops and the related artist and drop-maker workflows. This purpose is derived from the public description of the original project, which presents it as an artistic experiment where projects are designed, 3D-printed, and spread in public space to be hunted. :contentReference[oaicite:1]{index=1}

Out of scope:
- General-purpose features unrelated to creating, managing, publishing, distributing, discovering, or administering art drops
- Unrelated infrastructure work that does not support the product directly
- Cosmetic or stylistic changes without structural or maintainability value

Critical areas:
- All OWASP security requirements
- Authentication and authorization
- Artist area
- Drop Maker area
- Databases and persistence
- Personal data
- Removal of image metadata
- Social media integrations
- Software credentials and secret handling

## Repository layout

- `/` local project root
- `/use_cases` Markdown files containing Usecases

### Frontend
- `/frontend` Flutter application
- `/frontend/lib` application source code
- `/frontend/lib/app` app bootstrap, routing, theming, dependency wiring
- `/frontend/lib/core` cross-cutting concerns such as configuration, errors, networking, security, and utilities
- `/frontend/lib/shared` shared widgets, models, helpers, and constants
- `/frontend/lib/l10n` localization resources and generated localization bindings
- `/frontend/lib/features` feature modules following Clean Architecture

Each frontend feature under `/frontend/lib/features/<feature>` should use:
- `presentation/` UI, pages, widgets, and BLoC state management
- `application/` use cases and orchestration
- `domain/` entities, value objects, repository contracts, and business rules
- `data/` DTOs, mappers, repository implementations, and data sources

Example feature areas:
- `/frontend/lib/features/authentication`
- `/frontend/lib/features/artist_area`
- `/frontend/lib/features/drop_maker`
- `/frontend/lib/features/drops`
- `/frontend/lib/features/social_media`

### Frontend tests
- `/frontend/tests` frontend automated tests
- Organize tests into unit, widget, integration, and golden tests as appropriate

### Backend
- `/backend` backend source root

Recommended Clean Architecture structure under `/backend`:
- `/backend/src/UrbanArtDropFinder.Api` ASP.NET Core gRPC host, endpoint configuration, middleware, and DI bootstrap
- `/backend/src/UrbanArtDropFinder.Application` MediatR handlers, use cases, validation, and application services
- `/backend/src/UrbanArtDropFinder.Domain` entities, aggregates, value objects, domain events, and domain rules
- `/backend/src/UrbanArtDropFinder.Infrastructure` external integrations, credential abstractions, metadata handling, and infrastructure services
- `/backend/src/UrbanArtDropFinder.Persistence` Entity Framework DbContext, entity configuration, migrations, and persistence details
- `/backend/src/UrbanArtDropFinder.Contracts` shared contracts beyond generated gRPC artifacts when needed

### Backend tests
Recommended test structure:
- `/backend/tests/UrbanArtDropFinder.Api.Tests`
- `/backend/tests/UrbanArtDropFinder.Application.Tests`
- `/backend/tests/UrbanArtDropFinder.Domain.Tests`
- `/backend/tests/UrbanArtDropFinder.Infrastructure.Tests`
- `/backend/tests/UrbanArtDropFinder.IntegrationTests`

### Shared contracts
- `/protos` gRPC proto definitions

### Tooling and scripts
- `/dev_tools` development and maintenance scripts

### Documentation
- `/doc` project documentation, architecture notes, operational docs, and security documentation

## Environment
- Frontend language: Dart
- Frontend framework: Flutter with Material Design
- Backend language: C#
- Backend framework: ASP.NET Core gRPC with MediatR, FluentValidation, and Entity Framework
- Database access: cloud-agnostic via Entity Framework
- Frontend package manager: `flutter pub`
- Backend package manager: NuGet
- Product requirement: multilingual support for European languages

## Frontend quality tooling
- Linting: `flutter_lints`
- Static analysis: `flutter analyze`
- Formatting: `dart format .`

## Backend quality tooling
- Formatting: `dotnet format`
- Style rules: `.editorconfig`
- Static analysis: built-in .NET analyzers

## Testing
Frontend:
- `flutter_test`
- `test`
- `mocktail`
- golden tests
- integration tests via `integration_test`

Backend:
- xUnit
- unit tests for handlers, services, validators, domain logic, and business rules
- integration tests for gRPC endpoints with TestServer or WebApplicationFactory
- code coverage via Coverlet

Testing requirements:
- Unit tests are required for all business logic.
- Integration tests are required for externally exposed endpoints and critical flows.
- All tests must pass before a task is considered complete.
- Minimum coverage for new manually written code is 80%.
- Generated code is excluded from coverage expectations.
- Use tests first, then implementation.

## Common commands

### Frontend
- Install dependencies: `cd frontend && flutter pub get`
- Run app locally: `cd frontend && flutter run`
- Static analysis: `cd frontend && flutter analyze`
- Format code: `cd frontend && dart format .`
- Run all frontend tests: `cd frontend && flutter test tests --coverage`
- Run golden tests: `cd frontend && flutter test tests`
- Run integration tests: `cd frontend && flutter test integration_test`

### Backend
- Restore dependencies: `dotnet restore ./backend`
- Run service locally: `dotnet run --project ./backend/src/UrbanArtDropFinder.Api`
- Build solution: `dotnet build ./backend`
- Regenerate gRPC generated assets: `dotnet build ./backend`
- Format code: `dotnet format ./backend`
- Run all backend tests: `dotnet test ./backend`
- Run backend tests with coverage: `dotnet test ./backend --collect:"XPlat Code Coverage"`
- Add Entity Framework migration: `dotnet ef migrations add <MigrationName> --project ./backend/src/UrbanArtDropFinder.Persistence --startup-project ./backend/src/UrbanArtDropFinder.Api`
- Update database: `dotnet ef database update --project ./backend/src/UrbanArtDropFinder.Persistence --startup-project ./backend/src/UrbanArtDropFinder.Api`

### Git
- Show status: `git status --short`
- Create and switch to a branch: `git switch -c <type>/<short-description>`
- Sync with remote main: `git fetch origin && git rebase origin/main`
- Stage changes selectively: `git add <path>`
- Commit using Conventional Commits: `git commit -m "<type>(<scope>): <summary>"`
- Inspect recent history: `git log --oneline --decorate --graph -20`
- Push current branch: `git push -u origin <branch-name>`

## Working rules
- Prefer long-term structure over minimal local edits.
- Restructure the system when doing so improves readability for both humans and AI systems.
- New dependencies are allowed, but they must be actively maintained and regularly updated.
- Files and directories may be renamed, moved, or reorganized when that improves architecture or clarity.
- Public APIs, gRPC contracts, and database schemas may be changed when needed.
- Breaking changes are allowed.
- Practice test-first development: write tests before implementation.
- Use tests as the primary validation mechanism.
- 
- Continuously evolve the codebase toward clearer architecture and stronger maintainability.

## Git management
- Protect `main`: direct commits to `main` are not allowed; use feature branches and merge through review.
- Always use the `UrbanArtDrops` GitHub account for all repository operations (fetch, pull, push, merge, and branch cleanup).
- Branch naming must follow: `feat/...`, `fix/...`, `refactor/...`, `chore/...`, `docs/...`, `test/...`.
- Keep branches short-lived and scoped to one cohesive change.
- Rebase branch on top of `origin/main` before merge to keep history linear.
- Use small atomic commits with Conventional Commit messages.
- After every completed run, create a commit and push it to the current remote branch.
- Commit messages must summarize the implemented changes in 2-5 full sentences.
- If the user confirms satisfaction with the result, merge the current branch into `main` and delete the current branch on `origin`.
- Include test and documentation updates in the same branch when behavior changes.
- Never commit secrets, credentials, personal data, local environment files, or generated coverage artifacts.
- Before pushing, run formatting, static analysis, and relevant tests for changed areas.
- Resolve merge conflicts locally and rerun affected tests after conflict resolution.
- Delete merged branches from remote to keep repository hygiene.

## Code standards
- Evolve the codebase toward better readability, consistency, and maintainability instead of freezing the current style.
- For new C# code, enable and respect nullable reference types and use strict typing whenever practical.
- For new Dart code, use strong typing and avoid dynamic types unless there is a clear technical reason.
- Frontend code must follow Clean Architecture.
- Prefer stateless widgets unless state is required.
- Use BLoC for state management.
- Functions and methods should be as pure as practical, with clear input/output contracts.
- Implement comprehensive error handling for all external API calls and integrations.
- Use exponential backoff and retry policies for transient failures where appropriate.
- Use circuit breaker patterns for critical external dependencies.
- Implement graceful degradation when external services are unavailable.
- All new UI text must be localizable and must not be hard-coded directly in widgets.
- Write compact and precise comments only where they add real value.
- Include concise usage examples in comments where helpful.
- Use XML documentation comments for public C# APIs.
- Use `///` Dart doc comments for public Flutter and Dart APIs.

## Validation
Before finishing any task:
- Run the full frontend and backend test suites.
- Validate all manually written code, not only changed files.
- Generated code is excluded from coverage expectations.
- Linting and formatting must pass without errors before a task is considered complete.
- Follow test-first development.

Additional required steps:
- If gRPC contracts or `.proto` files change, run the proto compiler or equivalent code generation through the build pipeline and regenerate affected artifacts.
- If the database schema changes, generate Entity Framework migrations and update the database.
- Update documentation in `/doc` for every relevant change.
- Copy relevant screenshots from tests into the documentation when suitable test artifacts are available.

## File system boundary
- Write operations must be limited to files and directories inside the project root.
- The agent must not create, modify, move, or delete files outside the project directory.

## Security constraints
- Never store, print, commit, or expose credentials, tokens, API keys, secrets, or passwords.
- Never use production data or real personal data in tests, fixtures, documentation, or examples.
- The agent must not access production databases.
- The agent must not access production social media integrations.
- The agent has no access to image content and must not assume image inspection is possible.
- Do not log credentials, tokens, secrets, passwords, session identifiers, or authentication artifacts.
- Do not log personal data unless explicitly required, legally justified, and properly protected.
- Prefer masking, redaction, and structured summaries over raw sensitive diagnostic output.

## Decision policy
If multiple valid approaches exist:
1. Prefer the best long-term structure over the smallest possible change.
2. Prefer architectural clarity over backward compatibility when both conflict.
3. Replace existing patterns when a better structure is available.
4. Prefer stronger abstraction and generalization over duplicated solutions.
5. Actively modernize the codebase when doing so improves readability, maintainability, or architecture.

## Expected final response
When finishing a task, provide:
- a summary of what changed
- the files that were touched
- any breaking changes
- any database migrations or contract changes
- notable risks, side effects, or required follow-up actions
