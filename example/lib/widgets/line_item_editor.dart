import 'package:flutter/material.dart';

import '../bloc/invoice/invoice_state.dart';
import '../ui/breakpoints.dart';

/// Compact inline editor for a single invoice line. Responsive:
/// collapses to a single column on narrow screens.
class LineItemEditor extends StatefulWidget {
  final int index;
  final InvoiceLineDraft draft;
  final ValueChanged<InvoiceLineDraft> onChanged;
  final VoidCallback onRemove;
  final bool canRemove;

  const LineItemEditor({
    super.key,
    required this.index,
    required this.draft,
    required this.onChanged,
    required this.onRemove,
    required this.canRemove,
  });

  @override
  State<LineItemEditor> createState() => _LineItemEditorState();
}

class _LineItemEditorState extends State<LineItemEditor> {
  late TextEditingController _name;
  late TextEditingController _qty;
  late TextEditingController _price;
  late TextEditingController _tax;
  late TextEditingController _discount;
  late TextEditingController _reason;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.draft.itemName);
    _qty = TextEditingController(text: widget.draft.quantity);
    _price = TextEditingController(text: widget.draft.unitPrice);
    _tax = TextEditingController(text: widget.draft.taxPercent);
    _discount = TextEditingController(text: widget.draft.discountAmount);
    _reason = TextEditingController(text: widget.draft.discountReason);
  }

  @override
  void dispose() {
    for (final c in [_name, _qty, _price, _tax, _discount, _reason]) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit() => widget.onChanged(
    widget.draft.copyWith(
      itemName: _name.text,
      quantity: _qty.text,
      unitPrice: _price.text,
      taxPercent: _tax.text,
      discountAmount: _discount.text,
      discountReason: _reason.text,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final narrow = MediaQuery.of(context).size.width < 680;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: Gaps.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Gaps.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Line ${widget.index + 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.draft.lineTotal.toStringAsFixed(2)} SAR',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (widget.canRemove)
                  IconButton(
                    tooltip: 'Remove line',
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: widget.onRemove,
                  ),
              ],
            ),
            Gaps.hSm,
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Item name'),
              onChanged: (_) => _emit(),
            ),
            Gaps.hSm,
            if (narrow) ...[
              TextField(
                controller: _qty,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                onChanged: (_) => _emit(),
              ),
              Gaps.hSm,
              TextField(
                controller: _price,
                decoration: const InputDecoration(
                  labelText: 'Unit price (SAR)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => _emit(),
              ),
              Gaps.hSm,
              TextField(
                controller: _tax,
                decoration: const InputDecoration(labelText: 'VAT %'),
                keyboardType: TextInputType.number,
                onChanged: (_) => _emit(),
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qty,
                      decoration: const InputDecoration(labelText: 'Qty'),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _emit(),
                    ),
                  ),
                  Gaps.wSm,
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _price,
                      decoration: const InputDecoration(
                        labelText: 'Unit price (SAR)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => _emit(),
                    ),
                  ),
                  Gaps.wSm,
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _tax,
                      decoration: const InputDecoration(labelText: 'VAT %'),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _emit(),
                    ),
                  ),
                ],
              ),
            Gaps.hSm,
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _discount,
                    decoration: const InputDecoration(
                      labelText: 'Discount (optional)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => _emit(),
                  ),
                ),
                Gaps.wSm,
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _reason,
                    decoration: const InputDecoration(
                      labelText: 'Discount reason',
                    ),
                    onChanged: (_) => _emit(),
                  ),
                ),
              ],
            ),
            Gaps.hSm,
            DefaultTextStyle(
              style: theme.textTheme.bodySmall!.copyWith(
                color: theme.hintColor,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Subtotal ${widget.draft.lineExtensionAmount.toStringAsFixed(2)}',
                  ),
                  const SizedBox(width: 12),
                  Text('VAT ${widget.draft.lineTax.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
