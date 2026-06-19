import re


def get_assert(output, context):
    text = output.lower()
    score = 0.0
    checks = {
        "has_review": r'review|code review|review summary|review result',
        "has_severity": r'critical|major|minor',
        "has_verdict": r'request changes|approve',
        "has_findings": r'finding|issue|violation|problem|bug',
        "has_references": r'line\s*\d+|:\d+|\bline\b',
    }
    matched = []
    for name, pattern in checks.items():
        if re.search(pattern, text):
            score += 0.2
            matched.append(name)

    return {
        "pass": score >= 0.4,
        "score": score,
        "reason": f"Score {score:.1f}/1.0 — matched: {', '.join(matched) or 'none'}",  # noqa E501
    }
