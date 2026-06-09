# VoiceprintNFT

VoiceprintNFT is an iOS app that turns a short voice recording into generative art for NFT preparation.

The app is built for worldwide release. The interface, App Store metadata, privacy copy, and App Review notes use English as the primary language.

VoiceprintNFT does not save the recorded audio file. It analyzes abstract voice features such as waveform, pitch, rhythm, silence, and energy, then uses those features to render dark neon line art with creature-like, human-like, and symbolic contours. Each result changes with the user's voice and the generated seed, so the same person can create different works each time.

## What The App Does

- Records a short voice sample through the microphone.
- Extracts voice features without keeping the original audio file.
- Generates a square artwork in a dark neon line-art style.
- Adds readable creature, animal, figure, eye, wing, mask, and symbolic motifs.
- Lets the user remix the same voice features with a new seed.
- Exports a PNG and NFT-style metadata JSON.
- Opens OpenSea so the user can continue the minting flow.
- Saves generated works in a local gallery.

## App Store Description Draft

VoiceprintNFT turns your voice into visual art.

Speak for a few seconds, and the app analyzes the shape of your voice: waveform, pitch, rhythm, silence, energy, and the small changes that make your voice feel personal. From those signals, VoiceprintNFT creates a unique neon artwork.

The result is not a photo, not a face filter, and not a template image. It is generative art drawn from the characteristics of your voice. Some works feel like animals, masks, wings, eyes, constellations, or human silhouettes. Others feel closer to modern line art or electronic poster art. The style changes every time, even when the same person records again.

VoiceprintNFT is designed for people who want personal artwork without using their face, body, or private photos. Your voice becomes the source material, but the app does not store the recorded audio file. It keeps only abstract values used to create the image, such as pitch range, rhythm density, silence pattern, and energy.

After generating an artwork, you can remix it, save it, and export the image with NFT-style metadata. The exported metadata includes traits based on the analyzed voice features, so the artwork has a clear connection to the voice that created it.

VoiceprintNFT also includes a simple NFT preparation flow. Export the PNG and metadata JSON, upload the image to IPFS, replace the image CID in the metadata, then use OpenSea or your preferred minting tool.

The app does not mint or sell NFTs inside the app. It prepares creative assets that you can use outside the app.

VoiceprintNFT is for creative expression, digital identity experiments, generative art, audio art, NFT preparation, and people who want to make something personal without using a camera.

Your voice becomes a visual signature.

## Subtitle Draft

Turn your voice into NFT art

## Promotional Text Draft

Create neon generative art from your voice. Record a short sample, generate a unique visual piece, export PNG and metadata, and prepare it for NFT minting.

## Keywords Draft

voice,nft,generative art,neon,abstract art,opensea,digital art,waveform,audio art,creator

## Privacy Notes

VoiceprintNFT uses the microphone only to analyze a short voice sample for artwork generation. The app does not store the recorded audio file. It stores generated artwork data and abstract voice features locally so users can view and export their generated works.

No tracking is used.

## Price And Availability

The planned base price is 100 JPY for Japan, with equivalent worldwide pricing generated in App Store Connect.

Price and availability are set in App Store Connect, not in the iOS code. Before submitting for review:

1. Open App Store Connect.
2. Select `VoiceprintNFT`.
3. Open Pricing and Availability.
4. Confirm the Paid Apps Agreement is active.
5. Set Japan as the base country or region.
6. Set the base price to 100 JPY.
7. Keep worldwide storefront availability enabled unless a specific country or region must be excluded.
8. Review Apple's automatically generated equivalent prices for other storefronts.

Apple's App Store Connect pricing help says paid apps require the Paid Apps Agreement, and pricing must be set before review. Apple can generate equivalent prices across storefronts from a selected base country or region.

## TestFlight

GitHub Actions can build and upload the app to TestFlight:

```sh
gh workflow run "VoiceprintNFT iOS Build" --ref codex/trouble-navi-testflight -f upload_testflight=true
```

The workflow checks the App Store Connect app record, creates or prepares signing assets, builds an archive, exports an IPA, uploads it to App Store Connect, and waits for TestFlight processing.

## App Store Connect Record

Use these values if the app record must be created manually:

- Name: `VoiceprintNFT`
- Bundle ID: `com.tokyonasu.voiceprintinstallation`
- SKU: `voiceprint-ios`
- Platform: iOS
- Primary language: English
- Availability: Worldwide

## Submission Checklist

- App name is `VoiceprintNFT`.
- Display name is `VoiceprintNFT`.
- Primary App Store metadata is in English.
- Microphone usage text explains that audio is used only for artwork generation.
- Privacy details say audio is not stored and tracking is not used.
- Price is set in App Store Connect with Japan as 100 JPY base pricing.
- Worldwide availability is enabled in App Store Connect.
- Latest TestFlight build is processed.
- Screenshots show recording, generated neon line art, NFT preparation, and gallery.
- App Review notes explain that NFT minting happens outside the app through OpenSea or the user's own tools.
