# Council Fuse Kullanıcı Kılavuzu

> 5 dakikada başlayın — daha iyi yanıtlar için çok perspektifli müzakere

---

## Kurulum

### Claude Code (önerilen)

```bash
claude plugin add juserai/forge
```

### Evrensel tek satırlık kurulum

```
Fetch and follow https://raw.githubusercontent.com/juserai/forge/main/skills/council-fuse/SKILL.md
```

> **Sıfır bağımlılık** — Council Fuse hiçbir harici hizmet veya API gerektirmez. Kurun ve başlayın.

---

## Komutlar

| Komut | Ne yapar | Ne zaman kullanılır |
|-------|----------|---------------------|
| `/council-fuse <soru>` | Tam bir konsey müzakeresi başlatır | Önemli kararlar, karmaşık sorular |

---

## Nasıl Çalışır

Council Fuse, Karpathy'nin LLM Council kalıbını tek bir komutta özetler:

### Aşama 1: Toplantı

Üç ajan **paralel olarak** başlatılır, her biri farklı bir bakış açısıyla:

| Ajan | Rol | Model | Güçlü Yönü |
|------|-----|-------|------------|
| Generalist | Dengeli, pratik | Sonnet | Yaygın en iyi uygulamalar |
| Eleştirmen | Karşı taraf, kusurları bulur | Opus | Sınır durumları, riskler, kör noktalar |
| Uzman | Derin teknik detay | Sonnet | Uygulama hassasiyeti |

Her ajan **bağımsız** olarak yanıt verir — birbirlerinin yanıtlarını göremezler.

### Aşama 2: Puanlama

Başkan (ana ajan) tüm yanıtları Yanıt A/B/C olarak anonimleştirir, ardından her birini 4 boyutta puanlar (0-10):

- **Doğruluk** — olgusal kesinlik, mantıksal tutarlılık
- **Bütünlük** — tüm yönlerin kapsanması
- **Pratiklik** — uygulanabilirlik, gerçek dünya kullanılabilirliği
- **Netlik** — yapı, okunabilirlik

### Aşama 3: Sentez

En yüksek puanlı yanıt iskelet olur. Diğer yanıtlardan benzersiz içgörüler entegre edilir. Eleştirmenin geçerli itirazları uyarı olarak korunur.

---

## Kullanım Alanları

### Mimari kararlar

```
/council-fuse Should we use microservices or a monolith for our 10-person team?
```

Generalist dengeli ödünleşmeleri sunar, eleştirmen mikroservis abartısını sorgular ve uzman geçiş kalıplarını detaylandırır. Sentez koşullu bir öneri verir.

### Teknoloji seçimi

```
/council-fuse Redis vs PostgreSQL for our job queue
```

Üç farklı bakış açısı, operasyonel kaygıları (eleştirmen), uygulama detaylarını (uzman) veya pragmatik varsayılanı (generalist) kaçırmamanızı sağlar.

### Kod incelemesi

```
/council-fuse Is this error handling pattern correct? <paste code>
```

Tek seferde alın: genel akış doğrulaması, karşı taraf sınır durumu analizi ve derin teknik doğrulama.

---

## Çıktı Yapısı

Her konsey müzakeresi üretir:

1. **Puan Matrisi** — üç perspektifin şeffaf puanlaması
2. **Uzlaşı Analizi** — nerede hemfikir, nerede ayrışıyor
3. **Sentezlenmiş Yanıt** — kaynaşmış en iyi yanıt
4. **Azınlık Görüşü** — dikkat çekmeye değer geçerli muhalif görüşler

---

## Özelleştirme

### Bakış açılarını değiştirin

Özel konsey üyeleri tanımlamak için `agents/*.md` dosyalarını düzenleyin. Alternatif üçlüler:

- İyimser / Kötümser / Pragmatist
- Mimar / Uygulayıcı / Testçi
- Kullanıcı Savunucusu / Geliştirici / Güvenlik Uzmanı

### Modelleri değiştirin

Her ajan dosyasındaki `model:` alanını düzenleyin:

- `model: haiku` — maliyet etkin konseyler
- `model: opus` — kritik kararlar için tam ağır siklet

---

## Platformlar

| Platform | Konsey üyeleri nasıl çalışır |
|----------|------------------------------|
| Claude Code | 3 bağımsız ajan paralel olarak başlatılır |
| OpenClaw | Tek ajan, 3 ardışık bağımsız akıl yürütme turu |

---

## SSS

**S: 3 kat token maliyeti mi?**
C: Evet, yaklaşık olarak. Üç bağımsız yanıt artı sentez. Yatırımı haklı kılacak kararlar için kullanın.

**S: Daha fazla konsey üyesi ekleyebilir miyim?**
C: Framework bunu destekler — başka bir `agents/*.md` dosyası ekleyin ve SKILL.md iş akışını güncelleyin. Ancak maliyet-çeşitlilik dengesi için 3 ideal noktadır.

**S: Bir ajan başarısız olursa ne olur?**
C: Başkan o üyeye 0 puan verir ve kalan yanıtlardan sentez yapar. Zarif bozulma, çökme yok.
