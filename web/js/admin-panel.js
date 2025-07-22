// Country Road RP - Reckoning Admin Panel JavaScript
let sessionId = null;
let currentTab = 'dashboard';
let autoRefresh = true;
let refreshInterval = null;

// FiveM NUI API Helper
function callAPI(action, params = {}) {
    return new Promise((resolve, reject) => {
        // Store the resolve function for when we get the response
        window.pendingRequests = window.pendingRequests || {};
        const requestId = Date.now() + Math.random();
        window.pendingRequests[requestId] = resolve;
        
        // Call the NUI callback
        fetch(`https://countryroadrp-reckoning/adminAPI`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({
                action: action,
                params: params,
                requestId: requestId
            })
        }).catch(err => {
            reject(err);
            delete window.pendingRequests[requestId];
        });
        
        // Timeout after 10 seconds
        setTimeout(() => {
            if (window.pendingRequests[requestId]) {
                reject(new Error('Request timeout'));
                delete window.pendingRequests[requestId];
            }
        }, 10000);
    });
}

// Listen for NUI messages from client
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.type === 'authResult') {
        handleAuthResult(data.data);
    } else if (data.type === 'dashboardResult') {
        handleDashboardResult(data.data);
    } else if (data.type === 'playersResult') {
        handlePlayersResult(data.data);
    } else if (data.type === 'securityEventsResult') {
        handleSecurityEventsResult(data.data);
    } else if (data.type === 'tunnelActivityResult') {
        handleTunnelActivityResult(data.data);
    } else if (data.type === 'playerDetailsResult') {
        handlePlayerDetailsResult(data.data);
    } else if (data.type === 'playerActionResult') {
        handlePlayerActionResult(data.data);
    } else if (data.type === 'triggerEventResult') {
        handleTriggerEventResult(data.data);
    }
});

// Authentication
function authenticate() {
    // In a real implementation, this would show a login form
    const playerId = prompt('Enter your Player ID:');
    const token = prompt('Enter your token:');
    
    if (!playerId || !token) return;
    
    callAPI('authenticate', {playerId, token})
        .catch(error => {
            console.error('Auth error:', error);
            updateConnectionStatus(false);
            showNotification('Authentication failed: ' + error.message, 'error');
        });
}

function handleAuthResult(data) {
    if (data.success) {
        sessionId = data.sessionId;
        startAutoRefresh();
        loadData();
        showNotification('Authentication successful', 'success');
        updateConnectionStatus(true);
    } else {
        showNotification('Authentication failed: ' + data.error, 'error');
        updateConnectionStatus(false);
    }
}

// Auto-refresh functionality
function startAutoRefresh() {
    if (refreshInterval) clearInterval(refreshInterval);
    refreshInterval = setInterval(() => {
        if (autoRefresh) {
            updateRealtimeStats();
            if (currentTab === 'dashboard') {
                loadDashboard();
            }
        }
    }, 5000); // Refresh every 5 seconds
}

function toggleAutoRefresh() {
    autoRefresh = !autoRefresh;
    const btn = document.getElementById('auto-refresh-btn');
    btn.textContent = autoRefresh ? '⏸️' : '▶️';
    updateConnectionStatus(autoRefresh);
}

function updateConnectionStatus(connected) {
    const statusDot = document.getElementById('connection-status');
    const statusText = document.getElementById('connection-text');
    
    if (connected) {
        statusDot.className = 'status-dot status-online';
        statusText.textContent = 'Connected';
    } else {
        statusDot.className = 'status-dot status-offline';
        statusText.textContent = 'Disconnected';
    }
}

function updateRealtimeStats() {
    if (!sessionId) return;
    
    apiCall('/api/realtime-stats')
        .then(data => {
            document.getElementById('player-count').textContent = data.onlinePlayers;
            document.getElementById('active-events').textContent = data.activeEvents;
            document.getElementById('recent-activity').textContent = data.recentActivity;
            document.getElementById('server-uptime').textContent = formatUptime(data.systemUptime);
            updateConnectionStatus(true);
        })
        .catch(error => {
            console.error('Realtime stats error:', error);
            updateConnectionStatus(false);
        });
}

// API calls
function apiCall(endpoint) {
    return fetch(endpoint, {
        headers: {'Authorization': sessionId}
    }).then(response => response.json());
}

// Tab management
function showTab(tabName) {
    document.querySelectorAll('.tab-content').forEach(el => el.style.display = 'none');
    document.querySelectorAll('.nav button').forEach(el => el.classList.remove('active'));
    
    document.getElementById(tabName + '-content').style.display = 'block';
    document.getElementById('tab-' + tabName).classList.add('active');
    
    currentTab = tabName;
    loadTabData(tabName);
}

function loadTabData(tabName) {
    switch(tabName) {
        case 'dashboard':
            loadDashboard();
            break;
        case 'players':
            loadPlayers();
            break;
        case 'security':
            loadSecurityEvents();
            break;
        case 'tunnels':
            loadTunnelActivity();
            break;
        case 'resistance':
            loadResistanceActivity();
            break;
        case 'propaganda':
            loadPropaganda();
            break;
        case 'milestones':
            loadMilestones();
            break;
    }
}

function loadData() {
    loadTabData(currentTab);
}

function loadDashboard() {
    callAPI('getDashboard', {sessionId}).catch(error => {
        console.error('Dashboard error:', error);
        showNotification('Failed to load dashboard', 'error');
    });
}

function handleDashboardResult(data) {
    if (!data.success) {
        showNotification('Failed to load dashboard: ' + data.error, 'error');
        return;
    }
        document.getElementById('player-count').textContent = data.serverInfo.playerCount;
        document.getElementById('server-uptime').textContent = formatUptime(data.serverInfo.uptime);
        
        let html = '<div class="widget-grid">';
        
        // Recent Events
        html += '<div class="widget"><div class="widget-header"><h3>Recent Security Events</h3>';
        html += '<div class="widget-controls"><button onclick="showTab(\'security\')">View All</button></div></div>';
        if (data.recentEvents && data.recentEvents.length > 0) {
            html += '<table class="table"><thead><tr><th>Time</th><th>Player</th><th>Event</th><th>Severity</th></tr></thead><tbody>';
            data.recentEvents.forEach(event => {
                html += `<tr><td>${formatTime(event.timestamp)}</td><td>${event.player_name || 'Unknown'}</td><td>${event.event_type}</td><td><span class="severity-${event.severity}">${event.severity}</span></td></tr>`;
            });
            html += '</tbody></table>';
        } else {
            html += '<p>No recent events</p>';
        }
        html += '</div>';
        
        // System Stats
        html += '<div class="widget"><h3>System Statistics</h3>';
        if (data.systemStats) {
            for (const [category, stats] of Object.entries(data.systemStats)) {
                html += `<h4>${category.toUpperCase()}</h4>`;
                for (const [name, stat] of Object.entries(stats)) {
                    html += `<div class="stat-item"><span>${name.replace(/_/g, ' ')}</span><span class="stat-value">${stat.value}</span></div>`;
                }
            }
        } else {
            html += '<p>No statistics available</p>';
        }
        html += '</div>';
        
        // High Risk Players
        html += '<div class="widget"><h3>High Risk Players</h3>';
        if (data.highRiskPlayers && data.highRiskPlayers.length > 0) {
            html += '<table class="table"><thead><tr><th>Name</th><th>Suspicion</th><th>Violations</th></tr></thead><tbody>';
            data.highRiskPlayers.forEach(player => {
                html += `<tr class="clickable" onclick="showPlayerDetails('${player.citizenid}')">
                    <td>${player.player_name}</td>
                    <td><span style="color: ${player.suspicion_level > 75 ? '#e74c3c' : player.suspicion_level > 50 ? '#f39c12' : '#3498db'}">${player.suspicion_level}%</span></td>
                    <td>${player.total_violations}</td>
                </tr>`;
            });
            html += '</tbody></table>';
        } else {
            html += '<p>No high-risk players</p>';
        }
        html += '</div>';
        
        // Milestones Progress
        html += '<div class="widget"><h3>Story Milestones</h3>';
        if (data.milestones && data.milestones.length > 0) {
            data.milestones.forEach(milestone => {
                const progress = (milestone.current_triggers / milestone.required_triggers) * 100;
                html += `<div class="stat-item">
                    <span>${milestone.milestone_name.replace(/_/g, ' ')}</span>
                    <span class="stat-value">${milestone.current_triggers}/${milestone.required_triggers}</span>
                </div>
                <div class="progress-bar">
                    <div class="progress-fill" style="width: ${progress}%"></div>
                </div>`;
            });
        } else {
            html += '<p>No milestones data</p>';
        }
        html += '</div>';
        
        html += '</div>';
        document.getElementById('dashboard-content').innerHTML = html;
}

function handlePlayersResult(data) {
    if (!data.success) {
        showNotification('Failed to load players: ' + data.error, 'error');
        return;
    }
    
    let html = '<div class="widget">';
    html += '<div class="widget-header"><h3>Player Profiles</h3>';
    html += '<div class="widget-controls">';
    html += '<button onclick="exportData(\'player_profiles\')">Export</button>';
    html += '</div></div>';
    
    // Filters
    html += '<div class="filters">';
    html += '<select id="suspicion-filter" onchange="filterPlayers()"><option value="">All Suspicion Levels</option><option value="high">High (75%+)</option><option value="medium">Medium (25-75%)</option><option value="low">Low (<25%)</option></select>';
    html += '<select id="job-filter" onchange="filterPlayers()"><option value="">All Jobs</option></select>';
    html += '<input type="text" id="name-filter" placeholder="Search by name..." onkeyup="filterPlayers()">';
    html += '</div>';
    
    if (data.players && data.players.length > 0) {
        html += '<table class="table" id="players-table">';
        html += '<thead><tr><th>Name</th><th>Clearance</th><th>Job</th><th>Suspicion</th><th>Violations</th><th>Last Activity</th><th>Actions</th></tr></thead><tbody>';
        
        data.players.forEach(player => {
            const suspicionColor = player.suspicion_level > 75 ? '#e74c3c' : player.suspicion_level > 50 ? '#f39c12' : player.suspicion_level > 25 ? '#f1c40f' : '#27ae60';
            html += `<tr data-suspicion="${player.suspicion_level}" data-job="${player.job_name}" data-name="${player.player_name.toLowerCase()}">
                <td class="clickable" onclick="showPlayerDetails('${player.citizenid}')">${player.player_name}</td>
                <td>Level ${player.clearance_level}</td>
                <td>${player.job_name} (${player.job_rank})</td>
                <td><span style="color: ${suspicionColor}">${player.suspicion_level}%</span></td>
                <td>${player.total_violations || 0}</td>
                <td>${formatTime(player.last_activity)}</td>
                <td>
                    <button onclick="showPlayerActions('${player.citizenid}')" class="btn" style="padding: 0.25rem 0.5rem; font-size: 0.8rem;">Actions</button>
                </td>
            </tr>`;
        });
        html += '</tbody></table>';
        
        // Pagination
        if (data.pagination && data.pagination.total > data.pagination.limit) {
            html += '<div class="pagination">';
            const totalPages = Math.ceil(data.pagination.total / data.pagination.limit);
            for (let i = 1; i <= totalPages; i++) {
                const active = i === data.pagination.page ? 'active' : '';
                html += `<button class="pagination-btn ${active}" onclick="loadPlayers(${i})">${i}</button>`;
            }
            html += '</div>';
        }
    } else {
        html += '<p>No players found</p>';
    }
    html += '</div>';
    
    document.getElementById('players-content').innerHTML = html;
}

function handleSecurityEventsResult(data) {
    if (!data.success) {
        showNotification('Failed to load security events: ' + data.error, 'error');
        return;
    }
    
    let html = '<div class="widget">';
    html += '<div class="widget-header"><h3>Security Events</h3>';
    html += '<div class="widget-controls">';
    html += '<button onclick="exportData(\'security_logs\')">Export</button>';
    html += '</div></div>';
    
    // Filters
    html += '<div class="filters">';
    html += '<select id="severity-filter" onchange="filterSecurityEvents()"><option value="">All Severities</option><option value="low">Low</option><option value="medium">Medium</option><option value="high">High</option><option value="critical">Critical</option></select>';
    html += '<input type="text" id="player-filter" placeholder="Search by player..." onkeyup="filterSecurityEvents()">';
    html += '</div>';
    
    if (data.events && data.events.length > 0) {
        html += '<table class="table">';
        html += '<thead><tr><th>Time</th><th>Player</th><th>Event Type</th><th>Severity</th><th>Description</th><th>Location</th></tr></thead><tbody>';
        
        data.events.forEach(event => {
            const severityClass = 'severity-' + event.severity;
            html += `<tr>
                <td>${formatTime(event.timestamp)}</td>
                <td class="clickable" onclick="showPlayerDetails('${event.citizenid}')">${event.player_name || 'Unknown'}</td>
                <td>${event.event_type}</td>
                <td><span class="${severityClass}">${event.severity.toUpperCase()}</span></td>
                <td>${event.description}</td>
                <td>${event.location || 'N/A'}</td>
            </tr>`;
        });
        html += '</tbody></table>';
        
        // Pagination
        if (data.pagination && data.pagination.total > data.pagination.limit) {
            html += '<div class="pagination">';
            const totalPages = Math.ceil(data.pagination.total / data.pagination.limit);
            for (let i = 1; i <= totalPages; i++) {
                const active = i === data.pagination.page ? 'active' : '';
                html += `<button class="pagination-btn ${active}" onclick="loadSecurityEvents(${i})">${i}</button>`;
            }
            html += '</div>';
        }
    } else {
        html += '<p>No security events found</p>';
    }
    html += '</div>';
    
    document.getElementById('security-content').innerHTML = html;
}

function handleTunnelActivityResult(data) {
    if (!data.success) {
        showNotification('Failed to load tunnel activity: ' + data.error, 'error');
        return;
    }
    
    let html = '<div class="widget">';
    html += '<div class="widget-header"><h3>Tunnel Access Activity</h3></div>';
    
    if (data.activity && data.activity.length > 0) {
        html += '<table class="table">';
        html += '<thead><tr><th>Time</th><th>Player</th><th>Clearance</th><th>Entry Point</th><th>Exit Time</th><th>Duration</th></tr></thead><tbody>';
        
        data.activity.forEach(access => {
            const duration = access.exit_time ? 
                Math.round((new Date(access.exit_time) - new Date(access.entry_time)) / 60000) + ' min' : 
                'Still inside';
            html += `<tr>
                <td>${formatTime(access.entry_time)}</td>
                <td class="clickable" onclick="showPlayerDetails('${access.citizenid}')">${access.player_name}</td>
                <td>Level ${access.clearance_level}</td>
                <td>${access.entry_tunnel || 'Unknown'}</td>
                <td>${access.exit_time ? formatTime(access.exit_time) : 'N/A'}</td>
                <td>${duration}</td>
            </tr>`;
        });
        html += '</tbody></table>';
    } else {
        html += '<p>No tunnel activity found</p>';
    }
    html += '</div>';
    
    document.getElementById('tunnels-content').innerHTML = html;
}

function handlePlayerDetailsResult(data) {
    if (!data.success) {
        showNotification('Failed to load player details: ' + data.error, 'error');
        return;
    }
    
    const player = data.player;
    let html = `
        <div class="modal" id="player-details-modal">
            <div class="modal-content">
                <div class="modal-header">
                    <h2>Player Details: ${player.player_name}</h2>
                    <span class="close" onclick="closeModal('player-details-modal')">&times;</span>
                </div>
                <div class="modal-body">
                    <div class="player-info-grid">
                        <div class="info-section">
                            <h3>Basic Information</h3>
                            <p><strong>Citizen ID:</strong> ${player.citizenid}</p>
                            <p><strong>Job:</strong> ${player.job_name} (${player.job_rank})</p>
                            <p><strong>Clearance Level:</strong> Level ${player.clearance_level}</p>
                            <p><strong>Suspicion Level:</strong> <span style="color: ${player.suspicion_level > 75 ? '#e74c3c' : player.suspicion_level > 50 ? '#f39c12' : '#27ae60'}">${player.suspicion_level}%</span></p>
                            <p><strong>Last Activity:</strong> ${formatTime(player.last_activity)}</p>
                        </div>
                        <div class="info-section">
                            <h3>Statistics</h3>
                            <p><strong>Total Violations:</strong> ${player.total_violations || 0}</p>
                            <p><strong>Security Events:</strong> ${data.securityEvents.length}</p>
                            <p><strong>Tunnel Accesses:</strong> ${data.tunnelAccess.length}</p>
                            <p><strong>Blackline Events:</strong> ${data.blacklineEvents.length}</p>
                        </div>
                    </div>
                    
                    ${player.notes ? `<div class="info-section">
                        <h3>Admin Notes</h3>
                        <pre>${player.notes}</pre>
                    </div>` : ''}
                    
                    <div class="info-section">
                        <h3>Recent Security Events</h3>
                        ${data.securityEvents.length > 0 ? `
                            <table class="table">
                                <thead><tr><th>Time</th><th>Event</th><th>Severity</th><th>Description</th></tr></thead>
                                <tbody>
                                    ${data.securityEvents.slice(0, 10).map(event => `
                                        <tr>
                                            <td>${formatTime(event.timestamp)}</td>
                                            <td>${event.event_type}</td>
                                            <td><span class="severity-${event.severity}">${event.severity}</span></td>
                                            <td>${event.description}</td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        ` : '<p>No security events</p>'}
                    </div>
                    
                    <div class="modal-actions">
                        <button onclick="showPlayerActions('${player.citizenid}')" class="btn btn-primary">Player Actions</button>
                        <button onclick="closeModal('player-details-modal')" class="btn btn-secondary">Close</button>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    document.body.insertAdjacentHTML('beforeend', html);
}

function handlePlayerActionResult(data) {
    if (data.success) {
        showNotification(data.message, 'success');
        // Refresh current view if needed
        if (currentTab === 'players') {
            loadPlayers();
        }
    } else {
        showNotification(data.message || 'Action failed', 'error');
    }
}

function handleTriggerEventResult(data) {
    if (data.success) {
        showNotification(data.message, 'success');
    } else {
        showNotification(data.message || 'Event trigger failed', 'error');
    }
}

function loadPlayers(page = 1) {
    callAPI('getPlayers', {sessionId, page, limit: 25})
        .catch(error => {
            console.error('Players error:', error);
            showNotification('Failed to load players', 'error');
        });
}

function loadSecurityEvents(page = 1) {
    callAPI('getSecurityEvents', {sessionId, page, limit: 25})
        .catch(error => {
            console.error('Security events error:', error);
            showNotification('Failed to load security events', 'error');
        });
}

function showPlayerDetails(citizenid) {
    callAPI('getPlayerDetails', {sessionId, citizenid})
        .catch(error => {
            console.error('Player details error:', error);
            showNotification('Failed to load player details', 'error');
        });
}

function showPlayerActions(citizenid) {
    const html = `
        <div class="modal" id="player-actions-modal">
            <div class="modal-content">
                <div class="modal-header">
                    <h2>Player Actions</h2>
                    <span class="close" onclick="closeModal('player-actions-modal')">&times;</span>
                </div>
                <div class="modal-body">
                    <div class="action-section">
                        <h3>Update Suspicion Level</h3>
                        <input type="number" id="suspicion-input" min="0" max="100" placeholder="0-100">
                        <button onclick="updateSuspicion('${citizenid}')" class="btn">Update</button>
                    </div>
                    
                    <div class="action-section">
                        <h3>Update Clearance Level</h3>
                        <select id="clearance-input">
                            <option value="0">Level 0 - No Access</option>
                            <option value="1">Level 1 - Basic</option>
                            <option value="2">Level 2 - Standard</option>
                            <option value="3">Level 3 - High</option>
                            <option value="4">Level 4 - Maximum</option>
                        </select>
                        <button onclick="updateClearance('${citizenid}')" class="btn">Update</button>
                    </div>
                    
                    <div class="action-section">
                        <h3>Add Admin Note</h3>
                        <textarea id="note-input" placeholder="Enter admin note..."></textarea>
                        <button onclick="addNote('${citizenid}')" class="btn">Add Note</button>
                    </div>
                    
                    <div class="action-section">
                        <h3>Trigger Blackline Event</h3>
                        <select id="blackline-type">
                            <option value="interrogation">Interrogation</option>
                            <option value="memory_wipe">Memory Wipe</option>
                            <option value="surveillance">Surveillance</option>
                        </select>
                        <button onclick="triggerBlackline('${citizenid}')" class="btn btn-warning">Trigger</button>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    document.body.insertAdjacentHTML('beforeend', html);
}

function updateSuspicion(citizenid) {
    const suspicionLevel = document.getElementById('suspicion-input').value;
    if (!suspicionLevel || suspicionLevel < 0 || suspicionLevel > 100) {
        showNotification('Invalid suspicion level (0-100)', 'error');
        return;
    }
    
    callAPI('playerAction', {
        sessionId,
        action: 'update_suspicion',
        citizenid,
        params: {suspicionLevel: parseInt(suspicionLevel)}
    }).catch(error => {
        console.error('Update suspicion error:', error);
        showNotification('Failed to update suspicion', 'error');
    });
    
    closeModal('player-actions-modal');
}

function updateClearance(citizenid) {
    const clearanceLevel = document.getElementById('clearance-input').value;
    
    callAPI('playerAction', {
        sessionId,
        action: 'update_clearance',
        citizenid,
        params: {clearanceLevel: parseInt(clearanceLevel)}
    }).catch(error => {
        console.error('Update clearance error:', error);
        showNotification('Failed to update clearance', 'error');
    });
    
    closeModal('player-actions-modal');
}

function addNote(citizenid) {
    const note = document.getElementById('note-input').value;
    if (!note.trim()) {
        showNotification('Note cannot be empty', 'error');
        return;
    }
    
    callAPI('playerAction', {
        sessionId,
        action: 'add_note',
        citizenid,
        params: {note: note.trim()}
    }).catch(error => {
        console.error('Add note error:', error);
        showNotification('Failed to add note', 'error');
    });
    
    closeModal('player-actions-modal');
}

function triggerBlackline(citizenid) {
    const eventType = document.getElementById('blackline-type').value;
    
    callAPI('playerAction', {
        sessionId,
        action: 'trigger_blackline',
        citizenid,
        params: {eventType}
    }).catch(error => {
        console.error('Trigger blackline error:', error);
        showNotification('Failed to trigger blackline event', 'error');
    });
    
    closeModal('player-actions-modal');
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.remove();
    }
}

function loadPlayers() {
    document.getElementById('players-content').innerHTML = '<div class="loading">Loading player data...</div>';
    
    apiCall('/api/players').then(data => {
        let html = '<div class="widget">';
        html += '<div class="widget-header"><h3>Player Profiles</h3>';
        html += '<div class="widget-controls">';
        html += '<button onclick="exportData(\'player_profiles\')">Export</button>';
        html += '</div></div>';
        
        // Filters
        html += '<div class="filters">';
        html += '<select id="suspicion-filter" onchange="filterPlayers()"><option value="">All Suspicion Levels</option><option value="high">High (75%+)</option><option value="medium">Medium (25-75%)</option><option value="low">Low (<25%)</option></select>';
        html += '<select id="job-filter" onchange="filterPlayers()"><option value="">All Jobs</option></select>';
        html += '<input type="text" id="name-filter" placeholder="Search by name..." onkeyup="filterPlayers()">';
        html += '</div>';
        
        if (data.players && data.players.length > 0) {
            html += '<table class="table" id="players-table">';
            html += '<thead><tr><th>Name</th><th>Clearance</th><th>Job</th><th>Suspicion</th><th>Violations</th><th>Last Activity</th><th>Actions</th></tr></thead><tbody>';
            
            data.players.forEach(player => {
                const suspicionColor = player.suspicion_level > 75 ? '#e74c3c' : player.suspicion_level > 50 ? '#f39c12' : player.suspicion_level > 25 ? '#f1c40f' : '#27ae60';
                html += `<tr data-suspicion="${player.suspicion_level}" data-job="${player.job_name}" data-name="${player.player_name.toLowerCase()}">
                    <td class="clickable" onclick="showPlayerDetails('${player.citizenid}')">${player.player_name}</td>
                    <td>Level ${player.clearance_level}</td>
                    <td>${player.job_name} (${player.job_rank})</td>
                    <td><span style="color: ${suspicionColor}">${player.suspicion_level}%</span></td>
                    <td>${player.total_violations}</td>
                    <td>${formatTime(player.last_activity)}</td>
                    <td>
                        <button onclick="showPlayerActions('${player.citizenid}')" class="btn" style="padding: 0.25rem 0.5rem; font-size: 0.8rem;">Actions</button>
                    </td>
                </tr>`;
            });
            html += '</tbody></table>';
            
            // Pagination
            if (data.pagination) {
                html += '<div class="pagination">';
                const totalPages = Math.ceil(data.pagination.total / data.pagination.limit);
                for (let i = 1; i <= Math.min(totalPages, 10); i++) {
                    html += `<button onclick="loadPlayersPage(${i})" ${i === data.pagination.page ? 'class="active"' : ''}>${i}</button>`;
                }
                html += '</div>';
            }
        } else {
            html += '<p>No players found</p>';
        }
        
        html += '</div>';
        document.getElementById('players-content').innerHTML = html;
        
        // Populate job filter
        const jobFilter = document.getElementById('job-filter');
        const jobs = [...new Set(data.players.map(p => p.job_name))];
        jobs.forEach(job => {
            const option = document.createElement('option');
            option.value = job;
            option.textContent = job;
            jobFilter.appendChild(option);
        });
        
    }).catch(error => {
        console.error('Players error:', error);
        document.getElementById('players-content').innerHTML = '<div class="alert alert-danger">Failed to load player data</div>';
    });
}

function loadSecurityEvents() {
    document.getElementById('security-content').innerHTML = '<div class="loading">Loading security events...</div>';
    
    apiCall('/api/security-events').then(data => {
        let html = '<div class="widget">';
        html += '<div class="widget-header"><h3>Security Events</h3>';
        html += '<div class="widget-controls">';
        html += '<button onclick="exportData(\'security_logs\')">Export</button>';
        html += '</div></div>';
        
        // Filters
        html += '<div class="filters">';
        html += '<select id="severity-filter" onchange="loadSecurityEvents()"><option value="">All Severities</option><option value="critical">Critical</option><option value="alert">Alert</option><option value="warning">Warning</option><option value="info">Info</option></select>';
        html += '<input type="text" id="player-filter" placeholder="Filter by player..." onkeyup="debounce(loadSecurityEvents, 500)()">';
        html += '</div>';
        
        if (data.events && data.events.length > 0) {
            html += '<table class="table">';
            html += '<thead><tr><th>Time</th><th>Player</th><th>Event Type</th><th>Category</th><th>Severity</th><th>Description</th><th>Location</th></tr></thead><tbody>';
            
            data.events.forEach(event => {
                html += `<tr>
                    <td>${formatTime(event.timestamp)}</td>
                    <td class="clickable" onclick="showPlayerDetails('${event.citizenid}')">${event.player_name || 'Unknown'}</td>
                    <td>${event.event_type}</td>
                    <td>${event.event_category}</td>
                    <td><span class="severity-${event.severity}">${event.severity}</span></td>
                    <td title="${event.description}">${event.description.length > 50 ? event.description.substring(0, 50) + '...' : event.description}</td>
                    <td>${event.location_x ? `${event.location_x.toFixed(1)}, ${event.location_y.toFixed(1)}` : 'N/A'}</td>
                </tr>`;
            });
            html += '</tbody></table>';
        } else {
            html += '<p>No security events found</p>';
        }
        
        html += '</div>';
        document.getElementById('security-content').innerHTML = html;
        
    }).catch(error => {
        console.error('Security events error:', error);
        document.getElementById('security-content').innerHTML = '<div class="alert alert-danger">Failed to load security events</div>';
    });
}

function loadTunnelActivity() {
    document.getElementById('tunnels-content').innerHTML = '<div class="loading">Loading tunnel activity...</div>';
    
    apiCall('/api/tunnel-activity').then(data => {
        let html = '<div class="widget-grid">';
        
        // Activity Summary
        html += '<div class="widget"><h3>Tunnel Usage Summary</h3>';
        if (data.summary && data.summary.length > 0) {
            html += '<table class="table"><thead><tr><th>Zone</th><th>Total Attempts</th><th>Successful</th><th>Denied</th><th>Avg Duration</th><th>Last Activity</th></tr></thead><tbody>';
            data.summary.forEach(zone => {
                html += `<tr>
                    <td>${zone.tunnel_zone}</td>
                    <td>${zone.total_attempts}</td>
                    <td><span style="color: #27ae60">${zone.successful_access}</span></td>
                    <td><span style="color: #e74c3c">${zone.denied_access}</span></td>
                    <td>${zone.avg_duration ? Math.round(zone.avg_duration / 60) + 'm' : 'N/A'}</td>
                    <td>${formatTime(zone.last_activity)}</td>
                </tr>`;
            });
            html += '</tbody></table>';
        } else {
            html += '<p>No tunnel activity summary available</p>';
        }
        html += '</div>';
        
        // Recent Activity
        html += '<div class="widget"><h3>Recent Tunnel Access</h3>';
        if (data.activity && data.activity.length > 0) {
            html += '<table class="table"><thead><tr><th>Time</th><th>Player</th><th>Zone</th><th>Access</th><th>Clearance</th><th>Duration</th></tr></thead><tbody>';
            data.activity.slice(0, 20).forEach(access => {
                const accessColor = access.access_granted ? '#27ae60' : '#e74c3c';
                const accessText = access.access_granted ? 'Granted' : 'Denied';
                html += `<tr>
                    <td>${formatTime(access.entry_time)}</td>
                    <td class="clickable" onclick="showPlayerDetails('${access.citizenid}')">${access.player_name || 'Unknown'}</td>
                    <td>${access.tunnel_zone}</td>
                    <td><span style="color: ${accessColor}">${accessText}</span></td>
                    <td>Level ${access.clearance_used || 0}</td>
                    <td>${access.duration_seconds ? Math.round(access.duration_seconds / 60) + 'm' : 'Active'}</td>
                </tr>`;
            });
            html += '</tbody></table>';
        } else {
            html += '<p>No recent tunnel activity</p>';
        }
        html += '</div>';
        
        html += '</div>';
        document.getElementById('tunnels-content').innerHTML = html;
        
    }).catch(error => {
        console.error('Tunnel activity error:', error);
        document.getElementById('tunnels-content').innerHTML = '<div class="alert alert-danger">Failed to load tunnel activity</div>';
    });
}

function loadResistanceActivity() {
    document.getElementById('resistance-content').innerHTML = '<div class="loading">Loading resistance activity...</div>';
    
    apiCall('/api/resistance-activity').then(data => {
        let html = '<div class="widget">';
        html += '<div class="widget-header"><h3>Resistance Activity</h3>';
        html += '<div class="widget-controls">';
        html += '<button onclick="showModal(\'emergency-broadcast\')">Emergency Broadcast</button>';
        html += '</div></div>';
        
        if (data.activity && data.activity.length > 0) {
            html += '<table class="table"><thead><tr><th>Time</th><th>Type</th><th>Message/Details</th><th>Frequency</th><th>Signal Strength</th><th>Detected</th></tr></thead><tbody>';
            data.activity.forEach(activity => {
                const detectedColor = activity.detected_by_security ? '#e74c3c' : '#27ae60';
                const detectedText = activity.detected_by_security ? 'Yes' : 'No';
                html += `<tr>
                    <td>${formatTime(activity.timestamp)}</td>
                    <td>${activity.activity_type}</td>
                    <td title="${activity.message || 'N/A'}">${activity.message ? (activity.message.length > 50 ? activity.message.substring(0, 50) + '...' : activity.message) : 'N/A'}</td>
                    <td>${activity.frequency || 'N/A'}</td>
                    <td>${activity.signal_strength ? (activity.signal_strength * 100).toFixed(1) + '%' : 'N/A'}</td>
                    <td><span style="color: ${detectedColor}">${detectedText}</span></td>
                </tr>`;
            });
            html += '</tbody></table>';
        } else {
            html += '<p>No resistance activity recorded</p>';
        }
        
        html += '</div>';
        document.getElementById('resistance-content').innerHTML = html;
        
    }).catch(error => {
        console.error('Resistance activity error:', error);
        document.getElementById('resistance-content').innerHTML = '<div class="alert alert-danger">Failed to load resistance activity</div>';
    });
}

function loadPropaganda() {
    document.getElementById('propaganda-content').innerHTML = '<div class="loading">Loading propaganda data...</div>';
    
    apiCall('/api/propaganda').then(data => {
        let html = '<div class="widget">';
        html += '<div class="widget-header"><h3>Northbridge Propaganda</h3>';
        html += '<div class="widget-controls">';
        html += '<button onclick="showModal(\'propaganda-create\')">Create Announcement</button>';
        html += '</div></div>';
        
        if (data.propaganda && data.propaganda.length > 0) {
            html += '<table class="table"><thead><tr><th>Time</th><th>Channel</th><th>Type</th><th>Message</th><th>Audience</th><th>Effectiveness</th></tr></thead><tbody>';
            data.propaganda.forEach(prop => {
                const channelColor = prop.channel === 'emergency' ? '#e74c3c' : prop.channel === 'internal' ? '#f39c12' : '#3498db';
                html += `<tr>
                    <td>${formatTime(prop.broadcast_time)}</td>
                    <td><span style="color: ${channelColor}">${prop.channel}</span></td>
                    <td>${prop.message_type}</td>
                    <td title="${prop.message}">${prop.message.length > 60 ? prop.message.substring(0, 60) + '...' : prop.message}</td>
                    <td>${prop.audience_count || 'N/A'}</td>
                    <td>${prop.effectiveness_score ? (prop.effectiveness_score * 100).toFixed(1) + '%' : 'N/A'}</td>
                </tr>`;
            });
            html += '</tbody></table>';
        } else {
            html += '<p>No propaganda broadcasts recorded</p>';
        }
        
        html += '</div>';
        document.getElementById('propaganda-content').innerHTML = html;
        
    }).catch(error => {
        console.error('Propaganda error:', error);
        document.getElementById('propaganda-content').innerHTML = '<div class="alert alert-danger">Failed to load propaganda data</div>';
    });
}

function loadMilestones() {
    document.getElementById('milestones-content').innerHTML = '<div class="loading">Loading milestone data...</div>';
    
    apiCall('/api/milestones').then(data => {
        let html = '<div class="widget-grid">';
        
        if (data.milestones && data.milestones.length > 0) {
            data.milestones.forEach(milestone => {
                const progress = (milestone.current_triggers / milestone.required_triggers) * 100;
                const statusColor = milestone.status === 'completed' ? '#27ae60' : milestone.status === 'active' ? '#3498db' : '#95a5a6';
                
                html += `<div class="widget" style="border-left-color: ${statusColor}">
                    <div class="widget-header">
                        <h3>${milestone.milestone_name.replace(/_/g, ' ').toUpperCase()}</h3>
                        <span class="stat-value" style="color: ${statusColor}">${milestone.status}</span>
                    </div>
                    <p>${milestone.description || 'No description available'}</p>
                    <div class="stat-item">
                        <span>Progress:</span>
                        <span class="stat-value">${milestone.current_triggers}/${milestone.required_triggers}</span>
                    </div>
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: ${progress}%; background: ${statusColor}"></div>
                    </div>
                    ${milestone.first_trigger_time ? `<p style="margin-top: 0.5rem; font-size: 0.9em; color: #bdc3c7;">First trigger: ${formatTime(milestone.first_trigger_time)}</p>` : ''}
                    ${milestone.completion_time ? `<p style="font-size: 0.9em; color: #bdc3c7;">Completed: ${formatTime(milestone.completion_time)}</p>` : ''}
                </div>`;
            });
        } else {
            html += '<div class="widget"><h3>No Milestones</h3><p>No milestone data available</p></div>';
        }
        
        html += '</div>';
        document.getElementById('milestones-content').innerHTML = html;
        
    }).catch(error => {
        console.error('Milestones error:', error);
        document.getElementById('milestones-content').innerHTML = '<div class="alert alert-danger">Failed to load milestone data</div>';
    });
}

// Modal functions
function showModal(modalType) {
    const modal = document.getElementById(modalType + '-modal');
    if (modal) {
        modal.style.display = 'block';
    }
}

function closeModal(modalId) {
    document.getElementById(modalId).style.display = 'none';
}

// Event functions
function triggerEvent(eventType) {
    if (!confirm('Are you sure you want to trigger this event?')) return;
    
    fetch('/api/trigger-event', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': sessionId
        },
        body: JSON.stringify({eventType})
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showNotification('Event triggered: ' + data.message, 'success');
            refreshData();
        } else {
            showNotification('Failed to trigger event: ' + data.message, 'error');
        }
    })
    .catch(error => {
        console.error('Trigger event error:', error);
        showNotification('Error triggering event', 'error');
    });
}

function sendEmergencyBroadcast() {
    const message = document.getElementById('broadcast-message').value;
    if (!message.trim()) {
        alert('Please enter a message');
        return;
    }
    
    fetch('/api/trigger-event', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': sessionId
        },
        body: JSON.stringify({
            eventType: 'emergency_broadcast',
            params: { message: message }
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showNotification('Emergency broadcast sent', 'success');
            closeModal('emergency-broadcast-modal');
            document.getElementById('broadcast-message').value = '';
        } else {
            showNotification('Failed to send broadcast: ' + data.message, 'error');
        }
    });
}

function activateLockdown() {
    const x = document.getElementById('lockdown-x').value;
    const y = document.getElementById('lockdown-y').value;
    const z = document.getElementById('lockdown-z').value;
    
    if (!x || !y || !z) {
        alert('Please enter all coordinates');
        return;
    }
    
    fetch('/api/trigger-event', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': sessionId
        },
        body: JSON.stringify({
            eventType: 'lockdown_zone',
            params: { coords: { x: parseFloat(x), y: parseFloat(y), z: parseFloat(z) } }
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showNotification('Zone lockdown activated', 'success');
            closeModal('lockdown-zone-modal');
        } else {
            showNotification('Failed to activate lockdown: ' + data.message, 'error');
        }
    });
}

function exportData(type) {
    if (!type) {
        type = document.getElementById('export-type').value;
        closeModal('export-data-modal');
    }
    
    const format = document.getElementById('export-format') ? document.getElementById('export-format').value : 'json';
    
    window.open(`/api/export?type=${type}&format=${format}`, '_blank');
    showNotification('Export started', 'success');
}

// Search functions
function handleSearchKeypress(event) {
    if (event.key === 'Enter') {
        performGlobalSearch();
    }
}

function performGlobalSearch() {
    const query = document.getElementById('global-search').value;
    if (!query.trim()) return;
    
    apiCall(`/api/search?q=${encodeURIComponent(query)}`).then(data => {
        showSearchResults(data);
    });
}

function showSearchResults(results) {
    // Implementation for search results modal
    console.log('Search results:', results);
}

// Filter functions
function filterPlayers() {
    const suspicionFilter = document.getElementById('suspicion-filter').value;
    const jobFilter = document.getElementById('job-filter').value;
    const nameFilter = document.getElementById('name-filter').value.toLowerCase();
    const table = document.getElementById('players-table');
    
    if (!table) return;
    
    const rows = table.querySelectorAll('tbody tr');
    rows.forEach(row => {
        let show = true;
        
        if (suspicionFilter) {
            const suspicion = parseInt(row.dataset.suspicion);
            if (suspicionFilter === 'high' && suspicion < 75) show = false;
            if (suspicionFilter === 'medium' && (suspicion < 25 || suspicion >= 75)) show = false;
            if (suspicionFilter === 'low' && suspicion >= 25) show = false;
        }
        
        if (jobFilter && row.dataset.job !== jobFilter) show = false;
        if (nameFilter && !row.dataset.name.includes(nameFilter)) show = false;
        
        row.style.display = show ? '' : 'none';
    });
}

// Utility functions
function refreshData() {
    loadTabData(currentTab);
}

function formatTime(timestamp) {
    return new Date(timestamp).toLocaleString();
}

function formatUptime(ms) {
    const hours = Math.floor(ms / 3600000);
    const minutes = Math.floor((ms % 3600000) / 60000);
    return `${hours}h ${minutes}m`;
}

function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification alert-${type}`;
    notification.textContent = message;
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.remove();
    }, 5000);
}

function debounce(func, delay) {
    let timeoutId;
    return function (...args) {
        clearTimeout(timeoutId);
        timeoutId = setTimeout(() => func.apply(this, args), delay);
    };
}

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    authenticate();
});

// Auto-refresh
setInterval(() => {
    if (autoRefresh && sessionId) {
        updateRealtimeStats();
    }
}, 30000); // Refresh every 30 seconds

// Close modals when clicking outside
window.onclick = function(event) {
    const modals = document.querySelectorAll('.modal');
    modals.forEach(modal => {
        if (event.target === modal) {
            modal.style.display = 'none';
        }
    });
}
