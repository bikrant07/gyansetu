class QuizManager {
    constructor() {
        this.questionCount = 0;
        try {
            this.db = firebase.database();
            console.log('Database initialized in QuizManager');
        } catch (error) {
            console.error('Failed to initialize database:', error);
        }
        this.init();
    }

    init() {
        // Check Firebase initialization
        if (!firebase.apps.length) {
            console.error('Firebase not initialized');
            return;
        }
        
        if (!this.db) {
            console.error('Database not initialized');
            return;
        }
        
        this.setupEventListeners();
        this.setupQuestionButtons();
        this.loadExistingQuizzes();
    }

    setupEventListeners() {
        document.getElementById('quiz-form').addEventListener('submit', (e) => {
            e.preventDefault();
            if (!this.validateForm()) {
                return;
            }
            this.handleSubmit();
        });

        // Add listeners for class and subject changes
        document.getElementById('qa-class')?.addEventListener('change', () => {
            console.log('Class changed, reloading quizzes...');
            this.loadExistingQuizzes();
        });

        document.getElementById('qa-subject')?.addEventListener('change', () => {
            console.log('Subject changed, reloading quizzes...');
            this.loadExistingQuizzes();
        });

        // Initial load of quizzes
        if (document.getElementById('qa-class')?.value && document.getElementById('qa-subject')?.value) {
            console.log('Initial quiz load...');
            this.loadExistingQuizzes();
        }
    }

    setupQuestionButtons() {
        document.querySelector('.add-question-btn.mcq')?.addEventListener('click', () => this.addMCQQuestion());
        document.querySelector('.add-question-btn.true-false')?.addEventListener('click', () => this.addTrueFalseQuestion());
        document.querySelector('.add-question-btn.short')?.addEventListener('click', () => this.addShortQuestion());
    }

    addQuestion() {
        this.questionCount++;
        const questionContainer = document.createElement('div');
        questionContainer.className = 'question-container';
        questionContainer.id = `question-${this.questionCount}`;

        questionContainer.innerHTML = `
            <div class="question-header">
                <h4>Question ${this.questionCount}</h4>
                <button type="button" class="remove-question-btn" onclick="quizManager.removeQuestion(${this.questionCount})">
                    <i class="fas fa-trash"></i>
                </button>
            </div>
            <div class="form-group">
                <label>Question Text:</label>
                <textarea class="question-text" required placeholder="Enter your question here"></textarea>
            </div>
            <div class="mcq-options">
                <div class="form-group">
                    <label>Option A:</label>
                    <div class="option-group">
                        <input type="text" class="option-text" data-option="A" required placeholder="Enter option A">
                    </div>
                </div>
                <div class="form-group">
                    <label>Option B:</label>
                    <div class="option-group">
                        <input type="text" class="option-text" data-option="B" required placeholder="Enter option B">
                    </div>
                </div>
                <div class="form-group">
                    <label>Option C:</label>
                    <div class="option-group">
                        <input type="text" class="option-text" data-option="C" required placeholder="Enter option C">
                    </div>
                </div>
                <div class="form-group">
                    <label>Option D:</label>
                    <div class="option-group">
                        <input type="text" class="option-text" data-option="D" required placeholder="Enter option D">
                    </div>
                </div>
                <div class="form-group">
                    <label>Correct Answer:</label>
                    <select class="correct-option" required>
                        <option value="">Select correct option</option>
                        <option value="A">Option A</option>
                        <option value="B">Option B</option>
                        <option value="C">Option C</option>
                        <option value="D">Option D</option>
                    </select>
                </div>
            </div>
        `;

        document.getElementById('questions-container').appendChild(questionContainer);
    }

    removeQuestion(questionId) {
        const question = document.getElementById(`question-${questionId}`);
        question.remove();
    }

    validateForm() {
        const questions = document.querySelectorAll('.question-container');
        if (questions.length === 0) {
            alert('Please add at least one question to the quiz');
            return false;
        }
        
        for (let i = 0; i < questions.length; i++) {
            const questionType = questions[i].dataset.type;
            const questionText = questions[i].querySelector('.question-text').value;
            
            if (!questionText.trim()) {
                alert(`Please enter the question text for question ${i + 1}`);
                return false;
            }
            
            switch (questionType) {
                case 'mcq':
                    const options = questions[i].querySelectorAll('.option-text');
                    const correctOption = questions[i].querySelector('.correct-option').value;
                    
                    for (let j = 0; j < options.length; j++) {
                        if (!options[j].value.trim()) {
                            alert(`Please enter all options for question ${i + 1}`);
                            return false;
                        }
                    }
                    
                    if (!correctOption) {
                        alert(`Please select the correct answer for question ${i + 1}`);
                        return false;
                    }
                    break;

                case 'true-false':
                    const selectedOption = questions[i].querySelector('input[type="radio"]:checked');
                    if (!selectedOption) {
                        alert(`Please select True or False for question ${i + 1}`);
                        return false;
                    }
                    break;

                case 'short':
                    // No additional validation needed for short answer questions
                    break;
            }
        }
        return true;
    }

    async handleSubmit() {
        try {
            const formData = this.gatherFormData();
            
            if (this.editingQuizId) {
                // Update existing quiz
                await this.db.ref(`quizzes/${this.editingQuizId}`).update({
                    ...formData,
                    lastUpdated: Date.now()
                });
                this.editingQuizId = null;  // Clear editing mode
            } else {
                // Create new quiz
                const user = firebase.auth().currentUser;
                if (!user) {
                    throw new Error('User not authenticated');
                }
                
                const newQuizRef = this.db.ref('quizzes').push();
                await newQuizRef.set({
                    ...formData,
                    teacherId: user.uid,
                    timestamp: Date.now()
                });
            }

            alert(this.editingQuizId ? 'Quiz updated successfully!' : 'Quiz saved successfully!');
            document.getElementById('quiz-form').reset();
            document.getElementById('questions-container').innerHTML = '';
            this.questionCount = 0;
            this.loadExistingQuizzes();
            
        } catch (error) {
            console.error('Error saving quiz:', error);
            alert(`Failed to ${this.editingQuizId ? 'update' : 'save'} quiz: ${error.message}`);
        }
    }

    gatherFormData() {
        const questions = [];
        document.querySelectorAll('.question-container').forEach(questionEl => {
            const questionType = questionEl.getAttribute('data-type') || 'mcq';
            const questionText = questionEl.querySelector('.question-text').value;
            const questionData = {
                type: questionType,
                text: questionText
            };

            switch (questionType) {
                case 'mcq':
                    const options = {};
                    questionEl.querySelectorAll('.option-text').forEach(optionEl => {
                        options[optionEl.dataset.option] = optionEl.value;
                    });
                    questionData.options = options;
                    questionData.correctOption = questionEl.querySelector('.correct-option').value;
                    break;

                case 'true-false':
                    const selectedOption = questionEl.querySelector('input[type="radio"]:checked');
                    questionData.correctAnswer = selectedOption ? selectedOption.value : null;
                    break;

                case 'short':
                    questionData.sampleAnswer = questionEl.querySelector('.sample-answer').value || '';
                    break;

                default:
                    console.error('Unknown question type:', questionType);
                    break;
            }

            questions.push(questionData);
        });

        console.log('Questions data:', questions);

        return {
            class: document.getElementById('qa-class').value,
            subject: document.getElementById('qa-subject').value,
            title: document.getElementById('qa-title').value,
            description: document.getElementById('qa-description').value,
            questions,
            timing: {
                startTime: document.getElementById('quiz-start-time').value,
                duration: parseInt(document.getElementById('quiz-duration').value),
                timestamp: Date.now()
            }
        };
    }

    async loadExistingQuizzes() {
        try {
            const listContainer = document.getElementById('quiz-list');
            const classValue = document.getElementById('qa-class').value;
            const subjectValue = document.getElementById('qa-subject').value;

            console.log('Loading quizzes for:', { class: classValue, subject: subjectValue });

            if (!classValue || !subjectValue) {
                listContainer.innerHTML = `
                    <div class="no-content-message">
                        <i class="fas fa-filter"></i>
                        <p>Please select Class and Subject to view quizzes</p>
                    </div>
                `;
                return;
            }

            // Get reference to quizzes in database
            const quizzesRef = this.db.ref('quizzes');
            console.log('Fetching quizzes from database...');

            // Get all quizzes
            const snapshot = await quizzesRef.once('value');
            const quizzes = snapshot.val();

            if (!quizzes) {
                console.log('No quizzes found in database');
                listContainer.innerHTML = `
                    <div class="no-content-message">
                        <i class="fas fa-folder-open"></i>
                        <p>No quizzes found for selected filters</p>
                    </div>
                `;
                return;
            }

            // Filter quizzes based on class and subject
            const filteredQuizzes = Object.entries(quizzes)
                .map(([id, quiz]) => ({ id, ...quiz }))
                .filter(quiz => quiz.class === classValue && quiz.subject === subjectValue);

            console.log('Filtered quizzes:', filteredQuizzes);

            if (filteredQuizzes.length === 0) {
                listContainer.innerHTML = `
                    <div class="no-content-message">
                        <i class="fas fa-folder-open"></i>
                        <p>No quizzes found for ${classValue} - ${subjectValue}</p>
                    </div>
                `;
                return;
            }

            // Sort quizzes by timestamp (newest first)
            filteredQuizzes.sort((a, b) => (b.timestamp || 0) - (a.timestamp || 0));

            listContainer.innerHTML = `
                <div class="content-list-header">
                    <h2>Existing Quizzes</h2>
                    <span class="content-count">${filteredQuizzes.length} items</span>
                </div>
                <div class="content-grid">
                    ${filteredQuizzes.map(quiz => this.renderQuizCard(quiz)).join('')}
                </div>
            `;

        } catch (error) {
            console.error('Error loading quizzes:', error);
            const listContainer = document.getElementById('quiz-list');
            listContainer.innerHTML = `
                <div class="no-content-message">
                    <i class="fas fa-exclamation-triangle"></i>
                    <p>Error loading quizzes. Please try again.</p>
                </div>
            `;
        }
    }

    renderQuizCard(quiz) {
        const startTime = new Date(quiz.timing?.startTime || Date.now());
        const formattedStartTime = startTime.toLocaleString();
        
        return `
            <div class="content-card">
                <div class="content-card-header">
                    <i class="fas fa-question-circle"></i>
                    <h3>${quiz.title}</h3>
                </div>
                <div class="content-card-meta">
                    <span class="class-tag">${quiz.class}</span>
                    <span class="subject-tag">${quiz.subject}</span>
                    <span class="question-count">${quiz.questions.length} questions</span>
                </div>
                <div class="content-card-timing">
                    <span class="timing-info">
                        <i class="fas fa-clock"></i> Starts: ${formattedStartTime}
                    </span>
                    <span class="duration-info">
                        <i class="fas fa-hourglass-half"></i> Duration: ${quiz.timing?.duration || 0} minutes
                    </span>
                </div>
                <div class="content-card-actions">
                    <button onclick="quizManager.viewQuiz('${quiz.id}')" class="action-btn view-btn">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button onclick="quizManager.editQuiz('${quiz.id}')" class="action-btn edit-btn">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button onclick="quizManager.deleteQuiz('${quiz.id}')" class="action-btn delete-btn">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </div>
        `;
    }

    async viewQuiz(id) {
        try {
            const quizSnapshot = await this.db.ref(`quizzes/${id}`).once('value');
            const quiz = quizSnapshot.val();
            
            if (!quiz) {
                throw new Error('Quiz not found');
            }

            const startTime = new Date(quiz.timing?.startTime || Date.now());
            const formattedStartTime = startTime.toLocaleString();

            const modalHtml = `
                <div class="quiz-preview-modal">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h2>${quiz.title}</h2>
                            <button class="close-modal">&times;</button>
                        </div>
                        <div class="modal-body">
                            <div class="quiz-meta">
                                <span class="class-tag">${quiz.class}</span>
                                <span class="subject-tag">${quiz.subject}</span>
                                <div class="quiz-timing">
                                    <p><i class="fas fa-clock"></i> Starts: ${formattedStartTime}</p>
                                    <p><i class="fas fa-hourglass-half"></i> Duration: ${quiz.timing?.duration || 0} minutes</p>
                                </div>
                                <p class="quiz-description">${quiz.description}</p>
                            </div>
                            <div class="questions-preview">
                                ${quiz.questions.map((question, index) => `
                                    <div class="question-preview">
                                        <h3>Question ${index + 1}</h3>
                                        <p class="question-text">${question.text}</p>
                                        ${this.renderQuestionOptions(question)}
                                    </div>
                                `).join('')}
                            </div>
                        </div>
                    </div>
                </div>
            `;

            // Add modal to page
            const modalContainer = document.createElement('div');
            modalContainer.innerHTML = modalHtml;
            document.body.appendChild(modalContainer);

            // Add event listeners
            const modal = modalContainer.querySelector('.quiz-preview-modal');
            const closeBtn = modal.querySelector('.close-modal');
            
            closeBtn.onclick = () => {
                modalContainer.remove();
            };

            // Close on outside click
            window.onclick = (event) => {
                if (event.target === modal) {
                    modalContainer.remove();
                }
            };

        } catch (error) {
            console.error('Error viewing quiz:', error);
            alert('Failed to load quiz preview');
        }
    }

    renderQuestionOptions(question) {
        switch (question.type) {
            case 'mcq':
                return `
                    <div class="options-preview">
                        ${Object.entries(question.options).map(([key, value]) => `
                            <div class="option ${key === question.correctOption ? 'correct' : ''}">
                                <span class="option-label">${key}:</span>
                                <span class="option-text">${value}</span>
                                ${key === question.correctOption ? '<span class="correct-badge">✓</span>' : ''}
                            </div>
                        `).join('')}
                    </div>
                `;
            case 'true-false':
                return `
                    <div class="true-false-preview">
                        <div class="option ${question.correctAnswer === 'true' ? 'correct' : ''}">
                            <span>True</span>
                            ${question.correctAnswer === 'true' ? '<span class="correct-badge">✓</span>' : ''}
                        </div>
                        <div class="option ${question.correctAnswer === 'false' ? 'correct' : ''}">
                            <span>False</span>
                            ${question.correctAnswer === 'false' ? '<span class="correct-badge">✓</span>' : ''}
                        </div>
                    </div>
                `;
            case 'short':
                return `
                    <div class="short-answer-preview">
                        <p class="sample-answer"><strong>Sample Answer:</strong> ${question.sampleAnswer || 'No sample answer provided'}</p>
                    </div>
                `;
            default:
                return '';
        }
    }

    async editQuiz(id) {
        try {
            // Fetch quiz data
            const quizSnapshot = await this.db.ref(`quizzes/${id}`).once('value');
            const quiz = quizSnapshot.val();
            
            if (!quiz) {
                throw new Error('Quiz not found');
            }

            // Store the quiz ID for updating
            this.editingQuizId = id;  // Add this line to track which quiz is being edited

            // Populate form fields
            document.getElementById('qa-class').value = quiz.class;
            document.getElementById('qa-subject').value = quiz.subject;
            document.getElementById('qa-title').value = quiz.title;
            document.getElementById('qa-description').value = quiz.description;
            
            // Add timing field population
            if (quiz.timing) {
                document.getElementById('quiz-start-time').value = quiz.timing.startTime;
                document.getElementById('quiz-duration').value = quiz.timing.duration;
            }

            // Clear existing questions
            document.getElementById('questions-container').innerHTML = '';
            this.questionCount = 0;

            // Add each question
            quiz.questions.forEach(question => {
                switch (question.type) {
                    case 'mcq':
                        this.addMCQQuestion(question);
                        break;
                    case 'true-false':
                        this.addTrueFalseQuestion(question);
                        break;
                    case 'short':
                        this.addShortQuestion(question);
                        break;
                }
            });

            // Modify form submission
            const form = document.getElementById('quiz-form');
            const originalSubmitHandler = form.onsubmit;
            
            form.onsubmit = async (e) => {
                e.preventDefault();
                if (!this.validateForm()) {
                    return;
                }
                
                try {
                    const formData = this.gatherFormData();
                    await this.db.ref(`quizzes/${this.editingQuizId}`).update({
                        ...formData,
                        lastUpdated: Date.now()
                    });
                    
                    alert('Quiz updated successfully!');
                    form.reset();
                    document.getElementById('questions-container').innerHTML = '';
                    this.questionCount = 0;
                    this.editingQuizId = null;  // Clear the editing ID
                    this.loadExistingQuizzes();
                    
                    // Restore original submit handler
                    form.onsubmit = originalSubmitHandler;
                    
                } catch (error) {
                    console.error('Error updating quiz:', error);
                    alert('Failed to update quiz');
                }
            };

            // Scroll to form
            document.querySelector('.upload-section').scrollIntoView({ behavior: 'smooth' });

        } catch (error) {
            console.error('Error editing quiz:', error);
            alert('Failed to load quiz for editing');
        }
    }

    async deleteQuiz(id) {
        if (confirm('Are you sure you want to delete this quiz?')) {
            try {
                await firebase.database().ref(`quizzes/${id}`).remove();
                alert('Quiz deleted successfully!');
                this.loadExistingQuizzes();
            } catch (error) {
                console.error('Error deleting quiz:', error);
                alert('Failed to delete quiz. Please try again.');
            }
        }
    }

    addMCQQuestion(existingQuestion = null) {
        this.questionCount++;
        const questionContainer = document.createElement('div');
        questionContainer.className = 'question-container';
        questionContainer.id = `question-${this.questionCount}`;
        questionContainer.setAttribute('data-type', 'mcq');

        questionContainer.innerHTML = `
            <div class="question-header">
                <h4>MCQ Question ${this.questionCount}</h4>
                <button type="button" class="remove-question-btn" data-question="${this.questionCount}">
                    <i class="fas fa-trash"></i>
                </button>
            </div>
            <div class="form-group">
                <label>Question Text:</label>
                <textarea class="question-text" required placeholder="Enter your question here">${existingQuestion?.text || ''}</textarea>
            </div>
            <div class="mcq-options">
                ${['A', 'B', 'C', 'D'].map(option => `
                    <div class="form-group">
                        <label>Option ${option}:</label>
                        <div class="option-group">
                            <input type="text" class="option-text" data-option="${option}" 
                                required placeholder="Enter option ${option}"
                                value="${existingQuestion?.options?.[option] || ''}">
                        </div>
                    </div>
                `).join('')}
                <div class="form-group">
                    <label>Correct Answer:</label>
                    <select class="correct-option" required>
                        <option value="">Select correct option</option>
                        ${['A', 'B', 'C', 'D'].map(option => `
                            <option value="${option}" ${existingQuestion?.correctOption === option ? 'selected' : ''}>
                                Option ${option}
                            </option>
                        `).join('')}
                    </select>
                </div>
            </div>
        `;

        // Add event listener for remove button
        questionContainer.querySelector('.remove-question-btn').addEventListener('click', (e) => {
            const questionId = e.target.closest('.remove-question-btn').dataset.question;
            this.removeQuestion(questionId);
        });

        document.getElementById('questions-container').appendChild(questionContainer);
    }

    addTrueFalseQuestion(existingQuestion = null) {
        this.questionCount++;
        const questionContainer = document.createElement('div');
        questionContainer.className = 'question-container';
        questionContainer.id = `question-${this.questionCount}`;
        questionContainer.setAttribute('data-type', 'true-false');

        questionContainer.innerHTML = `
            <div class="question-header">
                <h4>True/False Question ${this.questionCount}</h4>
                <button type="button" class="remove-question-btn" data-question="${this.questionCount}">
                    <i class="fas fa-trash"></i>
                </button>
            </div>
            <div class="form-group">
                <label>Question Text:</label>
                <textarea class="question-text" required placeholder="Enter your question here">${existingQuestion?.text || ''}</textarea>
            </div>
            <div class="true-false-options">
                <div class="form-group">
                    <label>
                        <input type="radio" name="correct-${this.questionCount}" value="true" 
                            ${existingQuestion?.correctAnswer === 'true' ? 'checked' : ''} required> True
                    </label>
                </div>
                <div class="form-group">
                    <label>
                        <input type="radio" name="correct-${this.questionCount}" value="false"
                            ${existingQuestion?.correctAnswer === 'false' ? 'checked' : ''} required> False
                    </label>
                </div>
            </div>
        `;

        // Add event listener for remove button
        questionContainer.querySelector('.remove-question-btn').addEventListener('click', (e) => {
            const questionId = e.target.closest('.remove-question-btn').dataset.question;
            this.removeQuestion(questionId);
        });

        document.getElementById('questions-container').appendChild(questionContainer);
    }

    addShortQuestion(existingQuestion = null) {
        this.questionCount++;
        const questionContainer = document.createElement('div');
        questionContainer.className = 'question-container';
        questionContainer.id = `question-${this.questionCount}`;
        questionContainer.setAttribute('data-type', 'short');

        questionContainer.innerHTML = `
            <div class="question-header">
                <h4>Short Answer Question ${this.questionCount}</h4>
                <button type="button" class="remove-question-btn" data-question="${this.questionCount}">
                    <i class="fas fa-trash"></i>
                </button>
            </div>
            <div class="form-group">
                <label>Question Text:</label>
                <textarea class="question-text" required placeholder="Enter your question here">${existingQuestion?.text || ''}</textarea>
            </div>
            <div class="short-answer">
                <div class="form-group">
                    <label>Sample Answer (Optional):</label>
                    <textarea class="sample-answer" placeholder="Enter a sample or expected answer">${existingQuestion?.sampleAnswer || ''}</textarea>
                </div>
            </div>
        `;

        // Add event listener for remove button
        questionContainer.querySelector('.remove-question-btn').addEventListener('click', (e) => {
            const questionId = e.target.closest('.remove-question-btn').dataset.question;
            this.removeQuestion(questionId);
        });

        document.getElementById('questions-container').appendChild(questionContainer);
    }
}

// Initialize when document is ready
window.QuizManager = QuizManager;
console.log('QuizManager loaded and available globally'); 