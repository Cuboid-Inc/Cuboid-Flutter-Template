import 'package:cuboid_flutter/cuboid_flutter.dart';
import 'package:cuboid_flutter_template/features/home/ui/home_viewmodel.dart';
import 'package:flutter/material.dart';

class HomeView extends CuboidView<HomeViewModel> {
  const HomeView({super.key});

  @override
  HomeViewModel viewModelBuilder(BuildContext context) => HomeViewModel();

  @override
  Widget builder(BuildContext context, HomeViewModel vm, Widget? child) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuboid Flutter Template')),
      body: const Center(child: Text('Welcome')),
    );
  }
}
