import 'package:VehiCall/model/car.dart';
import 'package:flutter/material.dart';

class Fav extends ChangeNotifier {
  List<Car> carRent = [
    Car(
      price: '1400 / day',
      imagePath: 'lib/images/car.jpg',
      name: 'Vios',
      description:
          'Car for rent, good for outing , family use, airport transfer',
    ),

    Car(
      price: '1200 / day',
      imagePath: 'lib/images/car1.jpg',
      name: 'Mirage',
      description: 'Car for rent, good for outing , no issue all registred',
    ),

    Car(
      price: '1350 / day',
      imagePath: 'lib/images/car3.jpg',
      name: '2011 Ford scape',
      description:
          'Good running condition Cold Aircon Issue=expired registered ',
    ),

    Car(
      price: '600 / day',
      imagePath: 'lib/images/car4.jpg',
      name: 'Innova',
      description: 'Good for Family Use, outing, moving things out',
    ),
  ];

  List<Car> userCart = [];

  List<Car> getCarlist() {
    return carRent;
  }

  List<Car> getUserList() {
    return userCart;
  }

  void addItemToCart(Car car) {
    userCart.add(car);
    notifyListeners();
  }

  void removeItem(Car car) {
    userCart.remove(car);
    notifyListeners();
  }
}
