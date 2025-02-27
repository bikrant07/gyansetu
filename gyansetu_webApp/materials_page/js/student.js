function updateTopics() {
    const classSelect = document.getElementById('class-filter');
    const subjectSelect = document.getElementById('subject-filter');
    const topicSelect = document.getElementById('topic-filter');
    
    const selectedClass = classSelect.value;
    const selectedSubject = subjectSelect.value;
    
    // Clear existing topics
    topicSelect.innerHTML = '<option value="">All Topics</option>';
    
    // Handle subject visibility based on class selection
    if (selectedClass === 'Miscellaneous') {
        // Show only Languages and Technology options
        Array.from(subjectSelect.options).forEach(option => {
            if (['', 'Languages', 'Technology'].includes(option.value)) {
                option.style.display = '';
            } else {
                option.style.display = 'none';
            }
        });

        // Reset subject if not Languages or Technology
        if (selectedSubject && !['Languages', 'Technology'].includes(selectedSubject)) {
            subjectSelect.value = '';
        }

        // If a valid subject is selected, populate topics
        if (selectedSubject && window.topicsByClassAndSubject?.Miscellaneous?.[selectedSubject]) {
            const topics = window.topicsByClassAndSubject.Miscellaneous[selectedSubject];
            topics.forEach(topic => {
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

        // Reset subject if Languages or Technology
        if (['Languages', 'Technology'].includes(selectedSubject)) {
            subjectSelect.value = '';
        }

        // Load regular topics if available
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

// Keep the topics data structure
window.topicsByClassAndSubject = {
    'Class 6': {
        'Mathematics': ['Numbers and Operations', 'Basic Algebra', 'Geometry', 'Data Handling'],
        'Science': ['Living World', 'Materials', 'The Earth', 'Natural Phenomena'],
        'English': ['Grammar', 'Literature', 'Writing', 'Reading Comprehension'],
        'Social Studies': ['History', 'Geography', 'Civics', 'Economics'],
        'Computer': ['Basic Computing', 'Word Processing', 'Internet Basics', 'Digital Safety'],
        'Geography': ['Maps and Globes', 'Landforms', 'Climate', 'Natural Resources']
    },
    'Class 7': {
        'Mathematics': ['Integers', 'Fractions and Decimals', 'Algebra', 'Geometry and Mensuration'],
        'Science': ['Living Systems', 'Matter and Chemical Changes', 'Physical Phenomena', 'Environment'],
        'English': ['Advanced Grammar', 'Creative Writing', 'Literature Analysis', 'Comprehension Skills'],
        'Social Studies': ['Medieval History', 'Democracy', 'Geography', 'Social Issues'],
        'Computer': ['Programming Basics', 'Spreadsheets', 'Digital Communication', 'Cyber Security'],
        'Geography': ['Environment', 'Human Settlements', 'Natural Resources', 'Weather and Climate']
    },
    'Class 8': {
        'Mathematics': ['Quadratic Equations', 'Linear Equations', 'Geometry', 'Data Analysis'],
        'Science': ['Cell Structure', 'Chemical Reactions', 'Force and Pressure', 'Energy'],
        'English': ['Advanced Literature', 'Essay Writing', 'Speech and Debate', 'Critical Analysis'],
        'Social Studies': ['Modern History', 'Constitution', 'Economics', 'World Geography'],
        'Computer': ['Web Development', 'Database Concepts', 'Digital Design', 'Network Basics'],
        'Geography': ['Physical Geography', 'Population', 'Industries', 'Environmental Conservation']
    },
    'Class 9': {
        'Mathematics': ['Number Systems', 'Polynomials', 'Coordinate Geometry', 'Statistics'],
        'Science': ['Matter', 'Life Processes', 'Motion', 'Natural Resources'],
        'English': ['Literature and Poetry', 'Writing Skills', 'Grammar', 'Communication Skills'],
        'Social Studies': ['Contemporary India', 'Democratic Politics', 'Economics', 'Disaster Management'],
        'Computer': ['Programming', 'Data Structures', 'Web Technologies', 'Computer Networks'],
        'Geography': ['Contemporary India', 'Climate', 'Natural Vegetation', 'Population']
    },
    'Class 10': {
        'Mathematics': ['Real Numbers', 'Polynomials', 'Trigonometry', 'Statistics and Probability'],
        'Science': ['Chemical Reactions', 'Life Processes', 'Electricity', 'Environmental Issues'],
        'English': ['Advanced Literature', 'Writing Applications', 'Grammar and Usage', 'Reading Skills'],
        'Social Studies': ['India and Contemporary World', 'Democratic Politics', 'Economics Development', 'Resource Management'],
        'Computer': ['Advanced Programming', 'Database Management', 'Cyber Ethics', 'Mobile Computing'],
        'Geography': ['Resources and Development', 'Agriculture', 'Manufacturing Industries', 'Lifelines of Economy']
    },
    'Miscellaneous': {
        'Languages': ['Java', 'Python', 'Others'],
        'Technology': ['Basics of AI', 'Basics of Cloud Computing', 'Others']
    }
};

function filterMaterials() {
    const classFilter = document.getElementById('class-filter').value;
    const subjectFilter = document.getElementById('subject-filter').value;
    const topicFilter = document.getElementById('topic-filter').value;
    const materialsGrid = document.getElementById('materials-grid');
    
    // Check if all filters are selected
    if (!classFilter || !subjectFilter || !topicFilter) {
        materialsGrid.innerHTML = `
            <div class="select-prompt">
                <i class="fas fa-filter"></i>
                <p>Please select Class, Subject and Topic to view the content</p>
            </div>
        `;
        return;
    }

    const filteredMaterials = window.allMaterials.filter(material => {
        const matchesClass = material.class === classFilter;
        const matchesSubject = material.subject === subjectFilter;
        const matchesTopic = material.topic === topicFilter;
        
        return matchesClass && matchesSubject && matchesTopic;
    });

    if (filteredMaterials.length === 0) {
        materialsGrid.innerHTML = `
            <div class="no-content">
                <i class="fas fa-exclamation-circle"></i>
                <p>No content available for the selected filters</p>
            </div>
        `;
        return;
    }

    // Display the content directly in the materials grid
    const material = filteredMaterials[0];
    
    // Process content to wrap images in containers
    let processedContent = marked.parse(material.content);
    processedContent = processedContent.replace(
        /<img(.*?)>/g, 
        '<div class="image-container"><img$1></div>'
    );

    materialsGrid.innerHTML = `
        <div class="content-display">
            <div class="content-header">
                <h2>${material.topic}</h2>
                <div class="content-meta">
                    <span class="class-tag">${material.class}</span>
                    <span class="subject-tag">${material.subject}</span>
                </div>
            </div>
            <div class="content-body">
                ${processedContent}
            </div>
        </div>
    `;
}

// Modal related functions
function viewContent(materialId) {
    const material = window.allMaterials.find(m => m.id === materialId);
    if (!material) return;

    const modal = document.getElementById('content-modal');
    const contentDiv = document.getElementById('markdown-content');
    const materialsContainer = document.querySelector('.materials-container');
    
    try {
        window.scrollTo(0, 0);
        modal.scrollTo(0, 0);
        
        contentDiv.innerHTML = `
            <h1>${material.topic}</h1>
            <div class="material-meta">
                <span class="class-tag">${material.class}</span>
                <span class="subject-tag">${material.subject}</span>
            </div>
            ${marked.parse(material.content)}
        `;
        
        if (!document.querySelector('.back-to-materials')) {
            const backButton = document.createElement('button');
            backButton.className = 'back-to-materials';
            backButton.innerHTML = '<i class="fas fa-arrow-left"></i>';
            backButton.title = 'Back to Materials';
            backButton.onclick = closeModal;
            modal.appendChild(backButton);
        }
        
        modal.style.display = 'block';
        materialsContainer.classList.add('modal-open');
        document.addEventListener('keydown', handleEscKey);
        
    } catch (error) {
        contentDiv.innerHTML = `<div class="error">Error rendering content: ${error.message}</div>`;
    }
}

function closeModal() {
    const modal = document.getElementById('content-modal');
    const materialsContainer = document.querySelector('.materials-container');
    
    modal.style.display = 'none';
    materialsContainer.classList.remove('modal-open');
    modal.scrollTo(0, 0);
    document.removeEventListener('keydown', handleEscKey);
}

function handleEscKey(event) {
    if (event.key === 'Escape') {
        closeModal();
    }
}

async function loadMaterials() {
    try {
        const snapshot = await firebase.firestore()
            .collection('topic_contents')
            .get();
        
        window.allMaterials = [];
        snapshot.forEach(doc => {
            window.allMaterials.push({
                id: doc.id,
                ...doc.data()
            });
        });
        
        filterMaterials();
        
    } catch (error) {
        document.getElementById('materials-grid').innerHTML = 
            '<p class="error-message">Error loading materials. Please try again later.</p>';
    }
}

// Initialize when document is loaded
document.addEventListener('DOMContentLoaded', () => {
    loadMaterials();
    
    window.onclick = function(event) {
        const modal = document.getElementById('content-modal');
        if (event.target === modal) {
            closeModal();
        }
    };
});

// Export necessary functions to window
window.viewContent = viewContent;
window.closeModal = closeModal; 

// Update the function that renders markdown content
function renderMarkdownContent(content) {
    // Configure marked to handle images
    marked.setOptions({
        renderer: new marked.Renderer(),
        headerIds: true,
        gfm: true,
        breaks: true,
        pedantic: false,
        sanitize: false,
        smartLists: true,
        smartypants: true,
        xhtml: true
    });

    // Create a custom renderer
    const renderer = new marked.Renderer();
    
    // Override the image renderer with additional error handling
    renderer.image = function(href, title, text) {
        // Add a wrapper div for better control
        return `
            <div class="markdown-image-wrapper">
                <img 
                    src="${href}" 
                    alt="${text}" 
                    title="${title || ''}" 
                    crossorigin="anonymous" 
                    loading="lazy" 
                    onerror="this.onerror=null; this.src='../assets/images/image-placeholder.png'; this.classList.add('image-error');"
                    onload="this.classList.add('image-loaded')"
                >
                <div class="image-loading-placeholder">
                    <i class="fas fa-spinner fa-spin"></i>
                    <span>Loading image...</span>
                </div>
                <div class="image-error-message">
                    <i class="fas fa-exclamation-circle"></i>
                    <span>Failed to load image</span>
                </div>
            </div>
        `;
    };

    marked.setOptions({ renderer });

    // Convert markdown to HTML
    const htmlContent = marked(content);
    
    // Set the HTML content
    document.getElementById('markdown-content').innerHTML = htmlContent;
}

// Add these functions at the top of student.js
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

window.refreshQuizzes = function() {
    console.log('Refresh quizzes called');
    if (window.studentMaterials) {
        window.studentMaterials.loadAvailableQuizzes();
    } else {
        console.error('StudentMaterials not initialized');
        alert('Error: Please refresh the page');
    }
};