/**
 * Loading Spinner
 * Shows spinner overlay during calculations and async operations
 */

(function() {
  'use strict';

  let spinnerOverlay = null;
  let spinnerTimeout = null;

  /**
   * Create spinner overlay element
   */
  function createSpinnerOverlay() {
    const overlay = document.createElement('div');
    overlay.className = 'loading-overlay';
    overlay.id = 'loading-overlay';
    overlay.setAttribute('role', 'alert');
    overlay.setAttribute('aria-live', 'polite');
    overlay.setAttribute('aria-busy', 'true');

    overlay.innerHTML = `
      <div class="loading-spinner-container">
        <div class="loading-spinner" role="status"></div>
        <div class="loading-text">Calculating...</div>
        <div class="loading-subtext">Please wait while we process your request</div>
        <div class="loading-progress">
          <div class="loading-progress-bar"></div>
        </div>
      </div>
    `;

    document.body.appendChild(overlay);
    return overlay;
  }

  /**
   * Show loading spinner
   * @param {string} message - Optional message to display
   * @param {string} submessage - Optional submessage
   */
  function showSpinner(message = 'Calculating...', submessage = 'Please wait while we process your request') {
    if (!spinnerOverlay) {
      spinnerOverlay = createSpinnerOverlay();
    }

    // Update messages
    const textElement = spinnerOverlay.querySelector('.loading-text');
    const subtextElement = spinnerOverlay.querySelector('.loading-subtext');

    if (textElement) textElement.textContent = message;
    if (subtextElement) subtextElement.textContent = submessage;

    // Show overlay
    spinnerOverlay.classList.remove('success');
    spinnerOverlay.classList.add('active');

    // Disable scrolling
    document.body.style.overflow = 'hidden';

    // Animate progress bar (indeterminate)
    const progressBar = spinnerOverlay.querySelector('.loading-progress-bar');
    if (progressBar) {
      progressBar.style.width = '100%';
    }
  }

  /**
   * Hide loading spinner
   * @param {boolean} showSuccess - Show success animation before hiding
   */
  function hideSpinner(showSuccess = false) {
    if (!spinnerOverlay) return;

    if (showSuccess) {
      // Show success state briefly
      spinnerOverlay.classList.add('success');
      const textElement = spinnerOverlay.querySelector('.loading-text');
      if (textElement) textElement.textContent = 'Complete!';

      // Hide after animation
      setTimeout(() => {
        spinnerOverlay.classList.remove('active', 'success');
        document.body.style.overflow = '';
      }, 800);
    } else {
      // Hide immediately
      spinnerOverlay.classList.remove('active', 'success');
      document.body.style.overflow = '';
    }
  }

  /**
   * Update spinner progress
   * @param {number} percent - Progress percentage (0-100)
   */
  function updateProgress(percent) {
    if (!spinnerOverlay) return;

    const progressBar = spinnerOverlay.querySelector('.loading-progress-bar');
    if (progressBar) {
      progressBar.style.width = `${Math.min(100, Math.max(0, percent))}%`;
    }
  }

  /**
   * Initialize spinner handlers
   */
  function initSpinner() {
    // Track if Calculate button was recently clicked
    let calculateButtonClicked = false;
    
    // Show spinner when Calculate button is clicked (but don't block the event)
    const calculateBtn = document.getElementById('go');
    if (calculateBtn) {
      calculateBtn.addEventListener('click', function() {
        calculateButtonClicked = true;
        // Clear flag after 2 seconds
        setTimeout(() => { calculateButtonClicked = false; }, 2000);
      }, { capture: false, passive: true });
    }

    // Hide spinner when Shiny is idle (calculation complete)
    if (window.Shiny) {
      $(document).on('shiny:idle', function(event) {
        // Delay to ensure results are rendered
        setTimeout(() => {
          hideSpinner(true);
          calculateButtonClicked = false;
        }, 100);
      });

      // Show spinner on busy
      $(document).on('shiny:busy', function(event) {
        // Show spinner if Calculate button was clicked recently
        if (calculateButtonClicked) {
          showSpinner('Calculating...', 'Processing your analysis');
        }
      });

      // Handle errors
      $(document).on('shiny:error', function(event) {
        hideSpinner(false);
        calculateButtonClicked = false;
      });

      // Listen for custom spinner events from Shiny
      Shiny.addCustomMessageHandler('showSpinner', function(message) {
        showSpinner(message.text || 'Processing...', message.subtext || '');
      });

      Shiny.addCustomMessageHandler('hideSpinner', function(message) {
        hideSpinner(message.success || false);
      });

      Shiny.addCustomMessageHandler('updateProgress', function(message) {
        updateProgress(message.percent || 0);
      });
    }

    // Hide spinner on Escape key
    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape' && spinnerOverlay && spinnerOverlay.classList.contains('active')) {
        hideSpinner(false);
        calculateButtonClicked = false;
      }
    });
  }

  // Initialize on DOMContentLoaded
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initSpinner);
  } else {
    initSpinner();
  }

  // Expose globally
  window.PowerAnalysisTool = window.PowerAnalysisTool || {};
  window.PowerAnalysisTool.showSpinner = showSpinner;
  window.PowerAnalysisTool.hideSpinner = hideSpinner;
  window.PowerAnalysisTool.updateProgress = updateProgress;
})();
