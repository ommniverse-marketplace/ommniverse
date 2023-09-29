import { ethers, upgrades } from "hardhat";

async function main() {
  // Common Constants
  // Replace these with real value
  const OmmiTokenAddress = "";
  const primaryfeeReceiver = "";
  const secondaryfeeReceiver = "";

  // User Collection Factory Constants
  const PlatformFee = 100; // for 1% platform fee
  const PlatformFeeReceiver = "";

  // Ommniverse SemiFungible Collection Constants
  const Ommi1155Name = "OmmniverseFNFT";
  const Ommi1155Symbol = "OFNFT";
  // Ommniverse NonFungible Collection Constants
  const Ommi721Name = "OmmniverseNFT";
  const Ommi721Symbol = "ONFT";
  ///////////////////////////////////////////////////////

  const CollectionFactory = await ethers.getContractFactory(
    "CollectionFactory"
  );

  const SemiFungibleCollection = await ethers.getContractFactory(
    "SemiFungibleCollection"
  );
  // 1. Deploying User collection factory
  // Deploying SemiFungibleCollection VaultBeacon
  console.log("1. Deploying User Collection Beacon");
  const beaconSemiFungibleCollection = await upgrades.deployBeacon(
    SemiFungibleCollection
  );
  await beaconSemiFungibleCollection.deployed();
  console.log(
    `User Collection Beacon Proxy ${beaconSemiFungibleCollection.address}`
  );

  console.log(
    "User Collection Beacon Implementation",
    await upgrades.beacon.getImplementationAddress(
      beaconSemiFungibleCollection.address
    )
  );

  // Deploying CollectionFactory
  console.log("2. Deploying User CollectionFactory");
  const collectionFactory = await upgrades.deployProxy(
    CollectionFactory,
    [
      beaconSemiFungibleCollection.address,
      PlatformFee,
      OmmiTokenAddress,
      PlatformFeeReceiver,
    ],
    {
      initializer: "initialize",
    }
  );
  await collectionFactory.deployed();
  console.info(`User Collection Factory Proxy ${collectionFactory.address}`);
  const CollectionFactoryImplAddress =
    await upgrades.erc1967.getImplementationAddress(collectionFactory.address);
  console.log(
    "User Collection Factory Implementation",
    CollectionFactoryImplAddress
  );

  // 2. Deploying Ommniverse SemiFungible Collection
  const OmmniverseSemiFungibleCollection = await ethers.getContractFactory(
    "OmmniverseSemiFungibleCollection"
  );

  console.log("3. Deploying Ommniverse SemiFungible Collection");
  const ommniverseSemi = await upgrades.deployProxy(
    OmmniverseSemiFungibleCollection,
    [
      Ommi1155Name,
      Ommi1155Symbol,
      OmmiTokenAddress,
      primaryfeeReceiver,
      secondaryfeeReceiver,
    ],
    {
      initializer: "initialize",
    }
  );
  await ommniverseSemi.deployed();
  console.info(`Ommniverse SemiFungible Proxy ${ommniverseSemi.address}`);
  const OmniSemiImplAddress = await upgrades.erc1967.getImplementationAddress(
    ommniverseSemi.address
  );
  console.log("Ommniverse SemiFungible Implementation", OmniSemiImplAddress);

  // 3. Deploying Ommniverse NonFungible Collection
  const OmmniverseNonFungibleCollection = await ethers.getContractFactory(
    "OmmniverseNonFungibleCollection"
  );

  console.log("4. Deploying Ommniverse NonFungible Collection");
  const ommniverseNon = await upgrades.deployProxy(
    OmmniverseNonFungibleCollection,
    [
      Ommi721Name,
      Ommi721Symbol,
      OmmiTokenAddress,
      primaryfeeReceiver,
      secondaryfeeReceiver,
    ],
    {
      initializer: "initialize",
    }
  );
  await ommniverseNon.deployed();
  console.info(`Ommniverse NonFungible Proxy ${ommniverseNon.address}`);
  const OmniNonImplAddress = await upgrades.erc1967.getImplementationAddress(
    ommniverseNon.address
  );
  console.log("Ommniverse NonFungible Implementation", OmniNonImplAddress);
}

// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
