# Tokopaedi E-Commerce Performance Analysis: Sales, Channel Growth, Funnel Conversion & Onboarding | SQL (BigQuery)

## Overview

Dokumen ini menyajikan analisis performa bisnis dan perilaku pelanggan untuk **Tokopaedi** (*dummy dataset*), sebuah platform e-commerce multi-channel (Website, Mobile App/App Store/Play Store, dan Offline Store). <br>

Metrik yang dievaluasi meliputi total pendapatan (*revenue*), volume penjualan produk per kategori, pertumbuhan *channel* bulanan (*MoM* & *YoY*), tingkat konversi *funnel* organik, hingga efektivitas *onboarding* pelanggan baru. <br>

Analisis ini bertujuan untuk menjawab 5 kebutuhan utama dari berbagai *stakeholders* perusahaan:
+ **Board of Directors:** Mengevaluasi tren total pendapatan bulanan sepanjang tahun 2024.
+ **Warehouse Manager:** Memetakan volume kuantitas produk terjual per kategori dari tahun 2020 hingga 2024 untuk perencanaan *restock*.
+ **Marketing Manager:** Menganalisis performa pesanan dan pendapatan tiap *channel* di tahun 2024 serta pertumbuhan tahunannya terhadap 2023.
+ **Marketing Manager:** Mengukur efektivitas trafik dan tingkat konversi (*conversion rate*) jalur organik di berbagai *channel*.
+ **BI & CRM Lead:** Mengevaluasi akuisisi pelanggan baru per *channel* registrasi dan rata-rata waktu yang dibutuhkan hingga transaksi pertama (*time to first purchase*).

Analisis data dilakukan menggunakan **Google BigQuery (SQL)** serta divisualisasikan menggunakan **Python** dan **Google Looker Studio**. <br>
Kode SQL lengkap untuk analisis ini dapat diakses di sini: [Tokopaedi_Analysis_SQL_Code.sql](Tokopaedi_Analysis_SQL_Code.sql). <br>
File presentasi lengkap dapat diunduh di sini: [FINPRO SQL.pptx](FINPRO%20SQL.pptx).

## **Table of Contents** <br>
- [Dataset](#dataset) <br>
- [Analysis](#analysis)
- [Executive Summary](#executive-summary)
- [Recommendations](#recommendations)
- [Limitations](#limitations)

## Dataset

Dataset yang digunakan berasal dari database internal **Tokopaedi** yang terdiri dari 6 tabel utama yang saling terhubung (*relational database*):
1. **`order_detail`**: Menyimpan rincian pesanan pelanggan (`order_id`, `transaction_id`, `order_date`, `customer_id`, `channel_type`, `sku_id`, `quantity`, `price`, `before_discount`, `discount_item`, `after_discount`, `is_gross`, `is_valid`, `is_net`).
2. **`product_detail`**: Menyimpan informasi produk (`sku_id`, `category`, `brand`, `product`, `variant`, `sku_name`, `price`, `cogs`).
3. **`customer_detail`**: Menyimpan profil dan histori registrasi pelanggan (`customer_id`, `registration_date`, `customer_name`, `customer_type`, `dob`, `province`, `registration_channel`).
4. **`transaction_detail`**: Menyimpan rincian pembayaran transaksi (`transaction_id`, `transaction_date`, `customer_id`, `payment_method`, `before_tax`, `tax`, `after_tax`, `shipping_cost`, `transaction_discount`, `total_paid`).
5. **`payment_detail`**: Menyimpan referensi metode pembayaran (`id`, `payment_method`).
6. **`funnel_detail`**: Menyimpan aktivitas *funnel* dan trafik pengguna (`funnel_id`, `channel_source`, `customer_id`, `sku_id`, `funnel_date`, `status`, `event`, `order_id`).

Berikut adalah skema hubungan antar tabel (*Entity Relationship Diagram*) pada database Tokopaedi:

<a href="images/Scheme.jpg"><img src="images/Scheme.jpg" alt="ERD Tokopaedi" width="400"></a>

Metrik dan atribut kunci yang digunakan dalam analisis ini meliputi:
+ **`total_paid`**: Total biaya transaksi bersih yang dibayarkan pelanggan (termasuk pajak, ongkos kirim, dan dikurangi diskon transaksi).
+ **`after_discount`**: Nilai pendapatan produk setelah dikurangi diskon item.
+ **`is_valid`**: Indikator validitas pembayaran (`1` = pelanggan sudah melakukan pembayaran).
+ **`event` & `channel_source`**: Sumber trafik pengguna (seperti jalur `Organic`) pada *Website*, *App Store*, dan *Play Store*.
+ **`registration_date` & `order_date`**: Digunakan untuk menghitung *lead time* (selisih hari) sejak pelanggan mendaftar hingga melakukan pembelian pertama.

## Analysis

### 1. Laporan Pendapatan Bulanan 2024 (Request: Board of Directors)
Langkah pertama adalah mengevaluasi tren pendapatan bulanan Tokopaedi sepanjang tahun 2024 berdasarkan nilai `total_paid` pada tabel `transaction_detail`.

<table>
  <tr>
    <td align="left" valign="top">
      <a href="images/revenue-table-2024.jpg"><img src="images/revenue-table-2024.jpg" alt="Tabel revenue 2024" width="400" height="500"></a>
    </td>
    <td align="right" valign="top">
      <a href="images/grafik-table-2024.jpg"><img src="images/grafik-table-2024.jpg" alt="Grafik revenue 2024" width="600" height="1000"></a>
    </td>
  </tr>
</table>

Secara keseluruhan, Tokopaedi menunjukkan performa penjualan yang positif sepanjang tahun 2024. Pertumbuhan *sales* sempat mencapai puncak di semester pertama pada bulan Mei (Rp2,72 miliar), kemudian melandai ke titik terendah pada bulan Juli (Rp1,10 miliar). <br>
Memasuki kuartal IV (Oktober–Desember), terjadi lonjakan aktivitas belanja yang signifikan menjelang akhir tahun, di mana **Desember** mencatatkan rekor pendapatan tertinggi sepanjang tahun yakni mencapai **Rp4,11 miliar** (329 transaksi).

---

### 2. Tren Volume Penjualan per Kategori 2020–2024 (Request: Warehouse Manager)
Untuk membantu perencanaan *restock* gudang, saya menggabungkan tabel `order_detail` dan `product_detail` untuk melihat tren kuantitas unit terjual (`is_valid = 1`) di 11 kategori produk selama 5 tahun terakhir.

<table>
  <tr>
    <td align="left" valign="top">
      <a href="images/table-category-quantity.jpg"><img src="images/table-category-quantity.jpg" alt="Tabel Category per Qauntity" width="800" height="500"></a>
    </td>
    <td align="right" valign="top">
      <a href="images/grafik-category-quantity.jpg"><img src="images/grafik-category-quantity.jpg" alt="Grafik Category per Qauntity" width="600" height="1000"></a>
    </td>
  </tr>
</table>

Dari hasil agregasi tahunan, terlihat pergeseran preferensi pelanggan yang menarik:
+ **Puncak Historis vs Pemulihan 2024:** Tahun 2021 merupakan puncak penjualan bagi mayoritas kategori yang dipimpin oleh *Food & Beverage* (9.368 unit). Namun, tahun 2024 menunjukkan pemulihan yang sangat kuat pada beberapa lini.
+ **Rekor Tertinggi Baru di 2024:** Kategori **Fashion & Footwear** (5.143 unit), **Books & Stationery** (3.389 unit), **Home Decor** (2.104 unit), dan **Kitchen Appliances** (1.419 unit) berhasil mencetak rekor volume penjualan tertinggi baru dalam 5 tahun terakhir pada 2024.
+ **Tren Penurunan Konsisten:** Kategori **Toys & Games** mengalami penurunan volume penjualan tanpa henti selama 5 tahun berturut-turut, dari 3.519 unit (2020) merosot menjadi 1.987 unit (2024).

---

### 3. Analisis Performa & Pertumbuhan Channel 2024 vs 2023 (Request: Marketing Manager)
Selanjutnya, saya menganalisis kontribusi pesanan unik (`COUNT(DISTINCT order_id)`) dan pendapatan (`SUM(after_discount)`) dari tiga *channel* penjualan utama (*Website*, *App Store*, dan *Offline Store*) sepanjang 2024, serta membandingkan pertumbuhan pendapatan tiap bulannya terhadap tahun 2023.


<table>
  <tr>
    <td align="left" valign="top">
      <a href="images/revenue-by-channel-2024.png"><img src="images/revenue-by-channel-2024.png" alt="Revenue by Channel 2024" width="800" height="700"></a>
    </td>
    <td align="right" valign="top">
      <a href="images/monthonmonth.jpg"><img src="images/monthonmonth.jpg" alt="MOM" width="600" height="1000"></a>
    </td>
  </tr>
</table>

+ **Perbandingan Antar Channel (2024):** **Offline Store** mencatatkan total *order* paling sedikit (1.037 *orders*), tetapi justru menghasilkan *revenue* tertinggi (**Rp5,9 miliar**)—menandakan *Average Order Value (AOV)* yang jauh lebih besar dibanding *channel* lain, terutama didorong lonjakan di November (Rp909 juta) dan Desember (Rp1,54 miliar). Sebaliknya, **Website** unggul dari sisi volume pesanan tertinggi (1.182 *orders*), namun menghasilkan *revenue* Rp4,78 miliar yang mengindikasikan nilai per transaksi yang lebih kecil. **App Store** menjadi *channel* paling fluktuatif, sempat turun tajam di Februari (47 *orders*) dan Juli (55 *orders*) sebelum kembali menguat di akhir tahun.
+ **Pertumbuhan Terhadap 2023 (YoY per Bulan):** Dibandingkan bulan yang sama pada tahun 2023, pendapatan keseluruhan tahun 2024 tumbuh sangat pesat pada Februari (+108,83%), Desember (+99,76%), Januari (+88,91%), November (+86,41%), dan Mei (+72,49%). Namun, sempat terjadi kontraksi pada bulan Agustus (-54,09%) dan Maret (-38,50%).

---

### 4. Analisis Funnel Conversion — Event Organic 2024 (Request: Marketing Manager)
Untuk memetakan efektivitas trafik organik sepanjang tahun 2024, saya menghitung total *event* organik, jumlah pesanan unik yang terkonversi, serta *conversion rate* pada masing-masing `channel_source`.

<table>
  <tr>
    <td align="left" valign="top">
      <a href="images/channel-trafic.png"><img src="images/channel-trafic.png" alt="Channel Trafic" width="500" height="500"></a>
    </td>
    <td align="right" valign="top">
      <a href="images/acquisition.png"><img src="images/acquisition.png" alt="MOM" width="500" height="700"></a>
    </td>
  </tr>
</table>

+ **Dominasi Trafik vs Efisiensi Konversi:** Dari sisi volume trafik organik, **Website** mendominasi dengan **29.062 *events*** (627 *orders*), disusul **App Store** dengan **27.717 *events*** (611 *orders*), dan **Play Store** dengan **26.165 *events*** (579 *orders*).
+ Namun, pola ini berbalik saat dilihat dari efisiensi konversi (*conversion rate*): **Play Store** justru menjadi yang paling efisien (**2,21%**) meskipun trafiknya paling kecil, diikuti **App Store** (**2,20%**), sedangkan **Website** yang memiliki trafik terbesar justru mencatatkan *conversion rate* paling rendah (**2,16%**).

---

### 5. Akuisisi Pelanggan Baru & Rata-rata Waktu ke Pembelian Pertama 2024 (Request: BI & CRM Lead)
Tahap terakhir adalah mengevaluasi proses *onboarding* pelanggan baru sepanjang 2024 dengan membandingkan total pendaftar baru secara keseluruhan (Case 5.1) terhadap pendaftar baru yang benar-benar melakukan minimal satu transaksi valid beserta rata-rata durasi hari menuju transaksi pertamanya (Case 5.2).

<table>
  <tr>
    <td align="left" valign="top">
      <a href="images/new-customers.jpg"><img src="images/new-customers.jpg" alt="Table New Customer" width="400" height="500"></a>
    </td>
    <td align="right" valign="top">
      <a href="images/new-customers.png"><img src="images/new-customers.png" alt="New Customer Chart" width="600" height="1700"></a>
    </td>
  </tr>
</table>
+ **Tren Akuisisi Pelanggan Baru:** Volume registrasi pelanggan baru di ketiga *channel* (*Mobile App*, *Website*, *Offline Store*) mengalami tren penurunan dari awal hingga akhir tahun 2024. *Mobile App* sempat mendominasi di bulan Januari (15 pelanggan baru) dan *rebound* di Agustus, namun melemah drastis menjelang akhir tahun. *Website* cenderung lebih stabil di kuartal awal (7–10 pelanggan/bulan).
+ **Gap Aktivasi & Durasi ke Pembelian Pertama:** Ketika difilter khusus pelanggan yang sudah bertransaksi (`is_valid = 1`), terlihat bahwa sebagian pendaftar belum pernah melakukan *checkout* (misalnya pada *Offline Store* di beberapa bulan akhir tahun). Selain itu, rata-rata waktu tunggu dari tanggal registrasi hingga transaksi pertama (`avg_days_to_first_order`) masih cukup panjang, berkisar antara **45 hingga 145 hari** tergantung bulan dan *channel* pendaftaran.

## Executive Summary

+ **Kuatnya Momentum Peak Season Akhir Tahun:** Pendapatan Tokopaedi tahun 2024 sangat terdorong oleh performa kuartal IV, dengan puncak penjualan terjadi pada bulan Desember sebesar Rp4,11 miliar (+99,76% dibanding Desember 2023), sementara titik terendah berada di bulan Juli (Rp1,10 miliar).
+ **Pergeseran Mesin Pertumbuhan Kategori Produk:** *Fashion & Footwear* (5.143 unit), *Books & Stationery* (3.389 unit), *Home Decor* (2.104 unit), dan *Kitchen Appliances* (1.419 unit) mencetak rekor volume tertinggi baru di 2024, sementara *Toys & Games* menyusut lima tahun berturut-turut.
+ **Karakteristik Berbeda Tiap Channel Penjualan:** *Offline Store* unggul sebagai penghasil *revenue* tertinggi (Rp5,9 miliar) berkat nilai belanja per transaksi (AOV) yang besar, sedangkan *Website* menjadi penggerak frekuensi transaksi tertinggi (1.182 *orders*).
+ **Peluang Optimasi Konversi Trafik Organik:** *Play Store* (2,21%) dan *App Store* (2,20%) lebih efisien dalam mengonversi trafik organik menjadi pesanan dibandingkan *Website* (2,16%) yang memiliki volume kunjungan tertinggi.
+ **Tantangan Aktivasi Pengguna Baru:** Penurunan tren registrasi pelanggan baru sepanjang 2024 disertai jeda waktu yang cukup lama menuju transaksi pertama (rata-rata >45 hari) menunjukkan perlunya akselerasi pada tahap *onboarding*.

## Recommendations

Rekomendasi strategis dikelompokkan ke dalam empat fokus utama berdasarkan temuan data:

**1. Manajemen Inventaris & Kategori Produk (Warehouse)**
+ **Prioritaskan Stok pada Kategori Growth & On-Fire:** Tingkatkan alokasi stok secara terukur pada kategori *Fashion & Footwear*, *Home Decor* (yang tumbuh lebih dari 2x lipat sejak 2022), *Books & Stationery*, dan *Kitchen Appliances* untuk mencegah *stockout*, terutama menjelang kuartal IV.
+ **Gunakan Baseline 2024 untuk Kategori Volatil:** Untuk *Food & Beverage* dan *Beauty & Personal Care*, jaga ketersediaan stok dengan mengacu pada rata-rata permintaan tahun 2024, bukan lonjakan anomali tahun 2021.
+ **Pangkas Restock Kategori Declining:** Kurangi volume *restock* secara tegas pada kategori *Toys & Games* agar tidak membebani biaya penyimpanan gudang, serta terapkan sistem stok stabil/berbasis pesanan untuk kategori *niche* (*Sports Equipment*, *Gaming Gear*, *Electronics*).

**2. Strategi Musiman & Cross-Channel (Sales & Marketing)**
+ **Optimalkan Nilai Transaksi (AOV) di Website:** Mengingat *Website* memiliki jumlah pesanan tertinggi namun AOV lebih kecil dibanding *Offline Store*, terapkan strategi *product bundling*, *upselling*, atau batas minimum belanja (*minimum spend voucher*) untuk mendongkrak nilai keranjang belanja.
+ **Intervensi Promo di Low Season (Mid-Year):** Hadirkan kampanye khusus pada bulan Juli dan Agustus (seperti *Mid-Year Sale* atau *Flash Sale* eksklusif aplikasi) untuk menahan penurunan pendapatan di pertengahan tahun dan menstabilkan fluktuasi di *App Store*.

**3. Optimasi Funnel Organik (Marketing & Product)**
+ **Perbaiki Checkout Flow di Website:** Evaluasi *user journey* dan kecepatan halaman *checkout* pada *Website*. Karena *Website* memiliki trafik organik terbesar (29.062 *events*), peningkatan kecil pada *conversion rate* akan berdampak signifikan terhadap total pesanan.
+ **Dorong Akuisisi Trafik ke Mobile App (Play Store & App Store):** Mengingat aplikasi mobile terbukti memiliki tingkat konversi organik yang lebih tinggi, arahkan kampanye organik dan *deep-linking* ke dalam aplikasi untuk memaksimalkan ROI trafik.

**4. Akuisisi & Onboarding Pelanggan Baru (BI & CRM)**
+ **Akselerasi Pembelian Pertama (First-Order Incentive):** Untuk memangkas rata-rata waktu tunggu pembelian pertama (yang saat ini mencapai 45–90+ hari), berikan *Welcome Voucher* dengan batas waktu singkat (misalnya berlaku 7 hari setelah registrasi) disertai *automated reminder* (push notification/email) bagi pengguna baru yang belum melakukan *checkout*.
+ **Reaktivasi Akuisisi Akhir Tahun:** Perkuat program *referral* dan insentif registrasi di *Mobile App* dan *Offline Store* pada paruh kedua tahun agar tren akuisisi pelanggan baru sejalan dengan lonjakan transaksi di kuartal IV.

## Limitations

Analisis ini memberikan gambaran komprehensif mengenai performa Tokopaedi, namun memiliki beberapa keterbatasan ruang lingkup:
+ **Metrik Profitabilitas Per Channel & Kategori:** Analisis pendapatan per *channel* dan tren kategori saat ini berfokus pada *gross/net revenue* (`total_paid` dan `after_discount`) serta kuantitas unit terjual, belum membedah *net profit margin* setelah dikurangi `cogs` pada masing-masing *channel*.
+ **Detail Tahapan Drop-off pada Funnel:** Data `funnel_detail` mengukur total *event* organik terhadap konversi akhir (`order_id`), namun belum merinci pada tahap spesifik mana (*view product*, *add to cart*, atau *payment page*) pengguna *Website* paling banyak batal melakukan transaksi.
