/// Pure loyalty-program math — no I/O, no drift imports. Both the
/// [LoyaltyRepository] (UI-facing previews) and InvoiceDao's transaction
/// (the canonical earn/spend) go through this so the two can never
/// disagree on what a point is worth.
class LoyaltyMath {
  const LoyaltyMath._();

  /// Points earned for [amount] EGP at [pointsPerCurrency] points/EGP.
  /// Always floors — a fraction of a point isn't counted until reached.
  static int pointsEarnedFor(double amount, double pointsPerCurrency) =>
      pointsPerCurrency <= 0 ? 0 : (amount / pointsPerCurrency).floor();

  /// How much [points] is worth in EGP at [pointValueEGP] per point.
  static double redemptionValue(int points, double pointValueEGP) =>
      points * pointValueEGP;

  /// A redemption is allowed when the customer has enough points AND the
  /// value actually covers part of the bill (never redeem more than what
  /// is owed).
  static bool canRedeem(
    int points,
    int minimumRedeemPoints,
    double value,
    double total,
  ) =>
      points >= minimumRedeemPoints && value > 0 && value <= total;
}