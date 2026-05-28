kerjakan prompt dibawah ini

Build a complete Flutter savings app using Dart with Neo Brutalism design style. The app must be fully functional with real data, real-time clock, and complete CRUD operations. No placeholder logic, no TODO comments.

=== DESIGN SYSTEM: NEO BRUTALISM ===
- All containers: solid 2.5px black border (#111111), hard box-shadow offset 4px 4px 0px #111111
- Buttons: bold black border, shadow offset 3px 3px 0px #111, translate on press (active: offset 1px 1px)
- Background: #FFFDE7 (warm cream) as scaffold background
- Accent colors: #FFE500 (yellow), #FF5733 (red-orange), #00C49A (green), #4361EE (blue)
- Typography: GoogleFonts.spaceGrotesk — bold headers (weight 800), medium body (weight 500)
- Cards: white fill + 2px black border + 4px 4px 0px black shadow, border-radius: 0 (sharp corners only)
- Progress bars: 14px height, black border 2px, filled with accent color, no rounded ends
- Chips/tags: black border, no border-radius, bold text
- No Material shadows, no elevation, no gradient, no rounded corners anywhere
- Dialogs: also neo brutalism — black border 2.5px, shadow 5px 5px 0px black, no rounded corners, cream background
- Snackbars: black background, colored bold text, black border, no rounded corners

=== DEPENDENCIES (pubspec.yaml) ===
- google_fonts: ^6.2.1
- fl_chart: ^0.69.0
- intl: ^0.19.0
- shared_preferences: ^2.3.2
- uuid: ^4.4.0
- provider: ^6.1.2

=== APP ARCHITECTURE ===
Use Provider for state management. Create these files:
1. main.dart
2. models/saving_goal.dart
3. models/transaction.dart
4. models/milestone.dart
5. providers/savings_provider.dart
6. screens/home_screen.dart
7. screens/add_edit_goal_screen.dart     ← handles both Add AND Edit
8. screens/goal_detail_screen.dart
9. screens/add_edit_transaction_screen.dart  ← handles both Add AND Edit
10. widgets/realtime_clock_widget.dart
11. widgets/neo_button.dart
12. widgets/neo_card.dart
13. widgets/neo_dialog.dart
14. widgets/progress_bar_widget.dart
15. widgets/roadmap_widget.dart

=== MODELS ===

SavingGoal:
- String id (uuid)
- String title
- String emoji
- double targetAmount
- double currentAmount (computed from transactions sum)
- DateTime startDate
- DateTime targetDate
- String category (vacation/gadget/emergency/education/vehicle/property/other)
- List milestones (auto-generated at 25/50/75/100%)
- List transactions
- bool isCompleted
- String? notes

Transaction:
- String id
- double amount
- DateTime date
- String note
- TransactionType type (deposit / withdrawal)

Milestone:
- String id
- String label
- double percentage
- double targetAmount
- bool isReached
- DateTime? reachedAt

=== FULL CRUD IMPLEMENTATION ===

--- CREATE ---

1. ADD GOAL (AddEditGoalScreen in "add" mode)
- Form fields: title, emoji picker, category chips, targetAmount, startDate, targetDate, notes
- On save: generate UUID, auto-generate 4 milestones, add to provider list, persist to SharedPreferences
- Validation: all required fields filled, targetDate > startDate, targetAmount > 0

2. ADD TRANSACTION (AddEditTransactionScreen in "add" mode)
- Toggle: Deposit / Withdrawal (neo brutalism styled toggle)
- Fields: amount (with thousand separator formatter), date picker, note
- Quick amount chips: +100rb, +500rb, +1jt, +5jt
- On save: generate UUID, append to goal's transaction list, recalculate currentAmount, check & update milestone isReached status, persist
- Validation: amount > 0, withdrawal amount <= currentAmount (show NeoSnackbar error if exceeded)

--- READ ---

3. HOME SCREEN
- AppBar: app name left, realtime clock right (HH:mm:ss updates every second)
- Below AppBar: full date in Indonesian ("Kamis, 28 Mei 2026")
- Summary NeoCard row: total goals count, total saved (sum all currentAmount), total remaining (sum all targetAmount - currentAmount)
- Goal cards list: each shows emoji, title, progress bar, percentage, days remaining, quick deposit FAB
- Empty state: bold "Belum ada tabungan" message with + button
- FAB: "Tambah Goal" button

4. GOAL DETAIL SCREEN (tabs or scrollable sections)
- Section A — Overview: circular progress, amount saved vs target, percentage, days remaining, completion projection, category badge
- Section B — Roadmap: vertical milestone timeline with predicted dates
- Section C — Transactions: full list with date, amount (color-coded), note, running balance
- Section D — Chart: bar chart monthly + line chart cumulative vs target trajectory

--- UPDATE ---

5. EDIT GOAL (AddEditGoalScreen in "edit" mode)
- Reuse the same AddEditGoalScreen widget
- Accept optional SavingGoal? existingGoal parameter
- If existingGoal != null → pre-fill all fields with existing data, title shows "Edit Goal"
- On save: update existing goal in provider by id (do NOT create new), recalculate milestones based on new targetAmount, keep existing transactions intact
- Access: GoalDetailScreen AppBar has an edit IconButton (ti-pencil icon) → pushes AddEditGoalScreen(existingGoal: goal)
- Also accessible via long-press on goal card in HomeScreen → shows bottom sheet with Edit / Delete options

6. EDIT TRANSACTION (AddEditTransactionScreen in "edit" mode)
- Reuse same AddEditTransactionScreen widget
- Accept optional Transaction? existingTransaction parameter
- If existingTransaction != null → pre-fill fields, title shows "Edit Transaksi"
- On save: replace transaction in goal's list by id, recalculate currentAmount, update milestone statuses
- Access: tap on transaction item in GoalDetailScreen → shows bottom sheet with Edit / Delete options

--- DELETE ---

7. DELETE GOAL
- Trigger: long-press goal card → NeoBottomSheet with "Edit" and "Hapus Goal" options
- Also: AppBar menu in GoalDetailScreen → "Hapus Goal"
- Show NeoConfirmDialog before deleting:
  Title: "Hapus Goal?"
  Body: "Semua data tabungan '[title]' akan dihapus permanen."
  Buttons: "Batal" (secondary) and "Ya, Hapus" (red #FF5733 background)
- On confirm: remove from provider list, persist, Navigator.pop back to HomeScreen
- NeoConfirmDialog style: Dialog widget with shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero), black border 2.5px, shadow 5px 5px 0 black, cream background

8. DELETE TRANSACTION
- Trigger: swipe-to-dismiss on transaction list item (Dismissible widget, direction: endToStart)
- Background when swiping: red #FF5733 container with white trash icon (ti-trash), aligned right
- On dismiss: remove transaction from goal, recalculate currentAmount, recheck milestone statuses, persist
- Immediately show NeoSnackbar: black background, white text "Transaksi dihapus", yellow "Undo" button
- If Undo tapped: re-insert transaction at original index, recalculate, persist
- Also accessible via tap on transaction → bottom sheet with "Edit" and "Hapus" options

=== PROVIDER METHODS (savings_provider.dart) ===

CRUD methods:
- void addGoal(SavingGoal goal)
- void updateGoal(SavingGoal updatedGoal)   ← find by id, replace
- void deleteGoal(String goalId)
- void addTransaction(String goalId, Transaction tx)
- void updateTransaction(String goalId, Transaction updatedTx)  ← find by id, replace
- void deleteTransaction(String goalId, String txId)
- void undoDeleteTransaction(String goalId, Transaction tx, int originalIndex)

Calculation methods:
- double getCurrentAmount(SavingGoal goal) → sum all deposit - sum all withdrawal
- double getCompletionPercentage(SavingGoal goal) → clamp(0,100)
- int getDaysRemaining(SavingGoal goal) → targetDate.difference(DateTime.now()).inDays
- double getDailyTarget(SavingGoal goal) → targetAmount / max totalDays
- double getWeeklyTarget(SavingGoal goal) → targetAmount / totalWeeks
- double getMonthlyTarget(SavingGoal goal) → targetAmount / totalMonths
- double getAverageDailyDeposit(SavingGoal goal) → total deposits / days since startDate
- DateTime? getProjectedCompletion(SavingGoal goal) → based on average daily deposit rate
- List recalculateMilestones(SavingGoal goal) → regenerate 4 milestones, preserve isReached and reachedAt for already-reached ones
- void checkAndUpdateMilestones(SavingGoal goal) → after any transaction, check each milestone and set isReached=true + reachedAt=now if currentAmount >= milestone.targetAmount
- String getMotivationalMessage(SavingGoal goal) → based on % progress (Indonesian text)

Persistence:
- Future saveToPrefs() → serialize all goals to JSON, save under key 'savings_goals'
- Future loadFromPrefs() → deserialize on app start
- Implement toJson/fromJson on all models

=== REAL-TIME CLOCK WIDGET ===
- StatefulWidget with Timer.periodic(Duration(seconds:1)) in initState
- Calls setState every second to update _now = DateTime.now()
- Display: HH:mm:ss in large monospace bold (SpaceGrotesk 28px weight 800)
- Display: "Kamis, 28 Mei 2026" using DateFormat('EEEE, d MMMM yyyy', 'id_ID')
- Wrap in NeoCard with #FFE500 background
- Dispose timer in dispose() — mandatory

=== SAVINGS CALCULATOR WIDGET ===
Shown inside GoalDetailScreen and AddEditGoalScreen preview section.
Display in a NeoCard with colored rows:
- Row 1: "Durasi Total" → X hari / Y minggu / Z bulan
- Row 2: "Perlu nabung/hari" → Rp xxx.xxx
- Row 3: "Perlu nabung/minggu" → Rp x.xxx.xxx
- Row 4: "Perlu nabung/bulan" → Rp x.xxx.xxx
- Row 5: "Sisa waktu" → X hari lagi (red if < 30 days)
- Row 6: "Estimasi selesai" → tanggal proyeksi (based on avg daily deposit)

=== NEO BRUTALISM WIDGETS ===

NeoCard:
  Container with color, border: Border.all(color: Colors.black, width: 2.5),
  boxShadow: [BoxShadow(color: Colors.black, offset: Offset(4,4), blurRadius: 0)],
  padding, child. No border-radius.

NeoButton (StatefulWidget):
  GestureDetector tracking _isPressed
  AnimatedContainer: transform = _isPressed ? translate(2,2) : translate(0,0)
  boxShadow offset = _isPressed ? Offset(1,1) : Offset(3,3)
  Color, text, icon all configurable

NeoDialog (static method showNeoDialog):
  showDialog with barrierColor black54
  Dialog widget: shape BorderRadius.zero, backgroundColor cream
  Wrap content in Container with black border 2.5px + shadow 5px 5px 0 black
  Two buttons: secondary (outline) + primary (colored fill)

NeoSnackbar (static method showNeoSnackbar):
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.black,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      content: Text(message, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      action: SnackBarAction(label: actionLabel, textColor: Color(0xFFFFE500), onPressed: onAction)
    )
  )

NeoBottomSheet (static method showNeoBottomSheet):
  showModalBottomSheet with backgroundColor cream, shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero)
  Top: black drag handle bar
  List of NeoButton options (Edit = blue, Delete = red #FF5733)

ProgressBarWidget:
  Stack: outer Container (border 2px black, height 14px), inner AnimatedContainer (width = percentage * totalWidth, color = accent)

RoadmapWidget:
  Column of milestone rows. Each row: Row with indicator circle + vertical line + content
  Indicator: Container 40x40, border 2.5px black, shadow 3px 3px 0 black
  Reached: yellow background + Icons.check (bold), Pending: white background + number text
  Predicted date shown below each milestone label

=== INDONESIAN LOCALIZATION ===
- All UI text in Bahasa Indonesia
- Currency: NumberFormat.currency(locale:'id_ID', symbol:'Rp ', decimalDigits:0)
- Dates: DateFormat('EEEE, d MMMM yyyy', 'id_ID')
- Add in main.dart: supportedLocales: [Locale('id','ID')], localizationsDelegates: GlobalMaterialLocalizations.delegate etc.
- Category labels: Liburan, Gadget, Dana Darurat, Pendidikan, Kendaraan, Properti, Lainnya
- Status messages: "Baru mulai, semangat! 💪", "Seperempat jalan, luar biasa! 🎯", "Setengahnya sudah! Terus pantang menyerah! 🔥", "Hampir sampai! Jangan berhenti sekarang! ⚡", "GOAL TERCAPAI! Selamat! 🎉"

=== SAMPLE DATA (first launch only) ===
Goal 1: title="iPhone 16 Pro", emoji="📱", category=gadget, targetAmount=20000000,
  startDate=3 months ago, targetDate=6 months from now
  Transactions: 5 deposits (500rb, 1jt, 750rb, 1.5jt, 2jt) spread over past 3 months

Goal 2: title="Liburan Bali", emoji="🏖️", category=vacation, targetAmount=8000000,
  startDate=1 month ago, targetDate=4 months from now
  Transactions: 3 deposits (500rb, 1jt, 300rb) spread over past month

=== NAVIGATION FLOW ===
HomeScreen
  ├─ FAB → AddEditGoalScreen(existingGoal: null)
  ├─ Tap goal card → GoalDetailScreen
  └─ Long-press goal card → NeoBottomSheet → Edit / Delete

GoalDetailScreen
  ├─ AppBar edit icon → AddEditGoalScreen(existingGoal: goal)
  ├─ AppBar menu → Delete Goal (NeoConfirmDialog)
  └─ FAB → AddEditTransactionScreen(goalId, existingTransaction: null)

Transaction item
  ├─ Tap → NeoBottomSheet → Edit / Delete
  ├─ Tap Edit → AddEditTransactionScreen(goalId, existingTransaction: tx)
  └─ Swipe dismiss → Delete + Undo Snackbar

=== FINAL CHECKLIST ===
✓ All 4 CRUD operations implemented for both Goal and Transaction
✓ All screens connected via Navigator
✓ Realtime clock with proper Timer init and dispose
✓ Calculations accurate (no division by zero guards)
✓ SharedPreferences persistence on every state change
✓ Neo Brutalism design consistent across all screens and dialogs
✓ Indonesian locale for all dates and currency
✓ Sample data on first launch
✓ Undo delete for transactions
✓ Milestone auto-recalculation on goal edit and on every transaction
✓ Projected completion date based on actual deposit history
✓ App runs on Flutter 3.22+ Dart 3.4+, no errors

Generate all files completely. Output order: pubspec.yaml → main.dart → models → provider → screens → widgets.