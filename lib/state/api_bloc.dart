import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uplink/models/model_api.dart';
import 'package:uplink/services/db_service.dart';
import 'package:uuid/uuid.dart';

class ApiBloc extends Bloc<ApiEvent, ApiState> {
  static final ApiBloc _instance = ApiBloc._internal();
  factory ApiBloc() {
    return _instance;
  }

  ApiBloc._internal() : super(ApiState(apis: [], selectedApi: null, isLoading: true)) {
    on<InitializeEvent>(_onInitialize);
    on<SelectApiEvent>(_onSelectApi);
    on<CreateApiEvent>(_onCreateApi);
    on<RemoveApiEvent>(_onRemoveApi);
    on<UpdateApiEvent>(_onUpdateApi);
    on<EditingApiEvent>(_onEditingApi);
    on<StopEditingApiEvent>(_onStopEditingApi);
    add(InitializeEvent());
  }

  List<ModelApi> apis = [];
  ModelApi? selectedApi;


  Future<void> _onInitialize(InitializeEvent event, Emitter<ApiState> emit) async {
    apis = await DbService.getAllApis();
    emit(ApiState(apis: apis, selectedApi: null, isLoading: false));
  }

  void _onSelectApi(SelectApiEvent event, Emitter<ApiState> emit) {
    selectedApi = event.api;
    emit(ApiState(apis: apis, selectedApi: selectedApi, isLoading: false));
  }

  void _onCreateApi(CreateApiEvent event, Emitter<ApiState> emit) {
    apis.add(ModelApi(
      id: const Uuid().v4(),
      name: event.name,
      endpoint: event.endpoint,
      apiKey: event.apiKey,
    ));
    DbService.addApi(apis.last);
    emit(ApiState(apis: apis, selectedApi: selectedApi, isLoading: false));
  }

  void _onRemoveApi(RemoveApiEvent event, Emitter<ApiState> emit) {
    DbService.deleteApi(event.id);
    var updatedApis = List<ModelApi>.from(apis);
    updatedApis.removeWhere((element) => element.id == event.id);
    apis = updatedApis;
    emit(ApiState(apis: apis, selectedApi: selectedApi, isLoading: false));
  }

  void _onUpdateApi(UpdateApiEvent event, Emitter<ApiState> emit) async {
    var newApi = ModelApi(
      id: event.id,
      name: event.name,
      endpoint: event.endpoint,
      apiKey: event.apiKey,
    );
    await DbService.updateApi(newApi);
    var updatedApis = List<ModelApi>.from(apis);
    var index = updatedApis.indexWhere((element) => element.id == event.id);
    updatedApis[index] = newApi;
    apis = updatedApis;
    emit(ApiState(apis: apis, selectedApi: selectedApi, isLoading: false));
  }

  void _onEditingApi(EditingApiEvent event, Emitter<ApiState> emit) {
    emit(EditingApiState(apis: apis, selectedApi: selectedApi, isLoading: false));
  }

  void _onStopEditingApi(StopEditingApiEvent event, Emitter<ApiState> emit) {
    emit(NotEditingApiState(apis: apis, selectedApi: selectedApi, isLoading: false));
  }
}

abstract class ApiEvent {}

class InitializeEvent extends ApiEvent {}
class CreateApiEvent extends ApiEvent {
  final String name;
  final String endpoint;
  final String apiKey;

  CreateApiEvent(
      {required this.name, required this.endpoint, required this.apiKey});
}

class RemoveApiEvent extends ApiEvent {
  final String id;

  RemoveApiEvent({required this.id});
}

class SelectApiEvent extends ApiEvent {
  final ModelApi? api;

  SelectApiEvent({required this.api});
}

class UpdateApiEvent extends ApiEvent {
  final String id;
  final String name;
  final String endpoint;
  final String apiKey;

  UpdateApiEvent(
      {required this.id,
      required this.name,
      required this.endpoint,
      required this.apiKey});
}

class EditingApiEvent extends ApiEvent {}

class StopEditingApiEvent extends ApiEvent {}

class ApiState {
  final List<ModelApi> apis;
  final ModelApi? selectedApi;
  final bool isLoading;

  ApiState({required this.apis, this.selectedApi, this.isLoading = false});
}

class EditingApiState extends ApiState {
  EditingApiState({required super.apis, required super.selectedApi, required super.isLoading});
}

class NotEditingApiState extends ApiState {
  NotEditingApiState({required super.apis, required super.selectedApi, required super.isLoading});
}
