# 1. Gambaran Besar: state transition yang benar

Di `x/lending`, operasi utama kamu nanti adalah:

* deposit collateral
* withdraw collateral
* supply liquidity
* borrow
* repay
* liquidate

Secara finansial, semua operasi itu pada dasarnya memodifikasi 3 hal:

* **nilai collateral user**
* **nilai debt user**
* **likuiditas market**

Supaya aman, semua perubahan harus menjaga invariant risiko.

---

# 2. Konsep finansial dasar yang wajib kamu pegang

Sebelum formula, kita luruskan istilah.

## Collateral value

Nilai total aset jaminan user dalam satu unit acuan, biasanya USD-equivalent.

Contoh:

* 10 ATOM
* harga ATOM = $12
* collateral value = $120

## Debt value

Nilai total utang user dalam unit acuan yang sama.

Contoh:

* 50 USDC
* debt value = $50

## LTV (Loan-to-Value)

Batas maksimum pinjaman terhadap nilai collateral.

Contoh:

* collateral = $1000
* LTV = 70%
* max borrow = $700

## Liquidation threshold

Ambang di mana posisi dianggap tidak sehat dan boleh dilikuidasi.

Contoh:

* collateral = $1000
* liquidation threshold = 80%
* kalau debt mencapai nilai risiko tertentu, posisi bisa dilikuidasi

LTV dan liquidation threshold **tidak boleh sama**. Best practice:

* `LTV < liquidation_threshold`

Ini memberi buffer aman.

## Health factor

Ukuran kesehatan posisi.

Semakin besar, semakin aman. Kalau turun di bawah ambang tertentu, posisi bisa dilikuidasi.

---

# 3. Formula inti yang dipakai

## 3.1 Borrow limit

Untuk setiap collateral, ada bobot risiko. Secara umum:

`borrow_limit = Σ(collateral_value_i × ltv_i)`

Kalau user punya:

* $1000 ATOM, LTV 70%
* $500 OSMO, LTV 60%

Maka:

* borrow power dari ATOM = $700
* borrow power dari OSMO = $300
* total borrow limit = $1000

Artinya total debt user tidak boleh melebihi $1000 saat borrow atau withdraw.

---

## 3.2 Liquidation threshold value

`liquidation_limit = Σ(collateral_value_i × liquidation_threshold_i)`

Dengan data yang sama, misal:

* ATOM liq threshold 80% → $800
* OSMO liq threshold 75% → $375

Total liquidation limit = $1175

---

## 3.3 Health factor

Best practice paling umum:

`health_factor = liquidation_limit / debt_value`

Interpretasi:

* `> 1` → sehat
* `= 1` → batas
* `< 1` → liquidatable

Contoh:

* liquidation limit = $1175
* debt value = $900
* health factor = 1.305...

Posisi aman.

Kalau debt naik jadi $1300:

* HF = 1175 / 1300 = 0.9038
* posisi bisa dilikuidasi

---

# 4. Flow finansial per operasi

Sekarang kita bahas alur logika yang nanti akan jadi basis keeper.

---

## 4.1 Deposit collateral

Tujuan:

* menambah jaminan user

Efek:

* collateral naik
* borrow capacity naik
* health factor membaik

Alur:

1. validasi asset didukung market
2. transfer token ke module account
3. tambah collateral user
4. update total collateral / accounting jika perlu

Secara math:

* `collateral_value_new = collateral_value_old + deposited_value`

Tidak perlu cek risiko saat deposit, karena deposit selalu memperbaiki posisi.

---

## 4.2 Borrow

Tujuan:

* user meminjam aset dari pool

Alur:

1. update interest index market lebih dulu
2. hitung debt user terbaru
3. hitung collateral value dengan oracle
4. hitung borrow limit
5. cek `new_debt_value <= borrow_limit`
6. cek liquidity market cukup
7. tambah debt
8. transfer asset ke user
9. update total borrow

Math:

* `new_debt_value = existing_debt_value + borrowed_value`
* syarat:

  * `new_debt_value <= borrow_limit`

Ini check utama borrow.

---

## 4.3 Repay

Tujuan:

* mengurangi utang

Alur:

1. update market interest index
2. accrue debt user ke nilai terbaru
3. transfer repayment dari user
4. kurangi debt
5. update total borrow

Math:

* `new_debt = max(old_debt - repay_amount, 0)`

Repay selalu memperbaiki health factor.

---

## 4.4 Withdraw collateral

Tujuan:

* ambil kembali jaminan

Ini lebih sensitif dari deposit.

Alur:

1. hitung posisi user setelah withdraw
2. recalc collateral value
3. recalc borrow limit
4. cek debt tetap aman
5. baru transfer collateral ke user

Math:

* `new_collateral_value = old_collateral_value - withdrawn_value`
* hitung `new_borrow_limit`
* syarat:

  * `debt_value <= new_borrow_limit`

Kalau tidak, withdraw harus ditolak.

---

## 4.5 Liquidation

Tujuan:

* mengurangi risiko protokol saat posisi tidak sehat

Syarat:

* `health_factor < 1`

Alur:

1. update interest index
2. hitung debt dan collateral terbaru
3. cek posisi liquidatable
4. tentukan berapa debt yang boleh ditutup
5. liquidator bayar debt asset
6. liquidator menerima collateral senilai repayment + bonus
7. protocol ambil fee jika ada
8. update debt dan collateral user

---

# 5. Best practice liquidation yang final

Kamu tadi minta dipilihkan yang terbaik.

## 5.1 Permissionless liquidation

Ini benar.

Alasan:

* paling decentralized
* menciptakan pasar liquidator kompetitif
* tidak bergantung operator tunggal
* lebih tahan terhadap downtime internal

## 5.2 Incentive model terbaik

Best practice modern:

* **liquidation bonus ke liquidator**
* ditambah **protocol cut kecil**

Contoh:

* bonus liquidation total = 8%
* liquidator effective reward = 6%
* protocol treasury = 2%

Kenapa ini bagus:

* liquidator tetap termotivasi
* protokol juga punya revenue
* bonus tidak terlalu besar sehingga tidak terlalu menghukum borrower

Kalau bonus terlalu kecil:

* tidak ada insentif untuk eksekusi cepat

Kalau bonus terlalu besar:

* borrower terlalu dirugikan dan bisa memicu spiral sell pressure

Rentang praktik umum yang sehat:

* sekitar 5%–10%, tergantung volatilitas aset

Untuk asset volatilitas tinggi, bonus bisa sedikit lebih tinggi.

## 5.3 Partial liquidation

Ini pilihan terbaik.

Alasan:

* menurunkan risiko tanpa memaksa close semua posisi
* mengurangi slippage dan tekanan jual
* lebih adil untuk borrower
* lebih stabil saat market crash

Best practice modern biasanya memakai:

* close factor
* misalnya maksimal 50% debt bisa dilikuidasi per transaksi

Ini menjaga likuidasi bertahap, bukan brutal.

---

# 6. Interest model: kinked model

Sekarang ke bunga.

## 6.1 Utilization rate

Ini kunci semua bunga di model pool-based.

`utilization = total_borrow / total_available_liquidity`

Sering lebih tepat ditulis sebagai:

`U = borrows / (cash + borrows - reserves)`

Interpretasi:

* semakin tinggi utilization, semakin langka likuiditas
* bunga borrow harus naik

---

## 6.2 Kinked curve

Ada satu titik yang disebut `kink`.

Sebelum kink:

* bunga naik pelan

Setelah kink:

* bunga naik tajam

Tujuan:

* menjaga market tetap efisien
* mendorong repay / supply saat likuiditas terlalu ketat

### Formula bentuk umum

Kalau `U <= kink`:

`borrow_rate = base_rate + U × slope1`

Kalau `U > kink`:

`borrow_rate = base_rate + kink × slope1 + (U - kink) × slope2`

Dengan:

* `slope2 > slope1`

Contoh:

* base rate = 2%
* kink = 80%
* slope1 = 10%
* slope2 = 60%

Kalau utilization 50%:

* borrow rate = 2% + 0.5 × 10% = 7%

Kalau utilization 90%:

* rate = 2% + 0.8 × 10% + 0.1 × 60% = 16%

Kurva jadi agresif setelah 80%.

---

## 6.3 Supply rate

Lender dapat yield dari borrower, dikurangi reserve factor.

Best practice formula:

`supply_rate = borrow_rate × utilization × (1 - reserve_factor)`

Contoh:

* borrow rate = 16%
* utilization = 90%
* reserve factor = 10%

Maka:

* supply rate = 16% × 0.9 × 0.9 = 12.96%

Reserve factor masuk treasury / insurance / protocol reserves.

Ini best practice karena:

* lender dibayar dari aktivitas nyata borrower
* protocol punya bantalan keamanan dan revenue

---

# 7. Interest accrual: model yang paling benar

Jangan hitung bunga per user dengan loop global.
Best practice adalah **index-based accrual**.

## 7.1 Kenapa index-based?

Karena kamu tidak mau update semua akun setiap block. Itu tidak scalable.

Sebagai gantinya, tiap market punya:

* `borrow_index`
* `supply_index`
* `last_updated_time` atau `last_updated_block`

Lalu saat ada interaksi:

* index di-update
* user debt/supply di-“sync” terhadap index terbaru

## 7.2 Formula konsep

Jika:

* old borrow index = 1.00
* new borrow index = 1.10
* user principal = 100

Maka debt terbaru:

* `100 × 1.10 / 1.00 = 110`

Jadi bunga “terkumpul” lewat index, bukan lewat loop semua user.

Ini sangat penting untuk Cosmos app-chain yang mau production-grade.

---

# 8. Multi-asset valuation

Karena kamu memilih multi-asset, semua risk check harus dilakukan dalam satu unit nilai yang sama.

Best practice:

* valuasi semua collateral dan debt ke unit referensi internal, biasanya USD-equivalent precision tinggi

## 8.1 Formula collateral total

`total_collateral_value = Σ(amount_i × price_i × collateral_factor_i?)`

Untuk borrow limit:

* pakai LTV
  Untuk liquidation:
* pakai liquidation threshold

## 8.2 Formula debt total

`total_debt_value = Σ(debt_amount_j × price_j)`

Pastikan:

* price source konsisten
* decimal handling konsisten
* asset precision tidak bikin rounding error lintas token

---

# 9. Oracle design terbaik untuk Overlend

Kamu minta saya pilihkan yang terbaik dan modern.

## Final recommendation:

### **Hybrid oracle with medianization + TWAP + circuit breaker**

Struktur yang paling kuat untuk 2026:

### Primary source

* on-chain TWAP dari DEX / venue likuid

### Secondary source

* external oracle feed independen

### Aggregation

* median / sanity-check antara source

### Safety layer

* circuit breaker
* staleness check
* deviation check

Kenapa ini best practice:

* satu sumber saja terlalu berbahaya
* DEX-only bisa dimanipulasi saat liquidity tipis
* external-only punya trust / liveness risk
* hybrid memberi defense-in-depth

Fitur wajib:

* reject harga basi
* reject deviasi harga ekstrim
* fallback mode jika salah satu source gagal
* governance-controlled emergency pause per market

---

# 10. Revenue model terbaik

Untuk protokol lending jangka panjang, best practice bukan satu sumber fee, tapi gabungan yang sehat.

## Final recommendation

### 1. Reserve factor dari bunga

Ini harus jadi revenue utama.

Alasan:

* paling natural
* sustainable
* tidak mengganggu UX terlalu keras
* sejalan dengan pertumbuhan usage

### 2. Protocol share dari liquidation

Bagus sebagai revenue tambahan dan safety treasury.

### 3. Listing / market onboarding fee

Opsional, untuk market baru atau isolated market tertentu

### 4. Treasury reserves / insurance fund

Sebagian revenue masuk cadangan proteksi bad debt

Saya tidak menyarankan mengandalkan fee transaksi biasa sebagai pilar utama ekonomi protokol, karena itu kurang elegan untuk money market.

Model paling sehat:

* reserve factor sebagai core revenue
* liquidation share sebagai secondary
* treasury untuk risk absorption
* native token governance hanya kalau memang ada fungsi nyata

---

# 11. Risk parameter best practice

Untuk tiap market, kamu nantinya butuh parameter seperti:

* `ltv`
* `liquidation_threshold`
* `liquidation_bonus`
* `reserve_factor`
* `close_factor`
* `borrow_cap`
* `supply_cap`
* `is_isolated`
* `oracle_config`
* `interest_rate_model`

Contoh relasi sehat:

* LTV = 70%
* liquidation threshold = 80%
* close factor = 50%
* liquidation bonus = 8%
* reserve factor = 10%

Ini memberi:

* ruang borrow yang baik
* buffer keamanan
* likuidasi bertahap
* treasury growth

---

# 12. Urutan check yang benar per transaksi

Ini sering salah saat implementasi.

## Saat borrow

1. sync market interest
2. sync user debt
3. ambil harga oracle terbaru
4. hitung new debt value
5. cek borrow cap market
6. cek liquidity tersedia
7. cek posisi masih di bawah borrow limit
8. commit perubahan state
9. transfer token

## Saat withdraw

1. sync market interest
2. sync user debt
3. ambil harga terbaru
4. simulate collateral setelah withdraw
5. cek posisi tetap sehat untuk borrow limit
6. commit state
7. transfer token

## Saat liquidate

1. sync market interest
2. sync borrower debt
3. ambil harga oracle terbaru
4. cek `health_factor < 1`
5. hitung repay yang diizinkan oleh close factor
6. hitung collateral seize
7. transfer repay dari liquidator
8. settle debt borrower
9. transfer collateral ke liquidator
10. protocol cut ke treasury bila ada

Urutan ini penting supaya tidak ada exploit karena state lama.

---

# 13. Keputusan final yang saya rekomendasikan untuk Overlend

Ini versi final yang saya anggap paling best practice untuk visi lifetime project kamu.

## Product

* hybrid lending protocol
* core money market sebagai fondasi
* isolated credit market sebagai extension

## Core lending architecture

* pool-based untuk core market
* isolated credit pools / isolated P2P untuk undercollateralized layer

## Collateral

* overcollateralized di shared core market
* undercollateralized hanya di isolated market dengan risk separation ketat

## Interest

* kinked model per market
* parameterizable via governance
* index-based accrual

## Liquidation

* permissionless
* partial liquidation
* close factor
* liquidation bonus + protocol cut kecil

## Assets

* multi-asset dengan risk tiers

## IBC

* full IBC
* market per IBC asset dengan caps dan oracle gating

## Oracle

* hybrid oracle
* TWAP + external feed + medianization + circuit breaker

## Revenue

* reserve factor sebagai inti
* liquidation share sebagai tambahan
* treasury / insurance reserve wajib ada

---