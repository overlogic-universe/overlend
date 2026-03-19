# 🧠 1. Prinsip Dasar Store Layout (WAJIB DIPAHAMI)

Sebelum detail, ini rule yang dipakai di protocol besar:

---

## ✅ 1. Jangan simpan struct besar kalau tidak perlu

* mahal di decode
* boros gas

---

## ✅ 2. Gunakan prefix kecil & konsisten

* cepat di query
* mudah di-iterate

---

## ✅ 3. Pisahkan state granular

* collateral ≠ debt ≠ market

---

## ✅ 4. Optimize untuk read pattern (bukan write)

👉 karena query jauh lebih sering

---

# 🧱 2. Daftar State yang Kita Butuhkan

Dari desain sebelumnya, kita punya:

---

## 🔹 Market State

* config + accounting

---

## 🔹 User State

* collateral
* debt

---

## 🔹 Global State

* params

---

## 🔹 Interest State

* index

---

# 🗂️ 3. Prefix Design (FINAL)

Gunakan byte prefix (best practice Cosmos):

```text
0x01 → Markets
0x02 → Collateral
0x03 → Debt
0x04 → Params
0x05 → Interest Index
0x06 → Total Supply
0x07 → Total Borrow
```

---

# 🔍 4. Detail Key Structure (KRITIS)

---

# 🔷 A. Markets

## Key:

```text
0x01 | denom
```

## Value:

```text
Market struct
```

---

### Kenapa?

* lookup cepat per asset
* tidak perlu scan

---

# 🔷 B. Collateral (GRANULAR)

## Key:

```text
0x02 | address | denom
```

## Value:

```text
amount (sdk.Int)
```

---

### Kenapa TIDAK pakai struct Position?

❌ Ini buruk:

```go
Position {
  Collateral []Coin
}
```

👉 karena:

* decode berat
* update 1 asset → rewrite semua

---

### ✅ Ini best practice:

* per asset
* per user

👉 scalable

---

# 🔷 C. Debt

## Key:

```text
0x03 | address | denom
```

## Value:

```text
amount (sdk.Dec atau sdk.Int + index)
```

---

### Kenapa dipisah dari collateral?

* read lebih cepat
* logic jelas
* tidak konflik update

---

# 🔷 D. Params

## Key:

```text
0x04
```

## Value:

```text
Params struct
```

---

# 🔷 E. Interest Index

## Key:

```text
0x05 | denom
```

## Value:

```text
borrow_index
supply_index
last_updated_block
```

---

### Kenapa ini penting?

👉 ini core scaling:

* tidak update semua user
* hanya update index

---

# 🔷 F. Total Supply

## Key:

```text
0x06 | denom
```

## Value:

```text
total_supply
```

---

# 🔷 G. Total Borrow

## Key:

```text
0x07 | denom
```

## Value:

```text
total_borrow
```

---

# 🧠 5. Advanced Optimization (Level Pro)

---

## 🔥 1. Address Encoding

Gunakan:

```text
sdk.AccAddress (bytes)
```

❌ Jangan string:

* lebih besar
* lebih lambat

---

## 🔥 2. Denom Handling

IBC denom panjang → mahal

👉 opsi:

* hash denom
* atau normalize mapping

---

## 🔥 3. Composite Key Packing

```text
[address][denom]
```

👉 tanpa separator string

---

# ⚠️ 6. Query Pattern (Harus Dipikirkan Sekarang)

---

## Contoh query penting:

### 1. Semua collateral user

```text
prefix: 0x02 | address
```

---

### 2. Semua debt user

```text
prefix: 0x03 | address
```

---

### 3. Semua market

```text
prefix: 0x01
```

---

👉 semua O(n kecil), bukan full scan

---

# 🧩 7. Isolated Market (Untuk Credit Layer)

Dari sekarang, siapkan:

---

## Tambahkan ke Market:

```text
market_type:
- shared
- isolated
```

---

## Key tetap sama:

```text
0x01 | denom
```

---

👉 behavior beda di logic, bukan di store

---

# ⚠️ 8. Common Mistakes (Jangan Dilakukan)

---

## ❌ 1. Simpan semua dalam 1 struct besar

👉 tidak scalable

---

## ❌ 2. Loop semua user setiap block

👉 chain mati

---

## ❌ 3. Tidak pakai index-based interest

👉 tidak efisien

---

## ❌ 4. Tidak pisah collateral & debt

👉 sulit maintain

---

# 🧠 9. Mental Model (Supaya Nempel)

Bayangkan store kamu seperti:

---

## Tabel Collateral

| address | denom | amount |
| ------- | ----- | ------ |

---

## Tabel Debt

| address | denom | amount |

---

## Tabel Market

| denom | config |

---

👉 Ini relational thinking tapi di KVStore

---

# 🔥 10. Final Store Layout (Ringkas)

```text
Markets        → 0x01 | denom
Collateral     → 0x02 | address | denom
Debt           → 0x03 | address | denom
Params         → 0x04
InterestIndex  → 0x05 | denom
TotalSupply    → 0x06 | denom
TotalBorrow    → 0x07 | denom
```

---