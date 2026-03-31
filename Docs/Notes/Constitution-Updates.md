**TL;DR**: The **Plan/Apply** pattern and **Testing Definitions** belong in the **Constitution** because they are universal architectural standards. Specific "Plan" logic (e.g., *if X then Y*) and unique "Mock Data" schemas belong in the **Spec**. You should update the Constitution to mandate the use of an **Action Manifest** and clarify the roles of **Simulation** vs. **Audit ($WhatIf)**.

---

## Recommended Constitution Refinements

### 1. Updated Section 1: Philosophy & Workflow
* **Declarative Intent (Plan/Apply):** Scripts must utilize the **Plan/Apply** design pattern. The logic must first determine a "Plan" (Desired State) before any "Apply" (State Change) occurs. This ensures predictability and allows for rich auditing.
* **Idempotency:** Operations must verify the current state against the desired state. If the states match, no action is taken.

### 2. Updated Section 2: Architectural Mandate (Process Block)
* **Process Block (The Planner):** This block is responsible for data ingestion and the calculation of an **Action Manifest**. 
    * The manifest is an internal collection of objects representing "Intents" (e.g., `TargetVM`, `Action`, `Reason`).
    * No state-changing commands (Set, Remove, New) should be executed inside the main logic loop of the `Process` block.

### 3. Updated Section 4: Execution Modes
* **Simulation Mode (`-Simulation`):**
    * **Purpose:** Offline Logic Verification.
    * **Behavior:** Bypasses live connection calls (ZVM/vCenter). Loads static mock data from a standardized `./tests/mock/` path. 
    * **Mandate:** Must produce identical artifact structures (Logs/Excel) as a live run to verify business logic integrity without a network.
* **Audit/Plan Mode (`-WhatIf`):**
    * **Purpose:** Online Environment Audit.
    * **Behavior:** Connects to live systems but suppresses destructive actions via `$PSCmdlet.ShouldProcess`.
    * **Mandate:** Must output the "Action Manifest" to Excel/Logs with a status of `Proposed` or `Would Have...`.

### 4. Updated Section 7: Quality Assurance (Testing Definitions)
* **Unit Tests (Library/Module):**
    * **Target:** Individual functions in `/lib`.
    * **Goal:** Verify function-level input/output consistency. Mocks are mandatory for all external I/O (disk/API).
* **Integration Tests (Controller/Script):**
    * **Target:** The script file and its orchestration.
    * **Goal:** Validate **Business Logic** and **Bootstrap Integrity**.
    * **Method:** Run the script in `-Simulation` mode via Pester. Assert that given a specific mock state, the resulting "Action Manifest" contains the expected intents.

---

## Summary of Responsibilities

| Item | Located In: **Constitution** | Located In: **Script Spec** |
| :--- | :--- | :--- |
| **Architectural Pattern** | Mandates "Plan/Apply" structure. | N/A |
| **Execution Switches** | Defines `-WhatIf` and `-Simulation`. | N/A |
| **Business Logic** | N/A | Defines the *rules* for the Plan (e.g., "Delete if > 30 days"). |
| **Mock Data** | Defines where mock JSON is stored. | Defines the *content* of the mock JSON. |
| **Testing Standards** | Defines Unit vs. Integration. | Defines specific test cases for that script. |

---

### Implementation Note for the `End` Block
To support the **Plan/Apply** pattern effectively, the `End` block should be the only place where the "Apply" phase occurs (unless the script is designed to process extremely large datasets in chunks). This ensures that if the script fails during the `Process` (Plan) block, no partial changes have been made to the environment.