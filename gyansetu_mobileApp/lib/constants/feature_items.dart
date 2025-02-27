import 'package:flutter/material.dart';
import 'package:gyansetu_client/screens/chat_section.dart';
import '../materials.dart';
import '../ar_vr.dart';
import '../krishi.dart';

class FeatureItem {
  final String title;
  final Widget page;

  const FeatureItem({
    required this.title,
    required this.page,
  });
}

final List<FeatureItem> featureItems = [
  FeatureItem(
    title: "Chat",
    page: const ChatSection(),
  ),
  FeatureItem(
    title: "Materials",
    page: MaterialsPage(),
  ),
  FeatureItem(
    title: "AR/VR",
    page: ArVrPage(),
  ),
  FeatureItem(
    title: "Krishi",
    page: KrishiPage(),
  ),
];
