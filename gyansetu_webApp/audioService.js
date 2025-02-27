// Import axios with proper URL
import axios from 'https://cdn.jsdelivr.net/npm/axios@1.6.7/+esm';

class AudioService {
    constructor() {
        this.mediaRecorder = null;
        this.audioChunks = [];
        this.stream = null;
        this.isRecording = false;
        this.speechRecognition = null;
        this.audioContext = null;
        this.audioProcessor = null;
        this.vadTimeout = null;
        this.silenceThreshold = -50;
        this.silenceDuration = 1500;
        this.lastVoiceDetection = Date.now();
        this.isSpeaking = false;
        this.isRecognitionActive = false;
        this.isSecureContext = window.isSecureContext;
        this.apiBaseUrl = 'http://localhost:3000/api';
        this.currentAudio = null;
        this.isProcessing = false;
        this.lastTranscript = '';
        this.transcriptTimeout = null;
        this.setupAudioContext();
        this.setupSpeechRecognition();
    }

    setupAudioContext() {
        try {
            this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
        } catch (error) {
            console.error('Audio Context not supported:', error);
        }
    }

    setupSpeechRecognition() {
        try {
            const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
            if (SpeechRecognition) {
                this.speechRecognition = new SpeechRecognition();
                this.speechRecognition.continuous = true;
                this.speechRecognition.interimResults = true;
                this.setupSpeechRecognitionHandlers();
            } else {
                throw new Error('Speech Recognition not supported in this browser');
            }
        } catch (error) {
            console.error('Error setting up speech recognition:', error);
        }
    }

    setupSpeechRecognitionHandlers() {
        if (!this.speechRecognition) return;

        this.speechRecognition.onresult = (event) => {
            if (this.isSpeaking) return;

            const transcript = Array.from(event.results)
                .map(result => result[0].transcript)
                .join(' ');

            if (event.results[event.results.length - 1].isFinal) {
                if (this.transcriptTimeout) {
                    clearTimeout(this.transcriptTimeout);
                }

                this.transcriptTimeout = setTimeout(() => {
                    if (!this.isProcessing && transcript !== this.lastTranscript) {
                        this.isProcessing = true;
                        this.lastTranscript = transcript;
                        this.onTranscriptCallback?.(transcript);
                    }
                }, 1000);
            }
        };

        this.speechRecognition.onerror = (event) => {
            console.error('Speech Recognition Error:', event.error);
            if (event.error === 'not-allowed') {
                this.isRecording = false;
            }
        };

        this.speechRecognition.onend = () => {
            this.isRecognitionActive = false;
            if (this.isRecording && !this.isSpeaking) {
                this.startRecognition();
            }
        };
    }

    async startRecording(onTranscript, onSilence) {
        try {
            if (!window.isSecureContext) {
                throw new Error('Secure context required for audio input');
            }

            const stream = await navigator.mediaDevices.getUserMedia({
                audio: {
                    echoCancellation: true,
                    noiseSuppression: true,
                    autoGainControl: true
                }
            });

            this.stream = stream;
            this.isRecording = true;
            this.onTranscriptCallback = onTranscript;
            this.onSilenceCallback = onSilence;

            await this.setupAudioProcessing(stream);
            this.startRecognition();

            return true;
        } catch (error) {
            console.error('Start recording error:', error);
            return false;
        }
    }

    startRecognition() {
        if (!this.speechRecognition || this.isRecognitionActive) return;

        try {
            this.speechRecognition.start();
            this.isRecognitionActive = true;
        } catch (error) {
            console.error('Error starting recognition:', error);
            this.isRecognitionActive = false;
        }
    }

    stopRecording() {
        this.isRecording = false;
        this.isProcessing = false;
        this.lastTranscript = '';

        if (this.currentAudio) {
            this.currentAudio.pause();
            this.currentAudio = null;
        }

        if (this.speechRecognition) {
            try {
                this.speechRecognition.stop();
            } catch (error) {
                console.error('Error stopping recognition:', error);
            }
        }

        if (this.stream) {
            this.stream.getTracks().forEach(track => track.stop());
        }

        if (this.transcriptTimeout) {
            clearTimeout(this.transcriptTimeout);
        }
    }

    async speakResponse(text) {
        try {
            if (this.currentAudio) {
                this.currentAudio.pause();
                this.currentAudio = null;
            }

            this.isSpeaking = true;
            if (this.speechRecognition) {
                try {
                    this.speechRecognition.stop();
                } catch (error) {
                    console.error('Error stopping recognition:', error);
                }
            }

            const response = await fetch(`${this.apiBaseUrl}/tts`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    text: text,
                    voice: 'shimmer',
                    speed: 1.0
                })
            });

            if (!response.ok) {
                throw new Error('TTS API request failed');
            }

            const audioBlob = await response.blob();
            const audioUrl = URL.createObjectURL(audioBlob);
            const audio = new Audio(audioUrl);

            this.currentAudio = audio;

            return new Promise((resolve) => {
                audio.onended = () => {
                    URL.revokeObjectURL(audioUrl);
                    this.isSpeaking = false;
                    this.currentAudio = null;
                    if (this.isRecording) {
                        this.startRecognition();
                    }
                    resolve(true);
                };

                audio.onerror = () => {
                    this.isSpeaking = false;
                    this.currentAudio = null;
                    resolve(false);
                };

                audio.play().catch(() => {
                    this.isSpeaking = false;
                    this.currentAudio = null;
                    resolve(false);
                });
            });
        } catch (error) {
            console.error('Speak response error:', error);
            this.isSpeaking = false;
            return false;
        }
    }

    async setupAudioProcessing(stream) {
        if (!this.audioContext) return;

        const source = this.audioContext.createMediaStreamSource(stream);
        const analyser = this.audioContext.createAnalyser();
        analyser.fftSize = 2048;
        source.connect(analyser);

        setInterval(() => {
            const dataArray = new Float32Array(analyser.frequencyBinCount);
            analyser.getFloatFrequencyData(dataArray);
            const average = dataArray.reduce((sum, value) => sum + value, 0) / dataArray.length;

            if (average > this.silenceThreshold) {
                this.lastVoiceDetection = Date.now();
            } else {
                const timeSinceLastVoice = Date.now() - this.lastVoiceDetection;
                if (timeSinceLastVoice > this.silenceDuration) {
                    this.onSilenceCallback?.();
                }
            }
        }, 100);
    }
}

export default new AudioService(); 