import Combine
import SwiftUI
import RealmSwift

struct ExistingEntryEditorView: View {
    
    @Binding var entryForEdit: RLM_MedicineEntry?
    @EnvironmentObject var editorState: ExistingEntryEditorState
    @EnvironmentObject var infoCalculator: AvailabilityInfoCalculator
    @Environment(\.presentationMode) private var presentationMode

	var body: some View {
		VStack(spacing: 0) {
            containerView
            timeSection
            HStack(spacing: 0) {
                saveButton
                cancelButton
            }
		}
        .onReceive(infoCalculator.infoPublisher) { info in
            log("Received new info in ExistingEntryEditorView")
            editorState.selectionModel.info = info.0
            editorState.selectionModel.availableDrugs = info.1
        }
        .alert(item: $editorState.editorError) { error in
			Alert(
				title: Text("Kaboom 2"),
                message: Text(error.localizedDescription),
				dismissButton: .default(Text("Well that sucks."))
			)
		}
	}

    private var containerView: some View {
        DrugSelectionContainerView(
            model: $editorState.selectionModel,
            countAutoUpdate: { [weak editorState] targetId, newCount in
                editorState?.onAutoUpdate(on: targetId, count: newCount)
            }
        )
        .boringBorder
        .padding(8)
    }

    private var timeSection: some View {
        VStack(alignment: .center, spacing: 0) {
            timePicker.screenWide
            if showTimeChange {
                updatedDifferenceView
            }
        }
        .screenWide
        .padding(16)
    }

    private var saveButton: some View {
        Components.fullWidthButton("Save changes", {
            editorState.saveEdits(infoCalculator) {
                presentationMode.wrappedValue.dismiss()
            }
        })
        .padding(4)
        .accessibility(identifier: EditEntryScreen.saveEditsButton.rawValue)
    }

    private var cancelButton: some View {
        Button(action: {
            entryForEdit = nil
        }) {
            Text("Cancel")
                .foregroundColor(Color.white)
                .padding(8)
                .frame(maxWidth: UIScreen.main.bounds.width)
        }
        .buttonStyle(ComponentFullWidthButtonStyle(
            pressedColor: Color.red.opacity(0.22),
            standardColor: Color.red.opacity(0.44)
        ))
        .padding(4)
        .accessibility(identifier: EditEntryScreen.cancelEditsButton.rawValue)
    }
	
	private var updatedDifferenceView: some View {
        VStack(alignment: .center) {
            Text("Was \(editorState.targetModel.date, formatter: DateFormatting.ShortDateShortTime)")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text("\(distance)")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
	}
	
	private var timePicker: some View {
        DatePicker(
            selection: $editorState.selectedDate,
            displayedComponents: .init(arrayLiteral: .date, .hourAndMinute),
            label: {
                
            }
        )
        .datePickerStyle(.compact)
        .labelsHidden()
        .padding(4)
        .accessibility(identifier: EditEntryScreen.datePickerButton.rawValue)
    }
}

// Data
extension ExistingEntryEditorView {
    var distance: String {
        let originalDate = editorState.targetModel.date
        let newDate = editorState.selectedDate
        return originalDate.distanceString(newDate)
    }
    
    var showTimeChange: Bool {
        let originalDate = editorState.targetModel.date
        let newDate = editorState.selectedDate
        return originalDate != newDate
    }
}

struct ScreenWide: ViewModifier {
    func body(content: Content) -> some View {
        return content.frame(maxWidth: UIScreen.main.bounds.width)
    }
}

struct BoringBorder: ViewModifier {
    public let stroke: Color
    public let background: Color
    public init(_ stroke: Color = Color.gray,
                _ background: Color = Color.clear) {
        self.stroke = stroke
        self.background = background
    }
    func body(content: Content) -> some View {
        return content.overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(stroke)
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

    func boringBorder(_ background: Color = .clear) -> some View {
        return modifier(BoringBorder(.gray, background))
    }
}

#if DEBUG
struct DrugEntryEditorView_Previews: PreviewProvider {
	static var previews: some View {
        let entry = RLM_MedicineEntry()
        let binding = WrappedBinding(Optional(entry))
		return ExistingEntryEditorView(
            entryForEdit: binding.binding
        )
        .environmentObject(ExistingEntryEditorState(entry))
        .environmentObject(
            AvailabilityInfoCalculator(manager: DefaultRealmManager())
        )
	}
}
#endif
