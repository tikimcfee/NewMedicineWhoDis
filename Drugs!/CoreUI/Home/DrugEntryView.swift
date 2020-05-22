//
//  DrugEntryView.swift
//  Drugs!
//
//  Created by Ivan Lugo on 9/8/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation
import SwiftUI

/**Model and View Extensions */
// ----------------------------------------------

struct InProgressEntry {
	var entryMap: [Drug:Int]
    var date: Date
    init(_ map: [Drug:Int] = [:], _ date: Date = Date()) {
        self.entryMap = map
        self.date = date
    }
}

extension View {
	func slightlyRaised() -> some View {
		return self
			.shadow(color: Color.gray, radius: 0.5, x: 0.0, y: 0.5)
			.padding(4.0)
	}
}


struct DrugEntryView: View {
    
    @Binding var inProgressEntry: InProgressEntry
    @State var currentSelectedDrug: Drug? = nil
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            DrugSelectionListView(
                inProgressEntry: $inProgressEntry,
                currentSelectedDrug: $currentSelectedDrug
            ).padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))

            DrugEntryNumberPad(
                inProgressEntry: $inProgressEntry,
                currentSelectedDrug: $currentSelectedDrug
            ).padding(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 8))

        }
        .background(Color(red: 0.8, green: 0.9, blue: 0.9))
        
    }
    
    func resetState(_ map: [Drug:Int] = [:]) {
        self.inProgressEntry.entryMap = map
    }
}

#if DEBUG

struct DrugEntryView_Preview: PreviewProvider {
    static var previews: some View {
        DrugEntryView(
            inProgressEntry: DefaultDrugList.$inProgressEntry,
            currentSelectedDrug: DefaultDrugList.shared.drugs[4]
        )
    }
}

#endif
