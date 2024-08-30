import { Principal } from "@dfinity/principal";
import type { Identity } from '@dfinity/agent';
import { Ed25519KeyIdentity } from '@dfinity/identity';
import { IDL } from '@dfinity/candid';


import {init as subsinit2 } from '../../src/declarations/subs/subs.did.js';


import {init as testerinit2 } from '../../src/declarations/tester/tester.did.js';


import {
  PocketIc,
  createIdentity,
} from "@hadronous/pic";

import type {
  Actor,
  CanisterFixture
} from "@hadronous/pic";



import {idlFactory as subsIDLFactory } from "../../src/declarations/subs/subs.did.js";
import type {
  _SERVICE as SubsService,
  SubscriptionRequest } from "../../src/declarations/subs/subs.did.d";
export const sub_WASM_PATH = ".dfx/local/canisters/subs/subs.wasm";

import {idlFactory as testerIDLFactory } from "../../src/declarations/tester/tester.did.js";
import type {
  _SERVICE as TesterService } from "../../src/declarations/tester/tester.did.d";
export const tester_WASM_PATH = ".dfx/local/canisters/tester/tester.wasm";

import type {
  _SERVICE as NNSLedgerService,
  Account,
  Icrc1TransferResult

} from "../../src/declarations/nns-ledger/nns-ledger.did.d";
import {
  idlFactory as nnsIdlFactory,
} from "../../src/declarations/nns-ledger/nns-ledger.did.js";
import exp from "constants";


let pic: PocketIc;

let subs_fixture: CanisterFixture<SubsService>;
let nnsledger: Actor<NNSLedgerService>;

const NNS_SUBNET_ID =
  "erfz5-i2fgp-76zf7-idtca-yam6s-reegs-x5a3a-nku2r-uqnwl-5g7cy-tqe";
const nnsLedgerCanisterId = Principal.fromText(
    "ryjl3-tyaaa-aaaaa-aaaba-cai"
  );

const NNS_STATE_PATH = "pic/nns_state/node-100/state";

const admin = createIdentity("admin");
const alice = createIdentity("alice");
const bob = createIdentity("bob");
const charlie = createIdentity("charlie");

console.log("charlie Principal ", charlie.getPrincipal().toText());
const serviceProvider = createIdentity("serviceProvider");
const serviceProvider2 = createIdentity("serviceProvider2");

const base64ToUInt8Array = (base64String: string): Uint8Array => {
  return Buffer.from(base64String, 'base64');
};

const minterPublicKey = 'Uu8wv55BKmk9ZErr6OIt5XR1kpEGXcOSOC1OYzrAwuk=';
const minterPrivateKey =
  'N3HB8Hh2PrWqhWH2Qqgr1vbU9T3gb1zgdBD8ZOdlQnVS7zC/nkEqaT1kSuvo4i3ldHWSkQZdw5I4LU5jOsDC6Q==';

const minterIdentity = Ed25519KeyIdentity.fromKeyPair(
  base64ToUInt8Array(minterPublicKey),
  base64ToUInt8Array(minterPrivateKey),
);

async function awardTokens(actor: Actor<NNSLedgerService>, caller: Identity,  fromSub: Uint8Array | null, to: Account, amount: bigint) : Promise<Icrc1TransferResult> {
  actor.setIdentity(caller);
  let result = await actor.icrc1_transfer({
    memo: [],
    amount: amount,
    fee: [],
    from_subaccount: fromSub ? [fromSub] : [],
    to: to,
    created_at_time: [],
  });
  console.log("transfer result", result);
  return result;
};

async function tickN(x : number) {
  for (let i = 0; i < x; i++) {
    await pic.tick();
  };
}


describe("test subs", () => {
  beforeEach(async () => {
    pic = await PocketIc.create(process.env.PIC_URL,{
      nns: {
          fromPath: NNS_STATE_PATH,
          subnetId: Principal.fromText(NNS_SUBNET_ID),
      },
      system: 2,
    });

    await pic.setTime(new Date(2024, 1, 30).getTime());
    await pic.tick();
    await pic.tick();
    await pic.tick();
    await pic.tick();
    await pic.tick();
    await pic.advanceTime(1000 * 5);


    console.log("pic system", pic.getSystemSubnets());

    await pic.resetTime();
    await pic.tick();

    subs_fixture = await pic.setupCanister<SubsService>({
      idlFactory: subsIDLFactory,
      wasm: sub_WASM_PATH,
      arg: IDL.encode(subsinit2({IDL}), [[]])
    });

    nnsledger = await pic.createActor<NNSLedgerService>(
      nnsIdlFactory,
      nnsLedgerCanisterId
    );
  });


  afterEach(async () => {
    await pic.tearDown();
  });


  
  it(`can call hello world`, async () => {
    subs_fixture.actor.setIdentity(admin);

    const hello = await subs_fixture.actor.hello_world();

    pic.tick();

    console.log("got", hello);

    expect(hello).toBe("Hello World!");
  });

  it(`can create an immediate subscription and the payment is processed`, async () => {

    const alicesub1 = new Uint8Array(Buffer.from("asdcxzvuioashnuiddsfsdedfsdedffe", "utf-8"))

    await awardTokens(nnsledger, minterIdentity, null, {owner : alice.getPrincipal(), subaccount : []}, BigInt(10000000000));
    
    await awardTokens(nnsledger, minterIdentity, null, {owner : alice.getPrincipal(), subaccount : [alicesub1]}, BigInt(10000000000));

    pic.tick();
    await pic.advanceTime(1000); // 24 hours in milliseconds
    await tickN(10);


    // Set the identity to Alice to act on her behalf
    subs_fixture.actor.setIdentity(alice);
    nnsledger.setIdentity(alice);

    console.log("alice", alice.getPrincipal().toText());
    console.log("service provider", serviceProvider.getPrincipal().toText());
    console.log("nns ledger", nnsLedgerCanisterId.toText());
    // Approve the subscription canister to withdraw tokens on behalf of Alice
    const approvalResult = await nnsledger.icrc2_approve({
        from_subaccount: [],
        spender: {
            owner: subs_fixture.canisterId,
            subaccount: []
        },
        amount: BigInt(10000000000000000),
        memo: [],
        created_at_time: [BigInt((await pic.getTime()) * 1000000)],
        expected_allowance: [],
        expires_at: [],
        fee: [BigInt(10000)]
    });

    console.log("approval result", approvalResult);

    
    // Approve the subscription canister to withdraw tokens on behalf of Alice
    const approvalResult2 = await nnsledger.icrc2_approve({
      from_subaccount: [alicesub1],
      spender: {
          owner: subs_fixture.canisterId,
          subaccount: []
      },
      amount: BigInt(10000000000000000),
      memo: [],
      created_at_time: [BigInt((await pic.getTime()) * 1000000)],
      expected_allowance: [],
      expires_at: [],
      fee: [BigInt(10000)]
    });

    console.log("approval result 2t", approvalResult2);

    const approvalResult3 = await nnsledger.icrc2_approve({
      from_subaccount: [],
      spender: {
          owner: subs_fixture.canisterId,
          subaccount: []
      },
      amount: BigInt(10000000000000000),
      memo: [],
      created_at_time: [BigInt((await pic.getTime()) * 1000000)],
      expected_allowance: [],
      expires_at: [],
      fee: [BigInt(10000)]
    });

    console.log("approval result 3", approvalResult3);

    expect(approvalResult).toMatchObject({ Ok: expect.any(BigInt) });


    const addTokenResult = await subs_fixture.actor.add_token(nnsLedgerCanisterId, []);

    console.log("add token result", addTokenResult);

    // Prepare the subscription request
    const subscribeRequest : SubscriptionRequest = [[
      {tokenCanister: nnsLedgerCanisterId},
      {serviceCanister: serviceProvider.getPrincipal()},
      {interval: { Monthly: null }},
      {amountPerInterval: BigInt(1000000)},
    ]];

    console.log("subscribe request", subscribeRequest);

    // Execute the subscription
    const subResult = await subs_fixture.actor.icrc79_subscribe(subscribeRequest);

    console.log("sub result", subResult);

    expect(subResult).toMatchObject([[{ Ok: expect.any(Object) }]]);

    console.log("sub result", subResult);

    console.log("a blob", alicesub1);

    const subscribeRequest2 : SubscriptionRequest = [[
      {tokenCanister: nnsLedgerCanisterId},
      {serviceCanister: serviceProvider2.getPrincipal()},
      {productId: BigInt(1)},
      {interval: { Weekly: null }},
      {targetAccount: {owner : bob.getPrincipal(), subaccount: []}},
      {amountPerInterval: BigInt(2000000)},
      {subaccount: alicesub1},
    ]];

    const subResult2 = await subs_fixture.actor.icrc79_subscribe(subscribeRequest2);

    console.log("sub result2", subResult2);

    const subscribeRequest3 : SubscriptionRequest = [[
      {tokenCanister: nnsLedgerCanisterId},
      {serviceCanister: serviceProvider2.getPrincipal()},
      {productId:BigInt(2)},
      {interval: { Monthly: null }},
      {amountPerInterval: BigInt(2000000)},
    ]];

    const subResult3 = await subs_fixture.actor.icrc79_subscribe(subscribeRequest3);

    

    console.log("sub result3", subResult3);

    // Forward time to ensure the subscription payment is processed
    await pic.advanceTime(1000); // next tick hours in milliseconds
    await tickN(10);

    // Handle retrieving currently pending payments or confirm payment transaction
    const payments = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    console.log(payments, payments.length);
    expect(payments.length).toEqual(3);
    expect(payments[0].ledgerTransactionId).toBeDefined();

    await pic.advanceTime(2_629_800_000 + 1); // A month
    await tickN(20);

    // Handle retrieving currently pending payments or confirm payment transaction
    const payments2 = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    console.log(payments2, payments2.length);
    expect(payments2.length).toEqual(9);
    expect(payments2[0].ledgerTransactionId).toBeDefined();

    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);

    // Handle retrieving currently pending payments or confirm payment transaction
    const payments3 = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    //13 sub 0n
    //53 sub 1n 
    //13 sub 2n
    //79 total

    console.log(payments3, payments3.length);
    expect(payments3.length).toEqual(79);
    expect(payments3[12].ledgerTransactionId).toBeDefined();
    expect(payments3[12].transactionId).toBeDefined();
    expect(payments3[12].feeTransactionId).toBeDefined();

    /////////////
    // Test pagination and filtering for get vendor subscriptions
    /////////////

    const serviceSubs1 = await subs_fixture.actor.icrc79_get_service_subscriptions(serviceProvider.getPrincipal(), [],[],[]);

    console.log("serviceSubs1", serviceSubs1);

    expect(serviceSubs1.length).toEqual(1);

    const serviceSubs2 = await subs_fixture.actor.icrc79_get_service_subscriptions(serviceProvider2.getPrincipal(), [], [], []);

    console.log("serviceSubs2", serviceSubs2);

    expect(serviceSubs2.length).toEqual(2);

    const serviceSubs3 = await subs_fixture.actor.icrc79_get_service_subscriptions(serviceProvider2.getPrincipal(), [{
      products: [[[1n]]],
      status: [],
      subscriptions: [],
    }], [], []);

    console.log("serviceSubs3", serviceSubs3);

    expect(serviceSubs3.length).toEqual(1);

    const serviceSubs4 = await subs_fixture.actor.icrc79_get_service_subscriptions(serviceProvider2.getPrincipal(), [{
      products: [[[2n]]],
      status: [],
      subscriptions: [],
    }], [], []);

    console.log("serviceSubs4", serviceSubs4);

    expect(serviceSubs4.length).toEqual(1);

    const serviceSubs5 = await subs_fixture.actor.icrc79_get_service_subscriptions(serviceProvider2.getPrincipal(), [{
      products: [],
      status: [{Active: null}],
      subscriptions: [],
    }],  [], []);

    console.log("serviceSubs5", serviceSubs5);

    expect(serviceSubs5.length).toEqual(2);


    const serviceSubs6 = await subs_fixture.actor.icrc79_get_service_subscriptions(serviceProvider2.getPrincipal(), [{
      products: [],
      status: [{Paused: null}],
      subscriptions: [],
    }], [], []);

    console.log("serviceSubs6", serviceSubs6);

    expect(serviceSubs6.length).toEqual(0);

    const serviceSubs7= await subs_fixture.actor.icrc79_get_service_subscriptions(serviceProvider2.getPrincipal(), [], [], [1n]);

    console.log("serviceSubs7", serviceSubs7);

    expect(serviceSubs7.length).toEqual(1);

    const item = serviceSubs7[0].subscriptionId;

    const serviceSubs8= await subs_fixture.actor.icrc79_get_service_subscriptions(serviceProvider2.getPrincipal(), [], [item], [1n]);

    console.log("serviceSubs8", serviceSubs8);

    expect(serviceSubs8.length).toEqual(1);


    /////////////
    // Test pagination and filtering for get user subs
    /////////////

    const userSubs1 = await subs_fixture.actor.icrc79_get_user_subscriptions(  [], [],[]);

    console.log("userSubs1", userSubs1);

    expect(userSubs1.length).toEqual(3);

    const userSubs2 = await subs_fixture.actor.icrc79_get_user_subscriptions(  [{
      subscriptions: [],
      status: [],
      subaccounts: [[[alicesub1]]],
      products: [],
      services: [],
    }], [], []);

    console.log("userSubs2", userSubs2);

    expect(userSubs2.length).toEqual(1);

    const userSubs3 = await subs_fixture.actor.icrc79_get_user_subscriptions( [{
      subscriptions: [[0n]],
      status: [],
      subaccounts: [],
      products: [],
      services: [],
    }], [], []);

    console.log("userSubs3", userSubs3);

    expect(userSubs3.length).toEqual(1);

    const userSubs4 = await subs_fixture.actor.icrc79_get_user_subscriptions(  [{
      subscriptions: [],
      status: [],
      subaccounts: [],
      products: [[[1n]]],
      services: [],
    }], [], []);

    console.log("userSubs4", userSubs4);

    expect(userSubs4.length).toEqual(1);

    const userSubs5 = await subs_fixture.actor.icrc79_get_user_subscriptions( [{
      subscriptions: [],
      status: [],
      subaccounts: [],
      products: [],
      services: [[serviceProvider2.getPrincipal()]],
    }], [], []);

    console.log("userSubs5", userSubs5);

    expect(userSubs5.length).toEqual(2);


    const userSubs6 = await subs_fixture.actor.icrc79_get_user_subscriptions(  [{
      subscriptions: [],
      status: [{Active: null}],
      subaccounts: [],
      products: [],
      services: [],
    }], [], []);

    console.log("userSubs6", userSubs6);

    expect(userSubs6.length).toEqual(3);

    const userSubs9 = await subs_fixture.actor.icrc79_get_user_subscriptions(  [{
      subscriptions: [],
      status: [{Paused: null}],
      subaccounts: [],
      products: [],
      services: [],
    }], [], []);

    console.log("userSubs9", userSubs9);

    expect(userSubs9.length).toEqual(0);

    const userSubs7= await subs_fixture.actor.icrc79_get_user_subscriptions(  [], [], [1n]);

    console.log("userSubs7", userSubs7);

    expect(userSubs7.length).toEqual(1);

    const item2 = userSubs7[0].subscriptionId;

    const userSubs8= await subs_fixture.actor.icrc79_get_user_subscriptions( [], [item2], [1n]);

    console.log("userSubs8", userSubs8);

    expect(userSubs8.length).toEqual(1);


    /////////////
    // Test pagination and filtering for get user payments
    /////////////

    // Handle retrieving currently pending payments or confirm payment transaction
    const payments4 = await subs_fixture.actor.icrc79_get_user_payments([{
      subscriptions: [[0n]],
      status: [],
      subaccounts: [],
      products: [],
      services: [],
    }], [],  []);

    //console.log(payments4, payments4.length);
    expect(payments4.length).toEqual(13);


    const payments5 = await subs_fixture.actor.icrc79_get_user_payments([{
      subscriptions: [[1n, 2n]],
      status: [],
      subaccounts: [],
      products: [],
      services: [],
    }], [],  []);

    expect(payments5.length).toEqual(66);

    const payments6 = await subs_fixture.actor.icrc79_get_user_payments([{
      subscriptions: [],
      status: [],
      subaccounts: [[[alicesub1]]],
      products: [],
      services: [],
    }], [],  []);

    expect(payments6.length).toEqual(53);

    const payments7 = await subs_fixture.actor.icrc79_get_user_payments([{
      subscriptions: [],
      status: [],
      subaccounts: [],
      products: [[[1n]]],
      services: [],
    }], [],  []);

    expect(payments7.length).toEqual(53);


    const payments8 = await subs_fixture.actor.icrc79_get_user_payments([{
      subscriptions: [],
      status: [],
      subaccounts: [],
      products: [],
      services: [[serviceProvider2.getPrincipal()]],
    }], [],  []);

    expect(payments8.length).toEqual(66);

    console.log("payments8", payments8);


    const payments9 = await subs_fixture.actor.icrc79_get_user_payments([{
      subscriptions: [],
      status: [],
      subaccounts: [],
      products: [],
      services: [[serviceProvider2.getPrincipal()]],
    }], [70n],  [2n]);

    expect(payments9.length).toEqual(2);

    /////////////
    // Test pagination and filtering for get service payments
    /////////////

    // Handle retrieving currently pending payments or confirm payment transaction
    const paymentsService1 = await subs_fixture.actor.icrc79_get_service_payments(serviceProvider.getPrincipal(), [], [],  []);

    //console.log(payments4, payments4.length);
    expect(paymentsService1.length).toEqual(13);

    // Handle retrieving currently pending payments or confirm payment transaction
    const paymentsService2 = await subs_fixture.actor.icrc79_get_service_payments(serviceProvider2.getPrincipal(), [], [],  []);

    //console.log(payments4, payments4.length);
    expect(paymentsService2.length).toEqual(66);


    const paymentsService5 = await subs_fixture.actor.icrc79_get_service_payments(serviceProvider2.getPrincipal(), [{
      subscriptions: [[2n]],
      status: [],
      products: [],
    }], [],  []);

    expect(paymentsService5.length).toEqual(13);

    const paymentsService6 = await subs_fixture.actor.icrc79_get_service_payments(serviceProvider2.getPrincipal(),[{
      status: [{Active: null}],
      subscriptions: [],
      products: [],
    }], [],  []);

    expect(paymentsService6.length).toEqual(66);

    console.log("paymentsService6", paymentsService6);

    const paymentsService7 = await subs_fixture.actor.icrc79_get_service_payments(serviceProvider2.getPrincipal(), [{
      subscriptions: [],
      status: [{Paused: null}],
      products: [],
    }], [],  []);

    console.log("paymentsService7", paymentsService7);

    expect(paymentsService7.length).toEqual(0);


    const paymentsService8 = await subs_fixture.actor.icrc79_get_service_payments(serviceProvider2.getPrincipal(), [{
      subscriptions: [],
      status: [],
      products: [[[2n]]],
    }], [],  []);

    expect(paymentsService8.length).toEqual(13);

    console.log("payments8", payments8);


    const paymentsService9 = await subs_fixture.actor.icrc79_get_service_payments(serviceProvider2.getPrincipal(), [{
      subscriptions: [],
      status: [],
      products: [[[2n]]],
    }], [],  [2n]);

    expect(paymentsService9.length).toEqual(2);

    let item3 = paymentsService9[0].paymentId;

    const paymentsService10 = await subs_fixture.actor.icrc79_get_service_payments(serviceProvider2.getPrincipal(), [{
      subscriptions: [],
      status: [],
      products: [[[2n]]],
    }], [item3],  [2n]);

    expect(paymentsService10.length).toEqual(2);

    /////////////
    //
    // Test get pending payments
    //
    /////////////

    const pendingPayments = await subs_fixture.actor.icrc79_get_payments_pending([paymentsService10[0].subscriptionId, paymentsService10[1].subscriptionId]);

    expect(pendingPayments.length).toEqual(2);

    /////////////

    let serviceBalance = await nnsledger.icrc1_balance_of({owner : serviceProvider.getPrincipal(), subaccount :[]});
    let service2Balance = await nnsledger.icrc1_balance_of({owner : serviceProvider2.getPrincipal(), subaccount :[]});
    let aliceBalance =await nnsledger.icrc1_balance_of({owner : alice.getPrincipal(), subaccount :[]});
    let aliceSubBalance = await nnsledger.icrc1_balance_of({owner : alice.getPrincipal(), subaccount :[alicesub1]});
    let bobBalance = await nnsledger.icrc1_balance_of({owner : bob.getPrincipal(), subaccount :[]});
    let feeBalance =  await nnsledger.icrc1_balance_of({owner : Principal.fromText("ifoh3-ksock-kdg2i-274hs-z3x7e-irgfv-eyqzv-esrlt-2qywt-jbocu-gae"), subaccount :[]});

    expect(serviceBalance).toEqual(12805000n);
    expect(service2Balance).toEqual(25610000n);
    expect(aliceBalance).toEqual(9960470000n);
    expect(aliceSubBalance).toEqual(9892930000n);
    expect(bobBalance).toEqual(104410000n);
    expect(feeBalance).toEqual(2175000n);
    
    

  });


  it(`user can unsubscribe`, async () => {

    await awardTokens(nnsledger, minterIdentity, null, {owner : alice.getPrincipal(), subaccount : []}, BigInt(10000000000));
    
    pic.tick();
    await pic.advanceTime(1000); // 24 hours in milliseconds
    await tickN(10);


    // Set the identity to Alice to act on her behalf
    subs_fixture.actor.setIdentity(alice);
    nnsledger.setIdentity(alice);

    console.log("alice", alice.getPrincipal().toText());
    console.log("service provider", serviceProvider.getPrincipal().toText());
    console.log("nns ledger", nnsLedgerCanisterId.toText());
    // Approve the subscription canister to withdraw tokens on behalf of Alice
    const approvalResult = await nnsledger.icrc2_approve({
        from_subaccount: [],
        spender: {
            owner: subs_fixture.canisterId,
            subaccount: []
        },
        amount: BigInt(10000000000000000),
        memo: [],
        created_at_time: [BigInt((await pic.getTime()) * 1000000)],
        expected_allowance: [],
        expires_at: [],
        fee: [BigInt(10000)]
    });

    console.log("approval result", approvalResult);

    const addTokenResult = await subs_fixture.actor.add_token(nnsLedgerCanisterId, []);

    console.log("add token result", addTokenResult);

    // Prepare the subscription request
    const subscribeRequest : SubscriptionRequest = [[
      {tokenCanister: nnsLedgerCanisterId},
      {serviceCanister: serviceProvider.getPrincipal()},
      {interval: { Monthly: null }},
      {amountPerInterval: BigInt(1000000)},
    ]];

    console.log("subscribe request", subscribeRequest);

    // Execute the subscription
    const subResult = await subs_fixture.actor.icrc79_subscribe(subscribeRequest);

    console.log("sub result", subResult);

    expect(subResult).toMatchObject([[{ Ok: expect.any(Object) }]]);

    console.log("sub result", subResult);

    

    // Forward time to ensure the subscription payment is processed
    await pic.advanceTime(1000); // next tick hours in milliseconds
    await tickN(10);

    // Handle retrieving currently pending payments or confirm payment transaction
    const payments = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    console.log(payments, payments.length);
    expect(payments.length).toEqual(1);
    expect(payments[0].ledgerTransactionId).toBeDefined();

    await pic.advanceTime(2_629_800_000 + 1); // A month
    await tickN(20);

    // Handle retrieving currently pending payments or confirm payment transaction
    const payments2 = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    console.log(payments2, payments2.length);
    expect(payments2.length).toEqual(2);
    expect(payments2[0].ledgerTransactionId).toBeDefined();

    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);

    const payments3 = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    console.log(payments3, payments3.length);
    expect(payments3.length).toEqual(4);

    const unsubscribe = await subs_fixture.actor.icrc79_cancel_subscription([{
      subscriptionId: 0n,
      reason: "Because"
    }]);

    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);

    const payments4 = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    console.log(payments4, payments4.length);
    expect(payments4.length).toEqual(4);



  });

  it(`fee can be blocked`, async () => {

    await awardTokens(nnsledger, minterIdentity, null, {owner : charlie.getPrincipal(), subaccount : []}, BigInt(10000000000));
    
    pic.tick();
    await pic.advanceTime(1000); // 24 hours in milliseconds
    await tickN(10);


    // Set the identity to charlie to act on her behalf
    subs_fixture.actor.setIdentity(charlie);
    nnsledger.setIdentity(charlie);

    console.log("charlie", charlie.getPrincipal().toText());
    console.log("service provider", serviceProvider.getPrincipal().toText());
    console.log("nns ledger", nnsLedgerCanisterId.toText());
    // Approve the subscription canister to withdraw tokens on behalf of Alice
    const approvalResult = await nnsledger.icrc2_approve({
        from_subaccount: [],
        spender: {
            owner: subs_fixture.canisterId,
            subaccount: []
        },
        amount: BigInt(10000000000000000),
        memo: [],
        created_at_time: [BigInt((await pic.getTime()) * 1000000)],
        expected_allowance: [],
        expires_at: [],
        fee: [BigInt(10000)]
    });

    console.log("approval result", approvalResult);

    const addTokenResult = await subs_fixture.actor.add_token(nnsLedgerCanisterId, []);

    console.log("add token result", addTokenResult);

    // Prepare the subscription request
    const subscribeRequest : SubscriptionRequest = [[
      {tokenCanister: nnsLedgerCanisterId},
      {serviceCanister: serviceProvider.getPrincipal()},
      {interval: { Monthly: null }},
      {amountPerInterval: BigInt(1000000)},
    ]];

    console.log("subscribe request", subscribeRequest);

    // Execute the subscription
    const subResult = await subs_fixture.actor.icrc79_subscribe(subscribeRequest);

    console.log("sub result", subResult);

    expect(subResult).toMatchObject([[{ Ok: expect.any(Object) }]]);

    console.log("sub result", subResult);

    

    // Forward time to ensure the subscription payment is processed
    await pic.advanceTime(1000); // next tick hours in milliseconds
    await tickN(10);

    let feeBalance =  await nnsledger.icrc1_balance_of({owner : Principal.fromText("ifoh3-ksock-kdg2i-274hs-z3x7e-irgfv-eyqzv-esrlt-2qywt-jbocu-gae"), subaccount :[]});

    expect(feeBalance).toEqual(0n);
    

 

  });


  it(`duplicates are rejected`, async () => {

    await awardTokens(nnsledger, minterIdentity, null, {owner : charlie.getPrincipal(), subaccount : []}, BigInt(10000000000));
    
    pic.tick();
    await pic.advanceTime(1000); // 24 hours in milliseconds
    await tickN(10);


    // Set the identity to charlie to act on her behalf
    subs_fixture.actor.setIdentity(charlie);
    nnsledger.setIdentity(charlie);

    console.log("charlie", charlie.getPrincipal().toText());
    console.log("service provider", serviceProvider.getPrincipal().toText());
    console.log("nns ledger", nnsLedgerCanisterId.toText());
    // Approve the subscription canister to withdraw tokens on behalf of Alice
    const approvalResult = await nnsledger.icrc2_approve({
        from_subaccount: [],
        spender: {
            owner: subs_fixture.canisterId,
            subaccount: []
        },
        amount: BigInt(10000000000000000),
        memo: [],
        created_at_time: [BigInt((await pic.getTime()) * 1000000)],
        expected_allowance: [],
        expires_at: [],
        fee: [BigInt(10000)]
    });

    console.log("approval result", approvalResult);

    const addTokenResult = await subs_fixture.actor.add_token(nnsLedgerCanisterId, []);

    console.log("add token result", addTokenResult);

    // Prepare the subscription request
    const subscribeRequest : SubscriptionRequest = [[
      {tokenCanister: nnsLedgerCanisterId},
      {serviceCanister: serviceProvider.getPrincipal()},
      {interval: { Monthly: null }},
      {amountPerInterval: BigInt(1000000)},
    ]];

    console.log("subscribe request", subscribeRequest);

    // Execute the subscription
    const subResult = await subs_fixture.actor.icrc79_subscribe(subscribeRequest);
    const subResult2 = await subs_fixture.actor.icrc79_subscribe(subscribeRequest);

    console.log("sub result", subResult);

    expect(subResult).toMatchObject([[{ Ok: expect.any(Object) }]]);
    expect(subResult2).toMatchObject([[{ Err: expect.any(Object) }]]);

    console.log("sub result", subResult2);

    

    // Forward time to ensure the subscription payment is processed
    await pic.advanceTime(2_629_800_000); // next tick hours in milliseconds
    await tickN(10);

    const subResult3 = await subs_fixture.actor.icrc79_subscribe(subscribeRequest);


    expect(subResult3).toMatchObject([[{ Ok: expect.any(Object) }]]);
    

 

  });

  it(`vendor can unsubscribe`, async () => {

    await awardTokens(nnsledger, minterIdentity, null, {owner : alice.getPrincipal(), subaccount : []}, BigInt(10000000000));
    
    pic.tick();
    await pic.advanceTime(1000); // 24 hours in milliseconds
    await tickN(10);


    // Set the identity to Alice to act on her behalf
    subs_fixture.actor.setIdentity(alice);
    nnsledger.setIdentity(alice);

    console.log("alice", alice.getPrincipal().toText());
    console.log("service provider", serviceProvider.getPrincipal().toText());
    console.log("nns ledger", nnsLedgerCanisterId.toText());
    // Approve the subscription canister to withdraw tokens on behalf of Alice
    const approvalResult = await nnsledger.icrc2_approve({
        from_subaccount: [],
        spender: {
            owner: subs_fixture.canisterId,
            subaccount: []
        },
        amount: BigInt(10000000000000000),
        memo: [],
        created_at_time: [BigInt((await pic.getTime()) * 1000000)],
        expected_allowance: [],
        expires_at: [],
        fee: [BigInt(10000)]
    });

    console.log("approval result", approvalResult);

    const addTokenResult = await subs_fixture.actor.add_token(nnsLedgerCanisterId, []);

    console.log("add token result", addTokenResult);

    // Prepare the subscription request
    const subscribeRequest : SubscriptionRequest = [[
      {tokenCanister: nnsLedgerCanisterId},
      {serviceCanister: serviceProvider.getPrincipal()},
      {interval: { Monthly: null }},
      {amountPerInterval: BigInt(1000000)},
    ]];

    console.log("subscribe request", subscribeRequest);

    // Execute the subscription
    const subResult = await subs_fixture.actor.icrc79_subscribe(subscribeRequest);

    console.log("sub result", subResult);

    expect(subResult).toMatchObject([[{ Ok: expect.any(Object) }]]);

    console.log("sub result", subResult);

    // Forward time to ensure the subscription payment is processed
    await pic.advanceTime(1000); // next tick hours in milliseconds
    await tickN(10);

    // Handle retrieving currently pending payments or confirm payment transaction
    const payments = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    console.log(payments, payments.length);
    expect(payments.length).toEqual(1);
    expect(payments[0].ledgerTransactionId).toBeDefined();

    await pic.advanceTime(2_629_800_000 + 1); // A month
    await tickN(20);

    // Handle retrieving currently pending payments or confirm payment transaction
    const payments2 = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    console.log(payments2, payments2.length);
    expect(payments2.length).toEqual(2);
    expect(payments2[0].ledgerTransactionId).toBeDefined();

    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);

    const payments3 = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    console.log(payments3, payments3.length);
    expect(payments3.length).toEqual(4);

    subs_fixture.actor.setIdentity(serviceProvider);

    const unsubscribe = await subs_fixture.actor.icrc79_cancel_subscription([{
      subscriptionId: 0n,
      reason: "Because"
    }]);

    console.log(unsubscribe, unsubscribe.length);

    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);

    subs_fixture.actor.setIdentity(alice);

    const payments4 = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    console.log(payments4, payments4.length);
    expect(payments4.length).toEqual(4);



  });

  it(`can create a delayed subscription and the payment is processed`, async () => {

    await awardTokens(nnsledger, minterIdentity, null, {owner : alice.getPrincipal(), subaccount : []}, BigInt(10000000000));
    
    pic.tick();
    await pic.advanceTime(1000); // 24 hours in milliseconds
    await tickN(10);


    // Set the identity to Alice to act on her behalf
    subs_fixture.actor.setIdentity(alice);
    nnsledger.setIdentity(alice);

    console.log("alice", alice.getPrincipal().toText());
    console.log("service provider", serviceProvider.getPrincipal().toText());
    console.log("nns ledger", nnsLedgerCanisterId.toText());
    // Approve the subscription canister to withdraw tokens on behalf of Alice
    const approvalResult = await nnsledger.icrc2_approve({
        from_subaccount: [],
        spender: {
            owner: subs_fixture.canisterId,
            subaccount: []
        },
        amount: BigInt(10000000000000000),
        memo: [],
        created_at_time: [BigInt((await pic.getTime()) * 1000000)],
        expected_allowance: [],
        expires_at: [],
        fee: [BigInt(10000)]
    });

    console.log("approval result", approvalResult);

    const addTokenResult = await subs_fixture.actor.add_token(nnsLedgerCanisterId, []);

    console.log("add token result", addTokenResult);

    const currentTime = await pic.getTime();

    // Prepare the subscription request
    const subscribeRequest : SubscriptionRequest = [[
      {tokenCanister: nnsLedgerCanisterId},
      {serviceCanister: serviceProvider.getPrincipal()},
      {interval: { Monthly: null }},
      {amountPerInterval: BigInt(1000000)},
      {firstPayment: BigInt((currentTime * 1_000_000)+ (2_629_800_000 * 1_000_000))}, // 1 month from now
    ]];

    console.log("subscribe request", subscribeRequest);

    // Execute the subscription
    const subResult = await subs_fixture.actor.icrc79_subscribe(subscribeRequest);

    console.log("sub result", subResult);

    expect(subResult).toMatchObject([[{ Ok: expect.any(Object) }]]);

    console.log("sub result", subResult);

    

    // Forward time to ensure the subscription payment is processed
    await pic.advanceTime(1_000_000); //  next tick hours in milliseconds
    await tickN(10);

    // Handle retrieving currently pending payments or confirm payment transaction
    const payments = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    console.log(payments, payments.length);
    expect(payments.length).toEqual(0);

    await pic.advanceTime(2_629_800_000 + 1); // A month
    await tickN(20);

    // Handle retrieving currently pending payments or confirm payment transaction
    const payments2 = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    console.log(payments2, payments2.length);
    expect(payments2.length).toEqual(1);
    expect(payments2[0].ledgerTransactionId).toBeDefined();

  });

  it(`cannot create a subscription with invalid token canister`, async () => {

    await awardTokens(nnsledger, minterIdentity, null, {owner : alice.getPrincipal(), subaccount : []}, BigInt(10000000000));
    
    pic.tick();
    await pic.advanceTime(1000); // 24 hours in milliseconds
    await tickN(10);


    // Set the identity to Alice to act on her behalf
    subs_fixture.actor.setIdentity(alice);
    nnsledger.setIdentity(alice);

    console.log("alice", alice.getPrincipal().toText());
    console.log("service provider", serviceProvider.getPrincipal().toText());
    console.log("nns ledger", nnsLedgerCanisterId.toText());
    // Approve the subscription canister to withdraw tokens on behalf of Alice
    const approvalResult = await nnsledger.icrc2_approve({
        from_subaccount: [],
        spender: {
            owner: subs_fixture.canisterId,
            subaccount: []
        },
        amount: BigInt(10000000000000000),
        memo: [],
        created_at_time: [BigInt((await pic.getTime()) * 1000000)],
        expected_allowance: [],
        expires_at: [],
        fee: [BigInt(10000)]
    });

    console.log("approval result", approvalResult);

    const addTokenResult = await subs_fixture.actor.add_token(nnsLedgerCanisterId, []);

    console.log("add token result", addTokenResult);

    const currentTime = await pic.getTime();

    // Prepare the subscription request
    const subscribeRequest : SubscriptionRequest = [[
      {tokenCanister: alice.getPrincipal()},
      {serviceCanister: serviceProvider.getPrincipal()},
      {interval: { Monthly: null }},
      {amountPerInterval: BigInt(1000000)},
      {firstPayment: BigInt((currentTime * 1_000_000)+ (2_629_800_000 * 1_000_000))}, // 1 month from now
    ]];

    console.log("subscribe request", subscribeRequest);

    // Execute the subscription
    const subResult = await subs_fixture.actor.icrc79_subscribe(subscribeRequest);

    console.log("sub result", subResult);

    expect(subResult).toMatchObject([[{ Err: expect.any(Object)}]]);
  });

  it(`cannot create a subscription with end date in the past`, async () => {

    await awardTokens(nnsledger, minterIdentity, null, {owner : alice.getPrincipal(), subaccount : []}, BigInt(10000000000));
    
    pic.tick();
    await pic.advanceTime(1000); // 24 hours in milliseconds
    await tickN(10);


    // Set the identity to Alice to act on her behalf
    subs_fixture.actor.setIdentity(alice);
    nnsledger.setIdentity(alice);

    console.log("alice", alice.getPrincipal().toText());
    console.log("service provider", serviceProvider.getPrincipal().toText());
    console.log("nns ledger", nnsLedgerCanisterId.toText());
    // Approve the subscription canister to withdraw tokens on behalf of Alice
    const approvalResult = await nnsledger.icrc2_approve({
        from_subaccount: [],
        spender: {
            owner: subs_fixture.canisterId,
            subaccount: []
        },
        amount: BigInt(10000000000000000),
        memo: [],
        created_at_time: [BigInt((await pic.getTime()) * 1000000)],
        expected_allowance: [],
        expires_at: [],
        fee: [BigInt(10000)]
    });

    console.log("approval result", approvalResult);

    const addTokenResult = await subs_fixture.actor.add_token(nnsLedgerCanisterId, []);

    console.log("add token result", addTokenResult);

    const currentTime = await pic.getTime();

    // Prepare the subscription request
    const subscribeRequest : SubscriptionRequest = [[
      {tokenCanister: nnsLedgerCanisterId},
      {serviceCanister: serviceProvider.getPrincipal()},
      {interval: { Monthly: null }},
      {amountPerInterval: BigInt(1000000)},
      {endDate: BigInt((currentTime * 1_000_000) - (2_629_800_000 * 1_000_000))}, // 1 month in the past
    ]];

    console.log("subscribe request", subscribeRequest);

    // Execute the subscription
    const subResult = await subs_fixture.actor.icrc79_subscribe(subscribeRequest);

    console.log("sub result", subResult);

    expect(subResult).toMatchObject([[{ Err: {InvalidDate : null} }]]);
  });

  it(`vendor can pause and unpause`, async () => {

    await awardTokens(nnsledger, minterIdentity, null, {owner : alice.getPrincipal(), subaccount : []}, BigInt(10000000000));
    
    pic.tick();
    await pic.advanceTime(1000); // 24 hours in milliseconds
    await tickN(10);


    // Set the identity to Alice to act on her behalf
    subs_fixture.actor.setIdentity(alice);
    nnsledger.setIdentity(alice);

    console.log("alice", alice.getPrincipal().toText());
    console.log("service provider", serviceProvider.getPrincipal().toText());
    console.log("nns ledger", nnsLedgerCanisterId.toText());
    // Approve the subscription canister to withdraw tokens on behalf of Alice
    const approvalResult = await nnsledger.icrc2_approve({
        from_subaccount: [],
        spender: {
            owner: subs_fixture.canisterId,
            subaccount: []
        },
        amount: BigInt(10000000000000000),
        memo: [],
        created_at_time: [BigInt((await pic.getTime()) * 1000000)],
        expected_allowance: [],
        expires_at: [],
        fee: [BigInt(10000)]
    });

    console.log("approval result", approvalResult);

    const addTokenResult = await subs_fixture.actor.add_token(nnsLedgerCanisterId, []);

    console.log("add token result", addTokenResult);

    // Prepare the subscription request
    const subscribeRequest : SubscriptionRequest = [[
      {tokenCanister: nnsLedgerCanisterId},
      {serviceCanister: serviceProvider.getPrincipal()},
      {interval: { Monthly: null }},
      {amountPerInterval: BigInt(1000000)},
    ]];

    console.log("subscribe request", subscribeRequest);

    // Execute the subscription
    const subResult = await subs_fixture.actor.icrc79_subscribe(subscribeRequest);

    console.log("sub result", subResult);

    expect(subResult).toMatchObject([[{ Ok: expect.any(Object) }]]);

    console.log("sub result", subResult);

    // Forward time to ensure the subscription payment is processed
    await pic.advanceTime(1000); // next tick hours in milliseconds
    await tickN(10);

    // Handle retrieving currently pending payments or confirm payment transaction
    const payments = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    console.log(payments, payments.length);
    expect(payments.length).toEqual(1);
    expect(payments[0].ledgerTransactionId).toBeDefined();

    await pic.advanceTime(2_629_800_000 + 1); // A month
    await tickN(20);

    // Handle retrieving currently pending payments or confirm payment transaction
    const payments2 = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    console.log(payments2, payments2.length);
    expect(payments2.length).toEqual(2);
    expect(payments2[0].ledgerTransactionId).toBeDefined();

    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);

    const payments3 = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    console.log(payments3, payments3.length);
    expect(payments3.length).toEqual(4);

    subs_fixture.actor.setIdentity(serviceProvider);

    const pause = await subs_fixture.actor.icrc79_pause_subscription([{
      subscriptionId: 0n,
      active: false,
      reason: "Because"
    }]);

    console.log("pause", pause);

    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);

    subs_fixture.actor.setIdentity(alice);

    const payments4 = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    console.log(payments4, payments4.length);
    expect(payments4.length).toEqual(4);

    const unpauseAlice = await subs_fixture.actor.icrc79_pause_subscription([{
      subscriptionId: 0n,
      active: true,
      reason: "Alice attempt"
    }]);

    console.log("unpauseAlice", unpauseAlice);


    expect(unpauseAlice).toMatchObject([[{ Err: {Unauthorized : null} }]]);

    subs_fixture.actor.setIdentity(serviceProvider);

    const unpauseService = await subs_fixture.actor.icrc79_pause_subscription([{
      subscriptionId: 0n,
      active: true,
      reason: "Because"
    }]);

    console.log("unpauseService", unpauseService);

    expect(unpauseService).toMatchObject([[{ Ok: expect.any(BigInt)}]]);

    await pic.advanceTime(1000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);

    subs_fixture.actor.setIdentity(alice);

    const payments5 = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    console.log(payments5, payments5.length);
    expect(payments5.length).toEqual(7);




  });

  it(`user can pause and unpause`, async () => {

    await awardTokens(nnsledger, minterIdentity, null, {owner : alice.getPrincipal(), subaccount : []}, BigInt(10000000000));
    
    pic.tick();
    await pic.advanceTime(1000); // 24 hours in milliseconds
    await tickN(10);


    // Set the identity to Alice to act on her behalf
    subs_fixture.actor.setIdentity(alice);
    nnsledger.setIdentity(alice);

    console.log("alice", alice.getPrincipal().toText());
    console.log("service provider", serviceProvider.getPrincipal().toText());
    console.log("nns ledger", nnsLedgerCanisterId.toText());
    // Approve the subscription canister to withdraw tokens on behalf of Alice
    const approvalResult = await nnsledger.icrc2_approve({
        from_subaccount: [],
        spender: {
            owner: subs_fixture.canisterId,
            subaccount: []
        },
        amount: BigInt(10000000000000000),
        memo: [],
        created_at_time: [BigInt((await pic.getTime()) * 1000000)],
        expected_allowance: [],
        expires_at: [],
        fee: [BigInt(10000)]
    });

    console.log("approval result", approvalResult);

    const addTokenResult = await subs_fixture.actor.add_token(nnsLedgerCanisterId, []);

    console.log("add token result", addTokenResult);

    // Prepare the subscription request
    const subscribeRequest : SubscriptionRequest = [[
      {tokenCanister: nnsLedgerCanisterId},
      {serviceCanister: serviceProvider.getPrincipal()},
      {interval: { Monthly: null }},
      {amountPerInterval: BigInt(1000000)},
    ]];

    console.log("subscribe request", subscribeRequest);

    // Execute the subscription
    const subResult = await subs_fixture.actor.icrc79_subscribe(subscribeRequest);

    console.log("sub result", subResult);

    expect(subResult).toMatchObject([[{ Ok: expect.any(Object) }]]);

    console.log("sub result", subResult);

    // Forward time to ensure the subscription payment is processed
    await pic.advanceTime(1000); // next tick hours in milliseconds
    await tickN(10);

    // Handle retrieving currently pending payments or confirm payment transaction
    const payments = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    console.log(payments, payments.length);
    expect(payments.length).toEqual(1);
    expect(payments[0].ledgerTransactionId).toBeDefined();

    await pic.advanceTime(2_629_800_000 + 1); // A month
    await tickN(20);

    // Handle retrieving currently pending payments or confirm payment transaction
    const payments2 = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    console.log(payments2, payments2.length);
    expect(payments2.length).toEqual(2);
    expect(payments2[0].ledgerTransactionId).toBeDefined();

    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);

    const payments3 = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    console.log(payments3, payments3.length);
    expect(payments3.length).toEqual(4);

    subs_fixture.actor.setIdentity(alice);

    const pause = await subs_fixture.actor.icrc79_pause_subscription([{
      subscriptionId: 0n,
      active: false,
      reason: "Because"
    }]);

    console.log("pause", pause);

    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);

    const payments4 = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    console.log(payments4, payments4.length);
    expect(payments4.length).toEqual(4);

    subs_fixture.actor.setIdentity(serviceProvider);

    const unpauseService = await subs_fixture.actor.icrc79_pause_subscription([{
      subscriptionId: 0n,
      active: true,
      reason: "Because"
    }]);

    expect(unpauseService).toMatchObject([[{ Err: {Unauthorized : null} }]]);

    subs_fixture.actor.setIdentity(alice);


    const unpauseAlice = await subs_fixture.actor.icrc79_pause_subscription([{
      subscriptionId: 0n,
      active: true,
      reason: "Alice attempt"
    }]);

    console.log("unpauseAlice", unpauseAlice);


    await pic.advanceTime(1000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);
    await pic.advanceTime(2_629_800_000); //1 Month
    await tickN(25);

    subs_fixture.actor.setIdentity(alice);

    const payments5 = await subs_fixture.actor.icrc79_get_user_payments([], [],  []);

    console.log(payments5, payments5.length);
    expect(payments5.length).toEqual(7);

  });

  it(`user cannot cancel someone else's subscription`, async () => {

    await awardTokens(nnsledger, minterIdentity, null, {owner : alice.getPrincipal(), subaccount : []}, BigInt(10000000000));
    
    pic.tick();
    await pic.advanceTime(1000); // 24 hours in milliseconds
    await tickN(10);


    // Set the identity to Alice to act on her behalf
    subs_fixture.actor.setIdentity(alice);
    nnsledger.setIdentity(alice);

    console.log("alice", alice.getPrincipal().toText());
    console.log("service provider", serviceProvider.getPrincipal().toText());
    console.log("nns ledger", nnsLedgerCanisterId.toText());
    // Approve the subscription canister to withdraw tokens on behalf of Alice
    const approvalResult = await nnsledger.icrc2_approve({
        from_subaccount: [],
        spender: {
            owner: subs_fixture.canisterId,
            subaccount: []
        },
        amount: BigInt(10000000000000000),
        memo: [],
        created_at_time: [BigInt((await pic.getTime()) * 1000000)],
        expected_allowance: [],
        expires_at: [],
        fee: [BigInt(10000)]
    });

    console.log("approval result", approvalResult);

    const addTokenResult = await subs_fixture.actor.add_token(nnsLedgerCanisterId, []);

    console.log("add token result", addTokenResult);

    // Prepare the subscription request
    const subscribeRequest : SubscriptionRequest = [[
      {tokenCanister: nnsLedgerCanisterId},
      {serviceCanister: serviceProvider.getPrincipal()},
      {interval: { Monthly: null }},
      {amountPerInterval: BigInt(1000000)},
    ]];

    console.log("subscribe request", subscribeRequest);

    // Execute the subscription
    const subResult = await subs_fixture.actor.icrc79_subscribe(subscribeRequest);

    console.log("sub result", subResult);

    expect(subResult).toMatchObject([[{ Ok: expect.any(Object) }]]);

    

    // Forward time to ensure the subscription payment is processed
    await pic.advanceTime(1000); // next tick hours in milliseconds
    await tickN(10);


    subs_fixture.actor.setIdentity(bob);

    const pause = await subs_fixture.actor.icrc79_pause_subscription([{
      subscriptionId: 0n,
      active: false,
      reason: "Because"
    }]);

    console.log("pause", pause);

    

    expect(pause).toMatchObject([[{ Err: {Unauthorized : null} }]]);


  });


  it(`service can confirm subscription`, async () => {

    await awardTokens(nnsledger, minterIdentity, null, {owner : alice.getPrincipal(), subaccount : []}, BigInt(10000000000));
    
    pic.tick();
    await pic.advanceTime(1000); // 24 hours in milliseconds
    await tickN(10);


    // Set the identity to Alice to act on her behalf
    subs_fixture.actor.setIdentity(alice);
    nnsledger.setIdentity(alice);

    console.log("alice", alice.getPrincipal().toText());
    console.log("service provider", serviceProvider.getPrincipal().toText());
    console.log("nns ledger", nnsLedgerCanisterId.toText());
    // Approve the subscription canister to withdraw tokens on behalf of Alice
    const approvalResult = await nnsledger.icrc2_approve({
        from_subaccount: [],
        spender: {
            owner: subs_fixture.canisterId,
            subaccount: []
        },
        amount: BigInt(10000000000000000),
        memo: [],
        created_at_time: [BigInt((await pic.getTime()) * 1000000)],
        expected_allowance: [],
        expires_at: [],
        fee: [BigInt(10000)]
    });

    console.log("approval result", approvalResult);

    const addTokenResult = await subs_fixture.actor.add_token(nnsLedgerCanisterId, []);

    console.log("add token result", addTokenResult);

    // Prepare the subscription request
    const subscribeRequest : SubscriptionRequest = [[
      {tokenCanister: nnsLedgerCanisterId},
      {serviceCanister: serviceProvider.getPrincipal()},
      {interval: { Monthly: null }},
      {amountPerInterval: BigInt(1000000)},
    ]];

    console.log("subscribe request", subscribeRequest);

    // Execute the subscription
    const subResult = await subs_fixture.actor.icrc79_subscribe(subscribeRequest);

    console.log("sub result", subResult);

    expect(subResult).toMatchObject([[{ Ok: expect.any(Object) }]]);

    

    // Forward time to ensure the subscription payment is processed
    await pic.advanceTime(1000); // next tick hours in milliseconds
    await tickN(10);

    subs_fixture.actor.setIdentity(alice);

    //cancel the approval
    const approvalResult2 = await nnsledger.icrc2_approve({
      from_subaccount: [],
      spender: {
          owner: subs_fixture.canisterId,
          subaccount: []
      },
      amount: BigInt(0),
      memo: [],
      created_at_time: [BigInt((await pic.getTime()) * 1000000)],
      expected_allowance: [],
      expires_at: [],
      fee: [BigInt(10000)]
  });

  const tester_fixture = await pic.setupCanister<TesterService>({
    idlFactory: testerIDLFactory,
    wasm: tester_WASM_PATH,
    //arg: IDL.encode(testerinit2({IDL}), [[]])
  });

  var hadError = false;
  try{
    let aTest = await tester_fixture.actor.checksubscription(subs_fixture.canisterId, [0n], 1000n);

    console.log("shouldn't be here", aTest);
  }catch(e){
    hadError = true;
    console.log(e);
  };


  let aTest2 = await tester_fixture.actor.checksubscription(subs_fixture.canisterId, [0n], 501_000n);

  console.log(aTest2);

  expect(aTest2).toMatchObject([[{ Err: {InsufficientAllowance :  0n} }]]);




    


  });

  
/* 


  //maybe.  This seems complicated. If thi vendor pauses it , can the user resume it?


  it(`broker gets portion of subscription payments`, async () => {});


  it(`public good gets portion of subscription payments`, async () => {});

  it(`providing target account diverts payment`, async () => {});
  it(`providing end date ends subscription`, async () => {});

  it(`rejects intervals less than 1 hour`, async () => {});

  it(`admin can blacklist payments from certain endpoints`, async () => {});

  it(`admin can blacklist payments to certain endpoints`, async () => {});

  it(`broker can blacklist payments from certain endpoints`, async () => {});

  it(`transaction deduplication works for creating new subscriptions`, async () => {});

  it(`exchange rate error pauses subscription`, async () => {});

  it(`confirm identity in icrc-75 list`, async () => {});


  it(`subscription utilizes ICRC-17 to block via KYC`, async () => {});
  it(`exchange rate canister properly translates tokens`, async () => {});
  it(`failed exchange rate pauses the subscription`, async () => {});
 */

});
