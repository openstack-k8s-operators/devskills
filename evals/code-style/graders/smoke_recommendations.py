import re


def get_assert(output, context):
    text = output.lower()
    score = 0.0
    indicators = [
        r'style|convention|moderniz|recommend|suggestion|improve|issue|fix',
        r'declaration|var\b|slice|make\b|capital|uppercase|lower',
        r'concat|builder|strings\.join|inefficien|discard|ignor',
        r'naming|getter|prefix|accessor|wrap|%w',
        r'sprintf|fmt\.|error|handling',
    ]
    for pattern in indicators:
        if re.search(pattern, text):
            score += 0.2

    matched = int(score / 0.2)
    return {
        "pass": score >= 0.4,
        "score": score,
        "reason": f"Score {score:.1f}/1.0 — matched {matched}/5 indicator groups",
    }
