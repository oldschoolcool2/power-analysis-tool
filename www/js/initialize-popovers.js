/**
 * Initialize Bootstrap Popovers
 * Required for contextual help icons
 */

(function() {
  'use strict';

  /**
   * Initialize all popovers on the page
   */
  function initializePopovers() {
    // Check if Bootstrap is available
    if (typeof bootstrap === 'undefined') {
      console.warn('Bootstrap not loaded, popovers will not work');
      return;
    }

    // Initialize all elements with data-bs-toggle="popover"
    const popoverTriggerList = document.querySelectorAll('[data-bs-toggle="popover"]');
    const popoverList = [...popoverTriggerList].map(popoverTriggerEl => {
      return new bootstrap.Popover(popoverTriggerEl, {
        trigger: 'focus',
        html: true,
        placement: 'right',
        container: 'body',
        customClass: 'contextual-help-popover'
      });
    });

    console.log(`Initialized ${popoverList.length} popovers`);
  }

  /**
   * Add CSS for popovers
   */
  function addPopoverStyles() {
    const style = document.createElement('style');
    style.textContent = `
      /* Contextual help popover styling */
      .contextual-help-popover {
        max-width: 350px;
        font-size: var(--font-size-sm);
      }

      .contextual-help-popover .popover-header {
        background: var(--color-primary);
        color: white;
        font-weight: var(--font-weight-semibold);
        border-bottom: none;
        padding: var(--space-2) var(--space-3);
      }

      .contextual-help-popover .popover-body {
        padding: var(--space-3);
        color: var(--text-primary);
        line-height: 1.5;
      }

      .contextual-help-popover .popover-body strong {
        color: var(--text-primary);
        display: block;
        margin-top: var(--space-2);
        margin-bottom: var(--space-1);
      }

      .contextual-help-popover .popover-body em {
        color: var(--text-secondary);
        font-style: normal;
        font-size: var(--font-size-xs);
      }

      .contextual-help-popover .popover-body code {
        background: var(--bg-secondary);
        padding: 2px 6px;
        border-radius: var(--radius-sm);
        font-family: var(--font-mono, monospace);
        font-size: var(--font-size-xs);
      }

      .contextual-help-popover .popover-body ul {
        margin: var(--space-2) 0;
        padding-left: var(--space-4);
      }

      .contextual-help-popover .popover-body li {
        margin-bottom: var(--space-1);
      }

      /* Dark mode support */
      [data-theme='dark'] .contextual-help-popover {
        background: var(--bg-card);
        border-color: var(--border-default);
      }

      [data-theme='dark'] .contextual-help-popover .popover-body {
        background: var(--bg-card);
        color: var(--text-primary);
      }

      [data-theme='dark'] .contextual-help-popover .popover-arrow::after {
        border-right-color: var(--bg-card);
      }

      /* Help icon styling */
      .contextual-help-icon {
        color: var(--color-primary);
        opacity: 0.7;
        transition: opacity 0.2s ease, transform 0.2s ease;
      }

      .contextual-help-icon:hover {
        opacity: 1;
        transform: scale(1.1);
      }

      .contextual-help-icon:focus {
        outline: 2px solid var(--color-primary);
        outline-offset: 2px;
        border-radius: var(--radius-sm);
      }

      /* Mobile adjustments */
      @media (max-width: 768px) {
        .contextual-help-popover {
          max-width: 280px;
        }

        .contextual-help-popover .popover-body {
          font-size: var(--font-size-xs);
        }
      }
    `;
    document.head.appendChild(style);
  }

  /**
   * Initialize on DOM ready
   */
  function init() {
    addPopoverStyles();
    initializePopovers();
  }

  // Initialize on DOMContentLoaded
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  // Re-initialize when Shiny updates content
  if (window.Shiny) {
    $(document).on('shiny:value', function() {
      setTimeout(initializePopovers, 100);
    });
  }

  // Expose globally
  window.PowerAnalysisTool = window.PowerAnalysisTool || {};
  window.PowerAnalysisTool.initializePopovers = initializePopovers;
})();
