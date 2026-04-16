import '../models/invoice_line.dart';

extension DiscountListExtensions on List<Discount> {
  /// Returns the total amount of all discounts in the list.
  double get totalAmount {
    return fold(0.0, (sum, discount) => sum + discount.amount);
  }
}
