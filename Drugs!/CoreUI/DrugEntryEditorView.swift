import Foundation
import SwiftUI

public final class DrugEntryEditorState: ObservableObject {
    private let dataManager: MedicineLogDataManager

    @Published public var editorIsVisible: Bool = false
    @Published public var entryPadState: DrugSelectionPadViewState
    @Published var editorError: AppStateError? = nil
    @Published var inProgressEntry: InProgressEntry = InProgressEntry()
    @Published var sourceEntry: MedicineEntry = DefaultDrugList.shared.randomEntry() {
        willSet {
            inProgressEntry = InProgressEntry(newValue.drugsTaken, newValue.date)
        }
    }
	
    public init(dataManager: MedicineLogDataManager) {
        self.dataManager = dataManager
        self.entryPadState = DrugSelectionPadViewState(dataManager: dataManager)
	}

    func saveEdits() {
        guard sourceEntry.date != inProgressEntry.date
                && sourceEntry.drugsTaken != inProgressEntry.entryMap
        else { return }

        sourceEntry.date = inProgressEntry.date
        sourceEntry.drugsTaken = inProgressEntry.entryMap

        dataManager.updateEntry(updatedEntry: sourceEntry) { result in
            switch result {
                case .success:
                    self.editorIsVisible = false
                    self.editorError = nil

                case .failure(let error):
                    self.editorError = error as? AppStateError ?? .updateError
            }
        }
    }
}

struct DrugEntryEditorView: View {
	
	@EnvironmentObject private var editorState: DrugEntryEditorState
	@State var selectedDate: Date = Date()
	
	var body: some View {
		return VStack(spacing: 0) {
			DrugSelectionPadView()
            .frame(height: 300)
			.darkBoringBorder
			.padding(8)
            .environmentObject(editorState.entryPadState)
			
			VStack(alignment: .trailing, spacing: 8) {
                time("Original Time:", editorState.sourceEntry.date)
                time("New Time:", editorState.inProgressEntry.date)
				timePicker
					.screenWide
					.darkBoringBorder
				updatedDifferenceView
			}
            .screenWide
			.padding(8)
			
            Components.fullWidthButton("Save changes", editorState.saveEdits).padding(8)
		}.background(Color(red: 0.8, green: 0.9, blue: 0.9))
		.alert(item: $editorState.editorError) { error in
			Alert(
				title: Text("Kaboom 2"),
                message: Text(error.localizedDescription),
				dismissButton: .default(Text("Well that sucks."))
			)
		}
	}
	
	private var updatedDifferenceView: some View {
		return HStack(alignment: .firstTextBaseline) {
			Text(distance)
				.font(.subheadline)
				.foregroundColor(.gray)
				.padding(.horizontal, 24)
		}
	}
	
	private func time(_ title: String, _ date: Date) -> some View {
		return HStack(alignment: .firstTextBaseline) {
			Text(title)
				.font(.callout)
			Text("\(date, formatter: dateTimeFormatter)")
				.font(.subheadline)
				.padding(.horizontal, 24)
				.frame(width: 196)
				.boringBorder
		}
	}
	
	private var timePicker: some View {
		VStack {
			DatePicker(
				selection: entryBinding.date,
				displayedComponents: .init(arrayLiteral: .date,.hourAndMinute),
				label: { EmptyView() }
			).labelsHidden()
			.frame(height: 128)
			.clipped()
		}
	}
	
}

// Data
extension DrugEntryEditorView {
    var entryBinding: Binding<InProgressEntry> {
        return $editorState.inProgressEntry
    }

    var errorBinding: Binding<AppStateError?> {
        return $editorState.editorError
    }

    var distance: String {
        return editorState.sourceEntry.date
            .distanceString(entryBinding.date.wrappedValue)
    }
}

struct ScreenWide: ViewModifier {
    func body(content: Content) -> some View {
        return content.frame(maxWidth: UIScreen.main.bounds.width)
    }
}

struct BoringBorder: ViewModifier {
    public let color: Color
    public init(_ color: Color = Color.gray) {
        self.color = color
    }
    func body(content: Content) -> some View {
        return content.overlay(
            RoundedRectangle(cornerRadius: 4).stroke(color)
        )
    }
}

extension View {
    var boringBorder: some View {
        return modifier(BoringBorder())
    }

    var darkBoringBorder: some View {
        return modifier(BoringBorder(.black))
    }

    var screenWide: some View {
        return modifier(ScreenWide())
    }
}

#if DEBUG
struct DrugEntryEditorView_Previews: PreviewProvider {
	static var previews: some View {
		return DrugEntryEditorView().environmentObject(makeTestMedicineOperator())
	}
}
#endif
