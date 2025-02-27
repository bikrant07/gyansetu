function isBrowserSupported() {
    return 'webkitSpeechRecognition' in window || 'SpeechRecognition' in window;
}

class SpeechToTextManager {
    constructor() {
        if (!isBrowserSupported()) {
            alert('Speech recognition is not supported in your browser. Please use Chrome or Edge.');
            return;
        }
        console.log("Initializing SpeechToTextManager");
        this.recognition = null;
        this.transcript = '';
        this.finalTranscript = '';
        this.isRecording = false;
        this.summaryContainer = null;
        this.isEditing = false;
        this.autoCorrectMap = new Map([
            ['mathematic', 'mathematics'],
            ['fiziks', 'physics'],
            ['kemistry', 'chemistry'],
            ['bayology', 'biology'],
            ['algebra', 'algebra'],
            ['triangel', 'triangle'],
            ['equasion', 'equation'],
            ['theorum', 'theorem']
        ]);
        
        if ('webkitSpeechRecognition' in window) {
            console.log("Speech recognition is supported");
            this.recognition = new webkitSpeechRecognition();
            this.setupRecognition();
        } else {
            console.error('Speech recognition not supported in this browser');
        }
    }

    setupRecognition() {
        console.log("Setting up recognition");
        this.recognition.continuous = true;
        this.recognition.interimResults = true;
        this.recognition.lang = 'en-US';
        this.recognition.maxAlternatives = 3;

        this.recognition.onstart = () => {
            console.log("Recognition started");
        };

        this.recognition.onend = () => {
            console.log("Recognition ended");
            // Restart if still recording
            if (this.isRecording) {
                console.log("Restarting recognition");
                this.recognition.start();
            }
        };

        this.recognition.onresult = (event) => {
            console.log("Got recognition result", event);
            let interimTranscript = '';

            for (let i = event.resultIndex; i < event.results.length; i++) {
                let transcriptArray = [];
                for (let j = 0; j < event.results[i].length; j++) {
                    transcriptArray.push({
                        text: event.results[i][j].transcript,
                        confidence: event.results[i][j].confidence
                    });
                }
                
                transcriptArray.sort((a, b) => b.confidence - a.confidence);
                let transcript = this.autoTuneText(transcriptArray[0].text);

                if (event.results[i].isFinal) {
                    this.finalTranscript += transcript + ' ';
                } else {
                    interimTranscript += transcript;
                }
            }

            if (this.summaryContainer) {
                const liveText = document.getElementById('live-transcript');
                if (liveText) {
                    liveText.innerHTML = `<strong>Live:</strong> ${this.formatText(interimTranscript)}`;
                }
                const finalText = document.getElementById('final-transcript');
                if (finalText) {
                    this.transcript = this.finalTranscript;
                    finalText.innerHTML = this.formatText(this.transcript);
                }
            }
        };

        this.recognition.onerror = (event) => {
            console.error('Speech recognition error:', event.error);
            if (this.isRecording && event.error !== 'no-speech') {
                setTimeout(() => {
                    this.recognition.start();
                }, 1000);
            }
        };
    }

    createSummaryContainer() {
        this.summaryContainer = document.createElement('div');
        this.summaryContainer.className = 'transcript-container';
        this.summaryContainer.innerHTML = `
            <div class="transcript-header">
                <h3>Live Transcript</h3>
                <div class="transcript-controls">
                    <button id="edit-transcript" class="edit-btn">
                        <i class="fas fa-edit"></i> Edit
                    </button>
                    <button id="upload-transcript" class="upload-btn" style="display: none;">
                        <i class="fas fa-upload"></i> Upload
                    </button>
                    <button class="close-transcript-btn">
                        <i class="fas fa-times"></i>
                    </button>
                </div>
            </div>
            <div id="live-transcript" class="live-text"></div>
            <div id="final-transcript" class="final-text" contenteditable="false"></div>
        `;

        const closeBtn = this.summaryContainer.querySelector('.close-transcript-btn');
        closeBtn.addEventListener('click', () => this.cleanup());

        const editBtn = this.summaryContainer.querySelector('#edit-transcript');
        editBtn.addEventListener('click', () => this.toggleEdit());

        document.body.appendChild(this.summaryContainer);
    }

    autoTuneText(text) {
        let words = text.toLowerCase().split(' ');
        
        words = words.map(word => {
            if (this.autoCorrectMap.has(word)) {
                return this.autoCorrectMap.get(word);
            }
            
            for (let [correct, correction] of this.autoCorrectMap) {
                if (this.levenshteinDistance(word, correct) <= 2) {
                    return correction;
                }
            }
            
            return word;
        });

        let result = words.join(' ');
        result = result.charAt(0).toUpperCase() + result.slice(1);

        if (!/[.!?]$/.test(result)) {
            result += '.';
        }

        return result;
    }

    formatText(text) {
        const abbreviations = {
            'i.e.': 'i.e.',
            'e.g.': 'e.g.',
            'etc.': 'etc.',
            'ph.d': 'Ph.D.',
            'mr.': 'Mr.',
            'mrs.': 'Mrs.',
            'dr.': 'Dr.'
        };

        Object.keys(abbreviations).forEach(abbr => {
            const regex = new RegExp(`\\b${abbr}\\b`, 'gi');
            text = text.replace(regex, abbreviations[abbr]);
        });

        text = text.replace(/(^\w|\.\s+\w)/g, letter => letter.toUpperCase());

        return text;
    }

    toggleEdit() {
        const finalText = document.getElementById('final-transcript');
        const editBtn = document.getElementById('edit-transcript');
        
        this.isEditing = !this.isEditing;
        finalText.contentEditable = this.isEditing;
        
        if (this.isEditing) {
            editBtn.innerHTML = '<i class="fas fa-save"></i> Save';
            editBtn.classList.add('editing');
            finalText.classList.add('editing');
            const uploadBtn = document.getElementById('upload-transcript');
            if (uploadBtn) uploadBtn.style.display = 'none';
        } else {
            editBtn.innerHTML = '<i class="fas fa-edit"></i> Edit';
            editBtn.classList.remove('editing');
            finalText.classList.remove('editing');
            this.transcript = finalText.innerText;
            const uploadBtn = document.getElementById('upload-transcript');
            if (uploadBtn) uploadBtn.style.display = 'block';
        }
    }

    startRecording() {
        console.log("Starting recording");
        if (!this.recognition) {
            alert('Speech recognition not supported in your browser');
            return;
        }

        this.isRecording = true;
        this.transcript = '';
        this.finalTranscript = '';
        this.createSummaryContainer();
        try {
            this.recognition.start();
            console.log("Recognition started successfully");
        } catch (error) {
            console.error("Error starting recognition:", error);
        }
    }

    stopRecording() {
        if (!this.recognition || !this.isRecording) return;

        this.isRecording = false;
        this.recognition.stop();
        
        this.transcript = this.finalTranscript;
        
        const editBtn = document.getElementById('edit-transcript');
        const uploadBtn = document.getElementById('upload-transcript');
        if (editBtn) editBtn.style.display = 'block';
        if (uploadBtn) {
            uploadBtn.style.display = 'block';
            uploadBtn.onclick = () => this.uploadTranscript();
        }

        const finalText = document.getElementById('final-transcript');
        if (finalText) {
            finalText.innerHTML = this.formatText(this.transcript);
        }
    }

    cleanup() {
        if (this.recognition) {
            this.recognition.stop();
            this.isRecording = false;
        }
        if (this.summaryContainer) {
            document.body.removeChild(this.summaryContainer);
            this.summaryContainer = null;
        }
        this.transcript = '';
        this.finalTranscript = '';
    }

    levenshteinDistance(a, b) {
        if (a.length === 0) return b.length;
        if (b.length === 0) return a.length;

        const matrix = [];

        for (let i = 0; i <= b.length; i++) {
            matrix[i] = [i];
        }

        for (let j = 0; j <= a.length; j++) {
            matrix[0][j] = j;
        }

        for (let i = 1; i <= b.length; i++) {
            for (let j = 1; j <= a.length; j++) {
                if (b.charAt(i - 1) === a.charAt(j - 1)) {
                    matrix[i][j] = matrix[i - 1][j - 1];
                } else {
                    matrix[i][j] = Math.min(
                        matrix[i - 1][j - 1] + 1,
                        matrix[i][j - 1] + 1,
                        matrix[i - 1][j] + 1
                    );
                }
            }
        }

        return matrix[b.length][a.length];
    }

    async uploadTranscript() {
        try {
            // Check if user is authenticated
            const user = firebase.auth().currentUser;
            if (!user || !user.emailVerified) {
                alert('Please sign in with a verified email to upload transcripts');
                return;
            }

            // Prompt user for class name
            let className = prompt('Enter the class name:');
            if (!className) {
                alert('Class name is required to upload the transcript');
                return;
            }

            // Normalize the class name
            className = className.toLowerCase().replace(/\s+/g, '');

            const timestamp = new Date().toISOString();
            const formattedDate = new Date().toLocaleString();
            
            // Format the content with header information
            const formattedContent = `Teacher: ${user.displayName || user.email}
Date: ${formattedDate}
----------------------------------------

${this.transcript}`;

            const transcriptData = {
                content: formattedContent,
                timestamp: timestamp,
                title: `Class Transcript - ${new Date().toLocaleDateString()}`,
                userId: user.uid,
                userEmail: user.email,
                teacherName: user.displayName || user.email,
                className: className
            };

            // Get a reference to the Firebase storage and database
            const storageRef = firebase.storage().ref();
            const dbRef = firebase.database().ref('transcripts');

            // Create a unique file name using teacher's name
            const teacherName = (user.displayName || user.email)
                .replace(/[^a-zA-Z0-9]/g, '_') // Replace non-alphanumeric chars with underscore
                .toLowerCase();
            const fileName = `${teacherName}_${timestamp}.txt`;
            
            // Upload to Firebase Storage under the normalized class folder
            const fileRef = storageRef.child(`transcripts/${className}/${fileName}`);
            await fileRef.putString(formattedContent);
            
            // Get the download URL
            const downloadURL = await fileRef.getDownloadURL();
            
            // Save metadata to Realtime Database under the normalized class node
            const newTranscriptRef = dbRef.child(className).push();
            await newTranscriptRef.set({
                ...transcriptData,
                fileURL: downloadURL
            });

            alert('Transcript uploaded successfully!');
        } catch (error) {
            console.error('Error uploading transcript:', error);
            if (error.code === 'storage/unauthorized') {
                alert('Permission denied. Please make sure you are signed in with the correct account.');
            } else {
                alert('Failed to upload transcript. Please try again.');
            }
        }
    }
}