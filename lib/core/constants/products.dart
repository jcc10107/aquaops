// Canonical catalog of customer-facing products — single source of truth
// shared between the customer store screen and the owner's Edit Product
// Photos screen, so both always agree on which products exist.
class ProductDef {
  final String id;
  final String name;
  final double price;
  final String type;

  const ProductDef({
    required this.id,
    required this.name,
    required this.price,
    required this.type,
  });
}

const List<ProductDef> catalogProducts = [
  ProductDef(
    id: 'r_slim',
    name: 'Slim Refill',
    price: 35.0,
    type: 'Refill exchange • Cap sanitized',
  ),
  ProductDef(
    id: 'r_round',
    name: 'Round Refill',
    price: 35.0,
    type: 'Refill exchange • Dispenser fit',
  ),
  ProductDef(
    id: 'n_slim',
    name: 'New Slim Gallon',
    price: 235.0,
    type: 'New Container + Pure Water',
  ),
  ProductDef(
    id: 'n_round',
    name: 'New Round Gallon',
    price: 255.0,
    type: 'New Container + Pure Water',
  ),
  ProductDef(
    id: 'bottle500',
    name: '500ml Bottled Water',
    price: 15.0,
    type: 'Bottled water • Grab-and-go',
  ),
];
