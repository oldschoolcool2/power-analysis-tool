/**
 * Real-time Input Validation
 * Statistical Power Analysis Tool
 *
 * Provides real-time validation with inline error messages and smart suggestions
 */

(function() {
  'use strict';

  // Validation rules for different input types
  const validationRules = {
    sample_size: {
      min: 2,
      max: 1000000,
      message: (value, min, max) => {
        if (value < min) return `Sample size must be at least ${min}`;
        if (value > max) return `Sample size cannot exceed ${max.toLocaleString()}`;
        return null;
      },
      suggestion: (value) => {
        if (value < 30) return `For reliable results, consider n ≥ 30 (current: ${value})`;
        return null;
      }
    },

    power: {
      min: 0.5,
      max: 0.99,
      message: (value, min, max) => {
        if (value < min) return `Power must be at least ${(min * 100).toFixed(0)}%`;
        if (value > max) return `Power cannot exceed ${(max * 100).toFixed(0)}%`;
        return null;
      },
      suggestion: (value) => {
        if (value < 0.80) return `Standard practice uses 80% or 90% power (current: ${(value * 100).toFixed(0)}%)`;
        return null;
      }
    },

    alpha: {
      min: 0.001,
      max: 0.20,
      message: (value, min, max) => {
        if (value < min) return `Alpha must be at least ${min}`;
        if (value > max) return `Alpha should not exceed ${max}`;
        return null;
      },
      suggestion: (value) => {
        if (value > 0.10) return `Consider using α = 0.05 (two-sided) or 0.025 (one-sided) for conventional significance`;
        return null;
      }
    },

    proportion: {
      min: 0.001,
      max: 0.999,
      message: (value, min, max) => {
        if (value <= 0) return `Proportion must be greater than 0`;
        if (value >= 1) return `Proportion must be less than 1`;
        return null;
      },
      suggestion: (value) => {
        if (value < 0.01) return `Very rare events (<1%) may require very large sample sizes`;
        if (value > 0.5) return `For proportions > 50%, consider analyzing the complement event`;
        return null;
      }
    },

    hazard_ratio: {
      min: 0.01,
      max: 100,
      exclude: [1.0],
      message: (value, min, max, exclude) => {
        if (value <= 0) return `Hazard ratio must be positive`;
        if (Math.abs(value - 1.0) < 0.001) {
          return `Hazard ratio cannot be 1.0 (no effect). Try 0.75 for protective effect or 1.25 for increased risk`;
        }
        if (value < min || value > max) return `Hazard ratio must be between ${min} and ${max}`;
        return null;
      },
      suggestion: (value) => {
        if (value > 0.95 && value < 1.05) return `HR close to 1 indicates minimal effect. Consider if study is adequately powered.`;
        if (value > 3 || value < 0.33) return `HR far from 1 indicates large effect. Ensure this is clinically realistic.`;
        return null;
      }
    },

    odds_ratio: {
      min: 0.01,
      max: 100,
      exclude: [1.0],
      message: (value, min, max, exclude) => {
        if (value <= 0) return `Odds ratio must be positive`;
        if (Math.abs(value - 1.0) < 0.001) {
          return `Odds ratio cannot be 1.0 (no effect). Try 0.8 or 1.5`;
        }
        if (value < min || value > max) return `Odds ratio must be between ${min} and ${max}`;
        return null;
      },
      suggestion: (value) => {
        if (value > 0.95 && value < 1.05) return `OR close to 1 indicates minimal effect`;
        return null;
      }
    },

    cohens_d: {
      min: 0.01,
      max: 5,
      message: (value, min, max) => {
        if (value <= 0) return `Effect size must be positive`;
        if (value > max) return `Effect size unrealistically large (>${max})`;
        return null;
      },
      suggestion: (value) => {
        if (value < 0.2) return `d < 0.2 is a trivial effect size. Consider if study is worthwhile.`;
        if (value >= 0.2 && value < 0.5) return `d = ${value.toFixed(2)} is a small effect (Cohen's convention)`;
        if (value >= 0.5 && value < 0.8) return `d = ${value.toFixed(2)} is a medium effect (Cohen's convention)`;
        if (value >= 0.8) return `d = ${value.toFixed(2)} is a large effect (Cohen's convention)`;
        return null;
      }
    },

    event_rate: {
      min: 0.1,
      max: 99.9,
      message: (value, min, max) => {
        if (value <= 0) return `Event rate must be greater than 0%`;
        if (value >= 100) return `Event rate must be less than 100%`;
        return null;
      },
      suggestion: (value) => {
        if (value < 1) return `Very rare events (<1%) may require Rule of 3 or extended follow-up`;
        if (value > 50) return `For events >50%, consider analyzing non-event as the outcome`;
        return null;
      }
    },

    discontinuation_rate: {
      min: 0,
      max: 50,
      message: (value, min, max) => {
        if (value < 0) return `Discontinuation rate cannot be negative`;
        if (value > max) return `Discontinuation rate exceeds ${max}% - study may not be feasible`;
        return null;
      },
      suggestion: (value) => {
        if (value === 0) return `Consider 10-20% discontinuation for realistic planning`;
        if (value > 30) return `>30% discontinuation is very high. Consider mitigation strategies.`;
        return null;
      }
    }
  };

  /**
   * Validate input value against rules
   * @param {string} inputType - Type of validation rule to apply
   * @param {number} value - Value to validate
   * @returns {Object} - {valid: boolean, error: string|null, suggestion: string|null}
   */
  function validateInput(inputType, value) {
    const rule = validationRules[inputType];
    if (!rule) {
      return { valid: true, error: null, suggestion: null };
    }

    // Check for required numeric value
    if (isNaN(value) || value === null || value === undefined || value === '') {
      return { valid: false, error: 'Please enter a valid number', suggestion: null };
    }

    // Check exclusions
    if (rule.exclude) {
      for (const excludedValue of rule.exclude) {
        if (Math.abs(value - excludedValue) < 0.001) {
          const error = rule.message(value, rule.min, rule.max, rule.exclude);
          return { valid: false, error: error, suggestion: null };
        }
      }
    }

    // Check range
    const error = rule.message(value, rule.min, rule.max, rule.exclude);
    if (error) {
      return { valid: false, error: error, suggestion: null };
    }

    // Get suggestion
    const suggestion = rule.suggestion ? rule.suggestion(value) : null;

    return { valid: true, error: null, suggestion: suggestion };
  }

  /**
   * Show validation feedback on input
   * @param {HTMLElement} inputElement - Input element
   * @param {Object} validation - Validation result
   */
  function showValidationFeedback(inputElement, validation) {
    // Find or create feedback elements
    let feedbackContainer = inputElement.parentElement.querySelector('.validation-feedback');

    if (!feedbackContainer) {
      feedbackContainer = document.createElement('div');
      feedbackContainer.className = 'validation-feedback';
      inputElement.parentElement.appendChild(feedbackContainer);
    }

    // Clear previous feedback
    feedbackContainer.innerHTML = '';
    inputElement.classList.remove('is-invalid', 'is-valid', 'has-suggestion');

    if (!validation.valid) {
      // Show error
      inputElement.classList.add('is-invalid');
      const errorDiv = document.createElement('div');
      errorDiv.className = 'invalid-feedback d-block';
      errorDiv.innerHTML = `<i class="fa fa-exclamation-circle"></i> ${validation.error}`;
      feedbackContainer.appendChild(errorDiv);
    } else if (validation.suggestion) {
      // Show suggestion
      inputElement.classList.add('has-suggestion');
      const suggestionDiv = document.createElement('div');
      suggestionDiv.className = 'suggestion-feedback';
      suggestionDiv.innerHTML = `<i class="fa fa-lightbulb"></i> ${validation.suggestion}`;
      feedbackContainer.appendChild(suggestionDiv);
    } else {
      // Valid with no suggestions
      inputElement.classList.add('is-valid');
    }
  }

  /**
   * Attach validation to an input element
   * @param {HTMLElement} inputElement - Input element to validate
   * @param {string} validationType - Type of validation
   */
  function attachValidation(inputElement, validationType) {
    inputElement.addEventListener('input', function() {
      const value = parseFloat(inputElement.value);
      const validation = validateInput(validationType, value);
      showValidationFeedback(inputElement, validation);

      // Send validation status to Shiny
      if (window.Shiny && window.Shiny.setInputValue) {
        const inputId = inputElement.id.replace(/-/g, '_');
        Shiny.setInputValue(`${inputId}_valid`, validation.valid, {priority: 'event'});
      }
    });

    // Also validate on blur
    inputElement.addEventListener('blur', function() {
      const value = parseFloat(inputElement.value);
      const validation = validateInput(validationType, value);
      showValidationFeedback(inputElement, validation);
    });
  }

  /**
   * Auto-initialize validation on inputs with data-validate attribute
   */
  function autoInitValidation() {
    document.querySelectorAll('[data-validate]').forEach(input => {
      const validationType = input.getAttribute('data-validate');
      if (!input.hasAttribute('data-validation-initialized')) {
        attachValidation(input, validationType);
        input.setAttribute('data-validation-initialized', 'true');
      }
    });
  }

  /**
   * Check if Calculate button should be enabled
   */
  function updateCalculateButton() {
    const calculateBtn = document.getElementById('go');
    if (!calculateBtn) return;

    // Check if any inputs are invalid
    const hasInvalidInputs = document.querySelectorAll('.is-invalid').length > 0;

    if (hasInvalidInputs) {
      calculateBtn.disabled = true;
      calculateBtn.classList.add('btn-disabled');
      calculateBtn.title = 'Please fix validation errors before calculating';
    } else {
      calculateBtn.disabled = false;
      calculateBtn.classList.remove('btn-disabled');
      calculateBtn.title = '';
    }
  }

  // Initialize on DOMContentLoaded
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', autoInitValidation);
  } else {
    autoInitValidation();
  }

  // Re-initialize when Shiny updates content
  if (window.Shiny) {
    $(document).on('shiny:value', function(event) {
      setTimeout(() => {
        autoInitValidation();
        updateCalculateButton();
      }, 100);
    });

    // Update button state on any input change
    $(document).on('input change', 'input, select', function() {
      setTimeout(updateCalculateButton, 50);
    });
  }

  // Expose utilities globally
  window.PowerAnalysisTool = window.PowerAnalysisTool || {};
  window.PowerAnalysisTool.validateInput = validateInput;
  window.PowerAnalysisTool.attachValidation = attachValidation;
  window.PowerAnalysisTool.autoInitValidation = autoInitValidation;
})();
