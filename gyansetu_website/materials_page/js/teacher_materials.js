class TeacherMaterials {
    constructor() {
        this.currentTab = 'topic-content';
        this.init();
    }

    init() {
        this.setupTabNavigation();
        this.setupFormHandlers();
        this.loadExistingContent();
    }

    setupTabNavigation() {
        const tabs = document.querySelectorAll('.tab-btn');
        tabs.forEach(tab => {
            tab.addEventListener('click', (e) => {
                const tabId = e.target.getAttribute('data-tab');
                this.switchTab(tabId);
            });
        });
    }

    switchTab(tabId) {
        // Update active tab button
        document.querySelectorAll('.tab-btn').forEach(tab => {
            tab.classList.remove('active');
            if (tab.getAttribute('data-tab') === tabId) {
                tab.classList.add('active');
            }
        });

        // Update active content
        document.querySelectorAll('.tab-content').forEach(content => {
            content.classList.remove('active');
            if (content.id === `${tabId}-tab`) {
                content.classList.add('active');
            }
        });

        this.currentTab = tabId;
    }

    setupFormHandlers() {
        // Topic Content Form
        const topicForm = document.getElementById('topic-content-form');
        topicForm?.addEventListener('submit', (e) => this.handleTopicContentSubmit(e));

        // Study Material Form
        const materialForm = document.getElementById('study-material-form');
        materialForm?.addEventListener('submit', (e) => this.handleStudyMaterialSubmit(e));

        // Setup class and subject change handlers
        ['content', 'material'].forEach(prefix => {
            const classSelect = document.getElementById(`${prefix}-class`);
            const subjectSelect = document.getElementById(`${prefix}-subject`);
            
            classSelect?.addEventListener('change', () => this.updateTopics(prefix));
            subjectSelect?.addEventListener('change', () => this.updateTopics(prefix));
        });
    }

    updateTopics(prefix) {
        const classValue = document.getElementById(`${prefix}-class`).value;
        const subjectValue = document.getElementById(`${prefix}-subject`).value;
        const topicSelect = document.getElementById(`${prefix}-topic`);
        const subjectSelect = document.getElementById(`${prefix}-subject`);

        // Clear existing options
        topicSelect.innerHTML = '<option value="">Select Topic</option>';

        // Handle subject visibility based on class selection
        if (classValue === 'Miscellaneous') {
            // Show only Languages and Technology options
            Array.from(subjectSelect.options).forEach(option => {
                if (['', 'Languages', 'Technology'].includes(option.value)) {
                    option.style.display = '';
                } else {
                    option.style.display = 'none';
                }
            });

            // Add topics based on selected subject
            if (subjectValue === 'Languages') {
                const languageTopics = ['Java', 'Python', 'Others'];
                languageTopics.forEach(topic => {
                    const option = document.createElement('option');
                    option.value = topic;
                    option.textContent = topic;
                    topicSelect.appendChild(option);
                });
            } else if (subjectValue === 'Technology') {
                const techTopics = ['Basics of AI', 'Basics of Cloud Computing', 'Others'];
                techTopics.forEach(topic => {
                    const option = document.createElement('option');
                    option.value = topic;
                    option.textContent = topic;
                    topicSelect.appendChild(option);
                });
            }
        } else {
            // Show all regular subjects for normal classes
            Array.from(subjectSelect.options).forEach(option => {
                if (['Languages', 'Technology'].includes(option.value)) {
                    option.style.display = 'none';
                } else {
                    option.style.display = '';
                }
            });

            // Load regular topics if available
            if (classValue && subjectValue && window.topicsByClassAndSubject?.[classValue]?.[subjectValue]) {
                const topics = window.topicsByClassAndSubject[classValue][subjectValue];
                topics.forEach(topic => {
                    const option = document.createElement('option');
                    option.value = topic;
                    option.textContent = topic;
                    topicSelect.appendChild(option);
                });
            }
        }

        // Reset subject if switching between Miscellaneous and regular classes
        if (classValue === 'Miscellaneous' && !['Languages', 'Technology'].includes(subjectValue)) {
            subjectSelect.value = '';
        } else if (classValue !== 'Miscellaneous' && ['Languages', 'Technology'].includes(subjectValue)) {
            subjectSelect.value = '';
        }
    }

    async handleTopicContentSubmit(e) {
        e.preventDefault();
        
        try {
            const form = e.target;
            const classValue = form.querySelector('#content-class').value;
            const subject = form.querySelector('#content-subject').value;
            const topic = form.querySelector('#content-topic').value;
            const file = form.querySelector('#content-file').files[0];

            if (!classValue || !subject || !topic || !file) {
                alert('Please fill all required fields');
                return;
            }

            // Read file content
            const content = await this.readFileContent(file);
            
            // Save to Firebase
            const userId = firebase.auth().currentUser.uid;
            const newContentRef = firebase.database().ref('materials').push();
            
            await newContentRef.set({
                class: classValue,
                subject,
                topic,
                content,
                timestamp: Date.now(),
                teacherId: userId,
                type: 'topic-content'
            });

            alert('Topic content uploaded successfully!');
            form.reset();
            
        } catch (error) {
            console.error('Error uploading topic content:', error);
            alert('Failed to upload topic content. Please try again.');
        }
    }

    async handleStudyMaterialSubmit(e) {
        e.preventDefault();
        
        try {
            const form = e.target;
            const classValue = form.querySelector('#material-class').value;
            const subject = form.querySelector('#material-subject').value;
            const topic = form.querySelector('#material-topic').value;
            const file = form.querySelector('#material-file').files[0];

            if (!classValue || !subject || !topic || !file) {
                alert('Please fill all required fields');
                return;
            }

            // Upload file to Firebase Storage
            const storageRef = firebase.storage().ref();
            const fileRef = storageRef.child(`study-materials/${Date.now()}_${file.name}`);
            await fileRef.put(file);
            const downloadURL = await fileRef.getDownloadURL();

            // Save metadata to Realtime Database
            const userId = firebase.auth().currentUser.uid;
            const newMaterialRef = firebase.database().ref('materials').push();
            
            await newMaterialRef.set({
                class: classValue,
                subject,
                topic,
                fileUrl: downloadURL,
                fileName: file.name,
                timestamp: Date.now(),
                teacherId: userId,
                type: 'study-material'
            });

            alert('Study material uploaded successfully!');
            form.reset();
            
        } catch (error) {
            console.error('Error uploading study material:', error);
            alert('Failed to upload study material. Please try again.');
        }
    }

    loadExistingContent() {
        // Load and display existing content for each tab
        this.loadTopicContents();
        this.loadStudyMaterials();
    }

    loadTopicContents() {
        const materialsRef = firebase.database().ref('materials');
        materialsRef.orderByChild('type').equalTo('topic-content').on('value', snapshot => {
            const contents = snapshot.val() || {};
            this.displayTopicContents(contents);
        });
    }

    loadStudyMaterials() {
        const materialsRef = firebase.database().ref('materials');
        materialsRef.orderByChild('type').equalTo('study-material').on('value', snapshot => {
            const materials = snapshot.val() || {};
            this.displayStudyMaterials(materials);
        });
    }

    // Helper method to read file content
    readFileContent(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = (e) => resolve(e.target.result);
            reader.onerror = (e) => reject(e);
            reader.readAsText(file);
        });
    }

    // Implement other helper methods for loading content...
}

// Initialize when document is ready
document.addEventListener('DOMContentLoaded', () => {
    new TeacherMaterials();
}); 

// Add this function to handle topic loading
function updateTopicOptions(classValue, subjectValue, topicSelect) {
    // Clear existing options
    topicSelect.innerHTML = '<option value="">Select Topic</option>';
    
    if (classValue === 'Miscellaneous') {
        if (subjectValue === 'Languages') {
            const languageTopics = ['Java', 'Python', 'Others'];
            languageTopics.forEach(topic => {
                const option = document.createElement('option');
                option.value = topic;
                option.textContent = topic;
                topicSelect.appendChild(option);
            });
        } else if (subjectValue === 'Technology') {
            const techTopics = ['Basics of AI', 'Basics of Cloud Computing', 'Others'];
            techTopics.forEach(topic => {
                const option = document.createElement('option');
                option.value = topic;
                option.textContent = topic;
                topicSelect.appendChild(option);
            });
        }
    }
}

// Add event listeners
document.addEventListener('DOMContentLoaded', function() {
    const classSelects = document.querySelectorAll('[id$="-class"]');
    const subjectSelects = document.querySelectorAll('[id$="-subject"]');
    const topicSelects = document.querySelectorAll('[id$="-topic"]');

    // Add change event listeners to class and subject selects
    classSelects.forEach((classSelect, index) => {
        const subjectSelect = subjectSelects[index];
        const topicSelect = topicSelects[index];

        classSelect.addEventListener('change', function() {
            if (this.value === 'Miscellaneous') {
                // Filter subject options to show only Languages and Technology
                Array.from(subjectSelect.options).forEach(option => {
                    if (option.value !== '' && 
                        option.value !== 'Languages' && 
                        option.value !== 'Technology') {
                        option.style.display = 'none';
                    } else {
                        option.style.display = '';
                    }
                });
            } else {
                // Show all subject options for other classes
                Array.from(subjectSelect.options).forEach(option => {
                    option.style.display = '';
                });
            }
            // Reset subject and topic
            subjectSelect.value = '';
            topicSelect.innerHTML = '<option value="">Select Topic</option>';
        });

        subjectSelect.addEventListener('change', function() {
            updateTopicOptions(classSelect.value, this.value, topicSelect);
        });
    });
}); 