import SwiftUI
import SwiftData
import PhotosUI

struct RegistrationWizardView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var model = RegistrationViewModel()
    let completion: (UUID) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(model.step + 1), total: 5).padding()
            Group {
                switch model.step {
                case 0: CategoryStep(selection: $model.categories)
                case 1: PhotoStep(items: $model.photoItems, photos: model.photos)
                case 2: DetailsStep(details: $model.details, categories: model.categories)
                case 3: LocationStep(location: $model.location)
                default: ConfirmationStep(model: model)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack {
                if model.step > 0 { Button("common.back") { model.step -= 1 }.frame(minWidth: 70, minHeight: 50) }
                Button {
                    if model.step == 1 { Task { await model.loadPhotos(); model.step += 1 } }
                    else if model.step < 4 { model.step += 1 }
                    else { do { completion(try model.save(in: context)) } catch { model.errorMessage = error.localizedDescription } }
                } label: {
                    Text(LocalizedStringKey(model.step == 4 ? "common.save" : "common.next"))
                }.buttonStyle(PrimaryButtonStyle()).disabled(!model.canContinue)
            }.padding()
        }
        .navigationTitle("registration.title")
        .navigationBarTitleDisplayMode(.inline)
        .alert("error.title", isPresented: .constant(model.errorMessage != nil)) { Button("common.ok") { model.errorMessage = nil } } message: { Text(model.errorMessage ?? "") }
    }
}

private struct CategoryStep: View {
    @Binding var selection: Set<LostItemCategory>
    let columns = [GridItem(.adaptive(minimum: 100))]
    var body: some View { ScrollView { VStack(alignment: .leading) { Text("registration.what").font(.title.bold()); Text("registration.multiple").foregroundStyle(.secondary); LazyVGrid(columns: columns) { ForEach(LostItemCategory.allCases) { item in Button { if selection.contains(item) { selection.remove(item) } else { selection.insert(item) } } label: { VStack { Image(systemName: item.icon).font(.title); Text(item.title).font(.caption).multilineTextAlignment(.center) }.frame(maxWidth: .infinity, minHeight: 88).background(selection.contains(item) ? Color.supportBlue.opacity(0.18) : Color.clear, in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(selection.contains(item) ? Color.brandBlue : Color.secondary.opacity(0.25), lineWidth: selection.contains(item) ? 2 : 1)) }.buttonStyle(.plain).accessibilityAddTraits(selection.contains(item) ? .isSelected : []) } } }.padding() } }
}

private struct PhotoStep: View {
    @Binding var items: [PhotosPickerItem]; let photos: [Data]
    var body: some View { VStack(spacing: 24) { Text("registration.photos").font(.title.bold()); PhotosPicker(selection: $items, maxSelectionCount: 3, matching: .images) { Label("registration.choosePhotos", systemImage: "photo.on.rectangle.angled").frame(minHeight: 56) }.buttonStyle(.borderedProminent); Text("registration.photoPrivacy").font(.footnote).foregroundStyle(.secondary); if !photos.isEmpty { Text("registration.photoCount \(photos.count)") } ; Spacer() }.padding() }
}

private struct DetailsStep: View {
    @Binding var details: ItemDescription; let categories: Set<LostItemCategory>
    var body: some View {
        Form {
            Section("registration.details") {
                TextField("field.color", text: $details.color)
                TextField("field.brand", text: $details.brand)
                if categories.contains(.smartphone) {
                    TextField("field.model", text: $details.model)
                }
                if categories.contains(.passport) || categories.contains(.smartphone) {
                    TextField("field.lastFour", text: $details.identifierLastFour)
                        .keyboardType(.numberPad)
                }
                TextField("field.features", text: $details.details, axis: .vertical)
                    .lineLimit(3...6)
            }
            Section {
                Text("registration.optional")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct LocationStep: View {
    @Binding var location: LostLocation
    var body: some View { Form { Section("registration.where") { Picker("field.locationType", selection: $location.category) { ForEach(LocationCategory.allCases) { Label($0.title, systemImage: $0.icon).tag($0) } }; DatePicker("field.lastSeen", selection: $location.lastSeenAt); TextField("field.placeName", text: $location.name); TextField("field.locationDetail", text: $location.detail, axis: .vertical) } } }
}

private struct ConfirmationStep: View {
    @ObservedObject var model: RegistrationViewModel
    var body: some View {
        List {
            Section("registration.summary") {
                LabeledContent("registration.what", value: model.categories.map(\.title).sorted().joined(separator: ", "))
                LabeledContent("registration.where", value: model.location.name.isEmpty ? model.location.category.title : model.location.name)
                LabeledContent("field.lastSeen", value: model.location.lastSeenAt.formatted(date: .abbreviated, time: .shortened))
            }
            Section {
                Text("registration.saveNote")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
