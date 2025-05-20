import 'package:VehiCall/components/cart_item.dart';
import 'package:VehiCall/model/car.dart';
import 'package:VehiCall/model/fav.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<Fav>(
      builder:
          (context, value, child) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Favorites',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),

                const SizedBox(height: 25),

                Expanded(
                  child: ListView.builder(
                    itemCount: value.getUserList().length,
                    itemBuilder: (context, index) {
                      Car individualCar = value.getUserList()[index];
                      return CartItem(car: individualCar);
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
