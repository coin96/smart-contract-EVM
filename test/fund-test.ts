import "./utils/hooks"
import { Wallet, utils } from "ethers";
import { expect } from "chai";
import {
  basicContext,
  Context,
  fundTrader,
  setPrice,
} from "../scripts/context";
import { checkCredit, checkUnderlyingAsset } from "./utils/checkers";
import { timeJump } from "./utils/timemachine";
import { getDefaultOrderEnv, openPosition } from "../scripts/order";

/*
  Test cases list
  - deposit
    - deposit to others
  - set virtual credit
    - increase
    - decrease
  - withdraw
    - withdraw without timelock
    - withdraw with timelock
  - withdrawal can make ture credit negative

  Revert cases list
  - withdraw when being liquidated
  - withdraw when not enough balance
  - can not withdraw virtual credit
*/

describe("Funding", () => {
  let context: Context;
  let trader1: Wallet;
  let trader2: Wallet;
  let trader1Address: string;
  let trader2Address: string;

  beforeEach(async () => {
    context = await basicContext();
    trader1 = context.traderList[0];
    trader2 = context.traderList[1];
    trader1Address = await trader1.getAddress();
    trader2Address = await trader2.getAddress();
  });

  describe("funding",async () => {
    it("deposit", async () => {
      let c = context.dealer.connect(trader1);
  
      // deposit to self
      await c.deposit(utils.parseEther("100000"), trader1Address);
      checkUnderlyingAsset(context, trader1Address, "900000");
      checkUnderlyingAsset(context, context.dealer.address, "100000");
      checkCredit(context, trader1Address, "100000", "0");
  
      // deposit to others
      await c.deposit(utils.parseEther("20000"), trader2Address);
      checkUnderlyingAsset(context, trader2Address, "880000");
      checkUnderlyingAsset(context, context.dealer.address, "120000");
      checkCredit(context, trader2Address, "20000", "0");
    });
  
    it("set virtual credit", async () => {
      await context.dealer.setVirtualCredit(
        trader1Address,
        utils.parseEther("10")
      );
      await context.dealer.setVirtualCredit(
        trader2Address,
        utils.parseEther("20")
      );
      checkCredit(context, trader1Address, "0", "10");
      checkCredit(context, trader2Address, "0", "20");
  
      await context.dealer.setVirtualCredit(
        trader1Address,
        utils.parseEther("5")
      );
      checkCredit(context, trader1Address, "0", "5");
    });
  })

  describe("withdraw", async () => {
    it("without timelock", async () => {
      const state = await context.dealer.state();
      expect(state.withdrawTimeLock).to.equal(utils.parseEther("0"));
      let d = context.dealer.connect(trader1);
      await d.deposit(utils.parseEther("100000"), trader1Address);
      await d.withdraw(utils.parseEther("30000"), trader1Address);
      await d.withdraw(utils.parseEther("70000"), trader2Address);
      checkCredit(context, trader1Address, "0", "0");
      checkUnderlyingAsset(context, trader1Address, "930000");
      checkUnderlyingAsset(context, trader2Address, "1070000");
      checkUnderlyingAsset(context, context.dealer.address, "0");
    });

    it("with timelock", async () => {
      await context.dealer.setWithdrawTimeLock("100");
      const state = await context.dealer.state();
      expect(state.withdrawTimeLock).to.equal("100");
      let d = context.dealer.connect(trader1);
      await d.deposit(utils.parseEther("100000"), trader1Address);
      await d.withdraw(utils.parseEther("30000"), trader1Address);
      checkCredit(context, trader1Address, "100000", "0");
      checkUnderlyingAsset(context, trader1Address, "900000");

      await timeJump(50);
      expect( d.withdrawPendingFund(trader1Address)).to.be.revertedWith(
        "JOJO_WITHDRAW_PENDING"
      );
      await timeJump(10000);
      await d.withdrawPendingFund(trader1Address);
      checkCredit(context, trader1Address, "70000", "0");
      checkUnderlyingAsset(context, trader1Address, "930000");
    });
  });

  describe("Revert cases", async () => {
    it("withdraw when not enough balance", async () => {
      let d = context.dealer.connect(trader1);
      await d.deposit(utils.parseEther("100000"), trader1Address);
      expect(
        d.withdraw(utils.parseEther("100001"), trader1Address)
      ).to.be.revertedWith("JOJO_CREDIT_NOT_ENOUGH");
    });

    it("withdraw when liquidated", async () => {
      await fundTrader(context);
      await openPosition(
        trader1,
        trader2,
        "100",
        "30000",
        context.perpList[0],
        await getDefaultOrderEnv(context.dealer)
      );
      await setPrice(context.priceSourceList[0], "10000");
      expect(await context.dealer.isSafe(trader1.address)).to.be.false;
      expect(
        context.dealer
          .connect(trader1)
          .withdraw(utils.parseEther("1"), trader1.address)
      ).to.be.revertedWith("JOJO_ACCOUNT_NOT_SAFE");
    });

    it("can not withdraw virtual credit",async () => {
      await fundTrader(context)
      await context.dealer.setVirtualCredit(
        trader1.address,
        utils.parseEther("1000000")
      );
      expect(
        context.dealer
          .connect(trader1)
          .withdraw(utils.parseEther("1000001"), trader1.address)
      ).to.be.revertedWith("JOJO_ACCOUNT_NOT_SAFE");
    })
  });
});
