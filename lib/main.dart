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

class Customer {
  final String id;
  final String name;
  final String phone;
  double balance; // Positive balance = Customer owes money (Udhar)

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.balance = 0.0,
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
  final bool isCredit;

  Invoice({
    required this.id,
    required this.customerName,
    required this.date,
    required this.items,
    required this.grandTotal,
    required this.isCredit,
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

  final List<Customer> _customers = [
    Customer(id: 'c1', name: 'Gupta Kirana Store', phone: '9876543210', balance: 4500.0),
    Customer(id: 'c2', name: 'Sharma General Traders', phone: '9123456780', balance: 1200.0),
    Customer(id: 'c3', name: 'Verma Supermarket', phone: '9988776655', balance: 0.0),
  ];

  final List<Invoice> _invoices = [];

  void _addInvoice(Invoice invoice, Customer? customer) {
    setState(() {
      _invoices.insert(0, invoice);
      for (var item in invoice.items) {
        final prod = _products.firstWhere((p) => p.id == item.product.id);
        prod.stock -= item.quantity;
      }
      if (invoice.isCredit && customer != null) {
        customer.balance += invoice.grandTotal;
      }
    });
  }

  void _recordPayment(Customer customer, double amount) {
    setState(() {
      customer.balance -= amount;
      if (customer.balance < 0) customer.balance = 0;
    });
  }

  void _addProduct(Product p) {
    setState(() => _products.add(p));
  }

  void _addCustomer(Customer c) {
    setState(() => _customers.add(c));
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      InventoryScreen(products: _products, onAdd: _addProduct),
      BillingScreen(products: _products, customers: _customers, onInvoiceCreated: _addInvoice),
      KhataScreen(customers: _customers, onRecordPayment: _recordPayment, onAddCustomer: _addCustomer),
      LedgerScreen(invoices: _invoices),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Stock'),
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'POS Bill'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Khata'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Invoices'),
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

// ---------------- SCREEN 2: BILLING WITH KHATA OPTION ----------------
class BillingScreen extends StatefulWidget {
  final List<Product> products;
  final List<Customer> customers;
  final Function(Invoice, Customer?) onInvoiceCreated;

  const BillingScreen({super.key, required this.products, required this.customers, required this.onInvoiceCreated});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  Customer? _selectedCustomer;
  bool _isCreditBill = false;
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
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: DropdownButtonFormField<Customer>(
              decoration: const InputDecoration(labelText: 'Select Retailer / Customer', border: OutlineInputBorder()),
              value: _selectedCustomer,
              items: widget.customers.map((c) {
                return DropdownMenuItem(value: c, child: Text('${c.name} (Due: ₹${c.balance.toStringAsFixed(0)})'));
              }).toList(),
              onChanged: (val) => setState(() => _selectedCustomer = val),
            ),
          ),
          SwitchListTile(
            title: const Text('Add to Udhar / Khata (Credit)'),
            subtitle: Text(_isCreditBill ? 'Balance will be charged to customer ledger' : 'Paid in cash/UPI immediately'),
            value: _isCreditBill,
            activeColor: Colors.orange,
            onChanged: (val) => setState(() => _isCreditBill = val),
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
                    Text(_isCreditBill ? 'Credit Amount:' : 'Cash Total:'),
                    Text('₹${totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _isCreditBill ? Colors.orange.shade800 : Colors.teal)),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.print),
                  label: const Text('Save & Bill'),
                  onPressed: _cart.isEmpty
                      ? null
                      : () {
                          if (_isCreditBill && _selectedCustomer == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a customer for Khata / Credit bills!')));
                            return;
                          }
                          final inv = Invoice(
                            id: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                            customerName: _selectedCustomer?.name ?? 'Cash Counter',
                            date: DateTime.now(),
                            items: List.from(_cart),
                            grandTotal: totalAmount,
                            isCredit: _isCreditBill,
                          );
                          widget.onInvoiceCreated(inv, _selectedCustomer);
                          setState(() => _cart.clear());
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice ${inv.id} recorded successfully!')));
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

// ---------------- SCREEN 3: KHATA / CREDIT REGISTER ----------------
class KhataScreen extends StatelessWidget {
  final List<Customer> customers;
  final Function(Customer, double) onRecordPayment;
  final Function(Customer) onAddCustomer;

  const KhataScreen({super.key, required this.customers, required this.onRecordPayment, required this.onAddCustomer});

  void _showPaymentDialog(BuildContext context, Customer customer) {
    final payCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Receive Payment: ${customer.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Due: ₹${customer.balance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 12),
            TextField(
              controller: payCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount Received (₹)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(payCtrl.text);
              if (val != null && val > 0) {
                onRecordPayment(customer, val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final balCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Khata Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Retailer / Firm Name')),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
            TextField(controller: balCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Opening Balance (₹)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                onAddCustomer(Customer(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text,
                  phone: phoneCtrl.text,
                  balance: double.tryParse(balCtrl.text) ?? 0.0,
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save Customer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalCreditOutstanding = customers.fold(0, (acc, c) => acc + c.balance);

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Khata & Credit')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('New Khata'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.red.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Market Udhar (Receivable):', style: TextStyle(fontSize: 14, color: Colors.grey)),
                Text('₹${totalCreditOutstanding.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: customers.length,
              itemBuilder: (ctx, idx) {
                final c = customers[idx];
                final bool hasDue = c.balance > 0;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: hasDue ? Colors.red.shade100 : Colors.green.shade100,
                      child: Icon(Icons.store, color: hasDue ? Colors.red : Colors.green),
                    ),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Phone: ${c.phone}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${c.balance.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: hasDue ? Colors.red : Colors.green)),
                        Text(hasDue ? 'Udhar Due' : 'Cleared', style: TextStyle(fontSize: 11, color: hasDue ? Colors.red : Colors.green)),
                      ],
                    ),
                    onTap: () => _showPaymentDialog(context, c),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- SCREEN 4: INVOICE LEDGER ----------------
class LedgerScreen extends StatelessWidget {
  final List<Invoice> invoices;

  const LedgerScreen({super.key, required this.invoices});

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd MMM, hh:mm a');
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice History')),
      body: invoices.isEmpty
          ? const Center(child: Text('No invoices recorded yet.'))
          : ListView.builder(
              itemCount: invoices.length,
              itemBuilder: (ctx, idx) {
                final inv = invoices[idx];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ExpansionTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(inv.customerName, style: const TextStyle(fontWeight: FontWeight.bold))),
                        Text('₹${inv.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        Text('${inv.id} • ${f.format(inv.date)}  '),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: inv.isCredit ? Colors.orange.shade100 : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(inv.isCredit ? 'KHATA (UDHAR)' : 'PAID CASH',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: inv.isCredit ? Colors.orange.shade900 : Colors.green.shade900)),
                        )
                      ],
                    ),
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
