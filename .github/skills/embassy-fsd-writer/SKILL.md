---
name: embassy-fsd-writer
description: >
  Generates or updates implementation-oriented project documents and structured
  build plans for embedded Rust projects using Embassy. Converts rough embedded
  project ideas into deterministic engineering specs with architecture, task model,
  HAL/peripheral planning, async execution design, verification strategy, and
  phased implementation guidance. Supports initial generation and incremental
  evolution. Triggers on "Embassy", "embassy", "Rust embedded", "embedded rust",
  "write embassy spec", "create embassy spec", "generate embassy plan",
  "new embassy project spec", "update embassy spec", "evolve embassy spec".
---

# Embassy FSD Writer Skill

A general-purpose skill that turns a rough, unstructured embedded Rust project
description into a structured engineering specification and implementation plan
for projects built with **Rust** and the **Embassy async embedded ecosystem**,
or surgically updates an existing document with new requirements, constraints,
or architectural changes.

This skill is intended for microcontroller firmware projects such as sensor
nodes, gateways, HID devices, data loggers, control systems, BLE peripherals,
network-connected edge devices, and mixed interrupt/async embedded systems.

## 1. Purpose

This skill:

- Generates a canonical Embassy-oriented engineering specification from a rough description (**initial mode**).
- Updates or expands an existing project specification using a delta description (**evolve mode**).
- Adapts depth and detail based on inferred firmware complexity.
- Produces deterministic, implementation-ready Markdown for agent and developer consumption.
- Surfaces embedded-specific risks such as memory pressure, timing constraints, interrupt interactions, DMA usage, and power modes.
- Captures traceability between requirements, architecture decisions, and test coverage.
- Encourages Embassy-native design patterns such as task-based decomposition, async drivers, signal/channel usage, and explicit resource ownership.

It supports bare-metal microcontrollers, RTIC-to-Embassy migrations, ESP32,
nRF, STM32, RP2040, USB devices, BLE peripherals, Wi-Fi enabled devices,
UART/SPI/I2C sensor systems, and hybrid embedded/cloud-connected projects.

## 2. Invocation

### 2.1 Mode A — Initial Generation

Start a new Embassy project specification from scratch.

```text
/embassy-fsd-writer
<rough description text>
```

Behavior:
1. Parse the rough description.
2. Ask clarifying questions if critical implementation information is missing (Section 5).
3. Infer complexity tier (Section 6).
4. Generate the complete specification (Section 7).
5. Write the file (Section 10).

### 2.2 Mode B — Evolve Existing Document

Update, expand, refactor, or correct an already existing Embassy project spec.

```text
/embassy-fsd-writer update <path-to-existing-doc>
<delta description — changes, additions, clarifications, new constraints>
```

If no path is given, search the project for an existing spec:
1. Check `Documents/*-embassy-spec.md`
2. Check `Documents/*-rust-embedded-spec.md`
3. Check `docs/*-embassy-spec.md`
4. Check project root for `*-embassy-spec.md`

Behavior:
1. Read the existing document in full using the **Read** tool.
2. Parse the delta description.
3. Ask clarifying questions only if the delta introduces architectural ambiguity or invalidates prior assumptions.
4. Apply changes surgically — preserve all unaffected sections verbatim.
5. Regenerate only the sections affected by the delta.
6. Maintain numbering, cross-references, requirement IDs, and traceability automatically.
7. Write the updated file using the **Edit** tool (preferred) or **Write** tool (if changes are too extensive for surgical edits).

## 3. Tool Usage

This skill uses the following Claude Code tools:

| Tool | When |
|------|------|
| **Read** | Read existing spec, `Cargo.toml`, linker scripts, board configs, HAL setup |
| **Glob** | Find existing specs, project structure, examples, `.cargo/`, memory files |
| **Grep** | Search for Embassy crates, HAL crates, peripherals, features, executor/task usage |
| **Write** | Create new specification file or full rewrite |
| **Edit** | Surgical updates to existing sections |
| **AskUserQuestion** | Clarifying questions when architecture-affecting details are missing |
| **Task** (Explore) | Deep codebase exploration when source already exists |

### 3.1 Context Gathering (Before Generation)

Before writing the specification, the skill should gather context from the project
when source code exists:

1. **Glob** for project structure — `Cargo.toml`, `rust-toolchain.toml`,
   `.cargo/config.toml`, `memory.x`, `build.rs`, `src/**/*.rs`,
   `examples/**/*.rs`, `Embed.toml`, `probe-rs*.toml`.
2. **Grep** for Embassy ecosystem crates — `embassy-executor`, `embassy-time`,
   `embassy-sync`, `embassy-usb`, `embassy-net`, `embassy-stm32`,
   `embassy-rp`, `embassy-nrf`, `esp-hal`, `esp-wifi`, `bt-hci`, `trouble`,
   `defmt`, `panic-probe`, `static_cell`.
3. **Read** key config files — feature flags, target triples, linker config,
   memory map, logging setup, flashing/debug configuration.
4. Use findings to pre-fill architecture, executor model, peripheral ownership,
   and deployment sections.
5. If the project is nontrivial, infer likely MCU family and runtime constraints
   from dependencies and target configuration.

### 3.2 Evolve Mode — Diff Discipline

When updating an existing specification:

- **Never regenerate the entire file** unless the user explicitly requests a rewrite.
- Use the **Edit** tool with precise `old_string` / `new_string` pairs.
- Preserve all unaffected prose verbatim.
- Keep existing requirement IDs stable.
- Add new requirements using the next available ID in the correct group.
- Update traceability and verification sections whenever requirements or tests change.
- Revise assumptions if newly provided information confirms or contradicts them.
- If new peripherals or tasks are introduced, update resource ownership and concurrency sections consistently.

## 4. What This Skill Produces

This skill generates a structured engineering document focused on how to build the
firmware, not just what the firmware should do.

The output emphasizes:

- Target MCU / board assumptions
- Crate and dependency strategy
- Embassy executor/task model
- Interrupt/DMA/peripheral ownership boundaries
- Async communication patterns (`Signal`, `Channel`, `Mutex`, pub-sub)
- Startup, init, and boot flow
- Power and timing behavior
- Error handling and recovery strategy
- Flash, RAM, and storage constraints
- Bring-up, test, and debug procedures
- Verification and traceability

Typical outputs may be:
- a project spec,
- an implementation plan,
- a firmware architecture document,
- or an evolved version of one of the above.

## 5. Interaction Model (Clarifying Questions)

### 5.1 When to Ask

The skill must ask clarifying questions when critical implementation-affecting
information is missing. "Critical" means it affects:

- MCU family or board selection
- Peripheral availability or pin assignments
- Communication stack choice (BLE, Wi-Fi, USB, Ethernet, UART, CAN, LoRa)
- Timing model or hard real-time expectations
- Power constraints (battery, sleep, duty cycle)
- Safety/reset behavior
- Memory/storage constraints
- Update method (bootloader, DFU, USB, OTA, SWD only)
- Host-side integration expectations
- Whether the firmware is greenfield or must integrate with existing code

### 5.2 How to Ask

Use the **AskUserQuestion** tool with:
- 1-3 precise questions per round
- Multiple-choice options where possible
- Questions that unblock architecture and implementation planning

Example:

```text
Questions:
1. "Which MCU or board should this target?" → Options: STM32, RP2040, nRF52, ESP32, Unsure
2. "How does the device communicate externally?" → Options: BLE, Wi-Fi, USB, UART, Ethernet, Mixed
3. "Is low-power sleep behavior required?" → Options: Yes, No, Unsure
```

### 5.3 When to Infer Instead of Asking

The skill may silently infer reasonable defaults when:
- The detail does not materially change architecture, AND
- The cost of being wrong is low.

Safe inferences:
- "sensor polling" mentioned → assume periodic Embassy timer-driven task
- "logs" mentioned → assume `defmt` + RTT or UART logging (assumed)
- "settings" mentioned → assume flash-backed persisted configuration (assumed)
- "USB keyboard" mentioned → assume `embassy-usb` with HID class (assumed)
- "networking" mentioned on supported MCUs → assume async socket/task separation (assumed)

All such inferences must be marked `(assumed)` in the document or listed in
Risks, Assumptions & Dependencies.

## 6. Complexity Scaling Rules

The skill dynamically scales document depth based on inferred firmware complexity.

### 6.1 Complexity Tiers

| Tier | Characteristics | Target Length | Tasks |
|------|----------------|---------------|-------|
| **Low** | Single MCU, 1-3 peripherals, simple async loop | 3-5 pages | 1-3 |
| **Medium** | Multiple concurrent tasks, networking or USB, persistence, recovery | 6-12 pages | 3-6 |
| **High** | Multi-interface, strict timing, DMA/interrupt coordination, power modes, boot/update complexity | 12-20+ pages | 5-10 |

### 6.2 Complexity Signals

Infer complexity from:
- Number of peripherals and buses
- Number of concurrent Embassy tasks
- Presence of USB/BLE/Wi-Fi/network stacks
- DMA use, interrupt-heavy design, or mixed sync/async boundaries
- Need for persistence, bootloader/update flows, or fail-safe behavior
- Power management requirements
- Domain constraints (industrial control, medical, robotics, energy systems)

### 6.3 Scaling Behavior

| Section | Low | Medium | High |
|--------|-----|--------|------|
| Overview | Brief | Full | Full + stakeholders/constraints |
| Architecture | Basic module layout | Task + peripheral model | Full task/resource/timing model |
| Requirements | 5-12 FRs, 3-5 NFRs | 12-25 FRs, 5-10 NFRs | 25+ FRs, 10+ NFRs |
| Concurrency | Minimal | Channels/signals/tasks | Detailed ownership and priority analysis |
| Verification | Checklist | Structured test tables | Full matrix + fault injection |
| Troubleshooting | Optional | Included | Detailed recovery and debug workflows |

## 7. Information Extraction & Inference Rules

Given the rough description, the skill must extract or infer the following.

### 7.1 Project Name

Derive a short descriptive name, for example:
- `Embassy BLE Environmental Sensor`
- `RP2040 USB Macro Pad`
- `STM32 Modbus Gateway`
- `nRF52 Battery Telemetry Node`

### 7.2 System Purpose & Goals

Summarize:
- what the firmware does,
- who or what it interacts with,
- where it runs,
- and the primary engineering goals.

### 7.3 Platform & Hardware Context

Identify or infer:
- MCU family and target board
- clocks and timing-sensitive subsystems
- buses and peripherals
- external devices and sensors
- power source and reset constraints
- debug/programming method

### 7.4 Software Architecture

Identify:
- `main` / startup flow
- executor model
- Embassy tasks
- shared resources
- driver layering
- storage/persistence strategy
- communication stacks
- error propagation/restart boundaries

### 7.5 Functional Requirements (FR)

Convert described behaviors into FR-x.y items:
- Group by domain: platform, sensing, communications, storage, UI/control, updates
- Assign priority: **Must** / **Should** / **May**
- Use “shall” language

Example:
> "Read temperature every second and publish over BLE."

Becomes:
- **FR-1.1** [Must]: The firmware shall sample the temperature sensor at a configurable interval with a default period of 1 s.
- **FR-1.2** [Must]: The firmware shall publish the latest temperature reading through the BLE interface.
- **FR-1.3** [Should]: The firmware shall timestamp or sequence outgoing sensor updates for debugging and ordering.

### 7.6 Non-Functional Requirements (NFR)

Extract or infer:
- latency
- sampling jitter
- memory footprint
- boot time
- fault recovery
- uptime/reliability
- power consumption
- security
- flash endurance
- observability/debuggability

### 7.7 Embassy-Specific Design Decisions

The skill must explicitly capture:
- which executor model is assumed
- task decomposition and task ownership
- which resources are shared and how
- whether interrupts signal async tasks
- whether DMA is used and by whom
- what primitives coordinate work (`Signal`, `Channel`, mutexes, critical sections)
- whether blocking code must be isolated or avoided

### 7.8 Interfaces & Data Models

Describe:
- electrical/protocol interfaces
- user or host interfaces
- data payloads and units
- command formats
- buffer ownership expectations
- timing assumptions

### 7.9 Implementation Phases

At minimum define:
- **Phase 1**: Bring-up and platform foundation
- **Phase 2**: Core firmware behavior
- **Phase 3**: Reliability, optimization, and field readiness

Each phase must include:
- Scope
- Deliverables
- Exit criteria
- Dependencies

### 7.10 Verification & Validation

Generate test cases that verify:
- functional behavior
- concurrency behavior
- timeout/retry behavior
- error recovery
- power-up/reset flow
- critical NFRs such as latency or memory use

When the project targets a supported MCU (RP2040, STM32, nRF52, ESP32, etc.),
the skill **must** prescribe
[`embedded-test`](https://github.com/probe-rs/embedded-test) as the on-target
test harness. `embedded-test` integrates with `probe-rs` and Rust's standard
`#[test]` / `cargo test` workflow, running tests directly on hardware via a
`probe-rs` runner.

For each test case in Section 8 the skill must specify:
- Whether the test runs **on-target** (`embedded-test` + `probe-rs`) or
  **off-target** (host `cargo test` with mocks/QEMU).
- The `embedded-test` runner invocation, for example:
  ```
  cargo test --target thumbv6m-none-eabi -- --probe <VID:PID>
  ```
- Any `#[init]` setup or `#[test]` attribute usage needed (e.g., peripheral
  ownership teardown between tests).
- `defmt`-based assertion macros (`defmt::assert!`, `defmt::assert_eq!`)
  preferred over `std` equivalents for on-target tests.

Test strategy guidance:
- **Unit tests** (pure logic, no peripherals) → off-target host tests.
- **Integration tests** (peripheral drivers, async tasks, timing) → on-target
  `embedded-test`.
- **Acceptance / soak tests** → on-target with hardware in the loop.
- Capture the `probe-rs` chip target string needed to flash and run the test binary.

## 8. Canonical Document Structure

All generated or updated documents must conform to this structure:

```markdown
# <Project Name> — Embassy Embedded Project Specification

## 1. System Overview
- Purpose
- Problem statement
- Users / operators / integrators
- Goals & non-goals
- High-level runtime flow

## 2. Platform & Architecture
### 2.1 Hardware / Platform Context
- MCU / board / peripherals
- External devices
- Connectivity and power constraints

### 2.2 Software Architecture
- Crates / modules / layering
- Initialization and boot flow
- Persistence / storage
- Error handling model

### 2.3 Concurrency & Task Model
- Embassy executor assumptions
- Tasks and responsibilities
- Shared resources and ownership
- Signals, channels, mutexes, interrupts, DMA

## 3. Implementation Phases
### 3.1 Phase 1 — Bring-up & Foundation
### 3.2 Phase 2 — Core Functionality
### 3.3 Phase 3 — Reliability & Production Readiness

Each phase includes:
- Scope
- Deliverables
- Exit criteria
- Dependencies

## 4. Requirements
### 4.1 Functional Requirements (FR)
- FR-x.y [Must/Should/May]: requirement text

### 4.2 Non-Functional Requirements (NFR)
- NFR-x.y [Must/Should/May]: requirement text

### 4.3 Constraints
- MCU/resource/toolchain/environment constraints

## 5. Risks, Assumptions & Dependencies
- Technical risks with mitigation
- Assumptions (mark inferred items with "(assumed)")
- Crate and toolchain dependencies
- Hardware and supply dependencies

## 6. Interface Specifications
### 6.1 External Interfaces
- BLE, USB, UART, SPI, I2C, Wi-Fi, Ethernet, GPIO, etc.

### 6.2 Internal Interfaces
- Task-to-task communication
- Driver abstractions
- Buffer / ownership boundaries

### 6.3 Data Models / Message Formats
- Sensor payloads
- Commands
- Binary or textual protocol formats

## 7. Operational Procedures
- Build and flash
- Provisioning / configuration
- Normal operation
- Logging / debugging
- Recovery / factory reset / reprovisioning

## 8. Verification & Validation
### 8.1 Phase 1 Verification
| Test ID | Feature | Procedure | Success Criteria |
|---------|---------|-----------|-----------------|

### 8.2 Phase 2 Verification
| Test ID | Feature | Procedure | Success Criteria |
|---------|---------|-----------|-----------------|

### 8.3 Acceptance Tests
- End-to-end scenarios
- Soak/reliability tests
- Fault-injection tests

### 8.4 On-target Test Configuration (`embedded-test`)

Document the `embedded-test` + `probe-rs` setup required to run tests on hardware:

```toml
# .cargo/config.toml — wire up probe-rs as the test runner
[target.'cfg(all(target_arch = "arm", target_os = "none"))']
runner = "probe-rs run --chip <CHIP>"
```

```toml
# Cargo.toml — add embedded-test as a dev-dependency
[dev-dependencies]
embedded-test = { version = "0.x", features = ["defmt"] }
```

Specify:
- `probe-rs` chip target string (e.g., `RP2040`, `STM32F411RETx`, `nRF52840_xxAA`)
- Feature flags required (`defmt`, `embassy`, `xtensa`, etc.)
- Test module structure using `#[embedded_test::tests]` and `#[init]` setup
- Whether tests require exclusive peripheral access and how teardown is handled
- CI/CD considerations (hardware-in-the-loop vs. QEMU/off-target host fallback)

### 8.5 Traceability Matrix
| Requirement | Priority | Test Case(s) | Test Runner | Status |
|------------|----------|-------------|-------------|--------|

## 9. Troubleshooting Guide
| Symptom | Likely Cause | Diagnostic Steps | Corrective Action |
|---------|-------------|-----------------|-------------------|

## 10. Appendix
- Pin assignments
- Task inventory
- Memory budget assumptions
- Timing budgets
- Example logs / messages / packet layouts
```

### 8.1 Section Inclusion Rules

The skill must:
- **Always include**: Sections 1, 2, 3, 4, 5, 7, 8
- **Include** Section 6 whenever there is any protocol, bus, host, or task boundary worth documenting
- **Include** Section 9 for medium/high complexity projects
- **Include** Section 10 when concrete implementation constants or mappings exist
- Omit empty sections instead of writing “N/A”

## 9. Traceability Matrix (Mandatory)

Every generated document must contain a traceability matrix in Section 8.5.

Rules:
- Every **Must** and **Should** FR/NFR must appear in at least one test.
- Every test case must reference the FR(s) / NFR(s) it validates.
- The **Test Runner** column must be one of: `embedded-test` (on-target), `host` (off-target), or `manual`.
- Requirements lacking test coverage must be flagged as `GAP`.
- **May** items may be tested but are not required to be.
- In evolve mode, the traceability matrix must be regenerated to reflect all changes.

## 10. Formatting & Style Rules

- Output pure Markdown.
- Use heading levels exactly as defined in Section 8.
- Use concise engineering language.
- Use **"shall"** for requirements.
- Use **"must"** for hard constraints.
- Prefer tables for interfaces, tests, risks, and troubleshooting.
- Keep requirement IDs stable across evolve updates.
- Preserve unaffected text verbatim in evolve mode.
- Explicitly mark inferred details with `(assumed)`.

## 11. Output File Naming & Location

### 11.1 Default Location

If the user does not specify a target path:

```text
Documents/<project-name-kebab-case>-embassy-spec.md
```

Examples:
- `Documents/embassy-ble-environmental-sensor-embassy-spec.md`
- `Documents/rp2040-usb-macro-pad-embassy-spec.md`
- `Documents/stm32-modbus-gateway-embassy-spec.md`

### 11.2 Explicit Path

If the user provides a path, use it exactly.

### 11.3 Evolve Mode

When updating, write back to the same file that was read unless the user requests otherwise.

## 12. Feature Detection Heuristics

When source code exists, detect likely project features and incorporate them into
requirements and verification planning.

| Feature | Detection Patterns |
|--------|--------------------|
| **Embassy Executor** | `#[embassy_executor::main]`, `Spawner`, `#[embassy_executor::task]` |
| **Time/Timers** | `embassy_time`, `Timer::after`, `Ticker` |
| **Sync Primitives** | `embassy_sync`, `Signal`, `Channel`, `Mutex`, `PubSubChannel` |
| **USB** | `embassy_usb`, `usb`, `HID`, `CDC`, `MSC` |
| **Networking** | `embassy_net`, DHCP, TCP, UDP, DNS |
| **BLE** | `trouble`, `ble`, `gatt`, `advertising` |
| **Wi-Fi** | `cyw43`, `esp-wifi`, `wifi` |
| **Storage** | `embedded-storage`, flash, littlefs, nvm, config persistence |
| **Logging** | `defmt`, RTT, UART logs |
| **DMA** | `dma`, transfer completion interrupts, ring buffers |
| **Low Power** | sleep, stop mode, wakeup pin, deep sleep |
| **Bootloader/Update** | DFU, boot, OTA, image swap, rollback |
| **On-target Testing** | `embedded-test`, `#[embedded_test::tests]`, `probe-rs` runner, `cargo test --target` with embedded runner |

Workflow:
1. Scan the source tree and configuration files for the patterns above.
2. Reflect detected features in architecture, requirements, risks, and tests.
3. Add or expand verification cases for each detected subsystem.
4. Capture unsupported or uncertain capabilities as assumptions or open questions.

## 13. Quality Checklist

After generating or updating a document, the skill must verify:

- [ ] Every **Must** and **Should** FR/NFR appears in the traceability matrix.
- [ ] Every uncovered requirement is marked `GAP`.
- [ ] The traceability matrix includes a **Test Runner** column (`embedded-test` / `host` / `manual`).
- [ ] Section 8.4 (`embedded-test` configuration) is present and specifies the `probe-rs` chip target string.
- [ ] No placeholder or TODO text remains unless explicitly called out.
- [ ] Section numbering is sequential.
- [ ] Every phase has scope, deliverables, and exit criteria.
- [ ] Task model and resource ownership are internally consistent.
- [ ] Interrupt, DMA, and shared-resource assumptions are documented where relevant.
- [ ] The file path is correct.
- [ ] In evolve mode, unaffected sections are unchanged.

Report checklist failures to the user before finalizing.

## 14. Example Output Snippet

```markdown
# RP2040 USB Macro Pad — Embassy Embedded Project Specification

## 1. System Overview

The firmware shall run on an RP2040-based macro pad and expose a USB HID
keyboard interface to a host computer. Physical key presses shall be scanned,
debounced, translated into configurable key sequences, and emitted with bounded
input latency. The firmware is intended for desktop productivity and developer
automation workflows.

**Primary goals:**
- Deterministic key scan and HID event generation
- Configurable key mappings stored persistently
- Reliable USB enumeration and recovery after host reconnect
- Structured debug logging for bring-up and support

**Non-goals:**
- Wireless connectivity in Phase 1
- Runtime macro editing from a host GUI in initial releases

## 2.3 Concurrency & Task Model

- **Task A — key_scan_task**: Periodically scans the key matrix and debounces transitions.
- **Task B — hid_output_task**: Consumes debounced key events and emits USB HID reports.
- **Task C — status_task**: Drives status LED patterns and fault indication.
- A bounded channel shall transfer key events from the scan task to the HID task.
- USB interrupt handling shall remain compatible with the Embassy executor model.
- Persistent configuration writes shall be deferred to a low-frequency maintenance path.

## 4. Requirements

### 4.1 Functional Requirements

- **FR-1.1** [Must]: The firmware shall enumerate as a USB HID keyboard on supported host systems.
- **FR-1.2** [Must]: The firmware shall detect physical key presses and releases with debounce filtering.
- **FR-1.3** [Must]: The firmware shall emit mapped HID reports within 20 ms of a stable key event.
- **FR-1.4** [Should]: The firmware shall persist user keymap configuration in non-volatile storage.

### 4.2 Non-Functional Requirements

- **NFR-1.1** [Must]: End-to-end keypress-to-report latency shall not exceed 20 ms during normal operation.
- **NFR-1.2** [Must]: The firmware shall recover cleanly from host USB disconnect and reconnect events.
```