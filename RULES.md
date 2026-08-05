FLEETGO DEVELOPMENT AND AI AGENT RULES

PURPOSE

These rules apply to every developer, reviewer, automation tool, and AI agent working in this repository.

The goal is safe, clear, maintainable code with small changes, exact financial behavior, and no hidden product scope.

1. SOURCE OF TRUTH

AUTH-01. Follow the current user request or approved task first.

AUTH-02. Use PRD.md for product goals, users, scope, priorities, and success measures.

AUTH-03. Use doc/Transport_Fleet_MVP_Blueprint.md for business rules, calculations, financial states, security, and acceptance cases.

AUTH-04. Use doc/Transport_Fleet_MVP_Design_Brief.md for screen behavior, wording, accessibility, and interaction details.

AUTH-05. Use ARCHITECTURE.md for code structure, dependency direction, state flow, and backend boundaries.

AUTH-06. Use RULES.md for implementation and review standards.

AUTH-06A. Use DESIGN.md for color tokens, spacing, typography, and shared UI primitives. DESIGN.md defers to `lib/ui/common/` when the two disagree.

AUTH-07. When two sources disagree, stop the conflicting work. Record the exact conflict and ask for a product decision.

AUTH-08. Do not silently change a business rule to match existing code. Existing code is evidence, not product authority.

2. BEFORE CHANGING CODE

PRE-01. Read the relevant product, architecture, and design sections before editing.

PRE-02. Inspect git status before editing. Treat all existing changes as user-owned work.

PRE-03. Search the repository for existing models, widgets, formatters, repositories, and patterns before adding new code.

PRE-04. Trace the full path from user action to View, ViewModel, repository, data source, linked records, and tests.

PRE-05. For a bug, inspect every caller of the affected function. Fix the shared root cause when one shared fix covers all callers.

PRE-06. Define the smallest safe file set before editing.

PRE-07. Do not edit unrelated files for cleanup during a scoped task.

PRE-08. Do not overwrite, restore, reset, delete, or reformat unrelated user changes.

3. CHANGE SCOPE

SCOPE-01. Build only approved behavior.

SCOPE-02. Do not add speculative settings, abstractions, hooks, flags, platforms, or future modules.

SCOPE-03. Prefer deletion, reuse, standard Dart, Flutter features, and installed packages before new code.

SCOPE-04. Keep the smallest change which solves the root problem and protects all affected flows.

SCOPE-05. Do not mix a feature change with broad refactoring unless the refactor is required for a safe feature change.

SCOPE-06. Record a deliberate shortcut with a short ponytail comment only when a known limit and upgrade condition exist.

SCOPE-07. Do not create placeholder files, empty services, future interfaces, or unused extension points.

SCOPE-08. Existing violations do not establish a project pattern. Do not spread them into new code.

4. PROJECT STRUCTURE

ARCH-01. Organize product code by feature under lib/features.

ARCH-02. A feature keeps data code under data and screen code under ui.

ARCH-03. Shared business-neutral code belongs under lib/core.

ARCH-04. Shared presentation code belongs under lib/ui.

ARCH-05. Code under lib/core must not import lib/features or lib/ui.

ARCH-06. One feature must not import another feature's ui folder.

ARCH-07. Cross-feature models and repositories are imported from the owning feature's data folder or from lib/core.

ARCH-08. Promote a model to lib/core/models when three or more features own no clear single home, or when promotion removes an import cycle.

ARCH-09. Do not duplicate a model to avoid a dependency decision.

ARCH-10. Views render state and forward user actions. Views do not access repositories or contain business calculations.

ARCH-11. ViewModels own screen state and orchestration. ViewModels do not hold BuildContext.

ARCH-11A. New ViewModels do not access Supabase directly. They use repositories.

ARCH-12. Repositories own data access and model mapping. Repositories do not import UI code.

ARCH-13. Add a UseCase only for non-trivial business logic across repositories or a rule worth isolated testing.

ARCH-14. Do not add one-line pass-through UseCases.

ARCH-15. Add a reactive service only when at least two features need the same live state.

ARCH-16. Register routes, services, repositories, sheets, and dialogs in lib/app/app.dart.

ARCH-17. Regenerate Stacked files after a registration change. Never edit generated files by hand.

5. GENERATED FILES

GEN-01. Treat lib/app/app.router.dart, app.locator.dart, app.dialogs.dart, and app.bottomsheets.dart as generated output.

GEN-02. Change lib/app/app.dart or the source annotation, then run dart run build_runner build -d.

GEN-03. Do not review generated file length as handwritten code debt.

GEN-04. Commit generated changes only when their source registration changed.

GEN-05. Never place custom logic inside a generated file.

6. DEPENDENCIES AND PACKAGES

DEP-01. Use Dart or Flutter standard features before any package.

DEP-02. Use an installed package before adding another package with overlapping behavior.

DEP-03. A new runtime package requires approval plus a concrete current requirement, no suitable existing option, active maintenance, compatible licence, supported Flutter version, acceptable platform support, and acceptable binary impact.

DEP-04. Explain the package need and rejected built-in option in the change description.

DEP-05. Do not add dartz, dio, freezed, another state manager, another dependency injector, another router, a custom API framework, or a general service layer without an approved architecture change.

DEP-06. Do not add a package for string helpers, collection helpers, validation wrappers, simple storage wrappers, or a small widget.

DEP-07. Keep Supabase as the production backend SDK. Do not add a custom API server inside the mobile repository.

DEP-08. Run flutter pub get after pubspec.yaml changes. Do not hand-edit pubspec.lock.

DEP-09. Remove an unused dependency in the same change which removes its final usage.

7. MODELS AND DATA

DATA-01. Use one model per business concept with clear fromJson and toJson methods when wire mapping exists.

DATA-02. Do not add a DTO, mapper, and entity trio when one model matches the stored shape.

DATA-03. Add a separate wire model only when the remote shape differs from the domain shape in a meaningful way.

DATA-04. Keep enum conversion inside the owning model or enum extension, never inside a widget.

DATA-05. Mark a field nullable only when the business record permits a missing value.

DATA-06. Validate required data at form and repository trust boundaries. The database remains authoritative.

DATA-07. Master records use archive instead of hard delete.

DATA-08. Draft operational records follow the approved delete rules. Issued financial records never use delete.

DATA-09. Test fixtures must stay deterministic and clearly separated from production adapters.

DATA-11. Do not hardcode business names, dates, invoice numbers, staff emails, or report periods in production flows.

DATA-12. Supabase row mapping lives in a <model>_extension.dart file in the owning feature's data folder, exposing toRow and a static fromRow. Repositories hold query logic only, never private row mappers.

DATA-13. Enum wire values use the shared snake_case toJson and fromJson codec in lib/core/enums/enums_extentions.dart. Do not write per-enum database string mappings.

DATA-14. List screens read through fetchPage returning Result<PaginatedResult<T>> with page size 50, rendered by the shared PaginatedListView. fetchAll remains only for pickers and selectors.

DATA-15. Repositories cache reads in CacheEntry maps with the default TTL and clear the whole cache on every write.

DATA-16. Aggregate summary numbers come from security-invoker SQL views read by one fetchSummary repository method. Do not aggregate rows client-side.

8. MONEY RULES

MONEY-01. Store production money in PostgreSQL numeric values.

MONEY-02. Use num AED for Dart business state, and round every money operation result half-up to two decimal places at the point of calculation with lib/core/money.dart roundMoney (including each accumulation step of a fold or sum). Never let unrounded doubles accumulate.

MONEY-03. Never use unrounded floating-point for persisted money, balances, totals, or authoritative calculations. Authoritative financial math runs in Postgres numeric(14,2).

MONEY-04. Parse user-entered money with Formatters.parseMoney before calculation.

MONEY-05. Round half-up to two decimal places at the approved calculation boundary (SQL round(x, 2) and Dart roundMoney must agree).

MONEY-06. Format all displayed money through lib/core/config/formatters.dart.

MONEY-07. Do not build AED strings inside widgets.

MONEY-08. Keep VAT outside operational profit.

MONEY-09. Only cleared payment allocations reduce balances.

MONEY-10. Reject payment allocation above the cleared payment amount or remaining document balance.

MONEY-11. Financial issue, void, settlement, and allocation rules run in privileged database transactions.

MONEY-12. Do not show optimistic final financial totals before server confirmation.

MONEY-13. Issued invoices and settlements are immutable snapshots.

MONEY-14. Correct an issued document through void with reason and reissue.

MONEY-15. Never reuse an issued or void document number.

MONEY-16. Do not add percentage commission rules during the MVP. Supplier payable stays an explicit amount on each external allocation.

9. ERRORS AND VALIDATION

ERR-01. Every fallible repository operation returns Result<T>.

ERR-02. Wrap Supabase calls with the shared guard from lib/core/supabase/supabase_guard.dart.

ERR-03. No backend exception crosses a repository boundary.

ERR-04. ViewModels handle Success and Failure with an exhaustive switch.

ERR-06. Do not catch an error and ignore the result.

ERR-07. A broad catch requires conversion to a safe typed failure plus enough internal context for diagnosis.

ERR-08. User messages explain the failed action and safe next step. Do not expose SQL, tenant identifiers, stack traces, policies, secrets, or raw backend messages.

ERR-09. Keep form values after a retryable failure when resubmission is safe.

ERR-10. Disable repeated submission during issue, void, settlement, allocation, export, and file generation.

ERR-11. Never report partial success unless the authoritative data source confirms each completed record.

ERR-12. Validate IDs, required fields, numeric ranges, party ownership, status transitions, and permission before protected writes.

ERR-13. Release builds must fail startup when production backend configuration is absent.

ERR-14. Use try and finally for busy-state cleanup when an operation still has an exception path.

ERR-15. Use debugPrint only for safe development diagnostics. Never log private business or payment data.

ERR-16. Feature code calls SnackbarService through showSuccess, showError, showWarning, or showInfo. Do not call showSnackbar or showCustomSnackBar directly.

10. SECURITY AND PRIVACY

SEC-01. Every business table carries tenant ownership.

SEC-02. Enforce tenant membership and access packs through PostgreSQL Row Level Security.

SEC-03. Treat interface permission checks as presentation only. The database enforces access.

SEC-04. Never place a Supabase service-role key or secret in mobile code, assets, logs, tests, screenshots, or committed environment files.

SEC-05. Use compile-time environment values for public client configuration.

SEC-06. Do not log passwords, access tokens, customer tax details, payment references, private phone numbers, or raw financial records.

SEC-07. Clear tenant cache after sign-out or membership removal.

SEC-08. Audit invoice issue, invoice void, settlement issue, settlement void, payment allocation, and cheque-state changes.

SEC-09. Keep issued document snapshots stable after master-data or branding changes.

SEC-10. Do not weaken validation, access checks, audit, or error handling to shorten a change.

SEC-11. Unknown or missing users receive no protected access. Never default an unknown user to owner access.

SEC-12. Do not copy sensitive research records into production seeds, public fixtures, screenshots, prompts, or logs.

11. NAMING

NAME-01. Use snake_case for Dart file and folder names.

NAME-02. Use PascalCase for classes, enums, extensions, and typedefs.

NAME-03. Use lowerCamelCase for variables, fields, parameters, methods, and enum values.

NAME-04. Prefix private members with one underscore.

NAME-05. Boolean names start with is, has, should, or another clear state word.

NAME-06. Name actions with a verb, such as loadInvoices, issueInvoice, recordPayment, or archiveVehicle.

NAME-07. Name values by business meaning, not presentation position. Prefer customerBalance over topAmount.

NAME-08. Use approved terms consistently. Use Customer, Supplier, Agreement, Work Order, Vehicle Allocation, Settlement, and Operational Profit.

NAME-09. Avoid unexplained abbreviations. Common technical forms such as id, UI, PDF, VAT, AED, and TRN are accepted.

NAME-10. Do not use generic names such as data, item, manager, helper, common, misc, or utils when a precise business name exists.

NAME-11. Test names describe the behavior, condition, and expected result.

NAME-12. Use package:cuboid_flutter_template imports in handwritten Dart. Generated files are exempt.

NAME-13. Group imports as Dart SDK, Flutter, third-party packages, then project packages.

NAME-14. Prefer final and const when values do not change.

12. FILE SIZE AND CODE SPLITTING

SIZE-01. Keep new handwritten Dart files near 300 lines or fewer.

SIZE-02. A handwritten file above 300 lines requires review for a coherent split before adding more logic.

SIZE-03. Generated files, deterministic seed data, and focused PDF layout files are exceptions when splitting would reduce clarity.

SIZE-04. Do not split code only to satisfy a line count.

SIZE-05. Split by responsibility, not by arbitrary line ranges.

SIZE-06. Keep one primary public class per file. Small private widgets or tightly related value types stay with their owner.

SIZE-07. Keep methods near 40 lines or fewer where practical.

SIZE-08. Review any method above 60 lines for extraction of validation, mapping, calculation, or a coherent widget section.

SIZE-09. Extract a widget when the section has its own state, repeated structure, independent meaning, or a large build block.

SIZE-10. Do not move business logic into a widget to reduce ViewModel length.

SIZE-11. Do not create helper files with unrelated functions.

SIZE-12. Existing oversized files are cleanup targets. Their size does not approve more growth.

13. CLARITY AND REUSE

CLEAR-01. Prefer direct code over clever code.

CLEAR-02. Keep one level of abstraction for one clear purpose.

CLEAR-03. Keep single-use behavior local unless extraction improves readability or testing.

CLEAR-04. On the second real use, review shared ownership. On repeated cross-feature use, move the shared part to lib/core or lib/ui.

CLEAR-05. Do not generalize for imagined future variants.

CLEAR-06. Reuse shared formatters, theme tokens, app bars, buttons, fields, list cards, status chips, sheets, and dialogs.

CLEAR-07. Do not duplicate money, permission, status, or invoice rules across ViewModels.

CLEAR-08. Prefer an enum or value type over repeated magic strings for stable business states.

CLEAR-09. Keep constants close to their owner unless several features share the same stable value.

CLEAR-10. Avoid deep nesting. Use early returns for invalid or finished paths.

CLEAR-11. Avoid unnecessary dynamic values. Use typed request and response data when the framework path supports typing.

CLEAR-12. Do not hide a simple operation behind a factory, interface, builder, or registry with one implementation.

14. COMMENTS AND DOCUMENTATION

COMMENT-01. Write comments for reasons, invariants, regulatory constraints, workarounds, and non-obvious tradeoffs.

COMMENT-02. Do not describe code already clear from names and structure.

COMMENT-03. Do not keep commented-out code.

COMMENT-04. Do not add decorative comment banners or numbered comments which repeat screen order.

COMMENT-05. Keep comments accurate after every change. Delete stale comments.

COMMENT-06. Document shared public APIs and non-obvious financial behavior.

COMMENT-07. A TODO states the owner or issue, missing work, and removal condition.

COMMENT-08. Do not add vague TODO, FIXME, temporary, or later comments without an actionable condition.

COMMENT-09. Use a ponytail comment only for a deliberate simplification with a known ceiling and upgrade signal.

COMMENT-10. Do not add comments about AI reasoning, prompts, generated effort, or conversation history.

COMMENT-11. Keep lint suppression on the narrow affected line and state the reason. Do not weaken global lints to hide one issue.

15. UI AND ACCESSIBILITY

UI-01. Use AppTheme, AppColors, shared spacing, and shared controls before local styling.

UI-02. Use AppBarIOS for standard page headers.

UI-03. Follow doc/design/ios_polish_pattern.md for grouped list screens.

UI-04. Prefer CupertinoIcons where an existing symbol fits the action.

UI-05. Pair icon-only meaning with a visible label or semantic label.

UI-06. Do not use color as the only status signal.

UI-07. Keep text readable, touch targets comfortable, focus visible, and validation close to the field.

UI-08. Use Formatters for every displayed date, time, and money value.

UI-09. Use platform date and time pickers.

UI-10. Keep common flows usable on a phone without repeated navigation between records.

UI-11. Provide loading, empty, error, offline, disabled, and success states where the flow needs each state.

UI-12. Use direct action labels. Avoid vague labels such as Submit, Process, or Done.

UI-13. Preserve bottom navigation state through the existing shell.

UI-14. Do not introduce a new visual pattern when a shared project pattern covers the need.

16. TESTING

TEST-01. Every bug fix includes one regression check at the lowest useful level.

TEST-02. Every new branch, parser, money rule, security rule, or state transition includes a focused test.

TEST-03. Trivial visual or one-line changes do not need artificial tests.

TEST-04. ViewModel tests mock repositories and services. They do not access a real network.

TEST-05. Repository integration tests cover production adapters, mapping, typed failures, and tenant behavior.

TEST-06. Financial tests use exact values and cover rounding, partial payment, over-allocation, void, and immutable snapshot behavior.

TEST-07. Keep tests deterministic. Do not depend on current wall time, random order, or live external services.

TEST-08. Mirror source ownership under test/core and test/features.

TEST-09. Run targeted tests during development, then the full relevant suite before handoff.

TEST-10. Run flutter analyze after Dart changes.

TEST-11. Run dart format on changed Dart files.

TEST-12. Run flutter test before handoff for code changes unless an external blocker prevents execution.

TEST-13. For documentation-only changes, review accuracy, paths, links, and diffs. Flutter tests are optional when no code changed.

TEST-14. Never claim a check passed unless the command completed successfully.

TEST-15. Reset changed Stacked locator registrations during test cleanup.

17. GIT AND FILE SAFETY

GIT-01. Preserve the user's dirty worktree.

GIT-02. Inspect diffs for only the files inside the approved scope.

GIT-03. Do not use destructive reset, checkout, restore, clean, or delete commands without explicit approval.

GIT-04. Do not commit, push, open a pull request, or change remote state unless requested.

GIT-05. Do not modify .git internals.

GIT-06. Do not commit env files, credentials, tokens, certificates, private client documents, database exports, or generated user reports.

GIT-07. Keep research documents with real client details internal. Do not copy sensitive values into tests or screenshots.

GIT-08. Use apply_patch for deliberate text edits. Use formatters only for mechanical formatting.

18. AI AGENT RULES

AGENT-01. State the file scope before broad work begins.

AGENT-02. Search first, then edit. Do not invent project conventions from memory.

AGENT-03. Use subagents only when the user requests delegation or repository instructions require parallel work.

AGENT-04. Give each subagent one bounded task and non-overlapping file ownership.

AGENT-05. All agents share one worktree. Check for other agent edits before applying a patch.

AGENT-06. Do not delegate interpretation of required project instructions. The primary agent reads the relevant sources.

AGENT-07. Do not expose secrets or sensitive client data in tool output, logs, examples, or responses.

AGENT-08. Do not replace uncertain business rules with assumptions. Ask for a decision when the choice changes money, permissions, compliance, stored data, or scope.

AGENT-09. Use a safe, narrow assumption for reversible presentation details and state the assumption in the handoff.

AGENT-10. Do not claim production readiness while repositories, security policies, migrations, or financial transactions remain demo-backed.

AGENT-11. Report changed files, completed checks, failed checks, and remaining blockers.

AGENT-12. Do not include unrelated advice or future features in a completed handoff.

19. DOCUMENTATION UPDATES

DOC-01. Update PRD.md when approved product scope, users, goals, or success measures change.

DOC-02. Update the blueprint when an approved business calculation, financial state, permission, or data rule changes.

DOC-03. Update the design brief when an approved screen flow, interaction, wording system, or accessibility rule changes.

DOC-04. Update ARCHITECTURE.md when folders, layers, dependencies, state flow, backend boundaries, or generation rules change.

DOC-05. Update RULES.md when the team approves a new development boundary.

DOC-06. Describe current state and target state separately. Do not present planned backend work as implemented.

DOC-07. Keep one authority per topic and link to the authority instead of copying long sections across files.

20. REQUIRED COMMANDS

Run git status --short before work and before handoff.

Run rg with the affected symbol or behavior before editing shared code.

Run dart format on changed Dart files.

Run flutter analyze after Dart changes.

Run the focused test during development, then run flutter test before code handoff.

Run dart run build_runner build -d after registration changes in lib/app/app.dart.

Run git diff --check and git diff --stat before handoff.

21. DEFINITION OF DONE

DONE-01. The approved behavior works through the full affected flow.

DONE-02. The change follows product, architecture, design, and security rules.

DONE-03. Financial values and state changes use authoritative rules.

DONE-04. New and changed code is formatted and analyzed.

DONE-05. Relevant tests pass.

DONE-06. Generated files match their sources.

DONE-07. No unrelated file or user change was altered.

DONE-08. Documentation matches the resulting behavior.

DONE-09. The final handoff lists files, checks, and remaining approved follow-up work.
