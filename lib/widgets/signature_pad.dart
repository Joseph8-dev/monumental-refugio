import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme.dart';

/// Panel de firma manuscrita. Devuelve un PNG en base64 al confirmar.
Future<String?> showSignatureSheet(BuildContext context,
    {required String title}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _SignatureSheet(title: title),
  );
}

class _SignatureSheet extends StatefulWidget {
  final String title;
  const _SignatureSheet({required this.title});

  @override
  State<_SignatureSheet> createState() => _SignatureSheetState();
}

class _SignatureSheetState extends State<_SignatureSheet> {
  final List<List<Offset>> _strokes = [];
  final GlobalKey _padKey = GlobalKey();

  Future<String?> _export() async {
    final box = _padKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || _strokes.isEmpty) return null;

    final size = box.size;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in _strokes) {
      if (stroke.length < 2) {
        if (stroke.isNotEmpty) {
          canvas.drawCircle(stroke.first, 1.4, paint..style = PaintingStyle.fill);
          paint.style = PaintingStyle.stroke;
        }
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }

    final img = await recorder
        .endRecording()
        .toImage(size.width.round(), size.height.round());
    final ByteData? bytes =
        await img.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return null;
    return base64Encode(bytes.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),
              Text(widget.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              const Text('Firme dentro del recuadro',
                  style: TextStyle(color: AppColors.gray, fontSize: 13)),
              const SizedBox(height: 12),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                ),
                clipBehavior: Clip.antiAlias,
                child: GestureDetector(
                  key: _padKey,
                  onPanStart: (d) =>
                      setState(() => _strokes.add([d.localPosition])),
                  onPanUpdate: (d) =>
                      setState(() => _strokes.last.add(d.localPosition)),
                  child: CustomPaint(
                    painter: _SignaturePainter(_strokes),
                    size: Size.infinite,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _strokes.clear()),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _strokes.isEmpty
                          ? null
                          : () async {
                              final b64 = await _export();
                              if (context.mounted) {
                                Navigator.pop(context, b64);
                              }
                            },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Confirmar firma'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  _SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter old) => true;
}

/// Miniatura de una firma guardada (base64).
class SignaturePreview extends StatelessWidget {
  final String? base64Png;
  final String label;
  final VoidCallback onTap;

  const SignaturePreview({
    super.key,
    required this.base64Png,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final has = base64Png != null && base64Png!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 92,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: has ? Colors.white : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: has ? AppColors.blue : AppColors.line,
                width: has ? 1.4 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: has
                    ? Image.memory(base64Decode(base64Png!),
                        fit: BoxFit.contain)
                    : Text('$label — toca para firmar',
                        style: const TextStyle(color: AppColors.gray)),
              ),
              Icon(has ? Icons.edit : Icons.draw_outlined,
                  color: AppColors.blue, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
