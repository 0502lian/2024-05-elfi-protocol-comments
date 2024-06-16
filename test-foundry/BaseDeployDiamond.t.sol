/******************************************************************************\
* Authors: Timo Neumann <timo@fyde.fi>, Rohan Sundar <rohan@fyde.fi>
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
* Abstract Contracts for the shared setup of the tests
/******************************************************************************/

import "../contracts/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "../contracts/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../contracts/facets/DiamondLoupeFacet.sol";
import {OrderFacet} from "../contracts/facets/OrderFacet.sol";
import {RoleAccessControlFacet} from "../contracts/facets/RoleAccessControlFacet.sol";
import {AccountFacet} from "../contracts/facets/AccountFacet.sol";
import {PoolFacet} from "../contracts/facets/PoolFacet.sol";
import {StakeFacet} from "../contracts/facets/StakeFacet.sol";
import {MarketFacet} from "../contracts/facets/MarketFacet.sol";
import {MarketManagerFacet, MarketFactoryProcess} from "../contracts/facets/MarketManagerFacet.sol";
import {OracleFacet} from "../contracts/facets/OracleFacet.sol";
import {FeeFacet} from "../contracts/facets/FeeFacet.sol";
import {PositionFacet} from "../contracts/facets/PositionFacet.sol";
import {VaultFacet} from "../contracts/facets/VaultFacet.sol";
import {LiquidationFacet} from "../contracts/facets/LiquidationFacet.sol";
import {RebalanceFacet} from "../contracts/facets/RebalanceFacet.sol";
import {StakingAccountFacet} from "../contracts/facets/StakingAccountFacet.sol";
import {ConfigFacet} from "../contracts/facets/ConfigFacet.sol";
import {SwapFacet} from "../contracts/facets/SwapFacet.sol";
import {FaucetFacet} from "../contracts/facets/FaucetFacet.sol";
import {ReferralFacet} from "../contracts/facets/ReferralFacet.sol";

import {LpVault} from "../contracts/vault/LpVault.sol";
import {PortfolioVault} from "../contracts/vault/PortfolioVault.sol";
import {TradeVault} from "../contracts/vault/TradeVault.sol";
import {Vault} from "../contracts/vault/Vault.sol";

import {Diamond} from "../contracts/router/Diamond.sol";
import {DiamondInit} from "../contracts/router/DiamondInit.sol";
import "./utils/HelperContract.t.sol";

//libraries
import {RoleAccessControl} from "../contracts/storage/RoleAccessControl.sol";

//interface
import {IConfig} from "../contracts/interfaces/IConfig.sol";
import {IMarket} from "../contracts/interfaces/IMarket.sol";
import {IPool}   from "../contracts/interfaces/IPool.sol";
import {IStake} from "../contracts/interfaces/IStake.sol";
import {IOrder} from "../contracts/interfaces/IOrder.sol";

//storages
import {AppPoolConfig} from "../contracts/storage/AppPoolConfig.sol";
import { AppConfig} from "../contracts/storage/AppConfig.sol";
import { AppTradeConfig} from "../contracts/storage/AppTradeConfig.sol";
import { AppTradeTokenConfig} from "../contracts/storage/AppTradeTokenConfig.sol";
import {Order} from "../contracts/storage/Order.sol";


import {MockToken} from "../contracts/mock/MockToken.sol";
import {WETH} from "../contracts/mock/WETH.sol";

contract BaseDeployDiamond is HelperContract {

    bytes32 constant marketSymbolCodeETH = 0x4554485553440000000000000000000000000000000000000000000000000000;
    string constant marketSymbol = "ETHUSD";
    
    uint8 constant  usdDecimals = 6;
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    DiamondInit dInit;

    //address
    address public admin;
    address public developer;
    address public account0;
    address public account1;
    address public account2;
    address public user0;
    address public user1;



    //Tokens    
    WETH public weth;
    address public wbtc;
    address payable public usdc;
    address public sol;

    //Vaults
    Vault public lpVault;
    Vault public portfolioVault;
    Vault public tradeVault;
    address public xEth;
    address public xUSD;


    address[] facetAddressList;
    string[] facetDependencies;

    // deploys diamond and connects facets
    function setUp() public virtual {

        creatAdminAndAccount();

        //deploy facets
        dInit = new DiamondInit();
        dCutFacet = new DiamondCutFacet();
        dLoupe = new DiamondLoupeFacet();
        
        facetDependencies = ["Diamond",
                                "DiamondCutFacet",
                                "DiamondLoupeFacet",
                                "RoleAccessControlFacet",
                                "OrderFacet",
                                "AccountFacet",
                                "PoolFacet",
                                "StakeFacet",
                                "MarketFacet",
                                "MarketManagerFacet",
                                "OracleFacet",
                                "StakingAccountFacet",
                                "FeeFacet",
                                "PositionFacet",
                                "VaultFacet",
                                "LiquidationFacet",
                                "RebalanceFacet",
                                "ConfigFacet",
                                "SwapFacet",
                                "FaucetFacet",
                                "ReferralFacet"
                                ];
    
        // deploy diamond
        diamond = new Diamond(address(dCutFacet), address(dLoupe), address(dInit), developer );

        deployDiamondFacets();
        //tokens
        deployMockTokens();
        giveUserMockTokens();

        //roles
        configAccountRoal();

        //vaults
        deployAndConfigVaults();

        //config markets
        configMarket();

        //config common
        configCommon();
        
    }

    function deployDiamondFacets() internal{
        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](facetDependencies.length - 3);

        cut[0] = (
        FacetCut({
        facetAddress: address(new RoleAccessControlFacet()),
        action: FacetCutAction.Add,
        functionSelectors: generateSelectors("RoleAccessControlFacet")
        })
        );

         cut[1] = (
        FacetCut({
        facetAddress: address(new OrderFacet()),
        action: FacetCutAction.Add,
        functionSelectors: generateSelectors("OrderFacet")
        })
        );

        cut[2] = (
        FacetCut({
        facetAddress: address(new AccountFacet()),
        action: FacetCutAction.Add,
        functionSelectors: generateSelectors("AccountFacet")
        })
        );

        cut[3] = (
        FacetCut({
        facetAddress: address(new PoolFacet()),
        action: FacetCutAction.Add,
        functionSelectors: generateSelectors("PoolFacet")
        })
        );

        cut[4] = (
        FacetCut({
        facetAddress: address(new StakeFacet()),
        action: FacetCutAction.Add,
        functionSelectors: generateSelectors("StakeFacet")
        })
        );

        cut[5] = (
        FacetCut({
        facetAddress: address(new MarketFacet()),
        action: FacetCutAction.Add,
        functionSelectors: generateSelectors("MarketFacet")
        })
        );

        cut[6] = (
        FacetCut({
        facetAddress: address(new MarketManagerFacet()),
        action: FacetCutAction.Add,
        functionSelectors: generateSelectors("MarketManagerFacet")
        })
        );

        cut[7] = (
        FacetCut({
        facetAddress: address(new OracleFacet()),
        action: FacetCutAction.Add,
        functionSelectors: generateSelectors("OracleFacet")
        })
        );

        cut[8] = (
        FacetCut({
        facetAddress: address(new StakingAccountFacet()),
        action: FacetCutAction.Add,
        functionSelectors: generateSelectors("StakingAccountFacet")
        })
        );

        cut[9] = (
        FacetCut({
        facetAddress: address(new FeeFacet()),
        action: FacetCutAction.Add,
        functionSelectors: generateSelectors("FeeFacet")
        })
        );

          

          cut[10] = (
        FacetCut({
        facetAddress: address(new PositionFacet()),
        action: FacetCutAction.Add,
        functionSelectors: generateSelectors("PositionFacet")
        })
        );

          cut[11] = (
        FacetCut({
        facetAddress: address(new VaultFacet()),
        action: FacetCutAction.Add,
        functionSelectors: generateSelectors("VaultFacet")
        })
        );

          cut[12] = (
        FacetCut({
        facetAddress: address(new LiquidationFacet()),
        action: FacetCutAction.Add,
        functionSelectors: generateSelectors("LiquidationFacet")
        })
        );

          cut[13] = (
        FacetCut({
        facetAddress: address(new RebalanceFacet()),
        action: FacetCutAction.Add,
        functionSelectors: generateSelectors("RebalanceFacet")
        })
        );

        cut[14] = (
        FacetCut({
        facetAddress: address(new ConfigFacet()),
        action: FacetCutAction.Add,
        functionSelectors: generateSelectors("ConfigFacet")
        })
        );

          cut[15] = (
        FacetCut({
        facetAddress: address(new SwapFacet()),
        action: FacetCutAction.Add,
        functionSelectors: generateSelectors("SwapFacet")
        })
        );


          cut[16] = (
        FacetCut({
        facetAddress: address(new FaucetFacet()),
        action: FacetCutAction.Add,
        functionSelectors: generateSelectors("FaucetFacet")
        })
        );


          cut[17] = (
        FacetCut({
        facetAddress: address(new ReferralFacet()),
        action: FacetCutAction.Add,
        functionSelectors: generateSelectors("ReferralFacet")
        })
        );

        
        vm.prank(developer);
        //upgrade diamond
        DiamondCutFacet(address(diamond)).diamondCut(cut, address(0x0), "");

        // get all addresses
        facetAddressList = DiamondLoupeFacet(address(diamond)).facetAddresses();

    }

    function deployMockTokens() internal{
        console2.log('deploy MockTokens start....');
        vm.startPrank(developer);

        weth = new WETH();
        weth.mint(developer, 1000000000e18);

        wbtc = address(new MockToken("wbtc",18));
        MockToken(payable(wbtc)).mint(developer, 1000000000e18);

        usdc = payable(address(new MockToken("usdc",6)));
        MockToken(payable(usdc)).mint(developer, 1000000000e6);

        sol = address(new MockToken("sol",9));
         MockToken(payable(sol)).mint(developer, 1000000000e9);
        vm.stopPrank();
        console2.log('deploy MockTokens end....');
    }

    function giveUserMockTokens() internal{
        vm.startPrank(developer);
        weth.transfer(user0, 100e18);
        weth.transfer(user1, 100e18);
        weth.transfer(account0, 100e18);
        weth.transfer(account1, 100e18);
        MockToken(payable(usdc)).transfer(account0, 10000e6);
        MockToken(payable(usdc)).transfer(account1, 10000e6);
        MockToken(payable(usdc)).transfer(user0, 10000e6);
        MockToken(payable(usdc)).transfer(user1, 10000e6);
        vm.stopPrank();

        deal(user0, 100e18);
        deal(user1, 100e18);
        deal(developer, 100e18);
        deal(account0, 100e18);
        deal(account1, 100e10);
    }

    function deployAndConfigVaults() internal{
        
        vm.startPrank(developer);
        console2.log('develop vault  start....');
        lpVault = Vault(new LpVault(developer));
        tradeVault = Vault(new TradeVault(developer));
        portfolioVault = Vault(new PortfolioVault(developer));
        console2.log('develop vault  end....');

        console2.log('config vault role start....');
        lpVault.grantAdmin(address(diamond));
        tradeVault.grantAdmin(address(diamond));
        portfolioVault.grantAdmin(address(diamond));
        console2.log('config vault role end....');

        console2.log('config diamond vault  start....');

        ConfigFacet configFacet = ConfigFacet(address(diamond));

        IConfig.VaultConfigParams memory params = IConfig.VaultConfigParams(
            address(lpVault), address(tradeVault), address(portfolioVault));

        configFacet.setVaultConfig(params);
        

        console2.log('config diamond vault  end....');

        vm.stopPrank();
        
    }
    //create accounts
    function creatAdminAndAccount() internal{
         admin =  makeAddr("admin");
        developer = makeAddr("developer");
        console2.log(admin);
        account0 = makeAddr("account0");
        account1 = makeAddr("account1");
        account2 = makeAddr("account2");

        user0 = makeAddr("user0");
        user1 = makeAddr("user1");

    }

    //config account roal
    function configAccountRoal() internal{

        vm.startPrank(developer);
        RoleAccessControlFacet roleFacet = RoleAccessControlFacet(address(diamond));
        roleFacet.grantRole(developer, RoleAccessControl.ROLE_KEEPER);
        roleFacet.grantRole(developer, RoleAccessControl.ROLE_CONFIG);

        roleFacet.grantRole(account0, RoleAccessControl.ROLE_KEEPER);
        roleFacet.grantRole(account0, RoleAccessControl.ROLE_CONFIG);

        roleFacet.grantRole(account1, RoleAccessControl.ROLE_KEEPER);
        roleFacet.grantRole(account1, RoleAccessControl.ROLE_CONFIG);

        roleFacet.grantRole(account2, RoleAccessControl.ROLE_KEEPER);
        roleFacet.grantRole(account2, RoleAccessControl.ROLE_CONFIG);
        vm.stopPrank();
        console2.log('config  roles end....');
    }

    //config market
    function configMarket() internal{
   
        //string memory marketSymbol = "ETHUSD";
        
        console2.log("config market start" ,marketSymbol);
        MarketManagerFacet  marketManagerFacet = MarketManagerFacet(address(diamond));  
        
        vm.startPrank(developer);
        MarketFactoryProcess.CreateMarketParams memory params = MarketFactoryProcess.CreateMarketParams(
            marketSymbolCodeETH,
            "xETH",
            address(weth),
            address(weth));
        
        
        marketManagerFacet.createMarket(params);
        console2.log("created market end " ,marketSymbol);

        MarketFacet marketFacet = MarketFacet(address(diamond));
        IMarket.SymbolInfo memory symbolInfo = marketFacet.getSymbol(marketSymbolCodeETH);

        vm.stopPrank();

        xEth = symbolInfo.stakeToken;

        configMarketPool(symbolInfo.stakeToken);
        //config sympol
        setSymbolConfig();
        console2.log("config market end" ,marketSymbol);

        //usdPool
        createAndConfigUsdPool();

     }

    //config market pool
    function configMarketPool(address stakeToken) internal{
       
        AppPoolConfig.LpPoolConfig memory config = AppPoolConfig.LpPoolConfig({
            assetTokens: new address[](1),
            baseInterestRate: 6250000000,
            poolLiquidityLimit: 80000,
            mintFeeRate: 120,
            redeemFeeRate: 150,
            poolPnlRatioLimit: 0,
            //collateralStakingRatioLimit: 0, //@audit 没有使用了，是为什么？
            unsettledBaseTokenRatioLimit: 0,
            unsettledStableTokenRatioLimit: 0,
            poolStableTokenRatioLimit: 0,
            poolStableTokenLossLimit: 0
          }); 
        config.assetTokens[0] = address(weth);
       

        IConfig.LpPoolConfigParams memory params;
        params.stakeToken = stakeToken;
        params.config = config;

        ConfigFacet configFacet = ConfigFacet(address(diamond));
        console2.log("config pool start");
        vm.prank(developer);
        configFacet.setPoolConfig(params);
    
        console2.log("config pool end");

    }

    function setSymbolConfig() internal{

        AppConfig.SymbolConfig memory config = AppConfig.SymbolConfig({
                tickSize: 1000000,
        maxLeverage: 2000000,
        openFeeRate: 110,
        closeFeeRate: 130,
        maxLongOpenInterestCap: 10000000000000000000000000,
        maxShortOpenInterestCap: 10000000000000000000000000,
        longShortRatioLimit: 50000,
        longShortOiBottomLimit: 100000000000000000000000
        });
        IConfig.SymbolConfigParams memory params;
        params.symbol = marketSymbolCodeETH;
        params.config = config;
    

        ConfigFacet configFacet = ConfigFacet(address(diamond));
        console2.log("config symbol start ETHUSD");

        vm.prank(developer);
        configFacet.setSymbolConfig(params);

        console2.log("config symbol end ETHUSD");
    }

    //config common
    function configCommon() internal {

        console2.log("config common start");
        IConfig.CommonConfigParams memory params;
        AppConfig.ChainConfig memory chainConfig = AppConfig.ChainConfig({
            wrapperToken: address(weth),
            mintGasFeeLimit: 1500000,
            redeemGasFeeLimit: 1500000,
            placeIncreaseOrderGasFeeLimit: 1500000,
            placeDecreaseOrderGasFeeLimit: 1500000,
            positionUpdateMarginGasFeeLimit: 1500000,
            positionUpdateLeverageGasFeeLimit: 1500000,
            withdrawGasFeeLimit: 1500000,
            claimRewardsGasFeeLimit: 1500000
        });

        AppTradeConfig.TradeConfig memory tradeConfig = AppTradeConfig.TradeConfig({
            tradeTokens: new address[](2),
            tradeTokenConfigs: new AppTradeTokenConfig.TradeTokenConfig[](2) ,
            minOrderMarginUSD: 10000000000000000000,
            availableCollateralRatio: 120000,
            crossLtvLimit: 120000,
            maxMaintenanceMarginRate: 1000,
            fundingFeeBaseRate: 20000000000,
            maxFundingBaseRate: 200000000000,
            tradingFeeStakingRewardsRatio: 27000,
            tradingFeePoolRewardsRatio: 63000,
            tradingFeeUsdPoolRewardsRatio: 10000,
            borrowingFeeStakingRewardsRatio: 27000,
            borrowingFeePoolRewardsRatio: 63000,
            autoReduceProfitFactor: 0,
            autoReduceLiquidityFactor: 0,
            swapSlipperTokenFactor: 5000
        });

        tradeConfig.tradeTokens[0] = address(weth);
        tradeConfig.tradeTokens[1] = usdc;

         tradeConfig.tradeTokenConfigs[0] = AppTradeTokenConfig.TradeTokenConfig({
            isSupportCollateral: true,
            precision: 6,
            discount: 99000,
            collateralUserCap: 10000000000000000000,
            collateralTotalCap: 10000000000000000000000,
            liabilityUserCap: 100000000000000000,
            liabilityTotalCap: 5000000000000000000,
            interestRateFactor: 10,
            liquidationFactor: 5000
            });

        tradeConfig.tradeTokenConfigs[1] = AppTradeTokenConfig.TradeTokenConfig({
            isSupportCollateral: true,
            precision: 2,
            discount: 99000,
            collateralUserCap: 200000000000,
            collateralTotalCap: 200000000000000,
            liabilityUserCap: 5000000000,
            liabilityTotalCap: 1000000000000,
            interestRateFactor: 10,
            liquidationFactor: 5000
            });


    
        AppPoolConfig.StakeConfig memory stakeConfig = AppPoolConfig.StakeConfig({
            minPrecisionMultiple: 11,
            collateralProtectFactor: 500,
            collateralFactor: 5000,
            mintFeeStakingRewardsRatio: 27000,
            mintFeePoolRewardsRatio: 63000,
            redeemFeeStakingRewardsRatio: 27000,
            redeemFeePoolRewardsRatio: 63000,
            poolRewardsIntervalLimit: 0,
            minApr: 20000,
            maxApr: 2000000
            });


        params.chainConfig = chainConfig;
        params.tradeConfig = tradeConfig;
        params.stakeConfig = stakeConfig;
        params.uniswapRouter = address(0);    


        ConfigFacet configFacet = ConfigFacet(address(diamond));
        vm.prank(developer);
        configFacet.setConfig(params);

        console2.log("config common end");

    }

    //create and config usdPoll
    function createAndConfigUsdPool() internal{
        console2.log("create usdPool start");
        PoolFacet poolFacet = PoolFacet(address(diamond));
        IPool.UsdPoolInfo memory usdPoolInfo = poolFacet.getUsdPool();
        console2.log("usdPool stable Tokens number is ", usdPoolInfo.stableTokens.length);
        
        MarketManagerFacet  marketManagerFacet = MarketManagerFacet(address(diamond));  
        ConfigFacet configFacet = ConfigFacet(address(diamond));

        //create usdPool
        vm.startPrank(developer);
        xUSD = marketManagerFacet.createStakeUsdPool("xUSD", usdDecimals);
        console2.log("create usdPool end");

        IConfig.UsdPoolConfigParams memory params;
        AppPoolConfig.UsdPoolConfig memory config = AppPoolConfig.UsdPoolConfig(
            {
                poolLiquidityLimit: 80000,
                mintFeeRate: 10,
                redeemFeeRate: 10,
                unsettledRatioLimit: 0,
                supportStableTokens: new address[](1),
                stableTokensBorrowingInterestRate: new uint256[](1)
            }
        );
        config.supportStableTokens[0] = usdc;
        config.stableTokensBorrowingInterestRate[0] = 625000000;
        params.config = config;
        //config
        configFacet.setUsdPoolConfig(params);
        vm.stopPrank();

        console2.log("config usdPool end");
        
    }


    // function test1HasThreeFacets() public {
    //     assertEq(facetAddressList.length, facetDependencies.length - 1);
    // }

   


}