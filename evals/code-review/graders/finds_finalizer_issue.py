import re


def get_assert(output, context):
    text = output.lower()
    score = 0.0
    checks = {
        "finalizer": r'finalizer|deletion.?timestamp|cleanup|orphan',
        "critical_severity": r'critical|must fix|block',
        "observed_generation": r'observed.?generation|generation',
        "error_wrapping": r'error.?wrap|%w|unwrap|bare.*return.*err',
    }
    matched = []
    for name, pattern in checks.items():
        if re.search(pattern, text):
            score += 0.25
            matched.append(name)

    return {
        "pass": score >= 0.5,
        "score": score,
        "reason": f"Score {score:.1f}/1.0 — matched: {', '.join(matched) or 'none'}",  # noqa E501
    }
