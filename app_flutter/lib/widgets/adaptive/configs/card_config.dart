import 'package:flutter/material.dart';
import '../adaptive_card.dart';

extension AdaptiveCardConfigExtended on AdaptiveCardConfig {
  static AdaptiveCardConfig floating() => const AdaptiveCardConfig(variant: CardVariant.elevated, margin: EdgeInsets.all(16.0), borderRadius: BorderRadius.all(Radius.circular(16.0)), showShadow: true, selectable: false, elevation: 8.0);

  static AdaptiveCardConfig compact() => const AdaptiveCardConfig(variant: CardVariant.listItem, margin: EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0), borderRadius: BorderRadius.all(Radius.circular(6.0)), showShadow: false, selectable: false);

  static AdaptiveCardConfig action() => const AdaptiveCardConfig(variant: CardVariant.elevated, margin: EdgeInsets.all(12.0), borderRadius: BorderRadius.all(Radius.circular(12.0)), showShadow: true, selectable: false, elevation: 4.0);

  static AdaptiveCardConfig modal() => const AdaptiveCardConfig(variant: CardVariant.elevated, margin: EdgeInsets.all(24.0), borderRadius: BorderRadius.all(Radius.circular(20.0)), showShadow: true, selectable: false, elevation: 12.0);

  static AdaptiveCardConfig subtle() => const AdaptiveCardConfig(variant: CardVariant.simple, margin: EdgeInsets.all(4.0), borderRadius: BorderRadius.all(Radius.circular(4.0)), showShadow: false, selectable: false);

  static AdaptiveCardConfig media() => const AdaptiveCardConfig(variant: CardVariant.elevated, margin: EdgeInsets.all(8.0), borderRadius: BorderRadius.all(Radius.circular(8.0)), showShadow: true, selectable: false, elevation: 2.0);

  static AdaptiveCardConfig notification() => const AdaptiveCardConfig(variant: CardVariant.elevated, margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), borderRadius: BorderRadius.all(Radius.circular(12.0)), showShadow: true, selectable: false, elevation: 3.0);

  static AdaptiveCardConfig dashboard() => const AdaptiveCardConfig(variant: CardVariant.elevated, margin: EdgeInsets.all(16.0), borderRadius: BorderRadius.all(Radius.circular(12.0)), showShadow: true, selectable: false, elevation: 2.0);

  static AdaptiveCardConfig settings() => const AdaptiveCardConfig(variant: CardVariant.simple, margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0), borderRadius: BorderRadius.all(Radius.circular(8.0)), showShadow: false, selectable: false);

  static AdaptiveCardConfig custom({CardVariant variant = CardVariant.simple, EdgeInsets? margin, BorderRadius? borderRadius, Color? backgroundColor, bool showShadow = false, bool selectable = false, double? elevation}) =>
      AdaptiveCardConfig(variant: variant, margin: margin ?? const EdgeInsets.all(8.0), borderRadius: borderRadius ?? const BorderRadius.all(Radius.circular(8.0)), backgroundColor: backgroundColor, showShadow: showShadow, selectable: selectable, elevation: elevation);
}

class CardConfigBuilder {
  CardVariant _variant = CardVariant.simple;
  EdgeInsets _margin = const EdgeInsets.all(8.0);
  BorderRadius _borderRadius = const BorderRadius.all(Radius.circular(8.0));
  Color? _backgroundColor;
  bool _showShadow = false;
  bool _selectable = false;
  double? _elevation;

  CardConfigBuilder variant(CardVariant variant) {
    _variant = variant;
    return this;
  }

  CardConfigBuilder margin(EdgeInsets margin) {
    _margin = margin;
    return this;
  }

  CardConfigBuilder borderRadius(BorderRadius borderRadius) {
    _borderRadius = borderRadius;
    return this;
  }

  CardConfigBuilder backgroundColor(Color color) {
    _backgroundColor = color;
    return this;
  }

  CardConfigBuilder shadow(bool show, {double? elevation}) {
    _showShadow = show;
    _elevation = elevation;
    return this;
  }

  CardConfigBuilder selectable([bool selectable = true]) {
    _selectable = selectable;
    return this;
  }

  AdaptiveCardConfig build() {
    return AdaptiveCardConfig(variant: _variant, margin: _margin, borderRadius: _borderRadius, backgroundColor: _backgroundColor, showShadow: _showShadow, selectable: _selectable, elevation: _elevation);
  }
}

class CardConfigs {
  static const eventListItem = AdaptiveCardConfig(variant: CardVariant.event, margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0), borderRadius: BorderRadius.all(Radius.circular(12.0)), showShadow: true, selectable: false, elevation: 2.0);

  static const contactListItem = AdaptiveCardConfig(variant: CardVariant.contact, margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0), borderRadius: BorderRadius.all(Radius.circular(8.0)), showShadow: true, selectable: false, elevation: 1.0);

  static const groupListItem = AdaptiveCardConfig(variant: CardVariant.listItem, margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0), borderRadius: BorderRadius.all(Radius.circular(10.0)), showShadow: true, selectable: false, elevation: 1.5);

  static const selectableEvent = AdaptiveCardConfig(variant: CardVariant.selectable, margin: EdgeInsets.all(8.0), borderRadius: BorderRadius.all(Radius.circular(8.0)), showShadow: false, selectable: true);

  static const selectableContact = AdaptiveCardConfig(variant: CardVariant.selectable, margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0), borderRadius: BorderRadius.all(Radius.circular(8.0)), showShadow: false, selectable: true);

  static const bottomSheetCard = AdaptiveCardConfig(
    variant: CardVariant.elevated,
    margin: EdgeInsets.zero,
    borderRadius: BorderRadius.only(topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0)),
    showShadow: true,
    selectable: false,
    elevation: 8.0,
  );

  static const dialogCard = AdaptiveCardConfig(variant: CardVariant.elevated, margin: EdgeInsets.all(24.0), borderRadius: BorderRadius.all(Radius.circular(16.0)), showShadow: true, selectable: false, elevation: 16.0);
}
