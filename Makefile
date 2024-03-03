build-install-all: header.sh install_all.func.sh install_all.sh
	@mkdir -p ./dist
	@cat header.sh install_all.func.sh install_all.sh > ./dist/install_all
	@chmod +x ./dist/install_all
	@echo "Build complete"

build-test-install-all: build-install-all
	@./dist/install_all -t

phony: build-install-all
	@echo "Done"