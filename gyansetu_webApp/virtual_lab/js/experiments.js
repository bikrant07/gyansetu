document.addEventListener('DOMContentLoaded', function() {
    // Define correct answers for all experiments
    const experimentAnswers = {
        // Physics experiments
        'class9_physics1': {
            q1: 'b', // Angle of incidence equals angle of reflection
            q2: 'b'  // Same plane
        },
        'class9_physics2': {
            q1: 'c', // Weight of displaced fluid
            q2: 'b'  // Equal to weight of displaced fluid
        },
        // Chemistry experiments
        'class9_chemistry1': {
            q1: 'b', // Hydrogen gas
            q2: 'b'  // Salt and water
        },
        'class9_chemistry2': {
            q1: 'c', // Pink color
            q2: 'b'  // Salt and water
        },
        // Biology experiments
        'class9_biology1': {
            q1: 'b',
            q2: 'b'
        },
        'class9_biology2': {
            q1: 'c',
            q2: 'b'
        }
    };

    // Subject mapping for experiments
    const experimentSubjects = {
        'class9_physics1': 'physics',
        'class9_physics2': 'physics',
        'class9_chemistry1': 'chemistry',
        'class9_chemistry2': 'chemistry',
        'class9_biology1': 'biology',
        'class9_biology2': 'biology'
    };

    // Get current experiment ID from URL
    const currentPath = window.location.pathname;
    const experimentId = currentPath.split('/').pop().replace('.html', '');
    
    // Get current user ID (assuming it's stored after login)
    const currentUserId = localStorage.getItem('currentUserId') || 'guest';

    // Initialize progress tracking with user-specific key
    const progressKey = `experimentProgress_${currentUserId}`;
    let experimentProgress = JSON.parse(localStorage.getItem(progressKey)) || {};

    // Function to calculate subject progress
    function calculateSubjectProgress(subject) {
        const subjectExperiments = Object.keys(experimentAnswers).filter(
            expId => experimentSubjects[expId] === subject
        );
        
        let totalProgress = 0;
        let experimentsCount = 0;
        
        subjectExperiments.forEach(expId => {
            if (experimentProgress[expId]) {
                totalProgress += experimentProgress[expId].progress || 0;
                experimentsCount++;
            }
        });

        // Return average progress for the subject
        return experimentsCount > 0 ? Math.round(totalProgress / subjectExperiments.length) : 0;
    }

    // Function to update subject progress display
    function updateSubjectProgress(subject) {
        const progress = calculateSubjectProgress(subject);
        const progressElement = document.getElementById(`${subject}Progress`);
        const progressText = document.getElementById(`${subject}ProgressText`);
        
        if (progressElement && progressText) {
            progressElement.style.width = `${progress}%`;
            progressText.textContent = `Progress: ${progress}%`;
        }
    }

    // Function to update individual experiment progress
    function updateExperimentProgress(experimentId, progress, isCompleted) {
        experimentProgress[experimentId] = {
            progress: progress,
            completed: isCompleted,
            lastAttempt: new Date().toISOString()
        };
        localStorage.setItem(progressKey, JSON.stringify(experimentProgress));
        
        // Update the corresponding subject progress
        const subject = experimentSubjects[experimentId];
        if (subject) {
            updateSubjectProgress(subject);
        }
    }

    // Initialize quiz functionality if on an experiment page
    if (experimentId in experimentAnswers) {
        const correctAnswers = experimentAnswers[experimentId];
        const progressBar = document.getElementById('experimentProgress');
        const progressText = document.getElementById('progressText');
        const submitButton = document.getElementById('submitQuiz');
        const quizResult = document.getElementById('quizResult');

        // Display saved progress if any
        if (experimentProgress[experimentId]) {
            updateProgress(
                experimentProgress[experimentId].progress,
                experimentProgress[experimentId].completed
            );
        } else {
            // Initialize with 0 progress if no previous progress exists
            updateProgress(0, false);
        }

        function updateProgress(value, isCompleted) {
            if (progressBar && progressText) {
                progressBar.style.width = `${value}%`;
                progressText.textContent = `Progress: ${value}%`;
            }
            
            if (isCompleted && value === 100) {
                quizResult.innerHTML += '<p class="correct">🎉 Congratulations! Experiment successfully completed!</p>';
            }
            
            updateExperimentProgress(experimentId, value, isCompleted);
        }

        submitButton.addEventListener('click', function() {
            let score = 0;
            let feedback = '';
            let allCorrect = true;

            // Clear previous results
            quizResult.innerHTML = '';

            // Check Question 1
            const q1Answer = document.querySelector('input[name="q1"]:checked');
            if (q1Answer) {
                if (q1Answer.value === correctAnswers.q1) {
                    score += 50;
                    feedback += '<p class="correct">Question 1: Correct! ✓</p>';
                } else {
                    allCorrect = false;
                    feedback += '<p class="incorrect">Question 1: Incorrect. Please try again.</p>';
                }
            } else {
                allCorrect = false;
                feedback += '<p class="incorrect">Question 1: No answer selected.</p>';
            }

            // Check Question 2
            const q2Answer = document.querySelector('input[name="q2"]:checked');
            if (q2Answer) {
                if (q2Answer.value === correctAnswers.q2) {
                    score += 50;
                    feedback += '<p class="correct">Question 2: Correct! ✓</p>';
                } else {
                    allCorrect = false;
                    feedback += '<p class="incorrect">Question 2: Incorrect. Please try again.</p>';
                }
            } else {
                allCorrect = false;
                feedback += '<p class="incorrect">Question 2: No answer selected.</p>';
            }

            // Only show completion message if all answers are correct
            updateProgress(score, allCorrect);
            quizResult.innerHTML = feedback;
        });
    }

    // Initialize all subject progress bars on class page
    if (document.querySelector('.subject-tabs')) {  // Only run on class9.html page
        ['physics', 'chemistry', 'biology'].forEach(subject => {
            updateSubjectProgress(subject);
        });
    }
});