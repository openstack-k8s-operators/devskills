import re


def get_assert(output, context):
    text = output
    checks = {
        "has_analysis": bool(re.search(
            r'step\s*2|analysis|existing.*topolog', text, re.IGNORECASE
        )),
        "has_strategy": bool(re.search(
            r'step\s*3|strateg|approach|pros|cons', text, re.IGNORECASE
        )),
        "has_generation": bool(re.search(
            r'step\s*4|generat|kustomiz|file.*tree', text, re.IGNORECASE
        )),
        "has_stages": bool(re.search(
            r'nncp.*control.plane|control.plane.*edpm', text, re.IGNORECASE
        )),
    }
    matched = [k for k, v in checks.items() if v]
    score = len(matched) / len(checks)
    return {
        "pass": score >= 0.75,
        "score": score,
        "reason": f"Score {score:.2f}/1.0 — matched: {', '.join(matched) or 'none'}",
    }
