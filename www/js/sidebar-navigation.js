/**
 * Sidebar Navigation JavaScript
 * Statistical Power Analysis Tool
 *
 * Handles:
 * - Collapsible menu groups
 * - Active state management
 * - Mobile sidebar toggle
 * - Content switching via Shiny
 */

$(document).ready(function() {

  // ==========================================================================
  // Navigation Group Toggle (Collapsible Sections)
  // ==========================================================================

  $('.nav-group-header').on('click', function(e) {
    e.preventDefault();
    e.stopPropagation();

    const $header = $(this);
    const $children = $header.next('.nav-group-children');
    const $chevron = $header.find('.nav-group-chevron');

    // Toggle expanded state
    const isExpanded = $header.hasClass('expanded');

    if (isExpanded) {
      // Collapse
      $header.removeClass('expanded');
      $children.removeClass('expanded');
    } else {
      // Expand
      $header.addClass('expanded');
      $children.addClass('expanded');
    }

    // Update aria-expanded for accessibility
    $header.attr('aria-expanded', !isExpanded);
  });

  // ==========================================================================
  // Navigation Item Click (Content Switching)
  // ==========================================================================

  $('.nav-item, .nav-item-single').on('click', function(e) {
    e.preventDefault();

    const $item = $(this);
    const pageId = $item.data('page');

    // Remove active class from all items
    $('.nav-item, .nav-item-single').removeClass('active');
    $('.nav-group-header').removeClass('active');

    // Add active class to clicked item
    $item.addClass('active');

    // Add active class to parent group if child item
    if ($item.hasClass('nav-item')) {
      $item.closest('.nav-group').find('.nav-group-header').addClass('active');
    }

    // Notify Shiny to switch content
    if (typeof Shiny !== 'undefined') {
      Shiny.setInputValue('sidebar_page', pageId, {priority: 'event'});
    }

    // Close mobile sidebar after selection
    if (window.innerWidth < 1024) {
      closeSidebar();
    }
  });

  // ==========================================================================
  // Mobile Sidebar Toggle
  // ==========================================================================

  // Create toggle button if it doesn't exist
  if ($('.sidebar-toggle').length === 0) {
    $('<button>', {
      class: 'sidebar-toggle',
      'aria-label': 'Toggle navigation',
      html: '<i class="fa fa-bars"></i>'
    }).prependTo('body');
  }

  // Create overlay if it doesn't exist
  if ($('.sidebar-overlay').length === 0) {
    $('<div>', {
      class: 'sidebar-overlay'
    }).prependTo('body');
  }

  // Toggle button click
  $('.sidebar-toggle').on('click', function() {
    toggleSidebar();
  });

  // Overlay click (close sidebar)
  $('.sidebar-overlay').on('click', function() {
    closeSidebar();
  });

  // Close sidebar on ESC key
  $(document).on('keydown', function(e) {
    if (e.key === 'Escape' && $('.sidebar').hasClass('open')) {
      closeSidebar();
    }
  });

  function toggleSidebar() {
    $('.sidebar').toggleClass('open');
    $('.sidebar-overlay').toggleClass('active');
    $('body').toggleClass('sidebar-open');
  }

  function closeSidebar() {
    $('.sidebar').removeClass('open');
    $('.sidebar-overlay').removeClass('active');
    $('body').removeClass('sidebar-open');
  }

  // ==========================================================================
  // Auto-Expand Active Group on Page Load
  // ==========================================================================

  function expandActiveGroup() {
    const $activeItem = $('.nav-item.active, .nav-item-single.active');

    if ($activeItem.length > 0) {
      const $parentGroup = $activeItem.closest('.nav-group');

      if ($parentGroup.length > 0) {
        const $header = $parentGroup.find('.nav-group-header');
        const $children = $parentGroup.find('.nav-group-children');

        $header.addClass('expanded active');
        $children.addClass('expanded');
        $header.attr('aria-expanded', 'true');
      }
    }
  }

  // Expand active group on initial load
  expandActiveGroup();

  // ==========================================================================
  // Set Initial Active Page Based on Shiny Input
  // ==========================================================================

  if (typeof Shiny !== 'undefined') {
    // Listen for initial page value from Shiny
    Shiny.addCustomMessageHandler('set_active_page', function(pageId) {
      const $item = $(`.nav-item[data-page="${pageId}"], .nav-item-single[data-page="${pageId}"]`);

      if ($item.length > 0) {
        $('.nav-item, .nav-item-single').removeClass('active');
        $('.nav-group-header').removeClass('active');
        $item.addClass('active');

        // Activate parent group if child item
        if ($item.hasClass('nav-item')) {
          $item.closest('.nav-group').find('.nav-group-header').addClass('active');
        }

        expandActiveGroup();
      }
    });
  }

  // ==========================================================================
  // Keyboard Navigation Support
  // ==========================================================================

  $('.nav-group-header, .nav-item, .nav-item-single').attr('tabindex', '0');

  $('.nav-group-header, .nav-item, .nav-item-single').on('keydown', function(e) {
    // Enter or Space key
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      $(this).click();
    }
  });

  // ==========================================================================
  // Responsive Handling
  // ==========================================================================

  let resizeTimer;
  $(window).on('resize', function() {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(function() {
      // Close sidebar on desktop view
      if (window.innerWidth >= 1024) {
        closeSidebar();
      }
    }, 250);
  });

  // ==========================================================================
  // Utility: Smooth Scroll to Top on Page Change
  // ==========================================================================

  $('.nav-item, .nav-item-single').on('click', function() {
    $('.main-content').animate({ scrollTop: 0 }, 300);
  });

});
