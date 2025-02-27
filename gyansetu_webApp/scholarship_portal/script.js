// Add CORS Anywhere proxy URL
//const PROXY_URL = "https://cors-anywhere.herokuapp.com/";
const PROXY_URL = "https://api.allorigins.win/get?url=";
const BASE_URL = "https://services.india.gov.in/service/listing?cat_id=66&ln=en";
const SCHOLARSHIPS_PER_PAGE = 10;

document.addEventListener("DOMContentLoaded", () => {
    let scholarships = [];
    let originalOrder = [];
    let filteredScholarships = [];
    let currentPage = 1;

    // Add filter event listeners
    document.getElementById('stateFilter').addEventListener('change', applyStateFilter);
    document.getElementById('resetFilters').addEventListener('click', resetFilter);

    function applyStateFilter() {
        const stateFilter = document.getElementById('stateFilter').value.toLowerCase();
        currentPage = 1; // Reset to the first page when filtering
    
        // Filter scholarships based on the selected state
        filteredScholarships = scholarships.filter(scholarship => {
            return stateFilter && (
                scholarship.title.toLowerCase().includes(stateFilter) || 
                scholarship.description.toLowerCase().includes(stateFilter)
            );
        });
    
        // If no scholarships match, show a message
        if (filteredScholarships.length === 0) {
            const container = document.getElementById("scholarship-container");
            container.innerHTML = `
                <div class="no-results">
                    <i class="fas fa-search"></i>
                    <p>No scholarships found for this state yet</p>
                </div>
            `;
            return; // Stop further execution
        }
    
        // Display the filtered scholarships
        displayScholarships();
    }
    

    function resetFilter() {
        document.getElementById('stateFilter').value = '';
        filteredScholarships = [...scholarships];
        currentPage = 1;
        displayScholarships();
    }

    function createPagination(totalItems) {
        const totalPages = Math.ceil(totalItems / SCHOLARSHIPS_PER_PAGE);
        const paginationContainer = document.createElement('div');
        paginationContainer.className = 'pagination';

        // Previous button
        const prevBtn = document.createElement('button');
        prevBtn.innerHTML = '&laquo; Previous';
        prevBtn.className = 'pagination-btn';
        prevBtn.disabled = currentPage === 1;
        prevBtn.onclick = () => {
            if (currentPage > 1) {
                currentPage--;
                displayScholarships();
            }
        };

        // Next button
        const nextBtn = document.createElement('button');
        nextBtn.innerHTML = 'Next &raquo;';
        nextBtn.className = 'pagination-btn';
        nextBtn.disabled = currentPage === totalPages;
        nextBtn.onclick = () => {
            if (currentPage < totalPages) {
                currentPage++;
                displayScholarships();
            }
        };

        // Page info
        const pageInfo = document.createElement('span');
        pageInfo.className = 'page-info';
        pageInfo.textContent = `Page ${currentPage} of ${totalPages}`;

        paginationContainer.appendChild(prevBtn);
        paginationContainer.appendChild(pageInfo);
        paginationContainer.appendChild(nextBtn);

        return paginationContainer;
    }

    function displayScholarships() {
        const container = document.getElementById("scholarship-container");
        container.innerHTML = '';

        const scholarshipsToDisplay = filteredScholarships.length > 0 ? filteredScholarships : scholarships;

        if (scholarshipsToDisplay.length === 0) {
            container.innerHTML = `
                <div class="no-results">
                    <i class="fas fa-search"></i>
                    <p>No scholarships found for this state</p>
                </div>
            `;
            return;
        }

        // Calculate pagination
        const startIndex = (currentPage - 1) * SCHOLARSHIPS_PER_PAGE;
        const endIndex = startIndex + SCHOLARSHIPS_PER_PAGE;
        const paginatedScholarships = scholarshipsToDisplay.slice(startIndex, endIndex);

        paginatedScholarships.forEach((scholarship, index) => {
            const card = document.createElement("div");
            card.className = "card";
            card.innerHTML = `
                <div class="card-header">
                    <span class="scholarship-number">
                        <i class="fas fa-graduation-cap"></i>
                        Scholarship ${scholarship.number}
                    </span>
                    <button class="favorite-btn ${scholarship.favorite ? 'active' : ''}" 
                            onclick="toggleFavorite(${startIndex + index})">
                        ★
                    </button>
                </div>
                <div class="card-content">
                    <h2 class="card-title">${scholarship.title}</h2>
                    <p class="card-description">${scholarship.description}</p>
                    <a href="${scholarship.link}" target="_blank" class="apply-btn">Apply Now</a>
                </div>
            `;
            container.appendChild(card);
        });

        // Add pagination controls
        const paginationControls = createPagination(scholarshipsToDisplay.length);
        container.appendChild(paginationControls);
    }

    async function getTotalPages() {
        try {
            const response = await fetch(`${PROXY_URL}${encodeURIComponent(BASE_URL)}`);
            const data = await response.json();
            const content = data.contents; // Extract the actual HTML content
    
            const parser = new DOMParser();
            const doc = parser.parseFromString(content, "text/html");
    
            // Find the last page number from pagination
            const paginationLinks = doc.querySelectorAll('.pagination a');
            let maxPage = 1;
    
            paginationLinks.forEach(link => {
                const pageNum = parseInt(link.textContent);
                if (!isNaN(pageNum) && pageNum > maxPage) {
                    maxPage = pageNum;
                }
            });
    
            console.log(`Total pages found: ${maxPage}`);
            return maxPage;
        } catch (error) {
            console.error("Error getting total pages:", error);
            return 1;
        }
    }
    
    async function fetchScholarshipsFromPage(pageNum) {
        const url = `${BASE_URL}&page_no=${pageNum}`;
        try {
            console.log(`Fetching page ${pageNum}...`);
            const response = await fetch(`${PROXY_URL}${encodeURIComponent(url)}`);
            const data = await response.json();
            const content = data.contents; // Extract the actual HTML content
    
            const parser = new DOMParser();
            const doc = parser.parseFromString(content, "text/html");
            const entries = Array.from(doc.querySelectorAll(".edu-lern-con"));
    
            console.log(`Found ${entries.length} scholarships on page ${pageNum}`);
            return entries;
        } catch (error) {
            console.error(`Error fetching page ${pageNum}:`, error);
            return [];
        }
    }
    

    async function fetchAllScholarships() {
        try {
            // Check if we have cached data and it's less than 24 hours old
            const cachedData = localStorage.getItem('scholarshipsData');
            const cacheTimestamp = localStorage.getItem('scholarshipsCacheTime');
            const CACHE_DURATION = 24 * 60 * 60 * 1000; // 24 hours in milliseconds

            if (cachedData && cacheTimestamp) {
                const age = Date.now() - parseInt(cacheTimestamp);
                if (age < CACHE_DURATION) {
                    console.log('Using cached scholarship data');
                    scholarships = JSON.parse(cachedData);
                    originalOrder = [...scholarships];
                    filteredScholarships = [...scholarships];
                    displayScholarships();
                    return;
                }
            }

            const totalPages = await getTotalPages();
            let allScholarshipEntries = [];
            
            // Show loading message
            const container = document.getElementById("scholarship-container");
            container.innerHTML = `
                <div class="loading-message">
                    <i class="fas fa-spinner fa-spin"></i>
                    <p>Loading scholarships... Please wait...</p>
                </div>
            `;

            // Fetch all pages
            for (let pageNum = 1; pageNum <= totalPages; pageNum++) {
                const entries = await fetchScholarshipsFromPage(pageNum);
                allScholarshipEntries = [...allScholarshipEntries, ...entries];
                
                // Update loading message with progress
                container.innerHTML = `
                    <div class="loading-message">
                        <i class="fas fa-spinner fa-spin"></i>
                        <p>Loading scholarships... (Page ${pageNum}/${totalPages})</p>
                        <p>Found ${allScholarshipEntries.length} scholarships so far</p>
                    </div>
                `;
            }

            // Process and store the scholarships
            scholarships = allScholarshipEntries.map((entry, index) => {
                const title = entry.querySelector("h3")?.textContent.trim() || "No Title Available";
                const link = entry.querySelector("a")?.href || "#";
                const description = entry.querySelector("p")?.textContent.trim() || "No Description Available";

                return {
                    number: index + 1,
                    title,
                    link,
                    description,
                    favorite: false,
                    originalPosition: index
                };
            });

            // Cache the processed data
            localStorage.setItem('scholarshipsData', JSON.stringify(scholarships));
            localStorage.setItem('scholarshipsCacheTime', Date.now().toString());

            originalOrder = [...scholarships];
            filteredScholarships = [...scholarships];
            displayScholarships();
            
            // Show total count
            const totalCount = document.createElement('div');
            totalCount.className = 'total-count';
            totalCount.innerHTML = `Total Scholarships Available: ${scholarships.length}`;
            container.insertBefore(totalCount, container.firstChild);

        } catch (error) {
            console.error("Error fetching scholarships:", error);
            const container = document.getElementById("scholarship-container");
            container.innerHTML = `<p style="color: #ff7675; text-align: center; padding: 2rem;">Unable to load scholarships at this time. Please try again later.</p>`;
        }
    }

    // Start fetching scholarships
    fetchAllScholarships();

    window.toggleFavorite = function(index) {
        const scholarship = scholarships[index];
        scholarship.favorite = !scholarship.favorite;

        if (scholarship.favorite) {
            scholarships = [
                scholarship,
                ...scholarships.filter(s => s !== scholarship)
            ];
        } else {
            scholarships = scholarships.filter(s => s !== scholarship);
            const originalIndex = scholarship.originalPosition;
            
            scholarships = [
                ...scholarships.slice(0, originalIndex),
                scholarship,
                ...scholarships.slice(originalIndex)
            ];
        }

        filteredScholarships = [...scholarships];
        applyStateFilter();
    };
});
