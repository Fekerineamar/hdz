import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/ai/tools.dart';
import '../../models/domain.dart';

/// Renders the SSO slider ("block puzzle") captcha and returns the x position
/// the user chose. The piece is a full-height vertical strip that slides
/// horizontally; its `y` is fixed at 5 (as observed in the captured traffic).
class CaptchaDialog extends StatefulWidget {
  const CaptchaDialog({super.key, required this.puzzle});
  final CaptchaPuzzle puzzle;

  @override
  State<CaptchaDialog> createState() => _CaptchaDialogState();
}

class _CaptchaDialogState extends State<CaptchaDialog> {
  Uint8List? _bg;
  Uint8List? _piece;

  // Natural pixel sizes (measured at runtime).
  int _bgW = 310;
  int _bgH = 155;
  int _pieceW = 47;
  int _pieceH = 155;

  // Visible (non-transparent) shape bounds inside the piece image.
  int _shapeX = 0, _shapeY = 0, _shapeW = 47, _shapeH = 155;

  double _x = 0;

  @override
  void initState() {
    super.initState();
    try {
      _bg = base64Decode(widget.puzzle.originalImageBase64);
    } catch (_) {}
    try {
      _piece = base64Decode(widget.puzzle.jigsawImageBase64);
    } catch (_) {}
    _saveForDebug();
    _measureAndAutoSolve();
  }

  Future<void> _measureAndAutoSolve() async {
    await _measure();
    if (!mounted) return;
    final ncc = await _autoSolve();
    if (!mounted) return;
    // Only auto-submit a confident match; otherwise let the user fine-tune
    // from our best guess (the slider is already pre-positioned).
    if (ncc != null && ncc >= 0.5) {
      debugPrint('[AUTO] solved captcha at x=${_x.toStringAsFixed(0)} '
          'ncc=${ncc.toStringAsFixed(3)}');
      Navigator.of(context).pop(CaptchaAnswer(_x, 5));
    } else {
      debugPrint('[AUTO] low confidence (ncc=${ncc?.toStringAsFixed(3) ?? "n/a"}), '
          'falling back to manual at x=${_x.toStringAsFixed(0)}');
      setState(() {});
    }
  }

  /// Locates the gap in the background via normalized cross-correlation of the
  /// jigsaw shape, pre-positions [_x] on the best guess, and returns the NCC
  /// confidence (or null on error).
  Future<double?> _autoSolve() async {
    try {
      final bg = await ui.instantiateImageCodec(_bg!);
      final bgFrame = await bg.getNextFrame();
      final bgData =
          await bgFrame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bgW = bgFrame.image.width;

      final pc = await ui.instantiateImageCodec(_piece!);
      final pcFrame = await pc.getNextFrame();
      final pcData =
          await pcFrame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final pcW = pcFrame.image.width;

      if (bgData == null || pcData == null) return null;

      final sx = _shapeX, sy = _shapeY, sw = _shapeW, sh = _shapeH;

      // Build the template from only the visible (non-transparent) pixels of
      // the jigsaw shape. Transparent padding is pure black and pollutes NCC,
      // so it must be excluded (this is the key to a reliable match).
      final offsets = <int>[]; // packed (dy * sw + dx) within the shape bbox
      final tmpl = <double>[];
      for (var y = sy; y < sy + sh; y++) {
        for (var x = sx; x < sx + sw; x++) {
          final i = (y * pcW + x) * 4;
          if (pcData.getUint8(i + 3) < 40) continue; // transparent
          offsets.add((y - sy) * sw + (x - sx));
          tmpl.add(
              (pcData.getUint8(i) + pcData.getUint8(i + 1) + pcData.getUint8(i + 2)) / 3.0);
        }
      }
      final n = tmpl.length;
      if (n < 16) return null;
      final tMean = tmpl.reduce((a, b) => a + b) / n;
      final tm = tmpl.map((v) => v - tMean).toList();
      final tmLen = sqrt(tm.map((v) => v * v).reduce((a, b) => a + b));
      if (tmLen < 1e-6) return null;

      double bestNcc = -1;
      var bestX = 0;
      for (var x = 0; x + sw <= bgW; x++) {
        double sum = 0;
        final region = <double>[];
        for (final off in offsets) {
          final dx = off % sw;
          final dy = off ~/ sw;
          final i = ((sy + dy) * bgW + (x + dx)) * 4;
          final v =
              (bgData.getUint8(i) + bgData.getUint8(i + 1) + bgData.getUint8(i + 2)) / 3.0;
          region.add(v);
          sum += v;
        }
        final rMean = sum / n;
        double dot = 0, rLen = 0;
        for (var k = 0; k < n; k++) {
          final rm = region[k] - rMean;
          dot += tm[k] * rm;
          rLen += rm * rm;
        }
        final rLenSqrt = sqrt(rLen);
        if (rLenSqrt < 1e-6) continue;
        final ncc = dot / (tmLen * rLenSqrt);
        if (ncc > bestNcc) {
          bestNcc = ncc;
          bestX = x;
        }
      }

      final guess = (bestX - sx).clamp(0, _maxX.toInt());
      _x = guess.toDouble();
      debugPrint('[AUTO] best match x=$bestX ncc=${bestNcc.toStringAsFixed(3)} '
          'correctX=$guess');
      return bestNcc;
    } catch (e) {
      debugPrint('[AUTO] error: $e');
      return null;
    }
  }

  Future<void> _saveForDebug() async {
    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) return;
      await File('${dir.path}/captcha_bg.png').writeAsBytes(_bg!);
      await File('${dir.path}/captcha_piece.png').writeAsBytes(_piece!);
      debugPrint('[CAPTCHA] saved images to ${dir.path}');
    } catch (e) {
      debugPrint('[CAPTCHA] save failed: $e');
    }
  }

  Future<void> _measure() async {
    if (_bg != null) {
      final codec = await ui.instantiateImageCodec(_bg!);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _bgW = frame.image.width;
          _bgH = frame.image.height;
        });
      }
    }
    if (_piece != null) {
      final codec = await ui.instantiateImageCodec(_piece!);
      final frame = await codec.getNextFrame();
      final w = frame.image.width;
      final h = frame.image.height;
      int sx0 = w, sy0 = h, sx1 = -1, sy1 = -1;
      final data =
          await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data != null) {
        for (int y = 0; y < h; y++) {
          for (int x = 0; x < w; x++) {
            final a = data.getUint8((y * w + x) * 4 + 3);
            if (a > 40) {
              if (x < sx0) sx0 = x;
              if (x > sx1) sx1 = x;
              if (y < sy0) sy0 = y;
              if (y > sy1) sy1 = y;
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          _pieceW = w;
          _pieceH = h;
          _shapeX = sx0 < w ? sx0 : 0;
          _shapeY = sy0 < h ? sy0 : 0;
          _shapeW = sx1 >= sx0 ? sx1 - sx0 + 1 : w;
          _shapeH = sy1 >= sy0 ? sy1 - sy0 + 1 : h;
        });
      }
    }
    debugPrint('[CAPTCHA] bg=${_bgW}x$_bgH piece=${_pieceW}x$_pieceH '
        'shape=($_shapeX,$_shapeY ${_shapeW}x$_shapeH)');
  }

  /// The piece's bounding box is 47px wide; it slides within the background,
  /// so the max x is (bgWidth - pieceWidth), matching the browser.
  double get _maxX => (_bgW - _pieceW).toDouble().clamp(1, 100000);

  @override
  Widget build(BuildContext context) {
    final displayW =
        (MediaQuery.of(context).size.width - 96).clamp(240.0, 420.0);
    final displayH = displayW * _bgH / _bgW;
    final pieceW = displayW * _pieceW / _bgW;
    final pieceH = displayH * _pieceH / _bgH;

    return AlertDialog(
      title: const Text('Complete the puzzle'),
      content: SizedBox(
        width: displayW,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_bg != null)
              GestureDetector(
                onHorizontalDragUpdate: (d) => setState(
                    () => _x = (_x + d.delta.dx * (_bgW / displayW))
                        .clamp(0, _maxX)),
                onTapDown: (d) => setState(() => _x =
                    (d.localPosition.dx * (_bgW / displayW)).clamp(0, _maxX)),
                child: SizedBox(
                  width: displayW,
                  height: displayH,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Image.memory(_bg!, fit: BoxFit.fill),
                      ),
                      if (_piece != null)
                        Positioned(
                          left: (_x / _bgW) * displayW,
                          top: 0,
                          child: Image.memory(
                            _piece!,
                            width: pieceW,
                            height: pieceH,
                            fit: BoxFit.fill,
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else
              const Text('Puzzle image unavailable.'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: '-5',
                  onPressed: () =>
                      setState(() => _x = (_x - 5).clamp(0, _maxX)),
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_left),
                  tooltip: '-1',
                  onPressed: () =>
                      setState(() => _x = (_x - 1).clamp(0, _maxX)),
                ),
                Text('x = ${_x.toStringAsFixed(0)} / ${_maxX.toStringAsFixed(0)}'),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_right),
                  tooltip: '+1',
                  onPressed: () =>
                      setState(() => _x = (_x + 1).clamp(0, _maxX)),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: '+5',
                  onPressed: () =>
                      setState(() => _x = (_x + 5).clamp(0, _maxX)),
                ),
              ],
            ),
            const Text('Drag the piece to fit the gap, then fine-tune.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(CaptchaAnswer(_x, 5)),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
