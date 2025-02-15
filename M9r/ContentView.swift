/*
 * M9r
 * Copyright (C) 2025  MAINTAINERS
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        HSplitView {
            NavigationSplitView {
                SourceList()
            } detail: {
                NavigationStack {
                    VStack {
                        Text("No Selection")
                            .font(.largeTitle)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            QueueList()
                .frame(minWidth: 100, idealWidth: 200, maxWidth: 250)
        }
        .preferredColorScheme(.dark)
    }
}
