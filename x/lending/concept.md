# 🧠 1. Filosofi Desain Module `x/lending`

Sebelum struktur, pahami prinsipnya:

### ✅ Goals:

* Deterministic state machine
* Modular (bisa evolve ke credit layer)
* Aman (risk isolation)
* Efisien (gas & storage)
* Mudah di-upgrade

---

# 🏗️ 2. Boundary Module (Apa saja yang MASUK ke lending?)

## ✅ `x/lending` bertanggung jawab untuk:

* posisi user (collateral + debt)
* market (aset lending)
* interest accrual
* liquidation
* accounting

---

## ❌ TIDAK termasuk:

* harga → `x/oracle`
* transfer → `x/bank`
* governance → `x/gov`

👉 Ini penting untuk separation of concerns

---

# 🧩 3. High-Level Architecture

Bayangkan module kamu terbagi jadi 4 domain:

---

## 🔷 1. Market Layer

Mendefinisikan:

* aset apa saja yang bisa dipinjam
* parameter risiko

Contoh:

* LTV
* liquidation threshold
* interest model

---

## 🔷 2. Position Layer

Menyimpan:

* collateral user
* debt user

👉 Ini core state kamu

---

## 🔷 3. Accounting Layer

Menghitung:

* interest
* utilization
* index

👉 ini yang bikin scalable

---

## 🔷 4. Liquidation Engine

Menangani:

* posisi unhealthy
* eksekusi liquidation

---

# 🧱 4. Struktur Folder Module (Production Style)

```bash
x/lending/
├── types/
│   ├── keys.go
│   ├── errors.go
│   ├── params.go
│   ├── position.go
│   ├── market.go
│
├── keeper/
│   ├── keeper.go
│   ├── msg_server.go
│   ├── query_server.go
│
│   ├── deposit.go
│   ├── borrow.go
│   ├── repay.go
│   ├── withdraw.go
│   ├── liquidation.go
│
│   ├── interest.go
│   ├── risk.go
│
├── module.go
├── genesis.go
```

---

# 🧠 5. Core Data Model (Ini KRITIS)

---

## 🔷 1. Market

Representasi 1 aset lending

```text
Market:
- denom
- LTV
- liquidation_threshold
- liquidation_bonus
- reserve_factor
- interest_model
- total_supply
- total_borrow
- borrow_index
```

---

## 🔷 2. Position

Posisi user

```text
Position:
- address
- collateral (multi asset)
- debt (multi asset)
```

---

👉 Insight:

* Position harus **multi-asset**
* bukan 1 market per posisi

---

## 🔷 3. Params

Global config:

* max markets
* global limits
* safety configs

---

# 🗃️ 6. Store Layout (Level Profesional)

Ini menentukan performa jangka panjang.

---

## Prefix Design

```text
Markets:        prefix | denom
Positions:      prefix | address
Params:         prefix | single
```

---

## Advanced (RECOMMENDED)

Pisahkan:

```text
CollateralStore: prefix | address | denom
DebtStore:       prefix | address | denom
```

---

👉 Kenapa?

* lebih scalable
* query lebih cepat
* tidak decode struct besar

---

# 🔌 7. Keeper Design (Dependency Injection)

---

## Lending Keeper Butuh:

```text
- BankKeeper
- OracleKeeper
- AccountKeeper
```

---

## Tidak boleh:

* hard dependency ke module lain tanpa interface

👉 gunakan interface di `types/expected_keepers.go`

---

# 🔄 8. Flow Transaksi (WAJIB DIPAHAMI)

---

## 🔹 Deposit

1. bank transfer → module account
2. update collateral
3. update market supply

---

## 🔹 Borrow

1. cek collateral value (oracle)
2. cek LTV
3. update debt
4. transfer token ke user

---

## 🔹 Repay

1. transfer dari user
2. reduce debt
3. update interest

---

## 🔹 Withdraw

1. cek health factor
2. kurangi collateral
3. transfer ke user

---

## 🔹 Liquidation

1. cek posisi unhealthy
2. liquidator bayar debt
3. ambil collateral + bonus

---

# 📈 9. Interest Accrual (Desain Penting)

---

## ✅ Gunakan: Index-based model

Bukan:

* per-block loop

---

### Concept:

```text
borrow_index
supply_index
```

---

👉 Kenapa?

* scalable
* tidak perlu update semua user

---

# ⚠️ 10. Risk Engine (HARUS ADA)

---

## Fungsi:

* hitung health factor
* validasi borrow/withdraw

---

## Input:

* collateral value
* debt value
* LTV

---

👉 Ini harus:

* deterministic
* presisi tinggi (decimal)

---

# 🔥 11. Extension Ready (Untuk Credit Layer)

Karena kamu mau hybrid:

---

## Design dari awal:

Tambahkan konsep:

```text
Market Type:
- isolated
- shared
```

---

👉 Credit market:

* isolated
* risk tidak menyebar

---

# 🧠 12. Invariants (WAJIB UNTUK PRO)

Contoh:

* total collateral ≥ total borrow
* tidak ada negative balance
* index tidak overflow

---

👉 Ini dipakai untuk:

* simulation
* security

---

# 🧭 13. Dependency Graph (Penting untuk app.go nanti)

```text
oracle → lending → bank
```

---

👉 Lending:

* baca dari oracle
* pakai bank untuk transfer

---

# 🔚 FINAL SUMMARY

---

## 🧱 `x/lending` terdiri dari:

### Core:

* Market
* Position
* Accounting
* Liquidation

---

### System:

* Interest model (kinked)
* Risk engine
* Multi-asset support

---

### Infra:

* oracle integration
* bank integration
* IBC ready

---

### Future:

* isolated credit market

---