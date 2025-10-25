/**
 * Copy-to-Clipboard Functionality
 * Statistical Power Analysis Tool
 *
 * Provides copy-to-clipboard functionality for results text with visual feedback
 */

(function() {
  'use strict';

  /**
   * Copy text to clipboard with fallback for older browsers
   * @param {string} text - Text to copy
   * @returns {Promise<boolean>} - Success status
   */
  async function copyToClipboard(text) {
    // Modern async clipboard API
    if (navigator.clipboard && navigator.clipboard.writeText) {
      try {
        await navigator.clipboard.writeText(text);
        return true;
      } catch (err) {
        console.error('Failed to copy using async clipboard API:', err);
        return fallbackCopy(text);
      }
    }

    // Fallback for older browsers
    return fallbackCopy(text);
  }

  /**
   * Fallback copy method using temporary textarea
   * @param {string} text - Text to copy
   * @returns {boolean} - Success status
   */
  function fallbackCopy(text) {
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    textarea.style.pointerEvents = 'none';

    document.body.appendChild(textarea);
    textarea.select();

    let success = false;
    try {
      success = document.execCommand('copy');
    } catch (err) {
      console.error('Fallback copy failed:', err);
    }

    document.body.removeChild(textarea);
    return success;
  }

  /**
   * Extract plain text from HTML element
   * @param {HTMLElement} element - Element to extract text from
   * @returns {string} - Plain text content
   */
  function extractPlainText(element) {
    const clone = element.cloneNode(true);

    // Remove certain elements that shouldn't be copied
    const elementsToRemove = clone.querySelectorAll('.copy-button, script, style');
    elementsToRemove.forEach(el => el.remove());

    // Get text content and clean up whitespace
    let text = clone.textContent || clone.innerText || '';
    text = text
      .replace(/\n\s*\n\s*\n/g, '\n\n')  // Multiple newlines to double newline
      .replace(/[ \t]+/g, ' ')            // Multiple spaces to single space
      .trim();

    return text;
  }

  /**
   * Show visual feedback on button
   * @param {HTMLElement} button - Button element
   * @param {boolean} success - Whether copy was successful
   */
  function showFeedback(button, success) {
    const icon = button.querySelector('.fa, .svg-inline--fa');
    const text = button.querySelector('.copy-button-text');

    if (success) {
      // Success feedback
      button.classList.add('copied');
      if (icon) icon.className = 'fa fa-check';
      if (text) text.textContent = 'Copied!';

      // Reset after 2 seconds
      setTimeout(() => {
        button.classList.remove('copied');
        if (icon) icon.className = 'fa fa-copy';
        if (text) text.textContent = 'Copy to Clipboard';
      }, 2000);
    } else {
      // Error feedback
      button.classList.add('copy-error');
      if (icon) icon.className = 'fa fa-times';
      if (text) text.textContent = 'Failed to copy';

      // Reset after 2 seconds
      setTimeout(() => {
        button.classList.remove('copy-error');
        if (icon) icon.className = 'fa fa-copy';
        if (text) text.textContent = 'Copy to Clipboard';
      }, 2000);
    }
  }

  /**
   * Initialize copy button event listener
   * @param {HTMLElement} button - Button element
   */
  function initCopyButton(button) {
    const targetId = button.getAttribute('data-copy-target');

    button.addEventListener('click', async function(e) {
      e.preventDefault();

      const targetElement = document.getElementById(targetId);
      if (!targetElement) {
        console.error('Copy target not found:', targetId);
        showFeedback(button, false);
        return;
      }

      // Extract text
      const text = extractPlainText(targetElement);

      // Copy to clipboard
      const success = await copyToClipboard(text);

      // Show feedback
      showFeedback(button, success);

      // Optional: Send notification to Shiny
      if (window.Shiny && window.Shiny.setInputValue) {
        Shiny.setInputValue('text_copied', {
          success: success,
          target: targetId,
          timestamp: new Date().getTime()
        }, {priority: 'event'});
      }
    });
  }

  /**
   * Create and insert a copy button before an element
   * @param {HTMLElement} targetElement - Element to copy content from
   * @param {string} buttonText - Button label (default: "Copy to Clipboard")
   */
  function createCopyButton(targetElement, buttonText = 'Copy to Clipboard') {
    const targetId = targetElement.id || 'copy-target-' + Math.random().toString(36).substr(2, 9);
    targetElement.id = targetId;

    const button = document.createElement('button');
    button.className = 'copy-button btn btn-sm btn-outline-secondary';
    button.setAttribute('data-copy-target', targetId);
    button.type = 'button';

    button.innerHTML = `
      <i class="fa fa-copy"></i>
      <span class="copy-button-text">${buttonText}</span>
    `;

    // Insert button before target element
    targetElement.parentNode.insertBefore(button, targetElement);

    // Initialize
    initCopyButton(button);

    return button;
  }

  /**
   * Auto-initialize copy buttons on page load
   */
  function autoInit() {
    // Initialize all existing copy buttons
    document.querySelectorAll('.copy-button').forEach(button => {
      if (!button.hasAttribute('data-initialized')) {
        initCopyButton(button);
        button.setAttribute('data-initialized', 'true');
      }
    });

    // Auto-create copy buttons for elements with data-copyable attribute
    document.querySelectorAll('[data-copyable="true"]').forEach(element => {
      if (!element.previousElementSibling || !element.previousElementSibling.classList.contains('copy-button')) {
        createCopyButton(element);
      }
    });
  }

  // Initialize on DOMContentLoaded
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', autoInit);
  } else {
    autoInit();
  }

  // Re-initialize when Shiny updates content
  if (window.Shiny) {
    Shiny.addCustomMessageHandler('reinit-copy-buttons', autoInit);

    // Also initialize after any Shiny output update
    $(document).on('shiny:value', function(event) {
      setTimeout(autoInit, 100);
    });
  }

  // Expose utility functions globally
  window.PowerAnalysisTool = window.PowerAnalysisTool || {};
  window.PowerAnalysisTool.copyToClipboard = copyToClipboard;
  window.PowerAnalysisTool.createCopyButton = createCopyButton;
  window.PowerAnalysisTool.initCopyButtons = autoInit;
})();
