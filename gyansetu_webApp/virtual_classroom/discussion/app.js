// Initialize user data
let currentUser = null;
let currentUserData = null;
let currentChatId = 'public';
let currentChatPartner = null;

// Adjust chat container margin top to account for navbar height
// document.addEventListener("DOMContentLoaded", () => {
//     const navbar = document.querySelector(".navbar");
//     const chatContainer = document.querySelector("body");
//     const navbarHeight = navbar.offsetHeight;
//     chatContainer.style.marginTop = `70px`;
// });


// Display messages function
function displayMessages(messages) {
    const messagesDiv = document.getElementById('messages');
    if (!messagesDiv) return;
    
    messagesDiv.innerHTML = '';
    
    Object.keys(messages).forEach(key => {
        const message = messages[key];
        const messageElement = document.createElement('div');
        messageElement.className = `message ${message.userId === currentUser.uid ? 'sent' : 'received'}`;
        
        // Add translation button for received messages
        const translateButton = message.userId !== currentUser.uid ? 
            `<button onclick="translateMessage(this)" class="translate-btn">
                <i class="fas fa-language"></i>
            </button>` : '';

        messageElement.innerHTML = `
            <div class="message-header">
                <span class="user-name">${message.userName}</span>
                <span class="timestamp">${new Date(message.timestamp).toLocaleString()}</span>
                ${translateButton}
            </div>
            <div class="message-content" data-original="${message.text}">${message.text}</div>
        `;
        messagesDiv.appendChild(messageElement);
    });
    
    messagesDiv.scrollTop = messagesDiv.scrollHeight;
}

// Listen for auth state changes
firebase.auth().onAuthStateChanged(async (user) => {
    if (user) {
        currentUser = user;
        try {
            const userRef = firebase.database().ref('users/' + user.uid);
            
            // Get user data
            const snapshot = await userRef.once('value');
            currentUserData = snapshot.val();
            
            if (!currentUserData) {
                currentUserData = {
                    name: user.displayName || user.email.split('@')[0],
                    email: user.email,
                    lastSeen: Date.now(),
                    online: true,
                    role: 'student'
                };
                await userRef.set(currentUserData);
            }

            // Update online status
            await userRef.update({
                online: true,
                lastSeen: Date.now()
            });

            // Set offline on disconnect
            userRef.onDisconnect().update({
                online: false,
                lastSeen: Date.now()
            });

            // Display current user name
            document.getElementById('current-user-name').textContent = currentUserData.name;
            
            // Initialize chat and load users
            initializeChat();
            loadOnlineUsers();
            
            // Update navbar user info
            document.getElementById('userDisplayName').textContent = currentUserData.name;
            document.getElementById('userRole').textContent = `Role: ${currentUserData.role}`;
            
        } catch (error) {
            // console.error('Error loading user data:', error);
            // alert('Error loading user data: ' + error.message);
        }
    } else {
        window.location.href = 'login.html';
    }
});

// Load online users
function loadOnlineUsers() {
    const usersRef = firebase.database().ref('users');
    usersRef.on('value', (snapshot) => {
        const users = snapshot.val();
        const usersList = document.getElementById('users-list');
        
        usersList.innerHTML = `
            <div class="user-list-item ${currentChatId === 'public' ? 'active-chat' : ''}" 
                 onclick="switchToPublicChat()">
                <i class="fas fa-globe"></i>
                <span>Public Discussion</span>
            </div>
        `;
        
        if (users) {
            Object.keys(users).forEach(uid => {
                const user = users[uid];
                if (uid !== currentUser.uid) {
                    const userItem = document.createElement('div');
                    userItem.className = `user-list-item ${currentChatId.includes(uid) ? 'active-chat' : ''}`;
                    
                    // Only show online status if current user is a student and the other user is a teacher
                    // OR if current user is a teacher (they can see everyone's status)
                    const showOnlineStatus = 
                        (currentUserData.role === 'student' && user.role === 'teacher') ||
                        (currentUserData.role === 'teacher');
                    
                    userItem.innerHTML = `
                        <div class="online-indicator ${showOnlineStatus ? (user.online ? 'active' : 'inactive') : 'inactive'}" 
                             title="${showOnlineStatus ? (user.online ? 'Online' : 'Offline') : 'Status hidden'}">
                        </div>
                        <span>${user.name}</span>
                    `;
                    
                    userItem.addEventListener('click', () => startPrivateChat(uid, user));
                    usersList.appendChild(userItem);
                }
            });
        }
    });
}

// Start private chat
function startPrivateChat(targetUserId, targetUser) {
    const chatIds = [currentUser.uid, targetUserId].sort();
    currentChatId = chatIds.join('_');
    currentChatPartner = targetUser;
    
    document.querySelectorAll('.user-list-item').forEach(item => {
        item.classList.remove('active-chat');
    });
    event.currentTarget.classList.add('active-chat');
    
    document.getElementById('chat-title').textContent = `Chat with ${targetUser.name}`;
    initializeChat();
}

// Switch to public chat
function switchToPublicChat() {
    currentChatId = 'public';
    currentChatPartner = null;
    document.getElementById('chat-title').textContent = 'Public Discussion';
    
    document.querySelectorAll('.user-list-item').forEach(item => {
        item.classList.remove('active-chat');
    });
    event.currentTarget.classList.add('active-chat');
    
    initializeChat();
}

// Initialize chat
function initializeChat() {
    const messagesRef = firebase.database().ref(
        currentChatId === 'public' 
            ? 'messages/public' 
            : `messages/private/${currentChatId}`
    );
    
    // Remove previous listener if exists
    if (window.currentMessagesRef) {
        window.currentMessagesRef.off();
    }
    
    // Set new listener
    window.currentMessagesRef = messagesRef;
    messagesRef.on('value', (snapshot) => {
        const messages = snapshot.val();
        if (messages) {
            displayMessages(messages);
        } else {
            document.getElementById('messages').innerHTML = '';
        }
    });
}

// Send message function
async function sendMessage(messageText) {
    if (!currentUser || !messageText.trim()) return;
    
    try {
        const messagesRef = firebase.database().ref(
            currentChatId === 'public' 
                ? 'messages/public' 
                : `messages/private/${currentChatId}`
        );
        
        await messagesRef.push({
            text: messageText.trim(),
            userId: currentUser.uid,
            userName: currentUserData.name,
            timestamp: Date.now()
        });
    } catch (error) {
        console.error('Error sending message:', error);
        alert('Failed to send message');
    }
}

// Handle message form submission
document.getElementById('message-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const messageInput = document.getElementById('message-input');
    const messageText = messageInput.value.trim();
    
    if (messageText) {
        await sendMessage(messageText);
        messageInput.value = '';
    }
});

// Add logout handler function
async function handleLogout() {
    try {
        await firebase.auth().signOut();
        console.log('User logged out successfully');
        window.location.href = '../login_page.html';
    } catch (error) {
        console.error('Error logging out:', error);
        alert('Error logging out. Please try again.');
    }
}

// File handling function
async function handleFileUpload(file) {
    try {
        // Create unique filename
        const fileExt = file.name.split('.').pop();
        const fileName = `${Date.now()}_${Math.random().toString(36).substr(2, 9)}.${fileExt}`;
        const filePath = `uploads/${currentChatId}/${fileName}`;
        
        // Create storage reference
        const storageRef = firebase.storage().ref(filePath);
        
        // Create upload progress element
        const progressDiv = document.createElement('div');
        progressDiv.className = 'upload-progress';
        progressDiv.innerHTML = '<div class="upload-progress-bar" style="width: 0%"></div>';
        document.getElementById('messages').appendChild(progressDiv);
        
        // Upload file with progress tracking
        const uploadTask = storageRef.put(file);
        uploadTask.on('state_changed', 
            (snapshot) => {
                const progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
                progressDiv.querySelector('.upload-progress-bar').style.width = progress + '%';
            },
            (error) => {
                console.error('Upload error:', error);
                progressDiv.remove();
                alert('File upload failed');
            },
            async () => {
                // Get download URL
                const downloadURL = await uploadTask.snapshot.ref.getDownloadURL();
                progressDiv.remove();
                
                // Send message with file
                await sendMessage('', {
                    type: file.type.startsWith('image/') ? 'image' : 'file',
                    url: downloadURL,
                    name: file.name,
                    size: file.size
                });
            }
        );
    } catch (error) {
        console.error('File handling error:', error);
        alert('File upload failed');
    }
}

// Utility functions
function formatFileSize(bytes) {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB';
    return (bytes / 1048576).toFixed(1) + ' MB';
}

function formatTimestamp(timestamp) {
    return new Date(timestamp).toLocaleTimeString();
}

// Add file input listener
document.getElementById('file-input').addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (file) {
        if (file.size > 5 * 1024 * 1024) { // 5MB limit
            alert('File size must be less than 5MB');
            return;
        }
        handleFileUpload(file);
    }
});

// Add these new functions
async function translateMessage(button) {
    const messageContent = button.parentElement.nextElementSibling;
    const originalText = messageContent.getAttribute('data-original');
    
    // Toggle between original and translated text
    if (messageContent.getAttribute('data-translated')) {
        messageContent.textContent = originalText;
        messageContent.removeAttribute('data-translated');
        button.innerHTML = '<i class="fas fa-language"></i>';
        return;
    }

    try {
        button.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
        
        // Get user's preferred language from Google Translate
        const userLanguage = document.querySelector('.goog-te-combo')?.value || 'en';
        
        // Use Google Translate API
        const translateAPI = new google.translate.TranslateElement();
        google.translate.TranslateElement.getInstance().translateText(
            originalText,
            'en', // from language (assuming messages are in English)
            userLanguage, // to language
            function(result) {
                if (result) {
                    messageContent.textContent = result;
                    messageContent.setAttribute('data-translated', 'true');
                    button.innerHTML = '<i class="fas fa-undo"></i>';
                }
            }
        );
    } catch (error) {
        console.error('Translation error:', error);
        button.innerHTML = '<i class="fas fa-language"></i>';
        alert('Translation failed. Please try again.');
    }
}

