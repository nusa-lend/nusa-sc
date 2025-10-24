// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

/**
 * @title HelperDeployment
 * @author Nusa Protocol Team
 * @notice Contract containing deployment configuration constants for mainnet deployment
 * @dev This contract stores all the necessary addresses and configuration values for
 *      deploying the Nusa protocol on Base and Arbitrum mainnets. It includes LayerZero
 *      infrastructure addresses, token addresses, and deployed protocol contract addresses.
 * 
 * Key Features:
 * - LayerZero endpoint and library configurations for Base and Arbitrum
 * - DVN (Decentralized Verifier Network) addresses for message verification
 * - Token addresses for stablecoins and tokenized stocks on both chains
 * - Protocol contract addresses for cross-chain reference
 * - Mainnet-ready configuration constants
 */
contract HelperDeployment {
    // =============================================================
    //                    MAINNET CONFIGURATION
    // =============================================================

    // =============================================================
    //                  LAYERZERO INFRASTRUCTURE
    // =============================================================

    /// @notice LayerZero endpoint addresses for cross-chain messaging
    address public BASE_LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address public ARB_LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;

    /// @notice LayerZero send library addresses for outbound messages
    address public BASE_SEND_LIB = 0xB5320B0B3a13cC860893E2Bd79FCd7e13484Dda2;
    address public ARB_SEND_LIB = 0x975bcD720be66659e3EB3C0e4F1866a3020E493A;

    /// @notice LayerZero receive library addresses for inbound messages
    address public BASE_RECEIVE_LIB = 0xc70AB6f32772f59fBfc23889Caf4Ba3376C84bAf;
    address public ARB_RECEIVE_LIB = 0x7B9E184e07a6EE1aC23eAe0fe8D6Be2f663f05e6;

    /// @notice LayerZero endpoint IDs for chain identification
    uint32 public BASE_EID = 30184;
    uint32 public ARB_EID = 30110;

    /// @notice Decentralized Verifier Network (DVN) addresses for Base chain
    address public BASE_DVN1 = 0x554833698Ae0FB22ECC90B01222903fD62CA4B47; // Canary
    address public BASE_DVN2 = 0xa7b5189bcA84Cd304D8553977c7C614329750d99; // Horizen
    address public BASE_DVN3 = 0x9e059a54699a285714207b43B055483E78FAac25; // LayerZeroLabs

    /// @notice Decentralized Verifier Network (DVN) addresses for Arbitrum chain
    address public ARB_DVN1 = 0x19670Df5E16bEa2ba9b9e68b48C054C5bAEa06B8; // Horizen
    address public ARB_DVN2 = 0xf2E380c90e6c09721297526dbC74f870e114dfCb; // Canary
    address public ARB_DVN3 = 0x2f55C492897526677C5B68fb199ea31E2c126416; // LayerZeroLabs

    /// @notice LayerZero executor addresses for message execution
    address public BASE_EXECUTOR = 0x2CCA08ae69E0C44b18a57Ab2A87644234dAebaE4;
    address public ARB_EXECUTOR = 0x31CAe3B7fB82d847621859fb1585353c5720660D;

    // =============================================================
    //                     BASE CHAIN TOKENS
    // =============================================================

    /// @notice Base chain stablecoin and major token addresses
    address public BASE_USDC = 0xe3BaB20B2711e0577C46d14fd10bfFC0961036C3;
    address public BASE_WETH = 0xE29A9fBdf3d83c126C6366D7f401473Ab0850e7F;
    address public BASE_WBTC = 0xEF0CeF5eB4F2B475b00C9Cae5E58065f9f5062E8;
    address public BASE_CADC = 0xca03A4dFE09f664890ee7B46D9Af4F0B6d5f6f15;
    address public BASE_CNGN = 0xED6Cfb1D2F61F75419BaB537Ca1C5351B6a4c017;
    address public BASE_KRWT = 0xD773084B8Cd424AD87D35bE6901255feE285A763;
    address public BASE_TRYB = 0x1D7c9083d76aD235aE44d90Bc13EcA74Ccc2Ed42;
    address public BASE_MXNE = 0xB7e6d4119F5E482D8d68D0AA4c81F14A082Ec917;
    address public BASE_XSGD = 0xef49434AcC92ED24e7d245f748aacDE471A68F06;
    address public BASE_ZARP = 0x5F01296847f20Fc68C79D051AB75Fb9169096F00;
    address public BASE_IDRX = 0x74Ae55CA4EaA2337f309F77A7AF1b60Ea9085FB6;
    address public BASE_EURC = 0xB2B60Bb1e9796cAE4Dc4c87f456db675871b0d2B;

    // Tokenized Stocks
    address public BASE_bIB01 = 0x650776773016488249D90f5CE25bC2f87Bd037e4;
    address public BASE_bCOIN = 0x776E57A6411F734368360BA1c717F5d806CaE7a9;
    address public BASE_bCSPX = 0x18178895c9Fb3b7a5f69295826d8F18Cc3B79453;
    address public BASE_bIBTA = 0xBBA0Ba72349226ba2887583cD7078480B2f02c12;
    address public BASE_bHIGH = 0xf15bA231663f5351F3069C6C72fB117238D66047;
    address public BASE_bTSLA = 0x2D85b61280CfaCb67ca97c874AeeF44Aab16Ba63;
    address public BASE_bGOOGL = 0xdb21725DB0162bf173F41CEBFd5dd5a023b56363;
    address public BASE_bNVDA = 0xaCc509f29746DE5ADf75007aBeb84aF3e101dDD7;
    address public BASE_bMSFT = 0xAB0903D4BB2a7ecEB4cA88d74F3924c3fE0A8DC1;
    address public BASE_bGME = 0x09490E9e625adc21DB63183e9BF43eD3F8630782;
    address public BASE_bZPR1 = 0xc79b05e2962C1d3d9f5FEFE7c5bde9097629989b;

    address public ARB_USDC = 0xC23e60Ac84240ffCe72680652515dfb1435C356b;
    address public ARB_WETH = 0x338802B73DA88D05e1b3A0203092AD43807049Be;
    address public ARB_WBTC = 0xF1839107BECE28De0e83c92911434a18293B45A4;
    address public ARB_CADC = 0x99d19F4Cb938E0aAD646358c20cB9D0CE0A7a945;
    address public ARB_CNGN = 0xA0F8C84E78eabDF241A9fA9Ff6733AB17bB4E7FA;
    address public ARB_KRWT = 0x0B214413CAc3E0B8F356181d7339626FCafff6Bd;
    address public ARB_TRYB = 0xa7f56bc3252c676E43Ff1F3e6780Dbbc7679D7a6;
    address public ARB_MXNE = 0x14954b6a207A4CC908f44354e61997070507fCC4;
    address public ARB_XSGD = 0x1aA55163E448b100ac4541C69cf2b55C909A2bE9;
    address public ARB_ZARP = 0x623Cf9E33F269Fd459467E98a5e12Db4C2FBCAe0;
    address public ARB_IDRX = 0xB4626C50fb6A0019FEECD442310cd1F7395e2148;
    address public ARB_EURC = 0x8d55C23664B46212bC6dC03d03E237988c0d3646;

    // Tokenized Stocks
    address public ARB_bIB01 = 0x43Db7FF630c993f080f315007961756f2b96Fa45;
    address public ARB_bCOIN = 0x2F7c95D1848cb0a5E36DE0D4Db04C4aFe09053dD;
    address public ARB_bCSPX = 0x618942aF15f2Fe6F451bEe0E094D46df39822e74;
    address public ARB_bIBTA = 0xBf374ffDde61Ebf4e19dC0320BD2DeD9De447EB4;
    address public ARB_bHIGH = 0x88D873c00658874996E07E98E84fF89C3Aa314c1;
    address public ARB_bTSLA = 0x7E588B76807B0ADF014c4ceA3d9DF28d4C5E7c80;
    address public ARB_bGOOGL = 0xc75DE9a3c001f6e5f45fb44a11fa7d92E82BAc0E;
    address public ARB_bNVDA = 0x479702c416cbbD2d95F0C5408a961f9870e6EEa5;
    address public ARB_bMSFT = 0x7F7E97A31409ca29F1878E0d1B7068160834739B;
    address public ARB_bGME = 0xE8484F0442707C3DaEC850be6e05a128100A00cD;
    address public ARB_bZPR1 = 0xc6466031bd2CD675D3fb7c7faD17eAF4a8403Fe7;

    address public BASE_TokenDataStream = 0xB113959014d95C555B8A908D794e73478e5509A8;
    address public BASE_Router = 0x23c5462BcD096AbFdFe9A845A9E1Ec06bEa3F81B;
    address public BASE_IsHealthy = 0x9EDF457dB4C061E22CD87d3E4a886CeA967b629B;
    address public BASE_LendingPool = 0xCcc8E12AAf28D69a865e0B93a99fF490f30f9Df2;
    address public BASE_Proxy = 0xC60D72c8Cb53842f15cfFa8A0bb9DbC759E44452;

    address public ARB_TokenDataStream = 0xC0473BD9e466A7E564b9f1A0065f1eFa41966D54;
    address public ARB_Router = 0xcC0563F952FADb3a7D54A448AEB079D7d8F849fa;
    address public ARB_IsHealthy = 0x9383C92c309c4Db56Fa3Ee57a9Eb7ED8c5edDa22;
    address public ARB_LendingPool = 0x2099FDE6100bd4B7a5004a1aE4077bE9469984A8;
    address public ARB_Proxy = 0x7FB63D9Faf99A34bCA04EFd5BA7F75dC6DB37f4D;

    address public BASE_OAppBorrow = 0xC469d792421CD0eF585eab54EF93a6bF4623455E;
    address public ARB_OAppBorrow = 0x8868E3511c2C47AC55106C21f958E6Cf1Cbc1766;

    // *******************
}
