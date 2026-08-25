import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/warehouse_data.dart';
import '../services/api_service.dart';

enum _HistoryMetric { temperature, humidity }

class _HistoryRange {
  const _HistoryRange(this.label, this.hours);

  final String label;
  final int hours;
}

const _historyRanges = [
  _HistoryRange('ساعة', 1),
  _HistoryRange('6 ساعات', 6),
  _HistoryRange('24 ساعة', 24),
  _HistoryRange('7 أيام', 168),
];

class SensorHistoryScreen extends StatefulWidget {
  const SensorHistoryScreen({
    super.key,
    required this.api,
    required this.sensors,
    required this.initialSensorId,
  });

  final ApiService api;
  final Map<String, JsonMap> sensors;
  final String initialSensorId;

  @override
  State<SensorHistoryScreen> createState() => _SensorHistoryScreenState();
}

class _SensorHistoryScreenState extends State<SensorHistoryScreen> {
  late String _sensorId;
  _HistoryRange _range = _historyRanges.first;
  _HistoryMetric _metric = _HistoryMetric.temperature;
  SensorHistory? _history;
  String? _error;
  bool _loading = true;
  int? _selectedIndex;
  int _requestVersion = 0;

  List<String> get _sensorIds {
    final ids = widget.sensors.keys.toList()..sort();
    return ids;
  }

  @override
  void initState() {
    super.initState();
    final ids = _sensorIds;
    _sensorId = ids.contains(widget.initialSensorId)
        ? widget.initialSensorId
        : ids.first;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final requestVersion = ++_requestVersion;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final history = await widget.api.sensorHistory(
        _sensorId,
        hours: _range.hours,
        limit: 300,
      );
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() {
        _history = history;
        _selectedIndex = history.points.isEmpty
            ? null
            : history.points.length - 1;
      });
    } on ApiException catch (error) {
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() => _error = error.message);
    } on FormatException {
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() => _error = 'تعذر قراءة بيانات الحساس');
    } finally {
      if (mounted && requestVersion == _requestVersion) {
        setState(() => _loading = false);
      }
    }
  }

  void _selectSensor(String sensorId) {
    if (sensorId == _sensorId) return;
    setState(() => _sensorId = sensorId);
    _loadHistory();
  }

  void _selectRange(int hours) {
    final range = _historyRanges.firstWhere((item) => item.hours == hours);
    if (range.hours == _range.hours) return;
    setState(() => _range = range);
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final sensor = widget.sensors[_sensorId] ?? const <String, dynamic>{};
    final online = boolValue(sensor['online']);
    final points = _history?.points ?? const <SensorHistoryPoint>[];
    final values = points
        .map(
          (point) => _metric == _HistoryMetric.temperature
              ? point.temperature
              : point.humidity,
        )
        .toList();
    final metricColor = _metric == _HistoryMetric.temperature
        ? AppColors.danger
        : AppColors.success;
    final unit = _metric == _HistoryMetric.temperature ? '°C' : '%';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل الحساس'),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: _loading ? null : _loadHistory,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadHistory,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.device_thermostat,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _sensorId.toUpperCase(),
                          textDirection: TextDirection.ltr,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: online
                                    ? AppColors.success
                                    : AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              online ? 'متصل الآن' : 'غير متصل',
                              style: TextStyle(
                                color: online
                                    ? AppColors.success
                                    : AppColors.danger,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'الحساس',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sensorId,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceHigh,
                    icon: const Icon(Icons.expand_more),
                    items: _sensorIds
                        .map(
                          (id) => DropdownMenuItem(
                            value: id,
                            child: Text(
                              id.toUpperCase(),
                              textDirection: TextDirection.ltr,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) _selectSensor(value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  segments: [
                    for (final range in _historyRanges)
                      ButtonSegment(
                        value: range.hours,
                        label: Text(range.label),
                      ),
                  ],
                  selected: {_range.hours},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) =>
                      _selectRange(selection.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: const WidgetStatePropertyAll(
                      TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    side: const WidgetStatePropertyAll(
                      BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MetricButton(
                      label: 'الحرارة',
                      icon: Icons.thermostat,
                      color: AppColors.danger,
                      selected: _metric == _HistoryMetric.temperature,
                      onPressed: () =>
                          setState(() => _metric = _HistoryMetric.temperature),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricButton(
                      label: 'الرطوبة',
                      icon: Icons.water_drop_outlined,
                      color: AppColors.success,
                      selected: _metric == _HistoryMetric.humidity,
                      onPressed: () =>
                          setState(() => _metric = _HistoryMetric.humidity),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_loading)
                const _LoadingHistory()
              else if (_error != null)
                _HistoryError(message: _error!, onRetry: _loadHistory)
              else if (points.isEmpty)
                const _EmptyHistory()
              else ...[
                _MetricSummary(values: values, unit: unit),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _metric == _HistoryMetric.temperature
                                  ? 'تغيّر الحرارة'
                                  : 'تغيّر الرطوبة',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${points.length} قراءة',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _HistoryChart(
                          points: points,
                          values: values,
                          color: metricColor,
                          unit: unit,
                          selectedIndex: _selectedIndex,
                          onSelected: (index) =>
                              setState(() => _selectedIndex = index),
                        ),
                        const SizedBox(height: 8),
                        _SelectedReading(
                          point:
                              points[(_selectedIndex ?? points.length - 1)
                                  .clamp(0, points.length - 1)],
                          value:
                              values[(_selectedIndex ?? values.length - 1)
                                  .clamp(0, values.length - 1)],
                          unit: unit,
                          color: metricColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricButton extends StatelessWidget {
  const _MetricButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(42),
        foregroundColor: selected ? color : AppColors.muted,
        backgroundColor: selected
            ? color.withValues(alpha: 0.12)
            : Colors.transparent,
        side: BorderSide(color: selected ? color : AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _MetricSummary extends StatelessWidget {
  const _MetricSummary({required this.values, required this.unit});

  final List<double> values;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final minimum = values.reduce(math.min);
    final maximum = values.reduce(math.max);
    final average =
        values.reduce((left, right) => left + right) / values.length;
    return Row(
      children: [
        Expanded(
          child: _SummaryItem(
            label: 'الحالي',
            value: '${values.last.toStringAsFixed(1)}$unit',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryItem(
            label: 'المتوسط',
            value: '${average.toStringAsFixed(1)}$unit',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryItem(
            label: 'النطاق',
            value:
                '${minimum.toStringAsFixed(0)}–${maximum.toStringAsFixed(0)}$unit',
          ),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryChart extends StatelessWidget {
  const _HistoryChart({
    required this.points,
    required this.values,
    required this.color,
    required this.unit,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<SensorHistoryPoint> points;
  final List<double> values;
  final Color color;
  final String unit;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  void _select(Offset position, double width) {
    const left = 12.0;
    const right = 48.0;
    final plotWidth = math.max(1, width - left - right);
    final ratio = ((position.dx - left) / plotWidth).clamp(0.0, 1.0);
    onSelected((ratio * (points.length - 1)).round());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) =>
              _select(details.localPosition, constraints.maxWidth),
          onHorizontalDragUpdate: (details) =>
              _select(details.localPosition, constraints.maxWidth),
          child: SizedBox(
            height: 240,
            width: double.infinity,
            child: CustomPaint(
              painter: _HistoryChartPainter(
                points: points,
                values: values,
                color: color,
                unit: unit,
                selectedIndex: selectedIndex,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HistoryChartPainter extends CustomPainter {
  _HistoryChartPainter({
    required this.points,
    required this.values,
    required this.color,
    required this.unit,
    required this.selectedIndex,
  });

  final List<SensorHistoryPoint> points;
  final List<double> values;
  final Color color;
  final String unit;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 12.0;
    const right = 48.0;
    const top = 12.0;
    const bottom = 26.0;
    final plot = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final rawMin = values.reduce(math.min);
    final rawMax = values.reduce(math.max);
    final spread = rawMax - rawMin;
    final padding = spread == 0
        ? math.max(1.0, rawMax.abs() * 0.05)
        : spread * 0.12;
    final minimum = rawMin - padding;
    final maximum = rawMax + padding;

    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.8)
      ..strokeWidth = 1;
    for (var index = 0; index <= 4; index++) {
      final y = plot.top + (plot.height * index / 4);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      final labelValue = maximum - ((maximum - minimum) * index / 4);
      _drawText(
        canvas,
        '${labelValue.toStringAsFixed(0)}$unit',
        Offset(plot.right + 6, y - 7),
        AppColors.muted,
        9,
      );
    }

    double xFor(int index) => values.length == 1
        ? plot.center.dx
        : plot.left + (plot.width * index / (values.length - 1));
    double yFor(double value) =>
        plot.bottom - ((value - minimum) / (maximum - minimum) * plot.height);

    final linePath = Path();
    for (var index = 0; index < values.length; index++) {
      final point = Offset(xFor(index), yFor(values[index]));
      if (index == 0) {
        linePath.moveTo(point.dx, point.dy);
      } else {
        linePath.lineTo(point.dx, point.dy);
      }
    }

    final fillPath = Path.from(linePath)
      ..lineTo(xFor(values.length - 1), plot.bottom)
      ..lineTo(xFor(0), plot.bottom)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.24),
            color.withValues(alpha: 0.01),
          ],
        ).createShader(plot),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final selected = (selectedIndex ?? values.length - 1).clamp(
      0,
      values.length - 1,
    );
    final selectedPoint = Offset(xFor(selected), yFor(values[selected]));
    canvas.drawLine(
      Offset(selectedPoint.dx, plot.top),
      Offset(selectedPoint.dx, plot.bottom),
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..strokeWidth = 1,
    );
    canvas.drawCircle(selectedPoint, 5, Paint()..color = AppColors.surface);
    canvas.drawCircle(selectedPoint, 3.5, Paint()..color = color);

    final labelIndexes = values.length == 1
        ? <int>[0]
        : <int>[0, (values.length - 1) ~/ 2, values.length - 1];
    for (var position = 0; position < labelIndexes.length; position++) {
      final index = labelIndexes[position];
      final text = _formatAxisTime(points[index].time);
      final painter = _textPainter(text, AppColors.muted, 9);
      final x = switch (position) {
        0 => plot.left,
        1 => plot.center.dx - painter.width / 2,
        _ => plot.right - painter.width,
      };
      painter.paint(canvas, Offset(x, plot.bottom + 7));
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double fontSize,
  ) {
    _textPainter(text, color, fontSize).paint(canvas, offset);
  }

  TextPainter _textPainter(String text, Color color, double fontSize) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontFamily: 'NotoSans',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  bool shouldRepaint(covariant _HistoryChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

class _SelectedReading extends StatelessWidget {
  const _SelectedReading({
    required this.point,
    required this.value,
    required this.unit,
    required this.color,
  });

  final SensorHistoryPoint point;
  final double value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatFullTime(point.time),
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
          Text(
            '${value.toStringAsFixed(1)}$unit',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingHistory extends StatelessWidget {
  const _LoadingHistory();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 300,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, color: AppColors.danger, size: 36),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 280,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timeline, color: AppColors.muted, size: 38),
          SizedBox(height: 12),
          Text(
            'لا توجد قراءات ضمن هذه المدة',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _formatAxisTime(DateTime value) {
  return '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';
}

String _formatFullTime(DateTime value) {
  return '${_twoDigits(value.day)}/${_twoDigits(value.month)} '
      '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';
}
