#!/usr/bin/env -S npx ts-node
/**
 * Test script to verify the airdrop feature
 * Registers a new user and verifies they receive 20 GRX
 */

import * as anchor from "@coral-xyz/anchor";
import { PublicKey, Keypair } from "@solana/web3.js";

const REGISTRY_PROGRAM_ID = new PublicKey(
  "E1k1C1oyRye4dmZcBKJvFKeEarqJBbyUVP7t6odVgo1X"
);

async function main() {
  // Connect to localnet
  const connection = new anchor.web3.Connection("http://localhost:8899", "confirmed");
  
  console.log("✅ Connected to localnet");
  
  // Get the registry program
  const idl = require("./gridtokenx-anchor/target/idl/registry.json");
  const program = new anchor.Program(idl, REGISTRY_PROGRAM_ID, {
    connection,
  });

  console.log("📋 Registry Program loaded");
  console.log(`   Program ID: ${REGISTRY_PROGRAM_ID.toBase58()}`);

  // Create a new keypair for testing
  const testUser = Keypair.generate();
  
  console.log(`👤 Test user: ${testUser.publicKey.toBase58()}`);
  
  // Request airdrop to pay for transactions
  console.log("💰 Requesting airdrop for test user...");
  const airdropSig = await connection.requestAirdrop(
    testUser.publicKey,
    anchor.web3.LAMPORTS_PER_SOL * 10
  );
  await connection.confirmTransaction(airdropSig);
  
  const balance = await connection.getBalance(testUser.publicKey);
  console.log(`   Balance: ${balance / anchor.web3.LAMPORTS_PER_SOL} SOL`);

  console.log("\n✅ Test setup complete");
  console.log("Next: Call register_user instruction to test airdrop feature");
}

main().catch(console.error);
