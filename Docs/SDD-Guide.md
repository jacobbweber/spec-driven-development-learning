# **Spec-Driven Development (SDD): The 2026 Developer’s Guide**

**TL;DR:** Spec-Driven Development (SDD) shifts your role from writing code to writing **blueprints (specs)**. You own the intent; the AI owns the implementation. If the implementation fails, you update the specification—never patch the code directly.

---

# What is it?
Think of SDD like being an **Master Chef**, not the Cooker. In traditional coding, you spend your day cooking (typing lines of code). In SDD, you spend your day designing the menu and the recipe.

**The Golden Rule:** You are writing and managing **Specification Documents**, NOT the code directly. You are the source of intent; the AI is the source of implementation. You tell the AI *exactly* what to build and how it should behave in Markdown file(s), then the AI executes that plan.

### Skill & Time Distribution
**Traditional Developer**
* **Syntax/Language Mastery:** `[▓▓▓▓▓▓▓▓░░]` (80%) — Knowing where every semicolon goes.
* **Architectural Planning:** `[▓▓░░░░░░░░]` (20%) — High-level design is often an afterthought.
* **Time Spent Debugging Code:** `[▓▓▓▓▓▓▓░░░]` (70%) — Hunting for typos and logic errors.

**SDD Developer (Architect)**
* **Syntax/Language Mastery:** `[▓▓░░░░░░░░]` (20%) — You only need to read code, not type it perfectly.
* **Architectural Planning:** `[▓▓▓▓▓▓▓▓░░]` (80%) — Your value is in the clarity of your logic.
* **Time Managing Specs:** `[▓▓▓▓▓▓▓▓░░]` (80%) — Refining instructions so the AI builds it right the first time.


# Overview
* **Intent-First (Brain Before Fingers):** You decide exactly what you want and why you want it before a single line of code exists. This stops you from "making it up as you go" and prevents messy code.
* **Source of Truth (The Blueprint is King):** If the code and the spec don't match, the code is considered "broken." The spec is the final authority on how the app must behave.
* **Agentic Execution (The AI General Contractor):** You give the spec to an AI Agent. It reads the file, makes a technical plan, and performs the work across your whole project automatically.
* **Traceability (The Paper Trail):** Every feature has a "receipt"—a spec file that explains exactly why that code exists. This makes it easy to change things later without breaking the system.

# Context
### Context Clarification
While the philosophy (SDD) is the same, different tools use different "languages" to describe these concepts. 

It is important to understand that exact file naming is not critical when implementing the SDD philosophy, but it can be depending on the tool and framework you are using. Be sure to understand your tool or framework's requirements first. It is highly recommended to utilize an existing proven framework, as these are well-vetted and maintain consistency within the developer community.

| Framework/Tool | Term for "Spec" | Term for "Rules" | Key Workflow Concept |
| :--- | :--- | :--- | :--- |
| **GitHub Spec-Kit** | `spec.md` | `constitution.md` | **Slash Commands:** `/specify`, `/plan`, `/tasks`. |
| **Cursor** | **Notepads** | `.cursorrules` | **Composer:** Agentic "Edit Mode" using Notepads as context. |
| **Claude Code** | **Specs/Prompts** | `CLAUDE.md` | **Agentic Loops:** Multi-step autonomous terminal actions. |
| **Google Antigravity** | **Artifacts** | **Agent Config** | **Mission Control:** Orchestrating multiple parallel agents. |
| **VS Code / Copilot** | **Instructions** | `.github/copilot-instructions` | **Prompt Steering:** Guiding the AI via chat and file context. |
| **Windsurf / Flow** | **Flow Spec** | **Core Rules** | **Context Cascading:** Deep context passing between agents. |
| **Tessl** | **HSpecs** | **Standard** | **Transformation:** Code as a temporary artifact of the HSpec. |

# The Idea Behind SDD
SDD stops "vibe coding" (guessing and checking). By using a **Constitution** for global rules and **Specs** for feature logic, you prevent the AI from making incorrect assumptions. It treats the AI like a high-speed engine that requires a very precise map to reach the destination.

# How to Use It
1.  **Define the Law:** Create a `constitution.md` for rules that never change.
    * **Standards:** No secrets stored in the codebase; adhere to Semantic Versioning and Conventional Commits.
    * **Operations:** All changes must be maintained in a project `change.log`; Unit and Integration tests are required for all logic.
    * **Common Headers for Constitution Files:**
        * **Core Principles:** High-level goals and philosophy.
        * **Tech Stack:** Specific languages, frameworks, and versions.
        * **Security & Compliance:** Secret management and data handling laws.
        * **Standards & Tooling:** Formatting, linting, and testing requirements.
2.  **Define the Goal:** Write a `feat-001.md (or spec.md)` describing the functional requirements.
    * **Integrate SDLC Components:** Include Functional Requirements (FR), Non-Functional Requirements (NFR), User Stories, and Acceptance Criteria.
    * **Best Practices:** Define "Out-of-Scope" boundaries; list known edge cases; keep features atomic.
    * **Common Headers for Spec Files:**
        * **Context/User Story:** The "Who" and "Why."
        * **Functional Requirements:** The "What" (Features).
        * **Non-Functional Requirements:** Constraints (Performance, Security).
        * **Success Criteria:** Definition of Done (Given/When/Then).
3.  **Review the Plan:** The AI generates a `plan.md`. You approve it before any code is written.
4.  **Execute via Master Prompt:** Use a structured prompt to consume your files and trigger the AI agent.
    * **Example Master AI Prompt:** *"Read `.\constitution.md` and `.\specs\feat-001.md`. Based on these documents, generate a technical `plan.md` for my review. The plan should include architectural changes and an implementation task list. Do not write code yet."*

# Do's and Don'ts
### **Do's**
* **Always use the Master Prompt** to ensure the agent initializes with the correct hierarchy of context.
* **Review the Plan for logic gaps** before allowing the agent to write to the filesystem.
* **Treat the Spec as the Primary Fix**; if an edge case is missed, update the spec file first.
* **Include "Out-of-Scope" details** to prevent the agent from over-engineering or adding bloat.
* **Version your Specs** alongside your code to maintain a historical record of architectural intent.
* **Verify against the Task List** at the end of every agentic loop.

### **Don'ts**
* **Never "Quick Fix" code manually.** This creates a divergence that breaks future AI generations.
* **Don't update the Plan in isolation.** Changes to the implementation strategy must be reflected in the spec.
* **Don't over-specify implementation details.** Tell the agent *what* to achieve, not *how* to write the loop.
* **Don't skip the "Clarify" phase.** If the agent asks a question about the spec, your spec isn't clear enough.
* **Never commit secrets or keys** to the repository, regardless of what the agent suggests.

# The SDD Debugging Loop
* **Fix the Spec, Not the Code:** If there is a bug, the AI likely misunderstood the instructions.
* **Specificity Check:** If code formatting, syntax, or logic isn't following expectations, review your governing laws and spec; you are likely not specific enough in your details.
* **The Over-Specification Gotcha:** Avoid bloating your constitution with granular rules (e.g., specific regex patterns). If the constitution is too large, the agent will lose focus on the feature spec.
* **Mid-Project Law Changes:** Updating your constitution mid-way through a project often causes "Context Drift." Expect the agent to require a major refactor of existing code to align with the new laws.
* **Process:** Update `spec.md` $\rightarrow$ Update `plan.md` $\rightarrow$ Agent fixes code. 

# SDLC: Critical Aspects
* **Upstream Planning:** 80% of your effort is spent on architecture and specs.
* **Verification Gates:** You verify that the code matches the **Task List**, not just that the tests pass.
* **Maintenance:** Onboarding is instant; new devs read the `specs/` folder to understand the system.

# The Process Flow (GitHub Spec-Kit Framework)
1.  **Constitution:** Define immutable project standards.
2.  **Specify:** Define user stories and success metrics.
3.  **Clarify:** Resolve ambiguities through human-in-the-loop Q&A.
4.  **Plan:** Select technical patterns and architecture.
5.  **Tasks:** Decompose the plan into atomic steps.
6.  **Implement:** Agent executes tasks; human validates via tests.

# Evolution & Maintenance
* **Living Documentation:** Specs live in the repo and evolve with every PR, ensuring docs are never "stale."
* **Cross-Platform Parity:** Use one `spec.md` to drive implementation across Web, iOS, and Android for identical logic.

# Team Adoption Plan
* **Knowledge Sharing:**
    * Create a central Confluence/Wiki page for SDD workflows.
    * Conduct **"Spec Review"** sessions instead of traditional "Code Reviews."
* **Standardized Tooling:**
    * Deploy **GitHub Spec-Kit** for new feature development.
    * Use **VS Code/Copilot** or **Cursor** for rapid prototyping within SDD constraints.
* **Consistency:**
    * **Master Templates:** Standardize `python-constitution.md`, `powershell-constitution.md`, etc.
    * **Feature Blueprints:** Use reusable `spec-template.md` files to ensure SDLC components (FR/NFR) are never missed.
