# 🧠 1. Apa itu Domain Model (Dalam Cosmos SDK)?

Domain model = **representasi state bisnis kamu di blockchain**

Bukan sekadar struct, tapi:

* entitas apa saja yang ada
* relasi antar entitas
* aturan yang mengikat mereka

---

# 🧱 2. Domain Model Overlend (FINAL)

Kita bagi jadi 5 entitas utama:

---

## 🔷 1. Market (inti sistem)

### Fungsi:

Representasi satu aset lending (ATOM, USDC, dll)

---

### Field (konseptual):

* denom
* market_type (shared / isolated)
* ltv
* liquidation_threshold
* liquidation_bonus
* reserve_factor
* close_factor
* borrow_cap
* supply_cap
* interest_model
* oracle_config
* is_enabled

---

### Insight:

Market = tempat semua logic finansial terjadi

---

## 🔷 2. UserCollateral

### Fungsi:

Menyimpan collateral per user per asset

---

### Field:

* address
* denom
* amount

---

👉 disimpan granular (per asset)

---

## 🔷 3. UserDebt

### Fungsi:

Menyimpan utang user per asset

---

### Field:

* address
* denom
* principal
* interest_index_snapshot

---

👉 pakai index-based accrual

---

## 🔷 4. MarketState (Accounting Layer)

### Fungsi:

State global per market

---

### Field:

* total_supply
* total_borrow
* borrow_index
* supply_index
* last_updated_time

---

👉 ini jantung performa sistem

---

## 🔷 5. Params (Global)

### Fungsi:

Konfigurasi global

---

### Field:

* max_markets
* max_collateral_assets_per_user
* liquidation_enabled
* oracle_staleness_limit
* safety_limits

---

---

# 🧩 3. Relasi Antar Entitas

---

## User ↔ Market

User bisa:

* punya collateral di banyak market
* punya debt di banyak market

---

## Market ↔ MarketState

1:1 relationship

---

## Market ↔ Oracle

Market bergantung pada:

* harga dari oracle

---

## Market Type

```text
shared     → risk digabung
isolated   → risk terpisah
```

---

# 🧠 4. Invariants (PALING KRITIS)

Ini adalah **aturan yang harus selalu benar**
Kalau dilanggar → protocol rusak / bisa rugi besar

---

# 🔥 A. Global Invariants

---

## ✅ 1. No Negative State

* tidak boleh ada:

  * negative collateral
  * negative debt
  * negative supply

---

## ✅ 2. Total Supply ≥ Total Borrow (per market)

Kenapa:

* tidak boleh pinjam lebih dari liquidity

---

## ✅ 3. Index Monotonic

* borrow_index hanya boleh naik
* tidak boleh turun

---

## ✅ 4. Interest Consistency

* total debt harus konsisten dengan index

---

# 🔥 B. User-Level Invariants

---

## ✅ 5. Health Safety (Shared Market)

Untuk semua user:

```text
debt_value ≤ borrow_limit
```

---

👉 Ini dicek saat:

* borrow
* withdraw

---

## ✅ 6. Liquidation Condition

```text
health_factor < 1 → boleh dilikuidasi
```

---

## ✅ 7. Collateral Tidak Bisa Negatif

Setelah withdraw / liquidation:

* collateral ≥ 0

---

## ✅ 8. Debt Tidak Bisa Negatif

Setelah repay / liquidation:

* debt ≥ 0

---

# 🔥 C. Market-Level Invariants

---

## ✅ 9. Parameter Validity

Untuk setiap market:

* 0 < LTV < liquidation_threshold < 1
* liquidation_bonus > 0
* reserve_factor < 1
* close_factor ≤ 1

---

## ✅ 10. Caps Enforcement

* total_supply ≤ supply_cap
* total_borrow ≤ borrow_cap

---

# 🔥 D. Isolated Market Invariants (PENTING untuk Credit Layer)

---

## ✅ 11. Risk Isolation

Untuk market `isolated`:

👉 collateral dari market ini:

* tidak boleh dipakai untuk borrow di market lain

---

## ✅ 12. Debt Isolation

* debt di isolated market tidak boleh:

  * mempengaruhi shared pool

---

👉 ini critical untuk mencegah:

* systemic failure

---

# 🔥 E. Liquidation Invariants

---

## ✅ 13. Close Factor Enforcement

* liquidator hanya boleh repay sebagian debt

---

## ✅ 14. Collateral Seizure Correctness

* collateral yang diambil:

  * sesuai harga oracle
  * termasuk bonus
  * tidak melebihi collateral user

---

## ✅ 15. Protocol Fee Correctness

* fee tidak boleh lebih besar dari liquidation bonus

---

# 🔥 F. Oracle Invariants

---

## ✅ 16. Price Validity

* harga tidak boleh:

  * nol
  * negatif

---

## ✅ 17. Price Freshness

* harga tidak boleh stale (lebih lama dari threshold)

---

## ✅ 18. Price Deviation Check

* perubahan harga ekstrem harus ditolak / dibatasi

---

# 🧠 5. Constraint Operasional (Real Execution Rules)

---

## Borrow Constraint

* market aktif
* liquidity cukup
* posisi tetap sehat

---

## Withdraw Constraint

* posisi tetap sehat setelah withdraw

---

## Liquidation Constraint

* hanya jika unhealthy
* sesuai close factor

---

# 🧪 6. Invariants untuk Simulation Testing

Nanti kamu akan butuh ini untuk `simapp`:

---

## Contoh invariant function:

* check total collateral vs total debt
* check semua user tidak violate health (kecuali yang liquidatable)
* check index tidak overflow
* check store consistency

---

👉 Ini wajib untuk:

* production readiness
* audit

---

# 🔥 7. Insight Level Senior

---

## ⚠️ Fakta penting:

> 90% bug DeFi terjadi karena:

* salah math
* salah invariant
* edge case tidak dipikirkan

---

## 🔑 Prinsip:

* invariant dulu → baru code
* semua state transition harus menjaga invariant

---

# 🧭 8. Mental Model (Supaya Nempel)

Bayangkan:

* Market = “bank”
* UserCollateral = “tabungan jaminan”
* UserDebt = “utang”
* MarketState = “ledger bank”
* Invariants = “aturan hukum bank”

---

# 🔚 FINAL RESULT

Sekarang kamu sudah punya:

✅ Product design
✅ Architecture
✅ Store layout
✅ Financial math
✅ Domain model
✅ Invariants

👉 Ini sudah level **protocol design lengkap**

---