const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");

describe("NusaQuest", function () {
  let nusaQuest, deployer, bob, bobInstance;
  const ids = [0, 1, 2, 3, 4];
  const values = [200, 1, 1, 1, 1];
  const prices = [0, 40, 200, 300, 400];
  const uris = ["", "a", "b", "c", "d"];
  const destinationIds = ["Tugu Pahlawan", "Candi Borobudur"];
  const proofs = ["aaa", "bbb"];
  const fungibleTokenId = 0;

  beforeEach(async () => {
    [deployer, bob] = await ethers.getSigners();
    const NusaQuest = await ethers.getContractFactory("NusaQuest");
    nusaQuest = await NusaQuest.deploy();
    bobInstance = nusaQuest.connect(bob);
  });

  it("should allow minting both fungible and non-fungible tokens", async function () {
    await expect(nusaQuest.mint(ids, values, prices, uris))
      .to.emit(nusaQuest, "Minted")
      .withArgs(ids, values);

    const expectedNFTPrice = 40;
    const actualNFTPrice = await nusaQuest.getNFTPrice(ids[1]);

    const expectedSecondTokenURI = "https://gateway.pinata.cloud/ipfs/a";
    const actualSecondTokenURI = await nusaQuest.tokenURI(ids[1]);

    assert(expectedNFTPrice == actualNFTPrice);
    assert(expectedSecondTokenURI == actualSecondTokenURI);
  });

  it("should revert when input arrays have mismatched lengths", async function () {
    const modifiedIds = ids.slice(0, -1);
    await expect(
      nusaQuest.mint(modifiedIds, values, prices, uris)
    ).to.be.revertedWith(
      "Mismatch between IDs, values, and URIs. Please ensure all inputs have the same length."
    );
  });

  it("should revert when fungible token has invalid format", async function () {
    const modifiedPrices = [...prices];
    modifiedPrices[0] = 1;

    await expect(
      nusaQuest.mint(ids, values, modifiedPrices, uris)
    ).to.be.revertedWith(
      "To mint a fungible token, leave ID and price as 0, and URI empty."
    );
  });

  it("should allow claiming fungible token once per day for each destination", async function () {
    await nusaQuest.mint(ids, values, prices, uris);

    await expect(bobInstance.claim(destinationIds[0], proofs))
      .to.emit(nusaQuest, "Claimed")
      .withArgs(bob.address, destinationIds[0], anyValue);

    const expectedBalance = 20;
    const actualBalance = await nusaQuest.balance(bob.address, fungibleTokenId);

    const expectedProofsLength = 1;
    const actualProofs = await nusaQuest.getProofs();

    assert(expectedBalance == actualBalance);
    assert(expectedProofsLength == actualProofs.length);
  });

  it("should revert when user tries to claim token more than once per day per destination", async function () {
    await nusaQuest.mint(ids, values, prices, uris);
    await bobInstance.claim(destinationIds[1], proofs);

    await expect(
      bobInstance.claim(destinationIds[1], proofs)
    ).to.be.revertedWith(
      "You can only claim once per day for each destination."
    );
  });

  it("should allow user to swap claimed fungible tokens for an NFT", async function () {
    await nusaQuest.mint(ids, values, prices, uris);
    await bobInstance.claim(destinationIds[0], proofs);
    await bobInstance.claim(destinationIds[1], proofs);

    await expect(bobInstance.swap(ids[1], 40))
      .to.emit(nusaQuest, "Swapped")
      .withArgs(bob.address, ids[1]);
  });

  it("should revert when swapped token amount does not match NFT price", async function () {
    await nusaQuest.mint(ids, values, prices, uris);
    await bobInstance.claim(destinationIds[0], proofs);

    await expect(bobInstance.swap(ids[1], 50)).to.be.revertedWith(
      "Price mismatch: the provided token amount does not match the NFT price."
    );
  });
});
