import re


def get_assert(output, context):
    text = output.lower()
    checks = {
        "has_analysis": r"step\s*2|analy|existing.*hci|similar|identical|base.*on|review.*topolog|survey|model.*on.*hci",
        "has_strategy": r"step\s*3|strateg|approach|pros|cons|proposal|hitl|approval|plan\s*file|naming.*convention|naming.*sequence",
        "has_generation": r"step\s*4|generat|kustomiz|file.*tree|files.*written|files.*creat|files\s+created|scaffolded",
        "has_stages": r"nncp|network.config|control.plane|edpm|pre-ceph|post-ceph|stages?:|two.phase",
    }
    matched = []
    score = 0.0
    for name, pattern in checks.items():
        if re.search(pattern, text):
            score += 0.25
            matched.append(name)

    return {
        "pass": score >= 0.75,
        "score": score,
        "reason": f"Score {score:.1f}/1.0 — matched: {', '.join(matched) or 'none'}",
    }
