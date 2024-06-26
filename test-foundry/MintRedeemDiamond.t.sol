// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console2} from "forge-std/Test.sol";

//import {StakeFacet} from "../contracts/facets/StakeFacet.sol";

import {OracleProcess} from "../contracts/process/OracleProcess.sol";

import  "./BaseDeployDiamond.t.sol";
contract MintRedeemDiamond  is BaseDeployDiamond{
    bytes32 constant MINT_ID_KEY = keccak256("MINT_ID_KEY");
    bytes32 constant ORDER_ID_KEY = keccak256("ORDER_ID_KEY");

    function setUp() public virtual override {
        super.setUp();
    }

    function testMintxEthWithWETH() public{
        //deposit
        depositWETH(); 

    }

    function testOrderCreateAndExecute() public{
        //deposit weth
        depositWETH();

        uint256  preBalance = weth.balanceOf(user1);
        uint256 preTradeVaultBalance = weth.balanceOf(address(tradeVault));
        uint256 preMarketBalance = weth.balanceOf(xEth);

        console2.log("preBalance is ", preBalance);
        console2.log("preTradeVaultBalance is ", preTradeVaultBalance );
        console2.log("preMarketBalance is ", preMarketBalance );

        uint256 orderMargin = 1e18;
        uint256 executionFee = 2e15;

        OrderFacet orderFacet = OrderFacet(payable (address(diamond)));

        IOrder.PlaceOrderParams memory params = IOrder.PlaceOrderParams({
            symbol: marketSymbolCodeETH,
            orderSide: Order.Side.LONG,
            posSide: Order.PositionSide.INCREASE,
            orderType: Order.Type.MARKET,
            stopType: Order.StopType.NONE,
            isCrossMargin: false,
            marginToken: address(weth),
            qty: 0,
            leverage: 2e5,
            triggerPrice: 0,
            acceptablePrice: 1900e8,
            executionFee: executionFee,
            placeTime: 0,
            orderMargin: orderMargin,
            isNativeToken: false
        });
        // create order request
        vm.startPrank(user1);
        weth.approve(address(diamond), orderMargin);
        orderFacet.createOrderRequest{value: executionFee}(params);

        vm.stopPrank();

        // Order
        IOrder.AccountOrder[] memory orders =   orderFacet.getAccountOrders(user1);
        assertEq(1, orders.length);
        assertEq(user1, orders[0].orderInfo.account);

        //market
        MarketFacet marketFacet = MarketFacet(address(diamond));
        uint256 requestId = marketFacet.getLastUuid(ORDER_ID_KEY);

        //oracles
        int256 tokenPrice = 1800e8;
        OracleProcess.OracleParam[] memory oracles = new OracleProcess.OracleParam[](1);
        oracles[0] = OracleProcess.OracleParam({
            token: address(weth),
            targetToken: address(0),
            minPrice: tokenPrice,
            maxPrice: tokenPrice
        });
      
      vm.prank(account0);
      orderFacet.executeOrder(requestId, oracles);
      vm.stopPrank();


      console2.log("-------------------------------- deposit again ");
      //deposit again
      depositWETH();

    }

    function testMintxUsdWithUsdc() public{
        depositUSDC();
    }



    function depositWETH() internal{
       
        uint256  preBalance = weth.balanceOf(user0);
        uint256 preVaultBalance = weth.balanceOf(address(lpVault));
        uint256 preMarketBalance = weth.balanceOf(xEth);

        console2.log("preBalance is ", preBalance);
        console2.log("preVaultBalance is ", preVaultBalance );
        console2.log("preMarketBalance is ", preMarketBalance );

        int256 tokenPrice = 1800e8;
        uint256 requestTokenAmount = 30e18;
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

    function depositUSDC() internal{
       
        uint256  preBalance = MockToken(usdc).balanceOf(user0);
        uint256 preVaultBalance = MockToken(usdc).balanceOf(address(lpVault));
        uint256 preUsdPoolBalance = MockToken(usdc).balanceOf(xUSD);

        console2.log("usdc preBalance is ", preBalance);
        console2.log("usdc preVaultBalance is ", preVaultBalance );
        console2.log("usdc preMarketBalance is ", preUsdPoolBalance );

        int256 tokenPrice = 101e6;
        uint256 requestTokenAmount = 30e8;
        uint256 executionFee = 2e15;

        StakeFacet stakeFacet = StakeFacet(address(diamond));

        IStake.MintStakeTokenParams memory params = IStake.MintStakeTokenParams({
        stakeToken: xUSD,
        requestToken: usdc,
        requestTokenAmount: requestTokenAmount,
        walletRequestTokenAmount: requestTokenAmount,
        minStakeAmount: 0,
        isCollateral: false,
        isNativeToken: false,
        executionFee: executionFee
       });
       
        vm.startPrank(user0);
        MockToken(usdc).approve(address(diamond), requestTokenAmount);
        stakeFacet.createMintStakeTokenRequest{value:executionFee }(params);

        vm.stopPrank();


        uint256  afterBalance = MockToken(usdc).balanceOf(user0);
        uint256 afterLpVaultBalance = MockToken(usdc).balanceOf(address(lpVault));
        uint256 afterUsdPoolBalance = MockToken(usdc).balanceOf(xUSD);

        console2.log("usdc afterBalance is ", afterBalance);
        console2.log("usdc afterLpVaultBalance before execute is ", afterLpVaultBalance );
        console2.log("usdc afterUsdPoolBalance is ", afterUsdPoolBalance );

   
        MockToken xToken = MockToken(payable(xUSD));
        uint256 preXTokenBalance = xToken.balanceOf(user0);
        MarketFacet marketFacet = MarketFacet(address(diamond));
        uint256 requestId = marketFacet.getLastUuid(MINT_ID_KEY);

        console2.log("usdc preXTokenBalance is ", preXTokenBalance );

        OracleProcess.OracleParam[] memory oracles = new OracleProcess.OracleParam[](1);
        oracles[0] = OracleProcess.OracleParam({
            token: usdc,
            targetToken: address(0),
            minPrice: tokenPrice,
            maxPrice: tokenPrice
        });
        vm.prank(account0);
        stakeFacet.executeMintStakeToken(requestId, oracles);

        uint256 afterXTokenBalance = xToken.balanceOf(user0);
        
        afterLpVaultBalance = MockToken(usdc).balanceOf(address(lpVault));
        console2.log("user xUsd afterXTokenBalance is ", afterXTokenBalance );
        console2.log("usdc afterLpVaultBalance after execute is ", afterLpVaultBalance );

        // const mintFee = precision.mulRate(requestTokenAmount, lpPoolConfig.mintFeeRate)

        // const realRequestTokenAmount = requestTokenAmount - mintFee
        

    }




}