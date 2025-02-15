// Initialize StudentMaterials globally
window.studentMaterials = null;

// Global function to test quiz access
window.testQuizAccess = function() {
    const user = firebase.auth().currentUser;
    console.log('Testing quiz access...');
    console.log('Current user:', user);

    if (!user) {
        console.error('No user logged in');
        alert('Please log in first');
        return;
    }

    // Test quizzes access
    firebase.database().ref('quizzes').once('value')
        .then(snapshot => {
            console.log('Successfully read quizzes:', snapshot.val());
            alert('Quiz access successful! Check console for details.');
        })
        .catch(error => {
            console.error('Error accessing quizzes:', error);
            alert('Error accessing quizzes: ' + error.message);
        });
};

// Global function to refresh quizzes
window.refreshQuizzes = function() {
    console.log('Refresh quizzes called');
    if (window.studentMaterials) {
        window.studentMaterials.loadQuizzes();
    } else {
        console.error('StudentMaterials not initialized');
        alert('Error: Please refresh the page');
    }
};

class StudentMaterials {
    constructor() {
        console.log('StudentMaterials constructor called');
        this.quizCheckInterval = null;
        this.initialized = false;
        
        // Add immediate quiz check when quiz tab is shown
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                if (btn.getAttribute('data-tab') === 'quiz') {
                    console.log('Quiz tab clicked - loading quizzes');
                    this.loadAvailableQuizzes();
                }
            });
        });

        // Add quiz filter event listeners
        const quizClassFilter = document.getElementById('quiz-class-filter');
        const quizSubjectFilter = document.getElementById('quiz-subject-filter');
        
        if (quizClassFilter) {
            quizClassFilter.addEventListener('change', () => {
                console.log('Quiz class filter changed');
                if (quizClassFilter.value && quizSubjectFilter.value) {
                    this.loadAvailableQuizzes();
                }
            });
        }
        
        if (quizSubjectFilter) {
            quizSubjectFilter.addEventListener('change', () => {
                console.log('Quiz subject filter changed');
                if (quizClassFilter.value && quizSubjectFilter.value) {
                    this.loadAvailableQuizzes();
                }
            });
        }
    }

    init() {
        if (this.initialized) return;
        
        console.log('Initializing StudentMaterials');
        
        // Verify Firebase is initialized
        if (!firebase.apps.length) {
            console.error('Firebase not initialized');
            return;
        }

        // Verify user is authenticated
        const user = firebase.auth().currentUser;
        if (!user) {
            console.error('User not authenticated');
            return;
        }

        this.setupEventListeners();
        this.loadMaterials();
        
        // Load quizzes immediately if quiz tab is active
        const quizTab = document.querySelector('[data-tab="quiz"]');
        if (quizTab && quizTab.classList.contains('active')) {
            this.loadAvailableQuizzes();
        }
        
        this.startQuizCheck();
        this.initialized = true;
    }

    setupEventListeners() {
        // Tab switching
        const tabs = document.querySelectorAll('.tab-btn');
        console.log('Found tabs:', tabs.length);

        tabs.forEach(btn => {
            btn.addEventListener('click', () => {
                const tabId = btn.getAttribute('data-tab');
                console.log('Tab clicked:', tabId);

                // Remove active class from all tabs and contents
                tabs.forEach(b => b.classList.remove('active'));
                document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));

                // Add active class to clicked tab and corresponding content
                btn.classList.add('active');
                const contentElement = document.getElementById(`${tabId}-tab`);
                if (contentElement) {
                    contentElement.classList.add('active');
                }
            });
        });

        // Filter event listeners
        const classFilter = document.getElementById('class-filter');
        const subjectFilter = document.getElementById('subject-filter');
        const topicFilter = document.getElementById('topic-filter');
        const searchInput = document.getElementById('search-input');

        if (classFilter) {
            classFilter.addEventListener('change', () => {
                console.log('Class changed:', classFilter.value);
                this.updateTopics();
            });
        }

        if (subjectFilter) {
            subjectFilter.addEventListener('change', () => {
                console.log('Subject changed:', subjectFilter.value);
                this.updateTopics();
            });
        }

        if (topicFilter) {
            topicFilter.addEventListener('change', () => {
                console.log('Topic changed:', topicFilter.value);
                this.filterMaterials();
            });
        }

        if (searchInput) {
            searchInput.addEventListener('input', () => {
                this.filterMaterials();
            });
        }
    }

    startQuizCheck() {
        // Check for available quizzes every minute
        this.quizCheckInterval = setInterval(() => {
            this.loadAvailableQuizzes();
        }, 60000); // 60000 ms = 1 minute

        // Initial load
        this.loadAvailableQuizzes();
    }

    async loadAvailableQuizzes() {
        try {
            console.log('Starting loadAvailableQuizzes...');
            const quizList = document.getElementById('quiz-list');
            if (!quizList) {
                console.error('Quiz list element not found');
                return;
            }

            // Get filters
            const classValue = document.getElementById('quiz-class-filter')?.value;
            const subjectValue = document.getElementById('quiz-subject-filter')?.value;

            // Show prompt if no filters selected
            if (!classValue && !subjectValue) {
                quizList.innerHTML = `
                    <div class="select-prompt">
                        <i class="fas fa-filter"></i>
                        <p>Please select a Class or Subject to view quizzes</p>
                    </div>
                `;
                return;
            }

            // Fetch quizzes from Firebase Realtime Database
            const quizzesRef = firebase.database().ref('quizzes');
            const snapshot = await quizzesRef.once('value');
            const quizzes = snapshot.val();
            
            console.log('Raw quizzes data:', quizzes);

            if (!quizzes) {
                quizList.innerHTML = `
                    <div class="no-content-message">
                        <i class="fas fa-folder-open"></i>
                        <p>No quizzes available at this time</p>
                    </div>
                `;
                return;
            }

            // Convert quizzes object to array and filter
            const availableQuizzes = Object.entries(quizzes)
                .map(([id, quiz]) => {
                    // Calculate timing based on quiz.timing or quiz.timestamp
                    const startTime = quiz.timing?.startTime || quiz.timestamp || Date.now();
                    const duration = quiz.timing?.duration || quiz.duration || 30; // default 30 minutes
                    const endTime = startTime + (duration * 60000); // Convert minutes to milliseconds

                    return {
                        id,
                        ...quiz,
                        timing: {
                            startTime,
                            duration,
                            endTime
                        }
                    };
                })
                .filter(quiz => {
                    const matchesClass = !classValue || quiz.class === classValue;
                    const matchesSubject = !subjectValue || quiz.subject === subjectValue;
                    
                    // Check if quiz is currently active
                    const now = Date.now();
                    const isActive = now <= quiz.timing.endTime; // Only check if quiz hasn't ended

                    console.log('Quiz timing check:', {
                        id: quiz.id,
                        title: quiz.title,
                        startTime: new Date(quiz.timing.startTime).toLocaleString(),
                        endTime: new Date(quiz.timing.endTime).toLocaleString(),
                        now: new Date(now).toLocaleString(),
                        isActive
                    });

                    return matchesClass && matchesSubject && isActive;
                });

            console.log('Filtered quizzes:', availableQuizzes);

            if (availableQuizzes.length === 0) {
                quizList.innerHTML = `
                    <div class="no-content-message">
                        <i class="fas fa-clock"></i>
                        <p>No quizzes available${classValue || subjectValue ? ' for the selected filters' : ''}</p>
                    </div>
                `;
                return;
            }

            // Render available quizzes
            const renderedHTML = availableQuizzes.map(quiz => this.renderQuizCard(quiz)).join('');
            console.log('Rendered HTML:', renderedHTML);
            quizList.innerHTML = `<div class="quiz-cards">${renderedHTML}</div>`;
            console.log('Quizzes should now be visible on the page');
        } catch (error) {
            console.error('Error loading quizzes:', error);
            const quizList = document.getElementById('quiz-list');
            if (quizList) {
                quizList.innerHTML = `
                    <div class="error-message">
                        <i class="fas fa-exclamation-circle"></i>
                        <p>Error loading quizzes: ${error.message}</p>
                        <small>Please try refreshing the page</small>
                    </div>
                `;
            }
        }
    }
    

    renderQuizCard(quiz) {
        console.log('Rendering quiz card:', quiz);
        try {
            const questionCount = quiz.questions?.length || 0;
            const duration = quiz.timing?.duration || quiz.duration || 30;
            
            return `
                <div class="quiz-card">
                    <div class="quiz-card-header">
                        <h3>${quiz.title || 'Untitled Quiz'}</h3>
                    </div>
                    <div class="quiz-card-body">
                        <p>${quiz.description || 'No description provided'}</p>
                        <div class="quiz-meta">
                            <div>Questions: ${questionCount}</div>
                            <div>Duration: ${duration} minutes</div>
                        </div>
                    </div>
                    <div class="quiz-card-actions">
                        <button onclick="window.studentMaterials.startQuiz('${quiz.id}')">Start Quiz</button>
                    </div>
                </div>
            `;
        } catch (error) {
            console.error('Error rendering quiz card:', error, quiz);
            return '';
        }
    }

    async startQuiz(quizId) {
        try {
            const quizRef = firebase.database().ref(`quizzes/${quizId}`);
            const snapshot = await quizRef.once('value');
            const quiz = snapshot.val();

            if (!quiz) {
                alert('Quiz not found');
                return;
            }

            // Check if quiz is still active
            const now = Date.now();
            const startTime = quiz.timing.startTime;
            const endTime = quiz.timing.endTime;
            
            if (now > endTime) {
                alert('This quiz has expired');
                this.loadAvailableQuizzes(); // Refresh the quiz list
                return;
            }

            // Calculate remaining time
            const remainingTime = Math.floor((endTime - now) / 60000); // in minutes

            // Show quiz interface
            this.showQuizInterface(quiz, remainingTime);
        } catch (error) {
            console.error('Error starting quiz:', error);
            alert('Failed to start quiz. Please try again.');
        }
    }

    showQuizInterface(quiz, remainingTime) {
        const modal = document.createElement('div');
        modal.className = 'quiz-modal';
        modal.innerHTML = `
            <div class="quiz-container">
                <div class="quiz-header">
                    <h2>${quiz.title || 'Quiz'}</h2>
                    <div class="quiz-timer">
                        Time left: <span id="quiz-countdown">${remainingTime}:00</span>
                    </div>
                </div>
                <div class="quiz-questions">
                    ${quiz.questions.map((q, index) => this.renderQuestion(q, index)).join('')}
                </div>
                <div class="quiz-actions">
                    <button onclick="window.studentMaterials.submitQuiz('${quiz.id}')">Submit Quiz</button>
                </div>
            </div>
        `;

        document.body.appendChild(modal);
        this.startQuizTimer(remainingTime);
    }

    renderQuestion(question, index) {
        let optionsHtml = '';
        switch (question.type) {
            case 'mcq':
                optionsHtml = Object.entries(question.options).map(([key, value]) => `
                    <div class="quiz-option">
                        <input type="radio" name="q${index}" value="${key}" id="q${index}opt${key}">
                        <label for="q${index}opt${key}">${value}</label>
                    </div>
                `).join('');
                break;
            case 'true-false':
                optionsHtml = `
                    <div class="quiz-option">
                        <input type="radio" name="q${index}" value="true" id="q${index}true">
                        <label for="q${index}true">True</label>
                    </div>
                    <div class="quiz-option">
                        <input type="radio" name="q${index}" value="false" id="q${index}false">
                        <label for="q${index}false">False</label>
                    </div>
                `;
                break;
            case 'short':
                optionsHtml = `
                    <textarea name="q${index}" rows="3" placeholder="Enter your answer"></textarea>
                `;
                break;
        }

        return `
            <div class="quiz-question">
                <h3>Question ${index + 1}</h3>
                <p>${question.text}</p>
                <div class="quiz-options">
                    ${optionsHtml}
                </div>
            </div>
        `;
    }

    startQuizTimer(duration) {
        const timerElement = document.getElementById('quiz-countdown');
        let timeLeft = duration * 60; // Convert to seconds

        const timer = setInterval(() => {
            const minutes = Math.floor(timeLeft / 60);
            const seconds = timeLeft % 60;
            
            timerElement.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`;

            if (timeLeft <= 0) {
                clearInterval(timer);
                alert('Time is up! Submitting quiz...');
                this.submitQuiz();
                return;
            }

            timeLeft--;
        }, 1000);
    }

    async submitQuiz(quizId) {
        try {
            const answers = this.gatherQuizAnswers();
            const userId = firebase.auth().currentUser.uid;

            await firebase.database().ref(`quiz_attempts/${quizId}/${userId}`).set({
                answers,
                timestamp: Date.now()
            });

            alert('Quiz submitted successfully!');
            document.querySelector('.quiz-modal').remove();
            this.loadAvailableQuizzes();
        } catch (error) {
            console.error('Error submitting quiz:', error);
            alert('Failed to submit quiz. Please try again.');
        }
    }

    gatherQuizAnswers() {
        const answers = {};
        document.querySelectorAll('.quiz-question').forEach((question, index) => {
            const input = question.querySelector('input[type="radio"]:checked, textarea');
            if (input) {
                answers[index] = input.value;
            }
        });
        return answers;
    }

    loadMaterials() {
        try {
            const materialsRef = firebase.database().ref('materials');
            materialsRef.on('value', (snapshot) => {
                const materials = snapshot.val() || {};
                window.allMaterials = Object.entries(materials).map(([id, data]) => ({
                    id,
                    ...data
                }));
                this.filterMaterials();
            }, (error) => {
                console.error('Error loading materials:', error);
            });
        } catch (error) {
            console.error('Error in loadMaterials:', error);
        }
    }

    filterMaterials() {
        console.log('Filtering materials...');
        if (!window.allMaterials) {
            console.log('No materials available');
            return;
        }

        const classValue = document.getElementById('class-filter')?.value;
        const subjectValue = document.getElementById('subject-filter')?.value;
        const topicValue = document.getElementById('topic-filter')?.value;
        const searchValue = document.getElementById('search-input')?.value?.toLowerCase();

        console.log('Filter values:', { classValue, subjectValue, topicValue, searchValue });

        const filteredMaterials = window.allMaterials.filter(material => {
            const matchesClass = !classValue || material.class === classValue;
            const matchesSubject = !subjectValue || material.subject === subjectValue;
            const matchesTopic = !topicValue || material.topic === topicValue;
            const matchesSearch = !searchValue || 
                material.topic.toLowerCase().includes(searchValue) ||
                material.content?.toLowerCase().includes(searchValue);

            return matchesClass && matchesSubject && matchesTopic && matchesSearch;
        });

        console.log('Filtered materials:', filteredMaterials);
        this.displayMaterials(filteredMaterials);
    }

    displayMaterials(materials) {
        const grid = document.getElementById('materials-grid');
        if (!grid) return;

        grid.innerHTML = materials.length ? '' : '<p class="no-content">No materials found</p>';

        materials.forEach(material => {
            const card = document.createElement('div');
            card.className = 'material-card';
            card.innerHTML = `
                <div class="material-info">
                    <h3>${material.topic}</h3>
                    <div class="material-meta">
                        <span class="class-tag">${material.class}</span>
                        <span class="subject-tag">${material.subject}</span>
                    </div>
                    <p class="last-updated">Last updated: ${new Date(material.timestamp).toLocaleDateString()}</p>
                </div>
                <div class="material-actions">
                    <button onclick="viewContent('${material.id}')" class="view-btn">
                        <i class="fas fa-eye"></i> View
                    </button>
                </div>
            `;
            grid.appendChild(card);
        });
    }

    updateTopics() {
        console.log('Updating topics...');
        const classSelect = document.getElementById('class-filter');
        const subjectSelect = document.getElementById('subject-filter');
        const topicSelect = document.getElementById('topic-filter');
        
        if (!classSelect || !subjectSelect || !topicSelect) {
            console.error('Filter elements not found');
            return;
        }

        const selectedClass = classSelect.value;
        const selectedSubject = subjectSelect.value;
        
        console.log('Selected values:', { selectedClass, selectedSubject });
        console.log('Available topics:', window.topicsByClassAndSubject?.[selectedClass]?.[selectedSubject]);

        // Clear existing topics
        topicSelect.innerHTML = '<option value="">All Topics</option>';
        
        if (selectedClass && selectedSubject && window.topicsByClassAndSubject?.[selectedClass]?.[selectedSubject]) {
            const topics = window.topicsByClassAndSubject[selectedClass][selectedSubject];
            topics.forEach(topic => {
                const option = document.createElement('option');
                option.value = topic;
                option.textContent = topic;
                topicSelect.appendChild(option);
            });
        }
    }
}

// Initialize when document is ready
document.addEventListener('DOMContentLoaded', () => {
    console.log('DOM Content Loaded - Creating StudentMaterials instance');
    if (!window.studentMaterials) {
        window.studentMaterials = new StudentMaterials();
        
        // Wait for Firebase auth to be ready
        firebase.auth().onAuthStateChanged((user) => {
            console.log('Auth state changed:', user ? 'User logged in' : 'No user');
            if (user && window.studentMaterials && !window.studentMaterials.initialized) {
                window.studentMaterials.init();
            }
        });
    }
});

// Backup initialization
window.onload = () => {
    console.log('Window Loaded - Checking StudentMaterials initialization');
    if (!window.studentMaterials) {
        console.log('Creating backup StudentMaterials instance');
        window.studentMaterials = new StudentMaterials();
    }
}; 