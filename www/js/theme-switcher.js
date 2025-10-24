/**
 * Theme Switcher - Dark Mode Toggle
 * Statistical Power Analysis Tool
 *
 * Handles theme switching between light and dark modes with localStorage persistence
 */

(function() {
  'use strict';

  const STORAGE_KEY = 'theme-preference';
  const THEME_ATTRIBUTE = 'data-theme';

  /**
   * Get the current theme from localStorage or system preference
   * @returns {string} 'light' or 'dark'
   */
  function getPreferredTheme() {
    const stored = localStorage.getItem(STORAGE_KEY);

    if (stored) {
      return stored;
    }

    // Check system preference
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
      return 'dark';
    }

    return 'light';
  }

  /**
   * Set the theme on the document
   * @param {string} theme - 'light' or 'dark'
   */
  function setTheme(theme) {
    if (theme === 'dark') {
      document.documentElement.setAttribute(THEME_ATTRIBUTE, 'dark');
    } else {
      document.documentElement.removeAttribute(THEME_ATTRIBUTE);
    }

    // Save to localStorage
    localStorage.setItem(STORAGE_KEY, theme);

    // Update toggle button if it exists
    updateToggleButton(theme);

    // Dispatch custom event for other scripts
    window.dispatchEvent(new CustomEvent('themechange', { detail: { theme } }));
  }

  /**
   * Toggle between light and dark themes
   */
  function toggleTheme() {
    const current = document.documentElement.getAttribute(THEME_ATTRIBUTE);
    const newTheme = current === 'dark' ? 'light' : 'dark';
    setTheme(newTheme);
  }

  /**
   * Update the theme toggle button appearance
   * @param {string} theme - Current theme
   */
  function updateToggleButton(theme) {
    const button = document.getElementById('theme-toggle');
    if (!button) return;

    const icon = button.querySelector('.theme-toggle-icon');
    const text = button.querySelector('.theme-toggle-text');

    if (theme === 'dark') {
      if (icon) {
        icon.innerHTML = '<i class="fa fa-sun"></i>'; // Show sun icon in dark mode
      }
      if (text) {
        text.textContent = 'Light';
      }
      button.setAttribute('aria-label', 'Switch to light mode');
      button.setAttribute('title', 'Switch to light mode');
    } else {
      if (icon) {
        icon.innerHTML = '<i class="fa fa-moon"></i>'; // Show moon icon in light mode
      }
      if (text) {
        text.textContent = 'Dark';
      }
      button.setAttribute('aria-label', 'Switch to dark mode');
      button.setAttribute('title', 'Switch to dark mode');
    }
  }

  /**
   * Initialize theme on page load
   */
  function initTheme() {
    // Add no-transitions class to prevent animation on page load
    document.documentElement.classList.add('no-transitions');

    // Set initial theme
    const theme = getPreferredTheme();
    if (theme === 'dark') {
      document.documentElement.setAttribute(THEME_ATTRIBUTE, 'dark');
    }

    // Remove no-transitions class after a short delay
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        document.documentElement.classList.remove('no-transitions');
      });
    });

    // Update button
    updateToggleButton(theme);
  }

  /**
   * Setup event listeners
   */
  function setupListeners() {
    // Toggle button click
    const toggleButton = document.getElementById('theme-toggle');
    if (toggleButton) {
      toggleButton.addEventListener('click', toggleTheme);
    }

    // Keyboard shortcut: Ctrl+Shift+D (or Cmd+Shift+D on Mac)
    document.addEventListener('keydown', (e) => {
      if ((e.ctrlKey || e.metaKey) && e.shiftKey && e.key === 'D') {
        e.preventDefault();
        toggleTheme();
      }
    });

    // Listen for system theme changes
    if (window.matchMedia) {
      const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');

      // Modern browsers
      if (mediaQuery.addEventListener) {
        mediaQuery.addEventListener('change', (e) => {
          // Only auto-switch if user hasn't set a preference
          if (!localStorage.getItem(STORAGE_KEY)) {
            setTheme(e.matches ? 'dark' : 'light');
          }
        });
      }
      // Older browsers
      else if (mediaQuery.addListener) {
        mediaQuery.addListener((e) => {
          if (!localStorage.getItem(STORAGE_KEY)) {
            setTheme(e.matches ? 'dark' : 'light');
          }
        });
      }
    }
  }

  // Initialize immediately (before DOM ready for no-flash)
  initTheme();

  // Setup listeners when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', setupListeners);
  } else {
    setupListeners();
  }

  // Expose toggleTheme function globally for external use
  window.toggleTheme = toggleTheme;
  window.setTheme = setTheme;
  window.getPreferredTheme = getPreferredTheme;

})();
