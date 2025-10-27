/**
 * Keyboard Shortcuts
 * Provides keyboard navigation and shortcuts for the application
 */

(function() {
  'use strict';

  // Shortcut definitions
  const shortcuts = [
    {
      key: 'Enter',
      ctrl: true,
      description: 'Calculate',
      action: () => {
        const calculateBtn = document.getElementById('go');
        if (calculateBtn && !calculateBtn.disabled) {
          calculateBtn.click();
        }
      }
    },
    {
      key: 'r',
      ctrl: true,
      description: 'Reset current page',
      action: () => {
        // Find the active reset button based on current page
        const activePage = getActivePage();
        const resetBtn = findResetButton(activePage);
        if (resetBtn) {
          resetBtn.click();
        }
      }
    },
    {
      key: 'e',
      ctrl: true,
      description: 'Load example',
      action: () => {
        // Find the active example button
        const activePage = getActivePage();
        const exampleBtn = findExampleButton(activePage);
        if (exampleBtn) {
          exampleBtn.click();
        }
      }
    },
    {
      key: 'h',
      ctrl: true,
      shift: true,
      description: 'Show help',
      action: () => {
        const helpBtn = document.querySelector('[data-target="#help_modal"]');
        if (helpBtn) {
          helpBtn.click();
        }
      }
    },
    {
      key: '/',
      ctrl: false,
      description: 'Focus sidebar search',
      action: () => {
        // Focus first input in sidebar
        const firstInput = document.querySelector('.sidebar-nav input, .sidebar-nav select');
        if (firstInput) {
          firstInput.focus();
        }
      }
    },
    {
      key: 'Escape',
      ctrl: false,
      description: 'Close modals',
      action: () => {
        // Close any open modals
        const closeButtons = document.querySelectorAll('.modal.in .close, .modal.show .close');
        closeButtons.forEach(btn => btn.click());
      }
    }
  ];

  /**
   * Get currently active page
   */
  function getActivePage() {
    // Check which page is visible based on conditionalPanel
    const sidebarInput = document.querySelector('input[name="sidebar_page"]');
    if (sidebarInput) {
      return sidebarInput.value;
    }

    // Fallback: check visible h2 page title
    const visibleTitle = document.querySelector('.page-title:not([style*="display: none"])');
    if (visibleTitle) {
      const text = visibleTitle.textContent.toLowerCase();
      if (text.includes('single proportion')) return 'power_single';
      if (text.includes('two-group')) return 'power_twogrp';
      if (text.includes('survival')) return 'power_survival';
      if (text.includes('matched')) return 'match_casecontrol';
      if (text.includes('continuous')) return 'power_continuous';
      if (text.includes('non-inferiority')) return 'noninf';
      if (text.includes('vif')) return 'vif_calculator';
    }

    return null;
  }

  /**
   * Find reset button for current page
   */
  function findResetButton(page) {
    // Look for visible reset button
    const resetButtons = document.querySelectorAll('button[id*="reset"]:not([style*="display: none"])');
    for (const btn of resetButtons) {
      // Check if button is actually visible
      if (btn.offsetParent !== null) {
        return btn;
      }
    }
    return null;
  }

  /**
   * Find example button for current page
   */
  function findExampleButton(page) {
    // Look for visible example button
    const exampleButtons = document.querySelectorAll('button[id*="example"]:not([style*="display: none"])');
    for (const btn of exampleButtons) {
      // Check if button is actually visible
      if (btn.offsetParent !== null) {
        return btn;
      }
    }
    return null;
  }

  /**
   * Handle keyboard shortcuts
   */
  function handleKeyboardShortcut(event) {
    // Don't trigger shortcuts when typing in inputs (except Escape)
    if (event.key !== 'Escape' &&
        (event.target.tagName === 'INPUT' ||
         event.target.tagName === 'TEXTAREA' ||
         event.target.tagName === 'SELECT')) {
      return;
    }

    for (const shortcut of shortcuts) {
      const ctrlMatch = shortcut.ctrl ? event.ctrlKey || event.metaKey : !event.ctrlKey && !event.metaKey;
      const shiftMatch = shortcut.shift ? event.shiftKey : !event.shiftKey;
      const keyMatch = event.key.toLowerCase() === shortcut.key.toLowerCase();

      if (ctrlMatch && shiftMatch && keyMatch) {
        event.preventDefault();
        event.stopPropagation();
        shortcut.action();

        // Show brief feedback
        showShortcutFeedback(shortcut.description);
        break;
      }
    }
  }

  /**
   * Show brief feedback when shortcut is used
   */
  function showShortcutFeedback(description) {
    // Create or get feedback element
    let feedback = document.getElementById('keyboard-shortcut-feedback');

    if (!feedback) {
      feedback = document.createElement('div');
      feedback.id = 'keyboard-shortcut-feedback';
      feedback.className = 'keyboard-shortcut-feedback';
      document.body.appendChild(feedback);
    }

    // Update and show
    feedback.textContent = description;
    feedback.classList.add('active');

    // Hide after delay
    setTimeout(() => {
      feedback.classList.remove('active');
    }, 1500);
  }

  /**
   * Create keyboard shortcuts help modal content
   */
  function createShortcutsHelp() {
    const helpContainer = document.createElement('div');
    helpContainer.className = 'keyboard-shortcuts-help';
    helpContainer.style.display = 'none';

    let html = '<h4>Keyboard Shortcuts</h4><table class="table table-sm"><tbody>';

    shortcuts.forEach(shortcut => {
      const keys = [];
      if (shortcut.ctrl) keys.push('Ctrl');
      if (shortcut.shift) keys.push('Shift');
      keys.push(shortcut.key === ' ' ? 'Space' : shortcut.key.toUpperCase());

      const keyCombo = keys.join(' + ');
      html += `<tr><td><kbd>${keyCombo}</kbd></td><td>${shortcut.description}</td></tr>`;
    });

    html += '</tbody></table>';
    html += '<p class="text-muted small">Press <kbd>?</kbd> to toggle this help</p>';

    helpContainer.innerHTML = html;
    document.body.appendChild(helpContainer);

    return helpContainer;
  }

  /**
   * Toggle shortcuts help
   */
  function toggleShortcutsHelp() {
    let helpContainer = document.querySelector('.keyboard-shortcuts-help');

    if (!helpContainer) {
      helpContainer = createShortcutsHelp();
    }

    if (helpContainer.style.display === 'none') {
      helpContainer.style.display = 'block';
      helpContainer.style.position = 'fixed';
      helpContainer.style.top = '50%';
      helpContainer.style.left = '50%';
      helpContainer.style.transform = 'translate(-50%, -50%)';
      helpContainer.style.background = 'var(--bg-card)';
      helpContainer.style.padding = 'var(--space-6)';
      helpContainer.style.borderRadius = 'var(--radius-lg)';
      helpContainer.style.boxShadow = 'var(--shadow-xl)';
      helpContainer.style.zIndex = '10000';
      helpContainer.style.maxWidth = '500px';
    } else {
      helpContainer.style.display = 'none';
    }
  }

  /**
   * Initialize keyboard shortcuts
   */
  function initKeyboardShortcuts() {
    // Add global keyboard listener
    document.addEventListener('keydown', handleKeyboardShortcut);

    // Add '?' key to show shortcuts help
    document.addEventListener('keydown', function(e) {
      if (e.key === '?' && !e.ctrlKey && !e.metaKey) {
        if (e.target.tagName !== 'INPUT' && e.target.tagName !== 'TEXTAREA') {
          e.preventDefault();
          toggleShortcutsHelp();
        }
      }
    });

    // Add CSS for feedback
    const style = document.createElement('style');
    style.textContent = `
      .keyboard-shortcut-feedback {
        position: fixed;
        bottom: 20px;
        right: 20px;
        background: var(--bg-card);
        color: var(--text-primary);
        padding: 12px 20px;
        border-radius: var(--radius-lg);
        box-shadow: var(--shadow-lg);
        font-size: var(--font-size-sm);
        font-weight: var(--font-weight-medium);
        z-index: 9998;
        opacity: 0;
        transform: translateY(10px);
        transition: opacity 0.2s ease, transform 0.2s ease;
        pointer-events: none;
      }

      .keyboard-shortcut-feedback.active {
        opacity: 1;
        transform: translateY(0);
      }

      .keyboard-shortcuts-help kbd {
        background: var(--bg-secondary);
        color: var(--text-primary);
        padding: 2px 6px;
        border-radius: var(--radius-sm);
        font-family: var(--font-mono, monospace);
        font-size: var(--font-size-sm);
        border: 1px solid var(--border-default);
      }

      .keyboard-shortcuts-help table {
        margin-top: var(--space-4);
      }

      .keyboard-shortcuts-help td:first-child {
        width: 140px;
        font-weight: var(--font-weight-medium);
      }

      @media (max-width: 768px) {
        .keyboard-shortcut-feedback {
          bottom: 10px;
          right: 10px;
          left: 10px;
          text-align: center;
        }

        .keyboard-shortcuts-help {
          max-width: 90% !important;
          max-height: 80vh;
          overflow-y: auto;
        }
      }
    `;
    document.head.appendChild(style);

    console.log('Keyboard shortcuts initialized. Press ? to see all shortcuts.');
  }

  // Initialize on DOMContentLoaded
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initKeyboardShortcuts);
  } else {
    initKeyboardShortcuts();
  }

  // Expose globally
  window.PowerAnalysisTool = window.PowerAnalysisTool || {};
  window.PowerAnalysisTool.shortcuts = shortcuts;
  window.PowerAnalysisTool.showShortcutsHelp = toggleShortcutsHelp;
})();
