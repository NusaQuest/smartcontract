.PHONY: test compile coverage deploy verify

include .env

compile:
	npx hardhat compile

test:
	npx hardhat test

coverage:
	npx hardhat coverage

deploy:
	npx hardhat ignition deploy ignition/modules/NusaQuest.js --network ${NETWORK}

verify:
	npx hardhat verify --network ${NETWORK} ${CONTRACT_ADDRESS}