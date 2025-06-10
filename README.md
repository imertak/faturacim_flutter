# Faturacim Flutter Uygulamasi

Bu proje, kullanicilarin faturalarini yonetebilmesi, kamera araciligiyla fatura tarayip sisteme yukleyebilmesi ve harcamalarini analiz edebilmesi icin gelistirilmis bir Flutter uygulamasidir. Uygulama mobil ve web ortamlari icin derlenebilir.

## Ozellikler

- **Kullanici Girisi** (`lib/main.dart`): Eposta ve sifre ile giris yapilir. Giris islemi `globals.dart` dosyasindaki API uzerinden gerceklesir ve kullanici tokeni saklanir.
- **Ana Sayfa** (`lib/sayfa2.dart`): Son faturalar, doviz kurlari ve kampanya kutucuklarini icerir. Buradan kamera sayfasina, gecmis faturalar listesine, kategori analizine veya vergi hesaplama sayfasina gecis yapilabilir.
- **Kamera ile Fatura Yukleme** (`lib/kamerasayfasi.dart` ve `lib/kamerasayfasi2.dart`): Kamera araciligiyla cekilen fatura resmi, Cloudinary'ye yuklenir ve OCR islemi icin sunucuya gonderilir. Alinan bilgiler duzenlenip API'ye fatura olarak kaydedilebilir.
- **Gecmis Faturalar** (`lib/gecmisfaturalarsayfası.dart`): Tum faturalar listelenir, kategoriye gore filtrelenebilir ve Excel dosyasina aktarilabilir.
- **Fatura Detayi** (`lib/faturadetaysayfasi.dart`): Bir faturaya ait tutar, durum ve ilgili diger bilgiler ayrintili olarak gosterilir.
- **Kategori Analizi** (`lib/kategorianalizisayfasi.dart`): Faturalar secili doneme gore gruplanir ve `fl_chart` kutuphanesi kullanilarak pasta grafigi uzerinde gosterilir.
- **Vergi Hesaplama** (`lib/vergihesaplasayfasi.dart`): KDV, OTV ve stopaj gibi vergi turlerine gore tutar uzerinden hesaplama yapilabilir.
- **Profil Sayfalari** (`lib/profilsayfasi.dart` ve `lib/profilduzenleme.dart`): Kullanici bilgileri goruntulenebilir ve duzenlenebilir.

## Kod Yapisi

```
lib/
├── api_helper.dart          # API baglantisi ve yardimci fonksiyonlar
├── globals.dart             # Sunucu adresleri ve global degiskenler
├── main.dart                # Giris ekrani ve uygulamanin ana noktasi
├── sayfa2.dart              # Giris sonrasi ana sayfa
├── kamerasayfasi.dart       # Kamera ile fatura cekme ekrani
├── kamerasayfasi2.dart      # Cekilen fatura bilgilerini duzenleme ekrani
├── gecmisfaturalarsayfası.dart   # Gecmis fatura listesi
├── faturadetaysayfasi.dart  # Fatura detaylari
├── kategorianalizisayfasi.dart   # Harcama analizi ekranı
├── vergihesaplasayfasi.dart # Vergi hesaplama aracI
├── profilsayfasi.dart       # Profil bilgileri
└── profilduzenleme.dart     # Profil duzenleme sayfasi
```

`pubspec.yaml` dosyasinda `camera`, `http`, `path_provider`, `excel`, `fl_chart` ve `cloudinary_public` gibi paketler kullanilmaktadir.

## Calistirma

1. [Flutter](https://flutter.dev/) kurulumunu tamamlayin.
2. Gerekli paketleri yuklemek icin projenin kok dizininde:
   ```bash
   flutter pub get
   ```
3. Uygulamayi calistirmak icin:
   ```bash
   flutter run
   ```

## Testler

Varsayilan bir `widget_test.dart` dosyasi bulunmaktadir. Tum testleri calistirmak icin:

```bash
flutter test
```

## API Yapilandirmasi

`lib/globals.dart` dosyasinda API adresleri tanimlidir. Varsayilan olarak yerel `http://127.0.0.1:5202` adresi kullanilir. Gerektiginde bu degerleri kendi sunucunuza gore guncelleyebilirsiniz.

## Katki

Hata bildirimi veya iyilestirme onerileri icin Pull Request acabilirsiniz.

