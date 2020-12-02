import Combine
import SwiftUI

struct DrugEntryEditorView: View {
	
	@EnvironmentObject private var editorState: DrugEntryEditorState
	@State var selectedDate: Date = Date()
	
	var body: some View {
		return VStack(spacing: 0) {
			DrugSelectionContainerView()
            .frame(height: 300)
			.darkBoringBorder
			.padding(8)
            .environmentObject(editorState.entryPadState)
			
			VStack(alignment: .trailing, spacing: 8) {
                time("Original Time:",
                     editorState.sourceEntry.date,
                     EditEntryScreen.oldTimeLabel.rawValue)
                time("New Time:",
                     editorState.inProgressEntry.date,
                     EditEntryScreen.newTimeLabel.rawValue)
				timePicker
					.screenWide
					.darkBoringBorder
				updatedDifferenceView
			}
            .screenWide
			.padding(8)
			
            Components.fullWidthButton("Save changes", editorState.saveEdits)
            .padding(8)
            .accessibility(identifier: EditEntryScreen.saveEditsButton.rawValue)
		}
        .background(Color(red: 0.8, green: 0.9, blue: 0.9))
        .onDisappear(perform: { self.editorState.editorIsVisible = false })
        .alert(item: self.$editorState.editorError) { error in
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
	
	private func time(_ title: String,
                      _ date: Date,
                      _ label: String) -> some View {
		return HStack(alignment: .firstTextBaseline) {
			Text(title)
				.font(.callout)
			Text("\(date, formatter: dateTimeFormatter)")
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
                selection: $editorState.inProgressEntry.date,
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
            .distanceString($editorState.inProgressEntry.date.wrappedValue)
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
		return DrugEntryEditorView().environmentObject(makeTestMedicineOperator())
	}
}
#endif