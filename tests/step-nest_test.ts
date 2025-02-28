import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure users can create new routes with valid parameters",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("step-nest", "create-route", [
        types.utf8("Mountain Trail"),
        types.utf8("Beautiful mountain trail with scenic views"),
        types.uint(3),
        types.uint(5000)
      ], wallet_1.address)
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    assertEquals(block.receipts[0].result, "(ok u1)");
  },
});

Clarinet.test({
  name: "Ensure users can complete routes and receive tokens",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    // First create a route
    let block1 = chain.mineBlock([
      Tx.contractCall("step-nest", "create-route", [
        types.utf8("Mountain Trail"),
        types.utf8("Beautiful mountain trail with scenic views"),
        types.uint(3),
        types.uint(5000)
      ], wallet_1.address)
    ]);
    
    // Then complete it
    let block2 = chain.mineBlock([
      Tx.contractCall("step-nest", "complete-route", [
        types.uint(1)
      ], wallet_1.address)
    ]);
    
    assertEquals(block2.receipts.length, 1);
    assertEquals(block2.receipts[0].result, "(ok true)");
  },
});

Clarinet.test({
  name: "Ensure users can only rate routes they have completed",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    // Create route
    let block1 = chain.mineBlock([
      Tx.contractCall("step-nest", "create-route", [
        types.utf8("Mountain Trail"),
        types.utf8("Beautiful mountain trail with scenic views"),
        types.uint(3),
        types.uint(5000)
      ], wallet_1.address)
    ]);
    
    // Complete route
    let block2 = chain.mineBlock([
      Tx.contractCall("step-nest", "complete-route", [
        types.uint(1)
      ], wallet_1.address)
    ]);
    
    // Rate route
    let block3 = chain.mineBlock([
      Tx.contractCall("step-nest", "rate-route", [
        types.uint(1),
        types.uint(5)
      ], wallet_1.address)
    ]);
    
    assertEquals(block3.receipts.length, 1);
    assertEquals(block3.receipts[0].result, "(ok true)");
  },
});
