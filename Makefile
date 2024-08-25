build-install-all: header.sh install_all.func.sh install_all.sh
	@mkdir -p ./dist
	@cat header.sh install_all.func.sh install_all.sh > ./dist/install_all
	@chmod +x ./dist/install_all
	@echo "Build complete"

build-test-install-all: build-install-all
	@./dist/install_all -t

set-version:
	@echo "Enter version number: "
	@read version; \
	sed -i "s/# SCRIPTSH_VERSION=.*/SCRIPTSH_VERSION=$$version/" semver.sh; \
	echo "Version set to $$version"

shfmt:
	@shfmt -w -i 2 -ci -sr -ln bash "${FILE}"

build:
	@if [ -z "${FILE}" ]; then printf "FILE not provided\n" && exit 1 ; fi
	@./publish "${FILE}"

phony: build-install-all
	@echo "Done"

