/// Static content for the portal — kept out of the controller for clarity.
class PortalData {
  static const docsSections = [
    {'key': 'getting-started', 'label': 'Getting started'},
    {'key': 'pods', 'label': 'Pods & DI'},
    {'key': 'scheduling', 'label': 'Scheduling'},
  ];

  static const docsContent = {
    'getting-started': {
      'title': 'Getting started',
      'body': 'Scaffold a service, add @Service pods, wire constructor injection, and ship with jl build. Jetleaf compiles your component graph ahead of time for fast startup.',
      'hasCode': false,
    },
    'pods': {
      'title': 'Pods & Dependency Injection',
      'body': 'Jetleaf pods are the container-managed pods. Use @Service/@Repository/@Pod with constructor injection; @Primary and @Qualifier disambiguate; @Lazy defers expensive construction.',
      'hasCode': false,
    },
    'scheduling': {
      'title': 'Scheduling',
      'body': 'Add @EnableScheduling to your starter and annotate methods with @Scheduled(fixedRate: …) or CronType for recurring jobs.',
      'hasCode': true,
    },
  };
}
