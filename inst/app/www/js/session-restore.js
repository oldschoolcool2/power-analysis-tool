/**
 * Session Restore & User Preferences
 * Saves user inputs to localStorage and offers to restore on next visit
 */

(function() {
  'use strict';

  const STORAGE_KEY = 'powerAnalysisTool_session';
  const STORAGE_VERSION = '1.0';
  const SAVE_DELAY = 1000; // Debounce save for 1 second
  let saveTimeout = null;
  let sessionData = null;
  let hasUnsavedWork = false;

  /**
   * Load session data from localStorage
   */
  function loadSessionData() {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored) {
        const data = JSON.parse(stored);
        if (data.version === STORAGE_VERSION) {
          return data;
        }
      }
    } catch (e) {
      console.warn('Failed to load session data:', e);
    }
    return null;
  }

  /**
   * Save current session data to localStorage
   */
  function saveSessionData() {
    try {
      // Collect all input values
      const inputs = {};

      // Collect numeric inputs
      document.querySelectorAll('input[type="number"]').forEach(input => {
        if (input.id) {
          inputs[input.id] = parseFloat(input.value) || null;
        }
      });

      // Collect radio buttons
      document.querySelectorAll('input[type="radio"]:checked').forEach(radio => {
        if (radio.name) {
          inputs[radio.name] = radio.value;
        }
      });

      // Collect select dropdowns
      document.querySelectorAll('select').forEach(select => {
        if (select.id) {
          inputs[select.id] = select.value;
        }
      });

      // Collect sidebar page
      const sidebarPage = document.querySelector('input[name="sidebar_page"]');
      if (sidebarPage) {
        inputs.sidebar_page = sidebarPage.value;
      }

      const data = {
        version: STORAGE_VERSION,
        timestamp: new Date().toISOString(),
        inputs: inputs,
        page: inputs.sidebar_page || 'power_single'
      };

      localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
      hasUnsavedWork = false;

      console.log('Session saved:', data.timestamp);
    } catch (e) {
      console.warn('Failed to save session data:', e);
    }
  }

  /**
   * Restore session data to inputs
   */
  function restoreSession(data) {
    if (!data || !data.inputs) return;

    console.log('Restoring session from:', data.timestamp);

    Object.keys(data.inputs).forEach(inputId => {
      const value = data.inputs[inputId];

      // Try to find the input element
      let input = document.getElementById(inputId);

      // If not found by ID, try by name (for radio buttons)
      if (!input) {
        input = document.querySelector(`[name="${inputId}"]`);
      }

      if (input && value !== null && value !== undefined) {
        if (input.type === 'number') {
          input.value = value;
          // Trigger Shiny input change
          if (window.Shiny) {
            Shiny.setInputValue(inputId, parseFloat(value));
          }
        } else if (input.type === 'radio') {
          // Find the radio button with matching value
          const radioBtn = document.querySelector(`input[name="${inputId}"][value="${value}"]`);
          if (radioBtn) {
            radioBtn.checked = true;
            if (window.Shiny) {
              Shiny.setInputValue(inputId, value);
            }
          }
        } else if (input.tagName === 'SELECT') {
          input.value = value;
          if (window.Shiny) {
            Shiny.setInputValue(inputId, value);
          }
        }
      }
    });

    // Show success message
    showNotification('Session restored from ' + formatTimestamp(data.timestamp), 'success');
  }

  /**
   * Show restore prompt
   */
  function showRestorePrompt() {
    sessionData = loadSessionData();

    if (!sessionData) return;

    // Check if data is recent (within last 7 days)
    const sessionAge = Date.now() - new Date(sessionData.timestamp).getTime();
    const maxAge = 7 * 24 * 60 * 60 * 1000; // 7 days

    if (sessionAge > maxAge) {
      console.log('Session data too old, ignoring');
      return;
    }

    // Create restore prompt
    const prompt = document.createElement('div');
    prompt.className = 'session-restore-prompt';
    prompt.innerHTML = `
      <div class="session-restore-content">
        <div class="session-restore-header">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M12 2a10 10 0 1 0 10 10H12V2z"/>
            <path d="M12 2v10l7.07 7.07"/>
          </svg>
          <h4>Resume Previous Session?</h4>
        </div>
        <p>You have unsaved work from ${formatTimestamp(sessionData.timestamp)}. Would you like to restore it?</p>
        <div class="session-restore-actions">
          <button id="restore-yes" class="btn btn-primary btn-sm">Restore</button>
          <button id="restore-no" class="btn btn-secondary btn-sm">Start Fresh</button>
        </div>
      </div>
    `;

    document.body.appendChild(prompt);

    // Show prompt after short delay
    setTimeout(() => {
      prompt.classList.add('active');
    }, 500);

    // Handle restore
    document.getElementById('restore-yes').addEventListener('click', function() {
      restoreSession(sessionData);
      prompt.classList.remove('active');
      setTimeout(() => prompt.remove(), 300);
    });

    // Handle dismiss
    document.getElementById('restore-no').addEventListener('click', function() {
      localStorage.removeItem(STORAGE_KEY);
      prompt.classList.remove('active');
      setTimeout(() => prompt.remove(), 300);
    });
  }

  /**
   * Format timestamp for display
   */
  function formatTimestamp(timestamp) {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now - date;

    // Less than 1 hour ago
    if (diff < 60 * 60 * 1000) {
      const minutes = Math.floor(diff / (60 * 1000));
      return `${minutes} minute${minutes !== 1 ? 's' : ''} ago`;
    }

    // Less than 24 hours ago
    if (diff < 24 * 60 * 60 * 1000) {
      const hours = Math.floor(diff / (60 * 60 * 1000));
      return `${hours} hour${hours !== 1 ? 's' : ''} ago`;
    }

    // Show date
    return date.toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit'
    });
  }

  /**
   * Show notification
   */
  function showNotification(message, type = 'info') {
    let notification = document.getElementById('session-notification');

    if (!notification) {
      notification = document.createElement('div');
      notification.id = 'session-notification';
      notification.className = 'session-notification';
      document.body.appendChild(notification);
    }

    notification.className = `session-notification ${type}`;
    notification.textContent = message;
    notification.classList.add('active');

    setTimeout(() => {
      notification.classList.remove('active');
    }, 3000);
  }

  /**
   * Track unsaved changes
   */
  function trackChanges() {
    // Mark as having unsaved work when inputs change
    document.addEventListener('input', function(e) {
      if (e.target.matches('input, select, textarea')) {
        hasUnsavedWork = true;

        // Debounce save
        clearTimeout(saveTimeout);
        saveTimeout = setTimeout(saveSessionData, SAVE_DELAY);
      }
    });

    // Save on Calculate button click
    const calculateBtn = document.getElementById('go');
    if (calculateBtn) {
      calculateBtn.addEventListener('click', function() {
        saveSessionData();
      });
    }

    // Warn before leaving if unsaved work
    window.addEventListener('beforeunload', function(e) {
      if (hasUnsavedWork) {
        const message = 'You have unsaved work. Are you sure you want to leave?';
        e.returnValue = message;
        return message;
      }
    });

    // Save periodically (every 30 seconds if changes exist)
    setInterval(function() {
      if (hasUnsavedWork) {
        saveSessionData();
      }
    }, 30000);
  }

  /**
   * Add CSS styles
   */
  function addStyles() {
    const style = document.createElement('style');
    style.textContent = `
      .session-restore-prompt {
        position: fixed;
        top: 80px;
        right: 20px;
        z-index: 10000;
        background: var(--bg-card);
        border: 1px solid var(--border-default);
        border-radius: var(--radius-lg);
        box-shadow: var(--shadow-xl);
        max-width: 400px;
        opacity: 0;
        transform: translateX(420px);
        transition: opacity 0.3s ease, transform 0.3s ease;
      }

      .session-restore-prompt.active {
        opacity: 1;
        transform: translateX(0);
      }

      .session-restore-content {
        padding: var(--space-4);
      }

      .session-restore-header {
        display: flex;
        align-items: center;
        gap: var(--space-2);
        margin-bottom: var(--space-2);
        color: var(--color-primary);
      }

      .session-restore-header h4 {
        margin: 0;
        font-size: var(--font-size-lg);
        font-weight: var(--font-weight-semibold);
        color: var(--text-primary);
      }

      .session-restore-content p {
        margin: var(--space-2) 0;
        color: var(--text-secondary);
        font-size: var(--font-size-sm);
      }

      .session-restore-actions {
        display: flex;
        gap: var(--space-2);
        margin-top: var(--space-4);
      }

      .session-notification {
        position: fixed;
        bottom: 20px;
        right: 20px;
        background: var(--bg-card);
        color: var(--text-primary);
        padding: 12px 20px;
        border-radius: var(--radius-lg);
        box-shadow: var(--shadow-lg);
        font-size: var(--font-size-sm);
        z-index: 9998;
        opacity: 0;
        transform: translateY(10px);
        transition: opacity 0.2s ease, transform 0.2s ease;
      }

      .session-notification.active {
        opacity: 1;
        transform: translateY(0);
      }

      .session-notification.success {
        background: var(--color-success);
        color: white;
      }

      .session-notification.error {
        background: var(--color-error);
        color: white;
      }

      @media (max-width: 768px) {
        .session-restore-prompt {
          left: 20px;
          right: 20px;
          max-width: none;
          transform: translateY(-100px);
        }

        .session-restore-prompt.active {
          transform: translateY(0);
        }
      }
    `;
    document.head.appendChild(style);
  }

  /**
   * Initialize session restore
   */
  function initSessionRestore() {
    addStyles();
    trackChanges();

    // Show restore prompt after a short delay
    setTimeout(showRestorePrompt, 1000);

    console.log('Session restore initialized');
  }

  // Initialize on DOMContentLoaded
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initSessionRestore);
  } else {
    initSessionRestore();
  }

  // Expose globally
  window.PowerAnalysisTool = window.PowerAnalysisTool || {};
  window.PowerAnalysisTool.saveSession = saveSessionData;
  window.PowerAnalysisTool.clearSession = function() {
    localStorage.removeItem(STORAGE_KEY);
    showNotification('Session cleared', 'success');
  };
})();
