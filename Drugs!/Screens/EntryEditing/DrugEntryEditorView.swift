import Combine
import SwiftUI

struct DrugEntryEditorView: View {

    @EnvironmentObject private var editorState: DrugEntryEditorState
	@State var selectedDate: Date = Date()

    @Environment(\.presentationMode) var presentationMode
	
	var body: some View {
		VStack(spacing: 0) {
			timeSection
            containerView
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
        .darkBoringBorder
        .padding(8)
    }

    private var timeSection: some View {
        VStack(alignment: .trailing, spacing: 8) {
            time("Original Time:",
                 editorState.sourceEntry.date,
                 EditEntryScreen.oldTimeLabel.rawValue)
            time("New Time:",
                 editorState.selectionModel.inProgressEntry.date,
                 EditEntryScreen.newTimeLabel.rawValue)
            timePicker
                .screenWide
                .darkBoringBorder
            updatedDifferenceView
        }
        .screenWide
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
		return HStack(alignment: .firstTextBaseline) {
			Text(distance)
				.font(.subheadline)
				.foregroundColor(.gray)
				.padding(.horizontal, 24)
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
		VStack {
			DatePicker(
                selection: $editorState.selectionModel.inProgressEntry.date,
				displayedComponents: .init(arrayLiteral: .date, .hourAndMinute),
				label: { EmptyView() }
			)
            .datePickerStyle(WheelDatePickerStyle())
            .labelsHidden()
			.frame(height: 64)
			.clipped()
            .accessibility(identifier: EditEntryScreen.datePickerButton.rawValue)
        }
	}
	
}

// Data
extension DrugEntryEditorView {
    var errorBinding: Binding<AppStateError?> {
        return $editorState.editorError
    }

    var distance: String {
        return editorState.sourceEntry.date
            .distanceString($editorState.selectionModel.inProgressEntry.date.wrappedValue)
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
		return DrugEntryEditorView()
            .environmentObject(
                DrugEntryEditorState(
                    dataManager: op,
                    sourceEntry: MedicineEntry(Date(), [:])
                )
            )
	}
}
#endif
