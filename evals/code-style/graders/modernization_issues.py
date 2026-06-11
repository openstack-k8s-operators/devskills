import re


def get_assert(output, context):
    text = output.lower()
    score = 0.0
    checks = {
        "slice_decl": r'slice|var\b.*\[\]|declaration|redundant.*type',
        "map_decl": r'map|make\b|literal|composite',
        "string_concat": r'concat|builder|strings\.join|strings\.builder|inefficien|\+.*loop',
        "naming": r'naming|getter|get.*prefix|accessor|export',
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
