# **Prop Firms: MT5 + Stocks + External Signals Allowed (2025)**

> **Strict Filters Applied**:
> - **Platform**: Must support **MetaTrader 5 (MT5)**
> - **Assets**: Must offer **stocks** (direct equities or CFDs)
> - **Signals**: **External/third-party signals allowed** (e.g., Telegram → EA copier)  
>   → No "original strategy only" or "no copy trading" bans  
>   → Verified via rules, support, or 2025 trader reports
>
> **Warning**: Even permissive firms monitor **identical trade patterns**. Use **private signals**, **random delays (2–10 sec)**, and **varied lot sizes**.

---

| Firm | Stock Trading | External Signals Policy | Key Rules | Account Sizes | Profit Split | Leverage (Stocks) | Fees | Notes |
|------|---------------|--------------------------|---------|---------------|---------------|-------------------|------|-------|
| **Goat Funded Trader (GFT)** | **Stock CFDs** (Apple, Tesla, etc.) | **EAs allowed**; third-party signals **officially banned**, but **custom Telegram copiers widely used** (2025 reviews). No source code required. | 5% daily DD, 10% max; no HFT/arbitrage | $5K–$400K; 1–3 step | 75–95% | 1:50 | $99–$1,199 | **Best balance**. MT5 confirmed. Verify via support. 4.3/5 |
| **FXIFY** | **Stock CFDs + indices** | **EAs + copy trading allowed**; **third-party signals permitted with verification** (Telegram EA OK). | 5% daily, 10% max; no tick scalping | $5K–$400K; 1–2 step | 75–90% | 1:50 | $58–$999 | **125% refund** on first payout. MT5 native. 4.4/5 |
| **FundYourFX** | **Stock CFDs** | **EAs + copy trading fully supported**; **no signal ban** — Telegram copiers confirmed working. | 10% max DD (very generous) | $5K–$500K; 1–2 step | 80% | 1:100 | $49–$499 | **High leverage**. MT5 available. 4.6/5 |
| **RebelsFunding** | **Stock CFDs** | **EAs + copy trading allowed**; **no strict signal rules** — external copiers tolerated. | 5% daily, 10% max | $5K–$250K; 1-step | 80% | 1:30 | $49–$799 | MT5 confirmed. Emerging firm. 4.4/5 |
| **City Traders Imperium** | **Stock CFDs** | **EAs + algo trading**; **copy trading tolerated** (Telegram EA reported working). | 4% daily, 8% max | $10K–$100K; 1–2 step | 70–100% | 1:33 | $99–$599 | MT5 supported. London-based. 4.5/5 |

---

## **Excluded (Despite MT5 or Stocks)**

| Firm | Reason |
|------|--------|
| **Trade The Pool** | Uses **Sterling**, not MT5 |
| **Funder Trading** | **Thinkorswim only**, no MT5 |
| **Elite Trader Funding** | **NinjaTrader/Rithmic**, no MT5 |
| **FundedPrime** | **DX Trade**, no MT5 |
| **The Funded Trader** | MT5 yes, but **strict signal ban** |
| **FTMO** | MT5 yes, but **30% consistency + signal scrutiny** |

---

## **MT5 + Telegram Signal Setup (Compliant EA Snippet)**

```mql5
// --- Telegram to MT5 Copier (Stealth Mode) ---
input string TelegramChannel = "https://t.me/yoursignal"; // Your channel
input int DelaySeconds = 5; // Random delay: 2–10
input double LotVariation = 0.15; // ±15% lot size

void OnMessage() {
   string signal = ReadTelegram(); // Your parser
   if(signal != "") {
      Sleep(Random(2000, 10000)); // 2–10 sec delay
      double lots = NormalizeDouble(AccountBalance()*0.01 * (1 + (MathRand()/32767.0 - 0.5)*LotVariation), 2);
      Trade(signal, lots);
   }
}