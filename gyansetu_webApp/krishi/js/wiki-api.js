// Wikipedia API related functions
class WikiAPI {
    static async fetchContent(searchTerm) {
        try {
            const formattedTerm = searchTerm.trim().replace(/\s+/g, '_');
            
            // First, try to get the page content using MediaWiki API
            const apiUrl = `https://en.wikipedia.org/w/api.php?action=query&format=json&origin=*&prop=extracts|pageimages&titles=${formattedTerm}&exintro=1&explaintext=1&pithumbsize=500`;

            const response = await fetch(apiUrl);
            const data = await response.json();

            // Process the response
            const pages = data.query.pages;
            const pageId = Object.keys(pages)[0];
            const page = pages[pageId];

            if (pageId === '-1') {
                throw new Error('Topic not found. Please try another search term.');
            }

            // Format the content
            let content = {
                title: page.title,
                extract: page.extract,
                thumbnail: page.thumbnail ? page.thumbnail.source : null
            };

            return this.formatContent(content);

        } catch (error) {
            throw error;
        }
    }

    static formatContent(content) {
        let html = `
            <div class="wiki-article">
                <h1>${content.title}</h1>
                ${content.thumbnail ? `
                    <div class="article-image">
                        <img src="${content.thumbnail}" alt="${content.title}">
                    </div>
                ` : ''}
                <div class="article-content">
                    ${content.extract.split('\n').map(paragraph => 
                        paragraph ? `<p>${paragraph}</p>` : ''
                    ).join('')}
                </div>
                <div class="article-footer">
                    <a href="https://en.wikipedia.org/wiki/${content.title.replace(/ /g, '_')}" 
                       target="_blank" 
                       class="read-more-btn">
                        Read more on Wikipedia
                        <i class="fas fa-external-link-alt"></i>
                    </a>
                </div>
            </div>
        `;
        return html;
    }
}