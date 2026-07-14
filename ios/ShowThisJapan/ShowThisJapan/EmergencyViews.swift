import MapKit
import SwiftUI

struct EmergencyMenuView: View {
    var body: some View {
        List {
            Section("Call in Japan") { EmergencyCallRow(title:"Police",number:"110",icon:"shield.fill"); EmergencyCallRow(title:"Ambulance / Fire",number:"119",icon:"cross.case.fill") }
            Section("Help") {
                NavigationLink("Show My Emergency Information", destination: EmergencyProfileView()).accessibilityLabel("Show my emergency information")
                NavigationLink("Current Location", destination: CurrentLocationView())
            }
            Section("Emergency phrases") { NavigationLink("Disaster and emergency cards", destination: EmergencyPhraseList()) }
        }.navigationTitle("Emergency").tint(.red)
    }
}

struct EmergencyCallRow: View {
    @Environment(\.openURL) var openURL; let title:String; let number:String; let icon:String; @State private var confirm=false
    var body: some View { Button { confirm=true } label: { Label("\(title) — \(number)",systemImage:icon).font(.title3).frame(minHeight:52) }.confirmationDialog("Call a Japanese emergency number. Use this only in an emergency.",isPresented:$confirm,titleVisibility:.visible){Button("Call \(number)",role:.destructive){if let url=URL(string:"tel://\(number)"){openURL(url)}};Button("Cancel",role:.cancel){}} }
}

struct EmergencyPhraseList: View {
    @EnvironmentObject var app:AppViewModel
    var body: some View { List { PhraseRows(cards:app.cards.filter{$0.isEmergency}) }.navigationTitle("Emergency cards") }
}

struct EmergencyProfileView: View {
    @EnvironmentObject var app:AppViewModel; @State private var editing=false
    var rows:[(String,String)] { [("氏名 / Name",app.profile.fullName),("国籍 / Nationality",app.profile.nationality),("年齢 / Age",app.profile.age),("性別 / Gender",app.profile.gender),("宿泊先 / Hotel",app.profile.hotelName),("緊急連絡先 / Emergency contact",app.profile.emergencyContactPhone),("血液型 / Blood type",app.profile.bloodType),("アレルギー / Allergies",app.profile.allergies),("持病 / Conditions",app.profile.medicalConditions),("服用薬 / Medications",app.profile.medications),("食事制限 / Dietary restrictions",app.profile.dietaryRestrictions),("必要な配慮 / Accessibility",app.profile.accessibilityNeeds),("保険会社 / Insurer",app.profile.insuranceCompany),("保険番号 / Policy number",app.profile.insurancePolicyNumber)] }
    var body: some View { ScrollView { VStack(alignment:.leading,spacing:18){ Text("私は\(app.language.name)を話します。日本語は話せません。").font(.title.bold()); ForEach(Array(rows.enumerated()),id:\.offset){_,row in if !row.1.isEmpty { VStack(alignment:.leading){Text(row.0).font(.headline).foregroundStyle(.secondary);Text(row.1).font(.title2)}.accessibilityElement(children:.combine) } }; if rows.allSatisfy({$0.1.isEmpty}) { ContentUnavailableView("No emergency information",systemImage:"person.text.rectangle",description:Text("Add details before your trip.")) } }.padding() }.navigationTitle("Emergency Information").toolbar{Button("Edit"){editing=true}}.sheet(isPresented:$editing){ProfileEditor(profile:$app.profile)} }
}

struct ProfileEditor: View {
    @Environment(\.dismiss) var dismiss; @Binding var profile:EmergencyProfile
    var body: some View { NavigationStack { Form { Section("Identity"){TextField("Full name",text:$profile.fullName);TextField("Nationality",text:$profile.nationality);TextField("Age",text:$profile.age).keyboardType(.numberPad);TextField("Gender",text:$profile.gender)};Section("Stay and contact"){TextField("Hotel",text:$profile.hotelName);TextField("Hotel address",text:$profile.hotelAddress);TextField("Emergency contact name",text:$profile.emergencyContactName);TextField("Emergency contact phone",text:$profile.emergencyContactPhone).keyboardType(.phonePad)};Section("Medical"){TextField("Blood type",text:$profile.bloodType);TextField("Allergies",text:$profile.allergies,axis:.vertical);TextField("Medical conditions",text:$profile.medicalConditions,axis:.vertical);TextField("Medications",text:$profile.medications,axis:.vertical)};Section("Other"){TextField("Dietary restrictions",text:$profile.dietaryRestrictions,axis:.vertical);TextField("Accessibility needs",text:$profile.accessibilityNeeds,axis:.vertical);TextField("Insurance company",text:$profile.insuranceCompany);TextField("Policy number",text:$profile.insurancePolicyNumber)}}.navigationTitle("Emergency Profile").toolbar{ToolbarItem(placement:.confirmationAction){Button("Done"){dismiss()}}} } }
}

struct CurrentLocationView: View {
    @StateObject private var service=LocationService(); @Environment(\.openURL) var openURL
    var coordinate:CLLocationCoordinate2D { service.location?.coordinate ?? .init(latitude:35.6812,longitude:139.7671) }
    var text:String { guard let l=service.location else{return ""};return "\(service.address)\nLatitude: \(l.coordinate.latitude)\nLongitude: \(l.coordinate.longitude)\nUpdated: \(l.timestamp.formatted())" }
    var body: some View { ScrollView { VStack(spacing:18){ Map(initialPosition:.region(.init(center:coordinate,span:.init(latitudeDelta:0.01,longitudeDelta:0.01)))){if service.location != nil{Marker("Current location",coordinate:coordinate)}}.frame(height:300).clipShape(RoundedRectangle(cornerRadius:16)); if let error=service.errorMessage{Text(error).foregroundStyle(.red)}; if service.location == nil{Button("Get current location"){service.request()}.buttonStyle(PrimaryButtonStyle())}else{Text(text).font(.title3).textSelection(.enabled);ShareLink(item:text){Label("Share location",systemImage:"square.and.arrow.up").frame(maxWidth:.infinity)}.buttonStyle(.borderedProminent);Button("Open in Apple Maps"){openURL(URL(string:"https://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)")!)}.buttonStyle(.bordered)} }.padding() }.navigationTitle("Current Location") }
}

struct SettingsView: View {
    @EnvironmentObject var app:AppViewModel; @AppStorage("didOnboard") var didOnboard=true; @State private var erase=false
    var body: some View { Form { Section("Language"){Picker("Language",selection:$app.language){ForEach(AppLanguage.allCases){Text($0.name).tag($0)}}};Section("Your data"){NavigationLink("Emergency profile",destination:EmergencyProfileView());Button("Clear recent cards",role:.destructive){app.recentIDs=[]};Button("Clear favorites",role:.destructive){app.favorites=[]};Button("Delete emergency information",role:.destructive){app.profile = .init()}};Section("Privacy"){Text("Your profile and activity stay on this device. The app sends no personal or medical information to a server.")}}.navigationTitle("Settings") }
}

#Preview { NavigationStack { EmergencyMenuView() }.environmentObject(AppViewModel()) }
#Preview("Profile") { NavigationStack { EmergencyProfileView() }.environmentObject(AppViewModel()) }
#Preview("Location") { NavigationStack { CurrentLocationView() } }
#Preview("Settings") { NavigationStack { SettingsView() }.environmentObject(AppViewModel()) }
