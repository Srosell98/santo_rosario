import SwiftUI
import Combine

struct HomeTabView: View {
    @AppStorage("prayerMode") var prayerMode: String = "complete" // default is Modo Completo

    var body: some View {
        VStack {
            Spacer(minLength: 20)

            // Botón de acción único - Empezar
            Button(action: { onPlayComplete() }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Empezar")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(red: 0.62, green: 0.42, blue: 0.25))
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
}

struct SettingsView: View {
    @AppStorage("prayerMode") var prayerMode: String = "complete" // default is Modo Completo

    var body: some View {
        Form {
            Section("Modo de Oración") {
                Picker("Tipo de oración", selection: $prayerMode) {
                    Text("Modo Completo").tag("complete")
                    Text("Modo Responsorial").tag("responsorial")
                }
            }
            Section("Otros") {
                // other settings here...
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        HomeTabView()
            .onAppear {
                // Other initializations
                onPlayComplete(prayerMode: prayerMode) // Pass updated prayer mode
            }
    }
}