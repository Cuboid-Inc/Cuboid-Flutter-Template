import 'package:fleetgo/app/app.bottomsheets.dart';
import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/app/app.router.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/parties/data/parties_repository.dart';
import 'package:fleetgo/ui/widgets/paginated_list/pagination_controller.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

enum PartiesBusy { addParty }

class PartiesViewModel extends BaseViewModel {
  PartiesViewModel(PartiesRepository? repository)
    : _repository = repository ?? locator<PartiesRepository>();
  final PartiesRepository _repository;
  NavigationService get _navigation => locator<NavigationService>();
  BottomSheetService get _bottomSheets => locator<BottomSheetService>();
  PartyType selectedType = PartyType.customer;
  late final PaginationController<Party> pagination = PaginationController(
    callback: (page, size) => _repository.fetchPage(
      pageNumber: page,
      pageSize: size,
      type: selectedType,
    ),
    onStateChanged: notifyListeners,
  );
  Map<String, num> balances = const {};
  String? errorMessage;

  Future<void> init() async {
    await pagination.loadInitial();
    switch (await _repository.fetchBalances()) {
      case Success(:final value):
        balances = {for (final item in value) item.partyId: item.amount};
      case Failure(:final failure):
        errorMessage = failure.message;
    }
  }

  void selectType(PartyType type) {
    selectedType = type;
    pagination.loadInitial();
  }

  Future<void> refreshList() async {
    _repository.invalidateCache();
    await pagination.refresh();
  }

  num balanceFor(String partyId) => balances[partyId] ?? 0;

  void open(Party party) => _navigation.navigateTo(
    Routes.partyDetailView,
    arguments: PartyDetailViewArguments(party: party),
  );
  Future<void> add() async {
    if (busy(PartiesBusy.addParty)) return;
    await runBusyFuture(() async {
      final response = await _bottomSheets.showCustomSheet<Party, Object?>(
        variant: BottomSheetType.partyForm,
        isScrollControlled: true,
      );
      final party = response?.data;
      if (party != null) await create(party);
    }(), busyObject: PartiesBusy.addParty);
  }

  Future<void> create(Party party) async {
    switch (await _repository.create(party)) {
      case Success():
        await pagination.loadInitial();
      case Failure(:final failure):
        errorMessage = failure.message;
        notifyListeners();
    }
  }

  @override
  void dispose() {
    pagination.dispose();
    super.dispose();
  }
}
