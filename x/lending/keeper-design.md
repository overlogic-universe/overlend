# 🧠 1. Peran Keeper (Supaya Tidak Salah Kaprah)

Dalam Cosmos SDK:

> **Keeper = domain service layer (business logic + state access)**

Bukan:

* bukan controller
* bukan hanya storage wrapper

---

## 🔥 Prinsip utama keeper:

* semua state access lewat keeper
* semua business logic lewat keeper
* msg server hanya “entry point”

---

# 🧱 2. Struktur Keeper `x/lending`

---

## 🔷 Core Keeper

Struktur utama:

```go
type Keeper struct {
    storeKey storetypes.StoreKey

    bankKeeper    types.BankKeeper
    oracleKeeper  types.OracleKeeper
    accountKeeper types.AccountKeeper

    authority string // gov authority
}
```

---

## 🧠 Insight

* dependency harus interface (di `types/expected_keepers.go`)
* jangan import module lain langsung

👉 ini best practice untuk modularity

---

# 🔌 3. Expected Keepers (Dependency Interface)

---

## 📁 `types/expected_keepers.go`

Contoh (konseptual):

---

### BankKeeper

* transfer token
* cek balance

---

### OracleKeeper

* ambil harga
* validasi freshness

---

### AccountKeeper

* address handling
* module account

---

## ⚠️ Rule penting:

👉 hanya expose method yang kamu butuhkan
👉 jangan expose seluruh keeper

---

# 🧩 4. Internal Keeper API (CORE DESIGN)

Sekarang kita define fungsi inti.

---

# 🔷 A. Market Management

---

## Fungsi:

* GetMarket(denom)
* SetMarket(market)
* IsMarketEnabled(denom)

---

## Advanced:

* ValidateMarketParams()
* UpdateMarketParams()

---

---

# 🔷 B. Collateral Management

---

## Fungsi:

* GetCollateral(address, denom)
* SetCollateral(address, denom, amount)
* AddCollateral(...)
* SubCollateral(...)

---

## Insight:

👉 semua update collateral harus lewat sini
👉 tidak boleh langsung set state dari luar

---

---

# 🔷 C. Debt Management

---

## Fungsi:

* GetDebt(address, denom)
* SetDebt(...)
* IncreaseDebt(...)
* DecreaseDebt(...)

---

## Penting:

👉 harus sync dengan interest index

---

---

# 🔷 D. Market Accounting

---

## Fungsi:

* GetTotalSupply(denom)
* GetTotalBorrow(denom)
* IncreaseTotalBorrow(...)
* DecreaseTotalBorrow(...)

---

## Interest:

* GetBorrowIndex(denom)
* UpdateInterest(denom)

---

👉 ini harus selalu dipanggil sebelum operasi finansial

---

---

# 🔷 E. Risk Engine (CORE LOGIC)

---

## Fungsi:

* CalculateCollateralValue(address)
* CalculateDebtValue(address)
* CalculateBorrowLimit(address)
* CalculateHealthFactor(address)

---

## Validasi:

* ValidateBorrow(...)
* ValidateWithdraw(...)

---

👉 ini jantung safety

---

---

# 🔷 F. Liquidation Engine

---

## Fungsi:

* IsLiquidatable(address)
* CalculateLiquidation(...)
* ExecuteLiquidation(...)

---

👉 harus deterministic & aman

---

---

# 🔷 G. Oracle Integration

---

## Fungsi:

* GetPrice(denom)
* ValidatePrice(...)

---

👉 jangan percaya langsung ke oracle tanpa validasi

---

# 🔄 5. Public API vs Internal API

---

## 🔷 Public (dipakai MsgServer)

* Deposit
* Borrow
* Repay
* Withdraw
* Liquidate

---

## 🔷 Internal (helper)

* calculate health
* update interest
* risk check
* accounting update

---

👉 separation ini penting untuk clean code

---

# 🧠 6. Msg Server Design

---

## Prinsip:

> MsgServer = adapter dari transaction → keeper

---

## Contoh flow:

### MsgBorrow

1. validate basic msg
2. call keeper.Borrow(...)
3. return response

---

👉 jangan taruh business logic di MsgServer

---

# 🔥 7. Flow Implementasi di Keeper (REAL)

---

## 🔷 Borrow Flow (keeper level)

Urutan WAJIB:

1. `UpdateInterest(denom)`
2. `SyncUserDebt(address)`
3. `price := GetPrice(denom)`
4. `ValidateBorrow(address, amount)`
5. `IncreaseDebt(address, denom)`
6. `IncreaseTotalBorrow(denom)`
7. `bankKeeper.SendCoins(...)`

---

👉 urutan ini tidak boleh salah

---

# ⚠️ 8. Error Handling (Production Style)

---

## Gunakan error terstruktur:

```go
var ErrInsufficientCollateral = errors.Register(...)
var ErrMarketNotEnabled = errors.Register(...)
```

---

## Jangan:

* pakai error string biasa
* panic (kecuali fatal)

---

---

# 🧪 9. Keeper Testing Strategy

---

## Unit test:

* test setiap fungsi keeper
* mock dependency (oracle, bank)

---

## Simulation:

* random operation
* invariant check

---

👉 ini standar Cosmos production

---

# 🔐 10. Security Pattern (WAJIB)

---

## 🔥 1. Check-Effects-Interactions

Urutan:

1. validate
2. update state
3. transfer token

---

👉 hindari reentrancy / inconsistent state

---

## 🔥 2. Always sync interest first

Kalau tidak:

* user bisa exploit bunga

---

## 🔥 3. Oracle validation

* cek stale
* cek invalid

---

---

# 🧠 11. Extensibility (Untuk Credit Layer)

---

Design dari awal:

Tambahkan di keeper:

* IsIsolatedMarket(denom)
* ValidateIsolatedBorrow(...)

---

👉 supaya nanti:

* tidak rewrite besar

---

# 🧭 12. Dependency Flow

---

```text
Msg → MsgServer → Keeper → Store + Other Modules
```

---

👉 jangan lompat langsung ke store dari MsgServer

---

# 🔥 13. Anti-Pattern (JANGAN DILAKUKAN)

---

## ❌ Business logic di MsgServer

---

## ❌ Direct store access dari luar keeper

---

## ❌ Tidak update interest sebelum operasi

---

## ❌ Tidak validasi oracle

---

## ❌ Coupling antar module terlalu kuat

---

# 🧠 14. Mental Model

---

Keeper kamu adalah:

> **“core banking engine”**

Dia harus:

* deterministic
* aman
* konsisten
* predictable

---

# 🔚 FINAL RESULT

Sekarang kamu sudah punya:

✅ Domain model
✅ Invariants
✅ Store layout
✅ Financial math
✅ Keeper architecture

👉 Ini sudah setara design protocol serius

---