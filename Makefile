.PHONY: test compile

compile:
	npx hardhat compile

test: 
	npx hardhat test 