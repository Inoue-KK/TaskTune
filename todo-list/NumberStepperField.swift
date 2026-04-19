//
//  NumberStepperField.swift
//  todo-list
//
//  Created by 井上京佳 on 2026/04/18.
//

import SwiftUI

/// +/- ボタン付きの数値入力フィールド。中央の数字をタップするとキーボードで直接入力できる。
struct NumberStepperField: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    @State private var text: String = ""
    @State private var minusPressed = false
    @State private var plusPressed = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "minus")
                .font(.body.weight(.medium))
                .frame(width: 36, height: 36)
                .contentShape(Circle())
                .glassEffect(.regular, in: Circle())
                .scaleEffect(minusPressed ? 1.15 : 1.0)
                .animation(.spring(duration: 0.2, bounce: 0.5), value: minusPressed)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in guard !minusPressed else { return }; minusPressed = true }
                        .onEnded { _ in
                            minusPressed = false
                            value = max(range.lowerBound, value - 1)
                            text = "\(value)"
                        }
                )

            TextField("", text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.body.monospacedDigit())
                .frame(width: 44)
                .focused($isFocused)
                .onAppear { text = "\(value)" }
                .onChange(of: text) { _, newVal in
                    let digits = newVal.filter { $0.isNumber }
                    if digits != newVal { text = digits; return }
                    if let n = Int(digits), n >= range.lowerBound, n <= range.upperBound {
                        value = n
                    }
                }
                .onChange(of: isFocused) { _, focused in
                    if !focused { commit() }
                }

            Image(systemName: "plus")
                .font(.body.weight(.medium))
                .frame(width: 36, height: 36)
                .contentShape(Circle())
                .glassEffect(.regular, in: Circle())
                .scaleEffect(plusPressed ? 1.15 : 1.0)
                .animation(.spring(duration: 0.2, bounce: 0.5), value: plusPressed)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in guard !plusPressed else { return }; plusPressed = true }
                        .onEnded { _ in
                            plusPressed = false
                            value = min(range.upperBound, value + 1)
                            text = "\(value)"
                        }
                )
        }
    }

    private func commit() {
        if let n = Int(text) {
            value = max(range.lowerBound, min(range.upperBound, n))
        }
        text = "\(value)"
    }
}
