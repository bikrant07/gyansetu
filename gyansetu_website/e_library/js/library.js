// Initialize Firebase (assuming it's already initialized in your main app)
let currentUser = null;
let userRole = null;

// Add these constants at the top of the file
const DEFAULT_BOOK_COVER = '/assets/images/default-book-cover.jp';
const DEFAULT_MANUAL_COVER = '/assets/images/default-book-cover.jpg';

// Initialize the page
document.addEventListener('DOMContentLoaded', () => {
    // Check authentication state
    firebase.auth().onAuthStateChanged(user => {
        if (user) {
            const userData = JSON.parse(localStorage.getItem('userData'));
            if (!userData) {
                handleLogout();
                return;
            }

            currentUser = user;
            userRole = userData.role;

            // Show/hide teacher-specific elements
            const teacherElements = document.querySelectorAll('.teacher-only');
            teacherElements.forEach(el => {
                el.style.display = userRole === 'teacher' ? 'flex' : 'none';
            });

            // Load initial content
            loadBooks();
            if (userRole === 'teacher') {
                loadTeachingManuals();
            }

            // Initialize tabs for teachers
            initializeTabs();
        } else {
            window.location.href = '/login_page.html';
        }
    });

    // Add event listeners
    document.getElementById('class-filter').addEventListener('change', loadBooks);
    document.getElementById('subject-filter').addEventListener('change', loadBooks);
    document.getElementById('search-input').addEventListener('input', debounce(loadBooks, 300));
    document.getElementById('manual-search')?.addEventListener('input', debounce(loadTeachingManuals, 300));
});

function initializeTabs() {
    if (userRole !== 'teacher') return;

    const tabs = document.querySelectorAll('.tab-btn');
    const contents = document.querySelectorAll('.tab-content');

    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            // Remove active class from all tabs and contents
            tabs.forEach(t => t.classList.remove('active'));
            contents.forEach(c => c.classList.remove('active'));

            // Add active class to clicked tab and corresponding content
            tab.classList.add('active');
            document.getElementById(`${tab.dataset.tab}-tab`).classList.add('active');
        });
    });
}

async function loadBooks() {
    const booksGrid = document.getElementById('books-grid');
    const classFilter = document.getElementById('class-filter').value;
    const subjectFilter = document.getElementById('subject-filter').value;
    const searchQuery = document.getElementById('search-input').value.toLowerCase();

    booksGrid.innerHTML = '<div class="loading"><i class="fas fa-spinner fa-spin"></i><p>Loading books...</p></div>';

    try {
        // Construct the storage path - Updated to match your structure
        let path = 'books/students';
        if (classFilter) {
            path += `/class${classFilter}`;
            if (subjectFilter) {
                path += `/${subjectFilter}`;
            }
        }

        console.log('Fetching books from path:', path); // Debug log

        const storageRef = firebase.storage().ref(path);
        const result = await storageRef.listAll();

        // Filter and sort the books
        const books = await Promise.all(result.items
            .filter(item => {
                const name = item.name.toLowerCase();
                return !searchQuery || name.includes(searchQuery);
            })
            .map(async item => {
                try {
                    const url = await item.getDownloadURL();
                    const metadata = await item.getMetadata();
                    return { name: item.name, url, metadata };
                } catch (error) {
                    console.error('Error fetching book details:', error);
                    return null;
                }
            }));

        // Filter out any null results from failed fetches
        const validBooks = books.filter(book => book !== null);

        if (validBooks.length === 0) {
            booksGrid.innerHTML = `
                <div class="no-results">
                    <i class="fas fa-books"></i>
                    <p>No books found matching your criteria</p>
                    <p class="path-info">Searched in: ${path}</p>
                </div>
            `;
            return;
        }

        booksGrid.innerHTML = validBooks.map(book => `
            <div class="book-card">
                <div class="book-cover">
                    <div class="default-cover">
                        <i class="fas fa-book"></i>
                    </div>
                </div>
                <div class="book-info">
                    <h3 class="book-title">${formatBookName(book.name)}</h3>
                    <div class="book-meta">
                        <p><i class="fas fa-clock"></i> ${formatDate(book.metadata.timeCreated)}</p>
                        <p><i class="fas fa-file"></i> ${formatSize(book.metadata.size)}</p>
                    </div>
                    <div class="book-actions">
                        <button class="action-btn read-btn" onclick="openBook('${book.url}', '${book.name}')">
                            <i class="fas fa-book-reader"></i> Read
                        </button>
                        <button class="action-btn download-btn" onclick="downloadBook('${book.url}', '${book.name}')">
                            <i class="fas fa-download"></i> Download
                        </button>
                    </div>
                </div>
            </div>
        `).join('');

    } catch (error) {
        console.error('Error loading books:', error);
        booksGrid.innerHTML = `
            <div class="no-results">
                <i class="fas fa-exclamation-triangle"></i>
                <p>Error loading books. Please try again later.</p>
            </div>
        `;
    }
}

async function loadTeachingManuals() {
    if (userRole !== 'teacher') return;

    const manualsGrid = document.getElementById('manuals-grid');
    const searchQuery = document.getElementById('manual-search').value.toLowerCase();

    manualsGrid.innerHTML = '<div class="loading"><i class="fas fa-spinner fa-spin"></i><p>Loading manuals...</p></div>';

    try {
        const storageRef = firebase.storage().ref('/books/teacher');
        const result = await storageRef.listAll();

        const manuals = await Promise.all(result.items
            .filter(item => {
                const name = item.name.toLowerCase();
                return !searchQuery || name.includes(searchQuery);
            })
            .map(async item => {
                const url = await item.getDownloadURL();
                const metadata = await item.getMetadata();
                return { name: item.name, url, metadata };
            }));

        if (manuals.length === 0) {
            manualsGrid.innerHTML = `
                <div class="no-results">
                    <i class="fas fa-books"></i>
                    <p>No teaching manuals found</p>
                </div>
            `;
            return;
        }

        manualsGrid.innerHTML = manuals.map(manual => `
            <div class="book-card">
                <div class="book-cover">
                    <div class="default-cover">
                        <i class="fas fa-book"></i>
                        <div class="book-title-preview">${formatBookName(manual.name)}</div>
                    </div>
                </div>
                <div class="book-info">
                    <h3 class="book-title">${formatBookName(manual.name)}</h3>
                    <div class="book-meta">
                        <p><i class="fas fa-clock"></i> ${formatDate(manual.metadata.timeCreated)}</p>
                        <p><i class="fas fa-file"></i> ${formatSize(manual.metadata.size)}</p>
                    </div>
                    <div class="book-actions">
                        <button class="action-btn read-btn" onclick="openBook('${manual.url}', '${manual.name}')">
                            <i class="fas fa-book-reader"></i> Read
                        </button>
                        <button class="action-btn download-btn" onclick="downloadBook('${manual.url}', '${manual.name}')">
                            <i class="fas fa-download"></i> Download
                        </button>
                    </div>
                </div>
            </div>
        `).join('');

    } catch (error) {
        console.error('Error loading teaching manuals:', error);
        manualsGrid.innerHTML = `
            <div class="no-results">
                <i class="fas fa-exclamation-triangle"></i>
                <p>Error loading teaching manuals. Please try again later.</p>
            </div>
        `;
    }
}

function openBook(url, title) {
    // Open PDF in a new tab
    window.open(url, '_blank');
}

async function downloadBook(url, filename) {
    try {
        const response = await fetch(url);
        const blob = await response.blob();
        const downloadUrl = window.URL.createObjectURL(blob);
        
        const link = document.createElement('a');
        link.href = downloadUrl;
        link.download = filename;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        window.URL.revokeObjectURL(downloadUrl);
    } catch (error) {
        console.error('Error downloading book:', error);
        alert('Error downloading book. Please try again later.');
    }
}

// Utility Functions
function formatBookName(filename) {
    return filename
        .replace(/\.[^/.]+$/, '') // Remove file extension
        .split('_')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1))
        .join(' ');
}

function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString();
}

function formatSize(bytes) {
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    if (bytes === 0) return '0 Byte';
    const i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)));
    return Math.round(bytes / Math.pow(1024, i), 2) + ' ' + sizes[i];
}

function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Close modal when clicking outside
window.onclick = function(event) {
    const modal = document.getElementById('pdf-modal');
    if (event.target === modal) {
        closeModal();
    }
}

// Close modal with Escape key
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeModal();
    }
}); 