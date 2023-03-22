const { ethers } = require("hardhat");
const { expect } = require('chai');
const { BigNumber } = require("@ethersproject/bignumber");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("Scarab DAO", async () => {
    async function deployFixture() {
        let owner, addr1, addr2, addr3, addr4, scarab, scarabContract, nft, nftContract, wbnb, router, treasury, dao,  daoContract, WETH;
        let routerAddress = "0x10ED43C718714eb63d5aA57B78B54704E256024E";
        let WETHAddress = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";
        let WETHABI = [
            {"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"guy","type":"address"},{"name":"wad","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"src","type":"address"},{"name":"dst","type":"address"},{"name":"wad","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"wad","type":"uint256"}],"name":"withdraw","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"dst","type":"address"},{"name":"wad","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[],"name":"deposit","outputs":[],"payable":true,"stateMutability":"payable","type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"},{"name":"","type":"address"}],"name":"allowance","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"payable":true,"stateMutability":"payable","type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"src","type":"address"},{"indexed":true,"name":"guy","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"src","type":"address"},{"indexed":true,"name":"dst","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"dst","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Deposit","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"src","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Withdrawal","type":"event"}
        ];
        let routerABI = [
            {"inputs":[{"internalType":"address","name":"_factory","type":"address"},{"internalType":"address","name":"_WETH","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"WETH","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"tokenA","type":"address"},{"internalType":"address","name":"tokenB","type":"address"},{"internalType":"uint256","name":"amountADesired","type":"uint256"},{"internalType":"uint256","name":"amountBDesired","type":"uint256"},{"internalType":"uint256","name":"amountAMin","type":"uint256"},{"internalType":"uint256","name":"amountBMin","type":"uint256"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"addLiquidity","outputs":[{"internalType":"uint256","name":"amountA","type":"uint256"},{"internalType":"uint256","name":"amountB","type":"uint256"},{"internalType":"uint256","name":"liquidity","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"amountTokenDesired","type":"uint256"},{"internalType":"uint256","name":"amountTokenMin","type":"uint256"},{"internalType":"uint256","name":"amountETHMin","type":"uint256"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"addLiquidityETH","outputs":[{"internalType":"uint256","name":"amountToken","type":"uint256"},{"internalType":"uint256","name":"amountETH","type":"uint256"},{"internalType":"uint256","name":"liquidity","type":"uint256"}],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"factory","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountOut","type":"uint256"},{"internalType":"uint256","name":"reserveIn","type":"uint256"},{"internalType":"uint256","name":"reserveOut","type":"uint256"}],"name":"getAmountIn","outputs":[{"internalType":"uint256","name":"amountIn","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountIn","type":"uint256"},{"internalType":"uint256","name":"reserveIn","type":"uint256"},{"internalType":"uint256","name":"reserveOut","type":"uint256"}],"name":"getAmountOut","outputs":[{"internalType":"uint256","name":"amountOut","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountOut","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"}],"name":"getAmountsIn","outputs":[{"internalType":"uint256[]","name":"amounts","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountIn","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"}],"name":"getAmountsOut","outputs":[{"internalType":"uint256[]","name":"amounts","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountA","type":"uint256"},{"internalType":"uint256","name":"reserveA","type":"uint256"},{"internalType":"uint256","name":"reserveB","type":"uint256"}],"name":"quote","outputs":[{"internalType":"uint256","name":"amountB","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"tokenA","type":"address"},{"internalType":"address","name":"tokenB","type":"address"},{"internalType":"uint256","name":"liquidity","type":"uint256"},{"internalType":"uint256","name":"amountAMin","type":"uint256"},{"internalType":"uint256","name":"amountBMin","type":"uint256"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"removeLiquidity","outputs":[{"internalType":"uint256","name":"amountA","type":"uint256"},{"internalType":"uint256","name":"amountB","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"liquidity","type":"uint256"},{"internalType":"uint256","name":"amountTokenMin","type":"uint256"},{"internalType":"uint256","name":"amountETHMin","type":"uint256"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"removeLiquidityETH","outputs":[{"internalType":"uint256","name":"amountToken","type":"uint256"},{"internalType":"uint256","name":"amountETH","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"liquidity","type":"uint256"},{"internalType":"uint256","name":"amountTokenMin","type":"uint256"},{"internalType":"uint256","name":"amountETHMin","type":"uint256"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"removeLiquidityETHSupportingFeeOnTransferTokens","outputs":[{"internalType":"uint256","name":"amountETH","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"liquidity","type":"uint256"},{"internalType":"uint256","name":"amountTokenMin","type":"uint256"},{"internalType":"uint256","name":"amountETHMin","type":"uint256"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"bool","name":"approveMax","type":"bool"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"removeLiquidityETHWithPermit","outputs":[{"internalType":"uint256","name":"amountToken","type":"uint256"},{"internalType":"uint256","name":"amountETH","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"liquidity","type":"uint256"},{"internalType":"uint256","name":"amountTokenMin","type":"uint256"},{"internalType":"uint256","name":"amountETHMin","type":"uint256"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"bool","name":"approveMax","type":"bool"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"removeLiquidityETHWithPermitSupportingFeeOnTransferTokens","outputs":[{"internalType":"uint256","name":"amountETH","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"tokenA","type":"address"},{"internalType":"address","name":"tokenB","type":"address"},{"internalType":"uint256","name":"liquidity","type":"uint256"},{"internalType":"uint256","name":"amountAMin","type":"uint256"},{"internalType":"uint256","name":"amountBMin","type":"uint256"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"bool","name":"approveMax","type":"bool"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"removeLiquidityWithPermit","outputs":[{"internalType":"uint256","name":"amountA","type":"uint256"},{"internalType":"uint256","name":"amountB","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountOut","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"swapETHForExactTokens","outputs":[{"internalType":"uint256[]","name":"amounts","type":"uint256[]"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountOutMin","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"swapExactETHForTokens","outputs":[{"internalType":"uint256[]","name":"amounts","type":"uint256[]"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountOutMin","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"swapExactETHForTokensSupportingFeeOnTransferTokens","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountIn","type":"uint256"},{"internalType":"uint256","name":"amountOutMin","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"swapExactTokensForETH","outputs":[{"internalType":"uint256[]","name":"amounts","type":"uint256[]"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountIn","type":"uint256"},{"internalType":"uint256","name":"amountOutMin","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"swapExactTokensForETHSupportingFeeOnTransferTokens","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountIn","type":"uint256"},{"internalType":"uint256","name":"amountOutMin","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"swapExactTokensForTokens","outputs":[{"internalType":"uint256[]","name":"amounts","type":"uint256[]"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountIn","type":"uint256"},{"internalType":"uint256","name":"amountOutMin","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"swapExactTokensForTokensSupportingFeeOnTransferTokens","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountOut","type":"uint256"},{"internalType":"uint256","name":"amountInMax","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"swapTokensForExactETH","outputs":[{"internalType":"uint256[]","name":"amounts","type":"uint256[]"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amountOut","type":"uint256"},{"internalType":"uint256","name":"amountInMax","type":"uint256"},{"internalType":"address[]","name":"path","type":"address[]"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"swapTokensForExactTokens","outputs":[{"internalType":"uint256[]","name":"amounts","type":"uint256[]"}],"stateMutability":"nonpayable","type":"function"},{"stateMutability":"payable","type":"receive"}
        ];
        // 
        [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
        router = await ethers.getContractAt(routerABI, routerAddress);
        WETH = await ethers.getContractAt(WETHABI, WETHAddress);
        scarab = await ethers.getContractFactory("Scarab");
        scarabContract = await scarab.deploy();
        await scarabContract.deployed();
        treasury = await ethers.getContractFactory("Treasury");
        treasuryContract = await treasury.deploy(scarabContract.address, routerAddress);
        await treasuryContract.deployed();

        nft = await ethers.getContractFactory("ScarabNft");
        nftContract = await nft.deploy(scarabContract.address);
        await nftContract.deployed();
        dao = await ethers.getContractFactory("Dao");
        daoContract = await dao.deploy(scarabContract.address, nftContract.address, treasuryContract.address);
        await daoContract.deployed();
    
        console.log("Router Contract Address :- ", router.address);
        console.log("owner balance :- ",await owner.getBalance());
        console.log("Scarab Contract Address :- ", scarabContract.address);
        console.log("Treasury Contract Address :- ",treasuryContract.address);

        return { owner, addr1, addr2, addr3, addr4, scarab, scarabContract, nft, nftContract, wbnb, router, dao, daoContract, treasury, treasuryContract, WETH };
    }
    it("1. should transfer scarab tokens to treasury Contract", async() => {
        let { scarabContract, treasuryContract } = await loadFixture(deployFixture);
        console.log("Treasury Contract Before Scarab Token Balance :- ",await scarabContract.balanceOf(treasuryContract.address));
        await scarabContract.setTreasuryAddress(treasuryContract.address);
        await scarabContract.transfer(treasuryContract.address, BigNumber.from("4000000000000000000"));
        expect(await scarabContract.balanceOf(treasuryContract.address)).to.equal(BigNumber.from("4000000000000000000"));
        console.log("Treasury Contract After Scarab Token Balance :- ",await scarabContract.balanceOf(treasuryContract.address));
    });
    it("2. should addLiquidity of scarab and wbnb", async () => {
        let { owner, scarabContract, router } = await loadFixture(deployFixture);
        const block = await ethers.provider.getBlock();
        const timestamp = block.timestamp;
        await scarabContract.approve(router.address, BigNumber.from("10000000000000000000"));
        await router.addLiquidityETH(
            scarabContract.address,  
            BigNumber.from("10000000000000000000"),
            10, 
            10, 
            owner.address,
            timestamp + 120,
            {
                value: ethers.utils.parseEther("10")
            }
        );
    });
    it("3. should swap scarab tokens into eth", async() => {
        let { scarabContract, router, owner, treasuryContract } = await loadFixture(deployFixture);
        await scarabContract.setTreasuryAddress(treasuryContract.address);
        await scarabContract.transfer(treasuryContract.address, BigNumber.from("4000000000000000000"));
        console.log("scarab balance Treasury:- ",await scarabContract.balanceOf(treasuryContract.address));
        // console.log("scarab balance Owner:- ",await scarabContract.balanceOf(owner.address));

        const block = await ethers.provider.getBlock();
        const timestamp = block.timestamp;
        await scarabContract.approve(router.address, BigNumber.from("10000000000000000000"));
        await router.addLiquidityETH(
            scarabContract.address,  
            BigNumber.from("10000000000000000000"),
            10, 
            10, 
            owner.address,
            timestamp + 120,
            {
                value: ethers.utils.parseEther("10")
            }
        );
        console.log("Before- owner balance :- ",await owner.getBalance());
        treasuryContract.executeSwap();
        console.log("After- owner balance :- ",await owner.getBalance());
    });
    it("4. transfer fund from treaury to Dao", async () => {
        let { scarabContract, router, owner, treasuryContract, addr1, addr2, addr3, daoContract, nftContract, WETH } = await loadFixture(deployFixture);
        await scarabContract.setTreasuryAddress(treasuryContract.address);
        await scarabContract.transfer(treasuryContract.address, BigNumber.from("4000000000000000000"));
        console.log("scarab balance Treasury:- ",await scarabContract.balanceOf(treasuryContract.address));
        const block = await ethers.provider.getBlock();
        const timestamp = block.timestamp;
        await scarabContract.approve(router.address, BigNumber.from("10000000000000000000"));
        await router.addLiquidityETH(
            scarabContract.address,  
            BigNumber.from("10000000000000000000"),
            10, 
            10, 
            owner.address,
            timestamp + 120,
            {
                value: ethers.utils.parseEther("10")
            }
        );
        // treasuryContract.executeSwap();
        // console.log("Treasury Balance:-", await ethers.provider.getBalance(treasuryContract.address));
        await scarabContract.mint(addr1.address, 100);
        await scarabContract.mint(addr2.address, 100);
        console.log("3.1");
        await scarabContract.setWhitelistAddress(nftContract.address, true);
        await scarabContract.setWhitelistAddress(treasuryContract.address, true);
        await scarabContract.setWhitelistAddress(daoContract.address, true);
        console.log("3.1");
        console.log("before convert- scarab balance of addr1 : ",await scarabContract.connect(addr1).balanceOf(addr1.address));
        await scarabContract.connect(addr1).approve(nftContract.address, 100);
        console.log("3.1.1");
        await nftContract.connect(addr1).lockTokensAndMintNft(100, { gasLimit: 500000, });
        console.log("after convert- scarab balance of addr1 : ",await scarabContract.connect(addr1).balanceOf(addr1.address));
        console.log("after convert- scarab balance of nftcontract : ",await scarabContract.connect(owner).balanceOf(nftContract.address));
        
        console.log("3.2");
        expect(await nftContract.connect(addr1).ownerOf(1)).to.equal(addr1.address);
        expect(await nftContract.connect(addr1).balanceOf(addr1.address)).to.equal(1);
        console.log("3.3");
        daoContract.connect(addr1).createProposal('gggg',addr1.address,'pppp','dddd',10000);
        console.log("3.4");
        await scarabContract.connect(addr2).approve(daoContract.address, 2);
        await daoContract.connect(addr2).vote(1, true);
        console.log("3.4.1");
        console.log("Addr2 voted for proposal id 1 is true or false : ",await daoContract.getVoteforProposal(addr2.address, 1));
        console.log(" Proposals Details :- ", await daoContract.proposals(1));
        console.log("3.5");
        // console.log("after vote- scarab balance of addr2 : ",await scarabContract.connect(addr2).balanceOf(addr2.address));
        await network.provider.send("evm_increaseTime", [120]);
        console.log("Before- contract balance :- ",await ethers.provider.getBalance(addr1.address));
        await daoContract.executeProposal(1,{ gasLimit: 500000, });
        console.log("dao contract eth bal : a",await WETH.balanceOf(treasuryContract.address));
        console.log("After- contract balance :- ",await ethers.provider.getBalance(addr1.address));

        await nftContract.connect(addr1).unlockTokens(1, { gasLimit: 500000, });
        console.log("after- scarab balance of addr1 : ",await scarabContract.connect(addr1).balanceOf(addr1.address));
    });
    it("5. transfer fund from treaury to Dao", async () => {
        let { scarabContract, router, owner, treasuryContract, addr1, addr2, addr3, daoContract, nftContract, WETH } = await loadFixture(deployFixture);
        await scarabContract.setTreasuryAddress(treasuryContract.address);
        await scarabContract.transfer(treasuryContract.address, BigNumber.from("4000000000000000000"));
        console.log("scarab balance Treasury:- ",await scarabContract.balanceOf(treasuryContract.address));
        const block = await ethers.provider.getBlock();
        const timestamp = block.timestamp;
        await scarabContract.approve(router.address, BigNumber.from("10000000000000000000"));
        await router.addLiquidityETH(
            scarabContract.address,  
            BigNumber.from("10000000000000000000"),
            10, 
            10, 
            owner.address,
            timestamp + 120,
            {
                value: ethers.utils.parseEther("10")
            }
        );
        // treasuryContract.executeSwap();
        // console.log("Treasury Balance:-", await ethers.provider.getBalance(treasuryContract.address));
        await scarabContract.mint(addr1.address, 100);
        await scarabContract.mint(addr2.address, 100);
        console.log("3.1");
        await scarabContract.setWhitelistAddress(nftContract.address, true);
        await scarabContract.setWhitelistAddress(treasuryContract.address, true);
        await scarabContract.setWhitelistAddress(daoContract.address, true);
        console.log("3.1");
        console.log("before convert- scarab balance of addr1 : ",await scarabContract.connect(addr1).balanceOf(addr1.address));
        await scarabContract.connect(addr1).approve(nftContract.address, 100);
        console.log("3.1.1");
        await nftContract.connect(addr1).lockTokensAndMintNft(100, { gasLimit: 500000, });
        console.log("after convert- scarab balance of addr1 : ",await scarabContract.connect(addr1).balanceOf(addr1.address));
        console.log("after convert- scarab balance of nftcontract : ",await scarabContract.connect(owner).balanceOf(nftContract.address));
        
        console.log("3.2");
        expect(await nftContract.connect(addr1).ownerOf(1)).to.equal(addr1.address);
        expect(await nftContract.connect(addr1).balanceOf(addr1.address)).to.equal(1);
        console.log("3.3");
        daoContract.connect(addr1).createProposal('gggg',addr1.address,'pppp','dddd',10000);
        console.log("3.4");
        await scarabContract.connect(addr2).approve(daoContract.address, 2);
        await daoContract.connect(addr2).vote(1, true);
        console.log("3.4.1");
        console.log("Addr2 voted for proposal id 1 is true or false : ",await daoContract.getVoteforProposal(addr2.address, 1));
        console.log(" Proposals Details :- ", await daoContract.proposals(1));
        console.log("3.5");
        // console.log("after vote- scarab balance of addr2 : ",await scarabContract.connect(addr2).balanceOf(addr2.address));
        await network.provider.send("evm_increaseTime", [120]);
        console.log("Before- contract balance :- ",await ethers.provider.getBalance(addr1.address));
        await daoContract.executeProposal(1,{ gasLimit: 500000, });
        console.log("dao contract eth bal : a",await WETH.balanceOf(treasuryContract.address));
        console.log("After- contract balance :- ",await ethers.provider.getBalance(addr1.address));

        await nftContract.connect(addr1).unlockTokens(1, { gasLimit: 500000, });
        console.log("after- scarab balance of addr1 : ",await scarabContract.connect(addr1).balanceOf(addr1.address));

        ///////////set daoContractAddress in nftContract and gets ethers from the proposee in dao Contract
        await nftContract.setDaoContractAddress(daoContract.address);
        expect(await nftContract.daoContractAddress()).to.equal(daoContract.address);
        console.log("3.6");
        ///// return the fund amount
        console.log("contract balance before refund", await ethers.provider.getBalance(daoContract.address));
        await daoContract.connect(addr1).settlementFund(1, { value : ethers.utils.parseEther("0.000000000000011"), gasLimit: 50000 });
        console.log("contract balance after refund", await ethers.provider.getBalance(daoContract.address));
        console.log("3.7");

    });
}); 