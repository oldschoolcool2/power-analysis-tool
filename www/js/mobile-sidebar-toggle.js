/**
 * Mobile Sidebar Toggle
 * Provides collapsible sidebar for mobile devices
 */

(function() {
  'use strict';

  let sidebarToggleBtn = null;
  let sidebar = null;
  let overlay = null;

  /**
   * Create mobile toggle button
   */
  function createToggleButton() {
    const btn = document.createElement('button');
    btn.className = 'mobile-sidebar-toggle';
    btn.setAttribute('aria-label', 'Toggle sidebar navigation');
    btn.innerHTML = `
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <line x1="3" y1="6" x2="21" y2="6"/>
        <line x1="3" y1="12" x2="21" y2="12"/>
        <line x1="3" y1="18" x2="21" y2="18"/>
      </svg>
      <span class="sr-only">Menu</span>
    `;

    document.body.appendChild(btn);
    return btn;
  }

  /**
   * Create overlay for mobile sidebar
   */
  function createOverlay() {
    const overlay = document.createElement('div');
    overlay.className = 'mobile-sidebar-overlay';
    document.body.appendChild(overlay);
    return overlay;
  }

  /**
   * Toggle sidebar
   */
  function toggleSidebar() {
    if (!sidebar) return;

    const isOpen = sidebar.classList.contains('mobile-open');

    if (isOpen) {
      closeSidebar();
    } else {
      openSidebar();
    }
  }

  /**
   * Open sidebar
   */
  function openSidebar() {
    if (!sidebar || !overlay) return;

    sidebar.classList.add('mobile-open');
    overlay.classList.add('active');
    document.body.classList.add('sidebar-open');

    // Update button icon to X
    if (sidebarToggleBtn) {
      sidebarToggleBtn.innerHTML = `
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <line x1="18" y1="6" x2="6" y2="18"/>
          <line x1="6" y1="6" x2="18" y2="18"/>
        </svg>
        <span class="sr-only">Close menu</span>
      `;
    }

    // Trap focus in sidebar
    trapFocus(sidebar);
  }

  /**
   * Close sidebar
   */
  function closeSidebar() {
    if (!sidebar || !overlay) return;

    sidebar.classList.remove('mobile-open');
    overlay.classList.remove('active');
    document.body.classList.remove('sidebar-open');

    // Update button icon to hamburger
    if (sidebarToggleBtn) {
      sidebarToggleBtn.innerHTML = `
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <line x1="3" y1="6" x2="21" y2="6"/>
          <line x1="3" y1="12" x2="21" y2="12"/>
          <line x1="3" y1="18" x2="21" y2="18"/>
        </svg>
        <span class="sr-only">Menu</span>
      `;
    }

    // Release focus trap
    releaseFocus();
  }

  /**
   * Trap focus within sidebar
   */
  function trapFocus(element) {
    const focusableElements = element.querySelectorAll(
      'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
    );

    const firstFocusable = focusableElements[0];
    const lastFocusable = focusableElements[focusableElements.length - 1];

    element.addEventListener('keydown', handleFocusTrap);

    function handleFocusTrap(e) {
      if (e.key === 'Tab') {
        if (e.shiftKey) {
          if (document.activeElement === firstFocusable) {
            e.preventDefault();
            lastFocusable.focus();
          }
        } else {
          if (document.activeElement === lastFocusable) {
            e.preventDefault();
            firstFocusable.focus();
          }
        }
      }
    }
  }

  /**
   * Release focus trap
   */
  function releaseFocus() {
    if (sidebar) {
      sidebar.removeEventListener('keydown', handleFocusTrap);
    }
  }

  /**
   * Handle sidebar item click on mobile
   */
  function handleSidebarItemClick() {
    // Close sidebar when navigation item is clicked on mobile
    if (window.innerWidth <= 768) {
      closeSidebar();
    }
  }

  /**
   * Initialize mobile sidebar
   */
  function initMobileSidebar() {
    // Find sidebar
    sidebar = document.querySelector('.sidebar-nav');
    if (!sidebar) {
      console.warn('Sidebar not found');
      return;
    }

    // Create toggle button and overlay
    sidebarToggleBtn = createToggleButton();
    overlay = createOverlay();

    // Add event listeners
    sidebarToggleBtn.addEventListener('click', toggleSidebar);
    overlay.addEventListener('click', closeSidebar);

    // Close on Escape
    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape' && sidebar.classList.contains('mobile-open')) {
        closeSidebar();
      }
    });

    // Close sidebar when navigation item clicked
    const navItems = sidebar.querySelectorAll('a, button, input[type="radio"]');
    navItems.forEach(item => {
      item.addEventListener('click', handleSidebarItemClick);
    });

    // Handle window resize
    let resizeTimer;
    window.addEventListener('resize', function() {
      clearTimeout(resizeTimer);
      resizeTimer = setTimeout(function() {
        // Close sidebar if window is resized to desktop
        if (window.innerWidth > 768 && sidebar.classList.contains('mobile-open')) {
          closeSidebar();
        }
      }, 250);
    });

    // Add CSS
    const style = document.createElement('style');
    style.textContent = `
      /* Mobile sidebar toggle button */
      .mobile-sidebar-toggle {
        display: none;
        position: fixed;
        top: 16px;
        left: 16px;
        z-index: 1001;
        background: var(--bg-card);
        border: 1px solid var(--border-default);
        border-radius: var(--radius-md);
        padding: 10px;
        cursor: pointer;
        box-shadow: var(--shadow-md);
        transition: all 0.2s ease;
        color: var(--text-primary);
      }

      .mobile-sidebar-toggle:hover {
        background: var(--bg-hover);
        box-shadow: var(--shadow-lg);
      }

      .mobile-sidebar-toggle:active {
        transform: scale(0.95);
      }

      .mobile-sidebar-toggle svg {
        display: block;
      }

      /* Mobile sidebar overlay */
      .mobile-sidebar-overlay {
        display: none;
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.5);
        z-index: 999;
        opacity: 0;
        transition: opacity 0.3s ease;
        pointer-events: none;
      }

      .mobile-sidebar-overlay.active {
        opacity: 1;
        pointer-events: auto;
      }

      /* Mobile styles */
      @media (max-width: 768px) {
        .mobile-sidebar-toggle {
          display: block;
        }

        .mobile-sidebar-overlay {
          display: block;
        }

        /* Hide sidebar by default on mobile */
        .sidebar-nav {
          position: fixed;
          top: 0;
          left: 0;
          bottom: 0;
          transform: translateX(-100%);
          transition: transform 0.3s ease;
          z-index: 1000;
          width: 280px;
          max-width: 85vw;
          overflow-y: auto;
          box-shadow: var(--shadow-xl);
        }

        .sidebar-nav.mobile-open {
          transform: translateX(0);
        }

        /* Prevent body scroll when sidebar is open */
        body.sidebar-open {
          overflow: hidden;
        }

        /* Adjust main content for mobile */
        .main-content-wrapper {
          margin-left: 0;
          width: 100%;
        }

        /* Add padding to top of main content for toggle button */
        .app-container {
          padding-top: 60px;
        }

        /* Touch-friendly sidebar items */
        .sidebar-nav a,
        .sidebar-nav button,
        .sidebar-nav input[type="radio"] + label {
          min-height: 44px;
          display: flex;
          align-items: center;
        }
      }

      /* Swipe gesture support (optional enhancement) */
      @media (max-width: 768px) and (hover: none) and (pointer: coarse) {
        .sidebar-nav {
          touch-action: pan-y;
        }
      }
    `;
    document.head.appendChild(style);

    console.log('Mobile sidebar toggle initialized');
  }

  // Initialize on DOMContentLoaded
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initMobileSidebar);
  } else {
    initMobileSidebar();
  }

  // Expose globally
  window.PowerAnalysisTool = window.PowerAnalysisTool || {};
  window.PowerAnalysisTool.toggleSidebar = toggleSidebar;
  window.PowerAnalysisTool.openSidebar = openSidebar;
  window.PowerAnalysisTool.closeSidebar = closeSidebar;
})();
