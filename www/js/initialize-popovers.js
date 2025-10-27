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
      console.log('Trying fallback initialization...');

      // Try jQuery/Bootstrap 3 fallback
      if (typeof $ !== 'undefined' && typeof $.fn.popover !== 'undefined') {
        $('[data-bs-toggle="popover"]').popover({
          trigger: 'click focus',
          html: true,
          placement: 'right',
          container: 'body'
        });
        console.log('Initialized popovers with jQuery/Bootstrap 3');
        return;
      }

      console.error('No popover library available');
      return;
    }

    // Initialize all elements with data-bs-toggle="popover"
    const popoverTriggerList = document.querySelectorAll('[data-bs-toggle="popover"]');
    console.log(`Found ${popoverTriggerList.length} elements with popover data attribute`);

    if (popoverTriggerList.length === 0) {
      console.warn('No popover triggers found. Make sure help_content is provided to inputs.');
      // List all help icons for debugging
      const helpIcons = document.querySelectorAll('.contextual-help-icon');
      console.log(`Found ${helpIcons.length} help icon elements`);
      helpIcons.forEach((icon, i) => {
        console.log(`Help icon ${i}:`, icon.id, icon.getAttribute('data-bs-toggle'));
      });
    }

    const popoverList = [...popoverTriggerList].map(popoverTriggerEl => {
      return new bootstrap.Popover(popoverTriggerEl, {
        trigger: 'click focus',
        html: true,
        placement: 'right',
        container: 'body',
        customClass: 'contextual-help-popover'
      });
    });

    console.log(`Successfully initialized ${popoverList.length} popovers`);
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
        color: var(--color-primary) !important;
        opacity: 0.8;
        transition: opacity 0.2s ease, transform 0.2s ease;
        display: inline-block;
        vertical-align: middle;
        line-height: 1;
      }

      .contextual-help-icon:hover {
        opacity: 1 !important;
        transform: scale(1.15);
        color: var(--color-primary) !important;
      }

      .contextual-help-icon:focus {
        outline: 2px solid var(--color-primary);
        outline-offset: 2px;
        border-radius: var(--radius-sm);
        opacity: 1 !important;
      }

      .contextual-help-icon i {
        pointer-events: none;
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
