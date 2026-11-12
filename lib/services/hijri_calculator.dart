/// Kalkulator tanggal Hijriah inkremental.
///
/// Dipisahkan dari `_KioskScreenState` (god-class di `main.dart`) sebagai langkah
/// awal restrukturisasi. Fungsi intinya murni (tanpa akses ke state/IO) sehingga
/// mudah diuji dan dipakai ulang.
library;

/// Hasil konversi Hijriah (hari, bulan 1-12, tahun) beserta penamaan bulan
/// Bahasa Indonesia yang dipakai aplikasi.
class HijriDate {
  const HijriDate(this.day, this.month, this.year);

  final int day;
  final int month;
  final int year;

  /// Nama bulan Hijriah (indeks 0 = Muharram ... 11 = Dzulhijah).
  static const List<String> monthNames = <String>[
    'Muharram',
    'Safar',
    'Rabiul Awal',
    'Rabiul Akhir',
    'Jumadil Awal',
    'Jumadil Akhir',
    'Rajab',
    "Sya'ban",
    'Ramadhan',
    'Syawwal',
    'Dzulqaidah',
    'Dzulhijah',
  ];

  String get monthName =>
      (month >= 1 && month <= 12) ? monthNames[month - 1] : '';

  /// Format tampilan: `"12 Ramadhan 1446 H"`.
  String get formatted => "$day $monthName $year H";
}

/// Konversi Hijriah berbasis "anchor": satu tanggal acuan (dari API) lalu
/// maju secara inkremental dengan estimasi tabular (bulan ganjil 30 hari,
/// genap 29 hari). Perilaku identik dengan versi inline sebelumnya di `main.dart`.
class HijriCalculator {
  const HijriCalculator._();

  /// Majukan [anchorDay]/[anchorMonth]/[anchorYear] sebanyak [diffDays] hari.
  ///
  /// [diffDays] diasumsikan >= 0 (anchor adalah tanggal di masa lalu/ini).
  static HijriDate advance({
    required int anchorDay,
    required int anchorMonth,
    required int anchorYear,
    required int diffDays,
  }) {
    int hDay = anchorDay + diffDays;
    int hMonth = anchorMonth;
    int hYear = anchorYear;

    while (true) {
      final int daysInMonth = (hMonth % 2 != 0) ? 30 : 29;
      if (hDay <= daysInMonth) break;
      hDay -= daysInMonth;
      hMonth++;
      if (hMonth > 12) {
        hMonth = 1;
        hYear++;
      }
    }

    return HijriDate(hDay, hMonth, hYear);
  }
}
