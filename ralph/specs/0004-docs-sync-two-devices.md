# Spec 0004 — Sync docs to the two-device reality

Status: TODO
Priority: 4
Depends on: 0001 (the sequencer device must exist to be documented).

## Context
The repo now ships **two** devices (generator + sequencer) sharing one v3 bridge,
but the top-level docs still describe the single-device world:
- `docs/osc_contract.md` — the authoritative OSC address list.
- `PLAN.md` — project plan / architecture.
The sequencer adds **no new OSC** (its clock + templates are entirely Max-side),
so the risk here is *drift*, not new endpoints: the contract should (a) stay an
exact match for what the Python service actually dispatches, and (b) acknowledge
the second device + the internal (non-OSC) Max message vocabulary.

## Requirements
1. `docs/osc_contract.md` and `PLAN.md` describe the two-device architecture.
2. The OSC contract is provably in sync with the Python service — no address in
   the doc that Python ignores, none handled by Python that the doc omits.
3. The sequencer's internal Max messages are documented as NOT part of the OSC
   contract (mirroring how the generator's `notes`/`stop` are already scoped out).

## Tasks
- Update `docs/osc_contract.md`: note the sequencer shares the same v3 OSC (no new
  addresses); add/confirm a clearly-labelled list of the **internal** Max message
  vocabulary that is out of scope of the OSC contract — inbound to the bridge
  (`play beat rhythm template length seed register voiceleading triadsonly
  colormajor colorminor color7th panic testparse` + the shared `chord send ping
  reload model spice session reset_session notein`) and outbound from it
  (`status output error chord notes stop playoff rhythmname model session`).
- Update `PLAN.md` to mention `chord_sequencer_device` and the shared bridge.
- Add a tiny checker (script or documented one-liner) proving contract⇄Python
  parity, and record how to run it.

## Acceptance Criteria
- [ ] `docs/osc_contract.md` references the sequencer and states it uses the same
      v3 OSC with **no new addresses**.
- [ ] **No OSC drift:** the set of OSC addresses listed in `docs/osc_contract.md`
      equals the set the Python service dispatches (cross-checked against
      `python/src/config.py` + `python/src/osc_service.py`). Show the check and its
      passing output. Reconcile any mismatch found (fix whichever side is wrong).
- [ ] The internal (non-OSC) Max message vocabulary is documented and explicitly
      labelled as outside the OSC contract.
- [ ] `PLAN.md` names `chord_sequencer_device` / the two-device layout.
- [ ] Sanity unchanged: `cd max && npm test` exits 0 and
      `cd python && /opt/anaconda3/bin/python3 -m pytest -q` passes (docs-only
      change must not break anything).
- [ ] Committed on `ralph/build`; branch pushed.

## Not in scope
- No behavior/protocol changes — this spec is docs + a consistency check only. If
  the checker reveals a genuine code/doc mismatch, fix the smaller/wrong side and
  note it; do not redesign the protocol.

Print `<promise>DONE</promise>` only when every checkbox is verified.
