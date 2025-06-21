import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'discord_inspect_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  group('Inspector', () {
    late MockDio mockDio;
    late Inspector inspector;

    setUp(() {
      mockDio = MockDio();
      inspector =
          Inspector(hookUrls: ['http://mock-webhook-url.com'], dio: mockDio);
    });

    test('send method sends a simple message', () async {
      when(mockDio.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async =>
          Response(requestOptions: RequestOptions(path: ''), statusCode: 200));

      // Use the inspector instance initialized in setUp
      // final testInspector = Inspector(hookUrls: ['http://mock-webhook-url.com'], dio: mockDio);

      final message = DiscordWebhookMessage.simple('Test message');
      await inspector.send(message);

      verify(mockDio.post(
        'http://mock-webhook-url.com',
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).called(1);
    });

    test('createCurlEmbed generates correct embed for success', () {
      final embed = Inspector.createCurlEmbed(
        curl: 'curl example',
        method: 'GET',
        uri: 'http://example.com',
        statusCode: 200,
        responseBody: '{"key":"value"}',
        responseTime: '100ms',
      );

      expect(embed.title, 'GET http://example.com');
      expect(embed.description, 'Status Code: 200');
      expect(embed.color, 5763719); // Green
      expect(embed.fields!.length, 2);
      expect(embed.fields![0].name, 'cURL Command');
      expect(embed.fields![1].name, 'Response Body');
    });

    test('createCurlEmbed generates correct embed for client error', () {
      final embed = Inspector.createCurlEmbed(
        curl: 'curl example',
        method: 'POST',
        uri: 'http://example.com/error',
        statusCode: 404,
      );

      expect(embed.color, 16525609); // Yellow
    });

    test('createCurlEmbed generates correct embed for server error', () {
      final embed = Inspector.createCurlEmbed(
        curl: 'curl example',
        method: 'PUT',
        uri: 'http://example.com/server-error',
        statusCode: 500,
      );

      expect(embed.color, 15548997); // Red
    });

    test('sendCurlLog sends correct message with embed', () async {
      when(mockDio.post(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async =>
          Response(requestOptions: RequestOptions(path: ''), statusCode: 200));

      // final testInspector = Inspector(hookUrls: ['http://mock-webhook-url.com']);
      // testInspector.setDio(mockDio); // Assuming a setter for testing purposes

      await inspector.sendCurlLog(
        curl: 'curl test',
        method: 'GET',
        uri: 'http://test.com',
        statusCode: 200,
      );

      verify(mockDio.post(
        'http://mock-webhook-url.com',
        data: argThat(contains('embeds')), // Check if embeds are in the payload
        options: anyNamed('options'),
      )).called(1);
    });
  });

  group('DiscordInspector', () {
    test('isMatch returns true for matching URI and status', () {
      final options = DiscordInspector(
        webhookUrls: ['url'],
        includeUrls: ['api.example.com'],
        inspectionStatus: [ResponseStatus.success],
      );
      expect(options.isMatch('http://api.example.com/data', 200), isTrue);
    });

    test('isMatch returns false for non-matching URI', () {
      final options = DiscordInspector(
        webhookUrls: ['url'],
        includeUrls: ['api.example.com'],
        inspectionStatus: [ResponseStatus.success],
      );
      expect(options.isMatch('http://another.api.com/data', 200), isFalse);
    });

    test('isMatch returns false for non-matching status', () {
      final options = DiscordInspector(
        webhookUrls: ['url'],
        includeUrls: ['api.example.com'],
        inspectionStatus: [ResponseStatus.clientError],
      );
      expect(options.isMatch('http://api.example.com/data', 200), isFalse);
    });

    test('isMatch returns true when no filters are set', () {
      final options = DiscordInspector(
        webhookUrls: ['url'],
        includeUrls: [],
        excludeUrls: [],
        inspectionStatus: [], // No specific status filters
      );
      // If inspectionStatus is empty, it should match any status
      expect(options.isMatch('http://any.url.com', 200), isTrue);
      expect(options.isMatch('http://any.url.com', 404), isTrue);
    });

    test('isMatch returns true for any URI when includeUrls is empty', () {
      final options = DiscordInspector(
        webhookUrls: ['url'],
        includeUrls: [],
        excludeUrls: ['/admin'], // Exclude specific URLs
        inspectionStatus: [ResponseStatus.success],
      );
      expect(options.isMatch('http://api.com/data', 200), isTrue);
      expect(options.isMatch('http://api.com/users', 200), isTrue);
      expect(options.isMatch('http://api.com/admin', 200), isFalse);
    });

    test('isMatch handles multiple URI filters', () {
      final options = DiscordInspector(
        webhookUrls: ['url'],
        includeUrls: ['/users/', '/products/'],
        inspectionStatus: [ResponseStatus.success],
      );
      expect(options.isMatch('http://api.com/users/1', 200), isTrue);
      expect(options.isMatch('http://api.com/products/5', 200), isTrue);
      expect(options.isMatch('http://api.com/orders/10', 200), isFalse);
    });

    test('isMatch returns false for matching URI in excludeUrls', () {
      final options = DiscordInspector(
        webhookUrls: ['url'],
        excludeUrls: ['api.example.com'],
        inspectionStatus: [ResponseStatus.success],
      );
      expect(options.isMatch('http://api.example.com/data', 200), isFalse);
    });

    test('isMatch handles both includeUrls and excludeUrls', () {
      final options = DiscordInspector(
        webhookUrls: ['url'],
        includeUrls: ['/users'],
        excludeUrls: ['/users/admin'],
        inspectionStatus: [ResponseStatus.success],
      );
      expect(options.isMatch('http://api.com/users/123', 200), isTrue);
      expect(options.isMatch('http://api.com/users/admin/123', 200), isFalse);
      expect(options.isMatch('http://api.com/products/123', 200), isFalse);
    });

    test('isMatch handles very long URIs', () {
      final longUri = 'http://example.com/' + 'a' * 2000 + '/data';
      final options = DiscordInspector(
        webhookUrls: ['url'],
        includeUrls: ['/data'],
        inspectionStatus: [ResponseStatus.success],
      );
      expect(options.isMatch(longUri, 200), isTrue);
    });

    test('isMatch handles unusual response statuses', () {
      final options = DiscordInspector(
        webhookUrls: ['url'],
        inspectionStatus: [ResponseStatus.unknown],
      );
      expect(options.isMatch('http://api.com/data', 999), isFalse); // Unknown status should not match
    });

    test('isMatch handles multiple inspection statuses', () {
      final options = DiscordInspector(
        webhookUrls: ['url'],
        includeUrls: ['/data'],
        inspectionStatus: [
          ResponseStatus.clientError,
          ResponseStatus.serverError
        ],
      );
      expect(options.isMatch('http://api.com/data', 400), isTrue);
      expect(options.isMatch('http://api.com/data', 500), isTrue);
      expect(options.isMatch('http://api.com/data', 200), isFalse);
    });
  });

  group('DiscordWebhookMessage', () {
    test('simple factory creates message with content', () {
      final message = DiscordWebhookMessage.simple('Hello');
      expect(message.content, 'Hello');
      expect(message.embeds, isNull);
    });

    test('withEmbed factory creates message with embed', () {
      final embed = DiscordEmbed(title: 'Test Embed');
      final message = DiscordWebhookMessage.withEmbed(embed);
      expect(message.content, isNull);
      expect(message.embeds, isNotNull);
      expect(message.embeds!.length, 1);
      expect(message.embeds![0].title, 'Test Embed');
    });

    test('toJson creates correct JSON for simple message', () {
      final message = DiscordWebhookMessage.simple('Hello');
      final json = message.toJson();
      expect(json['content'], 'Hello');
      expect(json.containsKey('embeds'), isFalse);
    });

    test('toJson creates correct JSON for message with embed', () {
      final embed = DiscordEmbed(title: 'Test Embed');
      final message = DiscordWebhookMessage.withEmbed(embed);
      final json = message.toJson();
      expect(json.containsKey('content'), isFalse);
      expect(json['embeds'], isA<List>());
      expect(json['embeds'][0]['title'], 'Test Embed');
    });
  });

  group('DiscordEmbed', () {
    test('toJson creates correct JSON', () {
      final embed = DiscordEmbed(
        title: 'Title',
        description: 'Description',
        url: 'http://example.com',
        color: 123456,
        author: DiscordEmbedAuthor(name: 'Author'),
        fields: [DiscordEmbedField(name: 'Field', value: 'Value')],
        thumbnail: DiscordEmbedThumbnail(url: 'http://thumb.com'),
        image: DiscordEmbedImage(url: 'http://image.com'),
        footer: DiscordEmbedFooter(text: 'Footer'),
        timestamp: '2023-01-01T00:00:00.000Z',
      );
      final json = embed.toJson();

      expect(json['title'], 'Title');
      expect(json['description'], 'Description');
      expect(json['url'], 'http://example.com');
      expect(json['color'], 123456);
      expect(json['author']['name'], 'Author');
      expect(json['fields'][0]['name'], 'Field');
      expect(json['thumbnail']['url'], 'http://thumb.com');
      expect(json['image']['url'], 'http://image.com');
      expect(json['footer']['text'], 'Footer');
      expect(json['timestamp'], '2023-01-01T00:00:00.000Z');
    });
  });

  group('DiscordEmbedAuthor', () {
    test('toJson creates correct JSON', () {
      final author = DiscordEmbedAuthor(
        name: 'Test Author',
        url: 'http://author.com',
        iconUrl: 'http://icon.com',
      );
      final json = author.toJson();
      expect(json['name'], 'Test Author');
      expect(json['url'], 'http://author.com');
      expect(json['icon_url'], 'http://icon.com');
    });
  });

  group('DiscordEmbedField', () {
    test('toJson creates correct JSON', () {
      final field = DiscordEmbedField(
        name: 'Field Name',
        value: 'Field Value',
        inline: true,
      );
      final json = field.toJson();
      expect(json['name'], 'Field Name');
      expect(json['value'], 'Field Value');
      expect(json['inline'], true);
    });
  });

  group('DiscordEmbedThumbnail', () {
    test('toJson creates correct JSON', () {
      final thumbnail = DiscordEmbedThumbnail(url: 'http://thumb.com');
      final json = thumbnail.toJson();
      expect(json['url'], 'http://thumb.com');
    });
  });

  group('DiscordEmbedImage', () {
    test('toJson creates correct JSON', () {
      final image = DiscordEmbedImage(url: 'http://image.com');
      final json = image.toJson();
      expect(json['url'], 'http://image.com');
    });
  });

  group('DiscordEmbedFooter', () {
    test('toJson creates correct JSON', () {
      final footer = DiscordEmbedFooter(
        text: 'Footer Text',
        iconUrl: 'http://footer-icon.com',
      );
      final json = footer.toJson();
      expect(json['text'], 'Footer Text');
      expect(json['icon_url'], 'http://footer-icon.com');
    });
  });
}
