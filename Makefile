.PHONY: test compile

compile:
	npx hardhat compile

test: 
	npx hardhat test 

make deploy: 
	npx hardhat run /home/blackbeard/gpu/ganchain-contracts/ignition/modules/BuyBack_deploy.js