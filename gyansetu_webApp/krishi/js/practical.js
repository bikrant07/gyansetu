class PracticalLearning {
    constructor() {
        this.initializeFilters();
        this.initializeProgress();
        this.initializeExercises();
        this.initializeQuizzes();
    }

    initializeFilters() {
        const filterBtns = document.querySelectorAll('.filter-btn');
        const videoCards = document.querySelectorAll('.video-card');

        filterBtns.forEach(btn => {
            btn.addEventListener('click', () => {
                const category = btn.dataset.category;
                
                // Update active button
                filterBtns.forEach(b => b.classList.remove('active'));
                btn.classList.add('active');

                // Filter videos
                videoCards.forEach(card => {
                    if (category === 'all' || card.dataset.category === category) {
                        card.style.display = 'block';
                    } else {
                        card.style.display = 'none';
                    }
                });
            });
        });
    }

    initializeProgress() {
        const completeBtns = document.querySelectorAll('.mark-complete');
        const progressBar = document.querySelector('.progress');
        const progressText = document.querySelector('.progress-text');
        let completed = 0;

        completeBtns.forEach(btn => {
            btn.addEventListener('click', () => {
                if (!btn.classList.contains('completed')) {
                    btn.classList.add('completed');
                    btn.textContent = 'Completed';
                    completed++;
                    this.updateProgress(completed, completeBtns.length);
                }
            });
        });
    }

    updateProgress(completed, total) {
        const percentage = (completed / total) * 100;
        const progressBar = document.querySelector('.progress');
        const progressText = document.querySelector('.progress-text');
        
        progressBar.style.width = `${percentage}%`;
        progressText.textContent = `${Math.round(percentage)}% Complete`;
    }

    initializeExercises() {
        const canvas = document.getElementById('cropPlanner');
        if (!canvas) return;

        const ctx = canvas.getContext('2d');
        const gridSize = 20;
        const grid = Array(gridSize).fill().map(() => Array(gridSize).fill(null));
        
        // Game state
        let currentTool = 'plant';
        let day = 1;
        let plantCount = 0;
        let score = 0;
        let coins = 100;
        let level = 1;
        let weather = 'sunny';
        let gameSpeed = 1;

        // Game properties
        const cropProperties = {
            wheat: {
                cost: 10,
                growthRate: 8,
                waterNeed: 40,
                maxHeight: 0.9,
                color: '#f4d03f',
                harvestDay: 60,
                sellPrice: 25,
                name: 'Wheat',
                icon: '🌾',
                unlockLevel: 1,
                description: 'Basic crop, good for beginners'
            },
            rice: {
                cost: 15,
                growthRate: 6,
                waterNeed: 70,
                maxHeight: 0.7,
                color: '#27ae60',
                harvestDay: 90,
                sellPrice: 40,
                name: 'Rice',
                icon: '🌾',
                unlockLevel: 2,
                description: 'Needs lots of water, high profit'
            },
            corn: {
                cost: 20,
                growthRate: 10,
                waterNeed: 55,
                maxHeight: 1,
                color: '#f39c12',
                harvestDay: 75,
                sellPrice: 35,
                name: 'Corn',
                icon: '🌽',
                unlockLevel: 3,
                description: 'Fast growing, balanced crop'
            },
            tomato: {
                cost: 25,
                growthRate: 12,
                waterNeed: 60,
                maxHeight: 0.8,
                color: '#e74c3c',
                harvestDay: 45,
                sellPrice: 45,
                name: 'Tomato',
                icon: '🍅',
                unlockLevel: 4,
                description: 'Quick harvest, high maintenance'
            }
        };

        // Achievements system
        const achievements = [
            { id: 'firstHarvest', name: 'First Harvest', description: 'Harvest your first crop', reward: 50 },
            { id: 'masterFarmer', name: 'Master Farmer', description: 'Reach level 5', reward: 200 },
            { id: 'weatherMaster', name: 'Weather Master', description: 'Successfully grow crops in all weather conditions', reward: 150 }
        ];

        let unlockedAchievements = new Set();

        // Weather system with events
        const weatherEvents = {
            drought: { chance: 0.1, effect: { water: -30, growth: 0.5 } },
            flood: { chance: 0.1, effect: { water: 100, growth: 0.3 } },
            perfectDay: { chance: 0.1, effect: { water: 0, growth: 2.0 } }
        };

        function checkWeatherEvent() {
            for (const [event, data] of Object.entries(weatherEvents)) {
                if (Math.random() < data.chance) {
                    showEvent(`${event.toUpperCase()}! ${getEventDescription(event)}`);
                    return data.effect;
                }
            }
            return null;
        }

        function getEventDescription(event) {
            const descriptions = {
                drought: 'Water your crops quickly!',
                flood: 'Crops might drown!',
                perfectDay: 'Double growth speed!'
            };
            return descriptions[event];
        }

        function showEvent(message) {
            const event = document.createElement('div');
            event.className = 'game-event';
            event.innerHTML = `
                <div class="event-content">
                    <i class="fas fa-exclamation-triangle"></i>
                    <span>${message}</span>
                </div>
            `;
            document.body.appendChild(event);
            setTimeout(() => event.remove(), 5000);
        }

        function updateUI() {
            const infoPanel = document.querySelector('.info-panel');
            infoPanel.innerHTML = `
                <div class="game-stats">
                    <p><i class="fas fa-calendar"></i> Day: ${day}</p>
                    <p><i class="fas fa-seedling"></i> Plants: ${plantCount}</p>
                    <p><i class="fas fa-star"></i> Score: ${score}</p>
                    <p><i class="fas fa-coins"></i> Coins: ${coins}</p>
                    <p><i class="fas fa-level-up-alt"></i> Level: ${level}</p>
                    <p><i class="fas fa-cloud-sun"></i> Weather: ${weather}</p>
                </div>
                <div class="crop-market">
                    <h4>Crop Market</h4>
                    ${Object.entries(cropProperties)
                        .filter(([_, prop]) => prop.unlockLevel <= level)
                        .map(([crop, prop]) => `
                            <div class="crop-item">
                                <span>${prop.icon} ${prop.name}</span>
                                <span>Buy: ${prop.cost} 🪙</span>
                                <span>Sell: ${prop.sellPrice} 🪙</span>
                            </div>
                        `).join('')}
                </div>
                <div class="achievements">
                    <h4>Achievements</h4>
                    ${achievements.map(a => `
                        <div class="achievement-item ${unlockedAchievements.has(a.id) ? 'unlocked' : ''}">
                            <span>${a.name}</span>
                            <span>${a.description}</span>
                        </div>
                    `).join('')}
                </div>
            `;
        }

        function handleCanvasClick(e) {
            const rect = canvas.getBoundingClientRect();
            const x = Math.floor((e.clientX - rect.left) / cellSize);
            const y = Math.floor((e.clientY - rect.top) / cellSize);

            if (currentTool === 'plant') {
                const selectedCrop = cropProperties[cropSelect.value];
                if (coins >= selectedCrop.cost && !grid[y][x]) {
                    coins -= selectedCrop.cost;
                    grid[y][x] = {
                        type: cropSelect.value,
                        growth: 0,
                        water: 50,
                        health: 100,
                        plantedDay: day
                    };
                    plantCount++;
                    showEvent(`Planted ${selectedCrop.name}! -${selectedCrop.cost} coins`);
                }
            } else if (currentTool === 'water' && grid[y][x]) {
                grid[y][x].water = Math.min(100, grid[y][x].water + 25);
                grid[y][x].health = Math.min(100, grid[y][x].health + 5);
                showEvent('Watered plant! +5 health');
            } else if (currentTool === 'harvest' && grid[y][x]) {
                const crop = grid[y][x];
                if (crop.growth >= cropProperties[crop.type].harvestDay) {
                    const profit = cropProperties[crop.type].sellPrice;
                    coins += profit;
                    score += profit;
                    showEvent(`Harvested ${cropProperties[crop.type].name}! +${profit} coins`);
                    
                    if (!unlockedAchievements.has('firstHarvest')) {
                        unlockAchievement('firstHarvest');
                    }
                    
                    grid[y][x] = null;
                    plantCount--;
                }
            }

            updateUI();
            drawGrid();
        }

        function unlockAchievement(id) {
            const achievement = achievements.find(a => a.id === id);
            if (achievement && !unlockedAchievements.has(id)) {
                unlockedAchievements.add(id);
                coins += achievement.reward;
                showEvent(`Achievement Unlocked: ${achievement.name}! +${achievement.reward} coins`);
            }
        }

        // Add event listeners and initialize game
        canvas.addEventListener('click', handleCanvasClick);
        document.getElementById('nextDay').addEventListener('click', () => {
            for (let i = 0; i < 10; i++) {
                simulateDay();
            }
        });
        document.getElementById('resetSimulation').addEventListener('click', resetGame);

        // Initial setup
        updateUI();
        drawGrid();
    }

    initializeQuizzes() {
        const checkAnswerBtns = document.querySelectorAll('.check-answer');
        
        checkAnswerBtns.forEach(btn => {
            btn.addEventListener('click', () => {
                const question = btn.closest('.quiz-question');
                const selected = question.querySelector('input[type="radio"]:checked');
                
                if (selected && selected.value === 'b') {
                    question.classList.add('correct');
                    btn.textContent = 'Correct!';
                } else {
                    question.classList.add('incorrect');
                    btn.textContent = 'Try Again';
                }
            });
        });
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new PracticalLearning();
}); 