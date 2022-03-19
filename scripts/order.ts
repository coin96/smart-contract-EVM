import { ethers } from "hardhat";
import { BigNumber } from "bignumber.js";
import { Contract, Wallet, utils } from "ethers";

let ORDER_STRUCTRUE = [
  { name: "perp", type: "address" },
  { name: "paperAmount", type: "int256" },
  { name: "creditAmount", type: "int256" },
  { name: "makerFeeRate", type: "int128" },
  { name: "takerFeeRate", type: "int128" },
  { name: "signer", type: "address" },
  { name: "orderSender", type: "address" },
  { name: "expiration", type: "uint256" },
  { name: "salt", type: "uint256" },
];

interface Order {
  perp: string;
  paperAmount: string;
  creditAmount: string;
  makerFeeRate: string;
  takerFeeRate: string;
  signer: string;
  orderSender: string;
  expiration: string;
  salt: string;
}

export interface OrderEnv {
  makerFeeRate: string;
  takerFeeRate: string;
  orderSender: string;
  dealerAddress: string;
  EIP712domain: string;
}

export async function getDefaultOrderEnv(dealer: Contract): Promise<OrderEnv> {
  let dealerOwner = await dealer.owner();
  let domain = (await dealer.state()).domainSeparator;
  return {
    makerFeeRate: utils.parseEther("0.0001").toString(),
    takerFeeRate: utils.parseEther("0.0005").toString(),
    orderSender: dealerOwner,
    dealerAddress: dealer.address,
    EIP712domain: domain,
  };
}

export async function buildOrder(
  orderEnv: OrderEnv,
  perpAddress: string,
  paperAmount: string,
  creditAmount: string,
  signer: Wallet
): Promise<{ order: Order; hash: string; signature: string }> {
  let chainid = await signer.getChainId();
  let domain = {
    name: "JOJO",
    version: "1",
    chainId: chainid,
    verifyingContract: orderEnv.dealerAddress,
  };
  let order: Order = {
    perp: perpAddress,
    paperAmount: paperAmount,
    creditAmount: creditAmount,
    makerFeeRate: orderEnv.makerFeeRate,
    takerFeeRate: orderEnv.takerFeeRate,
    signer: signer.address,
    orderSender: orderEnv.orderSender,
    expiration: Math.floor(
      new Date().getTime() / 1000 + 60 * 60 * 24 * 10
    ).toFixed(0),
    salt: Math.round(Math.random() * Date.now()) + "",
  };
  let types = {
    Order: ORDER_STRUCTRUE,
  };

  const hash = ethers.utils._TypedDataEncoder.hash(domain, types, order);
  const signature = await signer._signTypedData(domain, types, order);

  return { order: order, hash: hash, signature: signature };
}

export function encodeTradeData(
  orderList: Order[],
  signatureList: string[],
  matchAmountList: string[]
): string {
  let abiCoder = new ethers.utils.AbiCoder();
  return abiCoder.encode(
    [
      "tuple(address perp, int256 paperAmount, int256 creditAmount, int128 makerFeeRate, int128 takerFeeRate, address signer, address orderSender, uint256 expiration, uint256 salt)[]",
      "bytes[]",
      "uint256[]",
    ],
    [orderList, signatureList, matchAmountList]
  );
}
