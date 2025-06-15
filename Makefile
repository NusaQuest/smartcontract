include .env

test:
	npx hardhat test

coverage:
	npx hardhat coverage

deploy:
	npx hardhat ignition deploy ignition/modules/NusaQuest.js --network lisk

verify:
	npx hardhat verify --network lisk ${CONTRACT_ADDRESS}