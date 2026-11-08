class PointOption {
  const PointOption(this.label, this.points);

  final String label;
  final double points;
}

class HomeSpecification {
  const HomeSpecification(this.label, this.ranges);

  final String label;
  final List<PointOption> ranges;
}

class HomeLevel {
  const HomeLevel(this.label, this.specifications);

  final String label;
  final List<HomeSpecification> specifications;
}

class RootOption {
  const RootOption(this.label, {this.points});

  final String label;
  final double? points;

  bool get isStandalone => points != null;
}

const List<RootOption> rootOptions = [
  RootOption('Homes'),
  RootOption('Media Shoots'),
  RootOption('Neighborhood'),
  RootOption('Leads', points: 0.0667),
  RootOption('Tenants', points: 0.006666),
  RootOption('SV', points: 0.0556),
  RootOption('New Inventory', points: 0.04),
  RootOption('PA', points: 0.0556),
];

const List<HomeLevel> homeLevels = [
  HomeLevel('Silver', [
    HomeSpecification('Silver w/ Splat', [
      PointOption('Up to 2,000', 0.25),
      PointOption('2,001 – 6,000', 0.50),
      PointOption('6,001 – 14,000', 0.75),
    ]),
    HomeSpecification('Silver w/out Splat', [
      PointOption('Up to 2,500', 0.25),
      PointOption('2,501 – 6,500', 0.50),
      PointOption('6,501 – 10,000', 0.75),
    ]),
  ]),
  HomeLevel('Platinum', [
    HomeSpecification('Full Platinum', [
      PointOption('Up to 3,500', 0.50),
      PointOption('3,501 – 10,000', 0.75),
    ]),
    HomeSpecification('Platinum w/o Splat', [
      PointOption('Up to 4,000', 0.50),
      PointOption('4,001 – 10,000', 0.75),
    ]),
    HomeSpecification('Platinum w/o Matterport', [
      PointOption('Up to 4,000', 0.25),
      PointOption('4,001 – 10,000', 0.50),
    ]),
    HomeSpecification('Platinum Photos Only', [
      PointOption('Up to 6,000', 0.25),
      PointOption('6,001 – 10,000', 0.50),
    ]),
  ]),
];

const List<PointOption> mediaShootOptions = [
  PointOption('Gold', 0.25),
  PointOption('Platinum', 0.50),
  PointOption('Diamond', 0.75),
  PointOption('Ten-x', 0.75),
  PointOption('Diamond Spotlight', 1.0),
];

const List<PointOption> neighborhoodOptions = [
  PointOption('Neighborhood', 1),
  PointOption('City', 1),
  PointOption('Condo', 1),
  PointOption('Event', 0.25),
  PointOption('Park', 0.08),
  PointOption('School', 0.08),
];
