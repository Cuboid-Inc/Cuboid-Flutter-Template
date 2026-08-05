import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/app/app.router.dart';
import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/party.dart';
import 'package:fleetgo/core/models/work_order.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/features/parties/data/parties_repository.dart';
import 'package:fleetgo/features/shell/shell_service.dart';
import 'package:fleetgo/features/work/data/work_repository.dart';
import 'package:fleetgo/ui/widgets/paginated_list/pagination_controller.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

extension WorkStatusLabel on WorkStatus {
  String get label => switch (this) {
    WorkStatus.planned => 'Planned',
    WorkStatus.completed => 'Completed',
    WorkStatus.billed => 'Billed',
    WorkStatus.canceled => 'Canceled',
  };
}

class WorkViewModel extends ReactiveViewModel {
  WorkViewModel([
    WorkRepository? repository,
    PartiesRepository? partiesRepository,
  ]) : _repository = repository ?? locator<WorkRepository>(),
       _partiesRepository = partiesRepository ?? locator<PartiesRepository>();

  final WorkRepository _repository;
  final PartiesRepository _partiesRepository;
  final _navigation = locator<NavigationService>();
  final _shellService = locator<ShellService>();

  List<Party> parties = const [];
  String _query = '';
  String? errorMessage;

  late final PaginationController<WorkOrder> pagination = PaginationController(
    callback: (page, size) => _repository.fetchPage(
      pageNumber: page,
      pageSize: size,
      status: filter,
      search: _query,
    ),
    onStateChanged: notifyListeners,
  );

  String get query => _query;
  WorkStatus? get filter => _shellService.workFilter;
  List<WorkStatus?> get filters => [null, ...WorkStatus.values];

  @override
  List<ListenableServiceMixin> get listenableServices => [_shellService];

  Future<void> init() async {
    setBusy(true);
    await pagination.loadInitial();
    switch (await _partiesRepository.fetchAll()) {
      case Success(:final value):
        parties = value;
      case Failure(:final failure):
        errorMessage = failure.message;
    }
    setBusy(false);
  }

  List<WorkOrder> get workOrders => pagination.items;

  String customerFor(WorkOrder work) {
    for (final party in parties) {
      if (party.id == work.customerId) return party.name;
    }
    return 'Unknown customer';
  }

  String totalFor(WorkOrder work) => Formatters.money(work.gross);
  String dateFor(WorkOrder work) => Formatters.dateTime(work.date);

  void setQuery(String value) {
    _query = value;
    pagination.loadInitial();
  }

  void setFilter(WorkStatus? value) {
    _shellService.setWorkFilter(value);
    pagination.loadInitial();
  }

  Future<void> refreshList() async {
    _repository.invalidateCache();
    _partiesRepository.invalidateCache();
    switch (await _partiesRepository.fetchAll()) {
      case Success(:final value):
        parties = value;
      case Failure(:final failure):
        errorMessage = failure.message;
    }
    await pagination.refresh();
  }

  Future<void> openNewTrip() async {
    await _navigation.navigateTo(Routes.newTripView);
    await refreshList();
  }

  Future<void> openMonthlyExtra() async {
    await _navigation.navigateTo(Routes.monthlyWorkView);
    await refreshList();
  }

  Future<void> openDetail(WorkOrder work, int index) async {
    await _navigation.navigateTo(
      Routes.workDetailView,
      arguments: WorkDetailViewArguments(work: work),
    );
    switch (await _repository.fetchOne(work.id)) {
      case Success(:final value):
        if (filter != null && value.status != filter) {
          pagination.removeItem(pagination.items[index]);
        } else {
          pagination.updateItem(index, value);
        }
      case Failure():
        break;
    }
  }

  @override
  void dispose() {
    pagination.dispose();
    super.dispose();
  }
}
