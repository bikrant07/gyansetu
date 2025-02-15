class StorageManager {
    constructor() {
        this.storage = firebase.storage();
        this.database = firebase.database();
    }

    async saveRecording(blob, metadata) {
        try {
            // Show progress container
            const progressDiv = this.createProgressDiv();

            // 1. Upload video to Firebase Storage
            const filename = `recordings/${metadata.subject}/${Date.now()}_${metadata.title}.webm`;
            const storageRef = this.storage.ref(filename);
            
            // Upload with progress
            const uploadTask = storageRef.put(blob);
            uploadTask.on('state_changed', 
                (snapshot) => {
                    const progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
                    progressDiv.textContent = `Upload Progress: ${Math.round(progress)}%`;
                }
            );

            // Wait for upload to complete
            await uploadTask;
            const downloadURL = await storageRef.getDownloadURL();

            // 2. Save metadata to Realtime Database
            const recordingData = {
                title: metadata.title,
                description: metadata.description,
                subject: metadata.subject,
                professor: metadata.professor,
                downloadURL: downloadURL,
                timestamp: Date.now(),
                size: blob.size,
                userId: firebase.auth().currentUser.uid
            };

            // Save to recordings collection in Realtime Database
            const newRecordingRef = this.database.ref('recordings').push();
            await newRecordingRef.set(recordingData);

            progressDiv.textContent = 'Upload Complete!';
            setTimeout(() => progressDiv.remove(), 2000);

            return {
                id: newRecordingRef.key,
                ...recordingData
            };

        } catch (error) {
            console.error('Upload error:', error);
            throw error;
        }
    }

    async getRecordings() {
        const recordingsRef = this.database.ref('recordings');
        const snapshot = await recordingsRef.once('value');
        return snapshot.val();
    }

    createProgressDiv() {
        const div = document.createElement('div');
        div.id = 'uploadProgress';
        div.style.position = 'fixed';
        div.style.top = '20px';
        div.style.right = '20px';
        div.style.padding = '10px';
        div.style.backgroundColor = '#4CAF50';
        div.style.color = 'white';
        div.style.borderRadius = '5px';
        div.style.zIndex = '1000';
        document.body.appendChild(div);
        return div;
    }
}

// Export for use in other files
window.StorageManager = new StorageManager(); 