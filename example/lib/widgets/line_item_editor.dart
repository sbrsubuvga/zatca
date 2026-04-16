import 'package:flutter/material.dart';

import '../bloc/invoice/invoice_state.dart';

/// A compact card that lets the user edit a single invoice line
/// — quantity, unit code, price, tax %, and optional discount.
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
    _name.dispose();
    _qty.dispose();
    _price.dispose();
    _tax.dispose();
    _discount.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      widget.draft.copyWith(
        itemName: _name.text,
        quantity: _qty.text,
        unitPrice: _price.text,
        taxPercent: _tax.text,
        discountAmount: _discount.text,
        discountReason: _reason.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Line ${widget.index + 1}',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
                const Spacer(),
                if (widget.canRemove)
                  IconButton(
                    tooltip: 'Remove line',
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: widget.onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Item name',
                isDense: true,
              ),
              onChanged: (_) => _emit(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qty,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emit(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _price,
                    decoration: const InputDecoration(
                      labelText: 'Unit price (SAR)',
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => _emit(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _tax,
                    decoration: const InputDecoration(
                      labelText: 'VAT %',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emit(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _discount,
                    decoration: const InputDecoration(
                      labelText: 'Discount (SAR, optional)',
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => _emit(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _reason,
                    decoration: const InputDecoration(
                      labelText: 'Discount reason',
                      isDense: true,
                    ),
                    onChanged: (_) => _emit(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Subtotal: ${widget.draft.lineExtensionAmount.toStringAsFixed(2)}  •  '
                'VAT: ${widget.draft.lineTax.toStringAsFixed(2)}  •  '
                'Total: ${widget.draft.lineTotal.toStringAsFixed(2)}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
