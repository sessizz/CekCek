# CekCek Marketplace

## Problem

Karavan/RV sahipleri yola çıkmadan önce onlarca şeyi kontrol etmeli. Her seferinde aynı şeyleri unutmamak için checklistler hazırlıyorlar. Ama herkes sıfırdan kendi listesini yapmak zorunda. Deneyimli bir karavancının yıllarda oluşturduğu mükemmel "kışlık bakım listesi" sadece kendi telefonunda kalıyor.

Aynı şey diğer alanlarda da geçerli — pilot checklistleri, tekne bakımı, kamp hazırlığı, uzun yol seyahati...

## Çözüm

CekCek'e bir **marketplace** ekliyoruz.

Kullanıcılar kendi hazırladıkları kontrol listelerini tek tuşla topluluğa yayınlayabilecek. Diğer kullanıcılar bu listeleri kategoriye göre gezebilecek, arayabilecek, puanlayabilecek ve tek dokunuşla kendi uygulamalarına indirebilecek.

## Nasıl Çalışacak?

### Yayınlayan Taraf
1. Hazırladığın bir checklist'e uzun bas → "Marketplace'e Yayınla"
2. Kısa bir açıklama yaz, kategori seç
3. Yayınla. Bitti.

### İndiren Taraf
1. Marketplace sekmesine git
2. Kategorilere göz at veya arama yap (ör. "winterization", "pre-flight")
3. Beğendiğin listeye dokun → maddeleri gör, puanını gör, yorumları oku
4. "İndir" → listeye anında eklenir, artık senin listen

### Sosyal Katman
- **Puanlama:** 1-5 yıldız. En iyi listeler öne çıkar.
- **Yorumlar:** "Bu listeye X maddesini de eklemenizi öneririm" gibi geri bildirimler.
- **İndirme sayısı:** Popüler listeler görünür.

## Kayıt Gerekiyor mu?

**Hayır.** Kullanıcı zaten iCloud hesabıyla uygulamayı kullanıyor. Marketplace'te de aynı iCloud kimliğiyle tanınıyor — ekstra kayıt formu, şifre, e-posta doğrulama yok. Aç ve kullan.

## Kategoriler

İlk aşamada:
- Karavan / RV
- Kamp
- Seyahat
- Havacılık
- Denizcilik
- Araç Bakımı
- Ev
- Diğer

Topluluk büyüdükçe yeni kategoriler eklenebilir.

## Moderasyon

- Uygunsuz içerik raporlanabilir
- Çok rapor alan içerik otomatik gizlenir
- Spam filtresi var
- Günlük yükleme limiti var (kötüye kullanımı önler)

## Teknik Altyapı (Özet)

- **Sunucu:** Supabase (veritabanı + API + kimlik doğrulama). Free tier ile başlanır, büyüdükçe $25/ay Pro plan yeterli.
- **Ek sunucu maliyeti yok** — middleware'e gerek kalmadan Edge Functions ile çözülüyor.
- **Veri boyutu:** Her checklist ~3 KB JSON. 10.000 checklist = 30 MB. Maliyet açısından çok hafif.
- **Offline:** İndirilen listeler cihaza kaydedilir, internet olmadan çalışır.

## Neden Önemli?

1. **Ağ etkisi:** Her yeni kullanıcı hem tüketici hem üretici. İçerik arttıkça uygulama daha değerli olur.
2. **Niş topluluk:** Karavan/RV sahipleri zaten birbirlerine yardım etmeyi seven bir topluluk. Marketplace bunu dijitalleştiriyor.
3. **Genişleme potansiyeli:** RV ile başlayıp havacılık, denizcilik, endüstriyel bakım gibi alanlara açılabilir. Her alanda checklist kullanan profesyoneller var.
4. **Monetizasyon:** İleride premium listeler, öne çıkarma, pro üyelik gibi gelir modelleri eklenebilir. Şimdilik tamamen ücretsiz.

## Zaman Çizelgesi

6 haftalık bir geliştirme planı:
- **Hafta 1-2:** Altyapı kurulumu (veritabanı, kimlik doğrulama)
- **Hafta 2-3:** Göz atma ve indirme özelliği
- **Hafta 3-4:** Yayınlama özelliği
- **Hafta 4-5:** Puanlama ve yorum
- **Hafta 5-6:** Son rötuşlar ve test

## Bir Cümleyle

> CekCek Marketplace: hazırladığın listeyi paylaş, başkalarının deneyiminden faydalan — kayıt yok, para yok, tek tuşla.
