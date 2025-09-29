# CurlViewer Filter Editing Plan

## Short Description
Add real-time filter editing capabilities to CurlViewer, allowing users to add, edit, and remove path blocking rules directly from the UI while the app is running.

## Summary progress
- Phase1: 0% - 0/8
- Phase2: 0% - 0/6
- Phase3: 0% - 0/4

## Reference Links
- [FilterOptions Implementation](../lib/src/options/filter_options.dart) - Current filter options structure
- [CurlViewer Controller](../lib/src/ui/controllers/curl_viewer_controller.dart) - Current controller structure
- [Path Blocking Tests](../test/path_blocking_unit_test.dart) - Test coverage for blocking functionality

## Plan Steps (Progress indicator 0% - 0/18 done)

### Phase 1: Controller and State Management (0% - 0/8 done)
- [ ] **Extend CurlViewerController** - Add filter management state and methods
  - Add `ValueNotifier<List<FilterRule>> activeFilters` for current filter rules
  - Add `ValueNotifier<bool> filterEditingMode` for UI state management
  - Add methods: `addFilter()`, `removeFilter()`, `updateFilter()`, `clearAllFilters()`
  - Add filter persistence support using existing persistence service

- [ ] **Create FilterRuleEditor** - Build a reusable widget for editing individual filter rules
  - Text input field for path pattern with validation
  - Dropdown for PathMatchType selection (exact, regex, glob)
  - Optional HTTP method selection (multi-select)
  - Status code and response data configuration
  - Save/Cancel buttons with proper validation

- [ ] **Add Filter Management Service** - Create service to handle filter operations
  - Bridge between UI and actual interceptor
  - Handle filter rule validation and sanitization
  - Manage filter rule persistence
  - Provide real-time updates to active interceptors

- [ ] **Update CurlViewerController** - Integrate filter management
  - Add filter-related ValueNotifiers
  - Implement filter CRUD operations
  - Add filter state persistence
  - Handle filter validation and error states

### Phase 2: UI Components and Integration (0% - 0/6 done)
- [ ] **Add Filter Tab/Section** - Create new UI section in CurlViewer
  - Add "Filters" tab or section to existing CurlViewer interface
  - Design consistent with existing CurlViewerStyle and CurlViewerColors
  - Include filter list view with add/edit/delete actions
  - Add filter status indicator (enabled/disabled)

- [ ] **Create Filter List Widget** - Build list view for managing multiple filters
  - Display active filters with pattern, type, and status
  - Add edit/delete actions for each filter
  - Include filter enable/disable toggle
  - Show filter match count or last matched time

- [ ] **Integrate with CurlViewer** - Add filter section to main CurlViewer widget
  - Add filter tab to existing tab structure
  - Integrate filter controller with main CurlViewerController
  - Handle filter state changes and UI updates
  - Add filter-related callbacks and event handling

### Phase 3: Real-time Integration and Testing (0% - 0/4 done)
- [ ] **Connect to Active Interceptors** - Enable real-time filter updates
  - Update active CurlInterceptorV2 instances when filters change
  - Handle interceptor recreation if needed
  - Ensure filter changes take effect immediately
  - Add proper error handling for filter application

- [ ] **Add Filter Testing Tools** - Provide tools to test filter rules
  - Add "Test Filter" functionality with sample requests
  - Show filter match results and response preview
  - Add filter rule validation and error reporting
  - Include filter performance metrics

- [ ] **Create Comprehensive Tests** - Test filter editing functionality
  - Unit tests for filter management controller
  - Widget tests for filter editing UI components
  - Integration tests for real-time filter updates
  - Test filter persistence and state management

- [ ] **Update Documentation** - Document new filter editing features
  - Update README with filter editing usage examples
  - Add filter editing to CurlViewer documentation
  - Create filter management best practices guide
  - Update API documentation for new controller methods

## Technical Considerations

### Architecture
- **State Management**: Use existing ValueNotifier pattern for consistency
- **Persistence**: Leverage existing CurlViewerPersistenceService
- **UI Consistency**: Follow existing CurlViewerStyle and CurlViewerColors patterns
- **Performance**: Implement efficient filter updates without recreating interceptors

### User Experience
- **Real-time Updates**: Filter changes should take effect immediately
- **Validation**: Provide clear feedback for invalid filter patterns
- **Persistence**: Filter rules should persist across app restarts
- **Testing**: Allow users to test filter rules before applying them

### Integration Points
- **CurlInterceptorV2**: Update active interceptors when filters change
- **CurlViewerController**: Extend existing controller with filter management
- **Persistence Service**: Store filter rules alongside other CurlViewer data
- **UI Components**: Integrate with existing CurlViewer tab structure

## Success Criteria
- [ ] Users can add new filter rules through the CurlViewer UI
- [ ] Filter rules take effect immediately without app restart
- [ ] Filter rules persist across app sessions
- [ ] Users can edit and delete existing filter rules
- [ ] Filter validation provides clear error messages
- [ ] Filter editing integrates seamlessly with existing CurlViewer functionality
- [ ] All filter operations are covered by comprehensive tests
- [ ] Documentation is updated with usage examples and best practices
