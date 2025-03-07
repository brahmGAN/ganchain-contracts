.PHONY: test compile

compile:
	npx hardhat compile

test: 
	npx hardhat test 

deploy-sepolia: 
	npx hardhat run /home/blackbeard/gpu/ganchain-contracts/ignition/modules/BuyBack_deploy.js --network sepolia

deploy-gpu: 
	npx hardhat run /home/blackbeard/gpu/ganchain-contracts/ignition/modules/BuyBack_deploy.js --network gpu