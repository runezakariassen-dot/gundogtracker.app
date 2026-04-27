// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../models/dog.dart';
import '../services/dog_photo_storage.dart';

class DogLabelResolver {
  DogLabelResolver(List<Dog> dogs)
      : _dogs = List<Dog>.from(dogs),
        _dogsById = {for (final dog in dogs) dog.id: dog},
        _nameCounts = _buildNameCounts(dogs);

  final List<Dog> _dogs;
  final Map<String, Dog> _dogsById;
  final Map<String, int> _nameCounts;

  DogLabelParts partsForDog(Dog dog) {
    final count = _nameCounts[dog.name] ?? 0;
    if (count <= 1) {
      return DogLabelParts(dog.name);
    }
    final year = dog.birthDate?.year;
    final disambiguator = year?.toString() ?? 'ukjent ar';
    return DogLabelParts(dog.name, disambiguator: disambiguator);
  }

  DogLabelParts partsForId(String dogId) {
    final dog = _dogsById[dogId];
    if (dog != null) {
      return partsForDog(dog);
    }
    final matches = _dogs.where((d) => d.name == dogId).toList();
    if (matches.length == 1) {
      return partsForDog(matches.first);
    }
    return DogLabelParts(dogId);
  }

  String labelForDog(Dog dog) {
    return partsForDog(dog).toString();
  }

  String labelForId(String dogId) {
    return partsForId(dogId).toString();
  }

  TextSpan spanForDog(
    BuildContext context,
    Dog dog, {
    TextStyle? style,
  }) {
    return _spanForParts(context, partsForDog(dog), style: style);
  }

  TextSpan spanForId(
    BuildContext context,
    String dogId, {
    TextStyle? style,
  }) {
    return _spanForParts(context, partsForId(dogId), style: style);
  }

  Widget chipLabelForDog(
    BuildContext context,
    Dog dog, {
    TextStyle? style,
    double avatarSize = 18,
  }) {
    return _labelWithAvatar(
      context,
      dog,
      style: style,
      avatarSize: avatarSize,
      maxWidth: 160,
    );
  }

  Widget pickerLabelForDog(
    BuildContext context,
    Dog dog, {
    TextStyle? style,
    double avatarSize = 20,
  }) {
    return _labelWithAvatar(
      context,
      dog,
      style: style,
      avatarSize: avatarSize,
      maxWidth: 220,
    );
  }

  Widget _labelWithAvatar(
    BuildContext context,
    Dog dog, {
    TextStyle? style,
    required double avatarSize,
    required double maxWidth,
  }) {
    final span = spanForDog(context, dog, style: style);
    final avatarFile = DogPhotoStorage.imageFileFromPath(dog.imagePath);
    if (avatarFile == null) {
      return Text.rich(
        span,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: avatarSize / 2,
            backgroundImage: FileImage(avatarFile),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text.rich(
              span,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _spanForParts(
    BuildContext context,
    DogLabelParts parts, {
    TextStyle? style,
  }) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final baseColor = style?.color ?? defaultStyle.color ?? Colors.white;
    final baseStyle = (style ?? defaultStyle).copyWith(color: baseColor);
    final secondaryStyle = baseStyle.copyWith(
      color: baseColor.withOpacity(0.6),
    );
    if (parts.disambiguator == null) {
      return TextSpan(text: parts.name, style: baseStyle);
    }
    return TextSpan(
      children: [
        TextSpan(text: parts.name, style: baseStyle),
        TextSpan(text: ' · ${parts.disambiguator}', style: secondaryStyle),
      ],
    );
  }

  static Map<String, int> _buildNameCounts(List<Dog> dogs) {
    final counts = <String, int>{};
    for (final dog in dogs) {
      counts[dog.name] = (counts[dog.name] ?? 0) + 1;
    }
    return counts;
  }
}

class DogLabelParts {
  const DogLabelParts(this.name, {this.disambiguator});

  final String name;
  final String? disambiguator;

  @override
  String toString() {
    if (disambiguator == null) {
      return name;
    }
    return '$name · $disambiguator';
  }
}
