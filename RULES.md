Cuboid Flutter Template DEVELOPMENT AND AI AGENT RULES

PURPOSE

These rules apply to every developer, reviewer, automation tool, and AI agent
working in this repository.

The goal is safe, clear, maintainable template code with small scoped changes
and no hidden product scope.

1. SOURCE OF TRUTH

AUTH-01. Follow the current user request or approved task first.

AUTH-02. Use approved downstream product documents for product goals, users,
scope, priorities, and success measures when working inside a generated
application.

AUTH-03. Use ARCHITECTURE.md for code structure, dependency direction, state
flow, generation rules, and backend boundaries.

AUTH-04. Use RULES.md for implementation and review standards.

AUTH-05. Use doc/design/ for reusable design guidance only.

AUTH-06. Existing code is evidence of current state, not authority for adding
product scope.

AUTH-07. When two sources disagree, stop the conflicting work. Record the exact
conflict and ask for a decision.

2. BEFORE CHANGING CODE

PRE-01. Read the relevant request, architecture, rules, and design sections
before editing.

PRE-02. Inspect git status before editing. Treat all existing changes as
user-owned work.

PRE-03. Search the repository for existing models, widgets, formatters,
repositories, and patterns before adding new code.

PRE-04. Trace the full path from user action to View, ViewModel, repository or
service, data source, linked records, and tests where those boundaries exist.

PRE-05. For a bug, inspect every caller of the affected function. Fix the shared
root cause when one shared fix covers all callers.

PRE-06. Define the smallest safe file set before editing.

PRE-07. Do not edit unrelated files for cleanup during a scoped task.

PRE-08. Do not overwrite, restore, reset, delete, or reformat unrelated user
changes.

3. CHANGE SCOPE

SCOPE-01. Build only approved behavior.

SCOPE-02. Do not add speculative settings, abstractions, hooks, flags,
platforms, or future modules.

SCOPE-03. Prefer deletion, reuse, standard Dart, Flutter features, and installed
packages before new code.

SCOPE-04. Keep the smallest change which solves the root problem and protects
all affected flows.

SCOPE-05. Do not mix a feature change with broad refactoring unless the refactor
is required for a safe feature change.

SCOPE-06. Record a deliberate shortcut with a short comment only when a known
limit and upgrade condition exist.

SCOPE-07. Do not create placeholder files, empty services, future interfaces, or
unused extension points.

SCOPE-08. Existing violations do not establish a project pattern. Do not spread
them into new code.

4. PROJECT STRUCTURE

ARCH-01. Organize app code by feature under lib/features.

ARCH-02. A feature uses lib/features/<feature>/data for data code and
lib/features/<feature>/ui for screen code. data is optional when the feature has
no data layer.

ARCH-03. Under a feature's ui folder, ViewModels belong in viewmodels, Views
belong in views, and feature-specific widgets belong in widgets. ui/widgets is
optional when the feature has no feature-specific widgets.

ARCH-04. Do not add domain, use-case, or other layer folders under features.

ARCH-05. startup is an intentional application-bootstrap exception. Do not move
or structurally refactor startup only to match generated feature folders.

ARCH-06. Shared business-neutral code belongs under lib/core.

ARCH-07. Shared presentation code belongs under lib/shared.

ARCH-08. Code under lib/core must not import lib/features.

ARCH-09. One feature must not import another feature's ui folder.

ARCH-10. Cross-feature models and repositories are imported from the owning
feature's data folder or from lib/core.

ARCH-11. Promote a model to lib/core/models only when it is genuinely shared or
when promotion removes an import cycle.

ARCH-12. Do not duplicate a model to avoid a dependency decision.

ARCH-13. Views render state and forward user actions. Views do not access
repositories or contain application business rules.

ARCH-14. ViewModels own screen state and orchestration. ViewModels do not hold
BuildContext.

ARCH-15. ViewModels must not call Supabase directly for feature data. They use
repositories when persistent feature data exists.

ARCH-16. Repositories own data access and model mapping. Repositories do not
import UI code.

ARCH-17. Do not add a UseCase layer.

ARCH-18. Do not add one-line pass-through UseCases.

ARCH-19. Add a reactive service only when at least two features need the same
live state.

ARCH-20. Register routes, services, repositories, sheets, and dialogs in
lib/app/app.dart.

ARCH-21. Regenerate Stacked files after a registration change. Never edit
generated files by hand.

5. GENERATED FILES

GEN-01. Treat lib/app/app.router.dart, app.locator.dart, app.logger.dart,
app.dialogs.dart, and app.bottomsheets.dart as generated output when present.

GEN-02. Change lib/app/app.dart or the source annotation, then run dart run
build_runner build -d.

GEN-03. Do not review generated file length as handwritten code debt.

GEN-04. Commit generated changes only when their source registration changed.

GEN-05. Never place custom logic inside a generated file.

6. DEPENDENCIES AND PACKAGES

DEP-01. Use Dart or Flutter standard features before any package.

DEP-02. Use an installed package before adding another package with overlapping
behavior.

DEP-03. A new runtime package requires approval plus a concrete current
requirement, no suitable existing option, active maintenance, compatible
licence, supported Flutter version, acceptable platform support, and acceptable
binary impact.

DEP-04. Explain the package need and rejected built-in option in the change
description.

DEP-05. Do not add another state manager, dependency injector, router, custom
API framework, or general service layer without an approved architecture change.

DEP-06. Do not add a package for string helpers, collection helpers, validation
wrappers, simple storage wrappers, or a small widget.

DEP-07. Supabase may be used as an auth/backend SDK, but the template currently
has no domain schema or active product migrations.

DEP-08. Run flutter pub get after pubspec.yaml changes. Do not hand-edit
pubspec.lock.

DEP-09. Remove an unused dependency in the same change which removes its final
usage.

7. MODELS AND DATA

DATA-01. Use one model per concept with clear fromJson and toJson methods when
wire mapping exists.

DATA-02. Do not add a DTO, mapper, and entity trio when one model matches the
stored shape.

DATA-03. Add a separate wire model only when the remote shape differs from the
application shape in a meaningful way.

DATA-04. Keep enum conversion inside the owning model or enum extension, never
inside a widget.

DATA-05. Mark a field nullable only when the record permits a missing value.

DATA-06. Validate required data at form and repository trust boundaries. When a
backend exists, it remains authoritative for persisted data.

DATA-07. Test fixtures must stay deterministic and clearly separated from
production adapters.

DATA-08. Do not hardcode product names, customer names, dates, staff emails, or
fixed periods in production flows.

DATA-09. Supabase row mapping belongs beside the owning model/repository when a
generated app introduces persistent data. Repositories hold query logic.

DATA-10. List screens that use paged backend data should read through a
repository method returning Result<PaginatedResult<T>> and render through shared
pagination widgets.

DATA-11. Repository caches must have explicit invalidation behavior on writes.

8. ERRORS AND VALIDATION

ERR-01. Every fallible repository operation returns Result<T>.

ERR-02. Wrap Supabase calls with shared backend guards such as
lib/core/network/supabase_guard.dart.

ERR-03. No backend exception crosses a repository boundary.

ERR-04. ViewModels handle Success and Failure explicitly.

ERR-05. Do not catch an error and ignore the result.

ERR-06. A broad catch requires conversion to a safe typed failure plus enough
internal context for diagnosis.

ERR-07. User messages explain the failed action and safe next step. Do not
expose SQL, tenant identifiers, stack traces, policies, secrets, or raw backend
messages.

ERR-08. Keep form values after a retryable failure when resubmission is safe.

ERR-09. Disable repeated submission during protected writes, export, and file
generation.

ERR-10. Never report partial success unless the authoritative data source
confirms each completed record.

ERR-11. Validate IDs, required fields, numeric ranges, ownership, status
transitions, and permission before protected writes where those concepts exist.

ERR-12. Release builds must fail startup when required production backend
configuration is absent.

ERR-13. Use try and finally for busy-state cleanup when an operation still has
an exception path.

ERR-14. Use debugPrint only for safe development diagnostics. Never log
confidential business data, credentials, or tokens.

ERR-15. Feature code calls SnackbarService through project helpers when they
exist. Do not bypass established notification wrappers.

9. SECURITY AND PRIVACY

SEC-01. Treat interface permission checks as presentation only. A backend with
protected data must enforce authorization server-side.

SEC-02. PostgreSQL RLS and privileged functions are application-specific once a
generated app introduces persistent domain data.

SEC-03. Never place a Supabase service-role key or secret in mobile code,
assets, logs, tests, screenshots, or committed environment files.

SEC-04. Use compile-time environment values for public client configuration.

SEC-05. Do not log passwords, access tokens, confidential contact details,
customer data, or raw protected records.

SEC-06. Clear user-scoped caches after sign-out or access removal where those
caches exist.

SEC-07. Do not weaken validation, access checks, audit, or error handling to
shorten a change.

SEC-08. Unknown or missing users receive no protected access. Never default an
unknown user to owner access.

SEC-09. Do not copy sensitive external records into production seeds, public
fixtures, screenshots, prompts, or logs.

10. NAMING

NAME-01. Use snake_case for Dart file and folder names.

NAME-02. Use PascalCase for classes, enums, extensions, and typedefs.

NAME-03. Use lowerCamelCase for variables, fields, parameters, methods, and enum
values.

NAME-04. Prefix non-public members with one underscore.

NAME-05. Boolean names start with is, has, should, or another clear state word.

NAME-06. Name actions with a verb, such as loadItems, saveProfile, or
archiveRecord.

NAME-07. Name values by domain meaning, not presentation position.

NAME-08. Avoid unexplained abbreviations. Common technical forms such as id, UI,
URL, API, JSON, PDF, and RLS are accepted.

NAME-09. Do not use generic names such as data, item, manager, helper, common,
misc, or utils when a precise name exists.

NAME-10. Test names describe the behavior, condition, and expected result.

NAME-11. Use package:cuboid_flutter_template imports in handwritten Dart until a
generated app is bootstrapped to a new package name. Generated files are exempt.

NAME-12. Group imports as Dart SDK, Flutter, third-party packages, then project
packages.

NAME-13. Prefer final and const when values do not change.

11. FILE SIZE AND CODE SPLITTING

SIZE-01. Keep new handwritten Dart files near 300 lines or fewer.

SIZE-02. A handwritten file above 300 lines requires review for a coherent split
before adding more logic.

SIZE-03. Generated files and deterministic seed data are exceptions when
splitting would reduce clarity.

SIZE-04. Do not split code only to satisfy a line count.

SIZE-05. Split by responsibility, not by arbitrary line ranges.

SIZE-06. Keep one primary public class per file. Small non-public widgets or
tightly related value types stay with their owner.

SIZE-07. Keep methods near 40 lines or fewer where practical.

SIZE-08. Review any method above 60 lines for extraction of validation, mapping,
or a coherent widget section.

SIZE-09. Extract a widget when the section has its own state, repeated
structure, independent meaning, or a large build block.

SIZE-10. Do not move application logic into a widget to reduce ViewModel length.

SIZE-11. Do not create helper files with unrelated functions.

SIZE-12. Existing oversized files are cleanup targets. Their size does not
approve more growth.

12. CLARITY AND REUSE

CLEAR-01. Prefer direct code over clever code.

CLEAR-02. Keep one level of abstraction for one clear purpose.

CLEAR-03. Keep single-use behavior local unless extraction improves readability
or testing.

CLEAR-04. On the second real use, review shared ownership. On repeated
cross-feature use, move the shared part to lib/core or lib/shared.

CLEAR-05. Do not generalize for imagined future variants.

CLEAR-06. Reuse shared formatters, theme tokens, app bars, buttons, fields, list
patterns, sheets, and dialogs.

CLEAR-07. Prefer an enum or value type over repeated magic strings for stable
states.

CLEAR-08. Keep constants close to their owner unless several features share the
same stable value.

CLEAR-09. Avoid deep nesting. Use early returns for invalid or finished paths.

CLEAR-10. Avoid unnecessary dynamic values. Use typed request and response data
when the framework path supports typing.

CLEAR-11. Do not hide a simple operation behind a factory, interface, builder,
or registry with one implementation.

13. COMMENTS AND DOCUMENTATION

COMMENT-01. Write comments for reasons, invariants, workarounds, and non-obvious
tradeoffs.

COMMENT-02. Do not describe code already clear from names and structure.

COMMENT-03. Do not keep commented-out code.

COMMENT-04. Do not add decorative comment banners or numbered comments which
repeat screen order.

COMMENT-05. Keep comments accurate after every change. Delete stale comments.

COMMENT-06. Document shared public APIs and non-obvious behavior.

COMMENT-07. A TODO states the owner or issue, missing work, and removal
condition.

COMMENT-08. Do not add vague TODO, FIXME, temporary, or later comments without
an actionable condition.

COMMENT-09. Use a short explanatory comment only for a deliberate
simplification with a known ceiling and upgrade signal.

COMMENT-10. Do not add comments about AI reasoning, prompts, generated effort,
or conversation history.

COMMENT-11. Keep lint suppression on the narrow affected line and state the
reason. Do not weaken global lints to hide one issue.

14. UI AND ACCESSIBILITY

UI-01. Use AppTheme, AppColors, shared spacing, and shared controls before local
styling.

UI-02. Use AppBarIOS for standard page headers.

UI-03. Follow doc/design/ios_polish_pattern.md for grouped list screens.

UI-04. Prefer CupertinoIcons where an existing symbol fits the action.

UI-05. Pair icon-only meaning with a visible label or semantic label.

UI-06. Do not use color as the only status signal.

UI-07. Keep text readable, touch targets comfortable, focus visible, and
validation close to the field.

UI-08. Use Formatters for displayed date and time values.

UI-09. Use platform date and time pickers.

UI-10. Keep common flows usable on a phone without repeated navigation between
records.

UI-11. Provide loading, empty, error, offline, disabled, and success states
where the flow needs each state.

UI-12. Use direct action labels. Avoid vague labels such as Submit, Process, or
Done.

UI-13. Preserve bottom navigation state through the existing shell.

UI-14. Do not introduce a new visual pattern when a shared project pattern
covers the need.

15. TESTING

TEST-01. Every bug fix includes one regression check at the lowest useful level.

TEST-02. Every new branch, parser, security rule, or state transition includes a
focused test.

TEST-03. Trivial visual or one-line changes do not need artificial tests.

TEST-04. ViewModel tests mock repositories and services. They do not access a
real network.

TEST-05. Repository integration tests cover production adapters, mapping, typed
failures, and authorization behavior when repositories exist.

TEST-06. Keep tests deterministic. Do not depend on current wall time, random
order, or live external services.

TEST-07. Mirror source ownership under test/core, test/features, test/shared,
and test/tool.

TEST-08. Run targeted tests during development, then the full relevant suite
before handoff.

TEST-09. Run flutter analyze after Dart changes.

TEST-10. Run dart format on changed Dart files.

TEST-11. Run flutter test before handoff for code changes unless an external
blocker prevents execution.

TEST-12. For documentation-only changes, review accuracy, paths, links, and
diffs. Flutter tests are optional when no code changed.

TEST-13. Never claim a check passed unless the command completed successfully.

TEST-14. Reset changed Stacked locator registrations during test cleanup.

16. GIT AND FILE SAFETY

GIT-01. Preserve the user's dirty worktree.

GIT-02. Inspect diffs for only the files inside the approved scope.

GIT-03. Do not use destructive reset, checkout, restore, clean, or delete
commands without explicit approval.

GIT-04. Do not commit, push, open a pull request, or change remote state unless
requested.

GIT-05. Do not modify .git internals.

GIT-06. Do not commit env files, credentials, tokens, certificates,
confidential client documents, database exports, or generated user exports.

GIT-07. Do not copy sensitive external documents into tests, screenshots,
prompts, logs, or public fixtures.

GIT-08. Use apply_patch for deliberate text edits. Use formatters only for
mechanical formatting.

17. AI AGENT RULES

AGENT-01. State the file scope before broad work begins.

AGENT-02. Search first, then edit. Do not invent project conventions from
memory.

AGENT-03. Use subagents only when the user requests delegation or repository
instructions require parallel work.

AGENT-04. Give each subagent one bounded task and non-overlapping file
ownership.

AGENT-05. All agents share one worktree. Check for other agent edits before
applying a patch.

AGENT-06. Do not delegate interpretation of required project instructions. The
primary agent reads the relevant sources.

AGENT-07. Do not expose secrets or sensitive client data in tool output, logs,
examples, or responses.

AGENT-08. Do not replace uncertain product rules with assumptions. Ask for a
decision when the choice changes permissions, compliance, stored data, security,
or scope.

AGENT-09. Use a safe, narrow assumption for reversible presentation details and
state the assumption in the handoff.

AGENT-10. Do not claim production readiness while repositories, security
policies, migrations, or server-side rules remain template-only or absent.

AGENT-11. Report changed files, completed checks, failed checks, and remaining
blockers.

AGENT-12. Do not include unrelated advice or future features in a completed
handoff.

18. DOCUMENTATION UPDATES

DOC-01. Update approved downstream product documentation when product scope,
users, goals, or success measures change in a generated application.

DOC-02. Update ARCHITECTURE.md when folders, layers, dependencies, state flow,
backend boundaries, or generation rules change.

DOC-03. Update RULES.md when the team approves a new development boundary.

DOC-04. Describe current state and target state separately. Do not present
planned backend work as implemented.

DOC-05. Keep one authority per topic and link to the authority instead of
copying long sections across files.

DOC-06. Do not restore deleted product documents as active template authority.

19. REQUIRED COMMANDS

Run git status --short before work and before handoff.

Run rg with the affected symbol or behavior before editing shared code.

Run dart format on changed Dart files.

Run flutter analyze after Dart changes.

Run the focused test during development, then run flutter test before code
handoff.

Run dart run build_runner build -d after registration changes in
lib/app/app.dart.

Run git diff --check and git diff --stat before handoff.

20. DEFINITION OF DONE

DONE-01. The approved behavior works through the full affected flow.

DONE-02. The change follows architecture, design, and security rules.

DONE-03. New and changed code is formatted and analyzed.

DONE-04. Relevant tests pass.

DONE-05. Generated files match their sources.

DONE-06. No unrelated file or user change was altered.

DONE-07. Documentation matches the resulting behavior.

DONE-08. The final handoff lists files, checks, and remaining approved follow-up
work.
