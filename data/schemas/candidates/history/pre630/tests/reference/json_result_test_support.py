"""Strict JSON decoding and structural comparisons for supplied-data tests."""

import json


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def reject_constant(value):
    raise ValueError(f"non-JSON constant: {value}")


def decode(raw):
    return json.loads(raw.decode("utf-8"), object_pairs_hook=unique_object,
                      parse_constant=reject_constant)


def compare(actual, wanted, path="result"):
    # bool is a subclass of int in Python; plain equality would miss true/1.
    if type(actual) is not type(wanted):
        raise AssertionError(f"{path}: expected {type(wanted).__name__}, got {type(actual).__name__}")
    if isinstance(wanted, dict):
        if actual.keys() != wanted.keys():
            raise AssertionError(f"{path}: unexpected field set")
        for key, value in wanted.items():
            compare(actual[key], value, f"{path}.{key}")
    elif isinstance(wanted, list):
        if len(actual) != len(wanted):
            raise AssertionError(f"{path}: unexpected list length")
        for index, value in enumerate(wanted):
            compare(actual[index], value, f"{path}[{index}]")
    elif actual != wanted:
        raise AssertionError(f"{path}: expected {wanted!r}, got {actual!r}")
