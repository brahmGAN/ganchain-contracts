const { ethers,upgrades } = require("hardhat");
const { expect } = require("chai");

function stringToBytes32(str) {
    const buffer = Buffer.alloc(32);
    buffer.write(str, 'utf8'); 
    return '0x' + buffer.toString('hex');
}

const id = stringToBytes32("ccad9036-3f3d-455e-abc2-8ff85ce1adef");
const id2 = stringToBytes32("ccad9036-3f3d-455e-abcd-8ff85ce1adef");
const id3 = stringToBytes32("ccad9036-3f3d-455e-abc2-8ff85ceabcdefgh");
const userId = stringToBytes32("6abddd01-464f-410b-935f-ae42e6afdd4c");
const amount = stringToBytes32("0.1");
const balanceRemaining = stringToBytes32("10.1");
const isDebit = false;
const notes = stringToBytes32("Credits applied");
const createdAt = stringToBytes32("2024-08-21 07:14:12.524712+00");
const updatedAt = stringToBytes32("2024-08-21 07:14:12.524712+00");
const machineId = stringToBytes32("1820321a-cd0f-4b05-803f-e7d69dc75e2a");
const startTime = stringToBytes32("2024-08-21 09:57:41.596");
const endTime = stringToBytes32("2024-08-25 10:57:41.596");
const baseCost = stringToBytes32("3.5752249999999997");
const totalCost = stringToBytes32("0");
const sshKeyId = stringToBytes32("3.5752249999999997dbjfdshb");
const status = stringToBytes32("initial");
const machineCount = 69;
const advancePaid = stringToBytes32("69.69");

describe("Market Place:",()=>{
    let deployer;
    let owner;
    let MarketPlace;
    let marketPlaceProxy;
    before(async()=>{
        [deployer,owner] = await ethers.getSigners();
        MarketPlace = await ethers.getContractFactory("Marketplace");
        marketPlaceProxy = await upgrades.deployProxy(MarketPlace,[owner.address],{ initializer: "initialize" });
    });

    describe("Transaction",async()=>{
        it("Add Transaction:",async()=>{
            await expect(
                await marketPlaceProxy.connect(owner).transaction(
                    id,
                    userId,
                    amount,
                    balanceRemaining,
                    isDebit,
                    notes,
                    createdAt,
                    updatedAt
                ))
                .to.emit(marketPlaceProxy,"TransactionEvent")
                .withArgs(
                    id,
                    userId,
                    amount,
                    balanceRemaining,
                    isDebit,
                    notes,
                    createdAt,
                    updatedAt
                );
        });
        it("Check the `transactions` mapping",async()=>{
            const transactionMapping = await marketPlaceProxy.transactions(id); 
            expect(transactionMapping[0]).to.be.equals(id);
            expect(transactionMapping[1]).to.be.equals(userId);
            expect(transactionMapping[2]).to.be.equals(amount);
            expect(transactionMapping[3]).to.be.equals(balanceRemaining);
            expect(transactionMapping[4]).to.be.equals(isDebit);
            expect(transactionMapping[5]).to.be.equals(notes);
            expect(transactionMapping[6]).to.be.equals(createdAt);
            expect(transactionMapping[7]).to.be.equals(updatedAt);
        });
    });

    describe("Bookings",async()=>{
        it("Add Bookings:",async()=>{
            await expect(
                await marketPlaceProxy.connect(owner).booking(
                    id, 
                    userId, 
                    machineId, 
                    startTime, 
                    endTime, 
                    baseCost,
                    totalCost, 
                    sshKeyId, 
                    status, 
                    notes, 
                    createdAt, 
                    updatedAt 
                ))
                .to.emit(marketPlaceProxy,"BookingEvent")
                .withArgs(
                    id, 
                    userId, 
                    machineId, 
                    startTime, 
                    endTime, 
                    baseCost,
                    totalCost, 
                    sshKeyId, 
                    status, 
                    notes, 
                    createdAt, 
                    updatedAt 
                );
        });
        it("Check the `transactions` mapping",async()=>{
            const bookingsMapping = await marketPlaceProxy.bookings(id); 
            expect(bookingsMapping[0]).to.be.equals(id);
            expect(bookingsMapping[1]).to.be.equals(userId);
            expect(bookingsMapping[2]).to.be.equals(machineId);
            expect(bookingsMapping[3]).to.be.equals(startTime);
            expect(bookingsMapping[4]).to.be.equals(endTime);
            expect(bookingsMapping[5]).to.be.equals(baseCost);
            expect(bookingsMapping[6]).to.be.equals(totalCost);
            expect(bookingsMapping[7]).to.be.equals(sshKeyId);
            expect(bookingsMapping[8]).to.be.equals(status);
            expect(bookingsMapping[9]).to.be.equals(notes);
            expect(bookingsMapping[10]).to.be.equals(createdAt);
            expect(bookingsMapping[11]).to.be.equals(updatedAt);
        });
    });

    describe("Rentals",async()=>{
        it("Add Rentals:",async()=>{
            await expect(
                await marketPlaceProxy.connect(owner).rental(
                    id, 
                    userId, 
                    machineId, 
                    machineCount, 
                    startTime, 
                    endTime,
                    advancePaid, 
                    totalCost, 
                    sshKeyId, 
                    status, 
                    notes,
                    createdAt, 
                    updatedAt 
                ))
                .to.emit(marketPlaceProxy,"RentalEvent")
                .withArgs(
                    id, 
                    userId, 
                    machineId, 
                    machineCount, 
                    startTime, 
                    endTime,
                    advancePaid, 
                    totalCost, 
                    sshKeyId, 
                    status, 
                    notes,
                    createdAt, 
                    updatedAt
                );
        });
        it("Check the `Rentals` mapping",async()=>{
            const rentalsMapping = await marketPlaceProxy.rentals(id); 
            expect(rentalsMapping[0]).to.be.equals(id);
            expect(rentalsMapping[1]).to.be.equals(userId);
            expect(rentalsMapping[2]).to.be.equals(machineId);
            expect(rentalsMapping[3]).to.be.equals(machineCount);
            expect(rentalsMapping[4]).to.be.equals(startTime);
            expect(rentalsMapping[5]).to.be.equals(endTime);
            expect(rentalsMapping[6]).to.be.equals(advancePaid);
            expect(rentalsMapping[7]).to.be.equals(totalCost);
            expect(rentalsMapping[8]).to.be.equals(sshKeyId);
            expect(rentalsMapping[9]).to.be.equals(status);
            expect(rentalsMapping[10]).to.be.equals(notes);
            expect(rentalsMapping[11]).to.be.equals(createdAt);
            expect(rentalsMapping[12]).to.be.equals(updatedAt);
        });
    });

    describe("Reverts",async()=>{
        it("Should revert wrong owner call",async()=>{
            await expect(marketPlaceProxy.connect(deployer).rental(
                id, 
                userId, 
                machineId, 
                machineCount, 
                startTime, 
                endTime,
                advancePaid, 
                totalCost, 
                sshKeyId, 
                status, 
                notes,
                createdAt, 
                updatedAt 
            ))
            .to.be.reverted;
        });

        it("Should revert when transaction exists",async()=>{
            await marketPlaceProxy.connect(owner).rental(
                id2, 
                userId, 
                machineId, 
                machineCount, 
                startTime, 
                endTime,
                advancePaid, 
                totalCost, 
                sshKeyId, 
                status, 
                notes,
                createdAt, 
                updatedAt 
            );
            await expect(marketPlaceProxy.connect(owner).rental(
                id2, 
                userId, 
                machineId, 
                machineCount, 
                startTime, 
                endTime,
                advancePaid, 
                totalCost, 
                sshKeyId, 
                status, 
                notes,
                createdAt, 
                updatedAt 
            ))
            .to.be.revertedWithCustomError(marketPlaceProxy,'RentalAlreadyExists');
        });

        it("Should revert when transaction exists",async()=>{
            await expect(marketPlaceProxy.connect(owner).updateRental(
                id3, 
                userId, 
                machineId, 
                machineCount, 
                startTime, 
                endTime,
                advancePaid, 
                totalCost, 
                sshKeyId, 
                status, 
                notes,
                createdAt, 
                updatedAt 
            ))
            .to.be.revertedWithCustomError(marketPlaceProxy,'RentalDoesNotExist');
        });
    });
});