import { describe, it, expect, beforeEach } from '@jest/globals';
import {
  createConstructorContext,
  createCircuitContext,
  dummyContractAddress,
} from '@midnight-ntwrk/compact-runtime';
// Import the actual compiled contract and ledger reader from managed output
import { Contract, ledger } from '../managed/contract/index.js';
import contractInfo from '../managed/compiler/contract-info.json';

describe('ZkNumberGuesser Contract & Runtime Tests', () => {
  let contract: Contract;
  let coinPublicKey: string;
  let contractAddress: any;

  beforeEach(() => {
    // Contract has zero Compact witnesses, instantiated with empty witness object
    contract = new Contract({});
    coinPublicKey = '00'.repeat(32);
    contractAddress = dummyContractAddress();
  });

  it('verifies contract metadata: zero witnesses and private circuit argument', () => {
    // The reviewer specifically requires that guess is recognized as a private circuit parameter,
    // not a Compact witness, matching contract-info.json.
    expect(contractInfo.witnesses).toHaveLength(0);
    expect(contractInfo.circuits).toHaveLength(1);
    expect(contractInfo.circuits[0].name).toBe('guess_number');
    expect(contractInfo.circuits[0].proof).toBe(true);
    expect(contractInfo.circuits[0].arguments).toHaveLength(1);
    expect(contractInfo.circuits[0].arguments[0].name).toBe('guess');
    expect(contractInfo.circuits[0].arguments[0].type['type-name']).toBe('Uint');
  });

  it('initializes contract state correctly via constructor', () => {
    const constructorContext = createConstructorContext({}, coinPublicKey);
    const initResult = contract.initialState(constructorContext);

    expect(initResult).toBeDefined();
    expect(initResult.currentContractState).toBeDefined();

    // Verify initial public ledger state via the compiled ledger function
    const initialLedger = ledger(initResult.currentContractState.data);
    expect(initialLedger.is_solved).toBe(false);
    expect(initialLedger.attempts).toBe(0n);
  });

  it('executes guess_number circuit with incorrect guess (increments attempts, remains unsolved)', () => {
    // 1. Initialize contract
    const constructorContext = createConstructorContext({}, coinPublicKey);
    const initResult = contract.initialState(constructorContext);

    // 2. Setup circuit context
    const circuitContext = createCircuitContext(
      contractAddress,
      coinPublicKey,
      initResult.currentContractState.data,
      initResult.currentPrivateState
    );

    // 3. Submit wrong guess (15n != 42n)
    const callResult = contract.circuits.guess_number(circuitContext, 15n);
    expect(callResult).toBeDefined();
    expect(callResult.proofData).toBeDefined();

    // 4. Verify resulting ledger state
    const updatedState = callResult.context.currentQueryContext.state.state;
    const updatedLedger = ledger(updatedState);

    expect(updatedLedger.attempts).toBe(1n);
    expect(updatedLedger.is_solved).toBe(false);
  });

  it('executes guess_number circuit with correct guess (42n marks is_solved = true)', () => {
    // 1. Initialize contract
    const constructorContext = createConstructorContext({}, coinPublicKey);
    const initResult = contract.initialState(constructorContext);

    // 2. Submit wrong guess first
    const context1 = createCircuitContext(
      contractAddress,
      coinPublicKey,
      initResult.currentContractState.data,
      initResult.currentPrivateState
    );
    const callResult1 = contract.circuits.guess_number(context1, 7n);
    const state1 = callResult1.context.currentQueryContext.state.state;

    const ledger1 = ledger(state1);
    expect(ledger1.attempts).toBe(1n);
    expect(ledger1.is_solved).toBe(false);

    // 3. Submit correct guess (42n)
    const context2 = createCircuitContext(
      contractAddress,
      coinPublicKey,
      state1,
      callResult1.context.currentPrivateState
    );
    const callResult2 = contract.circuits.guess_number(context2, 42n);
    const state2 = callResult2.context.currentQueryContext.state.state;

    const ledger2 = ledger(state2);
    expect(ledger2.attempts).toBe(2n);
    expect(ledger2.is_solved).toBe(true);
  });

  it('validates circuit input boundaries and types', () => {
    const constructorContext = createConstructorContext({}, coinPublicKey);
    const initResult = contract.initialState(constructorContext);

    const circuitContext = createCircuitContext(
      contractAddress,
      coinPublicKey,
      initResult.currentContractState.data,
      initResult.currentPrivateState
    );

    // Should reject non-bigint input
    expect(() => {
      // @ts-expect-error testing runtime validation
      contract.circuits.guess_number(circuitContext, 42);
    }).toThrow();

    // Should reject negative values
    expect(() => {
      contract.circuits.guess_number(circuitContext, -1n);
    }).toThrow();

    // Should reject values exceeding Uint32 max (4294967295)
    expect(() => {
      contract.circuits.guess_number(circuitContext, 4294967296n);
    }).toThrow();
  });

  it('validates zero-knowledge proof data construction for private guess input', () => {
    const constructorContext = createConstructorContext({}, coinPublicKey);
    const initResult = contract.initialState(constructorContext);

    const circuitContext = createCircuitContext(
      contractAddress,
      coinPublicKey,
      initResult.currentContractState.data,
      initResult.currentPrivateState
    );

    const guessVal = 42n;
    const callResult = contract.circuits.guess_number(circuitContext, guessVal);

    // Verify input contains serialized private guess value
    expect(callResult.proofData.input.value).toBeDefined();
    expect(callResult.proofData.input.alignment).toBeDefined();
    // Verify output is empty tuple
    expect(callResult.proofData.output.value).toEqual([]);
    // Public transcript contains ledger query & state updates (is_solved, attempts), not raw secret
    expect(callResult.proofData.publicTranscript.length).toBeGreaterThan(0);
  });
});
