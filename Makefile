.PHONY: install
install:
	@echo "🚀 Installing the project's packages with neojac"
	@neojac install

.PHONY: check
check:
	@echo "🚀 Checking format: neojac fmt --check"
	@neojac fmt --check src archwire.jac
	@echo "🚀 Checking the package: neojac check"
	@neojac check --space memu

.PHONY: test
test:
	@echo "🚀 Building the package and running its suite: neojac test"
	@neojac test
