import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/app/app.router.dart';
import 'package:fleetgo/core/config/app_config.dart';
import 'package:fleetgo/core/models/business_profile.dart';
import 'package:fleetgo/core/pdf/letterhead_store.dart' as letterhead_store;
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/more/data/business_profile_repository.dart';
import 'package:fleetgo/ui/common/snackbar_ui.dart';
import 'package:fleetgo/ui/pdf/fleet_pdf.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

enum BusinessProfileBusy { letterhead, save }

class BusinessProfileViewModel extends BaseViewModel {
  BusinessProfileViewModel([BusinessProfileRepository? repository])
    : _repository = repository ?? locator<BusinessProfileRepository>(),
      _auth = locator<AuthRepository>();

  static const footerNoteMaxLength = 100;

  final BusinessProfileRepository _repository;
  final AuthRepository _auth;
  final _snackbar = locator<SnackbarService>();
  final _navigation = locator<NavigationService>();

  final legalNameController = TextEditingController();
  final arabicLegalNameController = TextEditingController();
  final trnController = TextEditingController();
  final tradeLicenceController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final invoicePrefixController = TextEditingController();
  final footerController = TextEditingController();
  final paymentInstructionsController = TextEditingController();
  final letterheadMarginTopController = TextEditingController(text: '45');
  final letterheadMarginBottomController = TextEditingController(text: '25');
  final letterheadMarginLeftController = TextEditingController(text: '20');
  final letterheadMarginRightController = TextEditingController(text: '20');
  final formKey = GlobalKey<FormState>();

  /// Single supported currency (no per-tenant configuration for now).
  String get currency => AppConfig.currencyCode;

  int brandColor = 0xFF101828;
  bool useCustomLetterhead = false;
  String? letterheadPath;
  int? letterheadWidth;
  int? letterheadHeight;
  bool showMoreIdentityDetails = false;

  bool get letterheadIsLowRes =>
      letterheadPath != null &&
      letterheadWidth != null &&
      letterheadHeight != null &&
      letterheadWidth! < 1240 &&
      letterheadHeight! < 1754;

  String get tenantName => _auth.currentTenantName;

  Future<void> init() async {
    setBusy(true);
    switch (await _repository.fetchBusinessProfile()) {
      case Success(:final value):
        legalNameController.text = value.legalName.isEmpty
            ? tenantName
            : value.legalName;
        arabicLegalNameController.text = value.arabicLegalName ?? '';
        trnController.text = value.trn ?? '';
        tradeLicenceController.text = value.tradeLicence ?? '';
        addressController.text = value.address ?? '';
        cityController.text = value.city ?? '';
        phoneController.text = value.phone ?? '';
        emailController.text = value.email ?? '';
        invoicePrefixController.text = value.invoicePrefix;
        footerController.text = value.footer ?? '';
        paymentInstructionsController.text = value.paymentInstructions ?? '';
        brandColor = value.brandColor;
        useCustomLetterhead = value.useCustomLetterhead;
        letterheadPath = value.letterheadPath;
        letterheadMarginTopController.text = value.letterheadMarginTopMm
            .toString();
        letterheadMarginBottomController.text = value.letterheadMarginBottomMm
            .toString();
        letterheadMarginLeftController.text = value.letterheadMarginLeftMm
            .toString();
        letterheadMarginRightController.text = value.letterheadMarginRightMm
            .toString();
      case Failure(:final failure):
        _snackbar.showError(failure.message);
    }
    setBusy(false);
  }

  void selectBrandColor(int color) {
    brandColor = color;
    notifyListeners();
  }

  void toggleMoreIdentityDetails() {
    showMoreIdentityDetails = !showMoreIdentityDetails;
    notifyListeners();
  }

  void selectLetterheadMode(bool custom) {
    useCustomLetterhead = custom;
    notifyListeners();
  }

  Future<void> pickLetterhead() async {
    if (busy(BusinessProfileBusy.letterhead)) return;
    final previousPath = letterheadPath;
    final upload = await runBusyFuture(
      letterhead_store.pickLetterhead(),
      busyObject: BusinessProfileBusy.letterhead,
    );
    if (upload != null) {
      letterheadPath = upload.path;
      letterheadWidth = upload.width;
      letterheadHeight = upload.height;
      if (previousPath != null) {
        await runBusyFuture(
          letterhead_store.deleteLetterhead(previousPath),
          busyObject: BusinessProfileBusy.letterhead,
        );
      }
    }
    notifyListeners();
  }

  Future<void> removeLetterhead() async {
    if (letterheadPath == null) return;
    if (busy(BusinessProfileBusy.letterhead)) return;
    await runBusyFuture(
      letterhead_store.deleteLetterhead(letterheadPath!),
      busyObject: BusinessProfileBusy.letterhead,
    );
    letterheadPath = null;
    letterheadWidth = null;
    letterheadHeight = null;
    notifyListeners();
  }

  void previewLetterhead() {
    if (letterheadPath == null) return;
    if (!_hasValidMargins) {
      _snackbar.showError('Letterhead margins must be between 0 and 100mm.');
      return;
    }
    _navigation.navigateTo(
      Routes.pdfPreviewView,
      arguments: PdfPreviewViewArguments(
        title: 'Letterhead preview',
        build: () => buildLetterheadPreviewPdf(_pendingProfile()),
      ),
    );
  }

  Future<void> save() async {
    if (busy(BusinessProfileBusy.save)) return;
    final legalName = legalNameController.text.trim();
    if (legalName.isEmpty) {
      _snackbar.showError('Legal name is required.');
      return;
    }
    if (!_hasValidMargins) {
      _snackbar.showError('Letterhead margins must be between 0 and 100mm.');
      return;
    }
    await runBusyFuture(() async {
      switch (await _repository.updateBusinessProfile(
        _pendingProfile(legalName: legalName),
      )) {
        case Success():
          _snackbar.showSuccess('Business profile updated');
          _navigation.back();
        case Failure(:final failure):
          _snackbar.showError(failure.message);
      }
    }(), busyObject: BusinessProfileBusy.save);
  }

  BusinessProfile _pendingProfile({String? legalName}) => BusinessProfile(
    legalName: legalName ?? legalNameController.text.trim(),
    arabicLegalName: _optional(arabicLegalNameController.text),
    trn: _optional(trnController.text),
    tradeLicence: _optional(tradeLicenceController.text),
    address: _optional(addressController.text),
    city: _optional(cityController.text),
    phone: _optional(phoneController.text),
    email: _optional(emailController.text),
    brandColor: brandColor,
    footer: _optionalCapped(footerController.text, footerNoteMaxLength),
    paymentInstructions: _optionalCapped(
      paymentInstructionsController.text,
      footerNoteMaxLength,
    ),
    invoicePrefix: invoicePrefixController.text.trim().isEmpty
        ? 'INV'
        : invoicePrefixController.text.trim(),
    useCustomLetterhead: useCustomLetterhead,
    letterheadPath: letterheadPath,
    letterheadMarginTopMm: double.parse(
      letterheadMarginTopController.text.trim(),
    ),
    letterheadMarginBottomMm: double.parse(
      letterheadMarginBottomController.text.trim(),
    ),
    letterheadMarginLeftMm: double.parse(
      letterheadMarginLeftController.text.trim(),
    ),
    letterheadMarginRightMm: double.parse(
      letterheadMarginRightController.text.trim(),
    ),
  );

  bool get _hasValidMargins =>
      [
        letterheadMarginTopController,
        letterheadMarginBottomController,
        letterheadMarginLeftController,
        letterheadMarginRightController,
      ].every((controller) {
        final margin = double.tryParse(controller.text.trim());
        return margin != null &&
            margin.isFinite &&
            margin >= 0 &&
            margin <= 100;
      });

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _optionalCapped(String value, int maxLength) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.length > maxLength
        ? trimmed.substring(0, maxLength)
        : trimmed;
  }

  @override
  void dispose() {
    legalNameController.dispose();
    arabicLegalNameController.dispose();
    trnController.dispose();
    tradeLicenceController.dispose();
    addressController.dispose();
    cityController.dispose();
    phoneController.dispose();
    emailController.dispose();
    invoicePrefixController.dispose();
    footerController.dispose();
    paymentInstructionsController.dispose();
    letterheadMarginTopController.dispose();
    letterheadMarginBottomController.dispose();
    letterheadMarginLeftController.dispose();
    letterheadMarginRightController.dispose();
    super.dispose();
  }
}
