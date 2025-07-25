import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/fav_provider.dart';
import '../providers/theme_provider.dart';

enum SortOption { priceLowHigh, priceHighLow, ratingHighLow }

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Product> _products = [];
  bool _isLoading = false;
  SortOption? _selectedSort;

  Future<void> fetchProducts() async {
    setState(() => _isLoading = true);
    final response = await http.get(Uri.parse('https://fakestoreapi.com/products'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _products = data.map((e) => Product.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  List<Product> get sortedProducts {
    List<Product> sortedList = [..._products];
    if (_selectedSort == SortOption.priceLowHigh) {
      sortedList.sort((a, b) => a.price.compareTo(b.price));
    } else if (_selectedSort == SortOption.priceHighLow) {
      sortedList.sort((a, b) => b.price.compareTo(a.price));
    } else if (_selectedSort == SortOption.ratingHighLow) {
      sortedList.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return sortedList;
  }

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final favProvider = Provider.of<FavProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Shop'),
        actions: [
          PopupMenuButton<SortOption>(
            onSelected: (option) => setState(() => _selectedSort = option),
            icon: const Icon(Icons.sort),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortOption.priceLowHigh,
                child: Text('Price: Low → High'),
              ),
              const PopupMenuItem(
                value: SortOption.priceHighLow,
                child: Text('Price: High → Low'),
              ),
              const PopupMenuItem(
                value: SortOption.ratingHighLow,
                child: Text('Rating: High → Low'),
              ),
            ],
          ),
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => Navigator.pushNamed(context, '/cart'),
              ),
              if (cartProvider.count > 0)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cartProvider.count}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                )
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Smart Shop')),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pushReplacementNamed(context, '/home'),
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favourites'),
              onTap: () => Navigator.pushNamed(context, '/favourites'),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchProducts,
              child: ListView.builder(
                itemCount: sortedProducts.length,
                itemBuilder: (context, index) {
                  final product = sortedProducts[index];
                  final isFav = favProvider.isFavourite(product);

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: Image.network(product.image, width: 50, height: 50),
                      title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('৳${product.price.toStringAsFixed(2)} \n⭐ ${product.rating}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_shopping_cart),
                            onPressed: () => cartProvider.addItem(product),
                          ),
                          IconButton(
                            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                            onPressed: () => favProvider.toggleFavourite(product),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
