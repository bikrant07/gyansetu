class FarmingTools {
    constructor() {
        console.log('FarmingTools initialized');
        this.initializeCalculators();
        this.initializeWeather();
    }

    initializeCalculators() {
        const calculatorBtn = document.getElementById('calculatorBtn');
        const modal = document.getElementById('toolsModal');
        const closeBtn = document.getElementById('closeToolsModal');
        const calculateSeedsBtn = document.getElementById('calculateSeeds');
        const calculateWaterBtn = document.getElementById('calculateWater');

        calculatorBtn?.addEventListener('click', () => {
            modal?.classList.add('active');
            document.body.style.overflow = 'hidden';
            const practicalContent = document.querySelector('.practical-learning');
            if (practicalContent) {
                practicalContent.style.overflow = 'hidden';
            }
        });

        closeBtn?.addEventListener('click', () => {
            this.closeModal();
        });

        modal?.addEventListener('click', (e) => {
            if (e.target === modal) {
                this.closeModal();
            }
        });

        calculateSeedsBtn?.addEventListener('click', () => this.calculateSeeds());
        calculateWaterBtn?.addEventListener('click', () => this.calculateWater());
    }

    closeModal() {
        const modal = document.getElementById('toolsModal');
        modal?.classList.remove('active');
        document.body.style.overflow = '';
        const practicalContent = document.querySelector('.practical-learning');
        if (practicalContent) {
            practicalContent.style.overflow = '';
        }
    }

    async initializeWeather() {
        console.log('Initializing weather...');
        const weatherCard = document.querySelector('.weather-card');
        
        if (!weatherCard) {
            console.error('Weather card element not found');
            return;
        }

        try {
            if (!("geolocation" in navigator)) {
                throw new Error('Geolocation not supported');
            }

            weatherCard.innerHTML = `
                <div class="weather-loading">
                    <i class="fas fa-spinner fa-spin"></i>
                    <span>Fetching weather data...</span>
                </div>
            `;

            navigator.geolocation.getCurrentPosition(
                async (position) => {
                    console.log('Got location:', position.coords);
                    try {
                        const weather = await this.getWeatherData(
                            position.coords.latitude,
                            position.coords.longitude
                        );
                        console.log('Weather data:', weather);
                        this.updateWeatherUI(weather);
                    } catch (error) {
                        console.error('Failed to fetch weather:', error);
                        this.showWeatherError('Could not fetch weather data');
                    }
                },
                (error) => {
                    console.error('Geolocation error:', error);
                    this.showWeatherError('Please enable location access');
                },
                {
                    timeout: 10000,
                    maximumAge: 0
                }
            );

        } catch (error) {
            console.error('Weather initialization failed:', error);
            this.showWeatherError(error.message);
        }
    }

    async getWeatherData(lat, lon) {
        console.log(`Fetching weather for lat:${lat}, lon:${lon}`);
        const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,wind_speed_10m`;
        console.log('API URL:', url);

        const response = await fetch(url);
        if (!response.ok) {
            throw new Error(`Weather API error: ${response.status}`);
        }
        return await response.json();
    }

    updateWeatherUI(weather) {
        console.log('Updating UI with weather:', weather);
        const weatherCard = document.querySelector('.weather-card');
        
        if (!weatherCard || !weather.current) return;

        const temp = weather.current.temperature_2m;
        const humidity = weather.current.relative_humidity_2m;
        const windSpeed = weather.current.wind_speed_10m;

        weatherCard.innerHTML = `
            <div class="weather-content">
                <div class="weather-main">
                    <i class="fas ${this.getWeatherIcon(temp)}"></i>
                    <div class="weather-info">
                        <div class="temperature">${Math.round(temp)}°C</div>
                        <div class="description">Current Conditions</div>
                    </div>
                </div>
                
                <div class="weather-details">
                    <div class="weather-detail">
                        <i class="fas fa-tint"></i>
                        <span>Humidity: ${humidity}%</span>
                    </div>
                    <div class="weather-detail">
                        <i class="fas fa-wind"></i>
                        <span>Wind: ${Math.round(windSpeed)} km/h</span>
                    </div>
                </div>

                <div class="farming-recommendations">
                    <h3>Today's Farming Recommendations</h3>
                    
                    <!-- Crop Recommendations -->
                    <div class="recommendation-section">
                        <h4>Suitable Crops</h4>
                        <div class="crop-suggestions">
                            ${this.getCropRecommendations(temp, humidity)}
                        </div>
                    </div>

                    <!-- Activity Recommendations -->
                    <div class="recommendation-section">
                        <h4>Recommended Activities</h4>
                        <div class="activity-suggestions">
                            ${this.getActivityRecommendations(temp, humidity, windSpeed)}
                        </div>
                    </div>

                    <!-- Precautions -->
                    <div class="recommendation-section">
                        <h4>Precautions</h4>
                        <div class="precautions-list">
                            ${this.getPrecautions(temp, humidity, windSpeed)}
                        </div>
                    </div>
                </div>
            </div>
        `;
    }

    showWeatherError(message) {
        console.log('Showing weather error:', message);
        const weatherCard = document.querySelector('.weather-card');
        if (weatherCard) {
            weatherCard.innerHTML = `
                <div class="weather-error">
                    <i class="fas fa-exclamation-circle"></i>
                    <span>${message}</span>
                </div>
            `;
        }
    }

    getWeatherIcon(temp) {
        if (temp > 30) return 'fa-sun';
        if (temp > 20) return 'fa-cloud-sun';
        if (temp > 10) return 'fa-cloud';
        return 'fa-snowflake';
    }

    getCropRecommendations(temp, humidity) {
        let crops = [];
        
        // Temperature-based recommendations
        if (temp >= 25 && temp <= 35) {
            crops.push(
                { name: 'Tomatoes', icon: '🍅' },
                { name: 'Peppers', icon: '🫑' },
                { name: 'Eggplants', icon: '🍆' }
            );
        } else if (temp >= 15 && temp < 25) {
            crops.push(
                { name: 'Lettuce', icon: '🥬' },
                { name: 'Spinach', icon: '🥬' },
                { name: 'Peas', icon: '🌱' }
            );
        } else if (temp < 15) {
            crops.push(
                { name: 'Cabbage', icon: '🥬' },
                { name: 'Carrots', icon: '🥕' },
                { name: 'Onions', icon: '🧅' }
            );
        }

        return crops.map(crop => `
            <div class="crop-item">
                <span class="crop-icon">${crop.icon}</span>
                <span class="crop-name">${crop.name}</span>
            </div>
        `).join('');
    }

    getActivityRecommendations(temp, humidity, windSpeed) {
        let activities = [];

        // Morning activities (assuming optimal conditions)
        if (temp < 25 && humidity < 70 && windSpeed < 15) {
            activities.push({
                activity: 'Ideal for Planting',
                icon: 'fa-seedling',
                class: 'good'
            });
        }

        // Irrigation recommendations
        if (temp > 28 || humidity < 40) {
            activities.push({
                activity: 'Irrigation Recommended',
                icon: 'fa-tint',
                class: 'warning'
            });
        }

        // Pest control timing
        if (humidity > 75) {
            activities.push({
                activity: 'Monitor for Pests',
                icon: 'fa-bug',
                class: 'warning'
            });
        }

        // Harvesting conditions
        if (temp > 15 && temp < 30 && humidity < 70 && windSpeed < 20) {
            activities.push({
                activity: 'Good for Harvesting',
                icon: 'fa-harvest',
                class: 'good'
            });
        }

        return activities.map(item => `
            <div class="activity-item ${item.class}">
                <i class="fas ${item.icon}"></i>
                <span>${item.activity}</span>
            </div>
        `).join('');
    }

    getPrecautions(temp, humidity, windSpeed) {
        let precautions = [];

        if (temp > 35) {
            precautions.push({
                message: 'Protect plants from heat stress',
                icon: 'fa-temperature-high',
                class: 'warning'
            });
        }

        if (humidity > 85) {
            precautions.push({
                message: 'High risk of fungal diseases',
                icon: 'fa-cloud-rain',
                class: 'warning'
            });
        }

        if (windSpeed > 20) {
            precautions.push({
                message: 'Secure young plants from wind damage',
                icon: 'fa-wind',
                class: 'warning'
            });
        }

        if (temp < 5) {
            precautions.push({
                message: 'Protect crops from frost damage',
                icon: 'fa-snowflake',
                class: 'warning'
            });
        }

        return precautions.map(item => `
            <div class="precaution-item ${item.class}">
                <i class="fas ${item.icon}"></i>
                <span>${item.message}</span>
            </div>
        `).join('');
    }

    calculateSeeds() {
        const area = parseFloat(document.getElementById('seedArea')?.value || 0);
        const crop = document.getElementById('seedCrop')?.value;
        const result = document.getElementById('seedResult');

        if (!area || !crop || !result) return;

        const seedRates = {
            wheat: 100,
            rice: 30,
            corn: 20,
            soybean: 80
        };

        const seedAmount = area * seedRates[crop];
        result.innerHTML = `<div class="result-content">
            <i class="fas fa-info-circle"></i>
            <span>You need approximately ${seedAmount} kg of ${crop} seeds</span>
        </div>`;
        result.classList.add('active');
    }

    calculateWater() {
        const area = parseFloat(document.getElementById('waterArea')?.value || 0);
        const stage = document.getElementById('cropStage')?.value;
        const result = document.getElementById('waterResult');

        if (!area || !stage || !result) return;

        const waterRates = {
            initial: 3000,
            mid: 5000,
            final: 2000
        };

        const waterAmount = area * waterRates[stage];
        result.innerHTML = `<div class="result-content">
            <i class="fas fa-info-circle"></i>
            <span>Estimated water requirement: ${waterAmount} liters per day</span>
        </div>`;
        result.classList.add('active');
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    console.log('DOM loaded, initializing FarmingTools');
    window.farmingTools = new FarmingTools();
});