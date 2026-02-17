import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Simple UI debug logger for console-only logging
class UIDebugLogger {
  static bool _enabled = false;
  static int _indentLevel = 0;
  static final Map<String, int> _widgetBuildCounts = {};
  
  /// Enable/disable UI debugging
  static void setEnabled(bool enabled) {
    _enabled = enabled;
    _log('UI Debug Logging ${enabled ? 'ENABLED' : 'DISABLED'}');
  }
  
  /// Log widget build events
  static void logWidgetBuild(String widgetName, [String? details]) {
    if (!_enabled) return;
    
    final count = (_widgetBuildCounts[widgetName] ?? 0) + 1;
    _widgetBuildCounts[widgetName] = count;
    
    _log('🏗️  Building: $widgetName (build #$count)${details != null ? ' - $details' : ''}');
  }
  
  /// Log layout constraints and sizes
  static void logLayout(String widgetName, Size size, BoxConstraints constraints, [String? extraInfo]) {
    if (!_enabled) return;
    
    _log('📐 $widgetName Layout:');
    _log('  Size: ${size.width.toStringAsFixed(1)} x ${size.height.toStringAsFixed(1)}');
    _log('  Constraints: maxW=${constraints.maxWidth}, maxH=${constraints.maxHeight}');
    
    // Check for overflow
    if (constraints.hasBoundedWidth && size.width > constraints.maxWidth) {
      _log('  ⚠️ WIDTH OVERFLOW: ${(size.width - constraints.maxWidth).toStringAsFixed(1)}px');
    }
    if (constraints.hasBoundedHeight && size.height > constraints.maxHeight) {
      _log('  ⚠️ HEIGHT OVERFLOW: ${(size.height - constraints.maxHeight).toStringAsFixed(1)}px');
    }
    if (extraInfo != null) {
      _log('  ℹ️ $extraInfo');
    }
  }
  
  /// Log touch/gesture events
  static void logGesture(String widgetName, String gestureType) {
    if (!_enabled) return;
    
    _log('👆 $widgetName: $gestureType');
  }
  
  /// Log state changes
  static void logStateChange(String widgetName, String oldState, String newState) {
    if (!_enabled) return;
    
    _log('🔄 $widgetName State: $oldState → $newState');
  }
  
  /// Log navigation/routing
  static void logNavigation(String routeName, [String? action]) {
    if (!_enabled) return;
    
    _log('🧭 Navigation${action != null ? ' ($action)' : ''}: $routeName');
  }
  
  /// Log dialog events
  static void logDialog(String dialogName, String action) {
    if (!_enabled) return;
    
    _log('💬 Dialog $action: $dialogName');
  }
  
  /// Start a debug section (indents subsequent logs)
  static void startSection(String sectionName) {
    if (!_enabled) return;
    
    _log('┌─ $sectionName ──');
    _indentLevel++;
  }
  
  /// End a debug section
  static void endSection() {
    if (!_enabled) return;
    
    _indentLevel = _indentLevel > 0 ? _indentLevel - 1 : 0;
    _log('└─');
  }
  
  /// Reset build counters
  static void resetCounters() {
    _widgetBuildCounts.clear();
    _log('📊 Build counters reset');
  }
  
  /// Print build statistics
  static void printBuildStats() {
    if (!_enabled) return;
    
    _log('📊 Build Statistics:');
    final entries = _widgetBuildCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in entries.take(10)) {
      _log('  ${entry.key}: ${entry.value} builds');
    }
  }
  
  /// Internal logging with timestamp and indentation
  static void _log(String message) {
    if (!_enabled) return;
    
    final timestamp = DateTime.now().toIso8601String().split('T')[1].split('.')[0];
    final indent = '  ' * _indentLevel;
    
    // Use debugPrint for better formatting in Flutter console
    debugPrint('[$timestamp] 🐛 UI $indent$message');
  }
}

/// Extension to easily add debug logging to widgets
extension UIDebugExtension on Widget {
  /// Wrap widget with build logging
  Widget withBuildLogging(String widgetName, {String? details}) {
    return _DebugBuildLogger(
      widgetName: widgetName,
      details: details,
      child: this,
    );
  }
  
  /// Wrap widget with layout logging
  Widget withLayoutLogging(String widgetName) {
    return _DebugLayoutLogger(
      widgetName: widgetName,
      child: this,
    );
  }
  
  /// Wrap widget with gesture logging
  Widget withGestureLogging(String widgetName) {
    return GestureDetector(
      onTap: () => UIDebugLogger.logGesture(widgetName, 'tap'),
      onLongPress: () => UIDebugLogger.logGesture(widgetName, 'long press'),
      onDoubleTap: () => UIDebugLogger.logGesture(widgetName, 'double tap'),
      child: this,
    );
  }
}

/// Private helper widget for build logging
class _DebugBuildLogger extends StatelessWidget {
  final String widgetName;
  final String? details;
  final Widget child;

  const _DebugBuildLogger({
    required this.widgetName,
    required this.child,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    UIDebugLogger.logWidgetBuild(widgetName, details);
    return child;
  }
}

/// Private helper widget for layout logging
class _DebugLayoutLogger extends StatelessWidget {
  final String widgetName;
  final Widget child;

  const _DebugLayoutLogger({
    required this.widgetName,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final renderObject = context.findRenderObject();
          if (renderObject is RenderBox) {
            UIDebugLogger.logLayout(
              widgetName,
              renderObject.size,
              constraints,
            );
          }
        });
        
        return child;
      },
    );
  }
}