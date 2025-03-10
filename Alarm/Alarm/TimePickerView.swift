//
//  TimePickerView.swift
//  Alarm
//
//  Created by Ivan  Shi on 2/26/25.
//
import SwiftUI

struct TimePickerView: View {
    @Binding var alarmTime: Date?
    @Binding var isPresented: Bool
    @Binding var isAlarmOn: Bool
    @State private var selectedTime = Date()
    
    var body: some View {
        VStack {
            Text("Set Alarm for:")
                .font(.headline)
                .padding()
            
            DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .padding()
            
            Button("Set Alarm") {
                alarmTime = selectedTime
                isAlarmOn = true
                isPresented = false
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
        }
    }
}
