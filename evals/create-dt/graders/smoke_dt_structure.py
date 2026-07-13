import re


def get_assert(output, context):
    text = output.lower()
    checks = {
        "has_kustomize": r'kind:\s*component|kustomization\.yaml',
        "has_automation_vars": r'automation/vars|stages:',
        "has_stage_ordering": r'nncp|network.*configuration|control.plane|edpm',
        "has_dt_path": r'dt/|examples/dt/',
        "has_values": r'values\.yaml|service.values\.yaml',
    }
    matched = []
    for name, pattern in checks.items():
        if re.search(pattern, text):
            matched.append(name)
    score = len(matched) / len(checks)
    return {
        "pass": score >= 0.4,
        "score": score,
        "reason": f"Score {score:.1f}/1.0 — matched: {', '.join(matched) or 'none'}",
    }
