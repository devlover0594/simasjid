class MurottalSchedule {
  String prayer;
  bool enabled;
  int minutesBefore;
  String? path; // Path to local audio file
  String sourceType; // 'local', 'file', 'api'
  String? qari; // For API sources
  int? surahNumber; // For API sources
  int? currentSurah; // Track the current surah being played
  bool isRandom; // For local files, play random from folder
  int loopCount; // How many times to loop the audio
  int stopBeforeAdzan; // Stop X minutes before adzan
  bool tarhimEnabled;
  int tarhimMinutesBefore;
  bool adzanEnabled;

  MurottalSchedule({
    required this.prayer,
    this.enabled = false,
    this.minutesBefore = 10,
    this.path,
    this.sourceType = 'local',
    this.qari,
    this.surahNumber,
    this.currentSurah,
    this.isRandom = false,
    this.loopCount = 1,
    this.stopBeforeAdzan = 2,
    this.tarhimEnabled = false,
    this.tarhimMinutesBefore = 20,
    this.adzanEnabled = false,
  });

  factory MurottalSchedule.fromJson(Map<String, dynamic> json) {
    return MurottalSchedule(
      prayer: json['prayer'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
      minutesBefore: json['minutes_before'] as int? ?? 10,
      path: json['path'] as String?,
      sourceType: json['source_type'] as String? ?? 'local',
      qari: json['qari'] as String?,
      surahNumber: json['surah_number'] as int?,
      currentSurah: json['current_surah'] as int?,
      isRandom: json['is_random'] as bool? ?? false,
      loopCount: json['loop_count'] as int? ?? 1,
      stopBeforeAdzan: json['stop_before_adzan'] as int? ?? 2,
      tarhimEnabled: json['tarhim_enabled'] as bool? ?? false,
      tarhimMinutesBefore: json['tarhim_minutes_before'] as int? ?? 20,
      adzanEnabled: json['adzan_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prayer': prayer,
      'enabled': enabled,
      'minutes_before': minutesBefore,
      'path': path,
      'source_type': sourceType,
      'qari': qari,
      'surah_number': surahNumber,
      'current_surah': currentSurah,
      'is_random': isRandom,
      'loop_count': loopCount,
      'stop_before_adzan': stopBeforeAdzan,
      'tarhim_enabled': tarhimEnabled,
      'tarhim_minutes_before': tarhimMinutesBefore,
      'adzan_enabled': adzanEnabled,
    };
  }

  static MurottalSchedule createDefault(String prayer) {
    return MurottalSchedule(
      prayer: prayer,
      enabled: false,
      minutesBefore: 10,
      path: '',
      sourceType: 'file',
      qari: 'Abdullah-Al-Juhany',
      surahNumber: 1,
      currentSurah: 1,
      isRandom: false,
      loopCount: 1,
      stopBeforeAdzan: 2,
      tarhimEnabled: false,
      tarhimMinutesBefore: 20,
      adzanEnabled: false,
    );
  }
}
