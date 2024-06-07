// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {ForgeTestConfig} from "./ForgeTestConfig.s.sol";

contract HelperConfig is Script, ForgeTestConfig {
  NetworkConfig public activeNetworkConfig;

  struct NetworkConfig {
    string baseURL;
    uint256 mintCostUsd;
    uint256 feePercent;
    address domainRegistry;
    address metadata;
    address usdPriceFeed;
  }

  constructor() {
    if (block.chainid == 137) {
      activeNetworkConfig = getPolygonMainnetConfig();
    } else if (block.chainid == 80002) {
      activeNetworkConfig = getPolygonAmoyConfig();
    } else {
      activeNetworkConfig = getLocalhostConfig();
    }
  }

  function getPolygonMainnetConfig() public pure returns (NetworkConfig memory mainnetNetworkConfig) {
    mainnetNetworkConfig = NetworkConfig({
      baseURL: BASE_URL,
      mintCostUsd: MINT_COST_USD,
      feePercent: FEE_PERCENT,
      domainRegistry: POLYGON_DOMAIN_REGISTRY_ADDRESS,
      metadata: POLYGON_METADATA_ADDRESS,
      usdPriceFeed: POLYGON_MATIC_USD_ADDRESS
    });
  }

  function getEthereumSepoliaConfig() public pure returns (NetworkConfig memory mainnetNetworkConfig) {
    mainnetNetworkConfig = NetworkConfig({
      baseURL: BASE_URL,
      mintCostUsd: MINT_COST_USD,
      feePercent: FEE_PERCENT,
      domainRegistry: SEPOLIA_DOMAIN_REGISTRY_ADDRESS,
      metadata: SEPOLIA_METADATA_ADDRESS,
      usdPriceFeed: SEPOLIA_MATIC_USD_ADDRESS
    });
  }

  function getPolygonAmoyConfig() public pure returns (NetworkConfig memory amoyNetworkConfig) {
    amoyNetworkConfig = NetworkConfig({
      baseURL: BASE_URL,
      mintCostUsd: MINT_COST_USD,
      feePercent: FEE_PERCENT,
      domainRegistry: AMOY_DOMAIN_REGISTRY_ADDRESS,
      metadata: AMOY_METADATA_ADDRESS,
      usdPriceFeed: AMOY_MATIC_USD_ADDRESS
    });
  }

  function getLocalhostConfig() public pure returns (NetworkConfig memory localhostNetworkConfig) {
    localhostNetworkConfig = NetworkConfig({
      baseURL: BASE_URL,
      mintCostUsd: MINT_COST_USD,
      feePercent: FEE_PERCENT,
      domainRegistry: LOCALHOST_DOMAIN_REGISTRY_ADDRESS,
      metadata: LOCALHOST_METADATA_ADDRESS,
      usdPriceFeed: LOCALHOST_MATIC_USD_ADDRESS
    });
  }
}
