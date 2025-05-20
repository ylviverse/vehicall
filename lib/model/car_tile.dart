import 'package:VehiCall/model/car.dart';
import 'package:flutter/material.dart';

class CarTile extends StatelessWidget {
  final Car car;
  void Function()? onTap;
  CarTile({super.key, required this.car, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 25),
      width: MediaQuery.of(context).size.width * 0.75, // Responsive width
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // pic
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              car.imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height:
                  MediaQuery.of(context).size.width * 0.4, // Responsive height
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Text(
              car.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(car.price),
                  ],
                ),

                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Icon(Icons.favorite, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
