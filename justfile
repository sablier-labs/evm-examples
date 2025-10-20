# See https://github.com/sablier-labs/devkit/blob/main/just/evm.just

# Run just --list to see all available commands

import "./node_modules/@sablier/devkit/just/evm.just"

default:
  @just --list

# Build all contracts (airdrops, flow, lockup)

[group("build")]
build:
  just build-airdrops
  just build-flow
  just build-lockup
alias ba := build

# Build airdrops contracts
[group("build")]
build-airdrops:
  FOUNDRY_PROFILE=airdrops forge build

# Build flow contracts
[group("build")]
build-flow:
  FOUNDRY_PROFILE=flow forge build

# Build lockup contracts
[group("build")]
build-lockup:
  FOUNDRY_PROFILE=lockup forge build

# Test all contracts (airdrops, flow, lockup)
[group("test")]
test:
  just test-airdrops
  just test-flow
  just test-lockup
alias ta := test

# Test airdrops contracts
[group("test")]
test-airdrops:
  FOUNDRY_PROFILE=airdrops forge test

# Test flow contracts
[group("test")]
test-flow:
  FOUNDRY_PROFILE=flow forge test

# Test lockup contracts
[group("test")]
test-lockup:
  FOUNDRY_PROFILE=lockup forge test
