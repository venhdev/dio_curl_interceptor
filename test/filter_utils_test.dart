import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/src/core/utils/filter_utils.dart';
import 'package:dio_curl_interceptor/src/options/filter_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FilterUtils', () {
    late RequestOptions options;
    
    setUp(() {
      options = RequestOptions(
        path: '/api/users',
        method: 'GET',
      );
    });
    
    group('shouldFilter', () {
      test('should return false when filtering is disabled', () {
        final filterOptions = FilterOptions.disabled();
        
        expect(FilterUtils.shouldFilter(options, filterOptions), isFalse);
      });
      
      test('should return false when no rules are defined', () {
        final filterOptions = FilterOptions(rules: []);
        
        expect(FilterUtils.shouldFilter(options, filterOptions), isFalse);
      });
      
      test('should return false when path is excluded', () {
        final filterOptions = FilterOptions(
          rules: [FilterRule.exact('/api/users')],
          exclusions: ['/api/users'],
        );
        
        expect(FilterUtils.shouldFilter(options, filterOptions), isFalse);
      });
      
      test('should return true for exact path match', () {
        final filterOptions = FilterOptions(
          rules: [FilterRule.exact('/api/users')],
        );
        
        expect(FilterUtils.shouldFilter(options, filterOptions), isTrue);
      });
      
      test('should return false when method does not match', () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule(
              pathPattern: '/api/users',
              methods: ['POST', 'PUT'],
            ),
          ],
        );
        
        expect(FilterUtils.shouldFilter(options, filterOptions), isFalse);
      });
      
      test('should return true when method matches', () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule(
              pathPattern: '/api/users',
              methods: ['GET', 'POST'],
            ),
          ],
        );
        
        expect(FilterUtils.shouldFilter(options, filterOptions), isTrue);
      });
      
      test('should return true for regex path match', () {
        final filterOptions = FilterOptions(
          rules: [FilterRule.regex(r'/api/\w+')],
        );
        
        expect(FilterUtils.shouldFilter(options, filterOptions), isTrue);
      });
      
      test('should return true for glob path match', () {
        final filterOptions = FilterOptions(
          rules: [FilterRule.glob('/api/*')],
        );
        
        expect(FilterUtils.shouldFilter(options, filterOptions), isTrue);
      });
    });
    
    group('getMatchingRule', () {
      test('should return null when filtering is disabled', () {
        final filterOptions = FilterOptions.disabled();
        
        expect(FilterUtils.getMatchingRule(options, filterOptions), isNull);
      });
      
      test('should return null when no rules are defined', () {
        final filterOptions = FilterOptions(rules: []);
        
        expect(FilterUtils.getMatchingRule(options, filterOptions), isNull);
      });
      
      test('should return null when path is excluded', () {
        final rule = FilterRule.exact('/api/users');
        final filterOptions = FilterOptions(
          rules: [rule],
          exclusions: ['/api/users'],
        );
        
        expect(FilterUtils.getMatchingRule(options, filterOptions), isNull);
      });
      
      test('should return matching rule for exact path match', () {
        final rule = FilterRule.exact('/api/users');
        final filterOptions = FilterOptions(
          rules: [rule],
        );
        
        expect(FilterUtils.getMatchingRule(options, filterOptions), rule);
      });
      
      test('should return first matching rule when multiple rules match', () {
        final rule1 = FilterRule.exact('/api/users');
        final rule2 = FilterRule.regex(r'/api/\w+');
        final filterOptions = FilterOptions(
          rules: [rule1, rule2],
        );
        
        expect(FilterUtils.getMatchingRule(options, filterOptions), rule1);
      });
    });
    
    group('generateBlockedResponse', () {
      test('should use provided mock response if available', () async {
        final mockResponse = Response(
          requestOptions: options,
          data: {'test': 'data'},
          statusCode: 200,
        );
        
        final rule = FilterRule(
          pathPattern: '/api/users',
          mockResponse: mockResponse,
        );
        
        final response = await FilterUtils.generateBlockedResponse(options, rule);
        
        expect(response, mockResponse);
      });
      
      test('should generate response with specified status code and data', () async {
        final rule = FilterRule(
          pathPattern: '/api/users',
          statusCode: 403,
          responseData: {'error': 'Forbidden'},
        );
        
        final response = await FilterUtils.generateBlockedResponse(options, rule);
        
        expect(response.statusCode, 403);
        expect(response.data, {'error': 'Forbidden'});
      });
      
      test('should include X-Blocked-By header', () async {
        final rule = FilterRule(
          pathPattern: '/api/users',
        );
        
        final response = await FilterUtils.generateBlockedResponse(options, rule);
        
        expect(response.headers.value('X-Blocked-By'), 'CurlInterceptor');
      });
      
      test('should include custom headers if provided', () async {
        final rule = FilterRule(
          pathPattern: '/api/users',
          headers: {
            'Custom-Header': 'test-value',
          },
        );
        
        final response = await FilterUtils.generateBlockedResponse(options, rule);
        
        expect(response.headers.value('Custom-Header'), 'test-value');
      });
    });
  });
}
