// Add at the beginning
let speechToText;

// In startClass function
function startClass() {
    // ... other code ...
    
    // Initialize speech to text
    if (window.speechToText) {
        window.speechToText.cleanup();
    }
    window.speechToText = new SpeechToTextManager();
    window.speechToText.startRecording();
    
    // Add start recording button to controls
    const controls = document.querySelector('.class-controls');
    if (controls) {
        const transcriptBtn = document.createElement('button');
        transcriptBtn.className = 'control-btn transcript-btn active';
        transcriptBtn.innerHTML = '<i class="fas fa-closed-captioning"></i>';
        transcriptBtn.title = 'Live Transcript';
        controls.appendChild(transcriptBtn);
    }
}

// In endClass function
function endClass() {
    // ... other code ...
    
    if (window.speechToText) {
        window.speechToText.stopRecording();
    }
}

// Add cleanup on page unload
window.addEventListener('beforeunload', () => {
    if (window.speechToText) {
        window.speechToText.cleanup();
    }
});