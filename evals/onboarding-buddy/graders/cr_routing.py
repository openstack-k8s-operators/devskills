import re


def get_assert(output, context):
    text = output.lower()
    score = 0.0
    checks = {
        "nova_cr": r'\bnova\b',
        "openstack_role": r'compute|vm|virtual machine|openstack',
        "api_type_path": r'api/nova|nova_types\.go|v1beta1',
        "controller_path": r'internal/controller/nova|novareconciler|nova controller',
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
