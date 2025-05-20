import 'package:VehiCall/model/car.dart';
import 'package:VehiCall/model/fav.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CartItem extends StatefulWidget {
  Car car;
  CartItem({super.key, required this.car});

  @override
  State<CartItem> createState() => _CartItemState();
}

class _CartItemState extends State<CartItem> {
  //delete this sht
  void removeItemFromFav() {
    Provider.of<Fav>(context, listen: false).removeItem(widget.car);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Image.asset(widget.car.imagePath),
        title: Text(widget.car.name),
        subtitle: Text(widget.car.price),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: removeItemFromFav,
        ),
      ),
    );
  }
}
