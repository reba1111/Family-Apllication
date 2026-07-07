import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class ShoppingListScreen extends StatefulWidget {
  final String coupleId;
  final UserModel me;

  const ShoppingListScreen({Key? key, required this.coupleId, required this.me}) : super(key: key);

  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final FirestoreService _fs = FirestoreService();
  final TextEditingController _itemController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  void _addItem() async {
    final name = _itemController.text.trim();
    if (name.isEmpty) return;

    final item = ShoppingItemModel(
      id: '',
      name: name,
      isBought: false,
      addedBy: currentUserId,
      createdAt: DateTime.now(),
    );

    _itemController.clear();
    await _fs.addShoppingItem(widget.coupleId, item);
  }

  void _toggleItem(ShoppingItemModel item, bool isBought) async {
    await _fs.toggleShoppingItem(widget.coupleId, item.id, isBought, item.name);
  }

  void _deleteItem(ShoppingItemModel item) async {
    await _fs.deleteShoppingItem(widget.coupleId, item.id);
  }

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'لیستی کڕین 🛒',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ShoppingItemModel>>(
              stream: _fs.streamShoppingList(widget.coupleId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('کێشەیەک ڕوویدا'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data!;
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'لیستەکە بەتاڵە',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                // دابەشکردن بۆ کڕدراو و نەکڕدراو (Sorting)
                final activeItems = items.where((i) => !i.isBought).toList();
                final boughtItems = items.where((i) => i.isBought).toList();

                final sortedItems = [...activeItems, ...boughtItems];

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sortedItems.length,
                  itemBuilder: (context, index) {
                    final item = sortedItems[index];
                    return _buildShoppingItem(item);
                  },
                );
              },
            ),
          ),
          _buildBottomInput(),
        ],
      ),
    );
  }

  Widget _buildShoppingItem(ShoppingItemModel item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => _deleteItem(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: item.isBought ? Colors.white.withOpacity(0.5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!item.isBought)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: GestureDetector(
            onTap: () => _toggleItem(item, !item.isBought),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isBought ? Colors.green : Colors.transparent,
                border: Border.all(
                  color: item.isBought ? Colors.green : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: item.isBought
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: item.isBought ? FontWeight.normal : FontWeight.w600,
              color: item.isBought ? Colors.grey.shade500 : Colors.black87,
              decoration: item.isBought ? TextDecoration.lineThrough : TextDecoration.none,
            ),
          ),
          trailing: Text(
            item.addedBy == currentUserId ? 'من' : (widget.me.partnerNickname ?? 'ئەو'),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInput() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _itemController,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'کەرەستەیەکی نوێ بنووسە...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _addItem(),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _addItem,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
