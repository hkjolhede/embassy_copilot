# USB HID Rust Test Specification

This reference defines reusable tests for embedded Rust firmware exposing a USB
HID interface, typically implemented with `embassy-usb`.

Use these tests when the project includes:
- `embassy-usb`
- HID keyboard, mouse, consumer control, or custom HID reports
- host-facing USB device enumeration
- report generation from application events

## 1. Coverage Areas

- USB enumeration
- HID descriptor validity
- Input report delivery
- Host reconnect recovery
- Idle/quiet behavior
- Report formatting correctness
- Latency from event to host-visible report
- Stuck-key / stale-state prevention

## 2. Functional Tests

### HID-001 — Device Enumerates as Expected

**Objective:**  
Verify that the firmware enumerates successfully as the documented USB HID device.

**Preconditions:**  
- Firmware is flashed and device is connected to a compatible host.

**Procedure:**  
1. Connect the device to a host system.
2. Observe enumeration on each supported host OS.
3. Verify VID/PID, class, subclass, protocol, and HID interface presence.

**Expected Result:**  
The device enumerates successfully and presents the expected HID interface.

---

### HID-002 — HID Reports Match Declared Descriptor

**Objective:**  
Verify that generated reports conform to the HID report descriptor.

**Preconditions:**  
- Report format is documented.
- Host-side capture or decode tooling is available.

**Procedure:**  
1. Trigger representative user/application events.
2. Capture outbound HID reports.
3. Compare field size, ordering, and content to the descriptor.

**Expected Result:**  
All reports conform to the documented descriptor format.

---

### HID-003 — Input Event Produces Correct Host Action

**Objective:**  
Verify that a firmware-generated HID event produces the expected result on the host.

**Preconditions:**  
- Host-side application can receive HID input.

**Procedure:**  
1. Trigger a known input event.
2. Observe the resulting host behavior.
3. Repeat for each supported input type.

**Expected Result:**  
Each event produces the correct host-visible action.

---

### HID-004 — No Stuck Key After Release

**Objective:**  
Verify that key release state is transmitted correctly and no stale pressed state remains.

**Preconditions:**  
- Keyboard-style HID reports are implemented.

**Procedure:**  
1. Trigger a press event.
2. Trigger the corresponding release event.
3. Verify host behavior and report stream.

**Expected Result:**  
The host does not observe a stuck key or repeated unintended input.

---

### HID-005 — Host Disconnect and Reconnect Recovery

**Objective:**  
Verify that the device recovers from cable disconnect or host reset.

**Preconditions:**  
- Device is operating normally.

**Procedure:**  
1. Disconnect the USB cable or simulate host reset.
2. Reconnect after a short interval.
3. Re-exercise normal HID behavior.

**Expected Result:**  
The device re-enumerates cleanly and resumes normal HID operation.

---

### HID-006 — Event-to-Report Latency Meets Budget

**Objective:**  
Verify that the time from internal event generation to host-visible HID report
meets the documented latency target.

**Preconditions:**  
- A latency budget is defined.
- Timing capture is available.

**Procedure:**  
1. Trigger a deterministic firmware event.
2. Measure the time until the host receives or acts on the HID report.
3. Repeat across multiple trials.

**Expected Result:**  
Latency remains within the documented limit under normal operating conditions.

## 3. Edge Cases

### EC-HID-100 — Rapid Repeated Input
Send repeated input events near the maximum expected rate and verify no malformed
reports or dropped release events.

### EC-HID-101 — Unsupported Host Behavior
Test against multiple host platforms and document any host-specific deviations.

### EC-HID-102 — Idle Period Stability
Leave the device connected and idle for an extended period, then verify the next
input event succeeds immediately.

### EC-HID-103 — Partial Initialization Window
Verify no HID reports are emitted before USB initialization is complete.

## 4. Acceptance Guidance

Include at least:
- enumeration,
- descriptor/report validation,
- reconnect recovery,
- latency,
- and stale-state prevention

for any Embassy USB HID project.