/**
 * Copyright IBM Corporation 2015
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation
import AVFoundation
import ObjectMapper

public class SpeechToText: NSObject, WatsonService {

    let authStrategy: AuthenticationStrategy
    private var session: AVCaptureSession?

    // TODO: comment this initializer
    public required init(authStrategy: AuthenticationStrategy) {
        self.authStrategy = authStrategy
    }

    // TODO: comment this initializer
    public convenience required init(username: String, password: String) {
        let authStrategy = BasicAuthenticationStrategy(tokenURL: Constants.tokenURL,
            serviceURL: Constants.serviceURL, username: username, password: password)
        self.init(authStrategy: authStrategy)
    }

    /**
     Transcribe pre-recorded audio data.

     - parameter audio: The pre-recorded audio data.
     - parameter settings: Settings to configure the SpeechToText service.
     - parameter onInterim: A callback function to execute with interim transcription results from
        the SpeechToText service. This callback function will be executed exactly once for each
        interim transcription result produced by the SpeechToText service. Note that the
        SpeechToText `interimResults` setting must be `true` for the service to return interim
        transcription results.
     - parameter completionHandler: A function that will be executed with all final transcription
        results from the SpeechToText service, or an error if an error occured.
     */
    public func transcribe(
        audio: NSData,
        settings: SpeechToTextSettings,
        onInterim: ((SpeechToTextResponse?, NSError?) -> Void)? = nil,
        completionHandler: ([SpeechToTextResponse]?, NSError?) -> Void)
    {
        // 1. Set up SpeechToText with client-specified settings.
        // 2. Send the given audio data to the SpeechToText service.
        // 3. Execute the onInterim function for each interim transcription result.
        // 4. Execute the completionHandler with all final transcription results (or an error).

        let urlString = Constants.websocketsURL(settings.model,
            learningOptOut: settings.learningOptOut)

        guard let url = NSURL(string: urlString) else {
            let domain = Constants.errorDomain
            let code = -1
            let description = "Could not parse SpeechToText WebSockets URL."
            let userInfo = [NSLocalizedDescriptionKey: description]
            let error = NSError(domain: domain, code: code, userInfo: userInfo)
            completionHandler(nil, error)
            return
        }

        guard let start = Mapper().toJSONString(settings) else {
            let domain = Constants.errorDomain
            let code = -1
            let description = "Could not serialize SpeechToTextSettings as JSON."
            let userInfo = [NSLocalizedDescriptionKey: description]
            let error = NSError(domain: domain, code: code, userInfo: userInfo)
            completionHandler(nil, error)
            return
        }

        guard let stop = Mapper().toJSONString(SpeechToTextStop()) else {
            let domain = Constants.errorDomain
            let code = -1
            let description = "Could not serialize SpeechToTextStop as JSON."
            let userInfo = [NSLocalizedDescriptionKey: description]
            let error = NSError(domain: domain, code: code, userInfo: userInfo)
            completionHandler(nil, error)
            return
        }

        let manager = WebSocketManager(authStrategy: authStrategy, url: url)
        manager.onText = { text in
            // TODO: parsed as interim response -> execute onInterim with result
            // TODO: parsed as final/last response -> execute completionHandler with result, disconnect
            // TODO: parsed as state -> ignore
            // TODO: otherwise -> execute completionHandler with error, disconnet
        }
        manager.onData = { data in }
        manager.onError = { error in
            manager.disconnect()
            completionHandler(nil, error)
        }
        
        manager.writeString(start)
        print(start) // TODO: debugging
        manager.writeData(audio)
        manager.writeString(stop)
    }

    /**
     StopRecording is a function that stops a microphone capture session. Microphone audio will no
     longer be streamed to the Speech to Text service after the capture session is stopped.
     */
    public typealias StopRecording = Void -> Void

    /**
     Start the microphone and stream the recording to the SpeechToText service for a live
     transcription. The microphone will stop recording after an end-of-speech event is detected
     by SpeechToText or the stopRecording function is executed.

     - parameter settings: The settings used to configure the SpeechToText service.
     - parameter onInterim: A callback function to execute with interim transcription results from
        the SpeechToText service. This callback function will be executed exactly once for each
        interim transcription result produced by the SpeechToText service. Note that the
        SpeechToText `interimResults` setting must be `true` for the service to return interim
        transcription results.
     - parameter completionHandler: A function that will be executed with all final transcription
        results from the SpeechToText service, or an error if an error occured.

     - returns: A stopRecording function that can be executed to stop the microphone's recording,
        wait for any remaining transcription results to be returned by the SpeechToText service,
        then execute the completionHandler.
     */
    public func transcribe(
        settings: SpeechToTextSettings,
        onInterim: ((SpeechToTextResponse?, NSError?) -> Void)? = nil,
        completionHandler: ([SpeechToTextResponse]?, NSError?) -> Void)
        -> StopRecording
    {
        // 1. Set up SpeechToText with client-specified settings.
        // 2. Start the microphone.
        // 3. Stream microphone audio to the SpeechToText service.
        // 4. Execute the onInterim function for each interim transcription result.
        // 5. Continue until:
        //      a. The client executes the stopRecording function, or
        //      b. The SpeechToText service detects an "end of speech" event, or
        //      c. The SpeechToText service times out (either session timeout or inactivity timeout).
        // 6. Execute the completionHandler with all final transcription results (or an error).

        print("1")

        let urlString = Constants.websocketsURL(settings.model,
            learningOptOut: settings.learningOptOut)

        print("2")

        guard let url = NSURL(string: urlString) else {
            let domain = Constants.errorDomain
            let code = -1
            let description = "Could not parse SpeechToText WebSockets URL."
            let userInfo = [NSLocalizedDescriptionKey: description]
            let error = NSError(domain: domain, code: code, userInfo: userInfo)
            completionHandler(nil, error)
            return { }
        }

        print("3")

        guard let start = Mapper().toJSONString(settings) else {
            let domain = Constants.errorDomain
            let code = -1
            let description = "Could not serialize SpeechToTextSettings as JSON."
            let userInfo = [NSLocalizedDescriptionKey: description]
            let error = NSError(domain: domain, code: code, userInfo: userInfo)
            completionHandler(nil, error)
            return { }
        }

        print("4")

        guard let stop = Mapper().toJSONString(SpeechToTextStop()) else {
            let domain = Constants.errorDomain
            let code = -1
            let description = "Could not serialize SpeechToTextStop as JSON."
            let userInfo = [NSLocalizedDescriptionKey: description]
            let error = NSError(domain: domain, code: code, userInfo: userInfo)
            completionHandler(nil, error)
            return { }
        }

        print("5")

        let manager = WebSocketManager(authStrategy: authStrategy, url: url)
        manager.onText = { text in
            // TODO: parsed as interim response -> execute onInterim with result
            // TODO: parsed as final/last response -> execute completionHandler with result, disconnect
            // TODO: parsed as state -> ignore
            // TODO: otherwise -> execute completionHandler with error, disconnet
        }
        manager.onData = { data in }
        manager.onError = { error in
            manager.disconnect()
            completionHandler(nil, error)
        }

        print("6")

        manager.writeString(start)

        print("7")

        session = AVCaptureSession()
        guard let session = session else {
            return { }
        }

        print("8")

        let microphoneDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        let microphoneInput = try? AVCaptureDeviceInput(device: microphoneDevice)
        if session.canAddInput(microphoneInput) {
            session.addInput(microphoneInput)
        }

        print("9")

        let output = AVCaptureAudioDataOutput()
        let queue = dispatch_queue_create("sample buffer_delegate", DISPATCH_QUEUE_SERIAL)
        let streamer = StreamAudioToWatson(manager: manager)
        output.setSampleBufferDelegate(streamer, queue: queue)
        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        print("10")

        session.startRunning()

        print("11")

        let stopRecording = {
            self.session?.stopRunning()
            manager.writeString(stop)
        }

        print("12")

        return stopRecording
    }
}

class StreamAudioToWatson: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {

    private var manager: WebSocketManager

    init(manager: WebSocketManager) {
        self.manager = manager
        print("initialized StreamAudioToWatson")
    }

    func captureOutput(
        captureOutput: AVCaptureOutput!,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,
        fromConnection connection: AVCaptureConnection!)
    {
        print("received buffer")

        guard CMSampleBufferDataIsReady(sampleBuffer) else {
            print("buffer not ready... returning")
            return
        }

        let emptyBuffer = AudioBuffer(mNumberChannels: 0, mDataByteSize: 0, mData: nil)
        var audioBufferList = AudioBufferList(mNumberBuffers: 1, mBuffers: emptyBuffer)
        var blockBuffer: CMBlockBuffer?
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            nil,
            &audioBufferList,
            sizeof(audioBufferList.dynamicType),
            nil,
            nil,
            UInt32(kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment),
            &blockBuffer)

        let audioData = NSMutableData()
        let audioBuffers = UnsafeBufferPointer<AudioBuffer>(start: &audioBufferList.mBuffers,
            count: Int(audioBufferList.mNumberBuffers))
        for audioBuffer in audioBuffers {
            audioData.appendBytes(audioBuffer.mData, length: Int(audioBuffer.mDataByteSize))
        }

        manager.writeData(audioData)
    }
}
