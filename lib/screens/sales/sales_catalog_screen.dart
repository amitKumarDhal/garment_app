import 'package:flutter/material.dart';

class SalesCatalogScreen extends StatelessWidget {
  const SalesCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Product Catalog")),
      body: const Center(child: Text("Product List Here")),
    );
  }
}
