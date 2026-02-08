class Version implements Comparable<Version> {
  Version({
    required this.major,
    required this.minor,
    required this.patch,
    required this.build,
  });

  factory Version.fromString(String versionCode) {
    final version = versionCode.split('+');

    if (version.length > 2) {
      throw ArgumentError('Invalid version code: $versionCode');
    }

    final numbers = version[0].split('.');
    if (numbers.length != 3) {
      throw ArgumentError('Invalid version format: ${version[0]}');
    }

    return Version(
      major: int.parse(numbers[0]),
      minor: int.parse(numbers[1]),
      patch: int.parse(numbers[2]),
      build: version.length == 2
          ? int.parse(version[1])
          : null, // default when +build is missing
    );
  }

  final int major;
  final int minor;
  final int patch;
  final int? build;

  @override
  int compareTo(Version other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);

    // Ignore build if either version doesn't have it
    if (build == null || other.build == null) {
      return 0;
    }
    return build!.compareTo(other.build!);
  }

  bool operator >(Version other) => compareTo(other) > 0;

  bool operator <(Version other) => compareTo(other) < 0;

  @override
  String toString() => '$major.$minor.$patch${build != null ? '+$build' : ''}';
}
