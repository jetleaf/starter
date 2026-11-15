import 'package:test/test.dart';

import 'package:server_rendered_portal/src/web/template_renderer.dart';

void main() {
  group('PortalTemplateRenderer', () {
    final renderer = PortalTemplateRenderer();

    test('renders the home page inside the layout', () {
      final html = renderer.render('home', {
        'title': 'Template Test',
        'description': 'Rendering test',
        'heroTitle': 'Hello SSR',
        'heroSubtitle': 'Subtitle goes here',
        'features': ['fast', 'crawlable'],
        'betaBanner': true,
      });

      expect(html, contains('<!DOCTYPE html>'));
      expect(html, contains('<title>Template Test · Jetleaf Portal</title>'));
      expect(html, contains('Hello SSR'));
      expect(html, contains('<li>fast</li>'));
      expect(html, contains('<li>crawlable</li>'));
      expect(html, contains('Beta channel'));
    });

    test('hides the beta banner when disabled', () {
      final html = renderer.render('home', {
        'title': 'Template Test',
        'description': 'desc',
        'heroTitle': 'Hi',
        'heroSubtitle': 'Sub',
        'features': <String>[],
        'betaBanner': false,
      });

      expect(html, isNot(contains('Beta channel')));
    });

    test('docs page renders the selected section and sidebar links', () {
      final html = renderer.render('docs', {
        'title': 'Docs',
        'description': 'desc',
        'section': 'Scheduling',
        'sections': [
          {'key': 'scheduling', 'label': 'Scheduling'},
        ],
        'currentTitle': 'Scheduling',
        'currentBody': 'Body text',
        'currentHasCode': true,
      });

      expect(html, contains('Scheduling'));
      expect(html, contains('Body text'));
      expect(html, contains('@Scheduled'));
    });

    test('contact page renders validation errors when present', () {
      final html = renderer.render('contact', {
        'title': 'Contact',
        'description': 'desc',
        'name': 'Ada',
        'email': 'bad',
        'message': 'short',
        'hasErrors': true,
        'errors': ['A valid email address is required.'],
      });

      expect(html, contains('A valid email address is required.'));
      expect(html, contains('value="Ada"'));
    });
  });
}
