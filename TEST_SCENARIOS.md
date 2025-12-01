# Test Scenarios - Changes on Moongate

## Test Scenarios for All Fixes

---

## 1. Auto-Fill Company and Branch After Close Shift

### Scenario 1.1: Close Shift and Auto-Fill on Next Login
**Objective**: Verify company and branch are automatically pre-selected after closing a shift.

**Steps**:
1. Log in to the application
2. Select a company and branch
3. Open a shift
4. Close the shift
5. Log out (or app navigates to login)
6. Log in again with the same or different user credentials

**Expected Result**:
- Company dropdown shows the previously selected company as pre-selected
- Branch dropdown shows the previously selected branch as pre-selected
- User can proceed without manually selecting company/branch again
- Works for both online and offline login

---

### Scenario 1.2: Close Shift vs Logout Comparison
**Objective**: Verify that close shift behaves the same as logout for company/branch preservation.

**Steps**:
1. Log in, select company/branch, open shift
2. Close shift
3. Log in again - verify company/branch auto-filled
4. Log out
5. Log in again - verify company/branch still auto-filled

**Expected Result**:
- Both close shift and logout preserve company and branch
- Auto-fill works consistently after both operations

---

## 2. Dropdown Error Prevention

### Scenario 2.1: Company Dropdown No Errors
**Objective**: Verify no Flutter dropdown assertion errors when auto-selecting company.

**Steps**:
1. Log in to the application
2. Select a company and branch
3. Close shift or log out
4. Log in again (online or offline)
5. Observe the choose branch screen

**Expected Result**:
- No Flutter dropdown assertion errors
- Company dropdown displays correctly with pre-selected company
- No duplicate companies in dropdown

**Edge Cases**:
- **Online with server fetch**: Company should re-select after server data loads
- **Offline with cached data**: Company should select from cached data
- **Deleted company**: If preserved company no longer exists, selection should clear gracefully

---

### Scenario 2.2: Branch Dropdown No Errors
**Objective**: Verify no Flutter dropdown assertion errors when auto-selecting branch.

**Steps**:
1. Log in to the application
2. Select a company and branch
3. Close shift or log out
4. Log in again (online or offline)
5. Observe the choose branch screen

**Expected Result**:
- No Flutter dropdown assertion errors
- Branch dropdown displays correctly with pre-selected branch (if company matches)
- No duplicate branches in dropdown

**Edge Cases**:
- **Online with server fetch**: Branch should re-select after server data loads
- **Offline with cached data**: Branch should select from cached data
- **Company change**: When user changes company, branch should clear and reload for new company
- **Deleted branch**: If preserved branch no longer exists, selection should clear gracefully

---

## 3. Multiple User Offline Login

### Scenario 3.1: Multiple Users Can Login Offline
**Objective**: Verify multiple users can log in offline with their saved credentials.

**Steps**:
1. User A logs in online, selects company/branch, opens shift
2. User A logs out
3. User B logs in online, selects company/branch, opens shift
4. User B logs out
5. Go offline
6. User A logs in offline with their credentials
7. User B logs in offline with their credentials

**Expected Result**:
- User A can log in offline with their credentials
- User B can log in offline with their credentials
- Each user sees their own previously selected company/branch
- No "invalid credentials" errors for either user

---

### Scenario 3.2: User Login After Another User Logs Out
**Objective**: Verify correct user context when users log in sequentially.

**Steps**:
1. User A logs in, opens shift, makes a sale
2. User A logs out
3. User B logs in
4. User B opens shift screen

**Expected Result**:
- User B sees their own shift (not User A's shift)
- User B's shift screen shows correct information immediately (not after making a sale)
- Receipts show sales on the correct user's shift

---

## 4. PIN Authorization and Shift Access

### Scenario 4.1: PIN Authorizes User to Their Own Shifts
**Objective**: Verify PIN only authorizes user to access their own shifts.

**Steps**:
1. User A logs in, opens shift
2. User A logs out
3. User B logs in, enters PIN
4. User B tries to access shift screen

**Expected Result**:
- User B only sees their own shifts
- User B cannot access User A's shifts
- PIN validation correctly identifies the current user

---

### Scenario 4.2: Shift Confirm Modal Appears Quickly
**Objective**: Verify shift confirmation modal appears immediately without delay.

**Steps**:
1. User opens a shift on Day 1
2. User logs out
3. User logs in on Day 2
4. User enters PIN

**Expected Result**:
- Shift confirmation modal appears immediately after PIN entry
- No noticeable delay
- Modal shows correct shift information

---

## 5. Shift Ownership Verification

### Scenario 5.1: User Cannot Close Another User's Shift
**Objective**: Verify users cannot close shifts that belong to other users.

**Steps**:
1. User A logs in, opens shift
2. User A logs out
3. User B logs in
4. User B tries to close shift (if somehow User A's shift is visible)

**Expected Result**:
- Error message: "Cannot close shift: This shift belongs to another user"
- Shift remains open
- User B cannot modify User A's shift

---

### Scenario 5.2: Shift Calculations Use Correct User's Shift
**Objective**: Verify shift calculations always use the current user's shift.

**Steps**:
1. User A logs in, opens shift, makes sales
2. User A logs out
3. User B logs in, opens shift screen
4. User B views shift totals

**Expected Result**:
- Shift totals show User B's sales only
- No cross-contamination of sales data between users
- Calculations are accurate for the current user

---

## 6. Unsynced Sales Preservation

### Scenario 6.1: Unsynced Sales Preserved After Close Shift
**Objective**: Verify unsynced sales are preserved when shift is closed.

**Steps**:
1. Go offline
2. Make several sales (they will be unsynced)
3. Close the shift
4. Log out
5. Go online
6. Log in again
7. Check if unsynced sales are still present

**Expected Result**:
- Unsynced sales are preserved after close shift
- Message shows: "Shift closed successfully. X unsynced sale(s) preserved for later syncing"
- Sales can be synced later when online

---

### Scenario 6.2: Unsynced Sales Synced Later Updates Shifts
**Objective**: Verify that when unsynced sales are synced later, associated shifts are updated.

**Steps**:
1. Go offline
2. Make sales (unsynced)
3. Close shift
4. Log out
5. Go online
6. Log in again
7. Wait for background sync or manually refresh
8. Check shift details

**Expected Result**:
- Sales are synced to server
- Associated shift currency amounts are updated with server-generated posReference
- Shift data is correctly updated in local storage

---

## 7. Credit and Account Payment Types

### Scenario 7.1: Credit Payment Types Not Visible When Adding to Account
**Objective**: Verify credit payment types are filtered out when adding to customer account.

**Steps**:
1. Select a loyal customer
2. Enter an amount in "Amount Paid" field
3. Leave cart empty
4. Check payment type dropdown

**Expected Result**:
- Credit payment types (CREDIT-*) are not visible in dropdown
- Only actual payment methods are available
- "Add to Account" button is visible

---

### Scenario 7.2: ACC- Payment Types Not Visible When Adding to Account
**Objective**: Verify ACC- payment types are filtered out when adding to customer account.

**Steps**:
1. Select a loyal customer
2. Enter an amount in "Amount Paid" field
3. Leave cart empty
4. Check payment type dropdown

**Expected Result**:
- ACC- payment types are not visible in dropdown
- Only actual payment methods are available
- "Add to Account" button is visible

---

### Scenario 7.3: Credit Sales Process Correctly
**Objective**: Verify credit sales deduct from customer balance correctly.

**Steps**:
1. Select a loyal customer with account balance
2. Add items to cart
3. Select a CREDIT- payment type
4. Complete the sale

**Expected Result**:
- Sale processes successfully
- Customer account balance is deducted correctly
- Sale is recorded with credit payment type

---

## 8. Calculator Buttons and Quick Amount Entry

### Scenario 8.1: Quick Amount Buttons Work Correctly
**Objective**: Verify quick amount buttons (0.5, 1, 2, 5, 10, 20) work on tablet view.

**Steps**:
1. Open sale screen on tablet
2. Click quick amount button (e.g., "5")
3. Verify amount in "Amount Paid" field
4. Click another button (e.g., "10")
5. Verify cumulative amount

**Expected Result**:
- First button click clears field and sets amount
- Subsequent clicks add to current amount
- Amount is correctly displayed and calculated
- Clear icon appears when amount is entered

---

### Scenario 8.2: Clear Amount Functionality
**Objective**: Verify clear amount functionality works correctly.

**Steps**:
1. Enter amount using quick buttons or manually
2. Click clear icon in amount field
3. Verify field is cleared

**Expected Result**:
- Amount field is cleared
- All amount-related values reset to 0
- Clear icon disappears
- Next button use will clear field again (first use behavior)

---

## 9. Default Currency and Payment Type Selection

### Scenario 9.1: Default Currency Pre-selected
**Objective**: Verify default currency from settings is pre-selected in sale screen.

**Steps**:
1. Set a default currency in settings
2. Open sale screen
3. Check currency dropdown

**Expected Result**:
- Default currency is pre-selected
- Currency is highlighted/visible as selected
- User can change it if needed

---

### Scenario 9.2: Default Payment Type Pre-selected
**Objective**: Verify default payment type is pre-selected and highlighted.

**Steps**:
1. Set a default payment type in settings
2. Open sale screen
3. Check payment type grid/list

**Expected Result**:
- Default payment type is pre-selected
- Payment type is highlighted (pink accent color)
- User can change it if needed

---

## 10. Receipt Screen Enhancements

### Scenario 10.1: Day Dividers Display Correctly
**Objective**: Verify day dividers show different days for receipts.

**Steps**:
1. Make sales on different days
2. Open receipts screen
3. Scroll through receipts

**Expected Result**:
- Day dividers appear between receipts from different days
- Dividers are visually distinct
- Date format is readable

---

### Scenario 10.2: Shift Dividers Display Correctly
**Objective**: Verify shift dividers show shift information correctly.

**Steps**:
1. Make sales across multiple shifts
2. Open receipts screen
3. Scroll through receipts

**Expected Result**:
- Shift dividers appear between receipts from different shifts
- Shift dividers show: Shift reference, Opening time, Closing time (if closed), Status, Cashier name
- All shifts show their opening time (not just the most recent)

---

## 11. Token Refresh and Sync Operations

### Scenario 11.1: Token Refresh After Offline Login
**Objective**: Verify token is automatically refreshed when syncing after offline login.

**Steps**:
1. Log in offline
2. Make sales (unsynced)
3. Go online
4. Wait for background sync or manually refresh

**Expected Result**:
- Sales sync successfully
- No "Unauthorized" errors
- Token is automatically refreshed
- Sync completes without requiring re-login

---

### Scenario 11.2: All Sync Operations Handle Token Refresh
**Objective**: Verify all sync operations (sales, customers, payments, shifts) handle token refresh.

**Steps**:
1. Log in offline
2. Make changes (sales, customer updates, payments)
3. Go online
4. Trigger sync operations

**Expected Result**:
- All sync operations complete successfully
- Token refresh works for all operations
- No manual re-login required

---

## 12. Offline Data Loading

### Scenario 12.1: Cached Data Loads First
**Objective**: Verify cached data loads immediately for offline functionality.

**Steps**:
1. Log in online (data is cached)
2. Go offline
3. Log in again
4. Navigate through app

**Expected Result**:
- Cached companies, branches, currencies, etc. load immediately
- App is functional offline
- No "No Internet connection" errors for cached data

---

### Scenario 12.2: Server Data Updates Cached Data
**Objective**: Verify server data updates cache when online.

**Steps**:
1. Log in online
2. Verify fresh data is fetched from server
3. Check that cached data is updated

**Expected Result**:
- Fresh data is fetched from server
- Cached data is updated
- App uses latest data

---

## 13. Company Change and Branch Loading

### Scenario 13.1: Branch Loading on Company Change
**Objective**: Verify branches load correctly when company is changed.

**Steps**:
1. Select Company A
2. Verify branches for Company A load
3. Change to Company B
4. Verify branches for Company B load

**Expected Result**:
- Cached branches load immediately for offline support
- Fresh branches are fetched from server if online
- Branch list updates correctly
- No errors or duplicates

---

## 14. Error Handling and Edge Cases

### Scenario 14.1: Deleted Company/Branch Handling
**Objective**: Verify graceful handling when preserved company/branch no longer exists.

**Steps**:
1. Log in, select company/branch
2. Close shift
3. Delete company/branch from server (or simulate)
4. Log in again

**Expected Result**:
- Selection clears gracefully if company/branch doesn't exist
- No errors or crashes
- User can select new company/branch

---

### Scenario 14.2: Network Error Handling
**Objective**: Verify app handles network errors gracefully.

**Steps**:
1. Start online login
2. Disconnect network mid-login
3. Verify fallback to offline login

**Expected Result**:
- App falls back to offline login
- Cached data is used
- No crashes or unhandled errors

---

## Summary

These test scenarios cover:
- ✅ Auto-fill company and branch after close shift
- ✅ Dropdown error prevention
- ✅ Multiple user offline login
- ✅ PIN authorization and shift access
- ✅ Shift ownership verification
- ✅ Unsynced sales preservation
- ✅ Credit and account payment type filtering
- ✅ Calculator buttons and quick amount entry
- ✅ Default currency and payment type selection
- ✅ Receipt screen enhancements
- ✅ Token refresh and sync operations
- ✅ Offline data loading
- ✅ Company change and branch loading
- ✅ Error handling and edge cases

