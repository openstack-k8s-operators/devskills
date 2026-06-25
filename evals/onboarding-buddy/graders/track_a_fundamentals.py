import re


def get_assert(output, context):
    text = output.lower()

    # Menu auto-chaining often drifts Track A prompts into Track B content.
    if re.search(r'testing & contributing|running tests|make test|make run', text):
        return {
            "pass": False,
            "score": 0.0,
            "reason": "Drifted to Track B testing/contributing content",
        }

    score = 0.0
    checks = {
        "client_go": r'client-go|client\.go|kubernetes api',
        "controller_runtime": r'controller-runtime|controller runtime|reconcil',
        "kubebuilder": r'kubebuilder|crds?|custom resource definition',
        "track_a_teaching": r'analog|track a|fundamental|section a1|first topic',
    }
    matched = []
    for name, pattern in checks.items():
        if re.search(pattern, text):
            score += 0.25
            matched.append(name)

    return {
        "pass": score >= 0.5,
        "score": score,
        "reason": f"Score {score:.2f}/1.0 — matched: {', '.join(matched) or 'none'}",
    }
