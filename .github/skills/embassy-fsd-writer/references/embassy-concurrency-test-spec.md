# Embassy Concurrency Test Specification

This reference defines reusable verification cases for embedded Rust firmware
built with the Embassy async runtime. It focuses on task scheduling, signaling,
bounded queues, shared-resource coordination, fairness, starvation prevention,
and async recovery behavior.

Use these tests when the project includes:
- `#[embassy_executor::task]`
- `Spawner`
- `embassy_sync`
- `Signal`, `Channel`, `Mutex`, `PubSubChannel`
- interrupt-to-task handoff
- multi-task producer/consumer patterns

## 1. Coverage Areas

- Task startup ordering
- Cooperative scheduling behavior
- Producer/consumer correctness
- Queue backpressure and overflow handling
- Signal delivery and wakeup correctness
- Shared resource serialization
- Timeout and cancellation behavior
- Deadlock and starvation resistance
- Recovery after subsystem fault or restart

## 2. Functional Tests

### CONC-001 — Task Startup Completes Successfully

**Objective:**  
Verify that all expected Embassy tasks are spawned and reach their ready state.

**Preconditions:**  
- Firmware is built with all intended runtime features enabled.
- Logging or status instrumentation is available.

**Procedure:**  
1. Power on or reset the device.
2. Observe initialization logs or status indicators.
3. Confirm each required task reports startup completion or equivalent readiness.
4. Verify no task panics during initialization.

**Expected Result:**  
All required tasks start successfully and the system enters steady-state operation.

**Traceability Guidance:**  
Map to task model and initialization FRs.

---

### CONC-002 — Periodic Task Maintains Expected Cadence

**Objective:**  
Verify that a periodic Embassy task runs within its defined timing budget.

**Preconditions:**  
- A periodic task exists using `Timer::after` or `Ticker`.
- Timing can be observed via logs, GPIO toggling, or counters.

**Procedure:**  
1. Start the device in normal operation.
2. Observe 100 consecutive task activations.
3. Measure period and jitter.
4. Compare against documented timing targets.

**Expected Result:**  
Observed execution cadence remains within the allowed jitter and period limits.

**Traceability Guidance:**  
Map to timing, scheduling, and latency NFRs.

---

### CONC-003 — Channel Producer/Consumer Preserves Ordering

**Objective:**  
Verify that messages sent through an Embassy channel are received in the expected order.

**Preconditions:**  
- A producer task and a consumer task communicate through a bounded channel.

**Procedure:**  
1. Inject a deterministic sequence of messages from the producer.
2. Record the message order observed by the consumer.
3. Repeat under normal and elevated task load.

**Expected Result:**  
The consumer receives messages in the documented order with no corruption or duplication.

**Traceability Guidance:**  
Map to inter-task communication FRs.

---

### CONC-004 — Full Queue Backpressure Is Handled Safely

**Objective:**  
Verify correct behavior when a bounded queue reaches capacity.

**Preconditions:**  
- The firmware uses a bounded queue or channel.
- Expected full-queue behavior is defined: block, drop oldest, drop newest, or error.

**Procedure:**  
1. Cause the producer to outpace the consumer.
2. Sustain the overload condition long enough to fill the queue.
3. Observe system behavior and logs.
4. Verify that the implementation follows the documented queue policy.

**Expected Result:**  
Queue saturation is handled without panic, memory corruption, or undocumented loss behavior.

**Traceability Guidance:**  
Map to buffering, overload, and resilience requirements.

---

### CONC-005 — Signal Wakes Waiting Task

**Objective:**  
Verify that a task blocked waiting on a signal is woken correctly.

**Preconditions:**  
- The firmware uses `Signal` or equivalent wakeup primitive.

**Procedure:**  
1. Place the consumer task in a waiting state.
2. Trigger the corresponding signal from another task or interrupt path.
3. Measure wakeup and response behavior.

**Expected Result:**  
The waiting task resumes and processes the signal exactly once per documented event.

**Traceability Guidance:**  
Map to event-handling FRs.

---

### CONC-006 — Shared Resource Access Is Serialized

**Objective:**  
Verify that concurrent tasks do not corrupt a shared peripheral or memory-backed resource.

**Preconditions:**  
- Two or more tasks share access through a `Mutex`, critical section, or broker task.

**Procedure:**  
1. Drive overlapping access attempts from multiple tasks.
2. Observe output, logs, and resource state.
3. Repeat under high-frequency access conditions.

**Expected Result:**  
Resource access remains serialized per design; no corruption, partial transactions, or race symptoms occur.

**Traceability Guidance:**  
Map to data integrity and concurrency architecture requirements.

---

### CONC-007 — Cancellation or Timeout Leaves System Consistent

**Objective:**  
Verify that timeout or task cancellation does not leave shared state inconsistent.

**Preconditions:**  
- One async operation can time out or abort.

**Procedure:**  
1. Start a long-running async operation.
2. Trigger timeout, abort, or withdrawal of the awaited condition.
3. Inspect resource state and subsequent operation behavior.

**Expected Result:**  
The timed-out or aborted operation releases resources correctly and future operations proceed normally.

**Traceability Guidance:**  
Map to timeout, retry, and error-recovery requirements.

---

### CONC-008 — Consumer Restart Does Not Break Producer Path

**Objective:**  
Verify recovery when one task restarts or is reinitialized.

**Preconditions:**  
- The design allows subsystem restart, reinit, or soft recovery.

**Procedure:**  
1. Induce a recoverable fault in a consumer or service task.
2. Allow the subsystem to restart or reinitialize.
3. Resume normal producer traffic.

**Expected Result:**  
The producer path remains stable, recovery completes, and the system returns to normal operation without reboot unless documented.

**Traceability Guidance:**  
Map to resilience and self-recovery requirements.

## 3. Edge Cases

### EC-CONC-100 — Burst Traffic
Generate a short burst of events at the maximum expected rate and verify that
no undocumented message loss or lockup occurs.

### EC-CONC-101 — Slow Consumer
Artificially slow the consumer path and verify documented backpressure handling.

### EC-CONC-102 — Simultaneous Signals
Trigger multiple wakeup events close together and verify correct coalescing or
counting semantics.

### EC-CONC-103 — Repeated Timeout Cycle
Force repeated timeout conditions and verify the system does not leak resources
or degrade over time.

### EC-CONC-104 — Startup Race Window
Exercise reset/power-on repeatedly to expose task-start ordering races.

## 4. Acceptance Guidance

Include at least:
- one startup test,
- one queue/backpressure test,
- one shared-resource serialization test,
- one timeout/recovery test

for any medium-or-higher complexity Embassy project.