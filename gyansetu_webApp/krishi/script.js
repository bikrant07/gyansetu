 // API configuration
const API_BASE_URL = 'https://api.wikimedia.org/core/v1/wikipedia/en/page';

async function searchWikipedia() {
    const searchTerm = document.getElementById('searchTopic').value;
    const loader = document.getElementById('loader');
    const contentDiv = document.getElementById('wikiContent');

    if (!searchTerm) {
        showError('Please enter a search term');
        return;
    }

    try {
        // Show loader
        loader.style.display = 'flex';
        contentDiv.innerHTML = '';

        // Format search term for URL
        const formattedTerm = searchTerm.trim().replace(/\s+/g, '_');

        // Fetch content from Wikipedia API
        const response = await fetch(`${API_BASE_URL}/${formattedTerm}/html`, {
            headers: {
                'Authorization': 'Bearer YOUR_API_KEY', // If required
                'Accept': 'application/json',
            }
        });

        if (!response.ok) {
            throw new Error('Content not found');
        }

        const data = await response.json();
        
        // Process and display the content
        displayContent(data.html);

    } catch (error) {
        showError(error.message);
    } finally {
        loader.style.display = 'none';
    }
}

function displayContent(htmlContent) {
    const contentDiv = document.getElementById('wikiContent');
    
    // Create a temporary container
    const temp = document.createElement('div');
    temp.innerHTML = htmlContent;

    // Clean up the content
    cleanupContent(temp);

    // Add the processed content
    contentDiv.innerHTML = temp.innerHTML;

    // Add click handlers for references
    addReferenceHandlers();
}

function cleanupContent(element) {
    // Remove unwanted elements
    const unwanted = element.querySelectorAll('.mw-empty-elt, .mw-editsection');
    unwanted.forEach(el => el.remove());

    // Process images
    const images = element.querySelectorAll('img');
    images.forEach(img => {
        img.loading = 'lazy';
        img.classList.add('wiki-image');
    });

    // Process links
    const links = element.querySelectorAll('a');
    links.forEach(link => {
        if (link.href.startsWith('http')) {
            link.target = '_blank';
            link.rel = 'noopener noreferrer';
        }
    });
}

function addReferenceHandlers() {
    const refs = document.querySelectorAll('.reference-link');
    refs.forEach(ref => {
        ref.addEventListener('click', (e) => {
            e.preventDefault();
            const refContent = document.querySelector(ref.hash);
            if (refContent) {
                showReferencePopup(refContent.innerHTML, e);
            }
        });
    });
}

function showReferencePopup(content, event) {
    const popup = document.createElement('div');
    popup.className = 'reference-popup';
    popup.innerHTML = content;

    // Position the popup
    popup.style.left = `${event.pageX}px`;
    popup.style.top = `${event.pageY + 20}px`;

    document.body.appendChild(popup);

    // Close popup when clicking outside
    document.addEventListener('click', function closePopup(e) {
        if (!popup.contains(e.target)) {
            popup.remove();
            document.removeEventListener('click', closePopup);
        }
    });
}

function showError(message) {
    const contentDiv = document.getElementById('wikiContent');
    contentDiv.innerHTML = `
        <div class="error-message">
            <i class="fas fa-exclamation-circle"></i>
            ${message}
        </div>
    `;
}

// Add these styles for reference popups
const styles = `
.reference-popup {
    position: absolute;
    background: white;
    padding: 1rem;
    border-radius: 8px;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
    max-width: 300px;
    z-index: 1000;
}
`;

// Add styles to document
const styleSheet = document.createElement('style');
styleSheet.textContent = styles;
document.head.appendChild(styleSheet);