//
//  ContentView.swift
//  Alarm
//
//  Created by Edmond Li on 2/22/25.
//
import SwiftUI

struct ContentView: View {
    @State private var currentTime: String = ""
    @State private var showTimePicker = false
    @State private var alarmTime: Date? = nil
    @State private var isAlarmOn = false
    
    var body: some View {
        VStack {
            Text("Current time")
                .font(.headline)
                .foregroundColor(.black)
                .padding(.top)
            
            Text(currentTime)
                .font(.largeTitle)
                .foregroundColor(.black)
                .padding()
            
            if let alarmTime = alarmTime {
                Text("1 Alarm Set")
                    .foregroundColor(.black)
                HStack {
                    Text(alarmFormatter.string(from: alarmTime))
                        .foregroundColor(.black)
                    Toggle("", isOn: $isAlarmOn)
                        .labelsHidden()
                }
                .padding()
            } else {
                Text("No Alarms set")
                    .foregroundColor(.black)
            }
            
            Button(action: {
                showTimePicker = true
            }) {
                Text("Set Alarm")
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(.black)
            }
            .sheet(isPresented: $showTimePicker) {
                TimePickerView(alarmTime: $alarmTime, isPresented: $showTimePicker, isAlarmOn: $isAlarmOn)
            }
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .onAppear(perform: updateTime)
    }
    
    func updateTime() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        currentTime = formatter.string(from: Date())
    }
    
    private var alarmFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}
