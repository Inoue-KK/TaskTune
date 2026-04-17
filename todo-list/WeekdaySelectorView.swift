//
//  WeekdaySelectorView.swift
//  todo-list
//
//  Created by 井上京佳 on 2026/04/16.
//

import SwiftUI

struct WeekdaySelectorView: View {
    @Binding var selectedWeekdays: [Int]

    private let symbols = Calendar.current.shortWeekdaySymbols  // ["Sun", "Mon", ...]
    @State private var pressedWeekday: Int? = nil

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<7) { index in
                dayButton(weekday: index + 1)
            }
        }
        .padding(.horizontal, 4)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func dayButton(weekday: Int) -> some View {
        let isSelected = selectedWeekdays.contains(weekday)
        let isPressed = pressedWeekday == weekday

        return Text(String(symbols[weekday - 1].prefix(2)))
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .contentShape(Circle())
            .glassEffect(isSelected ? .regular.tint(Color.blue) : .regular, in: Circle())
            .scaleEffect(isPressed ? 1.18 : (isSelected ? 1.1 : 1.0))
            .animation(.spring(duration: 0.2, bounce: 0.6), value: isPressed)
            .animation(.spring(duration: 0.35, bounce: 0.55), value: isSelected)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard pressedWeekday != weekday else { return }
                        pressedWeekday = weekday
                    }
                    .onEnded { _ in
                        guard pressedWeekday == weekday else { return }
                        pressedWeekday = nil
                        if isSelected {
                            guard selectedWeekdays.count > 1 else { return }
                            selectedWeekdays.removeAll { $0 == weekday }
                        } else {
                            selectedWeekdays.append(weekday)
                        }
                    }
            )
    }
}
