import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/invoice_dao.dart';
import '../../core/database/daos/product_dao.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/product_repository.dart';

/// One line the cashier is putting on (or taking off) the session's tab.
///
/// Deliberately plain fields rather than a whole [ProductWithCategory]: a line
/// the cashier just tapped and a line loaded back from the open tab have to be
/// the same shape, and only the id, name and price survive that trip.
class _OrderLine {
  _OrderLine({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
  });
  final int productId;
  final String name;
  final double unitPrice;
  int quantity;
  double get total => unitPrice * quantity;
}

/// Café-order dialog for a LIVE session: pick products, adjust how many of
/// each, and take anything back the customer changed their mind about.
///
/// The dialog opens on the session's existing open tab (its unpaid drafts) and
/// saves it back as a whole, so "زوّد واحدة" and "شيل واحدة" are the same
/// gesture — the charged invoice is linked to the session (sessionId) so the
/// session panel's "الطلبات" row and the checkout total both pick it up.
Future<void> showSessionOrderModal(
  BuildContext context, {
  required int sessionId,
  int? customerId,
  int? employeeId,
  String deviceTitle = '',
}) {
  return showDialog(
    context: context,
    builder: (_) => SessionOrderModalContent(
      sessionId: sessionId,
      customerId: customerId,
      employeeId: employeeId,
      deviceTitle: deviceTitle,
    ),
  );
}

class SessionOrderModalContent extends ConsumerStatefulWidget {
  const SessionOrderModalContent({
    super.key,
    required this.sessionId,
    this.customerId,
    this.employeeId,
    this.deviceTitle = '',
  });

  final int sessionId;
  final int? customerId;
  final int? employeeId;
  final String deviceTitle;

  @override
  ConsumerState<SessionOrderModalContent> createState() =>
      _SessionOrderModalContentState();
}

class _SessionOrderModalContentState
    extends ConsumerState<SessionOrderModalContent> {
  final Map<int, _OrderLine> _lines = {};
  bool _loaded = false;

  /// Whether the tab already had something on it when we opened — so clearing
  /// it completely is still a save worth making.
  bool _hadExisting = false;
  String? _error;
  bool _saving = false;

  // --- product search + arrow navigation -----------------------------------
  final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocus;
  final ScrollController _gridScroll = ScrollController();
  /// The raw search text; its normalised form is recomputed on each build.
  String _query = '';
  /// Index into the currently visible products — where the arrows land.
  int _cursor = 0;
  /// Whether the arrows have been used since the search last changed, so the
  /// highlight only appears once the cashier is actually navigating.
  bool _cursorActive = false;
  /// Columns in the grid, kept so ArrowDown jumps exactly one row.
  int _columns = 3;
  /// The list the grid is showing right now. It is a field because the key
  /// handlers cannot see the build's locals.
  List<ProductWithCategory> _visible = const [];
  /// A stable key per grid index, so the cursor can be scrolled back into view.
  final Map<int, GlobalKey> _tileKeys = {};

  double get _total => _lines.values.fold<double>(0, (sum, l) => sum + l.total);
  int get _count => _lines.values.fold<int>(0, (sum, l) => sum + l.quantity);

  @override
  void initState() {
    super.initState();
    _searchFocus = FocusNode(onKeyEvent: _onSearchKey);
    _loadExisting();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _gridScroll.dispose();
    super.dispose();
  }

  /// Normalises Arabic (and case) so "شاى" finds "شاي" and a trailing ة/ه
  /// difference does not hide a product.
  static String _norm(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ئ', 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ة', 'ه')
      .replaceAll(RegExp(r'[\u064B-\u0652\u0640]'), '')
      .trim();

  /// Keeps the caret in the search field but lets the arrows drive the grid —
  /// the point of the box is to reach a product without leaving the keyboard.
  KeyEventResult _onSearchKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveCursor(_columns);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveCursor(-_columns);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _moveCursor(int delta) {
    if (_visible.isEmpty) return;
    setState(() {
      _cursorActive = true;
      _cursor = (_cursor + delta).clamp(0, _visible.length - 1);
    });
    _scrollToCursor();
  }

  /// Adds the product the cursor is on — or the first match when the arrows
  /// have not been used yet.
  void _addCursor() {
    if (_visible.isEmpty) return;
    final item = _visible[_cursor.clamp(0, _visible.length - 1)];
    final p = item.product;
    final canAdd = p.active && (_lines[p.id]?.quantity ?? 0) < p.stockQuantity;
    if (!canAdd) return;
    _cursorActive = true;
    _add(item); // _add() setStates.
  }

  Future<void> _scrollToCursor() async {
    // Let the cursor move land in the tree before asking it to scroll.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final ctx = _tileKeys[_cursor]?.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 120),
      alignment: 0.5,
    );
  }

  Future<void> _loadExisting() async {
    try {
      final existing = await ref
          .read(sessionDraftLinesProvider(widget.sessionId).future);
      if (!mounted) return;
      for (final line in existing) {
        final pid = line.productId;
        if (pid == null) continue;
        final current = _lines[pid];
        if (current == null) {
          _lines[pid] = _OrderLine(
            productId: pid,
            name: line.description,
            unitPrice: line.unitPrice,
            quantity: line.quantity,
          );
        } else {
          current.quantity += line.quantity;
        }
      }
      setState(() {
        _hadExisting = _lines.isNotEmpty;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  void _add(ProductWithCategory product) {
    final p = product.product;
    _lines.update(
      p.id,
      (line) {
        line.quantity++;
        return line;
      },
      ifAbsent: () => _OrderLine(
        productId: p.id,
        name: p.name,
        unitPrice: p.sellingPrice,
        quantity: 1,
      ),
    );
    setState(() {});
  }

  void _removeOne(int productId) {
    final line = _lines[productId];
    if (line == null) return;
    setState(() {
      if (line.quantity <= 1) {
        _lines.remove(productId);
      } else {
        line.quantity--;
      }
    });
  }

  void _removeLine(int productId) => setState(() => _lines.remove(productId));

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // The whole tab is rewritten, so a reduction is just a shorter list.
      // Nothing here has been paid for yet — see InvoiceDao.syncSessionDraft.
      await ref.read(invoiceRepositoryProvider).syncSessionDraft(
            sessionId: widget.sessionId,
            customerId: widget.customerId,
            employeeId: widget.employeeId,
            lines: [
              for (final line in _lines.values)
                InvoiceLineInput(
                  productId: line.productId,
                  description: line.name,
                  quantity: line.quantity,
                  unitPrice: line.unitPrice,
                ),
            ],
          );
      ref.invalidate(sessionDraftLinesProvider(widget.sessionId));
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث طلبات الجلسة')));
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsWithCategoryProvider);
    final size = MediaQuery.of(context).size;
    final width = size.width < 900 ? size.width - 40 : 860.0;
    final height = size.height < 700 ? size.height - 40 : 620.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: AppRadius.largeR,
          border: Border.all(color: AppColors.glassBorderPurple),
          boxShadow: AppShadows.glow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: !_loaded
                  ? const Center(child: CircularProgressIndicator())
                  : productsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(
                          child: Text('خطأ: $e',
                              style:
                                  const TextStyle(color: AppColors.danger))),
                      data: (products) => _body(products),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('طلبات الجلسة', style: AppTypography.sectionTitle),
            if (widget.deviceTitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(widget.deviceTitle, style: AppTypography.secondary),
            ],
          ],
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close_rounded,
              size: 20, color: AppColors.textTertiary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }

  Widget _body(List<ProductWithCategory> products) {
    final byId = <int, ProductRow>{
      for (final p in products) p.product.id: p.product,
    };
    // Keep anything already on the tab visible even if it has since run out or
    // been switched off, or the cashier would have no way to take it back.
    final available = products
        .where((p) =>
            _lines.containsKey(p.product.id) ||
            (p.product.active && p.product.stockQuantity > 0))
        .toList();

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _moveCursor(_columns),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _moveCursor(-_columns),
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _productsPane(available)),
          const SizedBox(width: AppSpacing.md),
          SizedBox(width: 296, child: _cartPane(byId)),
        ],
      ),
    );
  }

  Widget _productsPane(List<ProductWithCategory> available) {
    final q = _norm(_query);
    final visible = q.isEmpty
        ? available
        : [
            for (final item in available)
              if (_norm(item.product.name).contains(q) ||
                  _norm(item.category.name).contains(q))
                item,
          ];
    _visible = visible;
    if (_cursor >= visible.length) {
      _cursor = visible.isEmpty ? 0 : visible.length - 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _searchField(),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    q.isEmpty
                        ? 'لا توجد منتجات متاحة للطلب'
                        : 'مفيش منتج بالاسم ده',
                    style: const TextStyle(color: AppColors.textTertiary),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    _columns = constraints.maxWidth > 520 ? 3 : 2;
                    return GridView.builder(
                      controller: _gridScroll,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _columns,
                        mainAxisSpacing: AppSpacing.sm,
                        crossAxisSpacing: AppSpacing.sm,
                        childAspectRatio: 1.35,
                      ),
                      itemCount: visible.length,
                      itemBuilder: (_, i) => _productCard(
                        visible[i],
                        isCursor: _cursorActive && i == _cursor,
                        key: _tileKeys.putIfAbsent(i, () => GlobalKey()),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocus,
      autofocus: true,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      onChanged: (value) => setState(() {
        _query = value;
        _cursor = 0;
        _cursorActive = false;
      }),
      onSubmitted: (_) => _addCursor(),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'ابحث باسم المنتج أو التصنيف…',
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded,
            size: 18, color: AppColors.textTertiary),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                tooltip: 'امسح البحث',
                icon: const Icon(Icons.close_rounded,
                    size: 16, color: AppColors.textTertiary),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _query = '';
                    _cursor = 0;
                    _cursorActive = false;
                  });
                },
              ),
        filled: true,
        fillColor: AppColors.bgBase.withOpacity(0.45),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: AppRadius.smallR,
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallR,
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallR,
          borderSide: const BorderSide(color: AppColors.accentPrimary),
        ),
      ),
    );
  }

  Widget _productCard(ProductWithCategory item,
      {required bool isCursor, Key? key}) {
    final p = item.product;
    final qty = _lines[p.id]?.quantity ?? 0;
    final canAdd = p.active && qty < p.stockQuantity;
    final selected = qty > 0;

    return GestureDetector(
      key: key,
      onTap: canAdd ? () => _add(item) : null,
      child: MouseRegion(
        cursor: canAdd ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentPrimary.withOpacity(0.14)
                : AppColors.glassFill,
            borderRadius: AppRadius.mediumR,
            border: Border.all(
              color: isCursor
                  ? AppColors.accentSecondary
                  : selected
                      ? AppColors.accentPrimary.withOpacity(0.5)
                      : AppColors.glassBorder,
              width: isCursor ? 2 : 1,
            ),
            boxShadow: isCursor ? AppShadows.card : null,
          ),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      p.name,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'EGP ${p.sellingPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _QtyStepper(
                quantity: qty,
                onAdd: canAdd ? () => _add(item) : null,
                onRemove: qty > 0 ? () => _removeOne(p.id) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cartPane(Map<int, ProductRow> byId) {
    final lines = _lines.values.toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.bgBase.withOpacity(0.35),
        borderRadius: AppRadius.mediumR,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('الكارت', style: AppTypography.cardTitle),
              const Spacer(),
              Text('$_count طلب',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: lines.isEmpty
                ? const Center(
                    child: Text(
                      'مفيش طلبات على الكارت\nدوس على أي منتج تزوّده',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textTertiary),
                    ),
                  )
                : ListView.separated(
                    itemCount: lines.length,
                    separatorBuilder: (_, __) => const Divider(
                        color: AppColors.glassBorder, height: AppSpacing.sm),
                    itemBuilder: (_, i) => _cartRow(lines[i], byId),
                  ),
          ),
          const Divider(height: AppSpacing.md, color: AppColors.glassBorder),
          Row(
            children: [
              const Text('الإجمالي',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const Spacer(),
              Text('EGP ${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.statusAvailable)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cartRow(_OrderLine line, Map<int, ProductRow> byId) {
    final product = byId[line.productId];
    final stock = product?.stockQuantity;
    final canAdd =
        (product?.active ?? false) && stock != null && line.quantity < stock;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text('EGP ${line.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _QtyStepper(
          quantity: line.quantity,
          onAdd: canAdd ? () => setState(() => line.quantity++) : null,
          onRemove: () => _removeOne(line.productId),
        ),
        IconButton(
          tooltip: 'شيل من الطلب',
          icon: const Icon(Icons.delete_outline_rounded,
              size: 18, color: AppColors.danger),
          onPressed: () => _removeLine(line.productId),
        ),
      ],
    );
  }

  Widget _footer() {
    final canSave =
        _loaded && !_saving && (_lines.isNotEmpty || _hadExisting);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('$_count طلب', style: AppTypography.secondary),
            const Spacer(),
            SecondaryButton(
              label: 'إغلاق',
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: AppSpacing.sm),
            PrimaryButton(
              label: _saving ? '...' : 'حفظ الطلب',
              icon: Icons.check_circle_rounded,
              onPressed: canSave ? _save : null,
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13)),
        ],
      ],
    );
  }
}

/// A compact −/qty/+ control used both in the product grid and on the tab.
class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.quantity, this.onAdd, this.onRemove});

  final int quantity;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgBase.withOpacity(0.45),
        borderRadius: AppRadius.smallR,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(Icons.remove_rounded, onRemove),
          SizedBox(
            width: 26,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: quantity > 0
                    ? AppColors.accentSecondary
                    : AppColors.textTertiary,
              ),
            ),
          ),
          _button(Icons.add_rounded, onAdd),
        ],
      ),
    );
  }

  Widget _button(IconData icon, VoidCallback? onTap) {
    return MouseRegion(
      cursor:
          onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Icon(icon,
              size: 17,
              color: onTap == null
                  ? AppColors.textTertiary.withOpacity(0.45)
                  : AppColors.textPrimary),
        ),
      ),
    );
  }
}
