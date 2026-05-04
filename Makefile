.PHONY: install-claude install-opencode uninstall-claude uninstall-opencode \
       check test test-memory validate validate-skills new-skill new-agent help

INSTALL := ./scripts/install.sh
SCAFFOLD := ./scripts/scaffold.sh

## Installation

install-claude: ## Install globally for Claude Code (~/.claude/)
	@$(INSTALL) --claude-code

install-opencode: ## Install globally for OpenCode (~/.config/opencode/)
	@$(INSTALL) --opencode

## Uninstall

uninstall-claude: ## Remove from Claude Code
	@$(INSTALL) --uninstall-claude

uninstall-opencode: ## Remove from OpenCode
	@$(INSTALL) --uninstall-opencode

## Validation

check: ## Check dependencies
	@$(INSTALL) --check

test: ## Run plugin tests (structure + functional)
	@bash tests/test-plugin.sh all

test-memory: ## Run memory, state, worktree, and dependency tests
	@bash tests/test-memory.sh

validate: ## Run structure validation only
	@bash tests/test-plugin.sh structure

validate-skills: ## Validate skill and agent structure
	@bash tests/validate-skills.sh

## Scaffolding

new-skill: ## Scaffold a new skill (usage: make new-skill my-skill)
	@$(SCAFFOLD) --skill $(word 2,$(MAKECMDGOALS))

new-agent: ## Scaffold a new agent (usage: make new-agent my-agent)
	@$(SCAFFOLD) --agent $(word 2,$(MAKECMDGOALS))

%:
	@:

## Help

help: ## Show this help
	@echo "openstack-k8s-agent-tools"
	@echo ""
	@echo "Marketplace install (Claude Code, recommended):"
	@echo "  claude plugin marketplace add https://github.com/fmount/openstack-k8s-agent-tools"
	@echo "  claude plugin install openstack-k8s-agent-tools"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-24s\033[0m %s\n", $$1, $$2}'
