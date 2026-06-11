import re


def get_assert(output, context):
    text = output.lower()
    score = 0.0
    checks = {
        "error_casing": r'capital|uppercase|lower|should not start|error string',
        "error_wrapping": r'wrap|%w|errorf.*%w|unwrap',
        "error_handling": r'discard|ignor|unhandled|must handle|check.*err',
        "else_after_return": r'else|unnecessary|indent|simplif',
    }
    matched = []
    for name, pattern in checks.items():
        if re.search(pattern, text):
            score += 0.25
            matched.append(name)

    return {
        "pass": score >= 0.5,
        "score": score,
        "reason": f"Score {score:.1f}/1.0 — matched: {', '.join(matched) or 'none'}",
    }
