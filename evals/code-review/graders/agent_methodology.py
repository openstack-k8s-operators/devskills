import re


def get_assert(output, context):
    text = output
    score = 0.0
    checks = {
        "has_critical": bool(re.search(r'critical', text, re.IGNORECASE)),
        "has_major": bool(re.search(r'major', text, re.IGNORECASE)),
        "has_line_refs": bool(re.search(r'line\s*\d+|:\d+', text)),
        "has_verdict": bool(re.search(r'REQUEST CHANGES|APPROVE', text)),
    }
    matched = [k for k, v in checks.items() if v]
    score = len(matched) / len(checks)

    return {
        "pass": score >= 0.75,
        "score": score,
        "reason": f"Score {score:.2f}/1.0 — matched: {', '.join(matched) or 'none'}",  # noqa E501
    }
