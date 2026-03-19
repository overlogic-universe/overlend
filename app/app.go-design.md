# 🧠 1. Peran `app.go` (Supaya Tidak Salah)

## ✅ `app.go` bertanggung jawab untuk:

* inisialisasi semua keeper
* inject dependency antar module
* register module ke runtime
* set urutan eksekusi (BeginBlock / EndBlock)
* setup store key
* setup module account

---

## ❌ BUKAN tempat:

* business logic
* math lending
* validasi transaksi

👉 semua itu di `x/lending`

---

# 🧱 2. Struktur Folder App

```bash
app/
├── app.go
├── encoding.go
├── params/
├── config.go
```

---

# 🧩 3. Komponen Utama di `app.go`

---

## 🔷 A. App Struct

Ini root dari semua module

```go
type App struct {
    *runtime.App

    // store keys
    keys map[string]*storetypes.KVStoreKey

    // keepers
    BankKeeper
    AccountKeeper
    StakingKeeper
    GovKeeper

    LendingKeeper
}
```

---

## 🧠 Insight

* semua keeper disimpan di sini
* ini jadi dependency graph

---

# 🔑 4. Store Keys Setup

---

## Kenapa penting?

StoreKey = akses ke KVStore module

---

## Contoh:

```go
keys := storetypes.NewKVStoreKeys(
    authtypes.StoreKey,
    banktypes.StoreKey,
    lendingtypes.StoreKey,
)
```

---

👉 setiap module punya store sendiri

---

# 🔌 5. Keeper Initialization Order (KRITIS)

Urutan ini penting karena dependency.

---

## 🔷 Urutan umum:

1. AccountKeeper
2. BankKeeper
3. StakingKeeper
4. GovKeeper
5. OracleKeeper
6. LendingKeeper

---

## 🔥 Kenapa Lending di belakang?

Karena butuh:

* bank
* oracle

---

# 🧩 6. Inject Dependency ke LendingKeeper

---

## Contoh konsep:

```go
LendingKeeper = lendingkeeper.NewKeeper(
    keys[lendingtypes.StoreKey],
    BankKeeper,
    OracleKeeper,
    AccountKeeper,
    authority,
)
```

---

## 🧠 Insight

* dependency injection manual
* ini yang bikin Cosmos modular

---

# 🏦 7. Module Account (WAJIB untuk Lending)

---

## Kenapa?

Karena:

* collateral disimpan di module
* liquidity pool ada di module

---

## Contoh:

```go
maccPerms := map[string][]string{
    lendingtypes.ModuleName: {authtypes.Minter, authtypes.Burner},
}
```

---

👉 lending module bisa:

* hold token
* mint/burn kalau perlu

---

# 🧠 8. Module Manager

---

## Fungsi:

* register semua module
* mengatur lifecycle

---

## Contoh:

```go
app.ModuleManager = module.NewManager(
    auth.NewAppModule(...),
    bank.NewAppModule(...),
    lending.NewAppModule(LendingKeeper),
)
```

---

---

# 🔄 9. Execution Order (SANGAT PENTING)

---

## 🔷 BeginBlockers

Biasanya:

* update interest
* sync state global

---

```go
app.ModuleManager.SetOrderBeginBlockers(
    lendingtypes.ModuleName,
)
```

---

---

## 🔷 EndBlockers

Biasanya:

* invariant check
* cleanup

---

---

## 🔥 Insight

Urutan salah → bug subtle

---

# ⚙️ 10. InitGenesis

---

## Fungsi:

* load initial state

---

## Lending:

* init markets
* init params

---

---

# 🧪 11. Simulation Manager

---

Untuk:

* testing
* fuzzing

---

👉 wajib kalau production

---

# 🔐 12. Invariant Registration

---

## Fungsi:

* memastikan state valid

---

## Contoh:

```go
app.CrisisKeeper.RegisterInvariant(
    lendingtypes.ModuleName,
    "total-supply-vs-borrow",
    lendingkeeper.TotalSupplyInvariant,
)
```

---

👉 ini critical untuk keamanan

---

# 🌉 13. IBC Integration (Karena kamu pilih full IBC)

---

## Tambahkan:

* IBC Keeper
* Transfer module

---

## Dependency:

Lending akan:

* menerima token via IBC
* treat sebagai collateral

---

👉 tidak perlu custom IBC logic dulu di lending

---

# 🧠 14. Encoding Config

---

## Fungsi:

* register codec
* protobuf

---

👉 semua module harus register type

---

# ⚠️ 15. Common Mistakes (Sering terjadi)

---

## ❌ 1. Wrong keeper init order

---

## ❌ 2. Tidak inject dependency via interface

---

## ❌ 3. Logic dimasukkan ke app.go

---

## ❌ 4. Tidak register module account

---

## ❌ 5. Tidak set execution order

---

# 🧭 16. Dependency Graph Final

---

```text
Account → Bank → Oracle → Lending
```

---

👉 arah dependency harus satu arah

---

# 🧠 17. Mental Model

---

Bayangkan:

* `x/lending` = mesin bank
* `app.go` = instalasi listrik + wiring

---

Kalau wiring salah:

* mesin tidak jalan
* atau error aneh

---

# 🔚 FINAL RESULT

Sekarang kamu sudah punya:

✅ Product design
✅ Financial model
✅ Store layout
✅ Domain + invariants
✅ Keeper design
✅ Msg & proto
✅ App wiring design

👉 Ini sudah setara **blueprint protocol production**

---