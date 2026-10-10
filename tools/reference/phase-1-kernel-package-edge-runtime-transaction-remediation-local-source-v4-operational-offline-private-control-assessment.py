"""Assess bounded private control observations, never native effectiveness."""
from dataclasses import dataclass
import hashlib
import re

STATES = ('match', 'mismatch', 'pending', 'rejected')
MAX_PACKET_BYTES = 262144
MAX_PACKETS = 16

@dataclass(frozen=True)
class ControlObservation:
    control_id: str
    role: str
    before_raw: tuple
    after_raw: tuple
    baseline_state: str
    observed_state: str
    expected_state: str
    required_diagnostic_codes: tuple
    observed_diagnostic_codes: tuple

@dataclass(frozen=True)
class ControlAssessment:
    state: str
    raw_change_observed: object
    independent_literal_response_matches: bool
    private_control_effective: bool
    before_sha256: tuple
    after_sha256: tuple
    raw_artifact_retention_required: bool = True
    native_injection_effectiveness_proven: bool = False
    independence_verified: bool = False
    native_oracle_selected: bool = False
    native_conformance: bool = False
    runtime_authority: bool = False
    native_cases_run: int = 0
    native_proofs_added: int = 0

def _codes(values):
    if type(values) is not tuple or len(values) > 128:
        raise ValueError('bounded immutable diagnostic tuple required')
    for value in values:
        if type(value) is not str or re.fullmatch(r'[a-z][a-z0-9-]{0,127}', value) is None:
            raise ValueError('diagnostic code required')

def _raw(values):
    if type(values) is not tuple or not 1 <= len(values) <= MAX_PACKETS:
        raise ValueError('bounded explicit packet tuple required')
    for value in values:
        if value is not None and (type(value) is not bytes or len(value) > MAX_PACKET_BYTES):
            raise ValueError('bounded immutable raw bytes or unknown required')

def assess(observation):
    if type(observation) is not ControlObservation:
        raise ValueError('exact private control observation required')
    if type(observation.control_id) is not str or re.fullmatch(r'[a-z][a-z0-9-]{0,63}', observation.control_id) is None:
        raise ValueError('control identifier required')
    if type(observation.role) is not str or observation.role not in ('positive', 'negative'):
        raise ValueError('explicit positive or negative control required')
    for state in (observation.baseline_state, observation.observed_state, observation.expected_state):
        if type(state) is not str or state not in STATES:
            raise ValueError('closed private response state required')
    _raw(observation.before_raw)
    _raw(observation.after_raw)
    if len(observation.before_raw) != len(observation.after_raw):
        raise ValueError('explicit paired raw slots required')
    _codes(observation.required_diagnostic_codes)
    _codes(observation.observed_diagnostic_codes)
    known = all(value is not None for value in observation.before_raw + observation.after_raw)
    changed = observation.before_raw != observation.after_raw if known else None
    response = observation.observed_state == observation.expected_state and all(code in observation.observed_diagnostic_codes for code in observation.required_diagnostic_codes)
    positive = observation.role == 'positive' and observation.expected_state == 'match' and changed is False
    negative = observation.role == 'negative' and observation.expected_state != 'match' and bool(observation.required_diagnostic_codes) and changed is True
    effective = observation.baseline_state == 'match' and response and (positive or negative)
    state = 'effective-private-data-control' if effective else ('pending-raw-control-evidence' if not known else 'ineffective-private-data-control')
    digest = lambda values: tuple(None if value is None else hashlib.sha256(value).hexdigest() for value in values)
    return ControlAssessment(state, changed, response, effective, digest(observation.before_raw), digest(observation.after_raw))

if __name__ == '__main__':
    raise SystemExit('Import-only private control assessment; no injection, dispatch or native proof.')
