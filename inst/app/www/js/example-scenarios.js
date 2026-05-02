/**
 * Example Scenarios Dropdown
 * Provides multiple example scenarios for each analysis type
 */

(function() {
  'use strict';

  // Example scenarios for each analysis type
  const scenarios = {
    power_single: [
      {
        name: 'Post-Marketing Surveillance',
        description: 'Rare adverse event monitoring',
        values: {
          'tab1-power_n': 1500,
          'tab1-power_p': 500,
          'tab1-power_discon': 15,
          'tab1-power_alpha': 0.05
        }
      },
      {
        name: 'Safety Signal Detection',
        description: 'Very rare event (1 in 1000)',
        values: {
          'tab1-power_n': 5000,
          'tab1-power_p': 1000,
          'tab1-power_discon': 10,
          'tab1-power_alpha': 0.05
        }
      },
      {
        name: 'Common AE Monitoring',
        description: 'More frequent event (1 in 50)',
        values: {
          'tab1-power_n': 500,
          'tab1-power_p': 50,
          'tab1-power_discon': 20,
          'tab1-power_alpha': 0.05
        }
      }
    ],
    ss_single: [
      {
        name: 'Standard Safety Study',
        description: 'Calculate N for 1 in 500 event',
        values: {
          'tab1-ss_single_calc_mode': 'calc_n',
          'tab1-ss_power': 80,
          'tab1-ss_p': 500,
          'tab1-ss_discon': 15,
          'tab1-ss_alpha': 0.05
        }
      },
      {
        name: 'Fixed Sample Study',
        description: 'Find minimal detectable frequency',
        values: {
          'tab1-ss_single_calc_mode': 'calc_effect',
          'tab1-ss_power': 80,
          'tab1-ss_n_fixed': 1000,
          'tab1-ss_discon': 10,
          'tab1-ss_alpha': 0.05
        }
      }
    ],
    power_twogrp: [
      {
        name: 'Effectiveness RCT',
        description: 'Binary outcome, moderate effect',
        values: {
          'tab2-power_n1': 200,
          'tab2-power_n2': 200,
          'tab2-power_p1': 0.30,
          'tab2-power_p2': 0.20,
          'tab2-power_discon': 10,
          'tab2-power_alpha': 0.05
        }
      },
      {
        name: 'Comparative Safety',
        description: 'Rare event comparison',
        values: {
          'tab2-power_n1': 500,
          'tab2-power_n2': 500,
          'tab2-power_p1': 0.05,
          'tab2-power_p2': 0.03,
          'tab2-power_discon': 15,
          'tab2-power_alpha': 0.05
        }
      }
    ],
    power_survival: [
      {
        name: 'Oncology Trial',
        description: 'HR = 0.70, moderate event rate',
        values: {
          'tab3-power_n': 300,
          'tab3-power_hr': 0.70,
          'tab3-power_event_rate': 50,
          'tab3-power_discon': 10,
          'tab3-power_alpha': 0.05
        }
      },
      {
        name: 'Cardiovascular Outcome',
        description: 'HR = 0.80, low event rate',
        values: {
          'tab3-power_n': 500,
          'tab3-power_hr': 0.80,
          'tab3-power_event_rate': 25,
          'tab3-power_discon': 15,
          'tab3-power_alpha': 0.05
        }
      }
    ]
  };

  /**
   * Create dropdown for example scenarios
   */
  function createExampleDropdown(buttonId, page) {
    const button = document.getElementById(buttonId);
    if (!button || !scenarios[page]) return;

    // Replace button with dropdown
    const scenarioList = scenarios[page];
    if (scenarioList.length === 0) return;

    // Create dropdown container
    const dropdown = document.createElement('div');
    dropdown.className = 'btn-group example-scenarios-dropdown';

    // Create dropdown button
    dropdown.innerHTML = `
      <button type="button" class="btn btn-info btn-sm dropdown-toggle" data-bs-toggle="dropdown" aria-expanded="false">
        <i class="fa fa-lightbulb"></i> Load Example <span class="caret"></span>
      </button>
      <ul class="dropdown-menu" style="max-height: 300px; overflow-y: auto;">
        ${scenarioList.map((scenario, index) => `
          <li>
            <a class="dropdown-item scenario-item" href="#" data-scenario-index="${index}" data-page="${page}">
              <strong>${scenario.name}</strong>
              <br>
              <small class="text-muted">${scenario.description}</small>
            </a>
          </li>
        `).join('')}
      </ul>
    `;

    // Replace button with dropdown
    button.parentNode.replaceChild(dropdown, button);

    // Add event listeners to dropdown items
    dropdown.querySelectorAll('.scenario-item').forEach(item => {
      item.addEventListener('click', function(e) {
        e.preventDefault();
        const index = parseInt(this.getAttribute('data-scenario-index'));
        const page = this.getAttribute('data-page');
        loadScenario(page, index);
      });
    });
  }

  /**
   * Load a scenario
   */
  function loadScenario(page, index) {
    const scenario = scenarios[page][index];
    if (!scenario) return;

    console.log(`Loading scenario: ${scenario.name}`);

    // Apply values to inputs
    Object.keys(scenario.values).forEach(inputId => {
      const value = scenario.values[inputId];
      const input = document.getElementById(inputId);

      if (input) {
        if (input.type === 'number') {
          input.value = value;
          // Trigger Shiny update
          if (window.Shiny) {
            Shiny.setInputValue(inputId, parseFloat(value));
          }
        } else if (input.type === 'radio') {
          // Find radio button with matching value
          const radio = document.querySelector(`input[name="${inputId}"][value="${value}"]`);
          if (radio) {
            radio.checked = true;
            if (window.Shiny) {
              Shiny.setInputValue(inputId, value);
            }
          }
        } else if (input.tagName === 'SELECT') {
          input.value = value;
          if (window.Shiny) {
            Shiny.setInputValue(inputId, value);
          }
        }

        // Trigger input event for validation
        input.dispatchEvent(new Event('input', { bubbles: true }));
      }
    });

    // Show success notification
    showScenarioNotification(`Loaded: ${scenario.name}`);
  }

  /**
   * Show notification when scenario loaded
   */
  function showScenarioNotification(message) {
    let notification = document.getElementById('scenario-notification');

    if (!notification) {
      notification = document.createElement('div');
      notification.id = 'scenario-notification';
      notification.className = 'scenario-notification';
      document.body.appendChild(notification);
    }

    notification.innerHTML = `
      <i class="fa fa-check-circle"></i> ${message}
    `;
    notification.classList.add('active');

    setTimeout(() => {
      notification.classList.remove('active');
    }, 2500);
  }

  /**
   * Initialize example scenarios
   */
  function initExampleScenarios() {
    // Replace example buttons with dropdowns
    const exampleButtons = {
      'tab1-example_power_single': 'power_single',
      'tab1-example_ss_single': 'ss_single',
      'tab2-example_power_twogrp': 'power_twogrp',
      'tab3-example_power_survival': 'power_survival'
    };

    Object.keys(exampleButtons).forEach(buttonId => {
      const page = exampleButtons[buttonId];
      createExampleDropdown(buttonId, page);
    });

    // Add CSS
    const style = document.createElement('style');
    style.textContent = `
      .example-scenarios-dropdown {
        display: inline-block;
      }

      .example-scenarios-dropdown .dropdown-menu {
        min-width: 280px;
        padding: var(--space-2);
      }

      .example-scenarios-dropdown .dropdown-item {
        padding: var(--space-3);
        border-radius: var(--radius-sm);
        margin-bottom: var(--space-1);
        cursor: pointer;
        transition: background-color 0.15s ease;
      }

      .example-scenarios-dropdown .dropdown-item:hover {
        background-color: var(--bg-hover);
      }

      .example-scenarios-dropdown .dropdown-item strong {
        display: block;
        margin-bottom: var(--space-1);
        color: var(--text-primary);
      }

      .example-scenarios-dropdown .dropdown-item small {
        color: var(--text-secondary);
        font-size: var(--font-size-xs);
      }

      .scenario-notification {
        position: fixed;
        bottom: 80px;
        right: 20px;
        background: var(--color-success);
        color: white;
        padding: 12px 20px;
        border-radius: var(--radius-lg);
        box-shadow: var(--shadow-lg);
        font-size: var(--font-size-sm);
        font-weight: var(--font-weight-medium);
        z-index: 9998;
        opacity: 0;
        transform: translateY(10px);
        transition: opacity 0.2s ease, transform 0.2s ease;
        display: flex;
        align-items: center;
        gap: var(--space-2);
      }

      .scenario-notification.active {
        opacity: 1;
        transform: translateY(0);
      }

      .scenario-notification i {
        font-size: 18px;
      }

      @media (max-width: 768px) {
        .example-scenarios-dropdown .dropdown-menu {
          min-width: 240px;
        }

        .scenario-notification {
          bottom: 60px;
          right: 10px;
          left: 10px;
          text-align: center;
          justify-content: center;
        }
      }
    `;
    document.head.appendChild(style);

    console.log('Example scenarios initialized');
  }

  // Initialize on DOMContentLoaded
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initExampleScenarios);
  } else {
    initExampleScenarios();
  }

  // Re-initialize when Shiny updates content
  if (window.Shiny) {
    $(document).on('shiny:value', function() {
      setTimeout(initExampleScenarios, 200);
    });
  }

  // Expose globally
  window.PowerAnalysisTool = window.PowerAnalysisTool || {};
  window.PowerAnalysisTool.loadScenario = loadScenario;
  window.PowerAnalysisTool.scenarios = scenarios;
})();
