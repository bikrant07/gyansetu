class AssignmentManager {
    constructor() {
        console.log('AssignmentManager constructor called');
        this.db = firebase.database();
        this.saveAssignment = this.saveAssignment.bind(this);
        this.init();
    }

    init() {
        console.log('AssignmentManager init called');
        // Add click handler to save button
        const saveBtn = document.getElementById('save-assignment-btn');
        console.log('Save button found:', saveBtn);
        
        if (saveBtn) {
            saveBtn.onclick = () => {
                console.log('Save button clicked - direct handler');
                this.handleSave();
            };
        }
    }

    handleSave() {
        console.log('Handle save called');
        try {
            this.saveAssignment();
        } catch (error) {
            console.error('Save error:', error);
            alert('Error saving assignment: ' + error.message);
        }
    }

    validateForm() {
        console.log('Validating form');
        const fields = {
            class: document.getElementById('assignment-class').value,
            subject: document.getElementById('assignment-subject').value,
            title: document.getElementById('assignment-title').value,
            description: document.getElementById('assignment-description').value,
            content: document.getElementById('assignment-content').value,
            dueDate: document.getElementById('due-date').value
        };

        console.log('Form fields:', fields);

        if (!fields.class) {
            alert('Please select a class');
            return false;
        }
        if (!fields.subject) {
            alert('Please select a subject');
            return false;
        }
        if (!fields.title.trim()) {
            alert('Please enter a title');
            return false;
        }
        if (!fields.description.trim()) {
            alert('Please enter a description');
            return false;
        }
        if (!fields.content.trim()) {
            alert('Please enter content');
            return false;
        }
        if (!fields.dueDate) {
            alert('Please select a due date');
            return false;
        }

        return true;
    }

    gatherFormData() {
        return {
            class: document.getElementById('assignment-class').value,
            subject: document.getElementById('assignment-subject').value,
            title: document.getElementById('assignment-title').value,
            description: document.getElementById('assignment-description').value,
            content: document.getElementById('assignment-content').value,
            dueDate: document.getElementById('due-date').value
        };
    }

    saveAssignment() {
        console.log('Save assignment method called');
        
        if (!this.validateForm()) {
            console.log('Form validation failed');
            return;
        }

        try {
            const formData = this.gatherFormData();
            console.log('Assignment data:', formData);

            const user = firebase.auth().currentUser;
            if (!user) {
                alert('Please sign in to save assignments');
                return;
            }

            const assignmentsRef = this.db.ref('assignments');
            assignmentsRef.push({
                ...formData,
                teacherId: user.uid,
                timestamp: Date.now()
            })
            .then(() => {
                console.log('Assignment saved successfully');
                alert('Assignment saved successfully!');
                document.getElementById('assignment-form').reset();
            })
            .catch((error) => {
                console.error('Save error:', error);
                alert('Failed to save assignment: ' + error.message);
            });

        } catch (error) {
            console.error('Error:', error);
            alert('Error saving assignment: ' + error.message);
        }
    }
}

// Initialize when document loads
document.addEventListener('DOMContentLoaded', () => {
    console.log('Creating AssignmentManager instance');
    window.assignmentManager = new AssignmentManager();
});

// Re-initialize when switching to assignment tab
document.addEventListener('click', (e) => {
    if (e.target.matches('[data-tab="assignment"]')) {
        console.log('Assignment tab clicked');
        if (!window.assignmentManager) {
            window.assignmentManager = new AssignmentManager();
        } else {
            window.assignmentManager.init();
        }
    }
});