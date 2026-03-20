# Project Constitution

## 1. Architectural Standards
- **Controller-Library Architecture**:
  - Scripts must be divided into a Controller (e.g., `Invoke-VMSync.ps1`) and one or more Library modules (`src\Modules\VMLifecycle`).
  - Controllers orchestrate workflows, manage inputs, and handle outputs.
  - Libraries contain the reusable, testable logic and do not rely on global controller variables.
- **Module Structure**:
  - Library modules must separate logic into `Public` (exported functions) and `Private` (internal helper functions) directories.

## 2. Software Design
- **Single Responsibility**: Functions must be small and single-purpose. If a function requires the word "and" to describe what it does, it should likely be split up.
- **Idempotency**: All state-changing operations (like `New-VM` or `Set-VM`) must first verify if the state change is necessary. "Make it so" instead of "Do this".

## 3. PowerShell Coding Standards
- **Language**: PowerShell 7.5+
- **Strict Typing**: All variables, parameters, and function return types must be explicitly typed where possible (e.g., `[string]`, `[int]`).
- **Fail-Fast Error Handling**: `$ErrorActionPreference = 'Stop'` must be used globally or at the top of controllers. All external calls must be wrapped in `try/catch` blocks.
- **Output & Pipeline Etiquette**:
  - Return only rich objects (`[PSCustomObject]` or Classes) to the pipeline.
  - **No `Write-Host`**: Use `Write-Verbose`, `Write-Debug`, `Write-Warning`, or `Write-Information` for logging and status messages.
- **Naming Conventions**:
  - Use Approved Verbs only (`Get-Verb`).
  - Use singular nouns (e.g., `Get-Server`, not `Get-Servers`).
  - Enforce `PascalCase` for variables, parameters, and functions.
- **Splatting**: If a cmdlet or function takes 4 or more parameters, you MUST use splatting.
- **Cmdlet Binding & Help**: All Advanced Functions must use `[CmdletBinding()]` and include Comment-Based Help with Synopsis, Description, and Example blocks.
- **Static Analysis / Linting**: All code must pass `Invoke-ScriptAnalyzer` using the rules defined in `PSScriptAnalyzerSettings.psd1` without any warnings or errors. IDEs should be configured to enforce this ruleset for real-time linting.
- **Secrets**: Never hardcode credentials or secrets in the code.

## 4. Source Control & Release
- **Semantic Versioning**: Adhere strictly to SemVer (`Major.Minor.Patch`).
- **Conventional Commits**: Commit messages must follow the Conventional Commits specification (e.g., `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`).
- **Changelog**: Maintain a `docs\change.log` to record the date, time, and code changes corresponding to your commits.

## 5. Testing Requirements
- **Unit Tests**: Every Library function must have an accompanying `tests\Unit\` Pester 5 test file. Tests must include meaningful assertions and mock all external dependencies.
- **Integration Tests**: Controllers must have an accompanying `tests\Integration\` Pester 5 test file validating end-to-end execution.

## 6. SDD Workflow
- Any change to the codebase MUST be preceded by a change to the relevant Specification document (`requirements.md`, `spec.md`).
- The AI / Developer must refer back to this constitution and the specs before writing any code.

## 7. Concurrency & Thread Safety
- **Parallelism & Throttling**: Unbounded parallel execution is prohibited. All parallel operations must have an enforced ceiling (e.g., `ForEach-Object -Parallel -ThrottleLimit 5` or a restricted Runspace Pool) to prevent memory exhaustion and API rate-limiting.
- **Thread-Safe Data Structures**: Standard arrays and hashtables are not thread-safe. When aggregating data across parallel threads, you must use thread-safe .NET classes like `[System.Collections.Concurrent.ConcurrentBag[psobject]]`.
- **Atomic Writing & Logging**: When multiple threads write to the same log or file, standard cmdlets (`Out-File`) can cause file-lock collisions. Prefer non-locking outputs, aggregator patterns, or `[System.IO.File]::AppendAllText()` for rapid I/O.
- **Mutexes for Critical Sections**: To prevent race conditions when interacting with shared state (like a JSON configuration file being updated from multiple processes), use `[System.Threading.Mutex]`. Mutex acquisition and release MUST be wrapped in a `try/finally` block to ensure release upon failure.
