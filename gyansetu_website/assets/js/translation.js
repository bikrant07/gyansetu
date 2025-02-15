// Check and apply saved language preference on page load
document.addEventListener('DOMContentLoaded', () => {
  const savedLang = localStorage.getItem('preferredLanguage');
  if (savedLang && savedLang !== 'en') {
    // Set cookies for Google Translate
    document.cookie = `googtrans=/en/${savedLang}; path=/; domain=.${window.location.hostname}`;
    document.cookie = `googtrans=/en/${savedLang}; path=/; domain=${window.location.hostname}`;
    
    // Force reload if translation hasn't been applied
    setTimeout(() => {
      const currentLang = document.documentElement.lang;
      if (currentLang === 'en' && savedLang !== 'en') {
        window.location.reload();
      }
    }, 1000);
  }
}); 