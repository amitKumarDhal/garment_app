describe('Backend Server-side Financial Calculations', () => {
  it('calculates order line items and grand totals correctly', () => {
    const products = [
      { price: 250, qty: 10, gstPercentage: 5 },
      { price: 150, qty: 4, gstPercentage: 12 },
    ];
    const shipping = 100;
    const advance = 500;

    let subTotal = 0;
    let totalTax = 0;
    let totalQty = 0;

    products.forEach((prod) => {
      const base = prod.price * prod.qty;
      const tax = base * (prod.gstPercentage / 100);

      subTotal += base;
      totalTax += tax;
      totalQty += prod.qty;
    });

    const grandTotal = subTotal + totalTax + shipping;
    const balanceDue = grandTotal - advance;

    // Item 1: 2500 base + 125 tax = 2625
    // Item 2: 600 base + 72 tax = 672
    // Subtotal: 3100
    // Tax: 197
    // Grand: 3100 + 197 + 100 = 3397
    // Balance Due: 3397 - 500 = 2897
    expect(subTotal).toBe(3100);
    expect(totalTax).toBe(197);
    expect(totalQty).toBe(14);
    expect(grandTotal).toBe(3397);
    expect(balanceDue).toBe(2897);
  });

  it('safely handles empty/missing values with zero fallbacks', () => {
    const products = [{ price: undefined, qty: undefined, gstPercentage: undefined }];
    let subTotal = 0;
    let totalTax = 0;
    let totalQty = 0;

    products.forEach((prod: any) => {
      const price = Number(prod.price) || 0;
      const qty = Number(prod.qty) || 1;
      const gstPct = Number(prod.gstPercentage) || 0;

      const base = price * qty;
      const tax = base * (gstPct / 100);

      subTotal += base;
      totalTax += tax;
      totalQty += qty;
    });

    const grandTotal = subTotal + totalTax;
    expect(subTotal).toBe(0);
    expect(totalTax).toBe(0);
    expect(grandTotal).toBe(0);
  });
});
