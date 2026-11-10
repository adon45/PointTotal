# Point Tracker

Run locally with `flutter run -d chrome`.

To deploy, push to the `main` branch, then enable **Settings > Pages > Source: GitHub Actions** in the repository. The site URL is `https://<owner>.github.io/<repository>/`.

Entries are stored in each user's own browser on that device. They are lost if site data is cleared or the site URL changes. iPhone users can use **Share > Add to Home Screen**.

The Quick Guide screen is available from Home; its text lives in [lib/data/guide_content.dart](lib/data/guide_content.dart).

## Feedback

The review and suggestion form URLs and review popup thresholds are configured in [lib/config/feedback_config.dart](lib/config/feedback_config.dart). The review popup appears on Home after a successful submission once the app-open threshold is reached. Open counts and review preferences are stored per browser/device. Temporarily set `firstPromptAfterOpens` to `1` to test the popup, then set it back to `15`.
