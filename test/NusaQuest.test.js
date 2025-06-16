const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");

describe("NusaQuest", function () {
  let nusaQuest, deployer, bob;
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
    const bobInstance = await nusaQuest.connect(bob);
    const destinationId = destinationIds[0];

    await nusaQuest.mint(ids, values, prices, uris);

    await expect(bobInstance.claim(destinationId, proofs))
      .to.emit(nusaQuest, "Claimed")
      .withArgs(bob.address, destinationId, anyValue);

    const expectedBalance = 20;
    const actualBalance = await nusaQuest.balance(bob.address, fungibleTokenId);

    const expectedProofsLength = 1;
    const actualProofs = await nusaQuest.getProofs();

    assert(expectedBalance == actualBalance);
    assert(expectedProofsLength == actualProofs.length);
  });

  it("should revert when user tries to claim token more than once per day per destination", async function () {
    const bobInstance = await nusaQuest.connect(bob);
    const destinationId = destinationIds[0];

    await nusaQuest.mint(ids, values, prices, uris);
    await bobInstance.claim(destinationId, proofs);

    await expect(bobInstance.claim(destinationId, proofs)).to.be.revertedWith(
      "You can only claim once per day for each destination."
    );
  });

  it("should allow user to swap claimed fungible tokens for an NFT", async function () {
    const bobInstance = await nusaQuest.connect(bob);
    const firstDestinationId = destinationIds[0];
    const secondDestinationId = destinationIds[1];
    const nftId = ids[1];
    const amountToSwap = 40;

    await nusaQuest.mint(ids, values, prices, uris);
    await bobInstance.claim(firstDestinationId, proofs);
    await bobInstance.claim(secondDestinationId, proofs);

    await expect(bobInstance.swap(nftId, amountToSwap))
      .to.emit(nusaQuest, "Swapped")
      .withArgs(bob.address, nftId);
  });

  it("should revert when swapped token amount does not match NFT price", async function () {
    const bobInstance = await nusaQuest.connect(bob);
    const firstDestinationId = destinationIds[0];
    const nftId = ids[1];
    const amountToSwap = 50;

    await nusaQuest.mint(ids, values, prices, uris);
    await bobInstance.claim(firstDestinationId, proofs);

    await expect(bobInstance.swap(nftId, amountToSwap)).to.be.revertedWith(
      "Price mismatch: the provided token amount does not match the NFT price."
    );
  });
});
