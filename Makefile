COMPOSEFLAGS=-d
ITESTS_L2_HOST=http://localhost:9545
BEDROCK_TAGS_REMOTE?=origin

build: build-go build-ts
.PHONY: build

build-go: submodules op-node op-proposer op-batcher
.PHONY: build-go

build-ts: submodules
	if [ -n "$$NVM_DIR" ]; then \
		. $$NVM_DIR/nvm.sh && nvm use; \
	fi
	yarn install
	yarn build
.PHONY: build-ts

submodules:
	# CI will checkout submodules on its own (and fails on these commands)
	if [ -z "$$GITHUB_ENV" ]; then \
		git submodule init; \
		git submodule update; \
	fi
.PHONY: submodules

op-bindings:
	make -C ./op-bindings
.PHONY: op-bindings

op-node:
	make -C ./op-node op-node
.PHONY: op-node

op-batcher:
	make -C ./op-batcher op-batcher
.PHONY: op-batcher

op-proposer:
	make -C ./op-proposer op-proposer
.PHONY: op-proposer

op-program:
	make -C ./op-program op-program
.PHONY: op-program

mod-tidy:
	# Below GOPRIVATE line allows mod-tidy to be run immediately after
	# releasing new versions. This bypasses the Go modules proxy, which
	# can take a while to index new versions.
	#
	# See https://proxy.golang.org/ for more info.
	export GOPRIVATE="github.com/ethereum-optimism" && go mod tidy
.PHONY: mod-tidy

clean:
	rm -rf ./bin
.PHONY: clean

nuke: clean devnet-clean
	git clean -Xdf
.PHONY: nuke

devnet-up:
	@bash ./ops-bedrock/devnet-up.sh
.PHONY: devnet-up

testnet-up:
	@bash ./ops-bedrock/testnet-up.sh
.PHONY: testnet-up

goerli-up:
	@bash ./ops-bedrock-goerli/up.sh
.PHONY: goerli-up

upgrade-near-components:
	go get github.com/dndll/near-openrpc@near

devnet-up-deploy:
	PYTHONPATH=./bedrock-devnet python3 ./bedrock-devnet/main.py --monorepo-dir=.
.PHONY: devnet-up-deploy

devnet-down:
	@(cd ./ops-bedrock && GENESIS_TIMESTAMP=$(shell date +%s) docker compose -f docker-compose-devnet.yml stop)
.PHONY: devnet-down

testnet-down:
	@(cd ./ops-bedrock && GENESIS_TIMESTAMP=$(shell date +%s) docker compose -f docker-compose-testnet.yml stop)
.PHONY: testnet-down

goerli-down:
	@(cd ./ops-bedrock-goerli && GENESIS_TIMESTAMP=$(shell date +%s) docker compose stop)
.PHONY: goerli-down

devnet-clean:
	rm -rf ./packages/contracts-bedrock/deployments/devnetL1
	rm -rf ./.devnet
	cd ./ops-bedrock && docker compose -f docker-compose-devnet.yml down
	docker image ls 'ops-bedrock*' --format='{{.Repository}}' | xargs -r docker rmi
	docker volume ls --filter name=ops-bedrock --format='{{.Name}}' | xargs -r docker volume rm
.PHONY: devnet-clean

testnet-clean:
	rm -rf ./packages/contracts-bedrock/deployments/devnetL1
	rm -rf ./.devnet
	cd ./ops-bedrock && docker compose -f docker-compose-testnet.yml down
	docker image ls 'ops-bedrock*' --format='{{.Repository}}' | xargs -r docker rmi
	docker volume ls --filter name=ops-bedrock --format='{{.Name}}' | xargs -r docker volume rm
.PHONY: testnet-clean

goerli-clean:
	rm -rf ./.goerli
	cd ./ops-bedrock-goerli && docker compose down
	docker image ls 'ops-bedrock*' --format='{{.Repository}}' | xargs -r docker rmi
	docker volume ls --filter name=ops-bedrock --format='{{.Name}}' | xargs -r docker volume rm
.PHONY: goerli-clean

devnet-logs:
	# @(cd ./ops-bedrock && docker-compose -f docker-compose-devnet.yml logs -f)
	@(cd ./ops-bedrock && docker compose -f docker-compose-devnet.yml logs -f)
	.PHONY: devnet-logs

testnet-logs:
	@(cd ./ops-bedrock && docker compose -f docker-compose-testnet.yml logs -f)
	.PHONY: testnet-logs

test-unit:
	make -C ./op-node test
	make -C ./op-proposer test
	make -C ./op-batcher test
	make -C ./op-e2e test
	yarn test
.PHONY: test-unit

test-integration:
	bash ./ops-bedrock/test-integration.sh \
		./packages/contracts-bedrock/deployments/devnetL1
.PHONY: test-integration

# Remove the baseline-commit to generate a base reading & show all issues
semgrep:
	$(eval DEV_REF := $(shell git rev-parse develop))
	SEMGREP_REPO_NAME=ethereum-optimism/optimism semgrep ci --baseline-commit=$(DEV_REF)
.PHONY: semgrep

clean-node-modules:
	rm -rf node_modules
	rm -rf packages/**/node_modules


tag-bedrock-go-modules:
	./ops/scripts/tag-bedrock-go-modules.sh $(BEDROCK_TAGS_REMOTE) $(VERSION)
.PHONY: tag-bedrock-go-modules

update-op-geth:
	./ops/scripts/update-op-geth.py
.PHONY: update-op-geth
