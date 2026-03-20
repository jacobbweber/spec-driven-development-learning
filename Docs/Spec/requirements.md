# VM Lifecycle Manager - Requirements

## Overview
The VM Lifecycle Manager is a declarative orchestration tool designed to manage Hyper-V virtual machines on a local host. Instead of writing procedural scripts to create or delete VMs, users will define a desired state in a JSON file. The system will read this file and ensure the host environment matches the definition.

## Target Audience
- System Administrators and DevOps Engineers managing local Hyper-V workloads.

## Core Use Cases
1. **Declarative Virtual Networking**: Create and manage Hyper-V Virtual Switches (Private or Internal types). If a switch is missing, create it. If it exists but the SwitchType is wrong, update it.
2. **Declarative Storage Management**: Define VHDX files with specific sizes and paths. If missing, create the VHDX. If the size is too small, expand it.
3. **Declarative Compute Provisioning**: Create VMs with specific CPU and Memory allocations. Attach those VMs to the declaratively created Virtual Switches and mount the declarative VHDX files as hard drives.
4. **Declarative De-provisioning (Absent State)**: Remove any of the above resources if their desired state is "Absent".
5. **State Verification**: A user runs the tool with a `-WhatIf` or `-DryRun` equivalent to see what *would* happen without making actual changes.

## Non-Functional Requirements (Enterprise Upgrades)
### Logging
- A single, centralized logging function must be used for all output (Info, Warn, Error, Debug).
- Three distinct log variants must be generated simultaneously:
  1. **Aggregator Log**: Machine-readable format (JSON) suitable for Splunk or similar engines.
  2. **Developer Log**: Highly detailed text log including all debug context, stack traces, and verbose data.
  3. **Console Output**: Human-readable standard output directly to the terminal for the user running the script.
- **Log Retention & Rotation**: Logs must be rotated into an `\archive\[date]\` directory. Retention policy dictates logs are pruned if they exceed 30 days in age or 1GB in total size.

### Testing
- 100% of Library functions must have Unit Tests.
- Integration tests must be available for end-to-end execution scenarios.

## Out of Scope (For this demo phase)
- Network adapter configuration (Virtual Switches).
- Complex storage layouts (multiple VHDXs).
- Guest OS configuration (e.g., running scripts inside the VM).

## Inputs & Outputs
- **Input**: A `state.json` file containing an array of VM definitions (Name, State, CPUCount, MemoryMB, BootDevice).
- **Output**: Console logging indicating the actions taken (Created, Updated, Deleted, Skipped).
