/**
 * Bootstrap 5 Compatibility Fix for shinyBS
 * 
 * The shinyBS package was built for Bootstrap 3/4 and uses the old .tooltip('destroy') API.
 * Bootstrap 5 changed this to .tooltip('dispose'). This script patches the jQuery.fn.tooltip
 * method to support both APIs for backward compatibility.
 */

(function() {
  'use strict';
  
  // Function to apply the fix
  function applyBootstrap5Fix() {
    // Check if jQuery is loaded
    if (typeof jQuery === 'undefined') {
      console.warn('Bootstrap 5 shinyBS fix: jQuery not loaded yet, will retry...');
      return false;
    }
    
    // Check if tooltip method exists
    if (typeof jQuery.fn.tooltip === 'undefined') {
      console.warn('Bootstrap 5 shinyBS fix: Bootstrap tooltip not loaded yet, will retry...');
      return false;
    }
    
    // Store the original Bootstrap tooltip method
    var originalTooltip = jQuery.fn.tooltip;
    
    // Override jQuery.fn.tooltip to handle 'destroy' -> 'dispose' mapping
    jQuery.fn.tooltip = function(config) {
      // If the first argument is 'destroy', replace it with 'dispose'
      if (config === 'destroy') {
        config = 'dispose';
      }
      
      // Call the original tooltip method with potentially modified config
      return originalTooltip.call(this, config);
    };
    
    // Preserve all properties from the original method if they exist
    if (originalTooltip.Constructor) {
      jQuery.fn.tooltip.Constructor = originalTooltip.Constructor;
    }
    if (originalTooltip.noConflict) {
      jQuery.fn.tooltip.noConflict = originalTooltip.noConflict;
    }
    
    console.log('Bootstrap 5 shinyBS compatibility fix applied successfully');
    return true;
  }
  
  // Try to apply fix when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      // Retry a few times to ensure Bootstrap is loaded
      var retries = 0;
      var interval = setInterval(function() {
        if (applyBootstrap5Fix() || retries++ > 10) {
          clearInterval(interval);
        }
      }, 100);
    });
  } else {
    // DOM already loaded, try immediately
    var retries = 0;
    var interval = setInterval(function() {
      if (applyBootstrap5Fix() || retries++ > 10) {
        clearInterval(interval);
      }
    }, 100);
  }
})();

