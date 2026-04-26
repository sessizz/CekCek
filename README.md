# CekCek

![CekCek App Icon](CekCek/Assets.xcassets/AppIcon.appiconset/AppIcon-light.png)

**CekCek**, karavan ve RV sahipleri için hazırlanmış, bakım ve hazırlık listelerini yönetmeye odaklanan yerel bir iOS/macOS uygulamasıdır.  
SwiftUI ve SwiftData ile geliştirilmiştir; harici bir backend zorunluluğu olmadan çalışır.

## Ne İşe Yarıyor?

CekCek, tekrar eden kontrol süreçlerini daha düzenli hale getirmek için tasarlandı:

- yol öncesi kontrol listeleri
- kamp alanı varış / ayrılış rutinleri
- periyodik bakım maddeleri
- kullanıcıya özel checklist senaryoları

Uygulama varsayılan checklist’lerle başlar, ama tüm yapı kullanıcı tarafından düzenlenebilir, paylaşılabilir ve içe aktarılabilir.

## Öne Çıkan Özellikler

- SwiftData tabanlı yerel veri saklama
- CloudKit destekli senkronizasyon ve hata durumlarında yerel fallback
- İlk açılışta otomatik varsayılan RV checklist’leri
- Özel checklist oluşturma ve mevcut checklist’leri düzenleme
- Checklist öğesi ekleme, düzenleme, silme ve sıralama
- Tamamlanma geçmişi kaydı
- Checklist paylaşımı ve dosyadan içe aktarma
- iPhone, iPad ve macOS için native SwiftUI arayüzü
- Türkçe ve İngilizce lokalizasyon desteği

## Teknoloji Yığını

- `SwiftUI`
- `SwiftData`
- `CloudKit`
- `LocalizedStringKey` tabanlı lokalizasyon
- Xcode proje yapısı (`.xcodeproj`)

## Platform Desteği

- iOS 17.0+
- macOS 14.0+

## Proje Yapısı

```text
CekCek/
├── Models/        # SwiftData modelleri
├── Views/         # SwiftUI ekranları ve bileşenleri
├── Services/      # seed, import, sync monitor gibi servisler
├── Extensions/    # progress, display title, transfer data yardımcıları
├── Data/          # varsayılan checklist tanımları
└── Localizable.xcstrings
```

## Önemli Alanlar

- `Checklist`: ana liste modeli
- `ChecklistItem`: checklist içindeki maddeler
- `CompletionRecord`: tamamlanma geçmişi
- `DefaultDataSeeder`: varsayılan verileri ilk kurulumda ekler
- `ChecklistImporter`: dışa aktarılan checklist dosyalarını içe alır
- `CloudKitSyncMonitor`: senkronizasyon durumunu takip eder

## Kurulum

Projeyi Xcode ile açın:

```bash
open CekCek.xcodeproj
```

CLI üzerinden debug build almak için:

```bash
xcodebuild -project CekCek.xcodeproj -scheme CekCek -configuration Debug
```

Test hedefi kullanılırsa örnek test komutu:

```bash
xcodebuild test -project CekCek.xcodeproj -scheme CekCek -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Mimari Notlar

Uygulama katmanlı ve sade bir yapı izler:

- **Models**: SwiftData `@Model` sınıfları
- **Views**: `@Query`, `@Bindable` ve SwiftUI state yönetimiyle çalışan ekranlar
- **Services**: seed, import/export ve sync akışları
- **Extensions**: görünüm ve iş mantığı yardımcıları

`ContentView`, uygulamanın ana giriş ekranıdır ve `NavigationSplitView` ile özellikle iPad/macOS tarafında rahat bir ana-detay akışı sunar.

## Lokalizasyon

Tüm kullanıcıya dönük metinler `LocalizedStringKey` üzerinden yönetilir.  
Lokalizasyon dosyası:

- `CekCek/Localizable.xcstrings`

Mevcut diller:

- Türkçe (`tr`)
- İngilizce (`en`)

## Veri ve Senkronizasyon

- Ana veri katmanı SwiftData’dır.
- Uygulama CloudKit ile senkronizasyon başlatmayı dener.
- CloudKit kullanılamazsa yerel kalıcı depolamaya düşer.
- Kalıcı depolama da açılamazsa bellek içi fallback devreye girer.

Bu yaklaşım, uygulamanın hata durumlarında da açılabilir ve kullanılabilir kalmasını sağlar.

## Durum

Proje aktif olarak native Apple platformları odağında geliştirilmektedir. Kod tabanı, dış bağımlılıklardan kaçınan sade bir yapı üzerine kuruludur.

## Katkı

Katkı vermeden önce şu alanlara dikkat edilmesi faydalı olur:

- kullanıcıya görünen metinleri hardcode etmemek
- yeni string’leri `Localizable.xcstrings` içine eklemek
- platform farkları için gerektiğinde `#if os(macOS)` / `#if os(iOS)` kullanmak
- mevcut SwiftUI ve SwiftData yaklaşımını korumak

## Lisans

Bu depo için henüz bir lisans dosyası eklenmemiş görünüyor. Yayınlama planına göre `LICENSE` dosyası eklenebilir.
