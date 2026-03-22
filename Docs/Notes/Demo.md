# Spec-Driven Development (SDD) in Action: VM Lifecycle Demo

Welcome to the VM Lifecycle Demo project. This repository demonstrates how to use **Spec-Driven Development (SDD)** alongside an AI assistant to build a robust, declarative PowerShell 7.5+ application.

The core philosophy of SDD is that **human thought dictates the rules and requirements (the Specs)**, while the **AI handles the heavy lifting of code generation**, constrained entirely by those rules.

Below is the story of how this project was materialized, featuring context on the workflow and the theoretical prompts a user would have issued.

---

## Phase 1: Establishing the Rules of Engagement
Before writing any code, we must establish how the codebase should look and behave. We do this by creating a **Constitution**.

**User Prompt to AI:**
> *"I want to build a VM lifecycle manager in PowerShell. Before we write code, let's create a constitution document at `Docs\Spec\constitution.md`. We must strictly use PowerShell 7.5+, utilize explicit typing, rely on `try/catch` for error handling, and use the Controller-Library architecture pattern where global state is forbidden. Make sure every operation we eventually build is idempotent."*

**Result:** The AI generated `Docs\Spec\constitution.md`, establishing the immutable rules for the project. From this point forward, every code generation prompt relies on the AI having this constitution in its context.

---

## Phase 2: Defining the Requirements
With the rules established, we need to map out *what* the application actually does from a user perspective.

**User Prompt to AI:**
> *"Now let's draft `Docs\Spec\requirements.md`. The goal is a declarative tool where a user provides a `state.json` file defining properties like 'Name', 'State' (Present/Absent), 'CPU', and 'Memory' for local Hyper-V VMs. The tool should create VMs that are missing, update CPUs/Memory if they drift from the JSON, and delete VMs that are marked Absent. Limit the scope to just those properties for now."*

**Result:** The AI drafted `requirements.md`. The business logic is now decoupled from the code. If a stakeholder wants to add network adapter support, they update `requirements.md` first, not the PowerShell script.

---

## Phase 3: The Technical Specification
The AI and the developer now translate the conceptual requirements into a technical specification. This is the exact blueprint the AI will use to generate the code.

**User Prompt to AI:**
> *"Based on our requirements, draft `Docs\Spec\vm_lifecycle_spec.md`. Detail the schema for the JSON payload. Define the algorithm for a Controller script named `Invoke-VMSync.ps1` that iterates over the JSON payload, and define the logic for a module function called `Assert-VMState` that handles the idempotency checks against Hyper-V cmdlets (`Get-VM`, `New-VM`, `Set-VMProcessor`, etc.)."*

**Result:** The AI generated `vm_lifecycle_spec.md`. This document contains pseudo-code and specific algorithms. The human developer reviews this document, tweaking the algorithm until it's perfect, without worrying about PowerShell syntax errors.

---

## Phase 4: Code Generation
This is where the magic of SDD happens. Because the constraints (Constitution), the goal (Requirements), and the schematic (Spec) are fully defined and written to disk, the code generation prompt becomes incredibly simple and deterministic.

**User Prompt to AI:**
> *"Read `Docs\Spec\constitution.md` and `Docs\Spec\vm_lifecycle_spec.md`. Generate the `src\Modules\VMLifecycle\VMLifecycle.psm1` library and the `src\Invoke-VMSync.ps1` controller script exactly as specified. Also, generate an `Example\state.json` file with 3 sample VMs."*

**Result:** The AI produced the structural code found in `src\`. Because the AI was constrained by the SDD artifacts:
1. It used `[CmdletBinding()]` and strict types (Constitution).
2. It handled `Present` and `Absent` states (Requirements).
3. It checked for drift on `CPUCount` before running `Set-VMProcessor` (Lifecycle Spec).

---

## Phase 5: Execution
The final product is a clean, testable utility. A user can run the application knowing it behaves predictably because it was bound to specifications.

**How to run the Demo:**
1. Open a PowerShell terminal as Administrator (Hyper-V module required).
2. Navigate to the project root: `cd d:\Tech\git\local_projects\SDD-Demo2`
3. Execute the controller against the sample state:
   ```powershell
   .\src\Invoke-VMSync.ps1 -StateFilePath .\Example\state.json
   ```

*(Note: Depending on your local Hyper-V setup, running this without `-WhatIf` will attempt to create or remove VMs on your local machine if the Hyper-V role is installed).*

---

## Phase 6: Enterprise Upgrades (Phase 2)
After the initial MVP was built, the requirements grew to include strict enterprise standards (Fail-Fast, PSScriptAnalyzer compliance, Unit testing) and a robust 3-stream logging architecture with automated log rotation. 

Instead of jumping into the code to bolt this on, the developer updated the AI context via the SDD artifacts:
1. **Constitution Updated**: The developer added rules demanding `$ErrorActionPreference = 'Stop'`, rigorous splatting instead of backticks, and Pester test coverage to `docs\spec\constitution.md`.
2. **Requirements Updated**: The non-functional requirements for logging (Aggregator JSON, Developer diagnostic, and Terminal console) and rotation policies (30 days or 1GB max) were added to `requirements.md`.
3. **New Specification Drafted**: The developer drafted `docs\spec\logging_spec.md`, which explicitly defined the algorithm for rotating the files and the expected paths.

**User Prompt to AI:**
> *"I have updated our Constitution and Requirements, and provided a new `logging_spec.md`. Please build the new `Logging` module based strictly on the spec. Then, refactor our existing Controller and Lifecycle library to use `Write-Log` instead of `Write-Host`, enforce fail-fast, replace backticks with splatting, and ensure `Invoke-ScriptAnalyzer` passes 100%. Finally, generate Pester tests for all logic."*

**Result:** The AI executed the refactor without needing constant corrections or code-reviews because the exact behavior for error handling, log paths, and JSON properties were already defined. 

---

## Phase 7: Scaling the Architecture (Phase 3)
As the project proved successful, the requirements immediately expanded. Managing VM state wasn't enough; the tool needed to manage **Virtual Switches** and **Virtual Hard Disks** declaratively before attaching them to the VMs.

Dumping all this logic into a single `VMLifecycle.psm1` quickly becomes unmaintainable. In SDD, we solve this by decomposing the *Specifications* before we ever touch the code.

1. **Artifact Decomposition**: The monolithic `vm_lifecycle_spec.md` was deleted. In its place, three domain-specific specifications were drafted:
   - `hyperv_compute_spec.md`
   - `hyperv_network_spec.md`
   - `hyperv_storage_spec.md`
2. **State Payload Evolution**: `state.json` was upgraded to contain three distinct JSON arrays representing each domain's declarative resources.
3. **AI Code Generation**: The AI was prompted:
> *"I have broken out our specifications into three distinct domains. Please replace the `VMLifecycle` module entirely with three new modules corresponding to the specs (`HyperV.Compute`, `HyperV.Network`, `HyperV.Storage`). Then, replace the Controller with `Invoke-HyperVSync.ps1`, ensuring it orchestrates the Network, Storage, and Compute domains in the proper dependency order based on the new `state.json`."*

**Result**: The AI successfully created the three independent PS modules, each strictly adhering to their individual declarative rules (e.g., dynamically expanding VHDX files if they exist but are too small). It automatically generated the overarching integration tests, proving that SDD projects scale beautifully by dividing architectural ownership at the specification layer.

## Conclusion
By shifting the focus from "writing code" to "writing specifications and rules," Spec-Driven Development empowers developers to build complex, reliable systems much faster. The AI becomes a highly capable engineer that never violates architectural guidelines, because it reads the Constitution first.
