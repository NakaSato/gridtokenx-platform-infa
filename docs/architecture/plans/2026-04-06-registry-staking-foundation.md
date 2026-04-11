# GRX 2.0 Phase 1: Registry Staking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the foundation for GRX staking and validator registration in the Registry program.

**Architecture:** Extend the Registry program to support GRX token staking. Users and Validators will lock GRX tokens into a program-controlled PDA to gain "Boost" or "Validator" status.

**Tech Stack:** Rust (Anchor), Solana SPL Token-2022.

---

### Task 1: Define Staking State and Errors in Registry

**Files:**
- Modify: `gridtokenx-anchor/programs/registry/src/state.rs`
- Modify: `gridtokenx-anchor/programs/registry/src/error.rs`
- Test: `gridtokenx-anchor/tests/registry_staking.test.ts`

- [ ] **Step 1: Define ValidatorStatus and update UserAccount**

In `gridtokenx-anchor/programs/registry/src/state.rs`:

```rust
#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, PartialEq, Eq, InitSpace, Debug)]
#[repr(u8)]
pub enum ValidatorStatus {
    None,
    Active,
    Slashed,
    Suspended,
}

unsafe impl bytemuck::Zeroable for ValidatorStatus {}
unsafe impl bytemuck::Pod for ValidatorStatus {}

// Update UserAccount to include staking info (ensure alignment for ZeroCopy)
// Current UserAccount is 80 bytes. We'll add 16 bytes for staking.
#[account(zero_copy)]
#[repr(C)]
pub struct UserAccount {
    pub authority: Pubkey,   // 32
    pub user_type: UserType, // 1
    pub _padding1: [u8; 3],  // 3
    pub lat_e7: i32,         // 4
    pub long_e7: i32,        // 4
    pub _padding2: [u8; 4],  // 4
    pub h3_index: u64,       // 8
    pub status: UserStatus,  // 1
    pub validator_status: ValidatorStatus, // 1 (NEW)
    pub shard_id: u8,        // 1
    pub _padding3: [u8; 5],  // 5 (Adjusted)
    pub registered_at: i64,  // 8
    pub meter_count: u32,    // 4
    pub staked_grx: u64,     // 8 (NEW)
    pub last_stake_at: i64,  // 8 (NEW)
    pub _padding4: [u8; 4],  // 4 (Adjusted to keep 8-byte alignment/size)
}
```

- [ ] **Step 2: Add Staking Errors**

In `gridtokenx-anchor/programs/registry/src/error.rs`:

```rust
#[error_code]
pub enum RegistryError {
    // ... existing ...
    #[msg("Insufficient GRX balance for staking")]
    InsufficientStakingBalance,
    #[msg("Minimum stake amount not met")]
    MinStakeNotMet,
    #[msg("Unstaking period not yet reached")]
    UnstakingLocked,
}
```

- [ ] **Step 3: Commit**

```bash
git add gridtokenx-anchor/programs/registry/src/state.rs gridtokenx-anchor/programs/registry/src/error.rs
git commit -m "feat(registry): add staking state and error codes"
```

---

### Task 2: Implement `stake_grx` Instruction

**Files:**
- Modify: `gridtokenx-anchor/programs/registry/src/lib.rs`

- [ ] **Step 1: Add StakeGrx context and instruction**

In `gridtokenx-anchor/programs/registry/src/lib.rs`:

```rust
pub fn stake_grx(ctx: Context<StakeGrx>, amount: u64) -> Result<()> {
    let mut user_account = ctx.accounts.user_account.load_mut()?;
    let clock = Clock::get()?;

    // Transfer GRX from user to vault
    let cpi_accounts = TransferChecked {
        from: ctx.accounts.user_grx_ata.to_account_info(),
        mint: ctx.accounts.grx_mint.to_account_info(),
        to: ctx.accounts.grx_vault.to_account_info(),
        authority: ctx.accounts.user.to_account_info(),
    };
    let cpi_program = ctx.accounts.token_program.to_account_info();
    let cpi_ctx = CpiContext::new(cpi_program, cpi_accounts);
    token_interface::transfer_checked(cpi_ctx, amount, 9)?;

    user_account.staked_grx += amount;
    user_account.last_stake_at = clock.unix_timestamp;

    Ok(())
}

#[derive(Accounts)]
pub struct StakeGrx<'info> {
    #[account(mut)]
    pub user_account: AccountLoader<'info, UserAccount>,
    #[account(mut)]
    pub user: Signer<'info>,
    #[account(mut)]
    pub user_grx_ata: InterfaceAccount<'info, TokenAccount>,
    #[account(
        mut,
        seeds = [b"grx_vault"],
        bump,
    )]
    pub grx_vault: InterfaceAccount<'info, TokenAccount>,
    pub grx_mint: InterfaceAccount<'info, Mint>,
    pub token_program: Interface<'info, TokenInterface>,
    pub system_program: Program<'info, System>,
}
```

- [ ] **Step 2: Commit**

```bash
git add gridtokenx-anchor/programs/registry/src/lib.rs
git commit -m "feat(registry): implement stake_grx instruction"
```

---

### Task 3: Implement `register_validator` Instruction

- [ ] **Step 1: Add RegisterValidator logic**

In `gridtokenx-anchor/programs/registry/src/lib.rs`:

```rust
pub fn register_validator(ctx: Context<RegisterValidator>) -> Result<()> {
    let mut user_account = ctx.accounts.user_account.load_mut()?;
    
    // Check if user has enough stake (10,000 GRX)
    require!(
        user_account.staked_grx >= 10_000 * 10u64.pow(9),
        RegistryError::MinStakeNotMet
    );

    user_account.validator_status = ValidatorStatus::Active;
    
    Ok(())
}

#[derive(Accounts)]
pub struct RegisterValidator<'info> {
    #[account(
        mut,
        constraint = user_account.load()?.authority == user.key()
    )]
    pub user_account: AccountLoader<'info, UserAccount>,
    pub user: Signer<'info>,
}
```

- [ ] **Step 2: Commit**

```bash
git add gridtokenx-anchor/programs/registry/src/lib.rs
git commit -m "feat(registry): implement register_validator instruction"
```
