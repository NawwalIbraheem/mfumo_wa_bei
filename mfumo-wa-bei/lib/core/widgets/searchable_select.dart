import 'package:flutter/material.dart';

class SearchableSelectFormField<T> extends FormField<T> {
  SearchableSelectFormField({
    super.key,
    required List<T> items,
    required String labelText,
    required String Function(T item) itemLabel,
    String Function(T item)? itemSubtitle,
    IconData? leadingIcon,
    T? value,
    ValueChanged<T?>? onChanged,
    String? hintText,
    String? searchHintText,
    String? emptyText,
    bool clearable = false,
    super.enabled,
    super.validator,
    super.autovalidateMode,
  }) : super(
         initialValue: value,
         builder: (field) {
           return _SearchableSelectBody<T>(
             items: items,
             labelText: labelText,
             itemLabel: itemLabel,
             itemSubtitle: itemSubtitle,
             leadingIcon: leadingIcon,
             hintText: hintText,
             searchHintText: searchHintText,
             emptyText: emptyText,
             clearable: clearable,
             enabled: enabled,
             field: field,
             onChanged: onChanged,
           );
         },
       );
}

class _SearchableSelectBody<T> extends StatelessWidget {
  const _SearchableSelectBody({
    required this.items,
    required this.labelText,
    required this.itemLabel,
    required this.field,
    required this.enabled,
    this.itemSubtitle,
    this.leadingIcon,
    this.hintText,
    this.searchHintText,
    this.emptyText,
    this.clearable = false,
    this.onChanged,
  });

  final List<T> items;
  final String labelText;
  final String Function(T item) itemLabel;
  final String Function(T item)? itemSubtitle;
  final IconData? leadingIcon;
  final String? hintText;
  final String? searchHintText;
  final String? emptyText;
  final bool clearable;
  final bool enabled;
  final FormFieldState<T> field;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = field.value;
    final selectedText = selected == null ? null : itemLabel(selected);

    return InkWell(
      onTap: enabled ? () => _openPicker(context) : null,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        isEmpty: selected == null,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText ?? 'Chagua',
          errorText: field.errorText,
          enabled: enabled,
          suffixIcon: clearable && selected != null && enabled
              ? IconButton(
                  onPressed: () {
                    field.didChange(null);
                    onChanged?.call(null);
                  },
                  icon: const Icon(Icons.close),
                )
              : const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        child: Text(
          selectedText ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: enabled
              ? null
              : TextStyle(color: Theme.of(context).disabledColor),
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _SearchableSelectSheet<T>(
        title: labelText,
        items: items,
        selected: field.value,
        itemLabel: itemLabel,
        itemSubtitle: itemSubtitle,
        leadingIcon: leadingIcon,
        searchHintText: searchHintText ?? 'Tafuta...',
        emptyText: emptyText ?? 'Hakuna matokeo.',
      ),
    );

    if (selected == null) {
      return;
    }
    field.didChange(selected);
    onChanged?.call(selected);
  }
}

class _SearchableSelectSheet<T> extends StatefulWidget {
  const _SearchableSelectSheet({
    required this.title,
    required this.items,
    required this.selected,
    required this.itemLabel,
    required this.searchHintText,
    required this.emptyText,
    this.itemSubtitle,
    this.leadingIcon,
  });

  final String title;
  final List<T> items;
  final T? selected;
  final String Function(T item) itemLabel;
  final String Function(T item)? itemSubtitle;
  final IconData? leadingIcon;
  final String searchHintText;
  final String emptyText;

  @override
  State<_SearchableSelectSheet<T>> createState() =>
      _SearchableSelectSheetState<T>();
}

class _SearchableSelectSheetState<T> extends State<_SearchableSelectSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filteredItems = query.isEmpty
        ? widget.items
        : widget.items.where((item) {
            final label = widget.itemLabel(item).toLowerCase();
            final subtitle = widget.itemSubtitle?.call(item).toLowerCase();
            return label.contains(query) || subtitle?.contains(query) == true;
          }).toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.78,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: widget.searchHintText,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(child: Text(widget.emptyText))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                      itemCount: filteredItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final selected = item == widget.selected;
                        final subtitle = widget.itemSubtitle?.call(item);
                        return ListTile(
                          selected: selected,
                          selectedTileColor: const Color(0xFFE8F5E9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: widget.leadingIcon == null
                              ? null
                              : CircleAvatar(
                                  backgroundColor: const Color(0xFFE8F5E9),
                                  child: Icon(
                                    widget.leadingIcon,
                                    color: const Color(0xFF0E7A3B),
                                  ),
                                ),
                          title: Text(
                            widget.itemLabel(item),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: subtitle == null || subtitle.isEmpty
                              ? null
                              : Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF0E7A3B),
                                )
                              : null,
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
