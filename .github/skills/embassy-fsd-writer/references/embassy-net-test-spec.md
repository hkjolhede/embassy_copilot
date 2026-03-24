# Embassy Net Test Specification

This reference defines reusable tests for projects using `embassy-net` or a
similar async networking stack in embedded Rust.

Use these tests when the project includes:
- `embassy-net`
- DHCP or static IP networking
- TCP/UDP client or server behavior
- DNS resolution
- periodic network publishing or command/control interfaces

## 1. Coverage Areas

- Link initialization
- IP configuration
- DNS resolution
- TCP/UDP communication
- reconnect behavior
- timeout handling
- packet loss resilience
- bounded buffering under network disruption

## 2. Functional Tests

### NET-001 — Network Interface Initializes Successfully

**Objective:**  
Verify that the network stack initializes and reaches a usable state.

**Preconditions:**  
- Physical network medium is available.
- Credentials or static configuration are valid.

**Procedure:**  
1. Boot the device.
2. Observe network initialization logs or status indicators.
3. Verify that the network stack transitions to ready state.

**Expected Result:**  
The device reaches a documented ready state without panic or indefinite stall.

---

### NET-002 — IP Configuration Completes Correctly

**Objective:**  
Verify successful acquisition or application of IP configuration.

**Preconditions:**  
- DHCP or static IP configuration is defined.

**Procedure:**  
1. Start the device on the target network.
2. Observe assigned IP settings.
3. Confirm address, mask, gateway, and DNS settings match expectations.

**Expected Result:**  
The device obtains or applies valid IP configuration and enters normal operation.

---

### NET-003 — TCP Session Establishes and Exchanges Data

**Objective:**  
Verify that a TCP client or server path functions correctly.

**Preconditions:**  
- A reachable peer is available.

**Procedure:**  
1. Initiate or accept a TCP connection.
2. Exchange representative application payloads.
3. Validate payload integrity and expected protocol sequencing.

**Expected Result:**  
The TCP session succeeds and data integrity is maintained.

---

### NET-004 — UDP Transmission and Reception Work Correctly

**Objective:**  
Verify correct UDP send/receive behavior.

**Preconditions:**  
- UDP is part of the project architecture.

**Procedure:**  
1. Send representative UDP datagrams.
2. Receive reply or inbound datagrams.
3. Validate port usage, payload integrity, and application handling.

**Expected Result:**  
Expected UDP communication succeeds without corruption or misrouting.

---

### NET-005 — DNS Resolution Succeeds

**Objective:**  
Verify that hostname resolution works when the design depends on DNS.

**Preconditions:**  
- DNS server is reachable.
- At least one hostname target is configured.

**Procedure:**  
1. Request resolution of a known hostname.
2. Attempt communication to the resolved endpoint.
3. Repeat after a network restart if applicable.

**Expected Result:**  
The device resolves hostnames successfully and uses the result correctly.

---

### NET-006 — Link Drop Recovery Works

**Objective:**  
Verify recovery from temporary network unavailability.

**Preconditions:**  
- Device is in steady-state networked operation.

**Procedure:**  
1. Interrupt network connectivity.
2. Maintain outage long enough to trigger reconnect logic.
3. Restore connectivity.
4. Observe reconnection and resumed traffic.

**Expected Result:**  
The firmware recovers according to the documented retry and reconnect strategy.

---

### NET-007 — Network Timeout Does Not Deadlock Application

**Objective:**  
Verify that failed network operations time out cleanly.

**Preconditions:**  
- At least one network path has a timeout policy.

**Procedure:**  
1. Attempt a connection or transaction against an unreachable peer.
2. Wait for timeout behavior.
3. Repeat normal operations afterward.

**Expected Result:**  
The operation times out cleanly, resources are released, and the application remains responsive.

## 3. Edge Cases

### EC-NET-100 — Boot Without Network
Start the device with no network present and verify graceful degraded behavior.

### EC-NET-101 — Delayed DHCP
Delay DHCP response and verify the system does not panic or lock up.

### EC-NET-102 — Packet Loss
Inject packet loss and verify retry or tolerance behavior matches the design.

### EC-NET-103 — Repeated Link Flap
Toggle link availability repeatedly and verify no progressive degradation occurs.

### EC-NET-104 — Peer Reset Mid-Transaction
Reset the remote peer during transfer and verify local recovery behavior.

## 4. Acceptance Guidance

Include at least:
- initialization,
- IP configuration,
- one successful data-path test,
- one timeout test,
- and one reconnect test

for any networked Embassy project.