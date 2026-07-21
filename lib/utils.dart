class Oyunlastirma {
  // Yıldız ve Kupa Mantığı
  static String getOdul(int toplamSayfa) {
    int yildiz = toplamSayfa ~/ 500;
    if (yildiz == 0) return "Henüz ödül yok";

    // Kupa Mantığı
    if (yildiz == 3) return "Bronz Kupa 🥉";
    if (yildiz == 4) return "Gümüş Kupa 🥈";
    if (yildiz == 5) return "Altın Kupa 🥇";
    if (yildiz == 6 || yildiz == 7) return "Altın Kupa (${yildiz - 4}) 🏆";
    if (yildiz == 8) return "Zümrüt 💎";
    if (yildiz == 9) return "Yakut 🔴";
    if (yildiz == 10) return "Safir 🔵";
    if (yildiz == 11) return "Elmas 💎";
    if (yildiz >= 12) return "Efsanevi Elmas ✨";

    return "$yildiz Yıldız ⭐";
  }

  // Ünvan Mantığı
  static String getUnvan(int toplamSayfa) {
    List<String> unvanlar = [
      "Yeni Okur",
      "Kitapsever",
      "Kitapkolik",
      "Kitap Kurdu",
      "Kitap Bilgini",
      "Kitap Canavarı",
      "Okurgezer",
      "Kitapların Efendisi",
      "Kitap Ustası",
      "Ustaların Ustası",
      "Bilge Okur",
      "Mistik Okur",
      "Efsanevi Okur",
    ];

    int index = toplamSayfa ~/ 500;
    if (index >= unvanlar.length) return unvanlar.last;
    return unvanlar[index];
  }
}
