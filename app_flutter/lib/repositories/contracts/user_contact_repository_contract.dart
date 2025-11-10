import '../../models/domain/user_contact.dart';
import 'realtime_repository_contract.dart';

abstract class IUserContactRepository
    implements
        IRealtimeRepository<List<UserContact>>,
        IRefreshableRepository<List<UserContact>>,
        ILocalRepository<List<UserContact>> {
  @override
  Stream<List<UserContact>> get dataStream => contactsStream;
  Stream<List<UserContact>> get contactsStream;

  // Realtime methods inherited from IRealtimeRepository:
  // - Future<void> get initialized
  // - Future<void> initialize()
  // - Future<void> refresh() (from IRefreshableRepository)
  // - Future<void> startRealtimeSubscription()
  // - Future<void> stopRealtimeSubscription()
  // - bool get isRealtimeConnected
  // - Future<void> loadFromCache()
  // - Future<void> saveToCache()
  // - Future<void> clearCache()
  // - void dispose()
  // - List<UserContact> getLocalData() (from ILocalRepository)
  Future<ContactSyncResponse> syncContacts(List<ContactInfo> contacts);
  Future<List<UserContact>> fetchContacts({
    bool onlyRegistered = true,
    int limit = 100,
    int skip = 0,
  });
  @override
  List<UserContact> getLocalData() => getLocalContacts();
  List<UserContact> getLocalContacts();
  UserContact? getContactById(int id);
  UserContact? getContactByPhone(String phoneNumber);
}
