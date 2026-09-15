import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() => runApp(const FMCGApp());

class FMCGApp extends StatelessWidget {
  const FMCGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FMCG Tally Prototype',
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ---------------- MODELS ----------------
class Product {
  final String id;
  final String name;
  final String sku;
  int stock;
  final double purchasePrice;
  final double salePrice;
  final double gstPercent;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.stock,
    required this.purchasePrice,
    required this.salePrice,
    required this.gstPercent,
  });
}

class InvoiceItem {
  final Product product;
  int quantity;

  InvoiceItem({required this.product, required this.quantity});

  double get subtotal => product.salePrice * quantity;
  double get tax => subtotal * (product.gstPercent / 100);
  double get total => subtotal + tax;
}

class Invoice {
  final String id;
  final String customerName;
  final DateTime date;
  final List<InvoiceItem> items;
  final double grandTotal;

  Invoice({
    required this.id,
    required this.customerName,
    required this.date,
    required this.items,
    required this.grandTotal,
  });
}

// ---------------- MAIN STATE ----------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Product> _products = [
    Product(id: '1', name: 'Wheat Flour 5kg', sku: 'SKU-001', stock: 120, purchasePrice: 180, salePrice: 220, gstPercent: 5),
    Product(id: '2', name: 'Refined Oil 1L', sku: 'SKU-002', stock: 14, purchasePrice: 110, salePrice: 135, gstPercent: 5),
    Product(id: '3', name: 'Detergent Powder 1kg', sku: 'SKU-003', stock: 45, purchasePrice: 85, salePrice: 110, gstPercent: 18),
    Product(id: '4', name: 'Biscuits Carton', sku: 'SKU-004', stock: 8, purchasePrice: 420, salePrice: 500, gstPercent: 12),
  ];

  final List<Invoice> _invoices = [];

  void _addInvoice(Invoice invoice) {
    setState(() {
      _invoices.insert(0, invoice);
      for (var item in invoice.items) {
        final prod = _products.firstWhere((p) => p.id == item.product.id);
        prod.stock -= item.quantity;
      }
    });
  }

  void _addProduct(Product p) {
    setState(() {
      _products.add(p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      InventoryScreen(products: _products, onAdd: _addProduct),
      BillingScreen(products: _products, onInvoiceCreated: _addInvoice),
      LedgerScreen(invoices: _invoices),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Stock'),
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'New Bill'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Ledger'),
        ],
      ),
    );
  }
}

// ---------------- SCREEN 1: INVENTORY ----------------
class InventoryScreen extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onAdd;

  const InventoryScreen({super.key, required this.products, required this.onAdd});

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Item Name')),
            TextField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU / Barcode')),
            TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Opening Stock')),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sale Price (₹)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                onAdd(Product(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text,
                  sku: skuCtrl.text.isEmpty ? 'SKU-NEW' : skuCtrl.text,
                  stock: int.tryParse(stockCtrl.text) ?? 0,
                  purchasePrice: (double.tryParse(priceCtrl.text) ?? 0) * 0.8,
                  salePrice: double.tryParse(priceCtrl.text) ?? 0,
                  gstPercent: 5.0,
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FMCG Inventory (Stock)')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (ctx, idx) {
          final p = products[idx];
          final bool isLowStock = p.stock < 15;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('SKU: ${p.sku} | Price: ₹${p.salePrice} (+${p.gstPercent}% GST)'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${p.stock} units', style: TextStyle(fontWeight: FontWeight.bold, color: isLowStock ? Colors.red : Colors.green, fontSize: 16)),
                  if (isLowStock) const Text('Low Stock', style: TextStyle(color: Colors.red, fontSize: 10)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------- SCREEN 2: BILLING ----------------
class BillingScreen extends StatefulWidget {
  final List<Product> products;
  final Function(Invoice) onInvoiceCreated;

  const BillingScreen({super.key, required this.products, required this.onInvoiceCreated});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController _customerCtrl = TextEditingController(text: 'Walk-in Retailer');
  final List<InvoiceItem> _cart = [];

  void _addToCart(Product product) {
    final existingIdx = _cart.indexWhere((item) => item.product.id == product.id);
    if (existingIdx >= 0) {
      if (_cart[existingIdx].quantity < product.stock) {
        setState(() => _cart[existingIdx].quantity++);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot exceed available stock')));
      }
    } else {
      if (product.stock > 0) {
        setState(() => _cart.add(InvoiceItem(product: product, quantity: 1)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item out of stock!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalAmount = _cart.fold(0, (acc, item) => acc + item.total);

    return Scaffold(
      appBar: AppBar(title: const Text('Invoice & POS Billing')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _customerCtrl,
              decoration: const InputDecoration(labelText: 'Customer / Outlet Name', border: OutlineInputBorder()),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Align(alignment: Alignment.centerLeft, child: Text('Add Items:', style: TextStyle(fontWeight: FontWeight.bold))),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.products.length,
              itemBuilder: (ctx, i) {
                final prod = widget.products[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ActionChip(
                    label: Text('${prod.name} (₹${prod.salePrice})'),
                    onPressed: () => _addToCart(prod),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: _cart.isEmpty
                ? const Center(child: Text('No items added yet.'))
                : ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (ctx, idx) {
                      final item = _cart[idx];
                      return ListTile(
                        title: Text(item.product.name),
                        subtitle: Text('Qty: ${item.quantity} × ₹${item.product.salePrice} (+Tax: ₹${item.tax.toStringAsFixed(1)})'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('₹${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => setState(() {
                                if (item.quantity > 1) {
                                  item.quantity--;
                                } else {
                                  _cart.removeAt(idx);
                                }
                              }),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey.shade100, border: const Border(top: BorderSide(color: Colors.grey))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Grand Total:'),
                    Text('₹${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.print),
                  label: const Text('Generate Invoice'),
                  onPressed: _cart.isEmpty
                      ? null
                      : () {
                          final inv = Invoice(
                            id: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                            customerName: _customerCtrl.text,
                            date: DateTime.now(),
                            items: List.from(_cart),
                            grandTotal: totalAmount,
                          );
                          widget.onInvoiceCreated(inv);
                          setState(() => _cart.clear());
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice ${inv.id} saved!')));
                        },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ---------------- SCREEN 3: LEDGER ----------------
class LedgerScreen extends StatelessWidget {
  final List<Invoice> invoices;

  const LedgerScreen({super.key, required this.invoices});

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd MMM, hh:mm a');
    return Scaffold(
      appBar: AppBar(title: const Text('Sales Register / Ledger')),
      body: invoices.isEmpty
          ? const Center(child: Text('No invoices issued yet.'))
          : ListView.builder(
              itemCount: invoices.length,
              itemBuilder: (ctx, idx) {
                final inv = invoices[idx];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ExpansionTile(
                    title: Text('${inv.customerName} - ₹${inv.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${inv.id} • ${f.format(inv.date)}'),
                    children: inv.items
                        .map((item) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${item.product.name} (x${item.quantity})'),
                                  Text('₹${item.total.toStringAsFixed(2)}'),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                );
              },
            ),
    );
  }
}