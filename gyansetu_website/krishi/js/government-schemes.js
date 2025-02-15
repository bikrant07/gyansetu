class GovernmentSchemes {
    constructor() {
        this.container = document.getElementById('schemesContainer');
        this.schemes = {
            central: [
                {
                    name: "Pradhan Mantri Kisan Samman Nidhi (PM-KISAN)",
                    description: "Financial benefit of Rs. 6000/- per year transferred in three equal installments to farmer families",
                    benefits: [
                        "Direct cash transfer of ₹6000 annually",
                        "Amount credited directly to bank accounts",
                        "More than 11 crores beneficiaries covered",
                        "Rs. 2.81 lakh crores transferred through DBT"
                    ],
                    status: "Active",
                    link: "https://pmkisan.gov.in"
                },
                {
                    name: "Agriculture Infrastructure Fund (AIF)",
                    description: "Medium-long term debt financing for agriculture infrastructure projects",
                    benefits: [
                        "Rs. 1 lakh crore fund allocation",
                        "3% interest subvention on loans",
                        "Maximum loan term of 15 years",
                        "Credit guarantee coverage under CGTMSE scheme"
                    ],
                    status: "Active",
                    link: "https://agriinfra.dac.gov.in"
                },
                {
                    name: "Pradhan Mantri Fasal Bima Yojana (PMFBY)",
                    description: "Comprehensive crop insurance scheme to protect farmers",
                    benefits: [
                        "Insurance coverage and financial support",
                        "Low premium rates for farmers",
                        "Coverage from pre-sowing to post harvest",
                        "Use of technology for quick claim settlement"
                    ],
                    status: "Active",
                    link: "https://pmfby.gov.in"
                },
                {
                    name: "National Agriculture Market (eNAM)",
                    description: "Pan-India electronic trading portal for farm produce",
                    benefits: [
                        "Online trading platform for agricultural commodities",
                        "Better price discovery through bidding",
                        "Reduced transaction costs",
                        "Direct payment to farmers"
                    ],
                    status: "Active",
                    link: "https://enam.gov.in"
                },
                {
                    name: "Kisan Credit Card (KCC)",
                    description: "Credit facility for farmers with simplified procedures",
                    benefits: [
                        "Easy access to bank credit",
                        "Flexible repayment options",
                        "Coverage for cultivation expenses",
                        "Interest subvention benefits"
                    ],
                    status: "Active",
                    link: "https://www.pmkisan.gov.in"
                }
            ],
            state: {
                "Maharashtra": [
                    {
                        name: "Mahatma Jyotirao Phule Shetkari Karjamukti Yojana 2024",
                        description: "Loan waiver scheme for farmers in Maharashtra",
                        benefits: [
                            "Loan waiver up to ₹2 lakh",
                            "Coverage for defaulting farmers",
                            "Simple application process",
                            "Direct benefit transfer"
                        ],
                        status: "Active",
                        link: "https://maharashtra.gov.in"
                    }
                ],
                "Punjab": [
                    {
                        name: "Punjab State Farmers Policy 2024",
                        description: "Comprehensive support for farmers in Punjab",
                        benefits: [
                            "Direct seeding of rice incentive",
                            "Crop diversification program",
                            "Smart farming initiatives",
                            "Subsidies on agricultural equipment"
                        ],
                        status: "Active",
                        link: "https://punjab.gov.in"
                    }
                ],
                "Karnataka": [
                    {
                        name: "Krishi Bhagya Yojana",
                        description: "Water conservation and management scheme",
                        benefits: [
                            "Farm ponds construction subsidy",
                            "Drip irrigation support",
                            "Solar pump installation aid",
                            "Rainwater harvesting structures"
                        ],
                        status: "Active",
                        link: "https://karnataka.gov.in"
                    }
                ]
            }
        };
        this.init();
    }

    init() {
        this.createInterface();
        this.setupEventListeners();
    }

    createInterface() {
        this.container.innerHTML = `
            <div class="schemes-dashboard">
                <div class="schemes-header">
                    <div class="schemes-filters">
                        <button class="filter-btn active" data-type="central">Central Schemes</button>
                        <button class="filter-btn" data-type="state">State Schemes</button>
                        <select id="stateSelector" class="state-selector" style="display: none;">
                            <option value="">Select State</option>
                            ${Object.keys(this.schemes.state).map(state => 
                                `<option value="${state}">${state}</option>`
                            ).join('')}
                        </select>
                    </div>
                    <div class="search-box">
                        <input type="text" id="schemeSearch" placeholder="Search schemes...">
                        <i class="fas fa-search"></i>
                    </div>
                </div>

                <div class="schemes-grid" id="schemesGrid"></div>

                <div class="schemes-updates">
                    <h3>Latest Updates</h3>
                    <div class="updates-list">
                        <div class="update-item">
                            <div class="update-date">February 2024</div>
                            <div class="update-content">
                                <h4>New Scheme Updates</h4>
                                <p>Latest agricultural schemes and updates from central and state governments</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;

        this.displaySchemes('central');
    }

    setupEventListeners() {
        // Filter buttons
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
                e.target.classList.add('active');
                const type = e.target.dataset.type;
                
                // Show/hide state selector
                const stateSelector = document.getElementById('stateSelector');
                stateSelector.style.display = type === 'state' ? 'block' : 'none';
                
                this.displaySchemes(type, stateSelector.value);
            });
        });

        // State selector
        const stateSelector = document.getElementById('stateSelector');
        stateSelector.addEventListener('change', (e) => {
            if (e.target.value) {
                this.displaySchemes('state', e.target.value);
            }
        });

        // Search functionality
        const searchInput = document.getElementById('schemeSearch');
        searchInput.addEventListener('input', (e) => {
            const searchTerm = e.target.value.toLowerCase();
            const activeType = document.querySelector('.filter-btn.active').dataset.type;
            const selectedState = document.getElementById('stateSelector').value;
            
            this.displaySchemes(activeType, selectedState, searchTerm);
        });
    }

    displaySchemes(type = 'central', state = '', searchTerm = '') {
        const grid = document.getElementById('schemesGrid');
        let schemes = [];

        if (type === 'central') {
            schemes = this.schemes.central;
        } else if (type === 'state' && state) {
            schemes = this.schemes.state[state] || [];
        }

        // Filter schemes based on search term
        if (searchTerm) {
            schemes = schemes.filter(scheme => 
                scheme.name.toLowerCase().includes(searchTerm) ||
                scheme.description.toLowerCase().includes(searchTerm) ||
                scheme.benefits.some(benefit => benefit.toLowerCase().includes(searchTerm))
            );
        }

        grid.innerHTML = schemes.length ? schemes.map(scheme => `
            <div class="scheme-card ${scheme.status.toLowerCase()}">
                <div class="scheme-header">
                    <h3>${scheme.name}</h3>
                    <span class="status-badge ${scheme.status.toLowerCase()}">${scheme.status}</span>
                </div>
                
                <p class="scheme-description">${scheme.description}</p>
                
                <div class="scheme-benefits">
                    <h4>Benefits:</h4>
                    <ul>
                        ${scheme.benefits.map(benefit => `<li>${benefit}</li>`).join('')}
                    </ul>
                </div>

                <div class="scheme-actions">
                    <a href="${scheme.link}" target="_blank" class="btn-apply">Apply Now</a>
                    <button class="btn-details" onclick="showSchemeDetails('${scheme.name}')">
                        More Details
                    </button>
                </div>
            </div>
        `).join('') : '<div class="no-schemes">No schemes found</div>';
    }
}

// Initialize when document is ready
document.addEventListener('DOMContentLoaded', () => {
    if (document.getElementById('schemesContainer')) {
        window.govSchemes = new GovernmentSchemes();
    }
}); 