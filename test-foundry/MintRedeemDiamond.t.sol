// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console2} from "forge-std/Test.sol";

import {StakeFacet} from "../contracts/facets/StakeFacet.sol";



import  "./BaseDeployDiamond.t.sol";
contract MintRedeemDiamond  is BaseDeployDiamond{
    function setUp() public virtual override {
        super.setUp();
    }

 function testMintxEthWithWETH() public{
       
        uint256  preBalance = weth.balanceOf(user0);
        uint256 preVaultBalance = weth.balanceOf(address(lpVault));
        uint256 preMarketBalance = weth.balanceOf(xEth);

        console2.log("preBalance is ", preBalance);
        console2.log("preVaultBalance is ", preVaultBalance );
        console2.log("preMarketBalance is ", preMarketBalance );

        uint256 tokenPrice = 1800e8;
        uint256 requestTokenAmount = 1e18;
        uint256 executionFee = 2e15;

        StakeFacet stakeFacet = StakeFacet(address(diamond));

        IStake.MintStakeTokenParams memory params = IStake.MintStakeTokenParams({
        stakeToken: xEth,
        requestToken: address(weth),
        requestTokenAmount: requestTokenAmount,
        walletRequestTokenAmount: requestTokenAmount,
        minStakeAmount: 0,
        isCollateral: false,
        isNativeToken: false,
        executionFee: executionFee
       });
       
        vm.startPrank(user0);
        weth.approve(address(diamond), requestTokenAmount);
        stakeFacet.createMintStakeTokenRequest{value:executionFee }(params);

        vm.stopPrank();


        uint256  afterBalance = weth.balanceOf(user0);
        uint256 afterLpVaultBalance = weth.balanceOf(address(lpVault));
        uint256 afterMarketBalance = weth.balanceOf(xEth);

        console2.log("afterBalance is ", afterBalance);
        console2.log("afterLpVaultBalance is ", afterLpVaultBalance );
        console2.log("afterMarketBalance is ", afterMarketBalance );




    }
}