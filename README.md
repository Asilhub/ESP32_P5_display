# P5 Carwash Display — ESP32 + HUB75 (64x32)

Avtomoyka shoxobchalari uchun LED tablo dasturi. ESP32 mikrokontrolleri HUB75 RGB LED panelni boshqaradi va Serial port orqali keladigan JSON buyruqlarni ko'rsatadi: xizmat nomi, qolgan vaqt, balans, valyuta, xatolik holati.

Ko'p tilli: lotin va kirill alifbolari, UTF-8 dekoder, proporsional 16x10 shrift.

**Versiya:** 1.0.1  
**Panel:** P5-1921-64\*32-8S-S2 (64x32, 1/8 scan, four-scan)  
**Kontroller:** ESP32 (original, 2016)

---

## 1. Apparat va ulanish

### Pinout

ESP32 va HUB75 razyomi orasidagi ulanish:

| HUB75 pin | ESP32 GPIO | Vazifasi |
| :--- | :---: | :--- |
| **R1** | 18 | Qizil, yuqori yarim |
| **G1** | 17 | Yashil, yuqori yarim |
| **B1** | 16 | Ko'k, yuqori yarim |
| **R2** | 15 | Qizil, quyi yarim |
| **G2** | 19 | Yashil, quyi yarim |
| **B2** | 21 | Ko'k, quyi yarim |
| **A** | 4 | Satr tanlash A |
| **B** | 22 | Satr tanlash B |
| **C** | 14 | Satr tanlash C |
| **D / NC** | 13 | Satr tanlash D |
| **E** | 5 | Satr tanlash E (1/8 scan panelda ulanmasa ham bo'ladi) |
| **LAT / STB** | 26 | Latch |
| **OE** | 25 | Output Enable |
| **CLK** | 27 | Taktlash |
| **GND** | GND | Umumiy yer — kamida 2 ta GND simini ulang |

Pinlarni o'zgartirish kerak bo'lsa: [`p5_carwash.ino`](p5_carwash.ino) faylining boshidagi `#define` bloki.

### Quvvat

Panel ESP32 dan emas, **alohida 5 V manbadan** oziqlanadi.

- 64x32 P5 panel to'liq oq rangda ~3.5–4 A tortadi. Kamida **5 V / 5 A** blok qo'ying.
- ESP32 va panelning **GND** lari birlashtirilgan bo'lishi shart.
- Dasturda yorqinlik `setBrightness8(120)` qilib qo'yilgan (255 dan). Bu tokni cheklaydi va panelni qizib ketishdan saqlaydi. Ko'proq yorqinlik kerak bo'lsa manba quvvatini ham oshiring.

---

## 2. Dasturni yuklash

### A) Tayyor firmware bilan (mijoz uchun eng oson yo'l)

Kompilyatsiya qilish shart emas. [`release/`](release/) papkasidagi bitta fayl yetarli:

```
release/p5_carwash_v1.0.1_FULL.bin   ->  0x0 manziliga yoziladi
```

**Windows'da:**

```
cd release
flash.bat COM3
```

`esptool` o'rnatilmagan bo'lsa: `pip install esptool`

**Yoki Espressif Flash Download Tool (GUI) bilan:**

| Sozlama | Qiymat |
| :--- | :--- |
| Chip | ESP32 |
| Fayl | `p5_carwash_v1.0.1_FULL.bin` |
| Address | `0x0` |
| SPI Speed | 80 MHz |
| SPI Mode | DIO |
| Flash size | 4 MB |

**Qo'lda esptool buyrug'i:**

```
esptool --chip esp32 -p COM3 -b 921600 write_flash 0x0 p5_carwash_v1.0.1_FULL.bin
```

Alohida bo'laklar kerak bo'lsa, [`release/parts/`](release/parts/) papkasida:

| Fayl | Manzil |
| :--- | :--- |
| `bootloader.bin` | `0x1000` |
| `partitions.bin` | `0x8000` |
| `boot_app0.bin` | `0xe000` |
| `firmware.bin` | `0x10000` |

### B) Manbadan kompilyatsiya qilish

Arduino IDE da **ESP32 Dev Module** boardini tanlang.

Kerakli kutubxonalar (Library Manager orqali):

| Kutubxona | Versiya |
| :--- | :--- |
| ESP32 HUB75 LED MATRIX PANEL DMA Display | **3.0.14** |
| GFX_Lite | 2.0.0 |
| ArduinoJson | 7.x |
| esp32 board core | 3.3.7 |

> **Muhim:** HUB75 kutubxonasining **3.0.13 dan eski** versiyalari ishlamaydi. `VirtualMatrixPanel_T`, `ScanTypeMapping` va `FOUR_SCAN_32PX_HIGH` faqat 3.0.13+ da mavjud. 3.0.10 bilan kompilyatsiya `'FOUR_SCAN_32PX_HIGH' was not declared in this scope` xatosini beradi.

---

## 3. JSON protokoli

Serial port, **115200 baud**, har bir buyruq `\n` (yangi qator) bilan tugaydi.

### Kalitlar

| Kalit | Turi | Tavsif |
| :--- | :--- | :--- |
| `type` | matn | Rejim yoki ko'rsatiladigan matn (lotin) |
| `typeuz` / `textuz` | matn | Xuddi `type` kabi, lotin alifbosi |
| `typekg` / `textkg` | matn | Kirill rejimi (qirg'izcha) |
| `typekr` / `textkr` | matn | Kirill rejimi |
| `value` | son | Balans yoki vaqt — **MMSS formatida**, pastdagi izohga qarang |
| `colorR1` `colorG1` `colorB1` | 0–255 | Yuqori qator / matn rangi |
| `colorR2` `colorG2` `colorB2` | 0–255 | Quyi qator / raqam rangi |

Kalitlar shu tartibda tekshiriladi: `typekr` → `textkr` → `typekg` → `textkg` → `typeuz` → `textuz` → `type`. Birinchi topilgani ishlatiladi.

### `value` maydoni — MMSS, soniya emas

`formatTime()` funksiyasi qiymatni `/100` va `%100` qiladi:

| Yuborilgan | Ekranda |
| :---: | :---: |
| `300` | `03:00` |
| `230` | `02:30` |
| `45` | `00:45` |
| `1230` | `12:30` |

Ya'ni 2 daqiqa 30 soniya uchun `230` yuboriladi, `150` emas. Soniya qismi 59 dan oshmasligi kerak (`175` yuborilsa ekranda `01:75` chiqadi).

### Rejimlar

| Kalit so'z | Rejim | Ekranda |
| :--- | :--- | :--- |
| `MECANUZ`, `CARWASH`, `KGCARWASH`, `KG` | Logotip | `MECANUZ`, nafas oluvchi oq rang |
| `PP<matn>PP` | Valyuta | Tepada `value` raqami, pastda `<matn>` |
| `KG<matn>KG` | Valyuta | Xuddi shunday, avto-tarjimasiz |
| `SUM` | Raqam | Faqat `value` raqami, markazda |
| `SOM`, `СОМ` | Valyuta | Tepada raqam, pastda `SOM` / `СОМ` |
| `TEST` | Sinov | Butun alifbo va raqamlar skroll qiladi |
| boshqa har qanday matn | Matn + vaqt | Tepada matn, pastda `MM:SS` |

**Avto-tarjimalar:**

- `PPsumPP` yoki `PPsomPP` + kirill kaliti (`typekg`/`typekr`) → pastda `СОМ` chiqadi.
- Kirill rejimida `SHAMPUN` → `ШАМПУНЬ`, `PAUZA` → `ПАУЗА`.

**Xatolik rejimi:** buzilgan JSON kelsa ekranda qizil `ERROR` yozuvi miltillaydi va tepa/past chiziqlar qizil yonadi.

---

## 4. Misollar

```json
{"type":"MECANUZ"}
```
Bo'sh turgan holat — logotip nafas oluvchi oq rangda.

```json
{"typeuz":"PPsumPP","value":10000,"colorR1":255,"colorG1":180,"colorB1":0,"colorR2":0,"colorG2":255,"colorB2":0}
```
Balans: tepada sariq `10000`, pastda yashil `SUM`.

```json
{"typekg":"PPsumPP","value":10000}
```
Xuddi shunday, lekin pastda kirillcha `СОМ`.

```json
{"typeuz":"KOPIK","value":300,"colorR1":0,"colorG1":200,"colorB1":255,"colorR2":255,"colorG2":255,"colorB2":255}
```
Xizmat ishlayapti: tepada `KOPIK`, pastda `03:00`.

```json
{"typeuz":"PAUZA","value":45,"colorR1":255,"colorG1":255,"colorB1":0}
```
Pauza, `00:45` qoldi.

```json
{"typekg":"ШАМПУНЬ","value":230}
```
To'g'ridan-to'g'ri kirill matn, `02:30`.

```json
{"typeuz":"SUV","value":0}
```
Vaqt tugadi — 1 soniyadan keyin vaqt yo'qoladi, matn markazga ko'chadi.

```json
{"typeuz":"SUM","value":1500000}
```
Katta raqam, markazda.

```json
{"type":"TEST"}
```
Barcha harf va raqamlarni tekshirish uchun skroll.

---

## 5. Ma'lum cheklovlar

Bular mavjud xatti-harakat, mijozga oldindan aytilishi kerak:

1. **`Ө`, `Ү`, `Ң` harflari ekranga chiqmaydi.** Shriftda ular bor (60, 62, 68-indekslar), lekin `getFontIndex()` funksiyasi ularni xaritalamaydi. Natijada `КӨБҮК` → `КБК`, `ЧАҢ` → `ЧА` bo'lib chiqadi. Qirg'iz tili to'liq kerak bo'lsa, `getFontIndex()` ga uch qator qo'shish kifoya.

2. **Kirill rejimida lotin `SH` → `Ш` bo'lmaydi.** O'girish harfma-harf ishlaydi: `SHAMPUN` → `СХАМПУН`. Shu sababli `SHAMPUN` va `PAUZA` uchun kodda maxsus holat yozilgan. Boshqa so'zlar uchun **to'g'ridan-to'g'ri kirill yozib yuborish** ishonchliroq.

3. **`MECANUZ` va `ERROR` rejimlarida rang parametrlari e'tiborga olinmaydi** — animatsiya har kadrda rangni qayta yozadi.

4. **Matn kengligi 64 px.** Undan uzun matn avtomatik skroll qiladi. `MECANUZ` va `SHAMPUN` aynan 63 px — zo'rg'a sig'adi, chetlarida bo'shliq qolmaydi.

5. **Ekran balandligi 32 px.** Ikki qatorli rejimlarda kirill `Ц`, `Щ` harflarining dumlari quyi chiziqqa tegishi mumkin.

---

## 6. P4 (80x40) versiyasidan farqlar

Bu dastur avval 80x40 P4 panel uchun yozilgan edi. 64x32 P5 panelga o'tkazishda quyidagilar o'zgardi:

| Nima | P4 (80x40) | P5 (64x32) |
| :--- | :--- | :--- |
| Piksel xaritalash | To'g'ridan-to'g'ri DMA ga | `VirtualMatrixPanel_T` + `FOUR_SCAN_32PX_HIGH` |
| DMA konfiguratsiya | `HUB75_I2S_CFG(80, 40, 1)` | `HUB75_I2S_CFG(128, 16, 1)` — eni×2, bo'yi÷2 |
| Chizish chaqiruvi | `dma_display->drawPixel()` | `disp->drawPixel()` |
| I2S tezligi | 20 MHz | 10 MHz (ghosting bo'lmasligi uchun) |
| Yorqinlik | 80 | 120 |
| Ramka animatsiyasi | 4 tomonlama snake | Faqat tepa (0) va past (31) qatorlar |
| Bir qatorli matn Y | 12 | 8 |
| Ikki qatorli matn Y | 4 / 22 | 1 / 17 |

> **Nega ramka o'zgardi:** 64 px enda to'rt tomonlama ramka matnga joy qoldirmaydi — `MECANUZ` yozuvining o'zi 63 px. Shuning uchun animatsiya faqat yuqori va quyi qatorlar bo'ylab uzluksiz halqa qilib yuguradi, yon ustunlar matn uchun bo'sh qoladi.

> **Nega `VirtualMatrixPanel_T` kerak:** P5 paneli 1/8 scan (four-scan) turida. Bunday panelda fizik piksel joylashuvi mantiqiy koordinatalarga to'g'ri kelmaydi. Agar `dma_display` ga to'g'ridan-to'g'ri chizilsa, rasm aralashib ketadi. Barcha chizish `disp` orqali o'tishi shart.

---

## 7. Fayl tuzilmasi

```
p5_carwash/
├── p5_carwash.ino                    Asosiy dastur
├── font16x10.h                       Proporsional shrift, 81 ta belgi
├── README.md                         Shu hujjat
└── release/
    ├── p5_carwash_v1.0.1_FULL.bin    Tayyor firmware (0x0 ga yoziladi)
    ├── flash.bat                     Windows uchun flash skripti
    └── parts/
        ├── bootloader.bin            0x1000
        ├── partitions.bin            0x8000
        ├── boot_app0.bin             0xe000
        └── firmware.bin              0x10000
```

### Shrift haqida

[`font16x10.h`](font16x10.h) — 16 px balandlik, 10 px maksimal kenglik, 81 ta belgi.

- **Proporsional:** har bir belgining chap va o'ng tomonidagi bo'sh ustunlar ish vaqtida kesib tashlanadi, shuning uchun `1` va `:` kabi belgilar kam joy egallaydi.
- **Tarkibi:** `0-9`, `A-Z`, `: - . , $ % + / =`, hamda to'liq kirill alifbosi.
- **Amaldagi balandlik:** lotin bosh harflari 13 px (0–12 qatorlar), raqamlar va kirill harflari 14 px (0–13 qatorlar). `Ң` 15 px, `Ц` va `Щ` dumi bilan 16 px gacha tushadi.
- **Tuzatilgan nuqson:** kirill `В` va `Е` harflari avval qo'shnilaridan 1 px past turardi. `В` uchun kod lotin `B` glifiga yo'naltirilgan edi (13 qator), `Е` esa lotin `E` dan nusxa olingan edi (13 qator, 7 px). Ikkalasi ham qolgan kirill harflariga moslab 14 qator / 8 px ga keltirildi.
