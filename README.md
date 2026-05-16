# CekCek

![CekCek App Icon](CekCek/Assets.xcassets/AppIcon.appiconset/AppIcon-light.png)

**CekCek**, tekrar eden iş akışlarını, hazırlık süreçlerini ve kişisel kontrol listelerini düzenlemek için geliştirilmiş yerel bir iOS/macOS checklist uygulamasıdır.  
SwiftUI ve SwiftData ile geliştirilmiştir; harici bir backend zorunluluğu olmadan çalışır.

## Ne İşe Yarıyor?

CekCek, tekrar eden kontrol süreçlerini daha düzenli hale getirmek için tasarlandı:

- günlük görev rutinleri
- seyahat ve hazırlık listeleri
- bakım ve kontrol akışları
- ekip veya kişisel kullanım için özel checklist senaryoları

Uygulama varsayılan checklist’lerle başlar, ama tüm yapı kullanıcı tarafından düzenlenebilir, paylaşılabilir ve içe aktarılabilir.

## Öne Çıkan Özellikler

- SwiftData tabanlı yerel veri saklama
- CloudKit destekli senkronizasyon ve hata durumlarında yerel fallback
- İlk açılışta otomatik varsayılan checklist’ler
- Özel checklist oluşturma ve mevcut checklist’leri düzenleme
- Checklist öğesi ekleme, düzenleme, silme ve sıralama
- Tamamlanma geçmişi kaydı
- Checklist paylaşımı ve dosyadan içe aktarma
- iPhone, iPad ve macOS için native SwiftUI arayüzü
- Türkçe ve İngilizce lokalizasyon desteği

## Marketplace

Projede topluluk odaklı **CekCek Marketplace** katmanı da yer alır. Ana checklist deneyimi SwiftData ile yerel çalışır; marketplace özellikleri ise yapılandırılmış Supabase Edge Functions backend'ine bağlanır. Backend yapılandırması yoksa uygulama geliştirme ve demo amaçlı yerel örnek marketplace verilerine düşer.

Bu yapı ile kullanıcılar:

- hazırladıkları checklist’leri topluluğa yayınlayabilecek
- başka kullanıcıların checklist’lerini keşfedip indirebilecek
- kategori bazlı gezinebilecek
- puanlama ve yorumlarla kaliteli içerikleri öne çıkarabilecek

`marketplace.md` içindeki mimariye göre bu katman; Supabase tabanlı backend, Edge Functions, iCloud kimliğiyle sürtünmesiz giriş yaklaşımı ve uygulama içinde marketplace sekmesi içerir.

Desteklenen başlıklar:

- checklist yayınlama
- arama ve kategori bazlı keşif
- indirme ve yerel kopya olarak kullanma
- puanlama
- kullanıcı profili

Yorum, raporlama ve daha gelişmiş moderasyon akışları backend şemasında yer alsa da uygulama içinde kademeli olarak genişletilebilir.

## Teknoloji Yığını

- `SwiftUI`
- `SwiftData`
- `CloudKit`
- `LocalizedStringKey` tabanlı lokalizasyon
- Xcode proje yapısı (`.xcodeproj`)
- Marketplace için Supabase Edge Functions (opsiyonel backend)

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
- `marketplace.md`: marketplace mimarisi ve ürün planı

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
- Kalıcı depolama da açılamazsa bellek içi fallback devreye girer ve kullanıcı veri kaybı riski konusunda uyarılır.

Bu yaklaşım, uygulamanın hata durumlarında da açılabilir ve kullanılabilir kalmasını sağlar; ancak bellek içi mod yalnızca geçici bir kurtarma modudur.

## Durum

Proje aktif olarak native Apple platformları odağında geliştirilmektedir. Mevcut uygulama yerel checklist deneyimini korurken marketplace katmanını opsiyonel backend ile genişletir.

## Katkı

Katkı vermeden önce şu alanlara dikkat edilmesi faydalı olur:

- kullanıcıya görünen metinleri hardcode etmemek
- yeni string’leri `Localizable.xcstrings` içine eklemek
- platform farkları için gerektiğinde `#if os(macOS)` / `#if os(iOS)` kullanmak
- mevcut SwiftUI ve SwiftData yaklaşımını korumak

## Lisans

Bu depo için henüz bir lisans dosyası eklenmemiş görünüyor. Yayınlama planına göre `LICENSE` dosyası eklenebilir.
