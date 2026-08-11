import 'package:cuboid_flutter_template/features/home/ui/viewmodels/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class HomeView extends StackedView<HomeViewModel> {
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
