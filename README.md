# Proyek Akhir Praktikum Sistem Embedded

```bash
Anggota Kelompok    : 
Aliya Rizqiningrum Salamun                    2306161813
Mirza Adi Raffiansyah				          2306210323
Wesley Fredrick Oh				              2306202763
Rafi Naufal Aryaputra				          2306250680
```

## <span style="color:green">PLANT MONITORING SYSTEM </span>

### i. Introduction to The Problem and The Solution
Pada era globalisasi sekarang, muncul berbagai macam pekerjaan termasuk di bidang pertanian dan agrikultur. Seiring dengan perkembangan zaman, tentu tingkat permintaan dan penawaran untuk hasil pangan menjadi lebih tinggi. Akibatnya, diperlukan sebuah sistem pemantauan yang lebih baik untuk mengelola tanaman pertanian supaya menjadi lebih efisien.

Ketidakhadiran sistem monitoring yang efektif sering kali mengakibatkan keterlambatan dalam pengambilan keputusan, potensi kerusakan tanaman, serta pemborosan sumber daya. Hal ini juga berdampak pada produktivitas tenaga kerja, di mana pekerjaan manual yang bersifat repetitif dan kurang efisien masih banyak dilakukan.

Untuk itu, kami membuat sebuah sistem pemantauan atau monitoring tanaman yang lebih baik dengan memanfaatkan teknologi sistem embedded, dengan harapan bahwa proses produksi dan monitoring menjadi lebih modern, berbasis teknologi, tetap pada harga yang terjangkau. 

Plant Monitoring System beroperasi dengan sensor-sensor yang beradaptasi dengan lingkungannya, seperti sensor DHT11 untuk memeriksa kelembaban dan suhu, dan juga Light Dependent Resistor (LDR) yang berperan seperti sensor cahaya untuk memberitahu pengguna sistem atas kondisi ideal yang diperlukan tanaman.

---

### ii. Hardware Design and Implementation Details
Berikut beberapa komponen yang digunakan:
- Breadboard x1
- Sensor DHT11 x1
- LDR x1
- MAX7219 LED Dot Matrix 8x8 4-in-1 32x8 x1
- TowerPro Servo Motor SG90 x1
- Kabel Jumper Male-to-Male dan Male-to-Female

Sistem ini menggunakan arduino sebagai komponen utama yang memproses seluruh input dan output komponen, semua komponen di-*supply* oleh tegangan sebesar 5V oleh arduino. Namun, karena Arduino Uno hanya memiliki 1 buah pin 5V, kita menggunakan *power rail* di breadboard agar bisa mendistribusikan power ke seluruh komponen.

Sistem ini berpusat pada pembacaan DHT11 dan LDR. DHT11 membaca nilai *humidity* atau kelembaban udara saat ini lalu menyimpannya di sebuah register pada arduino. Nilai tersebut akan dibandingkan dengan nilai threshold, dan jika nilai kelembaban lebih rendah daripada nilai threshold, maka sistem akan menyiram air secara otomatis yang disimulasikan dengan membukanya servo sebesar 180 derajat. Selain itu, sistem juga memberitahu bahwa tanaman memerlukan air dengan menggunakan MAX7219.

Begitupun juga terjadi pada LDR, semakin gelap pencahayaan sebuah ruangan, maka nilai LDR juga semakin rendah. Jika nilai LDR ini juga lebih rendah daripada sebuah nilai threshold, artinya ruangan terlalu gelap untuk pertumbuhan tanaman. Karena tanaman tidak bisa berpindah tempat secara otomatis, sistem akan memberitahu orang terdekatnya bahwa tanaman kurang pencahayaan dengan menggunakan LED Matrix MAX7219.

---

### iii. Software Implementation Details
Pada awal ide implementasi, muncul ide untuk membuat sistem DHT11 dengan polling untuk secara konstan memberikan nilai kelembaban udara, serta LDR dengan sistem ADC Interrupt yang bisa melakukan interrupt setiap kali ADC dibaca untuk nantinya dibandingkan dengan nilai threshold. 

Adapun MAX7219 diimplementasikan dengan menggunakan protocol SPI untuk membangun komunikasi serial antara Arduino Uno ATMega328p dengan LED Matrix MAX7219.

Sistem ini juga mengimplementasikan timer menggunakan Timer0 dengan mode CTC untuk memberi jeda pada pembacaan DHT11, LDR, dan display LED Matrix MAX7219.

Seiring berjalannya pembuatan sistem, kami harus menghadapi beberapa masalah, seperti ADC interrupt yang tidak bisa berjalan sama sekali. Untuk itu, ADC interrupt tidak jadi digunakan sehingga digantikan dengan polling juga.

Terakhir, juga diimplementasikan logic untuk menampilkan pembacaan DHT11 dan juga LDR ke Serial Monitor untuk konteks *debugging*, agar hasil pembacaan lebih transparan ke pengguna sistem.

Alur program sudah persis atau hampir persis mengikuti flowchart yang telah disediakan di *repository* pengumpulan.

---

### iv. Test Results and Performance Evaluation
Hasil tes baik di Proteus dan Rangkaian asli telah menunjukkan hasil yang cukup memuaskan. Saat diuji, simulasi di kedua tempat menunjukkan nilai DHT11 dan LDR yang cukup meyakinkan.

Namun, karena sulitnya mensimulasikan kelembaban pada DHT11, servo hanya diuji di Proteus, yang juga telah bekerja dengan baik. Servo berputar 180 derajat dengan tepat.

MAX7219 juga telah bekerja dengan cukup baik, walaupun terdapat sedikit kendala di stabilisasi kabel jumper dan posisi modulnya, yang jika disenggol sedikit maka terjadi kesalahan display, namun secara logika sudah berjalan dengan semestinya.

Terdapat sebuah masalah saat hari H-1 pengumpulan, di mana Arduino secara tiba-tiba gagal membaca DHT11 dan memutar servo ketika diuji di proteus, walaupun telah diuji di H-2 semua sudah berjalan sesuai deskripsi di atas. Untuk letak permasalahan masih tidak diketahui.

---

### v. Conclusion and Future Work
Pada akhirnya, sistem monitoring tanaman bisa dikatakan berhasil dan sekaligus tidak berhasil dibuat, karena saat pengujian di hari H-2 rangkaian bekerja dengan sangat baik, namun saat H-1 rangkaian tidak bekerja terutama dalam pembacaan DHT di simulasi Proteus. 

Untuk kedepannya, sangat diperlukan kerapian kode, dan debugging yang seharusnya diperlukan lebih banyak kerja sama tim daripada per individu itu sendiri.

