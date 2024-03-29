import Combine
import SwiftUI

struct ExistingEntryEditorView: View {

    @EnvironmentObject private var editorState: ExistingEntryEditorState
	@State var selectedDate: Date = Date()

    @Environment(\.presentationMode) var presentationMode
	
	var body: some View {
		VStack(spacing: 0) {
            containerView
            timeSection
            HStack(spacing: 0) {
                saveButton
                cancelButton
            }
		}
        .onDisappear(perform: { self.editorState.editorIsVisible = false })
        .alert(item: self.$editorState.editorError) { error in
			Alert(
				title: Text("Kaboom 2"),
                message: Text(error.localizedDescription),
				dismissButton: .default(Text("Well that sucks."))
			)
		}
	}

    private var containerView: some View {
        DrugSelectionContainerView(
            model: $editorState.selectionModel
        )
        .boringBorder
        .padding(8)
    }

    private var timeSection: some View {
        VStack(alignment: .center, spacing: 8) {
            timePicker
                .screenWide
            updatedDifferenceView
        }
        .screenWide
        .padding(4)
        .boringBorder
        .padding(8)
    }

    private var saveButton: some View {
        Components.fullWidthButton("Save changes", {
            editorState.saveEdits {
                presentationMode.wrappedValue.dismiss()
            }
        })
        .padding(4)
        .accessibility(identifier: EditEntryScreen.saveEditsButton.rawValue)
    }

    private var cancelButton: some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
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
        return HStack(alignment: .bottom) {
            Text("Was \(editorState.sourceEntry.date, formatter: DateFormatting.ShortDateShortTime)")
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
			Text("\(distance)")
				.font(.subheadline)
				.foregroundColor(.gray)

        }
	}
	
	private func time(_ title: String,
                      _ date: Date,
                      _ label: String) -> some View {
		return HStack(alignment: .firstTextBaseline) {
			Text(title)
				.font(.callout)
            Text("\(date, formatter: DateFormatting.ShortDateShortTime)")
                .accessibility(identifier: label)
				.font(.subheadline)
				.padding(.horizontal, 24)
				.frame(width: 196)
				.boringBorder
		}
	}
	
	private var timePicker: some View {
        DatePicker(
            selection: $editorState.selectionModel.inProgressEntry.date,
            displayedComponents: .init(arrayLiteral: .date, .hourAndMinute),
            label: { Group { EmptyView() } }
        )
        .datePickerStyle(WheelDatePickerStyle())
        .labelsHidden()
        .frame(height: 64)
        .padding(8)
        .contentShape(Rectangle()) // Without this, DatePicker touch area overlaps surrounding views
        .clipped()
        .compositingGroup()
        .accessibility(identifier: EditEntryScreen.datePickerButton.rawValue)	}
	
}

// Data
extension ExistingEntryEditorView {
    var errorBinding: Binding<AppStateError?> {
        return $editorState.editorError
    }

    var distance: String {
        let originalDate = editorState.sourceEntry.date
        let newDate = editorState.selectionModel.inProgressEntry.date
        return originalDate.distanceString(newDate)
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
        let op = makeTestMedicineOperator()
		return ExistingEntryEditorView()
            .environmentObject(
                ExistingEntryEditorState(
                    dataManager: op,
                    sourceEntry: MedicineEntry(Date(), [:])
                )
            )
	}
}
#endif
