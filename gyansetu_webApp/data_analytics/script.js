// Global variable to store dataset
let fullData = [];

// Global variable to store the current chart instance
let currentChart = null;

// Column mappings for easier maintenance and accuracy
const COLUMNS = {
  LOCATION: 0,
  RURAL_URBAN: 1,
  SCHOOL_CATEGORY: 2,
  SCHOOL_MANAGEMENT: 3,
  SCHOOL_TYPE: 4,
  TOTAL_SCHOOLS: 5,
  HEADMASTER_ROOM: 6,
  LAND: 7,
  ELECTRICITY: 8,
  FUNCTIONAL_ELECTRICITY: 9,
  SOLAR_PANEL: 10,
  PLAYGROUND: 11,
  LIBRARY: 12,
  LIBRARIAN: 13,
  NEWSPAPER: 14,
  KITCHEN_GARDEN: 15,
  FURNITURE: 16,
  BOYS_TOILET: 17,
  FUNCTIONAL_BOYS_TOILET: 18,
  GIRLS_TOILET: 19,
  FUNCTIONAL_GIRLS_TOILET: 20,
  TOILET: 21,
  FUNCTIONAL_TOILET: 22,
  DRINKING_WATER: 23,
  FUNCTIONAL_DRINKING_WATER: 24,
  WATER_PURIFIER: 25,
  RAINWATER_HARVESTING: 26,
  WATER_TESTED: 27,
  HANDWASH: 28,
  INTERNET: 29,
  COMPUTER: 30
};

// Load and parse CSV data
function loadData() {
  fetch('data.csv')
    .then(response => response.text())
    .then(csvText => {
      // Parse CSV
      const rows = csvText.split('\n');
      const headers = rows[0].split(',');
      
      // Process each row into an object with column names
      fullData = rows.slice(1).map(row => {
        const values = row.split(',');
        const rowData = {};
        headers.forEach((header, index) => {
          rowData[header.trim()] = values[index];
        });
        return rowData;
      });

      console.log("First row of data:", fullData[0]); // Debug log
      console.log("Available columns:", headers); // Debug log
      
      showDefaultVisualizations();
    })
    .catch(error => {
      console.error("Error loading data:", error);
      document.getElementById('visualization').innerHTML = `
        <div class="error">
          Error loading data: ${error.message}
        </div>
      `;
    });
}

function showDefaultVisualizations() {
  // Clear any existing content
  const visualizationDiv = document.getElementById('visualization');
  visualizationDiv.innerHTML = '';

  // Create new container elements
  const controlsDiv = document.createElement('div');
  controlsDiv.className = 'controls';
  
  const contentWrapper = document.createElement('div');
  contentWrapper.className = 'content-wrapper';
  
  // Add controls
  controlsDiv.innerHTML = `
    <div class="control-group">
      <label for="chartType">Select Chart Type:</label>
      <select id="chartType">
        <option value="bar">Bar Chart</option>
        <option value="pie">Pie Chart</option>
        <option value="line">Line Chart</option>
      </select>
    </div>
    <div class="control-group">
      <label for="facility">Select Facility:</label>
      <select id="facility">
        <option value="library">Library</option>
        <option value="internet">Internet</option>
        <option value="drinking_water">Drinking Water</option>
        <option value="toilet">Toilets</option>
        <option value="electricity">Electricity</option>
        <option value="computer">Computer</option>

      </select>
    </div>
    <div class="control-group">
      <label for="sortOrder">Sort Order:</label>
      <select id="sortOrder">
        <option value="asc">Ascending (Least to Most)</option>
        <option value="desc">Descending (Most to Least)</option>
      </select>
    </div>
    <div class="control-group">
      <label for="dataLimit">Number of States:</label>
      <input type="number" id="dataLimit" value="10" min="5" max="36">
    </div>
    <div class="control-group">
      <label for="stateSelect">Select State:</label>
      <select id="stateSelect" onchange="updateVisualization()">
        <option value="all">All States</option>
        ${getUniqueStates()}
      </select>
      <button onclick="showStateAnalysis()" class="analyze-btn">Analyze Infrastructure</button>
    </div>
  `;

  // Add content wrapper
  contentWrapper.innerHTML = `
    <div class="chart-container">
      <canvas id="mainChart"></canvas>
    </div>
    <div class="stats-container">
      <h3>Statistics</h3>
      <div id="statsContent"></div>
    </div>
  `;

  // Append elements to visualization div
  visualizationDiv.appendChild(controlsDiv);
  visualizationDiv.appendChild(contentWrapper);

  // Add event listeners
  const controls = ['chartType', 'facility', 'sortOrder', 'dataLimit'];
  controls.forEach(control => {
    const element = document.getElementById(control);
    element.removeEventListener('change', updateVisualization);
    element.addEventListener('change', updateVisualization);
  });

  // Initial visualization
  updateVisualization();
}
function updateLegend() {
    const legendDiv = document.createElement('div');
    legendDiv.className = 'map-legend';
    
    const ranges = [
        { min: 0, max: 25, color: '#ffeda0' },
        { min: 25, max: 50, color: '#feb24c' },
        { min: 50, max: 75, color: '#f03b20' },
        { min: 75, max: 100, color: '#bd0026' }
    ];

    ranges.forEach(range => {
        const item = document.createElement('div');
        item.className = 'legend-item';
        item.innerHTML = `
            <span class="color-box" style="background-color: ${range.color}"></span>
            <span>${range.min}% - ${range.max}%</span>
        `;
        item.addEventListener('mouseover', () => highlightRegionsInRange(range.min, range.max));
        item.addEventListener('mouseout', resetHighlights);
        legendDiv.appendChild(item);
    });

    document.querySelector('.map-container').appendChild(legendDiv);
}
function addComparativeAnalysis() {
    const compareDiv = document.createElement('div');
    compareDiv.className = 'compare-container';
    
    compareDiv.innerHTML = `
        <div class="compare-controls">
            <select id="compareState1">
                <option value="">Select First State</option>
                ${getUniqueStates().map(state => 
                    `<option value="${state}">${state}</option>`
                ).join('')}
            </select>
            <select id="compareState2">
                <option value="">Select Second State</option>
                ${getUniqueStates().map(state => 
                    `<option value="${state}">${state}</option>`
                ).join('')}
            </select>
            <button onclick="compareStates()">Compare</button>
        </div>
        <div id="compareChart"></div>
    `;
    
    document.getElementById('visualization').appendChild(compareDiv);
}



function updateVisualization() {
  // Destroy existing chart if it exists
  if (currentChart) {
    currentChart.destroy();
    currentChart = null;
  }

  const chartType = document.getElementById('chartType').value;
  const facility = document.getElementById('facility').value;
  const sortOrder = document.getElementById('sortOrder').value;
  const dataLimit = parseInt(document.getElementById('dataLimit').value);

  const processedData = processDataForFacility(facility);
  console.log('Processed Data:', processedData); // Debug log

  if (processedData.length === 0) {
    document.getElementById('mainChart').innerHTML = 'No data available for selected facility';
    return;
  }

  const sortedData = sortData(processedData, sortOrder).slice(0, dataLimit);
  
  // Update statistics
  updateStatistics(sortedData, facility);

  // Create new chart based on type
  const ctx = document.getElementById('mainChart').getContext('2d');
  
  if (chartType === 'pie') {
    currentChart = createPieChart(ctx, sortedData);
  } else if (chartType === 'bar') {
    currentChart = createBarChart(ctx, sortedData);
  } else {
    currentChart = createLineChart(ctx, sortedData);
  }
}

function processDataForFacility(facility) {
  const stateData = {};
  const selectedState = document.getElementById('stateSelect').value;
  
  fullData.forEach(row => {
    const state = row['Location'];
    
    if (state && state !== 'Total' && (selectedState === 'all' || state === selectedState)) {
      if (!stateData[state]) {
        stateData[state] = {
          Location: state,
          value: 0,
          totalSchools: 0,
          withoutFacility: 0
        };
      }

      const totalSchools = parseInt(row['Total No. of Schools']) || 0;
      let withFacility = 0;

      switch(facility) {
        case 'library':
          withFacility = parseInt(row['Library or Reading Corner or Book Bank']) || 0;
          break;
        case 'internet':
          withFacility = parseInt(row['Internet']) || 0;
          break;
        case 'drinking_water':
          withFacility = parseInt(row['Drinking Water']) || 0;
          break;
        case 'toilet':
          withFacility = parseInt(row['Toilet Facility']) || 0;
          break;
        case 'electricity':
          withFacility = parseInt(row['Electricity']) || 0;
          break;
      }

      const withoutFacility = Math.max(0, totalSchools - withFacility);
      
      stateData[state].totalSchools += totalSchools;
      stateData[state].withoutFacility += withoutFacility;
      stateData[state].value = stateData[state].withoutFacility;
    }
  });

  return Object.values(stateData)
    .filter(d => d.withoutFacility > 0 && !isNaN(d.withoutFacility));
}

function updateStatistics(data, facility) {
  if (!data || data.length === 0) {
    document.getElementById('statsContent').innerHTML = `
      <div class="stat-item">
        <span class="stat-label">No data available</span>
      </div>
    `;
    return;
  }

  const total = data.reduce((sum, d) => sum + d.withoutFacility, 0);
  const avg = total / data.length;
  const max = Math.max(...data.map(d => d.withoutFacility));
  const min = Math.min(...data.map(d => d.withoutFacility));

  document.getElementById('statsContent').innerHTML = `
    <div class="stat-item">
      <span class="stat-label">Total Schools without ${getFacilityLabel(facility)}:</span>
      <span class="stat-value">${total.toLocaleString()}</span>
    </div>
    <div class="stat-item">
      <span class="stat-label">Average per State:</span>
      <span class="stat-value">${Math.round(avg).toLocaleString()}</span>
    </div>
    <div class="stat-item">
      <span class="stat-label">Maximum:</span>
      <span class="stat-value">${max.toLocaleString()}</span>
    </div>
    <div class="stat-item">
      <span class="stat-label">Minimum:</span>
      <span class="stat-value">${min.toLocaleString()}</span>
    </div>
  `;
}
function createBarChart(ctx, data) {
  return new Chart(ctx, {
    type: 'bar',
    data: {
      labels: data.map(d => d.Location),
      datasets: [{
        label: 'Number of Schools',
        data: data.map(d => d.value),
        backgroundColor: 'rgba(54, 162, 235, 0.8)',
        borderColor: 'rgba(54, 162, 235, 1)',
        borderWidth: 1
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: false
        },
        title: {
            display: true,
            text: 'Schools without Selected Facility',  // Use backtick ` symbol
            font: { size: 16 }
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          ticks: {
            callback: function(value) {
              return value.toLocaleString();
            }
          }
        },
        x: {
          ticks: {
            maxRotation: 45,
            minRotation: 45
          }
        }
      }
    }
  });
}

function createPieChart(ctx, data) {
  return new Chart(ctx, {
    type: 'pie',
    data: {
      labels: data.map(d => d.Location),
      datasets: [{
        data: data.map(d => d.value),
        backgroundColor: [
          'rgba(255, 99, 132, 0.8)',
          'rgba(54, 162, 235, 0.8)',
          'rgba(255, 206, 86, 0.8)',
          'rgba(75, 192, 192, 0.8)',
          'rgba(153, 102, 255, 0.8)',
          'rgba(255, 159, 64, 0.8)',
          'rgba(199, 199, 199, 0.8)',
          'rgba(83, 102, 255, 0.8)',
          'rgba(40, 159, 64, 0.8)',
          'rgba(210, 199, 199, 0.8)'
        ]
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          position: 'right'
        },
        title: {
          display: true,
          text: 'Schools without Selected Facility',
          font: { size: 16 }
        }
      }
    }
  });
}

function createLineChart(ctx, data) {
  return new Chart(ctx, {
    type: 'line',
    data: {
      labels: data.map(d => d.Location),
      datasets: [{
        label: 'Number of Schools',
        data: data.map(d => d.value),
        borderColor: 'rgba(54, 162, 235, 1)',
        backgroundColor: 'rgba(54, 162, 235, 0.1)',
        borderWidth: 2,
        fill: true,
        tension: 0.1
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: false
        },
        title: {
          display: true,
          text: 'Schools without Selected Facility',
          font: { size: 16 }
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          title: {
            display: true,
            text: 'Number of Schools →'
          },
          ticks: {
            callback: function(value) {
              return value.toLocaleString();
            }
          }
        },
        x: {
          title: {
            display: true,
            text: 'States →'
          },
          ticks: {
            maxRotation: 45,
            minRotation: 45
          }
        }
      }
    }
  });
}
function sortData(data, sortOrder) {
  return [...data].sort((a, b) => {
    if (sortOrder === 'asc') {
      return a.value - b.value;
    } else {
      return b.value - a.value;
    }
  });
}

function getFacilityLabel(facility) {
  const labels = {
    'library': 'Library',
    'internet': 'Internet',
    'drinking_water': 'Drinking Water',
    'toilet': 'Toilets',
    'electricity': 'Electricity',
    'computer':'Computer'
  };
  return labels[facility] || facility;
}

// Call loadData when the page loads
document.addEventListener('DOMContentLoaded', loadData);

// Add some CSS for the new controls
const styles = `
  .dashboard {
    padding: 20px;
    max-width: 1200px;
    margin: 0 auto;
  }

  .controls {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 20px;
    padding: 20px;
    background: #f5f5f5;
    border-radius: 8px;
    margin-bottom: 20px;
  }

  .content-wrapper {
    display: grid;
    grid-template-columns: 2fr 1fr;
    gap: 20px;
    margin-top: 20px;
  }

  .chart-container {
    position: relative;
    height: 300px;
    width: 100%;
    max-width: 600px;
    margin: 0 auto;
    padding: 10px;
  }

  .stats-container {
    background: white;
    border-radius: 8px;
    padding: 20px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  }

  .control-group {
    display: flex;
    flex-direction: column;
    gap: 5px;
  }

  .control-group label {
    font-weight: bold;
    color: #333;
  }

  .control-group select,
  .control-group input {
    padding: 8px;
    border-radius: 4px;
    border: 1px solid #ddd;
    font-size: 14px;
  }

  .stat-item {
    display: flex;
    justify-content: space-between;
    padding: 10px 0;
    border-bottom: 1px solid #eee;
  }

  .stat-label {
    font-weight: bold;
    color: #333;
  }

  .stat-value {
    color: #2196F3;
    font-weight: 500;
  }

  @media (max-width: 768px) {
    .content-wrapper {
      grid-template-columns: 1fr;
    }
    
    .controls {
      grid-template-columns: 1fr;
    }
  }

  .analyze-btn {
    margin-top: 5px;
    padding: 8px 16px;
    background: #4CAF50;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
  }

  .analyze-btn:hover {
    background: #45a049;
  }
`;

// Add styles to document
const styleSheet = document.createElement("style");
styleSheet.innerText = styles;
document.head.appendChild(styleSheet);

// Add this helper function to check if data is loaded correctly
function checkDataStructure() {
  if (fullData && fullData.length > 0) {
    console.log("Sample row:", fullData[0]);
    console.log("Available columns:", Object.keys(fullData[0]));
  } else {
    console.log("No data loaded");
  }
}

function getUniqueStates() {
  const states = new Set(fullData.map(row => row['Location']));
  return Array.from(states)
    .filter(state => state && state !== 'Total')
    .sort()
    .map(state => `<option value="${state}">${state}</option>`)
    .join('');
}

function showStateAnalysis() {
  const state = document.getElementById('stateSelect').value;
  if (!state || state === 'all') {
    alert('Please select a specific state for analysis');
    return;
  }
  
  const analysis = analyzeState(state);
  
  if (currentChart) {
    currentChart.destroy();
  }

  const ctx = document.getElementById('mainChart').getContext('2d');
  currentChart = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: ['Libraries', 'Internet', 'Drinking Water', 'Toilets', 'Electricity'],
      datasets: [{
        label: 'Schools with Facility',
        data: [
          analysis.withFacility.library,
          analysis.withFacility.internet,
          analysis.withFacility.water,
          analysis.withFacility.toilet,
          analysis.withFacility.electricity
        ],
        backgroundColor: 'rgba(75, 192, 192, 0.8)',
        stack: 'Stack 0'
      }, {
        label: 'Schools without Facility',
        data: [
          analysis.withoutFacility.library,
          analysis.withoutFacility.internet,
          analysis.withoutFacility.water,
          analysis.withoutFacility.toilet,
          analysis.withoutFacility.electricity
        ],
        backgroundColor: 'rgba(255, 99, 132, 0.8)',
        stack: 'Stack 0'
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        title: {
          display: true,
          text: `Infrastructure Analysis for ${state}`,
          font: { size: 16 }
        }
      },
      scales: {
        y: {
          stacked: true,
          title: {
            display: true,
            text: 'Number of Schools'
          }
        },
        x: {
          stacked: true
        }
      }
    }
  });

  // Update statistics
  updateStateStatistics(state, analysis);
}

function analyzeState(state) {
  const analysis = {
    totalSchools: 0,
    withFacility: {
      library: 0,
      internet: 0,
      water: 0,
      toilet: 0,
      electricity: 0
    },
    withoutFacility: {
      library: 0,
      internet: 0,
      water: 0,
      toilet: 0,
      electricity: 0
    }
  };

  fullData.forEach(row => {
    if (row['Location'] === state) {
      const totalSchools = parseInt(row['Total No. of Schools']) || 0;
      analysis.totalSchools += totalSchools;

      // Count schools with facilities
      const withLibrary = parseInt(row['Library or Reading Corner or Book Bank']) || 0;
      const withInternet = parseInt(row['Internet']) || 0;
      const withWater = parseInt(row['Drinking Water']) || 0;
      const withToilet = parseInt(row['Toilet Facility']) || 0;
      const withElectricity = parseInt(row['Electricity']) || 0;

      analysis.withFacility.library += withLibrary;
      analysis.withFacility.internet += withInternet;
      analysis.withFacility.water += withWater;
      analysis.withFacility.toilet += withToilet;
      analysis.withFacility.electricity += withElectricity;
    }
  });

  // Calculate schools without facilities
  analysis.withoutFacility.library = analysis.totalSchools - analysis.withFacility.library;
  analysis.withoutFacility.internet = analysis.totalSchools - analysis.withFacility.internet;
  analysis.withoutFacility.water = analysis.totalSchools - analysis.withFacility.water;
  analysis.withoutFacility.toilet = analysis.totalSchools - analysis.withFacility.toilet;
  analysis.withoutFacility.electricity = analysis.totalSchools - analysis.withFacility.electricity;

  return analysis;
}

function updateStateStatistics(state, analysis) {
  const statsContent = document.getElementById('statsContent');
  statsContent.innerHTML = `
    <div class="stat-item">
      <span class="stat-label">Total Schools:</span>
      <span class="stat-value">${analysis.totalSchools.toLocaleString()}</span>
    </div>
    <div class="stat-item">
      <span class="stat-label">Infrastructure Coverage:</span>
      <span class="stat-value">
        Libraries: ${((analysis.withFacility.library/analysis.totalSchools)*100).toFixed(1)}%<br>
        Internet: ${((analysis.withFacility.internet/analysis.totalSchools)*100).toFixed(1)}%<br>
        Water: ${((analysis.withFacility.water/analysis.totalSchools)*100).toFixed(1)}%<br>
        Toilets: ${((analysis.withFacility.toilet/analysis.totalSchools)*100).toFixed(1)}%<br>
        Electricity: ${((analysis.withFacility.electricity/analysis.totalSchools)*100).toFixed(1)}%
      </span>
    </div>
  `;
}

let map;
let infoWindow;

function initializeGoogleMap() {
    // Initialize map centered on India
    map = new google.maps.Map(document.getElementById('googleMap'), {
        center: { lat: 23.5937, lng: 78.9629 },
        zoom: 5,
        styles: [
            {
                featureType: "administrative.country",
                elementType: "geometry",
                stylers: [{ visibility: "simplified" }]
            }
        ]
    });

    infoWindow = new google.maps.InfoWindow();

    // Initial visualization
    updateMapData();
}

function updateMapData() {
    const selectedFacility = document.getElementById('facility').value;
    const stateData = processStateData(selectedFacility);

    // Load state boundaries and create polygons
    fetch('india-states.json')
        .then(response => response.json())
        .then(statesData => {
            statesData.features.forEach(feature => {
                const stateName = feature.properties.name;
                const stateInfo = stateData[stateName] || {
                    coverage: 0,
                    schools: 0,
                    withFacility: 0
                };

                const polygon = new google.maps.Polygon({
                    paths: convertCoordinates(feature.geometry.coordinates),
                    strokeColor: "#FFFFFF",
                    strokeOpacity: 0.8,
                    strokeWeight: 2,
                    fillColor: getColorByPercentage(stateInfo.coverage),
                    fillOpacity: 0.35,
                    map: map
                });

                // Add hover effect and info window
                addPolygonListeners(polygon, stateName, stateInfo);
            });

            updateLegend();
        });
}

function processStateData(facility) {
    const stateData = {};

    fullData.forEach(row => {
        if (row['Location'] !== 'Total') {
            const state = row['Location'];
            const totalSchools = parseInt(row['Total No. of Schools']) || 0;
            let facilityCount = 0;

            switch(facility) {
                case 'library':
                    facilityCount = parseInt(row['Library or Reading Corner or Book Bank']) || 0;
                    break;
                case 'internet':
                    facilityCount = parseInt(row['Internet']) || 0;
                    break;
                case 'drinking_water':
                    facilityCount = parseInt(row['Drinking Water']) || 0;
                    break;
                case 'toilet':
                    facilityCount = parseInt(row['Toilet Facility']) || 0;
                    break;
                case 'electricity':
                    facilityCount = parseInt(row['Electricity']) || 0;
                    break;
            }

            const coverage = totalSchools > 0 ? (facilityCount / totalSchools) * 100 : 0;
            stateData[state] = {
                coverage: coverage.toFixed(1),
                schools: totalSchools,
                withFacility: facilityCount
            };
        }
    });

    return stateData;
}

function addPolygonListeners(polygon, stateName, stateInfo) {
    // Hover effect
    polygon.addListener('mouseover', () => {
        polygon.setOptions({ fillOpacity: 0.7 });
        
        const content = `
            <div class="info-window">
                <h3>${stateName}</h3>
                <p>Coverage: ${stateInfo.coverage}%</p>
                <p>Total Schools: ${stateInfo.schools.toLocaleString()}</p>
                <p>With Facility: ${stateInfo.withFacility.toLocaleString()}</p>
            </div>
        `;

        infoWindow.setContent(content);
        infoWindow.setPosition(polygon.getBounds().getCenter());
        infoWindow.open(map);
    });

    polygon.addListener('mouseout', () => {
        polygon.setOptions({ fillOpacity: 0.35 });
        infoWindow.close();
    });

    // Click for detailed view
    polygon.addListener('click', () => {
        document.getElementById('stateSelect').value = stateName;
        showStateAnalysis();
    });
}

function convertCoordinates(coordinates) {
    // Convert GeoJSON coordinates to Google Maps LatLng
    return coordinates[0].map(coord => ({
        lat: coord[1],
        lng: coord[0]
    }));
}

// Update the existing mapStyles constant in your code
const mapStyles = `
    .map-container {
        position: relative;
        margin: 20px 0;
        border-radius: 8px;
        overflow: hidden;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    #googleMap {
        height: 500px;
        width: 100%;
    }

    .map-legend {
        position: absolute;
        bottom: 20px;
        right: 20px;
        background: white;
        padding: 10px;
        border-radius: 4px;
        box-shadow: 0 1px 5px rgba(0,0,0,0.2);
        z-index: 1;
    }

    .info-window {
        padding: 10px;
    }

    .info-window h3 {
        margin: 0 0 10px 0;
        color: #2196F3;
    }

    .info-window p {
        margin: 5px 0;
    }

    /* Add new map styles */
    #indiaMap {
        margin: 20px 0;
        border-radius: 8px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        height: 500px;
    }

    .map-tooltip {
        padding: 5px;
        font-size: 12px;
        line-height: 1.4;
    }
`;

// Keep the existing style application
const mapStyleSheet = document.createElement("style");
mapStyleSheet.textContent = mapStyles;
document.head.appendChild(mapStyleSheet);

// Add event listeners
document.addEventListener('DOMContentLoaded', initializeGoogleMap);
document.getElementById('facility').addEventListener('change', updateMapData);

// Load Google Charts
google.charts.load('current', {
    'packages': ['geochart'],
    'mapsApiKey': '' // No API key needed for basic usage
});

google.charts.setOnLoadCallback(drawRegionsMap);

function drawRegionsMap() {
    // Create map container if it doesn't exist
    if (!document.getElementById('regions_div')) {
        const mapContainer = document.createElement('div');
        mapContainer.id = 'regions_div';
        mapContainer.style.height = '500px';
        mapContainer.style.marginTop = '20px';
        document.querySelector('.chart-container').after(mapContainer);
    }

    const facility = document.getElementById('facility').value;
    const data = new google.visualization.DataTable();
    data.addColumn('string', 'State');
    data.addColumn('number', 'Coverage');
    data.addColumn({type: 'string', role: 'tooltip', 'p': {'html': true}});

    // Process data for each state
    const stateData = [];
    fullData.forEach(row => {
        if (row['Location'] !== 'Total') {
            const state = row['Location'];
            const totalSchools = parseInt(row['Total No. of Schools']) || 0;
            let facilityCount = 0;

            switch(facility) {
                case 'library':
                    facilityCount = parseInt(row['Library or Reading Corner or Book Bank']) || 0;
                    break;
                case 'internet':
                    facilityCount = parseInt(row['Internet']) || 0;
                    break;
                case 'drinking_water':
                    facilityCount = parseInt(row['Drinking Water']) || 0;
                    break;
                case 'toilet':
                    facilityCount = parseInt(row['Toilet Facility']) || 0;
                    break;
                case 'electricity':
                    facilityCount = parseInt(row['Electricity']) || 0;
                    break;
            }

            const coverage = totalSchools > 0 ? (facilityCount / totalSchools) * 100 : 0;
            const tooltip = `
                <div style="padding:10px">
                    <strong>${state}</strong><br>
                    Coverage: ${coverage.toFixed(1)}%<br>
                    Total Schools: ${totalSchools.toLocaleString()}<br>
                    With ${getFacilityLabel(facility)}: ${facilityCount.toLocaleString()}
                </div>`;

            stateData.push([state, coverage, tooltip]);
        }
    });

    data.addRows(stateData);

    const options = {
        region: 'IN',
        resolution: 'provinces',
        domain: 'IN',
        displayMode: 'regions',
        colorAxis: {colors: ['#edf8e9', '#006d2c']},
        backgroundColor: '#ffffff',
        datalessRegionColor: '#f5f5f5',
        defaultColor: '#f5f5f5',
        tooltip: { isHtml: true },
        legend: {
            textStyle: {
                color: '#666666',
                fontSize: 12
            }
        }
    };

    const chart = new google.visualization.GeoChart(document.getElementById('regions_div'));
    
    // Add click handler
    google.visualization.events.addListener(chart, 'select', function() {
        const selection = chart.getSelection();
        if (selection.length > 0) {
            const state = data.getValue(selection[0].row, 0);
            document.getElementById('stateSelect').value = state;
            showStateAnalysis();
        }
    });

    chart.draw(data, options);
}

// Add event listener for facility change
// document.getElementById('facility').addEventListener('change', drawRegionsMap);

// Add this to the end of your script.js

document.addEventListener('DOMContentLoaded', initializeIndiaMap);

// Recommendation System





// Function to populate state dropdown
function populateStateDropdown() {
    console.log("Populating state dropdown...");
    const stateSelect = document.getElementById('stateSelect');
    
    if (!stateSelect) {
        console.error("State select element not found!");
        return;
    }

    if (!fullData || fullData.length === 0) {
        console.error("No data available!");
        return;
    }

    // Get unique states from the data
    const states = [...new Set(fullData.map(row => row[COLUMNS.LOCATION]))];
    console.log("Found states:", states);

    // Sort states alphabetically
    states.sort();

    // Create and add options
    const options = states.map(state => 
        `<option value="${state}">${state}</option>`
    );

    // Add default option and other options
    stateSelect.innerHTML = `
        <option value="">Select State</option>
        ${options.join('')}
    `;

    console.log("Dropdown populated with", states.length, "states");
}




// Make sure COLUMNS is defined correct

// Initialize when the document is ready
document.addEventListener('DOMContentLoaded', () => {
    console.log("Document loaded, initializing...");
    initializeFeatures();
});

// Add this after your existing code

function generateRecommendations(state = 'all') {
    const analysis = {
        infrastructure: analyzeInfrastructure(state),
        genderParity: analyzeGenderParity(state),
        ruralUrbanGap: analyzeRuralUrbanGap(state),
        schoolTypes: analyzeSchoolTypes(state)
    };

    return prioritizeRecommendations(analysis);
}

function analyzeInfrastructure(state) {
    const infrastructureGaps = {
        library: { count: 0, total: 0 },
        internet: { count: 0, total: 0 },
        water: { count: 0, total: 0 },
        toilet: { count: 0, total: 0 },
        electricity: { count: 0, total: 0 }
    };

    fullData.forEach(row => {
        if (state === 'all' || row['Location'] === state) {
            const totalSchools = parseInt(row['Total No. of Schools']) || 0;
            
            infrastructureGaps.library.total += totalSchools;
            infrastructureGaps.library.count += parseInt(row['Library or Reading Corner or Book Bank']) || 0;
            
            infrastructureGaps.internet.total += totalSchools;
            infrastructureGaps.internet.count += parseInt(row['Internet']) || 0;
            
            infrastructureGaps.water.total += totalSchools;
            infrastructureGaps.water.count += parseInt(row['Drinking Water']) || 0;
            
            infrastructureGaps.toilet.total += totalSchools;
            infrastructureGaps.toilet.count += parseInt(row['Toilet']) || 0;
            
            infrastructureGaps.electricity.total += totalSchools;
            infrastructureGaps.electricity.count += parseInt(row['Electricity']) || 0;
        }
    });

    return infrastructureGaps;
}

function analyzeGenderParity(state) {
    const genderAnalysis = {
        girlsSchools: 0,
        boysSchools: 0,
        coEdSchools: 0,
        girlsToilets: 0,
        totalSchools: 0
    };

    fullData.forEach(row => {
        if (state === 'all' || row['Location'] === state) {
            const schoolCount = parseInt(row['Total No. of Schools']) || 0;
            const category = row['School Category'] || '';
            
            if (category.includes('Girls')) {
                genderAnalysis.girlsSchools += schoolCount;
            } else if (category.includes('Boys')) {
                genderAnalysis.boysSchools += schoolCount;
            } else if (category.includes('Co-Ed')) {
                genderAnalysis.coEdSchools += schoolCount;
            }
            
            genderAnalysis.totalSchools += schoolCount;
            genderAnalysis.girlsToilets += parseInt(row['Girls Toilet']) || 0;
        }
    });

    return genderAnalysis;
}

function prioritizeRecommendations(analysis) {
    const recommendations = [];
    const urgent = [];
    const important = [];
    const consideration = [];

    // Analyze infrastructure gaps
    Object.entries(analysis.infrastructure).forEach(([facility, data]) => {
        const coverage = (data.count / data.total) * 100;
        if (coverage < 50) {
            urgent.push(`Critical ${facility} shortage: Only ${coverage.toFixed(1)}% schools covered`);
        } else if (coverage < 75) {
            important.push(`Improve ${facility} coverage (current: ${coverage.toFixed(1)}%)`);
        }
    });

    // Analyze gender parity
    const genderData = analysis.genderParity;
    const coEdPercentage = (genderData.coEdSchools / genderData.totalSchools) * 100;
    
    if (coEdPercentage < 60) {
        important.push(`Increase co-educational schools (current: ${coEdPercentage.toFixed(1)}%)`);
    }

    // Format recommendations
    if (urgent.length > 0) {
        recommendations.push({
            priority: 'Urgent Actions Required',
            items: urgent
        });
    }

    if (important.length > 0) {
        recommendations.push({
            priority: 'Important Improvements Needed',
            items: important
        });
    }

    if (consideration.length > 0) {
        recommendations.push({
            priority: 'Consider for Long-term Planning',
            items: consideration
        });
    }

    return recommendations;
}

// Add this function to display recommendations in the UI
function displayRecommendations() {
    const state = document.getElementById('stateSelect').value;
    const recommendations = generateRecommendations(state);
    
    const recommendationsDiv = document.createElement('div');
    recommendationsDiv.className = 'recommendations-container';
    
    recommendations.forEach(category => {
        const categoryDiv = document.createElement('div');
        categoryDiv.className = 'recommendation-category';
        
        const header = document.createElement('h3');
        header.textContent = category.priority;
        header.className = category.priority.includes('Urgent') ? 'urgent' : 
                          category.priority.includes('Important') ? 'important' : 'consideration';
        
        const list = document.createElement('ul');
        category.items.forEach(item => {
            const li = document.createElement('li');
            li.textContent = item;
            list.appendChild(li);
        });
        
        categoryDiv.appendChild(header);
        categoryDiv.appendChild(list);
        recommendationsDiv.appendChild(categoryDiv);
    });

    // Replace or append to existing recommendations section
    const existingRecommendations = document.querySelector('.recommendations-container');
    if (existingRecommendations) {
        existingRecommendations.replaceWith(recommendationsDiv);
    } else {
        document.querySelector('.chart-container').after(recommendationsDiv);
    }
}

function analyzeRuralUrbanGap(state) {
    const analysis = {
        rural: {
            total: 0,
            withInternet: 0,
            withLibrary: 0,
            withElectricity: 0,
            withWater: 0,
            withToilets: 0
        },
        urban: {
            total: 0,
            withInternet: 0,
            withLibrary: 0,
            withElectricity: 0,
            withWater: 0,
            withToilets: 0
        }
    };

    fullData.forEach(row => {
        if (state === 'all' || row['Location'] === state) {
            const schoolCount = parseInt(row['Total No. of Schools']) || 0;
            const area = row['Rural/Urban'].trim().toLowerCase();
            
            if (area === 'rural' || area === 'urban') {
                analysis[area].total += schoolCount;
                analysis[area].withInternet += parseInt(row['Internet']) || 0;
                analysis[area].withLibrary += parseInt(row['Library or Reading Corner or Book Bank']) || 0;
                analysis[area].withElectricity += parseInt(row['Electricity']) || 0;
                analysis[area].withWater += parseInt(row['Drinking Water']) || 0;
                analysis[area].withToilets += parseInt(row['Toilet Facility']) || 0;
            }
        }
    });

    return analysis;
}

function analyzeSchoolTypes(state) {
    const analysis = {
        primary: { total: 0, withBasicInfra: 0 },
        secondary: { total: 0, withBasicInfra: 0 },
        higherSecondary: { total: 0, withBasicInfra: 0 }
    };

    fullData.forEach(row => {
        if (state === 'all' || row['Location'] === state) {
            const schoolCount = parseInt(row['Total No. of Schools']) || 0;
            const category = row['School Category'].toLowerCase();
            
            // Count schools by type
            if (category.includes('ps') || category.includes('primary')) {
                analysis.primary.total += schoolCount;
                if (hasBasicInfrastructure(row)) {
                    analysis.primary.withBasicInfra += schoolCount;
                }
            } else if (category.includes('ss') || category.includes('secondary')) {
                analysis.secondary.total += schoolCount;
                if (hasBasicInfrastructure(row)) {
                    analysis.secondary.withBasicInfra += schoolCount;
                }
            } else if (category.includes('hss') || category.includes('higher')) {
                analysis.higherSecondary.total += schoolCount;
                if (hasBasicInfrastructure(row)) {
                    analysis.higherSecondary.withBasicInfra += schoolCount;
                }
            }
        }
    });

    return analysis;
}

// Helper function to check if a school has basic infrastructure
function hasBasicInfrastructure(row) {
    return (
        parseInt(row['Electricity']) > 0 &&
        parseInt(row['Drinking Water']) > 0 &&
        parseInt(row['Toilet Facility']) > 0
    );
}

// Update the prioritizeRecommendations function to include rural-urban gap analysis
function prioritizeRecommendations(analysis) {
    const recommendations = [];
    const urgent = [];
    const important = [];
    const consideration = [];

    // Analyze infrastructure gaps
    Object.entries(analysis.infrastructure).forEach(([facility, data]) => {
        const coverage = (data.count / data.total) * 100;
        if (coverage < 50) {
            urgent.push(`Critical ${facility} shortage: Only ${coverage.toFixed(1)}% schools covered`);
        } else if (coverage < 75) {
            important.push(`Improve ${facility} coverage (current: ${coverage.toFixed(1)}%)`);
        }
    });

    // Analyze rural-urban gaps
    const ruralUrban = analysis.ruralUrbanGap;
    const ruralInternetRate = (ruralUrban.rural.withInternet / ruralUrban.rural.total) * 100;
    const urbanInternetRate = (ruralUrban.urban.withInternet / ruralUrban.urban.total) * 100;
    
    if (urbanInternetRate - ruralInternetRate > 30) {
        urgent.push(`Significant rural-urban digital divide: ${ruralInternetRate.toFixed(1)}% rural vs ${urbanInternetRate.toFixed(1)}% urban schools with internet`);
    }

    // Analyze school types
    const schoolTypes = analysis.schoolTypes;
    Object.entries(schoolTypes).forEach(([level, data]) => {
        const infraRate = (data.withBasicInfra / data.total) * 100;
        if (infraRate < 60) {
            important.push(`Improve basic infrastructure in ${level} schools (current: ${infraRate.toFixed(1)}%)`);
        }
    });

    // Analyze gender parity
    const genderData = analysis.genderParity;
    const coEdPercentage = (genderData.coEdSchools / genderData.totalSchools) * 100;
    
    if (coEdPercentage < 60) {
        important.push(`Increase co-educational schools (current: ${coEdPercentage.toFixed(1)}%)`);
    }

    // Format recommendations
    if (urgent.length > 0) {
        recommendations.push({
            priority: 'Urgent Actions Required',
            items: urgent
        });
    }

    if (important.length > 0) {
        recommendations.push({
            priority: 'Important Improvements Needed',
            items: important
        });
    }

    if (consideration.length > 0) {
        recommendations.push({
            priority: 'Consider for Long-term Planning',
            items: consideration
        });
    }

    return recommendations;
}

