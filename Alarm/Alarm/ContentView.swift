import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var currentTime: String = ""
    @State private var showTimePicker = false
    @State private var alarmTime: Date? = nil
    @State private var isAlarmOn = false
    @State private var isAlarmFiring = false
    @State private var backgroundColor: Color = .white
    @State private var soundClassifier = SoundClassifier()

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var player: AVAudioPlayer?

    init() {
        // Microphone permission check
        AVAudioSession.sharedInstance().requestRecordPermission { response in
            if response {
                print("Microphone access granted.")
            } else {
                print("Microphone access denied.")
            }
        }

        if let soundURL = Bundle.main.url(forResource: "alarmSound", withExtension: "mp3") {
            do {
                player = try AVAudioPlayer(contentsOf: soundURL)
                player?.numberOfLoops = -1
            } catch {
                print("Error loading sound: \(error)")
            }
        } else {
            print("alarmSound.mp3 not found")
        }
    }

    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 44/255, green: 56/255, blue: 99/255).opacity(0.62)
)
                .frame(width:290, height:153)
                //.background(Color(red: 44.0, green: 56.0, blue: 99.0).opacity(0.62))
                .overlay(alignment:.center) {
                    VStack{
                        Text("Current time")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.top)
                        Text(currentTime)
                            .font(.largeTitle)
                            .foregroundStyle(.white)
                            .padding()
                        
                        
                    }
                }
        
                

            if let alarmTime = alarmTime {
                Text("1 Alarm Set")
                    .foregroundStyle(.black)
                HStack {
                    Text(alarmFormatter.string(from: alarmTime))
                        .foregroundStyle(.black)
                    Toggle("", isOn: $isAlarmOn)
                        .labelsHidden()
                }
                .padding()
            } else {
                Text("No Alarms set")
                    .foregroundStyle(.black)
            }

            
            Button(action: {
                showTimePicker = true
            }) {
                Text("Set Alarm")
                    .font(.headline)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundStyle(.black)
            }
            .frame(width: 290, height: 66) // This frame now applies to the whole button
            .background(Color(red:255/255, green:117/255, blue:24/255).opacity(0.2))
            .cornerRadius(12)

                
            .sheet(isPresented: $showTimePicker) {
                TimePickerView(alarmTime: $alarmTime, isPresented: $showTimePicker, isAlarmOn: $isAlarmOn)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
        .onAppear(perform: updateTime)
        .onReceive(timer) { _ in
            updateTime()
            checkAlarm()
        }
    }

    func updateTime() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        currentTime = formatter.string(from: Date())
    }

    func checkAlarm() {
        guard let alarmTime = alarmTime, isAlarmOn else {
            stopAlarm()
            return
        }

        let now = Date()
        let calendar = Calendar.current
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        let alarmComponents = calendar.dateComponents([.hour, .minute], from: alarmTime)

        if nowComponents.hour == alarmComponents.hour && nowComponents.minute == alarmComponents.minute {
            startAlarm()
        } else if !isAlarmFiring {
            stopAlarm()
        }
    }

    func startAlarm() {
        if !isAlarmFiring {
            isAlarmFiring = true
            player?.play()
            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                backgroundColor = .red
            }

            // Start listening for running water
            soundClassifier.startListening()
            soundClassifier.onWaterDetected = {
                stopAlarm()
            }
        }
    }

    func stopAlarm() {
        if isAlarmFiring {
            isAlarmFiring = false
            player?.stop()
            player?.currentTime = 0
            withAnimation {
                backgroundColor = .white
            }

            // Stop listening when alarm turns off
            soundClassifier.stopListening()
        }
    }

    private var alarmFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

