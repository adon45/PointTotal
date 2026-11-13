import 'package:flutter/material.dart';

class GuideTopic {
  const GuideTopic({
    required this.icon,
    required this.title,
    required this.text,
    this.useAccent = false,
  });

  final IconData icon;
  final String title;
  final String text;
  final bool useAccent;
}

const List<GuideTopic> guideTopics = [
  GuideTopic(
    icon: Icons.today_outlined,
    title: 'Your daily points',
    text:
        "The large number on Home is the points earned from today's submissions. "
        'It starts fresh each new day.',
  ),
  GuideTopic(
    icon: Icons.add_circle_outline,
    title: 'Adding media',
    text:
        'Tap Add, choose what you captured, and make any follow-up selections. '
        "Tap Submit to add its points to today's total.",
    useAccent: true,
  ),
  GuideTopic(
    icon: Icons.touch_app_outlined,
    title: 'Choosing a submission',
    text:
        'For Homes, choose Silver or Platinum, a specification, and a square-footage range. '
        'For Media Shoots or Neighborhood, choose one item. Leads, SV, New Inventory, and PA need no further choices; Tenants asks for Added and Removed counts.',
  ),
  GuideTopic(
    icon: Icons.lightbulb_outline,
    title: 'A quick example',
    text:
        'Tap Add > Homes > Silver > Silver w/ Splat > Up to 2,000. '
        'Tap Submit to see the entry and its 0.25 points in the table.',
    useAccent: true,
  ),
  GuideTopic(
    icon: Icons.table_rows_outlined,
    title: 'Submitted Today',
    text: 'Every submission appears in the table with its points. Tap a row’s delete icon and confirm to remove one submission; the total updates.',
  ),
  GuideTopic(
    icon: Icons.exposure_outlined,
    title: 'How points are displayed',
    text: 'Each entry shows its exact point value. The daily total is rounded to the nearest hundredth.',
    useAccent: true,
  ),
  GuideTopic(
    icon: Icons.history,
    title: 'History',
    text: 'Tap the History icon at the top right to see past days. Tap a day to expand its submissions; History is view-only.',
  ),
  GuideTopic(
    icon: Icons.rate_review_outlined,
    title: 'Feedback',
    text: 'Tap Feedback to leave a review or make a suggestion. Use a suggestion to report a value that looks wrong.',
    useAccent: true,
  ),
  GuideTopic(
    icon: Icons.phonelink_lock_outlined,
    title: 'Your data stays on this device',
    text:
        'Entries are saved in this browser on this device. Clearing browser data or switching devices or browsers loses them. '
        'On iPhone, use Share > Add to Home Screen and open the app from that icon. '
        'The app also counts anonymous visits to help improve it; no personal information or points data is collected.',
  ),
];
