# BLE Rust Test Specification

This reference defines reusable tests for embedded Rust firmware implementing
Bluetooth Low Energy behavior, including advertising, GATT services,
characteristic read/write, notification paths, and reconnect handling.

Use these tests when the project includes:
- BLE peripheral behavior
- GATT services and characteristics
- notifications or indications
- command/control or telemetry over BLE
- bonding/pairing where applicable

## 1. Coverage Areas

- advertising and discovery
- connection establishment
- GATT attribute access
- notifications/indications
- MTU-sensitive payload handling
- reconnect behavior
- malformed or out-of-order command handling
- optional pairing/bonding behavior

## 2. Functional Tests

### BLE-001 — Device Advertises as Documented

**Objective:**  
Verify that the device advertises using the documented name, intervals, and advertised services.

**Preconditions:**  
- BLE is enabled and the device is in an advertisable state.

**Procedure:**  
1. Power on the device.
2. Scan from a BLE client.
3. Record advertisement name, service UUIDs, and visibility timing.

**Expected Result:**  
The device is discoverable and advertisement content matches the design.

---

### BLE-002 — Central Connects Successfully

**Objective:**  
Verify that a supported BLE client can establish a connection.

**Preconditions:**  
- Device is advertising.
- A supported central device is available.

**Procedure:**  
1. Initiate connection from the central device.
2. Observe connection establishment.
3. Maintain the connection long enough to perform basic operations.

**Expected Result:**  
Connection succeeds and remains stable under normal conditions.

---

### BLE-003 — Characteristic Read Returns Valid Data

**Objective:**  
Verify correct read behavior for readable characteristics.

**Preconditions:**  
- At least one readable characteristic exists.

**Procedure:**  
1. Connect to the device.
2. Read target characteristic values.
3. Validate payload format, units, and value freshness.

**Expected Result:**  
Readable characteristics return correctly formatted and valid data.

---

### BLE-004 — Characteristic Write Triggers Expected Action

**Objective:**  
Verify that writing to a writable characteristic causes the documented firmware behavior.

**Preconditions:**  
- At least one writable control or configuration characteristic exists.

**Procedure:**  
1. Connect to the device.
2. Write a valid command or configuration value.
3. Observe firmware state and resulting behavior.

**Expected Result:**  
The write is accepted and the expected action occurs.

---

### BLE-005 — Notification Path Works Correctly

**Objective:**  
Verify that notifications or indications are emitted correctly when enabled.

**Preconditions:**  
- A notifiable characteristic exists.

**Procedure:**  
1. Connect to the device.
2. Enable notifications or indications.
3. Trigger a state change or periodic update.
4. Capture notification payloads.

**Expected Result:**  
The client receives correctly formatted updates with expected timing and sequencing.

---

### BLE-006 — Disconnect and Reconnect Recovery Works

**Objective:**  
Verify behavior after a client disconnects and reconnects.

**Preconditions:**  
- Device is operating normally.

**Procedure:**  
1. Connect and perform a representative interaction.
2. Disconnect the central.
3. Reconnect and repeat the interaction.

**Expected Result:**  
The device returns to the expected advertisable/connectable state and resumes normal operation.

---

### BLE-007 — Invalid Write Is Rejected Safely

**Objective:**  
Verify safe handling of malformed, out-of-range, or unsupported writes.

**Preconditions:**  
- Writable characteristic exists.

**Procedure:**  
1. Send malformed, oversized, or semantically invalid writes.
2. Observe firmware behavior and error responses if available.
3. Confirm subsequent valid commands still work.

**Expected Result:**  
Invalid input is rejected safely without crash, corruption, or undefined state.

## 3. Edge Cases

### EC-BLE-100 — Large Payload Near MTU Limit
Send payloads near the supported MTU boundary and verify correct handling.

### EC-BLE-101 — Rapid Connect/Disconnect Cycle
Repeat connect/disconnect cycles and verify no progressive instability appears.

### EC-BLE-102 — Notification Burst
Trigger rapid consecutive notifications and verify flow control behavior.

### EC-BLE-103 — Client Disappears Mid-Operation
Drop the client connection unexpectedly during an active exchange and verify cleanup.

### EC-BLE-104 — Multiple Scan Environments
Verify discoverability and connection reliability in RF-noisy environments.

## 4. Acceptance Guidance

Include at least:
- advertising,
- connection,
- one read/write test,
- one notification test if applicable,
- and one reconnect/error-handling test

for any BLE-enabled Embassy/Rust project.