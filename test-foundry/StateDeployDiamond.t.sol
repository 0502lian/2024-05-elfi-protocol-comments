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
import {MarketManagerFacet} from "../contracts/facets/MarketManagerFacet.sol";
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

import {MockToken} from "../contracts/mock/MockToken.sol";
import {WETH} from "../contracts/mock/WETH.sol";

contract StateDeployDiamond is HelperContract {

    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    DiamondInit dInit;
    address public admin;
    address public developer;

    //Tokens    
    WETH public weth;
    address public wbtc;
    address public usdc;
    address public sol;

    //Vaults
    Vault public lpVault;
    Vault public portfolioVault;
    Vault public tradeVault;


    address[] facetAddressList;
    string[] facetDependencies;

    // deploys diamond and connects facets
    function setUp() public virtual {
        admin =  makeAddr("admin");
        developer = makeAddr("developer");
        console2.log(admin);

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
        diamond = new Diamond(address(dCutFacet), address(dLoupe), address(dInit), admin );

        deployDiamondFacets();
        //tokens
        deployMockTokens();
        //vaults
        deployVaults();
        
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

        
        vm.prank(admin);
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

        usdc = address(new MockToken("usdc",6));
        MockToken(payable(usdc)).mint(developer, 1000000000e6);

        sol = address(new MockToken("sol",9));
         MockToken(payable(sol)).mint(developer, 1000000000e9);
        vm.stopPrank();
        console2.log('deploy MockTokens end....');
    }

    function deployVaults() internal{
        console2.log('config vault role start....');
        vm.startPrank(developer);

        lpVault = Vault(new LpVault(developer));
        lpVault.grantAdmin(address(diamond));

        tradeVault = Vault(new TradeVault(developer));
        tradeVault.grantAdmin(address(diamond));

        portfolioVault = Vault(new PortfolioVault(developer));
        portfolioVault.grantAdmin(address(diamond));

        vm.stopPrank();
        console2.log('config vault role end....');
    }

    function test1HasThreeFacets() public {
        assertEq(facetAddressList.length, facetDependencies.length - 1);
    }


}