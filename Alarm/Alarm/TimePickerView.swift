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
    @Binding var hasAlarmFiredThisMinute: Bool //new
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
            
            
            Button(action: {
                alarmTime = selectedTime
                isAlarmOn = true
                hasAlarmFiredThisMinute = false // reset so new alarm can fire
                isPresented = false
            }) {
                Text("Set Alarm")
                    .font(.headline)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundStyle(.black)
            }
            .frame(width: 290, height: 66) // This frame now applies to the whole button
            .background(Color(red:255/255, green:117/255, blue:24/255).opacity(0.5))
            .cornerRadius(12)
        }
    }
}
