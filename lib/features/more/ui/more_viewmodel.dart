import 'package:fleetgo/app/app.dialogs.dart';
import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/app/app.router.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/more/data/more_repository.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

enum MoreBusy { logout }

class MoreMenuItem {
  const MoreMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.tint = AppColors.primary,
    this.tintBg = AppColors.chipBg,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color tint;
  final Color tintBg;
}

class MoreViewModel extends BaseViewModel {
  MoreViewModel([MoreRepository? repository])
    : _repository = repository ?? locator<MoreRepository>();

  final MoreRepository _repository;
  final _navigation = locator<NavigationService>();
  final _snackbar = locator<SnackbarService>();
  final _dialog = locator<DialogService>();
  final _auth = locator<AuthRepository>();
  String? errorMessage;
  MoreMenuCounts? menuCounts;
  String appVersion = '';

  bool get isOwner => _auth.currentAccess?.isOwner ?? false;
  bool get hasReports =>
      isOwner ||
      (_auth.currentAccess?.accessPacks.contains(AccessPack.reports) ?? false);

  Future<void> loadMenuCounts() async {
    switch (await _repository.fetchMenuCounts()) {
      case Success(:final value):
        menuCounts = value;
        notifyListeners();
      case Failure(:final failure):
        errorMessage = failure.message;
        notifyListeners();
    }
  }

  Future<void> init() async {
    setBusy(true);
    errorMessage = null;
    final info = await PackageInfo.fromPlatform();
    appVersion = 'v${info.version} (${info.buildNumber})';
    await loadMenuCounts();
    setBusy(false);
  }

  Future<void> refreshSummery() async {
    _repository.invalidateCache();
    await loadMenuCounts();
  }

  Future<void> openParties() => _openAndRefresh(Routes.partiesView);
  Future<void> openVehicles() => _openAndRefresh(Routes.vehiclesView);
  Future<void> openDrivers() => _openAndRefresh(Routes.driversView);
  Future<void> openAgreements() => _openAndRefresh(Routes.agreementsView);
  Future<void> openRouteRates() => _openAndRefresh(Routes.routeRatesView);
  Future<void> openStaff() => _openAndRefresh(Routes.staffAccessView);

  void openReports() => _navigation.navigateTo(Routes.reportsView);

  Future<void> openBusinessProfile() async {
    await _navigation.navigateTo(Routes.businessProfileView);
  }

  Future<void> _openAndRefresh(String route) async {
    await _navigation.navigateTo(route);
    await loadMenuCounts();
  }

  void toast(String message) => _snackbar.showInfo(message);

  Future<void> logout() async {
    if (busy(MoreBusy.logout)) return;
    await runBusyFuture(() async {
      final result = await _dialog.showCustomDialog(
        variant: DialogType.confirm,
        title: 'Logout',
        description: 'Are you sure you want to logout?',
      );
      if (result != null && result.confirmed) {
        switch (await _auth.signOut()) {
          case Success():
            await _navigation.clearStackAndShow(Routes.loginView);
          case Failure(:final failure):
            _snackbar.showError(failure.message);
        }
      }
    }(), busyObject: MoreBusy.logout);
  }
}
