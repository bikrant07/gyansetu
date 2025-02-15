class Navbar extends HTMLElement {
    constructor() {
        super();
        this.innerHTML = `
            <nav class="navbar">
                <div class="nav-brand">
                    <img src="/assets/images/app_logo.png" alt="GyanSetu Logo" class="nav-logo">
                    <span class="nav-title">GYANSETU</span>
                </div>
                
                <div class="nav-links">
                    <a href="/index.html" class="nav-link"><i class="fas fa-home"></i> Home</a>
                    <div class="nav-dropdown">
                        <div class="dropdown-link">
                            <div>
                                <i class="fas fa-book"></i>
                                <span>ERMS</span>
                            </div>
                            <i class="fas fa-chevron-down"></i>
                        </div>
                        <div class="dropdown-content">
                            <a href="/e_library/index.html">
                                <i class="fas fa-book-reader"></i>
                                <span>e-Library</span>
                            </a>
                            <a href="/materials_page/materials.html">
                                <i class="fas fa-file-alt"></i>
                                <span>Materials</span>
                            </a>
                            <a href="/code_editor/index.html">
                                <i class="fas fa-code"></i>
                                <span>Code Editor</span>
                            </a>
                        </div>
                    </div>
                    <div class="nav-dropdown">
                        <div class="dropdown-link">
                            <div>
                                <i class="fas fa-chalkboard"></i>
                                <span>Classroom</span>
                            </div>
                            <i class="fas fa-chevron-down"></i>
                        </div>
                        <div class="dropdown-content">
                            <a href="/virtual_classroom/index.html">
                                <i class="fas fa-chalkboard-teacher"></i>
                                <span>Virtual Classroom</span>
                            </a>
                            <a href="/virtual_lab/index.html">
                                <i class="fas fa-flask"></i>
                                <span>Virtual Lab</span>
                            </a>
                        </div>
                    </div>
                    <div class="nav-dropdown">
                        <div class="dropdown-link">
                            <div>
                                <i class="fas fa-chart-line"></i>
                                <span>Analytics</span>
                            </div>
                            <i class="fas fa-chevron-down"></i>
                        </div>
                        <div class="dropdown-content">
                            <a href="/data_analytics/index.html">
                                <i class="fas fa-chart-line"></i>
                                <span>Data Analytics</span>
                            </a>
                            <a href="http://127.0.0.1:5000">
                                <i class="fas fa-chart-line"></i>
                                <span>Recommendation</span>
                            </a>
                        </div>
                    </div>
                   
                    <a href="/krishi/index.html" class="nav-link"><i class="fas fa-seedling"></i> Krishi</a>
                    <a href="/scholarship_portal/index.html" class="nav-link"><i class="fas fa-graduation-cap"></i> Scholarship</a>
                    
                </div>

                <div class="auth-section" id="auth-section">
                    <!-- Will be populated dynamically -->
                </div>

                <button class="nav-toggle">
                    <span class="hamburger"></span>
                </button>
            </nav>
        `;

        this.initializeNavbar();
    }

    initializeNavbar() {
        // Toggle mobile menu
        const navToggle = this.querySelector('.nav-toggle');
        const navLinks = this.querySelector('.nav-links');
        const navLinksItems = this.querySelectorAll('.nav-link');
        
        navToggle.addEventListener('click', () => {
            navToggle.classList.toggle('active');
            navLinks.classList.toggle('active');
            document.body.style.overflow = navLinks.classList.contains('active') ? 'hidden' : '';
        });

        // Close mobile menu when clicking outside
        document.addEventListener('click', (e) => {
            if (!navLinks.contains(e.target) && !navToggle.contains(e.target)) {
                navToggle.classList.remove('active');
                navLinks.classList.remove('active');
                document.body.style.overflow = '';
            }
        });

        // Close mobile menu when clicking on a link
        navLinksItems.forEach(link => {
            link.addEventListener('click', () => {
                navToggle.classList.remove('active');
                navLinks.classList.remove('active');
                document.body.style.overflow = '';
            });
        });

        // Check if user data exists in localStorage
        const userData = JSON.parse(localStorage.getItem('userData'));
        const authSection = this.querySelector('#auth-section');

        if (userData) {
            // User is logged in
            authSection.innerHTML = `
                <div class="profile-dropdown">
                    <button class="profile-btn">
                        <i class="fas fa-user-circle"></i>
                        <span class="profile-name">${userData?.name || 'User'}</span>
                        <i class="fas fa-chevron-down"></i>
                    </button>
                    <div class="dropdown-content">
                        <div class="dropdown-header">
                            <img src="${userData?.profileImageUrl}" alt="Profile" class="dropdown-profile-img">
                            <div class="dropdown-user-info">
                                <span class="dropdown-name">${userData?.name || 'User'}</span>
                                <span class="dropdown-role">${userData?.role || 'Student'}</span>
                            </div>
                        </div>
                        <div class="dropdown-divider"></div>
                        <a href="/profile.html" class="dropdown-item">
                            <i class="fas fa-user"></i> My Profile
                        </a>
             
                        <div class="dropdown-item language-section">
                            <i class="fas fa-language"></i> Language
                            <select class="language-select" onchange="changeLanguage(this.value)">
                                <option value="">Select Language</option>
                                <option value="en">English</option>
                                <option value="hi">हिंदी (Hindi)</option>
                                <option value="bn">বাংলা (Bengali)</option>
                                <option value="te">తెలుగు (Telugu)</option>
                                <option value="ta">தமிழ் (Tamil)</option>
                                <option value="mr">मराठी (Marathi)</option>
                                <option value="gu">ગુજરાતી (Gujarati)</option>
                                <option value="kn">ಕನ್ನಡ (Kannada)</option>
                                <option value="ml">മലയാളം (Malayalam)</option>
                                <option value="pa">ਪੰਜਾਬੀ (Punjabi)</option>
                            </select>
                        </div>
                        <div class="dropdown-divider"></div>
                        <a href="#" onclick="handleLogout()" class="dropdown-item text-danger">
                            <i class="fas fa-sign-out-alt"></i> Logout
                        </a>
                    </div>
                </div>
            `;
        } else {
            // User is not logged in
            authSection.innerHTML = `
                <a href="/login_page.html" class="auth-btn combined-btn">
                    <i class="fas fa-user"></i> Login/SignUp
                </a>
            `;
        }

        // Also listen for auth state changes
        firebase.auth().onAuthStateChanged(user => {
            if (!user && userData) {
                // User is logged out but userData exists
                localStorage.removeItem('userData');
                window.location.reload();
            }
        });
    }
}

customElements.define('nav-bar', Navbar);

// Add this to your HTML
document.getElementById('navbar-container').innerHTML = '<nav-bar></nav-bar>';

// Logout handler
async function handleLogout() {
    try {
        await firebase.auth().signOut();
        localStorage.removeItem('userData');
        sessionStorage.clear();
        window.location.href = '/login_page.html';
    } catch (error) {
        console.error('Error logging out:', error);
        alert('Error logging out. Please try again.');
        // If error is due to invalid configuration, try clearing storage anyway
        if (error.code === 'auth/invalid-api-key') {
            localStorage.removeItem('userData');
            sessionStorage.clear();
            window.location.href = '/login_page.html';
        }
    }
}

function changeLanguage(lang) {
    if (!lang) return;
    
    // Get Google Translate element
    const googleTranslateElement = document.querySelector('#google_translate_element');
    
    if (googleTranslateElement) {
        // Get the select element from Google Translate
        const selectElement = googleTranslateElement.querySelector('select');
        if (selectElement) {
            // Set the value and trigger change event
            selectElement.value = lang;
            selectElement.dispatchEvent(new Event('change'));
        } else {
            // If select element is not found, use Google Translate API directly
            const iframe = document.querySelector('.goog-te-menu-frame');
            if (iframe) {
                const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
                const select = iframeDoc.querySelector('select.goog-te-combo');
                if (select) {
                    select.value = lang;
                    select.dispatchEvent(new Event('change'));
                }
            }
        }
    }

    // Use Google Translate API directly as fallback
    if (typeof google !== 'undefined' && google.translate) {
        const select = document.querySelector('.goog-te-combo');
        if (select) {
            select.value = lang;
            select.dispatchEvent(new Event('change'));
        } else {
            google.translate.TranslateElement({
                pageLanguage: 'en',
                includedLanguages: lang,
                layout: google.translate.TranslateElement.InlineLayout.SIMPLE,
                autoDisplay: true,
            }, 'google_translate_element');
        }
    }
} 