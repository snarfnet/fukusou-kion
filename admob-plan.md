# AdMob Plan

## Placement

- Current component: `AdMobBanner` in `src/App.jsx`.
- Placement id: `home-after-safety-actions`.
- Screen position: after symptom check and SOS guidance, before the bottom navigation.
- Config file: `src/admobConfig.js`.
- AdMob app id: `ca-app-pub-9404799280370656~9293420712`.
- Banner ad unit id: `ca-app-pub-9404799280370656/6667257375`.

## Rationale

Ads should not interrupt heatstroke risk decisions. Keep ads away from:

- WBGT risk summary
- hydration and rest timers
- symptom checklist
- emergency/SOS modal
- 119 call action

The current placement keeps the free-app monetization visible, but only after the user has already seen the safety-critical information.

## Future Native App Hook

When this prototype moves to React Native, replace `AdMobBanner` with the app's banner component. Keep the same product rule:

```jsx
<BannerAd
  unitId={admobConfig.bannerUnitId}
  size={BannerAdSize.ANCHORED_ADAPTIVE_BANNER}
  requestOptions={{ requestNonPersonalizedAdsOnly: true }}
/>
```

Use a test ad unit in development if you connect a live SDK before release. Only switch live traffic to production ad unit IDs after App Store / Play Store readiness checks.

## Free And Paid Model

- Free: show the banner after safety actions.
- Paid or subscription: hide this component.
- Emergency state: never show an interstitial or rewarded ad.
