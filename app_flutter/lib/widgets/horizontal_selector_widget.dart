import 'package:flutter/material.dart';
import '../models/selector_option.dart';

class HorizontalSelectorWidget<T> extends StatefulWidget {
  final List<SelectorOption<T>> options;

  final Function(T value) onSelected;

  final String? label;

  final IconData? icon;

  final double itemHeight;

  final EdgeInsets itemPadding;

  final EdgeInsets itemMargin;

  final EdgeInsets listPadding;

  final ScrollPhysics scrollPhysics;

  final String? emptyMessage;

  final bool autoScrollToSelected;

  const HorizontalSelectorWidget({
    super.key,
    required this.options,
    required this.onSelected,
    this.label,
    this.icon,
    this.itemHeight = 55.0,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.itemMargin = const EdgeInsets.only(right: 8),
    this.listPadding = const EdgeInsets.only(left: 16, right: 16),
    this.scrollPhysics = const ClampingScrollPhysics(),
    this.emptyMessage,
    this.autoScrollToSelected = false,
  });

  @override
  State<HorizontalSelectorWidget<T>> createState() =>
      _HorizontalSelectorWidgetState<T>();
}

class _HorizontalSelectorWidgetState<T>
    extends State<HorizontalSelectorWidget<T>> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    if (widget.autoScrollToSelected && widget.options.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelected();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    final selectedIndex = widget.options.indexWhere(
      (option) => option.isSelected,
    );
    if (selectedIndex != -1 && _scrollController.hasClients) {
      const estimatedItemWidth = 100.0;
      final scrollOffset = selectedIndex * estimatedItemWidth;

      _scrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildLabel() {
    if (widget.label == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            widget.label!,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.itemHeight,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          widget.emptyMessage ?? 'No items available',
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildHorizontalList() {
    final hasSubtitles = widget.options.any((opt) => opt.subtitle != null);
    final effectiveHeight = hasSubtitles
        ? widget.itemHeight + 8
        : widget.itemHeight;

    return SizedBox(
      height: effectiveHeight,
      child: ListView.builder(
        physics: widget.scrollPhysics,
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: widget.options.length,
        padding: widget.listPadding,
        itemBuilder: (context, index) {
          final option = widget.options[index];
          final isSelected = option.isSelected;

          return GestureDetector(
            onTap: option.isEnabled
                ? () => widget.onSelected(option.value)
                : null,
            child: Opacity(
              opacity: option.isEnabled ? 1.0 : 0.5,
              child: Container(
                margin: widget.itemMargin,
                padding: widget.itemPadding,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (option.highlightColor ??
                                Theme.of(context).primaryColor)
                            .withValues(alpha: 0.1)
                      : null,
                  border: Border.all(
                    color: isSelected
                        ? (option.highlightColor ??
                              Theme.of(context).primaryColor)
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.displayText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? (option.highlightColor ??
                                  Theme.of(context).primaryColor)
                            : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (option.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        option.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? (option.highlightColor ??
                                    Theme.of(context).primaryColor)
                              : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(),
        if (widget.label != null) const SizedBox(height: 6),
        widget.options.isEmpty ? _buildEmptyState() : _buildHorizontalList(),
      ],
    );
  }
}
