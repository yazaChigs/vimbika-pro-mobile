# Receipt Format Update Plan

## Current Structure Issues

### Current Payment Types Display:
```
Total USD                                  8.00
USD Other
```

**Problem:** Payment type name line doesn't show the amount.

### Current Summary Section:
```
------------------------------------------------
------------------------------------------------
Net Amount                                 6.96
VAT (15%)                                  1.04
Gross Amount                               8.00
```

**Problem:** Missing "Amount Paid" above "Net Amount".

---

## New Structure Plan

### 1. Payment Types Section (Updated)
```
------------------------------------------------
Total USD                                  8.00
USD Other                                  8.00
------------------------------------------------
```

**Changes:**
- Payment type name line should also display the amount
- Format: `[Currency] [PaymentName]`.padRight(40) + amount
- Example: `USD Other`.padRight(40) + "8.00"

### 2. Summary Section (Updated)
```
------------------------------------------------
------------------------------------------------
Amount Paid                                8.00
Net Amount                                 6.96
VAT (15%)                                  1.04
Gross Amount                               8.00
```

**Changes:**
- Add "Amount Paid" line above "Net Amount"
- Use `sale.amountPaid` for the amount
- Format: `Amount Paid`.padRight(40) + (currency symbol) + amount
- Maintain proper spacing alignment (40 chars padding)

---

## Complete Updated Receipt Format

```
[LOGO - Centered]

Company Name and Branch
TIN: [TIN Number]
VAT No: [VAT Number]
[Address]
[Email]
[Phone Number]

RECEIPT
(or FISCAL TAX INVOICE if fiscalized)

------------------------------------------------
Description                              Amount
------------------------------------------------
Carrot Cake                                4.00
Americano Large Cup                        4.00
------------------------------------------------
Total USD                                  8.00
USD Other                                  8.00
------------------------------------------------
Number of items                               2
------------------------------------------------
------------------------------------------------
Amount Paid                                8.00
Change:                                    0.00
Net Amount                                 6.96
VAT (15%)                                  1.04
Gross Amount                               8.00


Thank you for your purchase!
```

---

## Implementation Changes Required

### For All Three Printer Types (USB, Bluetooth, Sunmi):

1. **Payment Types Section** (Lines ~443-463, ~963-976, ~1570-1579):
   - **Current:** Payment name line shows: `'$currencySymbol $paymentName'.padRight(40)`
   - **New:** Payment name line shows: `'$currencySymbol $paymentName'.padRight(40) + amount.toStringAsFixed(2)`

2. **Summary Section** (Lines ~497-1014, ~994-1014, ~1596-1614):
   - **Add before Net Amount:**
     - Line: `'Amount Paid'.padRight(40) + (cur?.symbol ?? '') + ' ' + sale.amountPaid.toStringAsFixed(2)`
   - **Order:**
     1. Amount Paid
     2. Net Amount
     3. VAT (if applicable)
     4. Gross Amount
     5. Change

---

## Files to Modify

1. `lib/src/services/printer_service.dart`
   - `generateBluetoothReceipt()` - Lines ~443-463 (Payment Types), ~497-520 (Summary)
   - `generateUSBReceipt()` - Lines ~963-976 (Payment Types), ~994-1018 (Summary)
   - `printSunmiSaleReceipt()` - Lines ~1570-1579 (Payment Types), ~1596-1617 (Summary)

---

## Testing Checklist

- [ ] Payment type name displays amount correctly
- [ ] Amount Paid appears above Net Amount
- [ ] All amounts are right-aligned (using padRight(40))
- [ ] Spacing is consistent across all three printer types
- [ ] Currency symbol is included in Amount Paid line
- [ ] Format matches the preview exactly

