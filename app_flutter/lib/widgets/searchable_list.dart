import 'package:flutter/cupertino.dart';

/// A generic searchable list widget that handles search logic and UI
///
/// This widget provides a search field and automatically filters items
/// based on the search query using a custom filter function.
///
/// Type parameter [T] is the type of items in the list.
class SearchableList<T> extends StatefulWidget {
  /// The complete list of items to search through
  final List<T> items;

  /// Function to filter items based on search query
  /// Should return true if the item matches the query
  final bool Function(T item, String query) filterFunction;

  /// Builder function to create the list widget from filtered items
  final Widget Function(BuildContext context, List<T> filteredItems)
      listBuilder;

  /// Placeholder text for the search field
  final String searchPlaceholder;

  /// Optional padding around the search field
  final EdgeInsetsGeometry? searchPadding;

  /// Optional background color for the search field
  final Color? searchBackgroundColor;

  /// Whether to show the search field (default: true)
  final bool showSearch;

  const SearchableList({
    super.key,
    required this.items,
    required this.filterFunction,
    required this.listBuilder,
    required this.searchPlaceholder,
    this.searchPadding = const EdgeInsets.all(16.0),
    this.searchBackgroundColor,
    this.showSearch = true,
  });

  @override
  State<SearchableList<T>> createState() => _SearchableListState<T>();
}

class _SearchableListState<T> extends State<SearchableList<T>> {
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    }
  }

  List<T> _getFilteredItems() {
    if (_searchQuery.isEmpty) {
      return widget.items;
    }

    final query = _searchQuery.toLowerCase();
    return widget.items
        .where((item) => widget.filterFunction(item, query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _getFilteredItems();

    return Column(
      children: [
        if (widget.showSearch)
          Padding(
            padding: widget.searchPadding ?? EdgeInsets.zero,
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: widget.searchPlaceholder,
              backgroundColor: widget.searchBackgroundColor ??
                  CupertinoColors.systemGrey6.resolveFrom(context),
            ),
          ),
        Expanded(
          child: widget.listBuilder(context, filteredItems),
        ),
      ],
    );
  }
}
