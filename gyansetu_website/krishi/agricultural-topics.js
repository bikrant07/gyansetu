const AGRICULTURAL_TOPICS = [
    'Agriculture',
    'Crop_rotation',
    'Irrigation',
    'Organic_farming',
    'Sustainable_agriculture',
    'Pesticide',
    'Fertilizer',
    'Soil_conservation',
    'Agricultural_machinery',
    'Greenhouse'
];

// Add suggested topics
function addSuggestedTopics() {
    const container = document.createElement('div');
    container.className = 'suggested-topics';
    container.innerHTML = `
        <h3>Suggested Topics</h3>
        <div class="topic-tags">
            ${AGRICULTURAL_TOPICS.map(topic => `
                <button onclick="searchSpecificTopic('${topic}')" class="topic-tag">
                    ${topic.replace(/_/g, ' ')}
                </button>
            `).join('')}
        </div>
    `;
    
    document.querySelector('.search-container').after(container);
}

function searchSpecificTopic(topic) {
    document.getElementById('searchTopic').value = topic;
    searchWikipedia();
}