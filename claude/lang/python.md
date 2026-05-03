# Python

## Pydantic — Prefer Native Types Over Generic Primitives

When a Pydantic model field has a known semantic shape, use the matching Pydantic type instead of `str` / `int`. Validation comes free, type intent is explicit, and OpenAPI schemas auto-derive correct formats. Applies to settings classes (`BaseSettings`), domain models, and API request/response schemas alike.

**Common types worth reaching for first:**

- Network: `HttpUrl`, `AnyUrl`, `RedisDsn`, `PostgresDsn`, `MySQLDsn`, `AmqpDsn`, `IPvAnyAddress`
- Identifiers: `EmailStr` (requires `pydantic[email]`), `SecretStr`, `UUID4`
- Numbers: `PositiveInt`, `NonNegativeInt`
- Datetime: `AwareDatetime`, `NaiveDatetime` — default to `AwareDatetime` for API response models so serialized output always includes timezone
- File system: `FilePath`, `DirectoryPath`
- Enums: `enum.StrEnum` (Python 3.11+) for string enums, `enum.IntEnum` for int enums

**`pydantic-extra-types` (separate install):**

- `LanguageAlpha2`, `CountryAlpha2`, `PhoneNumber` (E.164), `MacAddress`, `SemanticVersion`, `TimeZoneName`

**Decision rule:** before typing a field as `str`, ask "is there a Pydantic type that captures this?" If a project lacks `pydantic-extra-types` but a field clearly needs one (country code, phone number, etc.), suggest adding the dependency rather than falling back to `str` + manual validator.

**FastAPI — let Pydantic types drive validation and OpenAPI together:** use `Literal`, `StrEnum`, and typed Pydantic models for both request parameters and response models. This gives automatic input validation, automatic 422 rejection for out-of-range values, and accurate OpenAPI schemas in one place.

- **Closed value sets:** declare as `Literal["S256"]` / `Literal["asc", "desc"]` (or `StrEnum`). Do not write `field: str` + a manual allowlist check. Applies to FastAPI `Query`, `Path`, `Body`, and `Form` parameters equally.
- **Response models:** use `response_model=SomeSchema` with a Pydantic model instead of returning raw `dict[str, Any]`. The OpenAPI response schema and field descriptions come free.
- **Request bodies:** use a Pydantic model directly, including form-encoded bodies (`Form()` + `python-multipart`).

For the full type catalog (constrained primitives, base64, payment cards, coordinates, etc.) see the official docs:
- https://docs.pydantic.dev/latest/api/types/
- https://docs.pydantic.dev/latest/api/networks/
- https://docs.pydantic.dev/latest/api/pydantic_extra_types_language_code/
- https://docs.pydantic.dev/latest/api/pydantic_extra_types_country/
- https://docs.pydantic.dev/latest/api/pydantic_extra_types_phone_numbers/

## Alembic — Migrations Must Not Import Application Code

A migration is a historical record of one schema transition. It has to keep producing the same DDL forever, even after the application code it once mirrored has been refactored, renamed, or deleted. Importing models, enums, settings, or helpers couples the script to whatever version of the app happens to be checked out, so re-running the migration on a fresh database can drift from history or fail outright.

**Rules of thumb:**

- No `from <app_pkg> import ...` inside `migrations/versions/*.py`. The only safe imports are `alembic`, `sqlalchemy`, and the standard library.
- Inline whatever metadata the script needs — table names, column lists, types, constraints — directly in `op.create_table(...)`, `op.add_column(...)`, etc. A few duplicated literals are cheap; a migration that breaks on replay is not.
- For data backfills use `op.execute(...)` with raw SQL (or a local SQLAlchemy `Table()` defined inside the migration), not the ORM model class.
- Enum value sets: copy the literal strings into the migration. Do not reference the `StrEnum` from app code, even if "it can't change" today.
- If a migration genuinely needs runtime logic, ask whether the work belongs in a separate one-shot script outside the migration timeline.
