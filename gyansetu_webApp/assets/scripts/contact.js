// Wait for DOM content to be loaded
document.addEventListener('DOMContentLoaded', function() {
    // Initialize EmailJS with your public key
    emailjs.init("QHOIy3WxG1b2gFwAB");

    // Add input event listeners for real-time validation
    const nameInput = document.getElementById('name');
    const emailInput = document.getElementById('email');

    if (nameInput) {
        nameInput.addEventListener('input', validateName);
    }
    if (emailInput) {
        emailInput.addEventListener('input', validateEmail);
    }
});

// Validation functions
function validateName(e) {
    const nameInput = e.target;
    const nameValue = nameInput.value.trim();
    const nameRegex = /^[a-zA-Z\s'-]+$/;  // Allows letters, spaces, hyphens, and apostrophes

    if (nameValue === '') {
        setInputError(nameInput, 'Name is required');
        return false;
    } else if (!nameRegex.test(nameValue)) {
        setInputError(nameInput, 'Name should only contain letters');
        return false;
    } else if (nameValue.length < 2) {
        setInputError(nameInput, 'Name is too short');
        return false;
    } else if (nameValue.length > 50) {
        setInputError(nameInput, 'Name is too long');
        return false;
    } else {
        clearInputError(nameInput);
        return true;
    }
}

function validateEmail(e) {
    const emailInput = e.target;
    const emailValue = emailInput.value.trim();
    const emailRegex = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

    if (emailValue === '') {
        setInputError(emailInput, 'Email is required');
        return false;
    } else if (!emailRegex.test(emailValue)) {
        setInputError(emailInput, 'Please enter a valid email address');
        return false;
    } else {
        clearInputError(emailInput);
        return true;
    }
}

function setInputError(input, message) {
    const formGroup = input.parentElement;
    const errorDisplay = formGroup.querySelector('.error-message') || createErrorElement(formGroup);
    
    input.classList.add('error');
    errorDisplay.textContent = message;
    errorDisplay.style.display = 'block';
}

function clearInputError(input) {
    const formGroup = input.parentElement;
    const errorDisplay = formGroup.querySelector('.error-message');
    
    input.classList.remove('error');
    if (errorDisplay) {
        errorDisplay.textContent = '';
        errorDisplay.style.display = 'none';
    }
}

function createErrorElement(formGroup) {
    const errorDisplay = document.createElement('div');
    errorDisplay.className = 'error-message';
    formGroup.appendChild(errorDisplay);
    return errorDisplay;
}

async function sendEmail() {
    const form = document.getElementById('contact-form');
    const submitBtn = form.querySelector('.submit-btn');
    const btnText = submitBtn.querySelector('.btn-text');
    const loadingSpinner = submitBtn.querySelector('.loading-spinner');
    
    const nameInput = document.getElementById('name');
    const emailInput = document.getElementById('email');
    const messageInput = document.getElementById('message');

    // Validate all fields
    const isNameValid = validateName({ target: nameInput });
    const isEmailValid = validateEmail({ target: emailInput });
    const isMessageValid = messageInput.value.trim() !== '';

    if (!isMessageValid) {
        setInputError(messageInput, 'Message is required');
        return;
    } else {
        clearInputError(messageInput);
    }

    if (!isNameValid || !isEmailValid || !isMessageValid) {
        showNotification('Please fix the errors in the form', 'error');
        return;
    }

    submitBtn.disabled = true;
    btnText.style.display = 'none';
    loadingSpinner.style.display = 'inline-block';

    try {
        // Send email using EmailJS
        const response = await emailjs.send(
            "service_ff8hm4z",
            "template_24dtict",
            {
                from_name: nameInput.value.trim(),
                reply_to: emailInput.value.trim(),
                message: messageInput.value.trim(),
                to_name: "GyanSetu Team"
            }
        );

        if (response.status === 200) {
            showNotification('Message sent successfully!', 'success');
            form.reset();
            // Clear any remaining error states
            [nameInput, emailInput, messageInput].forEach(input => clearInputError(input));
        } else {
            throw new Error('Failed to send message');
        }
    } catch (error) {
        console.error('Error sending email:', error);
        showNotification('Failed to send message. Please try again.', 'error');
    } finally {
        submitBtn.disabled = false;
        btnText.style.display = 'inline-block';
        loadingSpinner.style.display = 'none';
    }
}

function showNotification(message, type) {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.innerHTML = `
        <div class="notification-content">
            <i class="fas ${type === 'success' ? 'fa-check-circle' : 'fa-exclamation-circle'}"></i>
            <span>${message}</span>
        </div>
    `;

    document.body.appendChild(notification);

    setTimeout(() => {
        notification.remove();
    }, 3000);
} 