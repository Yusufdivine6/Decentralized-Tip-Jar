import { describe, it, beforeEach, expect } from 'vitest';

// Mocking the Tip Jar contract for testing purposes
const mockTipJar = {
  state: {
    totalTips: 0,
    userTips: {} as Record<string, number>, // Maps users to their tip amounts
  },
  sendTip: (amount: number, caller: string) => {
    if (amount <= 0) {
      return { error: 100 }; // Invalid tip amount
    }
    mockTipJar.state.totalTips += amount;
    if (!mockTipJar.state.userTips[caller]) {
      mockTipJar.state.userTips[caller] = 0;
    }
    mockTipJar.state.userTips[caller] += amount;
    return { value: amount };
  },
  getTotalTips: () => mockTipJar.state.totalTips,
  getUserTips: (user: string) => mockTipJar.state.userTips[user] || 0,
};

describe('Decentralized Tip Jar', () => {
  let user1: string, user2: string;

  beforeEach(() => {
    // Initialize mock state and user principals
    user1 = 'ST1234...';
    user2 = 'ST5678...';

    mockTipJar.state = {
      totalTips: 0,
      userTips: {},
    };
  });

  it('should allow a user to send a tip', () => {
    const result = mockTipJar.sendTip(100, user1);
    expect(result).toEqual({ value: 100 });
    expect(mockTipJar.state.totalTips).toBe(100);
    expect(mockTipJar.state.userTips[user1]).toBe(100);
  });

  it('should accumulate tips from multiple users', () => {
    mockTipJar.sendTip(100, user1);
    mockTipJar.sendTip(200, user2);

    expect(mockTipJar.state.totalTips).toBe(300);
    expect(mockTipJar.state.userTips[user1]).toBe(100);
    expect(mockTipJar.state.userTips[user2]).toBe(200);
  });

  it('should track individual contributions accurately', () => {
    mockTipJar.sendTip(50, user1);
    mockTipJar.sendTip(150, user1);

    expect(mockTipJar.state.userTips[user1]).toBe(200);
  });

  it('should return 0 for a user with no contributions', () => {
    const tips = mockTipJar.getUserTips(user2);
    expect(tips).toBe(0);
  });

  it('should reject invalid tip amounts', () => {
    const result = mockTipJar.sendTip(0, user1);
    expect(result).toEqual({ error: 100 });
  });
});
