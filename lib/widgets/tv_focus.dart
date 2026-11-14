import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Controller yang disediakan [TvKeyboardScope] agar layar induk (mis. menu
/// Settings) bisa menutup keyboard layar (soft keyboard) saat tombol **back**
/// pada remote ditekan, alih-alih langsung menutup seluruh menu.
///
/// Hanya satu [TvTextField] yang boleh "editing" (keyboard terbuka) dalam satu
/// scope pada satu waktu — sesuai perilaku fokus single-focus Flutter.
class TvKeyboardController {
  _TvFieldState? _active;

  /// Apakah sedang ada field dengan keyboard terbuka.
  bool get isEditing => _active != null;

  void _register(_TvFieldState s) => _active = s;

  void _unregister(_TvFieldState s) {
    if (_active == s) _active = null;
  }

  /// Tutup keyboard yang sedang terbuka (fokus tetap di field-nya).
  void closeEditing() => _active?.stopEditing();
}

/// InheritedWidget yang membagikan [TvKeyboardController] ke [TvTextField]
/// anak-anaknya. Bungkus layar Settings (atau dialog) dengan widget ini.
class TvKeyboardScope extends InheritedWidget {
  TvKeyboardScope({super.key, required super.child, TvKeyboardController? controller})
      : controller = controller ?? TvKeyboardController();

  final TvKeyboardController controller;

  static TvKeyboardController? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<TvKeyboardScope>()
      ?.controller;

  @override
  bool updateShouldNotify(TvKeyboardScope oldWidget) => false;
}

/// TextField ramah remote/TV.
///
/// Masalah di TV: `TextField` biasa langsung memunculkan soft keyboard begitu
/// fokus D-pad mendarat di field, sehingga tombol arah "terkunci" ke keyboard
/// dan pengguna tidak bisa berpindah ke field lain. Solusi Android TV yang
/// direkomendasikan: field **readOnly** sampai user secara eksplisit menekan
/// tombol OK/Select untuk mulai mengetik.
///
/// Perilaku:
/// - Fokus biasa (D-pad) hanya menyorot field (border teal), TANPA keyboard.
/// - Tekan OK/Select/Enter/Space/Game A pada field terfokus -> mode edit,
///   keyboard muncul.
/// - Tekan Back/Escape/Game B atau kehilangan fokus -> keyboard ditutup, fokus
///   tetap di field, sehingga navigasi lanjut.
class TvTextField extends StatefulWidget {
  const TvTextField({
    super.key,
    required this.controller,
    this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.style,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.focusColor = Colors.tealAccent,
    this.editingColor = Colors.amberAccent,
  });

  final TextEditingController controller;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final int? minLines;
  final TextStyle? style;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final Color focusColor;
  final Color editingColor;

  @override
  State<TvTextField> createState() => _TvFieldState();
}

class _TvFieldState extends State<TvTextField> {
  late final FocusNode _node;
  bool _ownsNode = false;
  bool _editing = false;
  TvKeyboardController? _scope;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _node = widget.focusNode!;
    } else {
      _node = FocusNode();
      _ownsNode = true;
    }
    _node.addListener(_onFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = TvKeyboardScope.of(context);
  }

  void _onFocusChanged() {
    // Kehilangan fokus otomatis menutup keyboard agar navigasi tidak macet.
    if (!_node.hasFocus && _editing) {
      _stopEditing();
    }
    if (mounted) setState(() {}); // perbarui border saat fokus berubah
  }

  void _startEditing() {
    if (!widget.enabled || _editing) return;
    setState(() => _editing = true);
    _scope?._register(this);
    _node.requestFocus();
  }

  void _stopEditing() {
    if (!_editing) return;
    setState(() => _editing = false);
    _scope?._unregister(this);
    // Fokus dipertahankan di field agar D-pad bisa lanjut menavigasi.
    _node.requestFocus();
  }

  /// Dipanggil [TvKeyboardController] saat tombol back ditekan pada layar induk.
  void stopEditing() => _stopEditing();

  @override
  void dispose() {
    _node.removeListener(_onFocusChanged);
    if (_editing) _scope?._unregister(this);
    if (_ownsNode) _node.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode n, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final k = event.logicalKey;
    final isSelect = k == LogicalKeyboardKey.select ||
        k == LogicalKeyboardKey.enter ||
        k == LogicalKeyboardKey.numpadEnter ||
        k == LogicalKeyboardKey.gameButtonA ||
        k == LogicalKeyboardKey.space;
    final isBack = k == LogicalKeyboardKey.escape ||
        k == LogicalKeyboardKey.gameButtonB;

    if (!_editing && isSelect) {
      _startEditing();
      return KeyEventResult.handled;
    }
    if (_editing && isBack) {
      _stopEditing();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(6),
    borderSide: BorderSide(color: color, width: width),
  );

  @override
  Widget build(BuildContext context) {
    final focused = _node.hasFocus;
    final base = widget.decoration ?? const InputDecoration();

    OutlineInputBorder resolveBorder(OutlineInputBorder? fallback) {
      if (_editing) return _border(widget.editingColor, 2);
      if (focused) return _border(widget.focusColor, 2);
      return fallback ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.white24, width: 1),
          );
    }

    final decoration = base.copyWith(
      enabled: widget.enabled,
      border: resolveBorder(
        base.border is OutlineInputBorder ? base.border as OutlineInputBorder : null,
      ),
      focusedBorder: resolveBorder(
        base.focusedBorder is OutlineInputBorder
            ? base.focusedBorder as OutlineInputBorder
            : null,
      ),
      hintText: _editing
          ? (base.hintText ?? 'Tekan OK untuk mengetik...')
          : (focused && base.hintText == null
                ? 'Tekan OK untuk mengetik'
                : base.hintText),
    );

    // Catatan: _node hanya di-attach ke TextField. Focus pembungkus memakai
    // node internal sendiri; KeyEvent yang tidak dikonsumsi TextField naik
    // (bubble) ke pembungkus sehingga bisa kita tangani di _onKey.
    return Focus(
      onKeyEvent: _onKey,
      child: TextField(
        controller: widget.controller,
        focusNode: _node,
        readOnly: !_editing,
        showCursor: _editing,
        enabled: widget.enabled,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        maxLines: _editing ? widget.maxLines : 1,
        minLines: widget.minLines,
        style: widget.style,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        decoration: decoration,
      ),
    );
  }
}
