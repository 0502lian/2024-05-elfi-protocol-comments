// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console2} from "forge-std/Test.sol";

//import {StakeFacet} from "../contracts/facets/StakeFacet.sol";

import {OracleProcess} from "../contracts/process/OracleProcess.sol";

import  "./BaseDeployDiamond.t.sol";
contract MintRedeemDiamond  is BaseDeployDiamond{
    bytes32 constant MINT_ID_KEY = keccak256("MINT_ID_KEY");

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

        int256 tokenPrice = 1800e8;
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
        console2.log("afterLpVaultBalance before execute is ", afterLpVaultBalance );
        console2.log("afterMarketBalance is ", afterMarketBalance );

   
        MockToken xToken = MockToken(payable(xEth));
        uint256 preXTokenBalance = xToken.balanceOf(user0);
        MarketFacet marketFacet = MarketFacet(address(diamond));
        uint256 requestId = marketFacet.getLastUuid(MINT_ID_KEY);

        console2.log("preXTokenBalance is ", preXTokenBalance );

        OracleProcess.OracleParam[] memory oracles = new OracleProcess.OracleParam[](1);
        oracles[0] = OracleProcess.OracleParam({
            token: address(weth),
            targetToken: address(0),
            minPrice: tokenPrice,
            maxPrice: tokenPrice
        });
        vm.prank(account0);
        stakeFacet.executeMintStakeToken(requestId, oracles);

        uint256 afterXTokenBalance = xToken.balanceOf(user0);
        
        afterLpVaultBalance = weth.balanceOf(address(lpVault));
        console2.log("afterXTokenBalance is ", afterXTokenBalance );
        console2.log("afterLpVaultBalance after execute is ", afterLpVaultBalance );

        // const mintFee = precision.mulRate(requestTokenAmount, lpPoolConfig.mintFeeRate)

        // const realRequestTokenAmount = requestTokenAmount - mintFee
        

    }
}