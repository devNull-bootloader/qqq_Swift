import SwiftUI

// MARK: - Note Model

struct Note: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var content: String
    var createdAt: Date = Date()
    var color: NoteColor = .yellow

    enum NoteColor: String, Codable, CaseIterable {
        case yellow, blue, green, pink, purple

        var background: Color {
            switch self {
            case .yellow: return Color(red: 60/255, green: 55/255, blue: 20/255)
            case .blue:   return Color(red: 20/255, green: 40/255, blue: 80/255)
            case .green:  return Color(red: 20/255, green: 60/255, blue: 30/255)
            case .pink:   return Color(red: 80/255, green: 20/255, blue: 60/255)
            case .purple: return Color(red: 40/255, green: 20/255, blue: 80/255)
            }
        }
        var accent: Color {
            switch self {
            case .yellow: return .yellow
            case .blue:   return .blue
            case .green:  return .green
            case .pink:   return Color.pink
            case .purple: return .purple
            }
        }
        var emoji: String {
            switch self {
            case .yellow: return "🟡"; case .blue: return "🔵"
            case .green:  return "🟢"; case .pink: return "🩷"
            case .purple: return "🟣"
            }
        }
    }
}

// MARK: - Notes Store

class NotesStore: ObservableObject {
    @Published var notes: [Note] = []
    private let key = "ms_notes_v1"

    init() { load() }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Note].self, from: data)
        else { return }
        notes = decoded
    }

    func save() {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func add() {
        notes.insert(Note(title: "Neue Notiz", content: ""), at: 0)
        save()
    }

    func delete(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        save()
    }

    func update(_ note: Note) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            notes[idx] = note
            save()
        }
    }
}

// MARK: - Notes View

struct NotesView: View {
    @StateObject private var store = NotesStore()
    @State private var editingNote: Note? = nil

    let columns = [GridItem(.adaptive(minimum: 160), spacing: 12)]

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    if store.notes.isEmpty {
                        VStack(spacing: 12) {
                            Spacer(minLength: 60)
                            Text("📝").font(.system(size: 48))
                            Text("Keine Notizen").font(.title2).foregroundColor(.appDim)
                            Text("Tippe auf +, um eine neue Notiz zu erstellen.")
                                .font(.system(size: 14))
                                .foregroundColor(.appDim)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(store.notes) { note in
                                NoteCard(note: note)
                                    .onTapGesture { editingNote = note }
                                    .contextMenu {
                                        Button(role: .destructive) { store.delete(note) } label: {
                                            Label("Löschen", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(12)
                    }
                }
                .background(Color.appBg)

                // Add button
                Button(action: {
                    store.add()
                    editingNote = store.notes.first
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 54, height: 54)
                        .background(Color.appAccent)
                        .clipShape(Circle())
                        .shadow(color: Color.appAccent.opacity(0.4), radius: 8)
                }
                .padding(20)
            }
            .navigationTitle("Notizen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("📝 Notizen")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.appText)
                }
            }
        }
        .sheet(item: $editingNote) { note in
            NoteEditor(note: note, store: store) {
                editingNote = nil
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Note Card

struct NoteCard: View {
    let note: Note
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(note.title.isEmpty ? "Unbenannte Notiz" : note.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.appText)
                .lineLimit(2)
            Divider().background(note.color.accent.opacity(0.5))
            Text(note.content.isEmpty ? "(Leer)" : note.content)
                .font(.system(size: 12))
                .foregroundColor(note.content.isEmpty ? .appDim : .appText)
                .lineLimit(6)
            Spacer(minLength: 0)
            Text(note.createdAt, style: .date)
                .font(.system(size: 10))
                .foregroundColor(.appDim)
        }
        .padding(10)
        .frame(minHeight: 120)
        .background(note.color.background)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(note.color.accent.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Note Editor

struct NoteEditor: View {
    @State var note: Note
    let store: NotesStore
    let onDismiss: () -> Void
    @FocusState private var contentFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TextField("Titel", text: $note.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.appText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.appCard)

                // Color picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Note.NoteColor.allCases, id: \.self) { c in
                            Button {
                                note.color = c
                            } label: {
                                Text(c.emoji)
                                    .font(.system(size: 22))
                                    .padding(6)
                                    .background(note.color == c ? Color.appCard2 : Color.clear)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8)
                                        .stroke(note.color == c ? c.accent : Color.clear, lineWidth: 2))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Color.appCard)

                Divider().background(Color.appBorder)

                TextEditor(text: $note.content)
                    .font(.system(size: 15))
                    .foregroundColor(.appText)
                    .scrollContentBackground(.hidden)
                    .background(note.color.background)
                    .padding(8)
                    .focused($contentFocused)

                Spacer(minLength: 0)
            }
            .background(Color.appBg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fertig") {
                        store.update(note)
                        onDismiss()
                    }
                    .foregroundColor(.appAccent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        store.delete(note)
                        onDismiss()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
