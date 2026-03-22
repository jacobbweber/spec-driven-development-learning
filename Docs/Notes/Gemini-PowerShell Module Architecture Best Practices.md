# PowerShell Module Architecture Best Practices

**TL;DR:** Transition to a **Service-Oriented Module Architecture** using a central **Context Object** (Class) to manage state. Replace procedural logic with **Task-Based Abstractions** (Workflow functions) and encapsulate I/O operations (Excel, Telemetry, Logging) into dedicated **Provider Classes** to ensure thread safety and reduce controller noise.

* * *

Core Architectural Techniques
-----------------------------

### 1\. The "Context Object" Pattern

Instead of passing numerous variables through function chains, define a single **PowerShell Class** to act as the "Source of Truth" for the session.

*   **Encapsulation:** Store configuration, runtime flags (Audit/Remediate), and references to Telemetry/Logging objects within this class.
*   **Methodology:** Pass this single `$Context` object to every public and private function.
*   **Benefits:** Adding a new global parameter only requires updating the class definition, not every function signature in the module.

### 2\. Provider-Based Abstraction

Encapsulate complex I/O logic into specialized classes. This isolates the "How" (Excel Interop, JSON parsing) from the "What" (Business Logic).

*   **Telemetry Class:** Handles internal collection and the final `Export-Json`. Use `[System.Collections.Concurrent.ConcurrentBag]` for thread-safe result collection during parallelism.
*   **Report Class:** Manages the OpenXML or ExcelCOM logic. Expose simple methods like `$Report.AddRow($Data)` so the workflow functions don't need to know about cell coordinates or formatting.
*   **Logger Class:** Implement thread-safe "Atomic Writes" using a **Mutex** or a thread-safe queue.

### 3\. Layered Function Hierarchy

Structure the module into three distinct layers to maximize reusability:

*   **Atomic Functions (Private):** Low-level, single-purpose tools (e.g., `Get-RegistryValue`, `Set-FilePermission`).
*   **Workflow Functions (Public):** High-level "Activity" scripts (e.g., `Invoke-VMCleanup`). These consume Atomic functions and the `$Context` object. They handle specific business units of work.
*   **Controller Script:** The entry point. It handles only initialization, calls the necessary Workflow functions, and triggers the final telemetry/report generation.

* * *

Feedback on Proposed Ideas
--------------------------

| Idea | Status | Expert Guidance |
| --- | --- | --- |
| **1\. Large Classes for state** | **Recommended** | Use a **Context Class** for state. Avoid putting complex business logic inside the class; keep it focused on data storage and state management. |
| **2\. Purpose-Specific Classes** | **Best Practice** | Essential for Telemetry and Excel. This allows you to swap a library (e.g., moving from ImportExcel to a SQL backend) without touching the business logic. |
| **3\. Abstracted Workflows** | **Best Practice** | These should be "Orchestrators." A controller script should look like a table of contents, calling 3-5 high-level workflows rather than hundreds of lines of code. |
| **4\. Multiple Scripts** | **Discouraged** | Keep logic within a **Root Module (.psm1)** or separate files dot-sourced into the manifest. Loose scripts make versioning, scoping, and parallelism harder to manage. |

* * *

Managing Parallelism and Large Inventories
------------------------------------------

*   **Batching:** When generating large inventories, split the data into batches before passing them to `ForEach-Object -Parallel`. This prevents memory exhaustion.
*   **Thread-Safe Collection:** Avoid updating a standard `[Array]` or `[ArrayList]` inside parallel blocks. Use `[System.Collections.Concurrent.ConcurrentDictionary]` for the inventory to prevent race conditions.
*   **Audit Mode Logic:** Implement a `WhatIf` preference or a `$Context.Mode` check inside Atomic functions. This ensures that switching from "Audit" to "Remediate" is a single flag change at the Controller level.

* * *

Structure Example
-----------------

1.  **`Project.psd1`**: Manifest.
2.  **`Project.psm1`**: Root module (imports classes and public functions).
3.  **`/Classes`**: `Context.ps1`, `Telemetry.ps1`, `Report.ps1`.
4.  **`/Public`**: Workflow functions (e.g., `Invoke-SiteRemediation.ps1`).
5.  **`/Private`**: Atomic helper functions.
6.  **`Main.ps1`**: The controller containing only the business logic sequence.

Would you like me to draft a boilerplate template for the **Context Class** and a thread-safe **Logging Class**?


**TL;DR:** Use **Distributed Logging** within workflow functions to ensure granular traceability. Encapsulate the logging logic in a **Thread-Safe Provider** passed via the Context Object to avoid file-locking and maintain a consistent schema across all layers.

* * *

### Logging Strategy and Direction

*   **Granular Traceability:** Workflow functions must log internal state changes, retries, and non-terminating errors. If logging is restricted to the controller, the "why" behind a failure is often lost, as the controller only sees the final success or failure of the high-level task.
*   **Parallelism Requirements:** In a parallel architecture, the controller script cannot monitor the real-time progress of individual runspaces. Each thread must independently call the Logging Provider to record its atomic actions to prevent data loss or "blind spots" during execution.
*   **Contextual Metadata:** Logging inside the workflow allows for the automatic inclusion of function-specific metadata—such as the target resource ID, the specific step name, or a unique Correlation ID—without passing that data back to the controller for every minor event.
*   **Layered Responsibility:**
    *   **Controller:** Logs "Macro" events (e.g., "Starting Site Remediation Phase").
    *   **Workflows:** Log "Micro" events (e.g., "Service 'X' stopped successfully on Host 'Y'").
    *   **Private/Atomic Functions:** Generally avoid direct logging; they should throw exceptions or return rich objects. The Workflow function catches these and logs the outcome. This ensures low-level tools remain reusable in different contexts.

### Technical Implementation for Maintainability

*   **Thread Safety:** Use a **Mutex (Mutual Exclusion)** or `[System.IO.FileStream]` with appropriate sharing locks within your Logging Class to handle concurrent writes from parallel workflows.
*   **Log Routing:** Instead of a standalone `Write-Log` function, use a method within your **Context Object** (e.g., `$Context.Logger.Write("Message")`). This ensures all parts of the script use the same configuration, file path, and log level without needing global variables.
*   **Asynchronous Buffering:** For very high-volume logging, workflows can write to a thread-safe queue (`ConcurrentQueue`), which a background thread or the controller then flushes to the `.log` file. This prevents logging I/O from becoming a bottleneck for the business logic.



