import re


def get_assert(output, context):
    text = output.lower()
    score = 0.0
    checks = {
        "explain_flow_mention": r'explain-flow|explain flow|/explain-flow',
        "nova_controller": r'internal/controller/nova|nova reconcil',
        "flow_artifact": r'flow diagram|sequence|mermaid|step.by.step|call graph',
        "handoff_context": r'before (we|i)|context|hand off|delegate|invoke',
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
