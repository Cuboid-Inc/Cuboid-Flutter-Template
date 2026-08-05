/// Half-up rounding to 2 decimal places. Blueprint: "Money rounds to two
/// decimal places with half-up rounding."
num roundMoney(num value) {
  final scaled = value * 100;
  const epsilon = 1e-9;
  return (scaled + (scaled.isNegative ? -epsilon : epsilon)).round() / 100;
}

/// VAT amount for a net amount at a percent rate (e.g. 5 for 5%).
num vatAmount(num net, num vatRate) => roundMoney(net * vatRate / 100);
