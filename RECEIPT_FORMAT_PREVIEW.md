# New Receipt Format Preview

## Structure Overview

### 1. Header Section
```
[LOGO - Centered]

Company Name and Branch
Company TIN: [TIN Number]
Company VAT: [VAT Number]
Company Address: [Address]
Email: [Email]
Phone: [Phone Number]
```

### 2. Title Section (Conditional)
```
If NOT fiscalized:
  RECEIPT

If fiscalized:
  FISCAL TAX INVOICE
```

### 3. Items Section
```
------------------------------------------------
DescriptionAmount
------------------------------------------------
Carrot Cake4.00
Americano Large Cup4.00
------------------------------------------------
Total USD8.00
USD Other8.00
------------------------------------------------
Number of items2
------------------------------------------------
------------------------------------------------
Net Amount6.96
VAT (15%)1.04
Gross Amount8.00
```

### 4. Payment & Footer Section
```
Change: [Amount]

Thank you for your purchase!
```

---

## Complete Receipt Example

```
        [LOGO]
        
Vimbika Coffee Shop - Main Branch
Company TIN: 123456789
Company VAT: VAT123456
Company Address: 123 Main Street, Harare
Email: info@vimbika.co.zw
Phone: +263 77 123 4567

        RECEIPT
        (or FISCAL TAX INVOICE if fiscalized)

------------------------------------------------
DescriptionAmount
------------------------------------------------
Carrot Cake4.00
Americano Large Cup4.00
------------------------------------------------
Total USD8.00
USD Other8.00
------------------------------------------------
Number of items2
------------------------------------------------
------------------------------------------------
Net Amount6.96
VAT (15%)1.04
Gross Amount8.00

Change: 2.00

Thank you for your purchase!
```

---

## Notes

1. **Logo**: Centered at the top
2. **Company Info**: All company details displayed in header
3. **Title**: "RECEIPT" if not fiscalized, "FISCAL TAX INVOICE" if fiscalized
4. **Items Format**: Description on left, Amount on right (aligned)
5. **Totals**: Shows payment types, then number of items
6. **Tax Breakdown**: Net Amount, VAT (with percentage), Gross Amount
7. **Footer**: Change amount and thank you message

---

## Implementation Details

- Company information will be retrieved from storage (ACTIVE_COMPANY)
- Branch information from sale.branch
- VAT number from fiscal device storage
- Fiscal status from sale.fiscalized
- Items formatted with description and amount aligned
- Payment types shown as "Total [Currency] [Amount]" for each payment type

