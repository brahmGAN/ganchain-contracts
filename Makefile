.PHONY: test compile

compile:
	npx hardhat compile

test: 
	npx hardhat test 

make deploy sepolia: 
	npx hardhat run /home/blackbeard/gpu/ganchain-contracts/ignition/modules/BuyBack_deploy.js --network sepolia

make deploy gpu: 
	npx hardhat run /home/blackbeard/gpu/ganchain-contracts/ignition/modules/BuyBack_deploy.js --network gpu