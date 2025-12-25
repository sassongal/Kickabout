# Repository vs Service Boundaries

## Clear Separation of Concerns

### Repository (Data Access Layer)
**Responsibility:** Pure data access operations

**What belongs here:**
- ✅ CRUD operations (create, read, update, delete)
- ✅ Queries (simple and complex)
- ✅ Data transformation (JSON ↔ Model)
- ✅ Infrastructure concerns (caching, retry, monitoring) - OK
- ✅ Batch writes (if purely data operations)

**What does NOT belong here:**
- ❌ Business validation rules
- ❌ Business logic (initialization, calculations)
- ❌ Orchestration (multiple repository calls)
- ❌ Transactions with business rules
- ❌ Error messages with business context

**Example:**
```dart
// ✅ GOOD: Pure data access
Future<String> createHub(Hub hub) async {
  final docRef = _firestore.collection('hubs').doc();
  await docRef.set(hub.toJson());
  return docRef.id;
}

// ❌ BAD: Contains business logic
Future<String> createHub(Hub hub) async {
  // Validation - should be in service
  if (await canCreateHub(hub.createdBy) == false) {
    throw Exception('Limit reached');
  }
  // Business logic - should be in service
  data['memberCount'] = 1;
  data['managerIds'] = [hub.createdBy];
  // ...
}
```

### Service (Business Logic Layer)
**Responsibility:** Business rules, orchestration, validation

**What belongs here:**
- ✅ Business validation rules
- ✅ Business logic (calculations, transformations)
- ✅ Orchestration (multiple repository calls)
- ✅ Transactions with business rules
- ✅ Domain-specific error messages
- ✅ Complex workflows

**What does NOT belong here:**
- ❌ Direct Firestore access (use repositories)
- ❌ Data transformation (JSON ↔ Model) - use repositories
- ❌ Infrastructure concerns (caching, retry) - use repositories

**Example:**
```dart
// ✅ GOOD: Business logic and orchestration
class HubCreationService {
  final HubsRepository _hubsRepo;
  final UsersRepository _usersRepo;
  
  Future<String> createHub(Hub hub) async {
    // Validation
    final canCreate = await _hubsRepo.canCreateHub(hub.createdBy);
    if (!canCreate.canCreate) {
      throw HubCreationLimitException(...);
    }
    
    // Business logic: Initialize denormalized fields
    final hubData = hub.toJson();
    hubData['memberCount'] = 1;
    hubData['managerIds'] = [hub.createdBy];
    
    // Orchestration: Multiple operations
    final hubId = await _hubsRepo.createHub(hub);
    await _hubsRepo.addMember(hubId, hub.createdBy, role: 'manager');
    await _usersRepo.addHubToUser(hub.createdBy, hubId);
    
    return hubId;
  }
}
```

### Infrastructure Service
**Responsibility:** Cross-cutting concerns

**Examples:**
- ✅ CacheService
- ✅ RetryService
- ✅ MonitoringService
- ✅ LocationService
- ✅ AnalyticsService

These are fine as-is - they provide infrastructure capabilities.

## Migration Plan

### Phase 1: Extract Hub Creation Logic
1. Create `HubCreationService` in `lib/features/hubs/domain/services/`
2. Move validation and business logic from `HubsRepository.createHub()`
3. Keep `HubsRepository.createHub()` as simple data access
4. Update all callers to use `HubCreationService`

### Phase 2: Audit Other Repositories
1. Check all repositories for business logic
2. Extract to appropriate services
3. Keep repositories as pure data access

### Phase 3: Move Domain Services
1. Move `HubPermissionsService` to `lib/features/hubs/domain/services/`
2. Ensure all services use repositories, not direct Firestore access

