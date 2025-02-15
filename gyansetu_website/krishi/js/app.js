class WikiAPI {
    static cache = new Map();
    static CACHE_DURATION = 1000 * 60 * 60 * 24; // 24 hours

    static async init() {
        // Load cache from localStorage on startup
        try {
            const savedCache = localStorage.getItem('wikiCache');
            if (savedCache) {
                const parsed = JSON.parse(savedCache);
                Object.entries(parsed).forEach(([key, value]) => {
                    this.cache.set(key, value);
                });
            }
        } catch (e) {
            console.error('Error loading cache:', e);
        }
    }

    static async fetchContent(topic) {
        try {
            // Check cache first
            const cachedContent = this.getFromCache(topic);
            if (cachedContent) {
                console.log('Serving from cache:', topic);
                return cachedContent;
            }

            console.log('Fetching from Wikipedia:', topic);
            const encodedTopic = encodeURIComponent(topic);
            
            let url = `https://en.wikipedia.org/w/api.php?` + 
                `action=query&` +
                `format=json&` +
                `origin=*&` +
                `prop=extracts|pageimages&` +
                `titles=${encodedTopic}&` +
                `exintro=1&` +
                `explaintext=1&` +
                `piprop=thumbnail&` +
                `pithumbsize=400`;

            let content = await this.fetchAndProcess(url);
            
            if (!content) {
                // Try search API if direct lookup fails
                const searchUrl = `https://en.wikipedia.org/w/api.php?` +
                    `action=query&` +
                    `format=json&` +
                    `origin=*&` +
                    `list=search&` +
                    `srsearch=${encodedTopic}&` +
                    `srlimit=1`;

                const searchData = await this.fetchJson(searchUrl);
                if (searchData.query.search.length > 0) {
                    const exactTitle = searchData.query.search[0].title;
                    url = this.buildUrl(exactTitle);
                    content = await this.fetchAndProcess(url);
                }
            }

            if (!content) {
                throw new Error('Content not found');
            }

            // Store in cache and localStorage
            this.addToCache(topic, content);
            this.saveCache();
            return content;

        } catch (error) {
            console.error('Error fetching from Wikipedia:', error);
            throw new Error('Failed to load content. Please try again.');
        }
    }

    static async fetchJson(url) {
        const response = await fetch(url);
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        return await response.json();
    }

    static async fetchAndProcess(url) {
        const data = await this.fetchJson(url);
        const pages = data.query.pages;
        const pageId = Object.keys(pages)[0];
        
        if (pageId === '-1') return null;

        const page = pages[pageId];
        return {
            title: page.title,
            extract: page.extract || 'No content available.',
            thumbnail: page.thumbnail,
            url: `https://en.wikipedia.org/wiki/${encodeURIComponent(page.title)}`,
            cachedAt: Date.now()
        };
    }

    static buildUrl(title) {
        return `https://en.wikipedia.org/w/api.php?` +
            `action=query&` +
            `format=json&` +
            `origin=*&` +
            `prop=extracts|pageimages&` +
            `titles=${encodeURIComponent(title)}&` +
            `exintro=1&` +
            `explaintext=1&` +
            `piprop=thumbnail&` +
            `pithumbsize=1000`;
    }

    static getFromCache(topic) {
        const cached = this.cache.get(topic);
        if (!cached) return null;

        // Check if cache is still valid
        const age = Date.now() - cached.cachedAt;
        if (age > this.CACHE_DURATION) {
            this.cache.delete(topic);
            return null;
        }

        return cached;
    }

    static addToCache(topic, content) {
        // Limit cache size to prevent memory issues
        if (this.cache.size > 100) {
            // Remove oldest entries
            const entries = Array.from(this.cache.entries());
            const oldestEntries = entries
                .sort((a, b) => a[1].cachedAt - b[1].cachedAt)
                .slice(0, 10);
            
            oldestEntries.forEach(([key]) => this.cache.delete(key));
        }

        this.cache.set(topic, content);
    }

    // Optional: Method to clear cache
    static clearCache() {
        this.cache.clear();
        console.log('Cache cleared');
    }

    // Helper method to clean up search terms
    static cleanSearchTerm(topic) {
        // Remove special characters and extra spaces
        return topic.trim()
            .toLowerCase()
            .replace(/[^\w\s]/g, '')
            .replace(/\s+/g, ' ');
    }

    static saveCache() {
        try {
            const cacheObj = Object.fromEntries(this.cache);
            localStorage.setItem('wikiCache', JSON.stringify(cacheObj));
        } catch (e) {
            console.error('Error saving cache:', e);
        }
    }
}

// Initialize cache on load
WikiAPI.init();

class App {
    constructor() {
        console.log('App initializing...');
        this.contentQueue = Promise.resolve(); // For sequential loading
        this.initializeTopics();
        this.setupEventListeners();
        // Load initial content after a short delay
        setTimeout(() => this.loadContent('Agriculture'), 100);
    }

    async loadContent(topic) {
        // Queue the content loading
        this.contentQueue = this.contentQueue.then(() => this._loadContent(topic));
    }

    async _loadContent(topic) {
        const loader = document.getElementById('loader');
        const contentDiv = document.getElementById('articleContent');
        
        try {
            loader.style.display = 'flex';
            contentDiv.innerHTML = '';
            
            // Clean up the search term
            let searchTerm = topic;
            
            // Only append agriculture-related terms if the topic isn't already specific
            const agriculturalTerms = ['agriculture', 'farming', 'crop', 'plant', 'food'];
            const isAgricultural = agriculturalTerms.some(term => 
                searchTerm.toLowerCase().includes(term)
            );
            
            if (!isAgricultural) {
                // Try first without modification
                try {
                    const content = await WikiAPI.fetchContent(searchTerm);
                    if (content) {
                        this.displayContent(content, contentDiv);
                        return;
                    }
                } catch (e) {
                    // If direct search fails, try with agricultural context
                    searchTerm = `${topic} agriculture`;
                }
            }
            
            const content = await WikiAPI.fetchContent(searchTerm);
            this.displayContent(content, contentDiv);
            
        } catch (error) {
            console.error('Error loading content:', error);
            contentDiv.innerHTML = `
                <div class="error-message">
                    <i class="fas fa-exclamation-circle"></i>
                    <p>${error.message}</p>
                    <p>Try searching for a different term or check your internet connection.</p>
                </div>
            `;
        } finally {
            loader.style.display = 'none';
        }
    }

    displayContent(content, contentDiv) {
        contentDiv.innerHTML = `
            <article class="article-header">
                <h1>${content.title}</h1>
                ${content.thumbnail ? `
                    <div class="article-image">
                        <img src="${content.thumbnail.source}" 
                             alt="${content.title}"
                             loading="lazy"
                             style="width: 100%; height: auto; max-height: 500px; object-fit: contain;"
                             onerror="this.parentElement.style.display='none'"
                             onload="this.parentElement.classList.add('image-loaded')"
                        >
                        <div class="image-loading">
                            <div class="spinner"></div>
                        </div>
                    </div>
                ` : ''}
            </article>
            <div class="article-text">
                ${content.extract ? 
                    content.extract.split('\n').map(para => 
                        para ? `<p>${para}</p>` : ''
                    ).join('')
                    : '<p>No detailed content available for this topic.</p>'
                }
            </div>
            <div class="see-more-section">
                <h3>Want to learn more?</h3>
                <div class="see-more-options">
                    <a href="${content.url}" target="_blank" class="see-more-btn wiki-btn">
                        <i class="fab fa-wikipedia-w"></i>
                        Read full article on Wikipedia
                    </a>
                    <button class="see-more-btn related-btn" data-topic="${content.title}">
                        <i class="fas fa-book-open"></i>
                        Show related topics
                    </button>
                </div>
            </div>
        `;

        // Add image error handling
        const images = contentDiv.querySelectorAll('img');
        images.forEach(img => {
            img.addEventListener('error', () => {
                img.parentElement.style.display = 'none';
            });
            
            img.addEventListener('load', () => {
                img.parentElement.classList.add('image-loaded');
            });
        });
    }

    async showRelatedTopics(topic) {
        try {
            const relatedContent = await WikiAPI.fetchRelatedTopics(topic);
            const relatedSection = document.createElement('div');
            relatedSection.className = 'related-topics-section';
            relatedSection.innerHTML = `
                <h3>Related Topics</h3>
                <div class="related-topics-grid">
                    ${relatedContent.map(item => `
                        <div class="related-topic-card" data-topic="${item.title}">
                            <h4>${item.title}</h4>
                            <p>${item.extract?.substring(0, 100)}...</p>
                        </div>
                    `).join('')}
                </div>
            `;

            // Insert after the article content
            const articleContent = document.querySelector('.article-content');
            articleContent.appendChild(relatedSection);

            // Add click handlers for related topics
            relatedSection.querySelectorAll('.related-topic-card').forEach(card => {
                card.addEventListener('click', () => {
                    this.loadContent(card.dataset.topic);
                    window.scrollTo({ top: 0, behavior: 'smooth' });
                });
            });

        } catch (error) {
            console.error('Error loading related topics:', error);
        }
    }

    setupEventListeners() {
        // Search input enter key
        document.getElementById('searchTopic').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                const searchTerm = e.target.value;
                if (searchTerm) {
                    this.loadContent(searchTerm);
                }
            }
        });
        
        // Topic buttons click
        document.getElementById('topicsList').addEventListener('click', (e) => {
            if (e.target.classList.contains('topic-button')) {
                const topic = e.target.dataset.topic;
                this.loadContent(topic);
            }
        });
    }

    initializeTopics() {
        const topicsList = document.getElementById('topicsList');
        console.log('Initializing topics...', topicsList);
        
        if (!topicsList) {
            console.error('Topics list element not found! Make sure the HTML contains an element with id="topicsList"');
            return;
        }

        const agricultureTopics = {
            'Farming Basics': [
                'Agriculture',
                'Organic farming',
                'Crop rotation',
                'Soil preparation',
                'Seed selection'
            ],
            'Major Crops': [
                'Wheat farming',
                'Cotton farming',
                'Sugarcane farming',
                'Maize cultivation'
            ],
            'Soil & Water': [
                'Soil Types',
                'Irrigation Systems',
                'Soil Conservation'
            ],
            'Plant Protection': [
                'Pest Management',
                'Weed Control',
            ],
            'Practical Farming': [
                'Natural farming',
                'Greenhouse farming',
                'Intercropping',
            ],
            'Animal Farming': [
                'Fish Farming',
                'Animal Health',
            ]
        };

        try {
            // Generate HTML for topics
            topicsList.innerHTML = Object.entries(agricultureTopics)
                .map(([category, topics]) => {
                    console.log(`Rendering category: ${category}`);
                    return `
                        <div class="topic-category">
                            <h4 class="category-title">
                                <i class="fas fa-chevron-right"></i>
                                ${category}
                            </h4>
                            <div class="topic-list">
                                ${topics.map(topic => `
                                    <button class="topic-button" data-topic="${topic}">
                                        <i class="fas fa-leaf"></i>
                                        ${topic}
                                    </button>
                                `).join('')}
                            </div>
                        </div>
                    `;
                }).join('');
        } catch (error) {
            console.error('Error rendering topics:', error);
            topicsList.innerHTML = '<p>Error loading topics. Please refresh the page.</p>';
        }

        // Add click handlers for category expansion
        document.querySelectorAll('.category-title').forEach(title => {
            title.addEventListener('click', () => {
                console.log('Category clicked:', title.textContent.trim());
                title.classList.toggle('expanded');
                const topicList = title.nextElementSibling;
                topicList.style.maxHeight = title.classList.contains('expanded') 
                    ? `${topicList.scrollHeight}px` 
                    : '0';
            });
        });
    }

    initializeContribute() {
        const contributeBtn = document.querySelector('.btn-primary');
        contributeBtn.addEventListener('click', () => {
            const modal = document.createElement('div');
            modal.className = 'contribute-modal';
            modal.innerHTML = `
                <div class="modal-content">
                    <div class="modal-header">
                        <h3>Contribute to Gyansetu</h3>
                        <button class="close-btn"><i class="fas fa-times"></i></button>
                    </div>
                    <div class="modal-body">
                        <p>To contribute to agricultural knowledge:</p>
                        <div class="contribute-options">
                            <a href="https://en.wikipedia.org/wiki/Wikipedia:Contributing_to_Wikipedia" target="_blank" class="contribute-option">
                                <i class="fab fa-wikipedia-w"></i>
                                <span>Contribute to Wikipedia</span>
                            </a>
                            <a href="https://github.com" target="_blank" class="contribute-option">
                                <i class="fab fa-github"></i>
                                <span>Contribute to Gyansetu</span>
                            </a>
                        </div>
                    </div>
                </div>
            `;

            document.body.appendChild(modal);

            // Close modal
            modal.querySelector('.close-btn').addEventListener('click', () => {
                modal.remove();
            });
        });
    }

    showNotification(message, type = 'success') {
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        notification.innerHTML = `
            <i class="fas ${type === 'success' ? 'fa-check-circle' : 'fa-exclamation-circle'}"></i>
            <span>${message}</span>
        `;
        
        document.body.appendChild(notification);
        setTimeout(() => notification.remove(), 3000);
    }
}

class UIController {
    constructor() {
        this.initializeTheme();
        this.initializeBookmarks();
        this.initializeContribute();
        this.initializeSidebarToggle();
    }

    initializeTheme() {
        const themeToggle = document.querySelector('#themeToggle');
        if (!themeToggle) return;
        
        themeToggle.addEventListener('click', () => {
            const themeIcon = themeToggle.querySelector('i');
            document.documentElement.classList.toggle('dark-theme');
            
            if (themeIcon) {
                if (themeIcon.classList.contains('fa-moon')) {
                    themeIcon.classList.replace('fa-moon', 'fa-sun');
                } else {
                    themeIcon.classList.replace('fa-sun', 'fa-moon');
                }
            }
            
            // Save preference
            const isDark = document.documentElement.classList.contains('dark-theme');
            localStorage.setItem('darkMode', isDark);
            
            this.showToast(`${isDark ? 'Dark' : 'Light'} mode enabled`);
        });

        // Load saved preference
        if (localStorage.getItem('darkMode') === 'true') {
            document.documentElement.classList.add('dark-theme');
            themeIcon.classList.replace('fa-moon', 'fa-sun');
        }
    }

    initializeBookmarks() {
        const bookmarksBtn = document.querySelector('.btn-icon i.fa-bookmark').parentElement;
        const bookmarks = JSON.parse(localStorage.getItem('bookmarks') || '[]');

        bookmarksBtn.addEventListener('click', () => {
            const bookmarksPanel = document.createElement('div');
            bookmarksPanel.className = 'bookmarks-panel';
            bookmarksPanel.innerHTML = `
                <div class="bookmarks-header">
                    <h3>Bookmarks</h3>
                    <button class="close-btn"><i class="fas fa-times"></i></button>
                </div>
                <div class="bookmarks-list">
                    ${bookmarks.length ? bookmarks.map(bookmark => `
                        <div class="bookmark-item">
                            <span>${bookmark}</span>
                            <button class="remove-bookmark" data-topic="${bookmark}">
                                <i class="fas fa-trash"></i>
                            </button>
                        </div>
                    `).join('') : '<p>No bookmarks yet</p>'}
                </div>
            `;

            document.body.appendChild(bookmarksPanel);

            // Close panel
            bookmarksPanel.querySelector('.close-btn').addEventListener('click', () => {
                bookmarksPanel.remove();
            });

            // Handle bookmark clicks
            bookmarksPanel.querySelectorAll('.bookmark-item span').forEach(item => {
                item.addEventListener('click', () => {
                    const topic = item.textContent;
                    app.loadContent(topic);
                    bookmarksPanel.remove();
                });
            });

            // Handle bookmark removal
            bookmarksPanel.querySelectorAll('.remove-bookmark').forEach(btn => {
                btn.addEventListener('click', () => {
                    const topic = btn.dataset.topic;
                    this.removeBookmark(topic);
                    bookmarksPanel.remove();
                    this.initializeBookmarks(); // Refresh panel
                });
            });
        });
    }

    initializeContribute() {
        const contributeBtn = document.querySelector('.btn-primary');
        contributeBtn.addEventListener('click', () => {
            const modal = document.createElement('div');
            modal.className = 'contribute-modal';
            modal.innerHTML = `
                <div class="modal-content">
                    <div class="modal-header">
                        <h3>Contribute to Gyansetu</h3>
                        <button class="close-btn"><i class="fas fa-times"></i></button>
                    </div>
                    <div class="modal-body">
                        <p>To contribute to agricultural knowledge:</p>
                        <div class="contribute-options">
                            <a href="https://en.wikipedia.org/wiki/Wikipedia:Contributing_to_Wikipedia" target="_blank" class="contribute-option">
                                <i class="fab fa-wikipedia-w"></i>
                                <span>Contribute to Wikipedia</span>
                            </a>
                            <a href="https://github.com" target="_blank" class="contribute-option">
                                <i class="fab fa-github"></i>
                                <span>Contribute to Gyansetu</span>
                            </a>
                        </div>
                    </div>
                </div>
            `;

            document.body.appendChild(modal);

            // Close modal
            modal.querySelector('.close-btn').addEventListener('click', () => {
                modal.remove();
            });
        });
    }

    initializeSidebarToggle() {
        const toggleBtn = document.querySelector('.sidebar-toggle');
        const sidebar = document.querySelector('.sidebar');
        const overlay = document.querySelector('.sidebar-overlay');

        if (!toggleBtn || !sidebar) {
            console.error('Sidebar elements not found');
            return;
        }

        // Toggle sidebar
        toggleBtn.addEventListener('click', () => {
            console.log('Toggle clicked'); // Debug log
            sidebar.classList.toggle('active');
            overlay.classList.toggle('active');
            
            // Toggle icon
            const icon = toggleBtn.querySelector('i');
            icon.classList.toggle('fa-bars');
            icon.classList.toggle('fa-times');
        });

        // Close sidebar when clicking overlay
        overlay.addEventListener('click', () => {
            sidebar.classList.remove('active');
            overlay.classList.remove('active');
            toggleBtn.querySelector('i').classList.replace('fa-times', 'fa-bars');
        });
    }

    addBookmark(topic) {
        const bookmarks = JSON.parse(localStorage.getItem('bookmarks') || '[]');
        if (!bookmarks.includes(topic)) {
            bookmarks.push(topic);
            localStorage.setItem('bookmarks', JSON.stringify(bookmarks));
            this.showToast(`Bookmarked: ${topic}`);
        }
    }

    removeBookmark(topic) {
        const bookmarks = JSON.parse(localStorage.getItem('bookmarks') || '[]');
        const index = bookmarks.indexOf(topic);
        if (index > -1) {
            bookmarks.splice(index, 1);
            localStorage.setItem('bookmarks', JSON.stringify(bookmarks));
            this.showToast(`Removed bookmark: ${topic}`);
        }
    }

    showToast(message) {
        const toast = document.createElement('div');
        toast.className = 'toast';
        toast.textContent = message;
        document.body.appendChild(toast);
        setTimeout(() => toast.remove(), 3000);
    }
}

// Add error message styling
const styles = document.createElement('style');
styles.textContent = `
    .error-message {
        padding: 20px;
        background-color: #fee;
        border-radius: 8px;
        border-left: 4px solid #f44336;
        margin: 20px 0;
    }

    .error-message i {
        color: #f44336;
        margin-right: 10px;
    }

    .error-message p {
        color: #333;
        margin: 5px 0;
    }
`;
document.head.appendChild(styles);

// Then, at the very bottom of the file, add the initialization
document.addEventListener('DOMContentLoaded', () => {
    const app = new App();
    const ui = new UIController();
    
    app.loadContent('Seed Bank');
});

// Add service worker registration
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('/sw.js')
            .then(registration => console.log('ServiceWorker registered'))
            .catch(err => console.log('ServiceWorker registration failed:', err));
    });
}
