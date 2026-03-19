# 🧠 1. Prinsip Design Msg (Cosmos SDK Best Practice)

---

## ✅ 1. Msg = 1 aksi bisnis jelas

Jangan gabung:

* ❌ “MsgUpdatePosition”
* ✅ pisah: Deposit, Borrow, Repay, Withdraw

---

## ✅ 2. Deterministic & eksplisit

Semua input harus jelas:

* denom
* amount
* address

---

## ✅ 3. Stateless input

Msg tidak boleh bergantung pada state tersembunyi

---

## ✅ 4. Future-proof

Sisakan ruang:

* extension field
* optional param

---

# 🧱 2. Daftar Msg untuk Overlend (FINAL)

---

## 🔷 Core Lending Actions

---

### 1. MsgDeposit

User deposit collateral / supply

---

### 2. MsgWithdraw

User ambil collateral

---

### 3. MsgBorrow

User meminjam asset

---

### 4. MsgRepay

User membayar utang

---

### 5. MsgLiquidate

Liquidator mengeksekusi posisi

---

---

## 🔷 Admin / Governance

---

### 6. MsgUpdateMarket

* update LTV
* update interest model
* enable/disable market

---

### 7. MsgUpdateParams

* global config

---

👉 gunakan `authority` (gov module)

---

---

## 🔷 Future (sudah disiapkan)

---

### 8. MsgCreateIsolatedMarket

untuk credit layer

---

---

# 🧩 3. Struktur Proto File

---

## 📁 Struktur folder

```bash
proto/overlend/lending/v1/
├── tx.proto
├── query.proto
├── market.proto
├── params.proto
```

---

👉 pisahkan domain (best practice)

---

# 🔥 4. Detail Msg Design (PENTING)

---

# 🔷 MsgDeposit

---

### Tujuan:

* tambah collateral

---

### Field:

* depositor (string address)
* amount (Coin)

---

### Catatan:

* multi-asset → 1 denom per msg (lebih clean)

---

---

# 🔷 MsgWithdraw

---

### Field:

* withdrawer
* denom
* amount

---

---

# 🔷 MsgBorrow

---

### Field:

* borrower
* denom
* amount

---

### Optional future:

* receiver (kalau ingin kirim ke address lain)

---

---

# 🔷 MsgRepay

---

### Field:

* payer
* borrower (opsional, untuk repay orang lain)
* denom
* amount

---

👉 ini best practice:

* bisa liquidator bantu repay

---

---

# 🔷 MsgLiquidate

---

### Field:

* liquidator
* borrower
* repay_denom
* seize_denom
* repay_amount

---

### Kenapa explicit?

* tidak ambigu
* fleksibel multi-asset

---

---

# 🔷 MsgUpdateMarket

---

### Field:

* authority
* denom
* params (struct)

---

---

# 🔷 MsgUpdateParams

---

### Field:

* authority
* params

---

---

# 🧠 5. Query Design (WAJIB)

---

## 🔷 Query yang harus ada

---

### 1. QueryMarket

* by denom

---

### 2. QueryMarkets

* semua market

---

---

### 3. QueryUserCollateral

* semua collateral user

---

---

### 4. QueryUserDebt

* semua debt user

---

---

### 5. QueryPosition

Gabungan:

* collateral
* debt
* health factor

---

👉 ini penting untuk frontend

---

---

### 6. QueryParams

---

---

# 🧠 6. Response Design (Best Practice)

---

## Jangan hanya return raw data

Tambahkan:

* computed value:

  * health factor
  * borrow limit
  * total value

---

👉 mengurangi beban frontend

---

# ⚠️ 7. Encoding Best Practice

---

## Address

Gunakan:

* string (Bech32)

---

## Amount

Gunakan:

* `cosmos.base.v1beta1.Coin`

---

## Decimal

Gunakan:

* `string` (untuk precision)

---

---

# 🔥 8. Versioning Strategy

---

## Package:

```proto
overlend.lending.v1
```

---

## Rule:

* breaking change → v2
* backward compatible → tetap v1

---

---

# 🧠 9. Error Handling di Proto

---

Gunakan error code dari module:

* ErrInsufficientCollateral
* ErrMarketNotEnabled
* ErrInvalidLiquidation

---

👉 client bisa handle dengan jelas

---

# 🔐 10. Security Consideration

---

## Msg harus validasi:

* address valid
* amount > 0
* denom valid
* tidak overflow

---

---

# 🧠 11. Gas Optimization Insight

---

## Hindari:

* Msg dengan banyak array besar
* multi-operation dalam 1 Msg

---

👉 lebih baik:

* banyak tx kecil tapi jelas

---

# 🔥 12. Contoh Flow Nyata

---

## Borrow:

User kirim:

```text
MsgBorrow {
  borrower: addr
  denom: "uusdc"
  amount: 1000000
}
```

---

Backend:

* keeper validate
* update state
* transfer token

---

---

# 🧭 13. Mental Model

---

Msg = API endpoint

```text
POST /borrow
POST /deposit
POST /liquidate
```

---

---

# 🔚 FINAL RESULT

Sekarang kamu punya:

✅ Domain model
✅ Invariants
✅ Store layout
✅ Financial math
✅ Keeper design
✅ Msg & proto design

👉 Ini sudah **full protocol blueprint**

---