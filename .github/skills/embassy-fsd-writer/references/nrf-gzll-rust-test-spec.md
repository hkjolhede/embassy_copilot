# nrf-gzll Rust Test Specification

This reference defines reusable tests for embedded Rust firmware using the
`nrf-gzll` crate — a safe, async Embassy-integrated driver for Nordic's
**Gazell Link Layer (GZLL)** and the optional **Gazell Pairing (GZP)** layer
on nRF52-series MCUs.

Use these tests when the project includes:
- Gazell Host or Device roles
- ACK payload exchange
- Pipe-based addressing and routing
- GZP dynamic pairing (optional `gzp-crypt` feature)
- Encrypted or plaintext data over GZP
- Recovery from TX failure or channel loss

## 1. Coverage Areas

- Initialization and singleton constraints
- Host/Device role configuration (typestate enforcement)
- Pipe addressing and pipe masks
- Basic transmit / receive path
- ACK payload round-trip
- TX failure and retry exhaustion handling
- RX FIFO backpressure (channel capacity)
- Channel table configuration
- FIFO flush discipline (disabled-only constraint)
- GZP pairing handshake
- GZP encrypted and plaintext packet exchange
- GZP key update and re-pairing fallback
- Interrupt handler binding correctness
- Payload size boundary enforcement
- Concurrent pipe reception on Host

## 2. Functional Tests

### GZLL-001 — Host Initializes Successfully

**Objective:**  
Verify that `init_host` returns a `GzllHost<GzllDisabled>` without panicking.

**Preconditions:**  
- Three PPI channels are available and passed to `GzllPeripherals::new`.
- `init_host` has not been called before in this boot (singleton).

**Procedure:**  
1. Construct a `GzllPeripherals` with three distinct PPI channels.
2. Call `init_host(peripherals)`.
3. Observe return value and absence of panic.

**Expected Result:**  
A `GzllHost<GzllDisabled>` is returned. No panic or hard fault occurs.

---

### GZLL-002 — Device Initializes Successfully

**Objective:**  
Verify that `init_device` returns a `GzllDevice` without panicking.

**Preconditions:**  
- Three PPI channels are available.
- `init_device` has not been called before in this boot.

**Procedure:**  
1. Construct `GzllPeripherals`.
2. Call `init_device(peripherals)`.
3. Observe return value.

**Expected Result:**  
A `GzllDevice` is returned. No panic or hard fault occurs.

---

### GZLL-003 — Host Configuration Setters Accepted While Disabled

**Objective:**  
Verify that all configuration setters return `Ok` when called on a
`GzllHost<GzllDisabled>`.

**Preconditions:**  
- Host is in disabled state (returned directly from `init_host`).

**Procedure:**  
1. Call `set_base_address_0` and `set_base_address_1` with valid addresses.
2. Call `set_address_prefix_byte` for each enabled pipe.
3. Call `set_channel_table` with a valid non-empty channel array.
4. Call `set_datarate`, `set_tx_power`, `set_timeslot_period`,
   `set_timeslots_per_channel`, `set_sync_lifetime`.
5. Call `set_rx_pipes_enabled` matching the `pipes-N` compile feature in use.
6. Assert all return `Ok(())`.

**Expected Result:**  
All setters accept valid values and return `Ok` while the stack is disabled.

---

### GZLL-004 — Configuration Rejected While Enabled

**Objective:**  
Verify that configuration setters return an error when called after `enabled()`.

**Preconditions:**  
- `GzllHost<GzllDisabled>` is available.

**Procedure:**  
1. Call `host.enabled()` to obtain `GzllHost<GzllEnabled>`.

**Note:**  
Because of typestate, the Rust type system prevents calling configuration
setters on `GzllHost<GzllEnabled>` at compile time rather than at runtime.
This test confirms the API contract by attempting to call a setter on the
enabled handle — it must **not compile**.

**Expected Result:**  
Code that calls a configuration setter on `GzllHost<GzllEnabled>` fails to
compile. No runtime check needed.

---

### GZLL-005 — Device Sends Packet and Receives ACK

**Objective:**  
Verify that a Device can send a data packet to a Host and receive an implicit
ACK.

**Preconditions:**  
- One board running Host firmware (`ack_payload_host` or equivalent).
- One board running Device firmware.
- Both boards configured with matching addresses and channel tables.
- Pipe 0 is enabled on both sides.

**Procedure:**  
1. Start Host (listening).
2. Call `device.send(0, &payload, &mut ack_buf).await`.
3. Observe return value.

**Expected Result:**  
`send` returns `Ok(None)` (ACK received, no ACK payload queued by Host) or
`Ok(Some(&mut [..]))` (ACK payload present). No `GzllError::TxFailed`.

---

### GZLL-006 — Host Receives Packet on Correct Pipe

**Objective:**  
Verify that `host.recv` correctly returns the payload and `RecvMeta` matching
the sending pipe.

**Preconditions:**  
- Host and Device configured with matching addresses on pipe 0.
- Host is in `GzllEnabled` state.

**Procedure:**  
1. Device calls `send(0, b"hello", &mut ack_buf).await`.
2. Host calls `recv(&mut buf).await`.
3. Inspect returned slice content and `RecvMeta.pipe`.

**Expected Result:**  
Returned buffer content matches the sent payload. `meta.pipe == 0`.
`meta.rssi` is a plausible negative dBm value.

---

### GZLL-007 — ACK Payload Round-Trip

**Objective:**  
Verify that a Host-enqueued ACK payload is delivered to the Device in the same
send call.

**Preconditions:**  
- Host and Device configured with matching addresses.
- Host is enabled.

**Procedure:**  
1. Host calls `host.send(0, b"ack-data")` *before* the next Device transmission arrives.
2. Device calls `send(0, &payload, &mut ack_buf).await`.
3. Inspect Device return value.

**Expected Result:**  
Device `send` returns `Ok(Some(&mut ack_buf[..n]))` where the slice contains
`b"ack-data"`.

---

### GZLL-008 — TX Failure Returned After Max Attempts Exhausted

**Objective:**  
Verify that `GzllDevice::send` returns `Err(GzllError::TxFailed)` when no Host
is reachable within `max_tx_attempts`.

**Preconditions:**  
- No Host is running or Host is powered off.
- Device's `max_tx_attempts` is reduced to a small value (e.g. 10) via
  `device.set_max_tx_attempts(10)`.

**Procedure:**  
1. Call `device.send(0, b"ping", &mut ack_buf).await`.
2. Observe return value.

**Expected Result:**  
Returns `Err(GzllError::TxFailed)` within a reasonable time proportional to
the attempt count. No panic or hang.

---

### GZLL-009 — Payload Size Limit Enforced

**Objective:**  
Verify that payloads exceeding `MAX_PAYLOAD` (32 bytes) are rejected.

**Preconditions:**  
- Device is available.

**Procedure:**  
1. Attempt `device.send(0, &[0u8; 33], &mut ack_buf).await`.
2. Observe return value.

**Expected Result:**  
Returns `Err(GzllError::InvalidData)` or
`Err(GzllError::InternalError(NrfGzllError::GzllInvalidPayloadLength))`.
No transmission attempt occurs.

---

### GZLL-010 — FIFO Flush Accepted While Disabled, Rejected While Enabled

**Objective:**  
Verify that `flush_rx_fifo` and `flush_tx_fifo` are only available on a
disabled Host (typestate) and that flushing a disabled host returns `Ok`.

**Preconditions:**  
- `GzllHost<GzllDisabled>` is available.

**Procedure:**  
1. Call `host.flush_rx_fifo(0)` and `host.flush_tx_fifo(0)` — both must
   return `Ok`.
2. Enable the Host with `host.enabled()`.
3. Confirm that the flush methods are **not available** on
   `GzllHost<GzllEnabled>` (compile-time check).

**Expected Result:**  
Flush calls succeed on disabled Host. Calling flush on enabled Host does not
compile.

---

### GZLL-011 — Host Receives on Multiple Pipes

**Objective:**  
Verify that the Host can correctly receive packets from different Devices on
different pipes within a single `recv` call loop.

**Preconditions:**  
- Firmware compiled with `pipes3` (or higher).
- Three Devices configured on pipes 0, 1, 2 respectively.
- Host has all three pipes enabled via `set_rx_pipes_enabled(0b00000111)`.

**Procedure:**  
1. Each Device sends one packet on its respective pipe.
2. Host calls `recv().await` three times.
3. Record `meta.pipe` for each received packet.

**Expected Result:**  
Packets are attributed to the correct pipe. All three packets are received
without data loss. Order may vary.

---

### GZLL-012 — RX FIFO Backpressure Handling

**Objective:**  
Verify behavior when the internal RX signal channel capacity (depth 4 per pipe)
is exceeded by a fast-transmitting Device.

**Preconditions:**  
- Host is not calling `recv` (simulated processing delay).
- Device transmits more than 4 packets rapidly.

**Procedure:**  
1. Artificially delay or block the Host's `recv` call.
2. Device sends 6 rapid consecutive packets on the same pipe.
3. Resume Host `recv` calls.
4. Count successfully delivered packets.

**Expected Result:**  
At most 4 packets are delivered; excess packets are dropped without crash or
undefined state. A `defmt` error log entry is emitted for each dropped packet
(channel overflow). The Host and Device both remain operational.

---

### GZLL-013 — Channel Table Applied Correctly

**Objective:**  
Verify that `set_channel_table` is accepted and the configured channel set is
returned by `get_channel_table`.

**Preconditions:**  
- Host or Device in disabled state.

**Procedure:**  
1. Call `set_channel_table(&[10, 30, 50, 70])`.
2. Call `get_channel_table(&mut vec)`.
3. Compare returned entries.

**Expected Result:**  
Returned entries match input exactly. `get_channel_table_size()` returns 4.

---

### GZLL-014 — Interrupt Handler Binding Compiles and Links

**Objective:**  
Verify that the required interrupt binding compiles and that all three required
interrupts are bound with the correct handlers.

**Preconditions:**  
- Embassy and `nrf-gzll` dependencies are correctly configured.

**Procedure:**  
1. Include the following in the firmware binary:
   ```rust
   bind_interrupts!(struct Irqs {
       EGU2_SWI2 => nrf_gzll::LowPriorityInterruptHandler;
       RADIO     => nrf_gzll::HighPrioInterruptHandler;
       TIMER1    => nrf_gzll::HighPrioInterruptHandler;
   });
   ```
2. Build the firmware.
3. Flash and observe boot.

**Expected Result:**  
Firmware compiles, links, and boots without a hard fault. GZLL operations work
after binding. Using a different timer feature (e.g. `timer2`) requires the
binding to reference `TIMER2` instead; a mismatch fails at link time.

---

## 3. GZP Pairing Tests

### GZLL-GZP-001 — GZP Pairing Handshake Completes

**Objective:**  
Verify that a GZP Device successfully completes a pairing exchange with a GZP
Host.

**Preconditions:**  
- Both boards compiled with `gzp-crypt` feature and `pipes3` or higher.
- Both boards use matching `GzpConfig::pairing_address` and
  `GzpConfig::validation_id`.
- Host is started in pairing mode.

**Procedure:**  
1. Start `GzpHost` in enabled + pairing state
   (`host.enable_pairing().await` or `process()` accepting
   `GzpProcessResult::PairingRequest`).
2. Call `gzp_device.pair_with_host().await`.
3. Observe return value on Device.
4. On Host, call `host.answer_pairing_request(true)`.

**Expected Result:**  
`pair_with_host()` returns `Ok(())`. Both sides now share a system address and
session token. Subsequent encrypted sends succeed without re-pairing.

---

### GZLL-GZP-002 — GZP Encrypted Packet Delivered to Host

**Objective:**  
Verify that an encrypted payload sent by a GZP Device is received and correctly
decrypted by the Host.

**Preconditions:**  
- Pairing (GZLL-GZP-001) has been completed.

**Procedure:**  
1. Device calls `gzp_device.send_encrypted(b"secret").await`.
2. Host calls `gzp_host.process().await`.
3. Inspect `GzpProcessResult::EncryptedPacket { data, rssi }`.

**Expected Result:**  
`data` equals `b"secret"`. No `GzpError` is returned on either side.

---

### GZLL-GZP-003 — GZP Plaintext Packet Delivered via Non-Reserved Pipe

**Objective:**  
Verify that a GZP Device can send unencrypted data on a non-reserved pipe
(pipe ≥ 2) and the Host receives it as a `PlaintextPacket`.

**Preconditions:**  
- Firmware compiled with `pipes3` or higher.
- Pipes 0 and 1 are reserved for GZP; application uses pipe 2.

**Procedure:**  
1. Device calls `gzp_device.send_plaintext(2, b"plain", &mut ack).await`.
2. Host calls `process()`.
3. Inspect `GzpProcessResult::PlaintextPacket { pipe, data, .. }`.

**Expected Result:**  
`pipe == 2`. `data` equals `b"plain"`. No GZP error.

---

### GZLL-GZP-004 — GZP Re-Pairing Triggered on Invalid Session

**Objective:**  
Verify that a GZP Device automatically falls back to re-pairing when the Host
has lost its session state (e.g. after Host power cycle).

**Preconditions:**  
- Prior pairing was completed.
- Host is power-cycled or restarted in pairing mode, clearing stored session.

**Procedure:**  
1. Device attempts `send_encrypted(b"data").await`.
2. Host returns `GzpError::InvalidId` or `GzpError::InvalidIdResponse`.
3. Application layer catches the error and calls `pair_with_host().await`.
4. Retry `send_encrypted`.

**Expected Result:**  
Re-pairing succeeds. Subsequent encrypted send is received correctly by Host.

---

### GZLL-GZP-005 — GZP Pairing Request Rejected by Host

**Objective:**  
Verify that a Device receives a failure when the Host rejects a pairing
request.

**Preconditions:**  
- Host is running but configured to reject pairing
  (`answer_pairing_request(false)`).

**Procedure:**  
1. Device calls `pair_with_host().await`.
2. Host processes the pairing request and calls `answer_pairing_request(false)`.
3. Observe Device return value.

**Expected Result:**  
`pair_with_host()` returns a `GzpError` indicating failure (e.g.
`GzpError::InvalidIdResponse` or `GzpError::TimeoutError`). No panic.

---

## 4. Edge Cases

### EC-GZLL-100 — Singleton Panic on Double Init
Calling `init_host` or `init_device` a second time in the same boot must panic
(backed by `StaticCell`). Verify this is documented and enforced — it must not
silently return a second instance.

### EC-GZLL-101 — Invalid Pipe Index
Passing a pipe number ≥ `NUM_PIPES` (e.g. pipe 8 when compiled with `pipes3`)
must return `Err(GzllError::InternalError(NrfGzllError::GzllInvalidPipe))`.

### EC-GZLL-102 — Empty Channel Table Rejected
Calling `set_channel_table(&[])` must return an error. Verify that the radio
does not enter an undefined state.

### EC-GZLL-103 — Host ACK Payload FIFO Full
If the Host attempts to enqueue more ACK payloads on a pipe than the TX FIFO
capacity allows, `host.send(pipe, data)` must return
`Err(GzllError::InternalError(NrfGzllError::GzllAttemptedToAddToFullFifo))`.
Subsequent valid sends or receives must still work.

### EC-GZLL-104 — Disable During Active Operations
Calling `host.disabled().await` while packets are in flight must complete cleanly.
`DISABLE_SIGNAL` must fire and the returned `GzllHost<GzllDisabled>` must accept
configuration changes.

### EC-GZLL-105 — Mismatched Channel Tables Between Host and Device
If Host and Device use different channel tables, the Device should fail to sync
and `send` should eventually return `Err(GzllError::TxFailed)`. Verify that
correcting the channel table and re-enabling restores communication.

### EC-GZLL-106 — MaxPayload Boundary — Exact 32 Bytes
Send a payload of exactly 32 bytes. Verify it is transmitted and received
without truncation or error.

## 5. `embedded-test` Test Runner Notes

Tests involving radio communication require **two physical nRF52 boards** and
cannot run on a single device with `embedded-test`. Recommended split:

| Test Category | Runner |
|---|---|
| Init, typestate, config setters, error codes | `embedded-test` (single board) |
| Payload boundary, FIFO errors, singleton panic | `embedded-test` (single board) |
| TX/RX round-trip, ACK payload, multi-pipe | Two boards, hardware-in-loop |
| GZP pairing, encryption, re-pairing | Two boards, hardware-in-loop |

For single-board `embedded-test` tests, bind interrupts in the `#[init]`
function and configure a loopback or mock scenario where possible.

Recommended Cargo configuration:

```toml
# .cargo/config.toml
[target.thumbv7em-none-eabihf]
runner = "probe-rs run --chip nRF52840_xxAA"
```

```toml
# Cargo.toml
[dev-dependencies]
embedded-test = { version = "0.x", features = ["defmt"] }
defmt = "1"
```

Test module example (single-board, config validation):

```rust
#[cfg(test)]
#[embedded_test::tests]
mod tests {
    use nrf_gzll::{init_host, GzllPeripherals};

    #[init]
    fn setup() -> GzllPeripherals {
        // obtain PPI channels from Embassy peripherals split
    }

    #[test]
    fn host_init_does_not_panic(p: GzllPeripherals) {
        let _host = init_host(p);
    }
}
```

## 6. Acceptance Guidance

Include at least:
- one successful init test (Host or Device),
- one TX/RX round-trip with ACK confirmation,
- one `TxFailed` error path test,
- one payload boundary test (exact 32 bytes and 33-byte rejection),
- and — if GZP is enabled — one full pairing handshake test and one encrypted
  send/receive test

for any firmware project using `nrf-gzll`.
