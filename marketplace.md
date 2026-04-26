# CekCek Marketplace — Mimari Plan

## Neden?

Kullanıcılar kendi checklistlerini toplulukla paylaşabilsin, başkalarının hazırladığı listeleri keşfedip indirebilsin. Kategoriler, puanlama ve yorumlama ile kaliteli içerik öne çıksın.

---

## 1. Genel Mimari

```
iOS/macOS App  ──►  Supabase Edge Functions  ──►  Supabase (Postgres + Auth)
                          │
                    Apple DeviceCheck API
                    (kimlik doğrulama)
```

**Neden Railway değil?** Supabase Edge Functions (Deno) hem auth hem API proxy işini görür. Ekstra sunucu maliyeti ve bakım yükü yok. İleride ihtiyaç olursa Railway eklenebilir.

**Yeni bağımlılık:** `supabase-swift` SPM paketi (tek eklenen dış bağımlılık).

---

## 2. Kullanıcı Kimliği (Kayıt Gerektirmeden)

### Akış

1. Uygulama açılışında `CKContainer.default().fetchUserRecordID()` — iCloud hesabına bağlı sabit UUID döner
2. İlk marketplace erişiminde `AppAttest` veya `DeviceCheck` token'ı alınır — gerçek Apple cihazı olduğunu kanıtlar
3. Supabase Edge Function'a gönderilir:
   - `cloudkit_user_id` (string)
   - `device_check_token` (Base64)
4. Edge Function Apple API'dan token'ı doğrular, `users` tablosunda upsert yapar, Supabase JWT döner
5. JWT Keychain'de saklanır, tüm sonraki isteklerde kullanılır

### Display Name

- İlk erişimde `CKContainer.default().discoverUserIdentity()` ile iCloud adı çekilir (izin gerekir)
- İzin verilmezse veya kullanıcı isterse özel isim girilebilir
- Tek seferlik "Marketplace'te görünecek isminiz" sheet'i gösterilir

### iCloud Yoksa?

- Marketplace'e göz atılabilir (browse-only)
- Yükleme, puanlama, yorum yapılamaz
- Net uyarı: "Marketplace özelliklerini kullanmak için iCloud'a giriş yapın"

### Önemli Bilgi

- `fetchUserRecordID()` → iCloud hesabına bağlı, cihaz/uygulama yeniden yüklenmesinden etkilenmez
- Aynı iCloud hesabı = aynı ID (farklı cihazlarda bile)
- Ek kayıt formu YOK — tamamen şeffaf

---

## 3. Supabase Veritabanı Şeması

### users

| Kolon | Tip | Not |
|-------|-----|-----|
| id | UUID PK | Supabase auth UUID |
| cloudkit_user_id | TEXT UNIQUE | iCloud record ID |
| display_name | TEXT | Varsayılan: "Anonymous" |
| avatar_url | TEXT? | Opsiyonel |
| is_banned | BOOLEAN | Varsayılan: false |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

### categories

| Kolon | Tip | Not |
|-------|-----|-----|
| id | UUID PK | |
| name_key | TEXT | Lokalizasyon anahtarı ("category.rv") |
| icon_name | TEXT | SF Symbol adı |
| sort_order | INT | Sıralama |
| is_active | BOOLEAN | |

**Seed data:** RV/Karavan, Kamp, Seyahat, Havacılık, Denizcilik, Ev, Araç, Diğer

### marketplace_checklists

| Kolon | Tip | Not |
|-------|-----|-----|
| id | UUID PK | |
| author_id | UUID FK→users | |
| category_id | UUID FK→categories | |
| title | TEXT | |
| description | TEXT? | |
| icon_name | TEXT | SF Symbol |
| language | TEXT | ISO 639-1 ("tr", "en") |
| item_count | INT | |
| download_count | INT | Denormalize, trigger ile güncellenir |
| average_rating | NUMERIC(3,2) | Denormalize, trigger ile güncellenir |
| rating_count | INT | Denormalize |
| status | TEXT | 'pending_review' / 'published' / 'rejected' / 'removed' |
| version | INT | |
| source_checklist_id | UUID? | Orijinal yerel UUID (güncelleme tespiti) |
| fts | tsvector | Full-text search, generated column |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

### marketplace_checklist_items

| Kolon | Tip | Not |
|-------|-----|-----|
| id | UUID PK | |
| checklist_id | UUID FK→marketplace_checklists | CASCADE delete |
| title | TEXT | |
| sort_order | INT | |

### ratings

| Kolon | Tip | Not |
|-------|-----|-----|
| id | UUID PK | |
| user_id | UUID FK→users | |
| checklist_id | UUID FK→marketplace_checklists | |
| score | INT | 1-5, CHECK constraint |
| created_at | TIMESTAMPTZ | |
| UNIQUE(user_id, checklist_id) | | Kullanıcı başına tek puan |

### reviews

| Kolon | Tip | Not |
|-------|-----|-----|
| id | UUID PK | |
| user_id | UUID FK→users | |
| checklist_id | UUID FK→marketplace_checklists | |
| body | TEXT | Min 10, max 1000 karakter |
| status | TEXT | 'visible' / 'hidden' / 'removed' |
| created_at | TIMESTAMPTZ | |
| UNIQUE(user_id, checklist_id) | | Kullanıcı başına tek yorum |

### downloads

| Kolon | Tip | Not |
|-------|-----|-----|
| id | UUID PK | |
| user_id | UUID FK→users | |
| checklist_id | UUID FK→marketplace_checklists | |
| downloaded_at | TIMESTAMPTZ | |
| UNIQUE(user_id, checklist_id) | | Tekrar indirme sayılmaz |

### reports

| Kolon | Tip | Not |
|-------|-----|-----|
| id | UUID PK | |
| reporter_id | UUID FK→users | |
| checklist_id | UUID? FK→marketplace_checklists | |
| review_id | UUID? FK→reviews | |
| reason | TEXT | 'spam' / 'offensive' / 'misleading' / 'copyright' / 'other' |
| details | TEXT? | |
| status | TEXT | 'pending' / 'reviewed' / 'actioned' / 'dismissed' |

### Trigger'lar

- **Rating değiştiğinde** → `marketplace_checklists.average_rating` ve `rating_count` güncellenir
- **Download eklendiğinde** → `marketplace_checklists.download_count` +1

### RLS (Row Level Security)

- **Checklists:** Herkes `published` olanları okuyabilir; yazar kendi checklistlerini CRUD yapabilir
- **Ratings/Reviews:** Herkes okuyabilir; kullanıcı sadece kendininkileri oluşturabilir/güncelleyebilir
- **Downloads:** Kullanıcı sadece kendi indirmelerini görebilir
- **Reports:** Herkes oluşturabilir; sadece admin (service key) okuyabilir

---

## 4. Supabase Edge Functions

### `auth/cloudkit-login`

```
POST /auth/cloudkit-login
Body: { cloudkit_user_id, device_check_token }
Response: { access_token, user }
```

1. Apple DeviceCheck API ile token doğrula
2. `users` tablosunda upsert (cloudkit_user_id ile)
3. Supabase JWT mint et (sub = user.id)
4. JWT döndür

### `checklists/publish`

```
POST /checklists/publish
Auth: Bearer <jwt>
Body: { title, description, icon_name, category_id, language, items[] }
```

1. Basit profanity/spam filtresi
2. Rate limit kontrolü (günde maks 5 yükleme)
3. `marketplace_checklists` + `marketplace_checklist_items` insert
4. `status: 'published'` (v1 için auto-approve)

---

## 5. iOS/macOS Uygulama Değişiklikleri

### Yeni Dosya Yapısı

```
CekCek/
  Marketplace/
    Models/
      MarketplaceChecklist.swift         — Codable struct (SwiftData DEĞİL)
      MarketplaceCategory.swift
      MarketplaceUser.swift
    Services/
      MarketplaceAuthService.swift       — CloudKit identity + JWT yönetimi
      MarketplaceAPIService.swift        — Supabase client wrapper
    Views/
      MarketplaceTabView.swift           — Root marketplace view
      MarketplaceBrowseView.swift        — Featured + kategori grid
      MarketplaceSearchView.swift        — Arama + filtreler
      MarketplaceCategoryView.swift      — Kategorideki listeler
      MarketplaceChecklistDetailView.swift  — Önizleme, puan, yorum, indir
      MarketplaceUploadView.swift        — Checklist yayınlama
      MarketplaceRatingView.swift        — Yıldız puanlama
      MarketplaceReviewSheet.swift       — Yorum yazma
      MarketplaceReportSheet.swift       — İçerik raporlama
      MarketplaceProfileView.swift       — Kullanıcının yayınladıkları
```

### Navigasyon Entegrasyonu

`ContentView`'a `TabView` eklenir:
- **Tab 1:** "Listelerim" (mevcut `NavigationSplitView`)
- **Tab 2:** "Marketplace" (yeni `MarketplaceTabView`)

macOS'ta sidebar'a "Marketplace" bölümü eklenir.

### Model Değişikliği

`Checklist.swift`'e eklenmesi gereken:

```swift
var marketplaceSourceId: UUID?   // marketplace'ten indirildiyse orijinal ID
```

SwiftData opsiyonel alan eklemede otomatik lightweight migration yapar.

### Marketplace Modelleri (Codable, SwiftData DEĞİL)

```swift
struct MarketplaceChecklist: Codable, Identifiable, Sendable {
    let id: UUID
    let authorDisplayName: String
    let categoryId: UUID?
    let title: String
    let description: String?
    let iconName: String
    let language: String
    let itemCount: Int
    let downloadCount: Int
    let averageRating: Double
    let ratingCount: Int
    let items: [MarketplaceChecklistItem]?  // detay sayfasında yüklenir
    let createdAt: Date
}
```

### MarketplaceAuthService

```swift
@MainActor @Observable
final class MarketplaceAuthService {
    var isAuthenticated = false
    var currentUser: MarketplaceUser?
    
    /// İlk çağrıda: fetchUserRecordID() → Edge Function → JWT → Keychain
    /// Sonraki çağrılarda: JWT expiry kontrol, gerekirse refresh
    func ensureAuthenticated() async throws { ... }
}
```

### İndirme Akışı

1. `MarketplaceAPIService.download(id:)` → full checklist + items çekilir
2. `downloads` tablosuna kayıt eklenir
3. Mevcut `ChecklistImporter` mantığı yeniden kullanılır:
   - `Checklist(isDefault: false, customTitle: title)`
   - `ChecklistItem`'lar oluşturulur
   - `checklist.marketplaceSourceId = marketplace checklist ID`
4. Yerel SwiftData'ya kaydedilir → artık tamamen offline çalışır

### Yükleme Akışı

1. Checklist context menüsünde "Marketplace'e Yayınla" butonu
2. `MarketplaceUploadView`: başlık (önceden dolu), açıklama, kategori, dil seçici
3. Mevcut `ChecklistTransferData` formatı yeniden kullanılır
4. Edge Function'a gönderilir

### Offline Davranış

- Marketplace göz atma → internet gerekli, offline durumda net mesaj + tekrar dene butonu
- Son çekilen listeler `URLCache` ile cache'lenir
- İndirilen checklistler tamamen yerel → offline çalışır
- Puan/yorum offline ise kuyruğa alınır, bağlantı gelince gönderilir

---

## 6. İçerik Moderasyonu

### Otomatik (v1)

- Başlık, açıklama, yorumlarda basit profanity/spam filtresi (Edge Function'da)
- Rate limiting: günde maks 5 yükleme, günde maks 20 yorum
- **v1 için auto-publish** — topluluk küçükken otomatik onay, `status` alanı gelecek için hazır

### Kullanıcı Raporlama

- Checklist veya yorum raporlanabilir (neden + detay)
- 3+ rapor alan içerik otomatik gizlenir (`status: 'pending_review'`)

### Admin

- **v1:** Supabase Dashboard üzerinden doğrudan tablo düzenleme
- **v2:** Basit admin web paneli (Supabase Edge Function + HTML veya ayrı Next.js)

### Banlama

- `users.is_banned = true` → INSERT operasyonları RLS ile engellenir

---

## 7. Maliyet Analizi

### Supabase Free Tier

| Kaynak | Limit | CekCek Tahmini |
|--------|-------|----------------|
| Database | 500 MB | 10.000 checklist ≈ 50 MB ✓ |
| Auth | 50K MAU | Yeterli ✓ |
| Edge Functions | 500K çağrı/ay | ~16K/gün ≈ 1.600 DAU ✓ |
| Storage | 1 GB | Kullanılmıyor (henüz) ✓ |

### Büyüme

- **Pro plan:** $25/ay — 8 GB DB, 100 GB storage. Büyük ölçek için yeterli.
- **Railway (gerekirse):** $5/ay hobby plan.
- Checklist'ler çok küçük (2-5 KB JSON) — maliyet kritik değil.

---

## 8. Uygulama Sırası

### Faz 1: Temel Altyapı (Hafta 1-2)

1. Supabase projesi kur, schema migration'ı çalıştır, kategorileri seed'le
2. `auth/cloudkit-login` Edge Function'ını yaz
3. `supabase-swift` SPM bağımlılığını Xcode projesine ekle
4. `MarketplaceAuthService` implementasyonu — şeffaf iCloud tabanlı login
5. `Checklist` modeline `marketplaceSourceId: UUID?` ekle

### Faz 2: Göz Atma ve İndirme (Hafta 2-3)

6. `MarketplaceAPIService` — browse/search/detail/download
7. `MarketplaceTabView`, `MarketplaceBrowseView`, `MarketplaceCategoryView`
8. `MarketplaceChecklistDetailView` — önizleme + indirme
9. Download → SwiftData dönüşümü (`ChecklistImporter` genişletilir)
10. `ContentView`'a TabView entegrasyonu

### Faz 3: Yayınlama (Hafta 3-4)

11. `MarketplaceUploadView` — kategori, açıklama, dil
12. Publish API çağrısı
13. Checklist context menüsüne "Marketplace'e Yayınla" eklenir

### Faz 4: Sosyal Özellikler (Hafta 4-5)

14. Puanlama UI ve API
15. Yorum UI ve API
16. Raporlama UI ve API

### Faz 5: Polish (Hafta 5-6)

17. Offline cache
18. Tüm yeni string'lerin lokalizasyonu (TR + EN)
19. İçerik moderasyon filtresi
20. iOS + macOS test

---

## 9. Riskler ve Çözümler

| Risk | Çözüm |
|------|-------|
| CloudKit userRecordID sunucu tarafında doğrulanamaz | DeviceCheck token doğrulaması (v1) |
| İlk dış bağımlılık (supabase-swift) | MIT lisanslı, aktif bakımlı, tek bağımlılık |
| İçerik moderasyon yükü büyür | Auto-publish + raporlama + eşik tabanlı otomatik gizleme |
| iCloud yoksa? | Browse-only mod, yayınlama/puanlama/yorum devre dışı |
| SwiftData model migration | Opsiyonel alan ekleme otomatik lightweight migration |

---

## 10. Değiştirilecek Mevcut Dosyalar

| Dosya | Değişiklik |
|-------|------------|
| `CekCek/Models/Checklist.swift` | `marketplaceSourceId: UUID?` eklenir |
| `CekCek/ContentView.swift` | TabView wrapper eklenir |
| `CekCek/CekCekApp.swift` | `MarketplaceAuthService` environment'a inject |
| `CekCek/Services/ChecklistImporter.swift` | Marketplace'ten indirme desteği |
| `CekCek/Models/ChecklistTransferData.swift` | Marketplace upload formatı olarak yeniden kullanılır |
| `CekCek/Localizable.xcstrings` | Tüm marketplace string'leri |
| `Package.swift` veya Xcode SPM | `supabase-swift` bağımlılığı |
