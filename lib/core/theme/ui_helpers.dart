import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Spacing scale (px).
const double s4 = 4;
const double s8 = 8;
const double s12 = 12;
const double s16 = 16;
const double s20 = 20;
const double s24 = 24;
const double s32 = 32;

// Corner radii (px), matching the design's card/button/hero rounding.
const double radiusSm = 12;
const double radiusMd = 16;
const double radiusLg = 20;
const double radiusPill = 999;

// Shared subtle card shadow used behind the dark hero card in the design.
const List<BoxShadow> cardShadow = [
  BoxShadow(color: Color(0x1A101828), blurRadius: 32, offset: Offset(0, 14)),
];

// Device height and width
double get dheight =>
    PlatformDispatcher.instance.views.first.physicalSize.height /
    PlatformDispatcher.instance.views.first.devicePixelRatio;

double get dwidth =>
    PlatformDispatcher.instance.views.first.physicalSize.width /
    PlatformDispatcher.instance.views.first.devicePixelRatio;
